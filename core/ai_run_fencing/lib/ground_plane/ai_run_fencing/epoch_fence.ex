defmodule GroundPlane.AIRunFencing.EpochFence do
  @moduledoc false

  alias GroundPlane.AIRunFencing.Validation
  alias GroundPlane.Contracts.PersistencePosture

  @required_refs [:artifact_ref, :epoch_ref]

  @spec authorize(map(), DateTime.t(), map()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now, policy) when is_map(attrs) and is_map(policy) do
    family = Map.fetch!(policy, :family)
    stale_reason = Map.fetch!(policy, :stale_reason)
    revoked_reason = Map.fetch!(policy, :revoked_reason)

    with :ok <- Validation.require_non_empty_refs(attrs, @required_refs),
         {:ok, expected_epoch} <- Validation.fetch_non_negative_integer(attrs, :expected_epoch),
         {:ok, observed_epoch} <- Validation.fetch_non_negative_integer(attrs, :observed_epoch),
         :ok <- ensure_family(attrs, family),
         :ok <- ensure_not_revoked(attrs, revoked_reason, now),
         :ok <- ensure_epoch_current(attrs, expected_epoch, observed_epoch, stale_reason, now) do
      {:ok, receipt(attrs, family, expected_epoch, observed_epoch, now)}
    end
  end

  defp ensure_family(attrs, family) do
    actual = Map.get(attrs, :fence_family)

    if is_nil(actual) or actual == family or compatible_family?(actual, family) do
      :ok
    else
      {:error, {:fence_family_mismatch, %{expected: family, actual: actual, redacted: true}}}
    end
  end

  defp compatible_family?(:checkpoint, :checkpoint_epoch), do: true
  defp compatible_family?(:replay, :replay_epoch), do: true
  defp compatible_family?(:promotion, :promotion_epoch), do: true
  defp compatible_family?(_actual, _family), do: false

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

  defp ensure_epoch_current(attrs, expected, observed, reason, now) do
    if expected == observed do
      :ok
    else
      {:error,
       {reason,
        Map.merge(details(attrs, now), %{expected_epoch: expected, observed_epoch: observed})}}
    end
  end

  defp receipt(attrs, family, expected_epoch, observed_epoch, now) do
    %{
      status: :authorized,
      fence_family: family,
      artifact_ref: Validation.fetch_string!(attrs, :artifact_ref),
      epoch_ref: Validation.fetch_string!(attrs, :epoch_ref),
      expected_epoch: expected_epoch,
      observed_epoch: observed_epoch,
      checked_at: now,
      persistence_posture: PersistencePosture.resolve(:revocation_epoch, attrs),
      redacted: true
    }
  end

  defp details(attrs, now) do
    attrs
    |> Map.take([
      :artifact_ref,
      :epoch_ref,
      :expected_epoch,
      :observed_epoch,
      :revocation_ref,
      :fence_family
    ])
    |> Map.merge(%{
      checked_at: now,
      persistence_posture: PersistencePosture.resolve(:revocation_epoch, attrs),
      redacted: true
    })
  end
end
