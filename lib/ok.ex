defmodule OK do
  @moduledoc """
  The `OK` module enables clean and expressive error handling in pipelines.

  Many Elixir libraries follow the tagged tuple convention for functions that will not alway return a valid response.
  In case of a success the value is returned in an `:ok` tagged tuple.
  If the function fails then a reason is returned in an `:error` tagged tuple.

  Calling code the matches on these two possible outcomes.

  ```elixir
  case my_func(args) do
    {:ok, value} ->
      do_more(value) # continue with subsequent processing
    {:error, reason} ->
      {:error, reason} # return early.
  end
  ```

  `OK` allows this code to be replaced by a result pipeline.

  ```elixir
  my_func(args)
  ~>> do_more
  ```

  *`OK` treates the combination of tagged tuples `{:ok, value} | {:error, reason}` as a result monad.
  The result monad is sometimes know as the try or either monad.*
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
  Result pipe operator.
  (Result monad bind operator)

  The result pipe takes the value out of an `{:ok, value}` tuple and passes it as the first argument to the function call on the right.

  ## Examples

      iex> {:ok, 5} ~>> double()
      {:ok, 10}

      iex> {:error, :previous_bad} ~>> double()
      {:error, :previous_bad}

      # x is {:ok, 7} defined in `OKTest`.
      iex> x() ~>> double()
      {:ok, 14}

  The result pipe is most useful when executing a series of operations that may fail.

      iex> {:ok, 6} ~>> safe_div(3) ~>> double
      {:ok, 4.0}

      iex> {:ok, 6} ~>> safe_div(0) ~>> double
      {:error, :zero_division}

  It can be used in several ways.
  Pipe to a local call.
  This example is the same as calling `double(5)`

      iex> {:ok, 5} ~>> double
      {:ok, 10}

  Pipe to a remote call.
  This example is the same as calling `OKTest.double(3)`

      iex> {:ok, 5} ~>> OKTest.double()
      {:ok, 10}

      iex> {:ok, 5} ~>> __MODULE__.double()
      {:ok, 10}

  Pipe with extra arguments
  This example is the same as calling `OK.safe_div(3, 4)`

      iex> {:ok, 6} ~>> safe_div(2)
      {:ok, 3.0}

      iex> {:ok, 6} ~>> safe_div(0)
      {:error, :zero_division}

  Given an anonymous function the following syntax needs to be used.

      iex> {:ok, 3} ~>> (fn (x) -> {:ok, x + 1} end).()
      {:ok, 4}

      # decrement returns an anonymous function.
      # weird I know but was needed as a test case
      iex> {:ok, 6} ~>> decrement().(2)
      {:ok, 4}
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
  noise and regaining precious horizontal real estate in the process. It does 
  this by extracting result tuples when using the `<-` operator.
  
  For example, in native Elixir, you could write a `with` statement as follows:
  
  ```elixir
  with {:ok, a} <- safe_div(8,2),
       {:ok, b} <- safe_div(a,2),
       do: {:ok, b}
  ```
  
  With `OK.with/1`, this can be rewritten as follows:
  ```elixir
  OK.with do
    a <- safe_div(8,2)
    b <- safe_div(a,2)
    {:ok, b}
  end
  ```

  ### Compared to `~>>`
  
  When combining functions that may fail, the OK pipe operator is inflexible in
  a couple areas: 
  - values can only be passed to the first argument of a function.
  - values can only be passed to the next function.

  These limitations can be overcome by `OK.with/1`.

  ## Examples

      iex> OK.with do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 2)
      ...>   {:ok, a + b}
      ...> end
      {:ok, 6.0}

      iex> OK.with do
      ...>   a <- safe_div(8, 2)
      ...>   b <- safe_div(a, 0)
      ...>   {:ok, a + b}
      ...> end
      {:error, :zero_division}
  """
  defmacro with(do: {:__block__, _env, lines}) do
    nest(lines)
  end
  defmacro with(do: {:__block__, _, normal}, else: exceptional) do
    exceptional_clauses = exceptional ++ (quote do
      reason ->
        {:error, reason}
    end)
    quote do
      unquote(nest(normal))
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

  require Logger

  @doc false
  defmacro try(do: {:__block__, _env, lines}) do
    Logger.warn("DEPRECIATED: `OK.try` has been replaced with `OK.with`")
    nest(lines)
  end

  defp nest([{:<-, _, [left, right]} | []]) do
    quote do
      case unquote(right) do
        result = {:ok, unquote(left)} ->
          result
        result = {:error, _} ->
          result
      end
    end
  end
  defp nest([{:<-, _, [left, right]} | rest]) do
    quote do
      case unquote(right) do
        {:ok, unquote(left)} ->
          unquote(nest(rest))
        result = {:error, _} ->
          result
      end
    end
  end
  defp nest([normal | []]) do
    quote do
      case unquote(normal) do
        {:ok, value} ->
          {:ok, value}
        {:error, reason} ->
          {:error, reason}
      end
    end
  end
  defp nest([normal | rest]) do
    quote do
      unquote(normal)
      unquote(nest(rest))
    end
  end
end
