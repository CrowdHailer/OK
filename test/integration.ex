defmodule OK.Integration do
  require OK
  import OK, only: [~>: 2, ~>>: 2]

  def run() do
    OK.success("a,b")
    ~> String.split()

    OK.failure(:some_error)
    ~> String.split()

    # TODO this should raise error
    :x =
      OK.success(5)
      ~>> safe_div(0)

    OK.failure(:some_error)
    ~>> safe_div(0)

    # nested = %{a: %{b: 5}}

    # OK.try do
    #   map_a <- fetch_key(%{}, :a)
    #   value <- fetch_key(map_a, :b)
    # after
    #   value
    # rescue
    #   _ ->
    #     :bob
    # end
  end

  # defp fetch_key(map, key) do
  #   case Map.fetch(map, key) do
  #     {:ok, value} ->
  #       {:ok, value}
  #
  #     :error ->
  #       {:error, :missing_key}
  #   end
  # end

  @spec safe_div(integer, integer) :: {:ok, float} | {:error, :zero_division}
  def safe_div(_, 0) do
    {:error, :zero_division}
  end

  def safe_div(a, b) do
    {:ok, a / b}
  end
end
