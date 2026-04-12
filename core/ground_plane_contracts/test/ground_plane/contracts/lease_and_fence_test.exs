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
end
