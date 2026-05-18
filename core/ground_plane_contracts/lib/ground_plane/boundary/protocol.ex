defmodule GroundPlane.Boundary.Protocol do
  @moduledoc """
  Behaviour for direct-module boundary dispatch.

  Remote transport is intentionally not implemented here. The same envelope and
  result contracts are used by monolith direct calls so a future transport can
  be added without changing the plane contracts.
  """

  alias GroundPlane.Boundary.DispatchResult
  alias GroundPlane.Boundary.Envelope

  @callback dispatch(Envelope.t()) :: {:ok, DispatchResult.t()} | {:error, map()}

  @spec dispatch(module(), Envelope.t()) :: {:ok, DispatchResult.t()} | {:error, term()}
  def dispatch(handler, %Envelope{} = envelope) when is_atom(handler) do
    with true <- function_exported?(handler, :dispatch, 1),
         {:ok, result} <- handler.dispatch(envelope),
         {:ok, result} <- DispatchResult.new(DispatchResult.to_map(result)) do
      {:ok, result}
    else
      false -> {:error, {:boundary_handler_missing, handler}}
      {:error, reason} -> {:error, reason}
      other -> {:error, {:invalid_boundary_dispatch_response, other}}
    end
  end

  def dispatch(_handler, _envelope), do: {:error, :invalid_boundary_dispatch}
end
