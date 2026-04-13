defmodule GroundPlane.Contracts.HandoffState do
  @moduledoc """
  Shared handoff lifecycle vocabulary.
  """

  @type t :: String.t()

  @values [
    "pending_local",
    "committed_local",
    "accepted_downstream",
    "started_execution",
    "completed_execution",
    "projected_back",
    "user_notified",
    "dead_letter",
    "superseded",
    "quarantined"
  ]

  @forward_only Map.new(
                  Enum.zip(
                    @values,
                    tl(@values)
                  )
                )

  @spec values() :: [t()]
  def values do
    @values
  end

  @spec valid?(term()) :: boolean()
  def valid?(state) when is_binary(state) do
    state in @values
  end

  def valid?(_state), do: false

  @spec transition_allowed?(t(), t()) :: boolean()
  def transition_allowed?(from, to) when from == to and is_binary(from) do
    valid?(from)
  end

  def transition_allowed?(from, to) when is_binary(from) and is_binary(to) do
    valid?(from) and valid?(to) and Map.get(@forward_only, from) == to
  end

  def transition_allowed?(_from, _to), do: false
end
