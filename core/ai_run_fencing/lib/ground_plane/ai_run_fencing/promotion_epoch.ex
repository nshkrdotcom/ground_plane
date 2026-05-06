defmodule GroundPlane.AIRunFencing.PromotionEpoch do
  @moduledoc """
  Promotion epoch fence for shadow, canary, promotion, and rollback state.
  """

  alias GroundPlane.AIRunFencing.EpochFence

  @spec authorize(map(), DateTime.t()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now) when is_map(attrs) do
    EpochFence.authorize(attrs, now, %{
      family: :promotion_epoch,
      stale_reason: :stale_promotion_epoch,
      revoked_reason: :promotion_epoch_revoked
    })
  end
end
