defmodule GroundPlane.Contracts.LeaseAndFenceTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.Fence
  alias GroundPlane.Contracts.Lease

  test "builds a lease and checks expiration" do
    now = DateTime.from_unix!(1_700_000_000)
    later = DateTime.add(now, 30, :second)

    assert {:ok, lease} =
             Lease.new(%{
               resource: "semantic:session:1",
               holder: "node-a",
               lease_id: "lease_123",
               epoch: 4,
               expires_at: later
             })

    refute Lease.expired?(lease, now)
    assert Lease.expired?(lease, DateTime.add(later, 1, :second))
  end

  test "derives fences from leases and compares epochs" do
    assert {:ok, older_lease} =
             Lease.new(%{
               resource: "semantic:session:1",
               holder: "node-a",
               lease_id: "lease_older",
               epoch: 3,
               expires_at: DateTime.from_unix!(1_700_000_010)
             })

    assert {:ok, newer_lease} =
             Lease.new(%{
               resource: "semantic:session:1",
               holder: "node-b",
               lease_id: "lease_newer",
               epoch: 4,
               expires_at: DateTime.from_unix!(1_700_000_020)
             })

    assert Fence.newer_than?(Fence.from_lease(newer_lease), Fence.from_lease(older_lease))
  end

  test "restart reuse rejects revoked expired or stale lease fences" do
    now = DateTime.from_unix!(1_700_000_000)
    later = DateTime.add(now, 30, :second)

    assert {:ok, active_lease} =
             Lease.new(%{
               resource: "semantic:session:1",
               holder: "node-a",
               lease_id: "lease_active",
               epoch: 4,
               expires_at: later
             })

    active_fence = Fence.from_lease(active_lease)

    assert {:ok, %{lease_id: "lease_active", lease_epoch: 4, fence_epoch: 4}} =
             Fence.authorize_restart_reuse(active_lease, active_fence, now)

    assert {:ok, revoked_lease} =
             Lease.new(%{
               resource: "semantic:session:1",
               holder: "node-a",
               lease_id: "lease_revoked",
               epoch: 4,
               expires_at: later,
               revoked_at: now,
               revocation_ref: "revocation://semantic/session/1"
             })

    assert {:error, {:lease_revoked_after_restart, revoked_details}} =
             Fence.authorize_restart_reuse(revoked_lease, Fence.from_lease(revoked_lease), now)

    assert revoked_details.revocation_ref == "revocation://semantic/session/1"

    assert {:error, {:lease_expired_after_restart, expired_details}} =
             Fence.authorize_restart_reuse(
               active_lease,
               active_fence,
               DateTime.add(later, 1, :second)
             )

    assert expired_details.lease_id == "lease_active"

    stale_fence = %Fence{active_fence | epoch: 5}

    assert {:error, {:stale_lease_epoch_after_restart, stale_details}} =
             Fence.authorize_restart_reuse(active_lease, stale_fence, now)

    assert stale_details.lease_epoch == 4
    assert stale_details.fence_epoch == 5
  end
end
