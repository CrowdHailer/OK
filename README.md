# OK

**Elegant handling of idiomatic Erlang conventions of `:ok`/`:error` tuples in Elixir. This includes more concise and readable `with` statement syntax, a tagged-enabled pipeline operator, and semantic pattern matching.**

## Installation

[Available in Hex](https://hex.pm/packages/ok), the package can be installed as:

  1. Add ok to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ok, "~> 1.5.0"}]
    end
    ```
    
## Usage

The OK module works with result tuples by treating them as a result monad.

```elixir
{:ok, value} | {:error, reason}
```

The following sections cover how these result tuples are used in `OK.with`, `~>>` (OK pipeline operator), and semantic pattern matching.

### `OK.with`

#### Basic Usage

* Use the `<-` operator to match & extract a value for an `:ok` tuple.
* Use the `=` operator as you normally would for pattern matching an untagged result.
* The last line should either be a function that returns the tuple, or the literal tuple itself.

_NB: Statements are **not** delimited by commas as with the native Elixir `with` construct._

```elixir
require OK

OK.with do
  user <- fetch_user(1)        # <- operator means func returns {:ok, user}
  cart <- fetch_cart(1)        # <- again, {:ok, cart}
  order = checkout(cart, user) # `=` allows pattern matching on non-tagged funcs
  save_order(order)            # Returns a tuple.
end
```

The above could also be written as

```elixir
require OK

OK.with do
  user <- fetch_user(1)
  cart <- fetch_cart(1)
  order = checkout(cart, user)
  saved <- save_order(order)
  {:ok, saved}                  # The last statement must return a tuple.
end
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

####  Error Matching

`OK.with` accepts also an else block which can be used for handling error results. Note that you pattern match on the _untagged_ error value, often denoted as `reason` in e.g. `{:error, reason}`.

```elixir
OK.with do
  a <- safe_div(8, 2) 
  _ <- safe_div(a, 0) # returns {:error, :zero_division}
else
  :zero_division -> # matches on the untagged :zero_division
    {:ok, :inf}     # return statements are always tagged.
end
```

*Unlike native with any unmatched error case does not throw an error and will just be passed as the return value*


### Result Pipeline Operator `~>>`

This macro allows pipelining result tuples through a pipeline of functions.
The `~>>` macro is the is equivalent to bind/flat_map in other languages.

```elixir
import OK only: ["~>>": 2]

def get_employee_data(file, name) do
  {:ok, file}
  ~>> File.read
  ~>> Poison.decode
  ~>> Dict.fetch(name)
end
```

### Semantic matches

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

## External Links and Resources

* [OK on Hex Docs](https://hex.pm/packages/ok)
* [Handling Errors in Elixir](http://insights.workshop14.io/2015/10/18/handling-errors-in-elixir-no-one-say-monad.html)
* Elixir Forum
  * [Elegant error handling with result monads, alternative to elixir `with` special form](https://elixirforum.com/t/elegant-error-handling-with-result-monads-alternative-to-elixir-with-special-form/3264/1)
  * [Discussion on :ok/:error](https://elixirforum.com/t/usage-of-ok-result-error-vs-some-result-none/3253)
  * [OK v1 library](https://elixirforum.com/t/ok-elegant-error-handling-for-elixir-pipelines-version-1-0-released/1932/)
* [Railway programming](http://www.zohaib.me/railway-programming-pattern-in-elixir/)
* Similar Libraries
  * [exceptional](https://github.com/expede/exceptional)
  * [elixir-monad](https://github.com/nickmeharry/elixir-monad)
  * [happy_with](https://github.com/vic/happy_with)
  * [monad](https://github.com/rmies/monad)
  * [ok_jose](https://github.com/vic/ok_jose)
  * [towel](https://github.com/knrz/towel)
