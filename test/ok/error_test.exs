defmodule OK.ErrorTest do
  use ExUnit.Case

  def foo(x) do
    {:ok, x}
  end

  def bar(y) do
    {:bad, y}
  end

  require OK

  test "helpful error for binding failure" do
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
      OK.with do
        a <- foo(6)
        b <- bar(a)
        OK.success(b)
      end
    end
  end

  test "match failure" do
    message = """
    no binding to right hand side value: '{:ok, 6}'

        Code
          %{a: a} <- foo(6)

        Expected signature
          foo(6) :: {:ok, %{a: a}} | {:error, reason}

        Actual values
          foo(6) :: {:ok, 6}
    """

    assert_raise OK.BindError, message, fn ->
      OK.with do
        %{a: a} <- foo(6)
        b <- foo(a)
        OK.success(b)
      end
    end
  end
end
