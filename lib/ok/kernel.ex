defmodule OK.Kernel do
  @moduledoc """
  Add ok binding to all functions.

  **NOTE** this is an experimental feature,
  it will be removed or added permanently for 2.0 release

  ## Example

      defmodule MyApp do
        use OK.Kernel

        def checkout(user_id, cart_id) do
          user <- fetch_user(user_id)        # `<-` will bind user when fetch_user returns {:ok, user}
          cart <- fetch_cart(cart_id)        # `<-` will shortcut to else clause if returned {:error, reason}
          order = checkout(cart, user) # `=` allows pattern matching on non-tagged funcs

          order.invoice_id
        else
          :user_not_found ->
            IO.puts("No user for user_id: \#{user_id}")
            nil
          :user_not_found ->
            IO.puts("User has no cart")
            nil
        end

      end

  TODO move examples to `OK.def/2`
  """

  require Logger
  defmacro __using__(_opts) do
    Logger.warn("Experimental: Use of `OK.Kernel` redefines function definition.")
    quote do
      import Kernel, except: [def: 2]
      import OK, only: [def: 2]
    end
  end
end
