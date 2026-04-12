defmodule GroundPlane.Postgres.Outbox do
  @moduledoc """
  Generic outbox row helpers.
  """

  alias GroundPlane.Contracts.Id

  @spec new_entry(String.t(), map(), keyword()) :: map()
  def new_entry(topic, payload, opts \\ []) when is_binary(topic) and is_map(payload) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    %{
      entry_id: Id.random("outbox"),
      topic: topic,
      payload: payload,
      dedupe_key: Keyword.get(opts, :dedupe_key, Id.random("dedupe")),
      state: "pending",
      attempt_count: 0,
      inserted_at: now
    }
  end

  @spec mark_dispatched(map(), DateTime.t()) :: map()
  def mark_dispatched(entry, %DateTime{} = now) do
    entry
    |> Map.put(:state, "dispatched")
    |> Map.put(:attempt_count, entry.attempt_count + 1)
    |> Map.put(:dispatched_at, now)
  end

  @spec mark_completed(map(), DateTime.t()) :: map()
  def mark_completed(entry, %DateTime{} = now) do
    entry
    |> Map.put(:state, "completed")
    |> Map.put(:completed_at, now)
  end
end
