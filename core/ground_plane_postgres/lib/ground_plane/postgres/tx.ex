defmodule GroundPlane.Postgres.Tx do
  @moduledoc """
  Thin transaction helper that delegates transaction ownership to the adapter.
  """

  @spec run(module(), (-> term())) :: term()
  def run(adapter, fun) when is_atom(adapter) and is_function(fun, 0) do
    adapter.transaction(fun)
  end
end
