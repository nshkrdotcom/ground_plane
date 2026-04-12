defmodule GroundPlane.Projection.Publication do
  @moduledoc """
  Helpers for building and publishing normalized projection records.
  """

  alias GroundPlane.Contracts.Id

  @spec build(String.t(), String.t(), term(), keyword()) :: map()
  def build(name, operation, payload, opts \\ [])
      when is_binary(name) and is_binary(operation) do
    %{
      publication_id: Keyword.get(opts, :publication_id, Id.random("projection")),
      name: name,
      operation: operation,
      payload: payload,
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @spec publish(module(), map()) :: {:ok, term()} | {:error, term()}
  def publish(adapter, publication) when is_atom(adapter) and is_map(publication) do
    adapter.publish(publication)
  end
end
