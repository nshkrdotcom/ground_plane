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

  test "credential lease scope rejects mismatched provider, operation, target, policy, rotation, and fence" do
    now = DateTime.from_unix!(1_700_000_000)

    assert {:ok, lease} = Lease.new(credential_lease_attrs(now))
    fence = Fence.from_lease(lease)

    assert {:ok, evidence} =
             Fence.authorize_credential_materialization(
               lease,
               fence,
               credential_context(%{}),
               now
             )

    assert evidence.provider_family == "codex"
    refute Map.has_key?(evidence, :payload)

    assert {:error, {:provider_account_mismatch, _details}} =
             Fence.authorize_credential_materialization(
               lease,
               fence,
               credential_context(%{provider_account_ref: "provider-account://tenant-1/codex/b"}),
               now
             )

    assert {:error, {:operation_class_mismatch, _details}} =
             Fence.authorize_credential_materialization(
               lease,
               fence,
               credential_context(%{operation_class: "http"}),
               now
             )

    assert {:error, {:stale_policy_revision, _details}} =
             Fence.authorize_credential_materialization(
               lease,
               fence,
               credential_context(%{policy_revision_ref: "policy-revision://tenant-1/codex/2"}),
               now
             )

    assert {:error, {:stale_installation_revision, _details}} =
             Fence.authorize_credential_materialization(
               lease,
               fence,
               credential_context(%{
                 installation_revision_ref: "installation-revision://tenant-1/app/2"
               }),
               now
             )

    assert {:error, {:rotation_epoch_mismatch, _details}} =
             Fence.authorize_credential_materialization(
               lease,
               fence,
               credential_context(%{rotation_epoch: 2}),
               now
             )

    assert {:error, {:stale_target_grant, _details}} =
             Fence.authorize_credential_materialization(
               lease,
               fence,
               credential_context(%{
                 target_grant_revision: "target-grant-revision://tenant-1/sandbox/2"
               }),
               now
             )

    assert {:error, {:fence_token_mismatch, _details}} =
             Fence.authorize_credential_materialization(
               lease,
               %Fence{fence | fence_token: "fence://tenant-1/codex/a/2"},
               credential_context(%{}),
               now
             )
  end

  test "retry dispatch revalidates lease, target, idempotency, and materialization state" do
    now = DateTime.from_unix!(1_700_000_000)

    assert {:ok, lease} = Lease.new(credential_lease_attrs(now))
    fence = Fence.from_lease(lease)

    assert {:ok, retry} =
             Fence.authorize_retry_dispatch(
               lease,
               fence,
               retry_context(%{}),
               now
             )

    assert retry.retry_dispatch_status == :authorized_revalidated
    assert retry.idempotency_key == "idem://tenant-1/codex/retry-1"
    assert retry.active_execution_ref == "execution://tenant-1/codex/active-1"
    assert retry.restart_event == :workflow_resume
    refute Map.has_key?(retry, :payload)

    assert {:error, {:duplicate_active_execution_after_restart, _details}} =
             Fence.authorize_retry_dispatch(
               lease,
               fence,
               retry_context(%{current_execution_ref: "execution://tenant-1/codex/other"}),
               now
             )

    assert {:error, {:stale_materialization_epoch_after_restart, _details}} =
             Fence.authorize_retry_dispatch(
               lease,
               fence,
               retry_context(%{materialization_epoch: 0}),
               now
             )

    assert {:error, {:duplicate_dispatch_old_lease_reuse, _details}} =
             Fence.authorize_retry_dispatch(
               lease,
               fence,
               retry_context(%{
                 materialized_credential_lease_ref: "credential-lease://tenant-1/codex/old"
               }),
               now
             )
  end

  test "restart event lanes revalidate or fail closed before materialized credential reuse" do
    now = DateTime.from_unix!(1_700_000_000)

    assert {:ok, lease} = Lease.new(credential_lease_attrs(now))
    fence = Fence.from_lease(lease)

    for event <- [
          :target_detach,
          :sandbox_restart,
          :process_crash,
          :stream_reconnect,
          :workflow_resume
        ] do
      assert {:ok, result} =
               Fence.authorize_retry_dispatch(
                 lease,
                 fence,
                 retry_context(%{restart_event: event}),
                 now
               )

      assert result.restart_event == event
    end

    assert {:error, {:unsupported_restart_revalidation_event, details}} =
             Fence.authorize_retry_dispatch(
               lease,
               fence,
               retry_context(%{restart_event: :dump_previous_token}),
               now
             )

    assert details.restart_event == :dump_previous_token
  end

  test "credential lease cleanup emits terminal redacted evidence only" do
    now = DateTime.from_unix!(1_700_000_000)
    expired_at = DateTime.add(now, -1, :second)

    assert {:ok, expired_lease} =
             credential_lease_attrs(now)
             |> Map.put(:expires_at, expired_at)
             |> Lease.new()

    assert {:ok, cleanup} =
             Lease.cleanup_event(expired_lease, %{
               cleanup_ref: "cleanup://tenant-1/codex/lease-1",
               cleaned_at: now
             })

    assert cleanup.status == :cleaned
    assert cleanup.credential_lease_ref == "credential-lease://tenant-1/codex/a/1"
    refute Map.has_key?(cleanup, :payload)

    assert {:error, :active_lease_cleanup_rejected} =
             credential_lease_attrs(now)
             |> Lease.new()
             |> then(fn {:ok, active_lease} ->
               Lease.cleanup_event(active_lease, %{
                 cleanup_ref: "cleanup://tenant-1/codex/lease-active",
                 cleaned_at: now
               })
             end)
  end

  test "persistence posture changes storage refs without changing fence decisions" do
    now = DateTime.from_unix!(1_700_000_000)

    assert {:ok, memory_lease} = Lease.new(credential_lease_attrs(now))

    assert {:ok, durable_lease} =
             credential_lease_attrs(now)
             |> Map.put(:profile, :integration_postgres)
             |> Lease.new()

    memory_fence = Fence.from_lease(memory_lease)
    durable_fence = Fence.from_lease(durable_lease)

    assert memory_lease.persistence_posture.persistence_profile_ref ==
             "persistence-profile://mickey_mouse"

    assert durable_lease.persistence_posture.persistence_tier_ref ==
             "persistence-tier://postgres_shared"

    assert {:ok, memory_result} =
             Fence.authorize_credential_materialization(
               memory_lease,
               memory_fence,
               credential_context(%{}),
               now
             )

    assert {:ok, durable_result} =
             Fence.authorize_credential_materialization(
               durable_lease,
               durable_fence,
               credential_context(%{}),
               now
             )

    assert Map.drop(memory_result, [:persistence_posture]) ==
             Map.drop(durable_result, [:persistence_posture])

    assert durable_result.persistence_posture.durable? == true
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

  defp credential_lease_attrs(now) do
    %{
      resource: "credential:codex:tenant-1:account-a",
      holder: "materializer-a",
      lease_id: "lease_active",
      epoch: 4,
      expires_at: DateTime.add(now, 30, :second),
      tenant_id: "tenant-1",
      subject_ref: "subject://tenant-1/codex/user-a",
      provider_family: "codex",
      provider_account_ref: "provider-account://tenant-1/codex/account-a",
      connector_instance_ref: "connector-instance://tenant-1/codex/a",
      credential_handle_ref: "credential-handle://tenant-1/codex/account-a",
      credential_lease_ref: "credential-lease://tenant-1/codex/a/1",
      operation_class: "cli",
      target_ref: "target://tenant-1/sandbox/a",
      attach_grant_ref: "attach-grant://tenant-1/sandbox/a",
      operation_policy_ref: "operation-policy://tenant-1/codex/run",
      installation_revision_ref: "installation-revision://tenant-1/app/1",
      policy_revision_ref: "policy-revision://tenant-1/codex/1",
      target_grant_revision: "target-grant-revision://tenant-1/sandbox/1",
      rotation_epoch: 1,
      fence_token: "fence://tenant-1/codex/a/1"
    }
  end

  defp credential_context(attrs) do
    Map.merge(
      %{
        tenant_id: "tenant-1",
        provider_family: "codex",
        provider_account_ref: "provider-account://tenant-1/codex/account-a",
        connector_instance_ref: "connector-instance://tenant-1/codex/a",
        credential_handle_ref: "credential-handle://tenant-1/codex/account-a",
        operation_class: "cli",
        target_ref: "target://tenant-1/sandbox/a",
        attach_grant_ref: "attach-grant://tenant-1/sandbox/a",
        operation_policy_ref: "operation-policy://tenant-1/codex/run",
        installation_revision_ref: "installation-revision://tenant-1/app/1",
        policy_revision_ref: "policy-revision://tenant-1/codex/1",
        target_grant_revision: "target-grant-revision://tenant-1/sandbox/1",
        rotation_epoch: 1,
        fence_token: "fence://tenant-1/codex/a/1"
      },
      attrs
    )
  end

  defp retry_context(attrs) do
    Map.merge(
      credential_context(%{
        idempotency_key: "idem://tenant-1/codex/retry-1",
        dispatch_ref: "dispatch://tenant-1/codex/retry-1",
        active_execution_ref: "execution://tenant-1/codex/active-1",
        current_execution_ref: "execution://tenant-1/codex/active-1",
        retry_authority_ref: "retry-authority://tenant-1/codex/retry-1",
        materialization_epoch: 1,
        materialized_credential_lease_ref: "credential-lease://tenant-1/codex/a/1",
        restart_event: :workflow_resume
      }),
      attrs
    )
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
