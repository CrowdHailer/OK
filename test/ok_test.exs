defmodule OKTest do
  use ExUnit.Case
  import OK, only: :macros
  doctest OK

  test "try a chain of operations" do
    result = OK.try do
      a <- safe_div(8, 2)
      b <- safe_div(a, 2)
    end
    assert result == {:ok, 2}
  end

  test "try last operation failure" do
    result = OK.try do
      a <- safe_div(8, 2)
      b <- safe_div(a, 0)
    end
    assert result == {:error, :zero_division}
  end

  test "try first operation failure" do
    result = OK.try do
      a <- safe_div(8, 0)
      b <- safe_div(a, 2)
    end
    assert result == {:error, :zero_division}
  end

  test "try normal code within block" do
    result = OK.try do
      a <- safe_div(6, 2)
      b = a + 1
      c <- safe_div(b, 2)
    end
    assert result == {:ok, 2}
  end

  test "primitives as final operation" do
    result = OK.try do
      a <- safe_div(8, 2)
      b <- safe_div(a, 2)
      {:ok, a + b}
    end
    assert result == {:ok, 6}
  end

  test "function as final operation" do
    result = OK.try do
      a <- safe_div(8, 2)
      b <- safe_div(a, 2)
      OK.failure(a + b)
    end
    assert result == {:error, 6}
  end

  test "will fail to match if the return value is not a result" do
    assert_raise CaseClauseError, fn() ->
      result = OK.try do
        a <- safe_div(8, 2)
        {:x, 5}
      end
    end
  end

  test "bind passes success value to function" do
    report_func = fn (arg) -> send(self, arg) end

    OK.bind({:ok, :test_value}, report_func)
    assert_receive :test_value
  end

  test "bind returns replied value" do
    reply_func = fn (_arg) -> {:ok, :reply_ok} end

    result = OK.bind({:ok, :test_value}, reply_func)
    assert {:ok, :reply_ok} == result
  end

  test "bind does not execute function for failure tuple" do
    fail_func = fn (_arg) -> flunk("Should not be called") end

    OK.bind({:error, :error_reason}, fail_func)
  end

  test "bind returns original error" do
    error_func = fn (_arg) -> {:error, :new_error} end

    result = OK.bind({:error, :original_error}, error_func)
    assert {:error, :original_error} == result
  end

  test "bind must only take a function in success case" do
    assert_raise FunctionClauseError, fn ->
      OK.bind({:ok, :test_value}, :no_func)
    end
  end

  # These are all used in doc tests
  def double(a) do
    {:ok, 2 * a}
  end

  def x do
    {:ok, 7}
  end

  def decrement() do
    fn (a, b) -> {:ok, a - b} end
  end

  def safe_div(_, 0) do
    {:error, :zero_division}
  end
  def safe_div(a, b) do
    {:ok, a / b}
  end
end
