defmodule OK.Pipe do
  @moduledoc false

  defmacro __using__(_options) do
    quote do
      import OK, only: [~>: 2, ~>>: 2]
    end
  end
end
