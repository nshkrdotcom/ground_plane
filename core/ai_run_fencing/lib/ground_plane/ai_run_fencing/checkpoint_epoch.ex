defmodule GroundPlane.AIRunFencing.CheckpointEpoch do
  @moduledoc """
  Checkpoint epoch fence for adaptive run checkpoint reuse.
  """

  alias GroundPlane.AIRunFencing.EpochFence

  @spec authorize(map(), DateTime.t()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now) when is_map(attrs) do
    EpochFence.authorize(attrs, now, %{
      family: :checkpoint_epoch,
      stale_reason: :stale_checkpoint_epoch,
      revoked_reason: :checkpoint_epoch_revoked
    })
  end
end
