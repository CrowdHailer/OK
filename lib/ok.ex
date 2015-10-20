defmodule OK do
  def bind({:ok, value}, func), do: func.(value)
end
