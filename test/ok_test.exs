defmodule OKTest do
  use ExUnit.Case
  import OK, only: [~>>: 2, ~>: 2, success: 1, failure: 1]
  doctest OK

  test "matching on a success case" do
    success(value) = {:ok, :value}
    assert :value == value
  end

  test "matching on a failure case" do
    failure(reason) = {:error, :reason}
    assert :reason == reason
  end

  test "bind passes success value to function" do
    report_func = fn arg -> send(self(), arg) end

    OK.flat_map({:ok, :test_value}, report_func)
    assert_receive :test_value
  end

  test "bind returns replied value" do
    reply_func = fn _arg -> {:ok, :reply_ok} end

    result = OK.flat_map({:ok, :test_value}, reply_func)
    assert {:ok, :reply_ok} == result
  end

  test "bind does not execute function for failure tuple" do
    fail_func = fn _arg -> flunk("Should not be called") end

    OK.flat_map({:error, :error_reason}, fail_func)
  end

  test "bind returns original error" do
    error_func = fn _arg -> {:error, :new_error} end

    result = OK.flat_map({:error, :original_error}, error_func)
    assert {:error, :original_error} == result
  end

  test "bind must only take a function in success case" do
    assert_raise FunctionClauseError, fn ->
      OK.flat_map({:ok, :test_value}, :no_func)
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
    fn a, b -> {:ok, a - b} end
  end

  def safe_div(_, 0) do
    {:error, :zero_division}
  end

  def safe_div(a, b) do
    {:ok, a / b}
  end

  def pass_func(x) do
    {:ok, x}
  end

  def fail_func(x) do
    {:error, x}
  end
end
