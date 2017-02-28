# OK

**Elegant error handling in elixir pipelines. See [Handling Errors in Elixir](http://insights.workshop14.io/2015/10/18/handling-errors-in-elixir-no-one-say-monad.html) for a more detailed explanation**

[Documentation for OK is available on hexdoc](https://hexdocs.pm/ok)

## Installation

[Available in Hex](https://hex.pm/packages/ok), the package can be installed as:

  1. Add ok to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ok, "~> 1.4.0"}]
    end
    ```

## Usage

The erlang convention for functions that can fail is to return a result tuple.
A result tuple is a two-tuple tagged either as a success(`:ok`) or a failure(`:error`).

The OK module works with result tuples by treating them as a result monad.

```elixir
{:ok, value} | {:error, reason}
```

[Forum discussion on :ok/:error](https://elixirforum.com/t/usage-of-ok-result-error-vs-some-result-none/3253)

### Result pipelines `~>>`

This macro allows pipelining result tuples through a pipeline of functions.
The `~>>` macro is the is equivalent to bind/flat_map in other languages.

```elixir
import OK, only: ["~>>": 2]

def get_employee_data(file, name) do
  {:ok, file}
  ~>> File.read
  ~>> Poison.decode
  ~>> Dict.fetch(name)
end

def handle_user_data({:ok, data}), do: IO.puts("Contact at #{data["email"]}")
def handle_user_data({:error, :enoent}), do: IO.puts("File not found")
def handle_user_data({:error, {:invalid, _}}), do: IO.puts("Invalid JSON")
def handle_user_data({:error, :key_not_found}), do: IO.puts("Could not find employee")

get_employee_data("my_company/employees.json")
|> handle_user_data
```

Code structured like this is an example of [railway programming](http://www.zohaib.me/railway-programming-pattern-in-elixir/).

[Forum discussion on error handling in pipelines](https://elixirforum.com/t/ok-elegant-error-handling-for-elixir-pipelines-version-1-0-released/1932)

### Result blocks `with`

For situations when the pipeline macro is not sufficiently flexible.

To extract a value for an ok tuple use the `<-` operator.

```elixir
require OK

OK.with do
  user <- fetch_user(1)
  cart <- fetch_cart(1)
  order = checkout(cart, user)
  save_order(order)
end
```

`Ok.with/1` supports an else block that can be used for handling error values.

```elixir
OK.with do
  a <- safe_div(8, 2)
  _ <- safe_div(a, 0)
else
  :zero_division -> # matches on reason
    {:ok, :inf}     # must return a new success or failure
end
```

*Unlike native with any unmatched error case does not through an error and will just be passed as the return value*

The cart example above is equivalent to
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

[Forum discussion on `with` naming](https://elixirforum.com/t/alternative-to-with-specific-to-result-tuples/3264)

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

### Similar Libraries

For reference.

- [exceptional](https://github.com/expede/exceptional)
- [elixir-monad](https://github.com/nickmeharry/elixir-monad)
- [happy_with](https://github.com/vic/happy_with)
- [monad](https://github.com/rmies/monad)
- [ok_jose](https://github.com/vic/ok_jose)
- [towel](https://github.com/knrz/towel)

*Possible extensions to include implementing bind on structs so that errors can be better handled.
Implement a catch functionality for functions that error.
Implement existing monad library protocols so can extend similar DB functionality e.g. slick*
