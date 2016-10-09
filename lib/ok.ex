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
  def success(value), do: {:ok, value}

  @doc """
  Creates a failed result tuple with the given reason.

  ## Examples

      iex> OK.failure("reason")
      {:error, "reason"}
  """
  def failure(reason), do: {:error, reason}

  @doc """
  Result pipe operator.
  (Result monad bind operator)

  The result pipe takes the value out of an `{:ok, value}` tuple and passes it as the first argument to the function call on the right.

  ## Examples

      iex> {:ok, 5} ~>> double()
      {:ok, 10}

      iex> {:error, :previous_bad} ~>> double()
      {:error, :previous_bad}

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
end
