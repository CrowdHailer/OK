defmodule OK.BindError do
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
