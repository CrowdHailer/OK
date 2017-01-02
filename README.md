# OK

**Elegant error handling in elixir pipelines. See [Handling Errors in Elixir](http://insights.workshop14.io/2015/10/18/handling-errors-in-elixir-no-one-say-monad.html) for a more detailed explanation**

[Documentation for OK is available on hexdoc](https://hexdocs.pm/ok)

## Installation

[Available in Hex](https://hex.pm/packages/ok), the package can be installed as:

  1. Add ok to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ok, "~> 1.2.0"}]
    end
    ```

## Usage

The erlang convention for functions that can fail is to return a result tuple.
A result tuple is a two-tuple tagged either as a success(`:ok`) or a failure(`:error`).

The OK module works with result tuples by treating them as a result monad.

```elixir
{:ok, value} | {:error, reason}
```

### Result pipelines '~>>'

This macro allows pipelining result tuples through a pipeline of functions.
The `~>>` macro is the is equivalent to bind/flat_map in other languages.

```elixir
import OK, only: :macros

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

### Result blocks *BETA*

For situations when the pipeline macro is not sufficiently flexible.

To extract a value for an ok tuple use the `<-` operator.

```elixir
OK.try do
  a <- safe_div(6, 2)
  b = a + 1
  c <- safe_div(b, 2)
  {:ok, a + c}
end
```

The above code is equivalent to
```elixir
case safe_div(6, 2) do
  {:ok, a} ->
    b = a + 1
    case safe_div(b, 2) do
      result = {:ok, c} ->
        {:ok, a + c}
      {:error, reason} ->
        {:error, reason}
    end
  {:error, reason} ->
    {:error, reason}
end
```

### Railway programming

`OK` can be used for railway programming.
An explanation of this is available in this [blog](http://www.zohaib.me/railway-programming-pattern-in-elixir/)

### Similar Libraries

For reference.

- [exceptional](https://github.com/expede/exceptional)
- [elixir-monad](https://github.com/nickmeharry/elixir-monad)
- [monad](https://github.com/rmies/monad)
- [towel](https://github.com/knrz/towel)

*Possible extensions to include implementing bind on structs so that errors can be better handled.
Implement a catch functionality for functions that error.
Implement existing monad library protocols so can extend similar DB functionality e.g. slick*
