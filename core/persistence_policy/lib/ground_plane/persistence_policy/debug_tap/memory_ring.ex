defmodule GroundPlane.PersistencePolicy.DebugTap.MemoryRing do
  @moduledoc "Bounded in-memory debug tap for redacted metadata."
  @behaviour GroundPlane.PersistencePolicy.DebugTap

  alias GroundPlane.PersistencePolicy.Redaction

  defstruct limit: 32, events: []

  @type t :: %__MODULE__{limit: pos_integer(), events: [map()]}

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    limit = Keyword.get(opts, :limit, 32)
    %__MODULE__{limit: max(limit, 1), events: []}
  end

  @impl true
  def emit(%__MODULE__{} = tap, event) when is_map(event) do
    with :ok <- Redaction.validate_event(event) do
      event = normalize_event(event)
      {:ok, %{tap | events: keep_latest(tap.events ++ [event], tap.limit)}}
    end
  end

  def emit(%__MODULE__{} = _tap, _event), do: {:error, :invalid_debug_event}

  defp normalize_event(event) do
    %{
      safe_ref: value(event, :safe_ref),
      hash_ref: value(event, :hash_ref),
      metadata: value(event, :metadata) || %{}
    }
  end

  defp keep_latest(events, limit) do
    events
    |> Enum.reverse()
    |> Enum.take(limit)
    |> Enum.reverse()
  end

  defp value(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} -> value
      :error -> Map.get(attrs, Atom.to_string(field))
    end
  end
end
