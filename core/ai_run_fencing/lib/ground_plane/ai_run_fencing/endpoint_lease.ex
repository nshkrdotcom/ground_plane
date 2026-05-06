defmodule GroundPlane.AIRunFencing.EndpointLease do
  @moduledoc """
  Endpoint lease fence for self-hosted or local endpoint reuse.
  """

  alias GroundPlane.AIRunFencing.LeaseFence

  @spec authorize(map(), DateTime.t()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now) when is_map(attrs) do
    LeaseFence.authorize(attrs, now, %{
      family: :endpoint_lease,
      expired_reason: :endpoint_lease_expired,
      revoked_reason: :endpoint_lease_revoked,
      stale_reason: :stale_endpoint_lease_epoch
    })
  end
end
