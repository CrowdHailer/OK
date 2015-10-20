defmodule OK do
  def bind({:ok, value}, func), do: func.(value)
  def bind(failure = {:error, _reason}, _func), do: failure
end
