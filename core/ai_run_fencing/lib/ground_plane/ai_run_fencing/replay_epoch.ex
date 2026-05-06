defmodule GroundPlane.AIRunFencing.ReplayEpoch do
  @moduledoc """
  Replay epoch fence for replay bundle reuse.
  """

  alias GroundPlane.AIRunFencing.EpochFence

  @spec authorize(map(), DateTime.t()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now) when is_map(attrs) do
    EpochFence.authorize(attrs, now, %{
      family: :replay_epoch,
      stale_reason: :stale_replay_epoch,
      revoked_reason: :replay_epoch_revoked
    })
  end
end
