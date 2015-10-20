defmodule OKTest do
  use ExUnit.Case
  doctest OK

  test "bind passes value to function" do
    report_func = fn (arg) -> send(self, arg) end

    OK.bind({:ok, :test_value}, report_func)
    assert_receive :test_value
  end

  test "bind returns replied value" do
    reply_func = fn (_arg) -> {:ok, :reply_ok} end

    result = OK.bind({:ok, :test_value}, reply_func)
    assert {:ok, :reply_ok} == result
  end
end
