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
  @spec map({:ok, a}, function(a) :: b) :: {:ok, b} when a: any, b: any
  @spec map({:error, reason}, function(any) :: any) :: {:error, reason} when reason: any
  def map({:ok, value}, func) when is_function(func, 1), do: {:ok, func.(value)}
  def map({:error, reason}, _func), do: {:error, reason}

  @doc """
  Takes a result tuple and a next function.
  If the result tuple is tagged as a success then its value will be passed to the next function.
  If the tag is failure then the next function is skipped.

  ## Examples

      iex> OK.bind({:ok, 2}, fn (x) -> {:ok, 2 * x} end)
      {:ok, 4}

      iex> OK.bind({:error, :some_reason}, fn (x) -> {:ok, 2 * x} end)
      {:error, :some_reason}
  """
  # @spec bind({:ok, a} | {:error, reason}, function(a) :: {:ok, b} | {:error, reason}) ::
  #         {:ok, b} | {:error, reason}
  #       when a: any, b: any, reason: term
  # NOTE return value of function is not checked to be a result tuple.
  # errors are informative enough when piped to something else expecting result tuple.
  # Also dialyzer will catch in anonymous function with incorrect typespec is given.
  def bind({:ok, value}, func) when is_function(func, 1), do: func.(value)
  def bind({:error, reason}, _func), do: {:error, reason}

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
  The OK result pipe operator `~>>`, or result monad bind operator, is similar
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
      OK.bind(unquote(lhs), fn unquote(value) -> unquote({call, line, args}) end)
    end
  end

  @doc """
  Composes multiple functions similar to Elixir's native `with` construct.

  `OK.with/1` enables more terse and readable expressions however, eliminating
  noise and regaining precious horizontal real estate. This makes `OK.with`
  statements simpler, more readable, and ultimately more maintainable.

  It does this by extracting result tuples when using the `<-` operator.

      iex> OK.with do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 2)
      ...>   OK.success b
      ...> end
      {:ok, 2.0}

  In above example, the result of each call to `safe_div/2` is an `:ok` tuple
  from which the `<-` extract operator pulls the value and assigns to the
  variable `a`. We then do the same for `b`, and to indicate our return value
  we use the `OK.success/1` macro.

  We could have also written this with a raw `:ok` tuple:

      iex> OK.with do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 2)
      ...>   {:ok, b}
      ...> end
      {:ok, 2.0}

  Or even this:

      iex> OK.with do
      ...>   a <- safe_div(8, 2)
      ...>   _ <- safe_div(a, 2)
      ...> end
      {:ok, 2.0}

  In addition to this, regular matching using the `=` operator is also available:

      iex> OK.with do
      ...>   a <- safe_div(8, 2)
      ...>   b = 2.0
      ...>   OK.success a + b
      ...> end
      {:ok, 6.0}

  Error tuples are returned from the expression:

      iex> OK.with do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 0) # error here
      ...>   {:ok, a + b}        # does not execute this line
      ...> end
      {:error, :zero_division}

  `OK.with` also provides `else` blocks where you can pattern match on the _extracted_ error values, which is useful for wrapping or correcting errors:

      iex> OK.with do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 0) # returns {:error, :zero_division}
      ...>   {:ok, a + b}
      ...> else
      ...>   :zero_division -> OK.failure "You cannot divide by 0."
      ...> end
      {:error, "You cannot divide by 0."}

  ## Combining OK.with and ~>>

  Because the OK.pipe operator (`~>>`) also uses result monads, you can now pipe
  _safely_ within an `OK.with` block:

      iex> OK.with do
      ...>   a <- {:ok, 100}
      ...>        ~>> safe_div(10)
      ...>        ~>> safe_div(5)
      ...>   b <- safe_div(64, 32)
      ...>        ~>> double()
      ...>   OK.success a + b
      ...> end
      {:ok, 6.0}

      iex> OK.with do
      ...>   a <- {:ok, 100}
      ...>        ~>> safe_div(10)
      ...>        ~>> safe_div(0)   # error here
      ...>   b <- safe_div(64, 32)
      ...>        ~>> double()
      ...>   OK.success a + b
      ...> end
      {:error, :zero_division}

  ## Remarks

  Notice that in all of these examples, we know this is a happy path operation
  because we are inside of the `OK.with` block. But it is much more elegant,
  readable and DRY, as it eliminates large numbers of superfluous `:ok` tags
  that would normally be found in native `with` blocks.

  Also, `OK.with` does not have trailing commas on each line. This avoids
  compilation errors when you accidentally forget to add/remove a comma when
  coding.

  Be sure to check out [`ok_test.exs` tests](https://github.com/CrowdHailer/OK/blob/master/test/ok_test.exs)
  for more examples.
  """
  defmacro with(do: code) do
    {:__block__, _env, lines} = wrap_code_block(code)
    return = bind_match(lines)

    quote do
      IO.warn(
        "`OK.with/1` is deprecated. Use instead `OK.try/1` or `OK.for/1`",
        Macro.Env.stacktrace(__ENV__)
      )

      case unquote(return) do
        result = {tag, _} when tag in [:ok, :error] ->
          result
      end
    end
  end

  defmacro with(do: code, else: exceptional) do
    {:__block__, _env, normal} = wrap_code_block(code)

    exceptional_clauses =
      exceptional ++
        quote do
          reason ->
            {:error, reason}
        end

    quote do
      unquote(bind_match(normal))
      |> case do
        {:ok, value} ->
          {:ok, value}

        {:error, reason} ->
          case reason do
            unquote(exceptional_clauses)
          end
          |> case do
            result = {tag, _} when tag in [:ok, :error] ->
              result
          end
      end
    end
  end

  defp wrap_code_block(block = {:__block__, _env, _lines}), do: block

  defp wrap_code_block(expression = {_, env, _}) do
    {:__block__, env, [expression]}
  end

  defp wrap_code_block(literal) do
    {:__block__, [], [literal]}
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

  If any bind fails then the rescue block will be tried.

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

  def wrap({:ok, value}), do: {:ok, value}
  def wrap({:error, reason}), do: {:error, reason}
  def wrap(other), do: {:ok, other}

  defp bind_match([]) do
    quote do: nil
  end

  defp bind_match([{:<-, env, [left, right]} | rest]) do
    line = Keyword.get(env, :line)
    lhs_string = Macro.to_string(left)
    rhs_string = Macro.to_string(right)
    tmp = quote do: tmp

    quote line: line do
      case unquote(tmp) = unquote(right) do
        {:ok, unquote(left)} ->
          unquote(bind_match(rest) || tmp)

        result = {:error, _} ->
          result

        return ->
          raise %OK.BindError{return: return, lhs: unquote(lhs_string), rhs: unquote(rhs_string)}
      end
    end
  end

  defp bind_match([normal | rest]) do
    tmp = quote do: tmp

    quote do
      unquote(tmp) = unquote(normal)
      unquote(bind_match(rest) || tmp)
    end
  end

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

  def map_all(list, fun) do
    result =
      Enum.reduce_while(list, [], fn value, acc ->
        case fun.(value) do
          {:ok, value} ->
            {:cont, [value | acc]}

          {:error, _} = error ->
            {:halt, error}
        end
      end)

    if is_list(result), do: {:ok, Enum.reverse(result)}, else: result
  end
end
