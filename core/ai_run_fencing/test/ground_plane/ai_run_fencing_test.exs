defmodule GroundPlane.AIRunFencingTest do
  use ExUnit.Case, async: true

  alias GroundPlane.AIRunFencing
  alias GroundPlane.AIRunFencing.CheckpointEpoch
  alias GroundPlane.AIRunFencing.EndpointLease
  alias GroundPlane.AIRunFencing.ProviderPoolLease
  alias GroundPlane.AIRunFencing.ReplayEpoch
  alias GroundPlane.AIRunFencing.RunLock

  test "AOC-009 validates run lock lease checkpoint provider pool endpoint and replay fences" do
    now = DateTime.from_unix!(1_700_000_000)

    assert {:ok, receipt} =
             AIRunFencing.authorize(%{
               tenant_ref: "tenant://adaptive/a",
               ai_run_ref: "ai-run://adaptive/run-1",
               run_lock: run_lock(),
               checkpoint_epoch: epoch(:checkpoint),
               endpoint_lease: expiring_lease(now, :endpoint),
               provider_pool_lease: expiring_lease(now, :provider_pool),
               replay_epoch: epoch(:replay),
               checked_at: now
             })

    assert receipt.status == :authorized
    assert receipt.ai_run_ref == "ai-run://adaptive/run-1"
    assert receipt.fence_receipts.run_lock.fence_family == :run_lock
    assert receipt.fence_receipts.checkpoint_epoch.fence_family == :checkpoint_epoch
    assert receipt.fence_receipts.endpoint_lease.fence_family == :endpoint_lease
    assert receipt.fence_receipts.provider_pool_lease.fence_family == :provider_pool_lease
    assert receipt.fence_receipts.replay_epoch.fence_family == :replay_epoch
    refute Map.has_key?(receipt, :payload)
    refute Map.has_key?(receipt, :provider_payload)

    assert {:error, {:duplicate_active_run, _details}} =
             RunLock.authorize(%{run_lock() | current_execution_ref: "execution://other"}, now)

    assert {:error, {:stale_checkpoint_epoch, _details}} =
             CheckpointEpoch.authorize(%{epoch(:checkpoint) | observed_epoch: 1}, now)

    assert {:error, {:endpoint_lease_expired, _details}} =
             EndpointLease.authorize(%{expiring_lease(now, :endpoint) | expires_at: now}, now)

    assert {:error, {:provider_pool_lease_revoked, _details}} =
             ProviderPoolLease.authorize(
               Map.merge(expiring_lease(now, :provider_pool), %{
                 revoked_at: now,
                 revocation_ref: "revocation://provider-pool/1"
               }),
               now
             )

    assert {:error, {:stale_replay_epoch, _details}} =
             ReplayEpoch.authorize(%{epoch(:replay) | observed_epoch: 0}, now)
  end

  defp run_lock do
    %{
      ai_run_ref: "ai-run://adaptive/run-1",
      idempotency_ref: "idempotency://adaptive/run-1",
      active_execution_ref: "execution://adaptive/run-1/current",
      current_execution_ref: "execution://adaptive/run-1/current",
      lock_epoch: 3
    }
  end

  defp epoch(kind) do
    %{
      fence_family: kind,
      artifact_ref: "#{kind}://adaptive/run-1/current",
      expected_epoch: 3,
      observed_epoch: 3,
      epoch_ref: "epoch://adaptive/run-1/#{kind}/3"
    }
  end

  defp expiring_lease(now, kind) do
    %{
      fence_family: kind,
      lease_ref: "lease://adaptive/run-1/#{kind}/1",
      owner_ref: "owner://adaptive/run-1/#{kind}",
      expires_at: DateTime.add(now, 60, :second),
      lease_epoch: 3,
      fence_epoch: 3
    }
  end
end
