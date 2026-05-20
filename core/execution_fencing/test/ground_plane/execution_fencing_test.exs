defmodule GroundPlane.ExecutionFencingTest do
  use ExUnit.Case, async: true

  alias GroundPlane.ExecutionFencing
  alias GroundPlane.ExecutionFencing.CheckpointEpoch
  alias GroundPlane.ExecutionFencing.EndpointLease
  alias GroundPlane.ExecutionFencing.EpochFence
  alias GroundPlane.ExecutionFencing.ResourcePoolLease
  alias GroundPlane.ExecutionFencing.ReplayEpoch
  alias GroundPlane.ExecutionFencing.RunLock

  test "AOC-009 validates run lock lease checkpoint resource pool endpoint and replay fences" do
    now = DateTime.from_unix!(1_700_000_000)

    assert {:ok, receipt} =
             ExecutionFencing.authorize(%{
               tenant_ref: "tenant://adaptive/a",
               execution_ref: "execution://adaptive/run-1",
               run_lock: run_lock(),
               checkpoint_epoch: epoch(:checkpoint),
               endpoint_lease: expiring_lease(now, :endpoint),
               resource_pool_lease: expiring_lease(now, :resource_pool),
               replay_epoch: epoch(:replay),
               checked_at: now
             })

    assert receipt.status == :authorized
    assert receipt.execution_ref == "execution://adaptive/run-1"
    assert receipt.fence_receipts.run_lock.fence_family == :run_lock
    assert receipt.fence_receipts.checkpoint_epoch.fence_family == :checkpoint_epoch
    assert receipt.fence_receipts.endpoint_lease.fence_family == :endpoint_lease
    assert receipt.fence_receipts.resource_pool_lease.fence_family == :resource_pool_lease
    assert receipt.fence_receipts.replay_epoch.fence_family == :replay_epoch

    assert receipt.persistence_posture.persistence_profile_ref ==
             "persistence-profile://mickey_mouse"

    assert receipt.fence_receipts.endpoint_lease.persistence_posture.durable? == false
    refute Map.has_key?(receipt, :payload)
    refute Map.has_key?(receipt, :external_payload)

    assert {:error, {:duplicate_active_run, _details}} =
             RunLock.authorize(%{run_lock() | current_execution_ref: "execution://other"}, now)

    assert {:error, {:stale_checkpoint_epoch, _details}} =
             CheckpointEpoch.authorize(%{epoch(:checkpoint) | observed_epoch: 1}, now)

    assert {:error, {:endpoint_lease_expired, _details}} =
             EndpointLease.authorize(%{expiring_lease(now, :endpoint) | expires_at: now}, now)

    assert {:error, {:resource_pool_lease_revoked, _details}} =
             ResourcePoolLease.authorize(
               Map.merge(expiring_lease(now, :resource_pool), %{
                 revoked_at: now,
                 revocation_ref: "revocation://resource-pool/1"
               }),
               now
             )

    assert {:error, {:stale_replay_epoch, _details}} =
             ReplayEpoch.authorize(%{epoch(:replay) | observed_epoch: 0}, now)
  end

  test "durable execution fence posture does not change authorization semantics" do
    now = DateTime.from_unix!(1_700_000_000)

    assert {:ok, memory} =
             ExecutionFencing.authorize(%{
               tenant_ref: "tenant://adaptive/a",
               execution_ref: "execution://adaptive/run-1",
               run_lock: run_lock(),
               checkpoint_epoch: epoch(:checkpoint),
               endpoint_lease: expiring_lease(now, :endpoint),
               resource_pool_lease: expiring_lease(now, :resource_pool),
               replay_epoch: epoch(:replay),
               checked_at: now
             })

    assert {:ok, durable} =
             ExecutionFencing.authorize(%{
               tenant_ref: "tenant://adaptive/a",
               execution_ref: "execution://adaptive/run-1",
               profile: :integration_postgres,
               run_lock: run_lock(),
               checkpoint_epoch: Map.put(epoch(:checkpoint), :profile, :integration_postgres),
               endpoint_lease:
                 Map.put(expiring_lease(now, :endpoint), :profile, :integration_postgres),
               resource_pool_lease:
                 Map.put(expiring_lease(now, :resource_pool), :profile, :integration_postgres),
               replay_epoch: Map.put(epoch(:replay), :profile, :integration_postgres),
               checked_at: now
             })

    assert Map.drop(memory, [:persistence_posture, :fence_receipts]) ==
             Map.drop(durable, [:persistence_posture, :fence_receipts])

    assert durable.persistence_posture.durable? == true
    assert durable.fence_receipts.endpoint_lease.persistence_posture.durable? == true
  end

  test "epoch compatibility policy denies unknown aliases unless policy admits them" do
    now = DateTime.from_unix!(1_700_000_000)
    default_policy = epoch_policy(:checkpoint_epoch)

    assert {:ok, default_alias} =
             EpochFence.authorize(
               %{epoch(:checkpoint) | fence_family: :checkpoint},
               now,
               default_policy
             )

    assert default_alias.fence_family == :checkpoint_epoch

    unknown_attrs = %{epoch(:checkpoint) | fence_family: :checkpoint_shadow}

    assert {:error,
            {:fence_family_mismatch,
             %{expected: :checkpoint_epoch, actual: :checkpoint_shadow, redacted: true}}} =
             EpochFence.authorize(unknown_attrs, now, default_policy)

    assert {:ok, custom_alias} =
             EpochFence.authorize(
               unknown_attrs,
               now,
               Map.put(default_policy, :compatible_families, %{
                 checkpoint_epoch: [:checkpoint_shadow]
               })
             )

    assert custom_alias.fence_family == :checkpoint_epoch
  end

  defp run_lock do
    %{
      execution_ref: "execution://adaptive/run-1",
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

  defp epoch_policy(family) do
    %{
      family: family,
      stale_reason: :stale_checkpoint_epoch,
      revoked_reason: :checkpoint_epoch_revoked
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
