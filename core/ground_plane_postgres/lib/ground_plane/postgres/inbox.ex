defmodule GroundPlane.Postgres.Inbox do
  @moduledoc """
  Generic inbox row helpers.
  """

  alias GroundPlane.Contracts.Id

  @spec new_entry(String.t(), map(), keyword()) :: map()
  def new_entry(source, payload, opts \\ []) when is_binary(source) and is_map(payload) do
    %{
      receipt_id: Id.random("inbox"),
      source: source,
      payload: payload,
      idempotency_key: Keyword.get(opts, :idempotency_key, Id.random("receipt")),
      state: "received"
    }
  end

  @spec mark_applied(map(), DateTime.t()) :: map()
  def mark_applied(entry, %DateTime{} = now) do
    entry
    |> Map.put(:state, "applied")
    |> Map.put(:applied_at, now)
  end
end
