defmodule OK.KernelTest do
  use ExUnit.Case
  defmodule Example do
    use OK.Kernel

    def alright(value), do: {:ok, value}

    def maybe(:good), do: {:ok, :good}
    def maybe(:bad), do: {:error, :bad}
    def maybe(other), do: {:error, other}

    def run(test) do
      intermediate <- alright(test)
      final <- maybe(intermediate)

      final
    else
      :bad ->
        :rescued
    end
  end

  test "can return any value from function body" do
    assert :good == Example.run(:good)
  end

  test "errors can be handled in an else clause" do
    assert :rescued == Example.run(:bad)
  end

  test "unhandled exceptions will raise an error" do
    assert_raise CaseClauseError, fn() ->
      Example.run(:unhandled)
    end
  end
end
