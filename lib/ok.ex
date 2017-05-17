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
  Takes a result tuple and a next function.
  If the result tuple is tagged as a success then its value will be passed to the next function.
  If the tag is failure then the next function is skipped.

  ## Examples

      iex> OK.bind({:ok, 2}, fn (x) -> {:ok, 2 * x} end)
      {:ok, 4}

      iex> OK.bind({:error, :some_reason}, fn (x) -> {:ok, 2 * x} end)
      {:error, :some_reason}
  """
  def bind({:ok, value}, func) when is_function(func, 1), do: func.(value)
  def bind(failure = {:error, _reason}, _func), do: failure

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

  ## Example

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
  defmacro lhs ~>> rhs do
    {call, line, args} = case rhs do
      {call, line, nil} ->
        {call, line, []}
      {call, line, args} when is_list(args) ->
        {call, line, args}
    end
    quote do
      case unquote(lhs) do
        {:ok, value} ->
          unquote({call, line, [{:value, [], OK} | args]})
        {:error, _reason} ->
          unquote(lhs)
      end
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
      case unquote(return) do
        result = {tag, _} when tag in [:ok, :error] ->
          result
      end
    end
  end
  defmacro with(do: code, else: exceptional) do
    {:__block__, _env, normal} = wrap_code_block(code)
    exceptional_clauses = exceptional ++ (quote do
      reason ->
        {:error, reason}
    end)
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

  defmacro def(signature, do: code) do
    {:__block__, _env, lines} = wrap_code_block(code)
    quote do
      Kernel.def unquote(signature) do
        unquote(bind_match(lines))
      end
    end
  end
  defmacro def(signature, do: code, else: exceptional) do
    {:__block__, _env, lines} = wrap_code_block(code)
    quote do
      Kernel.def unquote(signature) do
        unquote(bind_match(lines, exceptional))
      end
    end
  end

  defp wrap_code_block(block = {:__block__, _env, _lines}), do: block
  defp wrap_code_block(expression = {_, env, _}) do
     {:__block__, env, [expression]}
   end
  defp wrap_code_block(primitive) do
     {:__block__, [], [primitive]}
   end

  require Logger

  @doc """
  DEPRECATED: `OK.try` has been replaced with `OK.with`
  """
  defmacro try(do: {:__block__, _env, lines}) do
    Logger.warn("DEPRECATED: `OK.try` has been replaced with `OK.with`")
    bind_match(lines)
  end

  defmodule BindError do
    defexception [:return, :lhs, :rhs]

    def message(%{return: return, lhs: lhs, rhs: rhs}) do
      """
      no binding to right hand side value: '#{inspect(return)}'

          Code
            #{lhs} <- #{rhs}

          Expected signature
            #{rhs} :: {:ok, #{lhs}} | {:error, reason}

          Actual values
            #{rhs} :: #{inspect(return)}
      """
    end
  end

  defp bind_match(code, exceptional \\ nil)
  defp bind_match([], _exceptional) do
    quote do: nil
  end
  defp bind_match([{:<-, env, [left, right]} | rest], exceptional) do
    line = Keyword.get(env, :line)
    lhs_string = Macro.to_string(left)
    rhs_string = Macro.to_string(right)
    tmp = quote do: tmp
    result = quote do: result
    result_handler = if exceptional == nil do
      result
    else
      # TODO link error line number to the bind that triggered it
      [{:->, e, _} | _] = exceptional
      l = Keyword.get(e, :line)
      quote line: l - 1 do
        {:error, reason} = unquote(result)
        case reason do
          unquote(exceptional)
        end
      end
    end
    quote line: line do
      case unquote(tmp) = unquote(right) do
        {:ok, unquote(left)} ->
          unquote(bind_match(rest, exceptional) || tmp)
        unquote(result) = {:error, _} ->
          unquote(result_handler)
        return ->
          raise %BindError{
            return: return,
            lhs: unquote(lhs_string),
            rhs: unquote(rhs_string)}
      end
    end
  end
  defp bind_match([normal | rest], exceptional) do
    tmp = quote do: tmp
    quote do
      unquote(tmp) = unquote(normal)
      unquote(bind_match(rest, exceptional) || tmp)
    end
  end
end
