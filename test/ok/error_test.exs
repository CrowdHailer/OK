defmodule OK.ErrorTest do
  use ExUnit.Case

  def foo(x) do
    {:ok, x}
  end

  def bar(y) do
    {:bad, y}
  end

  require OK

  test "helpful error for binding failure in for" do
    message = """
    no binding to right hand side value: '{:bad, 6}'

        Code
          b <- bar(a)

        Expected signature
          bar(a) :: {:ok, b} | {:error, reason}

        Actual values
          bar(a) :: {:bad, 6}
    """

    assert_raise OK.BindError, message, fn ->
      OK.for do
        a <- foo(6)
        b <- bar(a)
      after
        OK.success(b)
      end
    end
  end

  test "helpful error for binding failure in try" do
    message = """
    no binding to right hand side value: '{:bad, 6}'

        Code
          b <- bar(a)

        Expected signature
          bar(a) :: {:ok, b} | {:error, reason}

        Actual values
          bar(a) :: {:bad, 6}
    """

    assert_raise OK.BindError, message, fn ->
      OK.try do
        a <- foo(6)
        b <- bar(a)
      after
        b
      rescue
        _ ->
          :ok
      end
    end
  end
end
