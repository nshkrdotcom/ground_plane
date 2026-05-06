defmodule GroundPlane.AIRunFencing.ProviderPoolLease do
  @moduledoc """
  Provider-pool materialization lease fence.
  """

  alias GroundPlane.AIRunFencing.LeaseFence

  @spec authorize(map(), DateTime.t()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now) when is_map(attrs) do
    LeaseFence.authorize(attrs, now, %{
      family: :provider_pool_lease,
      expired_reason: :provider_pool_lease_expired,
      revoked_reason: :provider_pool_lease_revoked,
      stale_reason: :stale_provider_pool_lease_epoch
    })
  end
end
