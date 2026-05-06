defmodule GroundPlane.AIRunFencing.LeaseFence do
  @moduledoc false

  alias GroundPlane.AIRunFencing.Validation

  @required_refs [:lease_ref, :owner_ref]

  @spec authorize(map(), DateTime.t(), map()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now, policy) when is_map(attrs) and is_map(policy) do
    family = Map.fetch!(policy, :family)
    expired_reason = Map.fetch!(policy, :expired_reason)
    revoked_reason = Map.fetch!(policy, :revoked_reason)
    stale_reason = Map.fetch!(policy, :stale_reason)

    with :ok <- Validation.require_non_empty_refs(attrs, @required_refs),
         {:ok, expires_at} <- Validation.fetch_datetime(attrs, :expires_at),
         {:ok, lease_epoch} <- Validation.fetch_non_negative_integer(attrs, :lease_epoch),
         {:ok, fence_epoch} <- Validation.fetch_non_negative_integer(attrs, :fence_epoch),
         :ok <- ensure_not_revoked(attrs, revoked_reason, now),
         :ok <- ensure_not_expired(attrs, expires_at, expired_reason, now),
         :ok <- ensure_epoch_current(attrs, lease_epoch, fence_epoch, stale_reason, now) do
      {:ok, receipt(attrs, family, lease_epoch, fence_epoch, expires_at, now)}
    end
  end

  defp ensure_not_revoked(attrs, reason, now) do
    case Map.get(attrs, :revoked_at) do
      nil ->
        :ok

      %DateTime{} ->
        {:error, {reason, details(attrs, now)}}

      _other ->
        {:error, {:invalid_revoked_at, details(attrs, now)}}
    end
  end

  defp ensure_not_expired(attrs, expires_at, reason, now) do
    if DateTime.compare(expires_at, now) == :gt do
      :ok
    else
      {:error, {reason, details(attrs, now)}}
    end
  end

  defp ensure_epoch_current(attrs, lease_epoch, fence_epoch, reason, now) do
    if lease_epoch == fence_epoch do
      :ok
    else
      {:error,
       {reason,
        Map.merge(details(attrs, now), %{lease_epoch: lease_epoch, fence_epoch: fence_epoch})}}
    end
  end

  defp receipt(attrs, family, lease_epoch, fence_epoch, expires_at, now) do
    %{
      status: :authorized,
      fence_family: family,
      lease_ref: Validation.fetch_string!(attrs, :lease_ref),
      owner_ref: Validation.fetch_string!(attrs, :owner_ref),
      lease_epoch: lease_epoch,
      fence_epoch: fence_epoch,
      expires_at: expires_at,
      checked_at: now,
      redacted: true
    }
  end

  defp details(attrs, now) do
    attrs
    |> Map.take([
      :lease_ref,
      :owner_ref,
      :lease_epoch,
      :fence_epoch,
      :revocation_ref,
      :fence_family
    ])
    |> Map.merge(%{checked_at: now, redacted: true})
  end
end
