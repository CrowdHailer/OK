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
  ~>> &do_more/1
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

  defmacro lhs ~>> rhs do
    quote bind_quoted: [lhs: lhs, rhs: rhs] do
      OK.bind(lhs, rhs)
    end
  end
end
