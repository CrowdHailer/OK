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
    Binding to variable failed, '{:bad, 6}' is not a result tuple.

        Code
          b <- bar(a)

        Expected signature
          bar(a) :: {:ok, b} | {:error, reason}

        Actual values
          bar(a) :: {:bad, 6}
    """
    assert_raise OK.BindError, message, fn() ->
      OK.with do
        a <- foo(6)
        b <- bar(a)
        _ <- {:ok, b}
      end
    end
  end
end
