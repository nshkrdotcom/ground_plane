defmodule GroundPlane.Contracts.FenceComponentsTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.Fence
  alias GroundPlane.Contracts.Fence.AuthorityScope
  alias GroundPlane.Contracts.Fence.CredentialScope
  alias GroundPlane.Contracts.Fence.Epoch
  alias GroundPlane.Contracts.Fence.Identity
  alias GroundPlane.Contracts.Fence.PersistenceScope

  test "builds a composed fence view from component contracts" do
    assert {:ok, fence} = Fence.new(valid_attrs())

    assert %Identity{resource: "credential:resource-a:tenant-1:account-a"} = fence.identity
    assert %Epoch{epoch: 4, rotation_epoch: 1} = fence.epoch_ref

    assert %CredentialScope{credential_lease_ref: "credential-lease://tenant-1/resource-a/a/1"} =
             fence.credential_scope

    assert %AuthorityScope{policy_revision_ref: "policy-revision://tenant-1/resource-a/1"} =
             fence.authority_scope

    assert %PersistenceScope{persistence_posture: %{durable?: false}} = fence.persistence_scope

    assert fence.resource == fence.identity.resource
    assert fence.epoch == fence.epoch_ref.epoch
    assert fence.policy_revision_ref == fence.authority_scope.policy_revision_ref
  end

  test "constructor rejects invalid identity and epoch combinations" do
    assert {:error, {:invalid_identity_field, :resource}} =
             valid_attrs()
             |> Map.put(:resource, "")
             |> Fence.new()

    assert {:error, {:invalid_epoch_field, :epoch}} =
             valid_attrs()
             |> Map.put(:epoch, -1)
             |> Fence.new()
  end

  test "constructor rejects incomplete credential scope" do
    assert {:error, {:missing_credential_scope_fields, [:credential_lease_ref]}} =
             valid_attrs()
             |> Map.delete(:credential_lease_ref)
             |> Fence.new()
  end

  test "constructor rejects invalid authority and persistence fields" do
    assert {:error, {:invalid_authority_field, :policy_revision_ref}} =
             valid_attrs()
             |> Map.put(:policy_revision_ref, "")
             |> Fence.new()

    assert {:error, {:invalid_persistence_posture, "memory"}} =
             valid_attrs()
             |> Map.put(:persistence_posture, "memory")
             |> Fence.new()
  end

  defp valid_attrs do
    %{
      resource: "credential:resource-a:tenant-1:account-a",
      holder: "materializer-a",
      lease_id: "lease_active",
      epoch: 4,
      tenant_id: "tenant-1",
      resource_family: "resource-a",
      resource_account_ref: "account://tenant-1/resource-a/account-a",
      resource_instance_ref: "resource-instance://tenant-1/resource-a/a",
      credential_handle_ref: "credential-handle://tenant-1/resource-a/account-a",
      credential_lease_ref: "credential-lease://tenant-1/resource-a/a/1",
      operation_class: "cli",
      target_ref: "target://tenant-1/sandbox/a",
      attach_grant_ref: "attach-grant://tenant-1/sandbox/a",
      operation_policy_ref: "operation-policy://tenant-1/resource-a/run",
      installation_revision_ref: "installation-revision://tenant-1/app/1",
      policy_revision_ref: "policy-revision://tenant-1/resource-a/1",
      target_grant_revision: "target-grant-revision://tenant-1/sandbox/1",
      rotation_epoch: 1,
      fence_token: "fence://tenant-1/resource-a/a/1",
      persistence_posture: %{durable?: false}
    }
  end
end
