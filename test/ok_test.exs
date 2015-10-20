defmodule OKTest do
  use ExUnit.Case
  import OK, only: :macros
  doctest OK

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

  test "wrapping a value as a success" do
    assert {:ok, :any_value} = OK.success(:any_value)
  end

  test "wrapping a reason as a failure" do
    assert {:error, :some_reason} = OK.failure(:some_reason)
  end

  test "macro passes success value to function" do
    report_func = fn (arg) -> send(self, arg) end

    {:ok, :test_value} ~>> report_func
    assert_receive :test_value
  end

  test "macro returns replied value" do
    reply_func = fn (_arg) -> {:ok, :reply_ok} end

    result = {:ok, :test_value} ~>> reply_func
    assert {:ok, :reply_ok} == result
  end

  test "macro does not execute function for failure tuple" do
    fail_func = fn (_arg) -> flunk("Should not be called") end

    {:error, :error_reason} ~>> fail_func
  end

  test "macro returns original error" do
    error_func = fn (_arg) -> {:error, :new_error} end

    result = {:error, :original_error} ~>> error_func
    assert {:error, :original_error} == result
  end

  test "macro must only take a function in success case" do
    assert_raise FunctionClauseError, fn ->
      {:ok, :test_value} ~>> :no_func
    end
  end
end
