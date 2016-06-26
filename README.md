# OK Elixir

**Effecient error handling in elixir pipelines. See [Handling Errors in Elixir](http://insights.workshop14.io/2015/10/18/handling-errors-in-elixir-no-one-say-monad.html) for a more detailed explination**

## Installation

[Available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ok to your list of dependencies in `mix.exs`:

        def deps do
          [{:ok, "~> 0.0.1"}]
        end

  2. Refetch the dependencies, execute:

        $ mix deps.get

## Usage

The OK module works with the native error handling in Erlang/Elixir, that is a result tuple.
A result tuple is a two-tuple tagged either as a success(`:ok`) or a failure(`:error`).

```elixir
{:ok, value} | {:error, reason}
```

### Bind

The primary functionality is the `OK.bind/2` function.
This function takes a result tuple and a next function.
If the result tuple is tagged as a success then it will be passed to the next function.
If the tag is failure then the next function is skipped

```elixir
OK.bind({:ok, 2}, fn (x) -> {:ok, 2 * x} end)
# => {:ok, 4}

OK.bind({:error, :some_reason}, fn (x) -> {:ok, 2 * x} end)
# => {:error, :some_reason}
```

### '~>>' Macro

This macro allows pipelining results through a pipeline of anonymous functions.

```elixir
import OK, only: :macros

def get_employee_data(file, name) do
  {:ok, file}
  ~>> &File.read/1
  ~>> &Poison.decode/1
  ~>> &Dict.fetch(&1, name)
end

def handle_user_data({:ok, data}), do: IO.puts("Contact at #{data["email"]}")
def handle_user_data({:error, :enoent}), do: IO.puts("File not found")
def handle_user_data({:error, {:invalid, _}}), do: IO.puts("Invalid JSON")
def handle_user_data({:error, :key_not_found}), do: IO.puts("Could not find employee")

get_employee_data("my_company/employees.json")
|> handle_user_data
```

### Success

Wraps a value in a successful result tuple.

```elixir
OK.success(:value)
# => {:ok, :value}
```

### Failure

Wraps a reason in a failure result tuple.

```elixir
Ok.failure("reason")
# => {:error, "reason"}
```

