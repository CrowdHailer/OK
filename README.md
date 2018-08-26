# OK

**Elegant error/exception handling in Elixir, with result monads.**

[![Hex pm](http://img.shields.io/hexpm/v/ok.svg?style=flat)](https://hex.pm/packages/ok)
[![Build Status](https://secure.travis-ci.org/CrowdHailer/OK.svg?branch=master
"Build Status")](https://travis-ci.org/CrowdHailer/OK)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

- [Install from Hex](https://hex.pm/packages/ok)
- [Documentation available on hexdoc](https://hexdocs.pm/ok)

## Result tuples

The OK module works with result tuples by treating them as a result monad.

```elixir
{:ok, value} | {:error, reason}
```

See [Handling Errors in Elixir](http://insights.workshop14.io/2015/10/18/handling-errors-in-elixir-no-one-say-monad.html) for a more detailed explanation.

See [FAQ](#faq) at end of README for a few common question.

## OK.for

`OK.for/1` combines several functions that may fail.

- Use the `<-` operator to match & extract a value for an `:ok` tuple.
- Use the `=` operator as you normally would for pattern matching an untagged result.

```elixir
require OK

OK.for do
  user <- fetch_user(1)             # `<-` operator means func returns {:ok, user}
  cart <- fetch_cart(1)             # `<-` again, {:ok, cart}
  order = checkout(cart, user)      # `=` allows pattern matching on non-tagged funcs
  saved_order <- save_order(order)
after
  saved_order                       # Value will be wrapped if not already a result tuple
end
```

`OK.for/1` guarantees that it's return value is also in the structure of a result tuple.

## OK.try

`OK.try/1` combines several functions that may fail, and handles errors.

This is useful when writing code that has it's own representation of errors.
e.g. HTTP Responses.

For example when using raxx to build responses the following code will always return a response.

```elixir
require OK
import Raxx

OK.try do
  user <- fetch_user(1)             # `<-` operator means func returns {:ok, user}
  cart <- fetch_cart(1)             # `<-` again, {:ok, cart}
  order = checkout(cart, user)      # `=` allows pattern matching on non-tagged funcs
  saved_order <- save_order(order)
after
  response(:created)                # Value will be returned unwrapped
rescue
  :user_not_found ->
    response(:not_found)
  :could_not_save ->
    response(:internal_server_error)
end
```

## OK Pipe

The pipe (`~>>`) is equivalent to `bind`/`flat_map`.
The pipe (`~>`) is equivalent to `map`.

These macros allows pipelining result tuples through multiple functions
for an extremely concise happy path.

```elixir
use OK.Pipe

def get_employee_data(file, name) do
  {:ok, file}
  ~>> File.read
  ~> String.upcase
end
```

Use `~>>` for `File.read` because it returns a result tuple.
Use `~>` for `String.upcase` because it returns a bare value that should be wrapped in an ok tuple.

## Semantic matches

`OK` provides macros for matching on success and failure cases.
This allows for code to check if a result returned from a function was a
success or failure while hiding implementation details about how that result is
structured.

```elixir
import OK, only: [success: 1, failure: 1]

case fetch_user(id) do
  success(user) ->
    user
  failure(:not_found) ->
    create_guest_user()
end
```

## FAQ

#### Why does `OK` not catch raised errors?

For the main rational behind this decision see the article [Errors are not exceptional](http://crowdhailer.me/2018-08-26/errors-are-not-exceptional/)

Two other reasons:
- Exceptional input and errors are not the same thing,
  `OK` leaves raising exceptions as a way to handle errors that should never happen.
- Calls inside try/1 are not tail recursive since the VM needs to keep the stacktrace in case an exception happens.
  [see source](https://github.com/elixir-lang/elixir/blob/22bd10a8170af0b187029d115abe4cc8edcf2ae6/lib/elixir/lib/kernel/special_forms.ex#L1622).

#### What about other shapes of error and success?

- Accepting any extra forms is a slippery slope, and they are not always unambiguous.
  If a library is not returning errors as you like it is very easy to wrap in a custom function.

  ```elixir
  def fetch_foo(map) do
    case Map.fetch(map, :foo) do
      {:ok, foo} -> {:ok, foo}
      :error -> {:error, :no_foo}
    end
  end
  ```

#### What changed in version 2.0

- `OK.with` was deprecated.
- `use OK.Pipe` was added.

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
