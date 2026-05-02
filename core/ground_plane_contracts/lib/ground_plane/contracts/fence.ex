defmodule GroundPlane.Contracts.Fence do
  @moduledoc """
  Struct and comparison helpers for fenced ownership.
  """

  alias GroundPlane.Contracts.Lease

  defstruct [:resource, :holder, :lease_id, :epoch]

  @type t :: %__MODULE__{
          resource: String.t(),
          holder: String.t(),
          lease_id: String.t(),
          epoch: non_neg_integer()
        }

  @spec from_lease(Lease.t()) :: t()
  def from_lease(%Lease{} = lease) do
    %__MODULE__{
      resource: lease.resource,
      holder: lease.holder,
      lease_id: lease.lease_id,
      epoch: lease.epoch
    }
  end

  @spec newer_than?(t(), t()) :: boolean()
  def newer_than?(%__MODULE__{epoch: left}, %__MODULE__{epoch: right}) do
    left > right
  end

  @spec authorize_restart_reuse(Lease.t(), t(), DateTime.t()) ::
          {:ok, map()} | {:error, {atom(), map()}}
  def authorize_restart_reuse(%Lease{} = lease, %__MODULE__{} = fence, %DateTime{} = now) do
    details = restart_details(lease, fence, now)

    cond do
      lease.resource != fence.resource ->
        {:error, {:lease_resource_mismatch_after_restart, details}}

      lease.holder != fence.holder ->
        {:error, {:lease_holder_mismatch_after_restart, details}}

      lease.lease_id != fence.lease_id ->
        {:error, {:lease_id_mismatch_after_restart, details}}

      Lease.revoked?(lease) ->
        {:error, {:lease_revoked_after_restart, details}}

      Lease.expired?(lease, now) ->
        {:error, {:lease_expired_after_restart, details}}

      fence.epoch > lease.epoch ->
        {:error, {:stale_lease_epoch_after_restart, details}}

      lease.epoch > fence.epoch ->
        {:error, {:stale_fence_epoch_after_restart, details}}

      true ->
        {:ok, details}
    end
  end

  defp restart_details(%Lease{} = lease, %__MODULE__{} = fence, %DateTime{} = now) do
    %{
      resource: lease.resource,
      holder: lease.holder,
      lease_id: lease.lease_id,
      lease_epoch: lease.epoch,
      fence_epoch: fence.epoch,
      checked_at: now,
      revoked_at: lease.revoked_at,
      revocation_ref: lease.revocation_ref
    }
  end
end
