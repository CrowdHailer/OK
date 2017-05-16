defmodule OK.ErrorTest do
  use ExUnit.Case

  def good(x) do
    {:ok, x}
  end

  def invalid(y) do
    {:bad, y}
  end

  require OK

  test "helpful error for binding failure" do
    message = """
    no binding to right hand side value: '{:bad, 6}'

        Code
          b <- invalid(a)

        Expected signature
          invalid(a) :: {:ok, b} | {:error, reason}

        Actual values
          invalid(a) :: {:bad, 6}
    """
    assert_raise OK.BindError, message, fn() ->
      OK.with do
        a <- good(6)
        b <- invalid(a)
        OK.success(b)
      end
    end
  end

  test "match failure" do
    message = """
    no binding to right hand side value: '{:ok, 6}'

        Code
          %{a: a} <- good(6)

        Expected signature
          good(6) :: {:ok, %{a: a}} | {:error, reason}

        Actual values
          good(6) :: {:ok, 6}
    """
    assert_raise OK.BindError, message, fn() ->
      OK.with do
        %{a: a} <- good(6)
        b <- good(a)
        OK.success(b)
      end
    end
  end

  test "invalid result from main block" do
    message = """
    final value from block was invalid, a result tuple was expected.

        Code
          invalid(a)

        Expected output
          {:ok, value} | {:error, reason}

        Actual output
          {:bad, 6}
    """
    assert_raise OK.BadResultError, message, fn() ->
      OK.with do
        a <- good(6)
        invalid(a)
      end
    end
  end

  test "invalid result from error case" do
    message = """
    final value from block was invalid, a result tuple was expected.

        Code
          invalid(5)

        Expected output
          {:ok, value} | {:error, reason}

        Actual output
          {:bad, 5}
    """
    assert_raise OK.BadResultError, fn() ->
      OK.with do
        fn() -> {:error, :zero_division} end.()
      else
        :zero_division ->
          invalid(5)
      end
    end
  end
end
