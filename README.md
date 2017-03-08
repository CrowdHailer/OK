# OK

**Elegant error handling for Elixir. Built on the solid foundation of the result monad.**

- [Install from Hex](https://hex.pm/packages/ok)
- [Documentation available on hexdoc](https://hexdocs.pm/ok)

## Result tuples

The OK module works with result tuples by treating them as a result monad.

```elixir
{:ok, value} | {:error, reason}
```

See [Handling Errors in Elixir](http://insights.workshop14.io/2015/10/18/handling-errors-in-elixir-no-one-say-monad.html) for a more detailed explanation.

## OK.with

`OK.with/1` allows for more concise and ultimately more readable code than the native `with` construct. It does this by leveraging result monads for both the happy and non-happy paths. By extracting the actual function return values from the result tuples, `OK.with/1` reduces noise which improves readability and recovers precious horizontal code real estate. This also encourages writing idiomatic Elixir functions which return `:ok`/`:error` tuples.

- [Elegant error handling with result monads, alternative to elixir `with` special form](https://elixirforum.com/t/elegant-error-handling-with-result-monads-alternative-to-elixir-with-special-form/3264/1)
- [Discussion on :ok/:error](https://elixirforum.com/t/usage-of-ok-result-error-vs-some-result-none/3253)

#### Basic Usage

- Use the `<-` operator to match & extract a value for an `:ok` tuple.
- Use the `=` operator as you normally would for pattern matching an untagged result.
- Return result must also be in the form of a tagged tuple.
- _Optionally_ pattern match on some errors in an `else` block.

_NB: Statements are **not** delimited by commas as with the native Elixir `with` construct._

```elixir
require OK

OK.with do
  user <- fetch_user(1)        # `<-` operator means func returns {:ok, user}
  cart <- fetch_cart(1)        # `<-` again, {:ok, cart}
  order = checkout(cart, user) # `=` allows pattern matching on non-tagged funcs
  save_order(order)            # Returns an ok/error tuple
```

The cart example above is equivalent to the following nested `case` statements

```elixir
case fetch_user(1) do
  {:ok, user} ->
    case fetch_cart(1) do
      {:ok, cart} ->
        order = checkout(cart, user)
        save_order(order)
      {:error, reason} ->
        {:error, reason}
    end
  {:error, reason} ->
    {:error, reason}
end
```

You can pattern match on errors as well in an `else` block:

```elixir
require OK

OK.with do
  user <- fetch_user(1)
  cart <- fetch_cart(1)
  order = checkout(cart, user)
  save_order(order)
else
  :user_not_found ->           # Match on untagged reason
    {:error, :unauthorized}    # Return a literal error tuple
end
```

Note that the `else` block pattern matches on the extracted error reason, but the return expression must still be the full tuple.

*Unlike Elixir's native `with` construct, any unmatched error case does not throw an error and will just be passed as the return value*

You can also use `OK.success` and `OK.failure` macros:

```elixir
require OK

OK.with do
  user <- fetch_user(1)
  cart <- fetch_cart(1)
  order = checkout(cart, user)
  saved <- save_order(order)
  OK.success saved
else
  :user_not_found ->
    OK.failure :unauthorized
end
```

## Result Pipeline Operator `~>>`

This macro allows pipelining result tuples through multiple functions for an extremely concise happy path.
The `~>>` macro is equivalent to bind/flat_map in other languages.

```elixir
import OK only: ["~>>": 2]

def get_employee_data(file, name) do
  {:ok, file}
  ~>> File.read
  ~>> Poison.decode
  ~>> Dict.fetch(name)
end
```

## Semantic matches

`OK` provides macros for matching on success and failure cases.
This allows for code to check if a result returned from a function was a success or failure.

This check can be done without knowledge about how the result is structured to represent a success or failure

```elixir
import OK, only: [success: 2, failure: 2]

case fetch_user(id) do
  success(user) ->
    user
  failure(:not_found) ->
    create_guest_user()
end
```

## Additional External Links and Resources

- Elixir Forum
  - [OK v1 library](https://elixirforum.com/t/ok-elegant-error-handling-for-elixir-pipelines-version-1-0-released/1932/)
- [Railway programming](http://www.zohaib.me/railway-programming-pattern-in-elixir/)
- Similar Libraries
  - [exceptional](https://github.com/expede/exceptional)
  - [elixir-monad](https://github.com/nickmeharry/elixir-monad)
  - [happy_with](https://github.com/vic/happy_with)
  - [monad](https://github.com/rmies/monad)
  - [ok_jose](https://github.com/vic/ok_jose)
  - [towel](https://github.com/knrz/towel)
