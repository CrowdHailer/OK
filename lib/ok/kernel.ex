defmodule OK.Kernel do
  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [def: 2]
      import OK, only: [def: 2]
    end
  end
end
