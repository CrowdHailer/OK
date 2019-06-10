defmodule OK do
  @moduledoc """
  The `OK` module enables clean and expressive error handling when coding with
  idiomatic `:ok`/`:error` tuples. We've included many examples in the function
  docs here, but you can also check out the
  [README](https://github.com/CrowdHailer/OK/blob/master/README.md) for more
  details and usage.

  Feel free to [open an issue](https://github.com/CrowdHailer/OK/issues) for
  any questions that you have.
  """

  @doc """
  Applies a function to the interior value of a result tuple.

  If the tuple is tagged `:ok` the value will be mapped by the function.
  A tuple tagged `:error` will be unchanged.

  ## Examples

      iex> OK.map({:ok, 2}, fn (x) -> 2 * x end)
      {:ok, 4}

      iex> OK.map({:error, :some_reason}, fn (x) -> 2 * x end)
      {:error, :some_reason}
  """
  @spec map({:ok, a}, (a -> b)) :: {:ok, b} when a: any, b: any
  @spec map({:error, reason}, (any -> any)) :: {:error, reason} when reason: any
  def map({:ok, value}, func) when is_function(func, 1), do: {:ok, func.(value)}
  def map({:error, reason}, _func), do: {:error, reason}

  @doc """
  Takes a result tuple and a next function.
  If the result tuple is tagged as a success then its value will be passed to the next function.
  If the tag is failure then the next function is skipped.

  ## Examples

      iex> OK.flat_map({:ok, 2}, fn (x) -> {:ok, 2 * x} end)
      {:ok, 4}

      iex> OK.flat_map({:error, :some_reason}, fn (x) -> {:ok, 2 * x} end)
      {:error, :some_reason}
  """
  @spec flat_map({:ok, a} | {:error, reason}, (a -> {:ok, b} | {:error, reason})) ::
          {:ok, b} | {:error, reason}
        when a: any, b: any, reason: any
  # NOTE return value of function is not checked to be a result tuple.
  # errors are informative enough when piped to something else expecting result tuple.
  # Also dialyzer will catch in anonymous function with incorrect typespec is given.
  def flat_map({:ok, value}, func) when is_function(func, 1), do: func.(value)
  def flat_map({:error, reason}, _func), do: {:error, reason}

  @doc """
  Transform every element of a list with a mapping function.
  The mapping function must return a result tuple.

  If all of the result tuples are tagged :ok, then it returns a list tagged with :ok.
  If one or more of the result tuples are tagged :error, it returns the first error.

  ## Examples

      iex> OK.map_all(1..3, &safe_div(6, &1))
      {:ok, [6.0, 3.0, 2.0]}

      iex> OK.map_all([-1, 0, 1], &safe_div(6, &1))
      {:error, :zero_division}
  """
  @spec map_all([a], (a -> {:ok, b} | {:error, reason})) :: {:ok, [b]} | {:error, reason}
        when a: any, b: any, reason: any
  def map_all(list, func) when is_function(func, 1) do
    result =
      Enum.reduce_while(list, [], fn value, acc ->
        case func.(value) do
          {:ok, value} ->
            {:cont, [value | acc]}

          {:error, _} = error ->
            {:halt, error}
        end
      end)

    if is_list(result), do: {:ok, Enum.reverse(result)}, else: result
  end

  @doc """
  Takes a result tuple, a predicate function, and an optional error reason.
  If the result tuple is tagged as a success then its value will be passed to the predicate function.
  If the predicate returns `true`, then the result tuple stay the same.
  If the predicate returns `false`, then the result tuple becomes `{:error, reason}`.
  If the tag is failure then the predicate function is skipped.

  ## Examples

      iex> OK.check({:ok, 2}, fn (x) -> x == 2 end, :bad_value)
      {:ok, 2}

      iex> OK.check({:ok, 2}, fn (x) -> x == 3 end, :bad_value)
      {:error, :bad_value}

      iex> OK.check({:error, :some_reason}, fn (x) -> x == 4 end, :bad_value)
      {:error, :some_reason}
  """
  @spec check({:ok, a}, (a -> boolean), test_failure_reason) ::
          {:ok, a} | {:error, test_failure_reason}
        when a: any, test_failure_reason: any
  @spec check({:error, reason}, (a -> boolean), test_failure_reason) :: {:error, reason}
        when a: any, reason: any, test_failure_reason: any

  def check({:ok, value}, func, reason) when is_function(func, 1) do
    case func.(value) do
      true -> {:ok, value}
      false -> {:error, reason}
    end
  end

  def check({:error, reason}, _func, _reason), do: {:error, reason}

  @doc """
  Wraps a value as a successful result tuple.

  ## Examples

      iex> OK.success(:value)
      {:ok, :value}
  """
  defmacro success(value) do
    quote do
      {:ok, unquote(value)}
    end
  end

  @doc """
  Creates a failed result tuple with the given reason.

  ## Examples

      iex> OK.failure("reason")
      {:error, "reason"}
  """
  defmacro failure(reason) do
    quote do
      {:error, unquote(reason)}
    end
  end

  @doc """
  Wraps any term in an `:ok` tuple, unless already a result monad.

  ## Examples

      iex> OK.wrap("value")
      {:ok, "value"}

      iex> OK.wrap({:ok, "value"})
      {:ok, "value"}

      iex> OK.wrap({:error, "reason"})
      {:error, "reason"}
  """
  def wrap({:ok, value}), do: {:ok, value}
  def wrap({:error, reason}), do: {:error, reason}
  def wrap(other), do: {:ok, other}

  @doc """
  Require a variable not to be nil.

  Optionally provide a reason why variable is required.

  ## Examples

      iex> OK.required(:some)
      {:ok, :some}

      iex> OK.required(nil)
      {:error, :value_required}

      iex> OK.required(Map.get(%{}, :port), :port_number_required)
      {:error, :port_number_required}
  """
  @spec required(any, any) :: {:ok, any} | {:error, any}
  def required(value, reason \\ :value_required)
  def required(nil, reason), do: {:error, reason}
  def required(value, _reason), do: {:ok, value}

  @doc """
  Pipeline version of `map/2`.

  ## Examples

      iex> {:ok, 5} ~> Integer.to_string
      {:ok, "5"}

      iex> {:error, :zero_division_error} ~> Integer.to_string
      {:error, :zero_division_error}

      iex> {:ok, "a,b"} ~> String.split(",")
      {:ok, ["a", "b"]}
  """
  defmacro lhs ~> {call, line, args} do
    value = quote do: value
    args = [value | args || []]

    quote do
      OK.map(unquote(lhs), fn unquote(value) -> unquote({call, line, args}) end)
    end
  end

  @doc """
  The OK result pipe operator `~>>`, or result monad flat_map operator, is similar
  to Elixir's native `|>` except it is used within happy path. It takes the
  value out of an `{:ok, value}` tuple and passes it as the first argument to
  the function call on the right.

  It can be used in several ways.

  Pipe to a local call.<br />
  _(This is equivalent to calling `double(5)`)_

      iex> {:ok, 5} ~>> double()
      {:ok, 10}

  Pipe to a remote call.<br />
  _(This is equivalent to calling `OKTest.double(5)`)_

      iex> {:ok, 5} ~>> OKTest.double()
      {:ok, 10}

      iex> {:ok, 5} ~>> __MODULE__.double()
      {:ok, 10}

  Pipe with extra arguments.<br />
  _(This is equivalent to calling `safe_div(6, 2)`)_

      iex> {:ok, 6} ~>> safe_div(2)
      {:ok, 3.0}

      iex> {:ok, 6} ~>> safe_div(0)
      {:error, :zero_division}

  It also works with anonymous functions.

      iex> {:ok, 3} ~>> (fn (x) -> {:ok, x + 1} end).()
      {:ok, 4}

      iex> {:ok, 6} ~>> decrement().(2)
      {:ok, 4}

  When an error is returned anywhere in the pipeline, it will be returned.

      iex> {:ok, 6} ~>> safe_div(0) ~>> double()
      {:error, :zero_division}

      iex> {:error, :previous_bad} ~>> safe_div(0) ~>> double()
      {:error, :previous_bad}
  """
  defmacro lhs ~>> {call, line, args} do
    value = quote do: value
    args = [value | args || []]

    quote do
      OK.flat_map(unquote(lhs), fn unquote(value) -> unquote({call, line, args}) end)
    end
  end

  @doc """
  Lightweight notation for working with the values from serval failible components.

  Values are extracted from an ok tuple using the in (`<-`) operator.
  Any line using this operator that trys to match on an error tuple will result in early return.

  If all bindings can be made, i.e. all functions returned `{:ok, value}`,
  then the after block is executed to return the final value.

  Return values from the after block are wrapped as an ok result,
  unless they are already a result tuple.
  The return value of a for comprehension is always a result monad

      iex> OK.for do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 2)
      ...> after
      ...>   a + b
      ...> end
      {:ok, 6.0}

      iex> OK.for do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 2)
      ...> after
      ...>   OK.success(a + b)
      ...> end
      {:ok, 6.0}

      iex> OK.for do
      ...>   a <- safe_div(8, 2)
      ...>   _ <- safe_div(a, 2)
      ...> after
      ...>   {:error, :something_else}
      ...> end
      {:error, :something_else}

  Regular matching using the `=` operator is also available,
  for calculating intermediate values.

      iex> OK.for do
      ...>   a <- safe_div(8, 2)
      ...>   b = 2.0
      ...> after
      ...>   a + b
      ...> end
      {:ok, 6.0}

      iex> OK.for do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 0) # error here
      ...> after
      ...>   a + b               # does not execute this line
      ...> end
      {:error, :zero_division}

      iex> OK.for do: :literal, after: :result
      {:ok, :result}
  """
  defmacro for(do: binding, after: yield_block) do
    {:__block__, _env, bindings} = wrap_code_block(binding)

    safe_yield_block =
      quote do
        unquote(__MODULE__).wrap(unquote(yield_block))
      end

    expand_bindings(bindings, safe_yield_block)
  end

  defmacro for(_) do
    description = """
    OK.for/1 requires `do` and `after` clauses. e.g.

        OK.for do
          a <- safe_div(8, 2)
          b <- safe_div(a, 2)
        after
          a + b
        end
    """

    raise %SyntaxError{
      file: __ENV__.file,
      line: __ENV__.line,
      description: description
    }
  end

  @doc """
  Handle return value from several failible functions.

  Values are extracted from an ok tuple using the in (`<-`) operator.
  Any line using this operator that trys to match on an error tuple will result in early return.

  If all bindings can be made, i.e. all functions returned `{:ok, value}`,
  then the after block is executed to return the final value.

  If any binding fails then the rescue block will be tried.

  *Note: return value from after will be returned unwrapped*

  ## Examples

      iex> OK.try do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 2)
      ...> after
      ...>   a + b
      ...> rescue
      ...>   :zero_division ->
      ...>     :nan
      ...> end
      6.0

      iex> OK.try do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 0)
      ...> after
      ...>   a + b
      ...> rescue
      ...>   :zero_division ->
      ...>     :nan
      ...> end
      :nan
  """
  defmacro try(do: bind_block, after: yield_block, rescue: exception_clauses) do
    {:__block__, _env, bindings} = wrap_code_block(bind_block)

    quote do
      case unquote(expand_bindings(bindings, yield_block)) do
        {:error, reason} ->
          case reason do
            unquote(exception_clauses)
          end

        value ->
          value
      end
    end
  end

  defmacro try(_) do
    description = """
    OK.try/1 requires `do`, `after` and `rescue` clauses. e.g.

        OK.try do
          a <- safe_div(8, 2)
          b <- safe_div(a, 0)
        after
          a + b
        rescue
          :zero_division ->
            :nan
        end
    """

    raise %SyntaxError{
      file: __ENV__.file,
      line: __ENV__.line,
      description: description
    }
  end

  defp wrap_code_block(block = {:__block__, _env, _lines}), do: block

  defp wrap_code_block(expression = {_, env, _}) do
    {:__block__, env, [expression]}
  end

  defp wrap_code_block(literal) do
    {:__block__, [], [literal]}
  end

  defp expand_bindings([{:<-, env, [left, right]} | rest], yield_block) do
    line = Keyword.get(env, :line)

    normal_cases =
      quote line: line do
        {:ok, unquote(left)} ->
          unquote(expand_bindings(rest, yield_block))

        {:error, reason} ->
          {:error, reason}
      end

    warning_case =
      quote line: line, generated: true do
        return ->
          raise %OK.BindError{
            return: return,
            lhs: unquote(Macro.to_string(left)),
            rhs: unquote(Macro.to_string(right))
          }
      end

    quote line: line do
      case unquote(right) do
        unquote(normal_cases ++ warning_case)
      end
    end
  end

  defp expand_bindings([normal | rest], yield_block) do
    quote location: :keep do
      unquote(normal)
      unquote(expand_bindings(rest, yield_block))
    end
  end

  defp expand_bindings([], yield_block) do
    yield_block
  end
end
