defmodule OK do
  def bind({:ok, value}, func) when is_function(func, 1), do: func.(value)
  def bind(failure = {:error, _reason}, _func), do: failure

  def success(value), do: {:ok, value}

  def failure(reason), do: {:error, reason}

  defmacro lhs ~>> rhs do
    quote bind_quoted: [lhs: lhs, rhs: rhs] do
      OK.bind(lhs, rhs)
    end
  end
end
