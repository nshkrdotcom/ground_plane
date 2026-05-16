defmodule GroundPlane.ExecutionFencing.ResourcePoolLease do
  @moduledoc """
  Resource-pool materialization lease fence.
  """

  alias GroundPlane.ExecutionFencing.LeaseFence

  @spec authorize(map(), DateTime.t()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now) when is_map(attrs) do
    LeaseFence.authorize(attrs, now, %{
      family: :resource_pool_lease,
      expired_reason: :resource_pool_lease_expired,
      revoked_reason: :resource_pool_lease_revoked,
      stale_reason: :stale_resource_pool_lease_epoch
    })
  end
end
