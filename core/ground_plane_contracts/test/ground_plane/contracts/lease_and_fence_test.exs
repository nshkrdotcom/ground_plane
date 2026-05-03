defmodule GroundPlane.Contracts.LeaseAndFenceTest do
  use ExUnit.Case, async: false

  alias GroundPlane.Contracts.EpochRef
  alias GroundPlane.Contracts.Fence
  alias GroundPlane.Contracts.Lease
  alias GroundPlane.Contracts.ResourcePath

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

  test "restart reuse ignores ambient env token auth root and target grant" do
    with_env(
      %{
        "GROUND_PLANE_RESTART_TOKEN" => "fixture-token-not-secret",
        "GROUND_PLANE_AUTH_ROOT" => "env-auth-root",
        "GROUND_PLANE_TARGET_GRANT" => "env-target-grant",
        "GROUND_PLANE_LEASE_ID" => "lease_active"
      },
      fn ->
        now = DateTime.from_unix!(1_700_000_000)

        assert {:ok, lease} =
                 Lease.new(%{
                   resource: "semantic:session:1",
                   holder: "node-a",
                   lease_id: "lease_active",
                   epoch: 4,
                   expires_at: DateTime.add(now, 30, :second)
                 })

        mismatched_fence = %Fence{Fence.from_lease(lease) | holder: "node-b"}

        assert {:error, {:lease_holder_mismatch_after_restart, details}} =
                 Fence.authorize_restart_reuse(lease, mismatched_fence, now)

        assert details.holder == "node-a"
        refute Map.has_key?(details, :token)
        refute Map.has_key?(details, :auth_root)
        refute Map.has_key?(details, :target_grant)
      end
    )
  end

  test "revoked and rotated leases do not rehydrate ambient env material" do
    with_env(
      %{
        "GROUND_PLANE_REVOKED_AT" => "2026-05-03T00:00:00Z",
        "GROUND_PLANE_REVOCATION_REF" => "revocation://env/ignored",
        "GROUND_PLANE_ROTATED_LEASE_ID" => "lease_rotated_from_env"
      },
      fn ->
        now = DateTime.from_unix!(1_700_000_000)

        assert {:ok, active_lease} =
                 Lease.new(%{
                   resource: "semantic:session:1",
                   holder: "node-a",
                   lease_id: "lease_active",
                   epoch: 4,
                   expires_at: DateTime.add(now, 30, :second)
                 })

        refute Lease.revoked?(active_lease)
        assert active_lease.lease_id == "lease_active"
        assert active_lease.revocation_ref == nil

        assert {:error, :revoked_lease_missing_ref} =
                 Lease.new(%{
                   resource: "semantic:session:1",
                   holder: "node-a",
                   lease_id: "lease_revoked",
                   epoch: 4,
                   expires_at: DateTime.add(now, 30, :second),
                   revoked_at: now
                 })
      end
    )
  end

  test "ambient tenant env cannot fill lower tenant-scoped refs" do
    with_env(%{"GROUND_PLANE_TENANT_ID" => "tenant-from-env"}, fn ->
      assert {:error, {:missing_required_fields, [:tenant_id]}} =
               ResourcePath.new(%{
                 segments: ["workflow", "resource-work-1"],
                 resource_kind_path: ["workflow"],
                 terminal_resource_id: "resource-work-1"
               })

      assert {:error, {:missing_required_fields, [:tenant_id]}} =
               EpochRef.new(%{
                 epoch_ref: "epoch-1",
                 resource_id: "resource-work-1",
                 epoch: 1,
                 trace_id: "trace-109"
               })
    end)
  end

  defp with_env(vars, fun) when is_map(vars) and is_function(fun, 0) do
    previous = Map.new(vars, fn {name, _value} -> {name, System.get_env(name)} end)

    Enum.each(vars, fn {name, value} -> System.put_env(name, value) end)

    try do
      fun.()
    after
      Enum.each(previous, fn
        {name, nil} -> System.delete_env(name)
        {name, value} -> System.put_env(name, value)
      end)
    end
  end
end
