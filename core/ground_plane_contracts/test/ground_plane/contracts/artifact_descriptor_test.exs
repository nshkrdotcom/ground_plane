defmodule GroundPlane.Contracts.ArtifactDescriptorTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.ArtifactDescriptor

  @digest "sha256:" <> String.duplicate("a", 64)

  defp attrs do
    %{
      artifact_ref: "artifact://outer-brain/reply-1",
      tenant_ref: "tenant://acme",
      owner_ref: "service://outer-brain",
      content_digest: @digest,
      size_bytes: 42,
      media_type: "text/plain",
      schema_ref: "schema://outer-brain/reply-body",
      schema_version: 1,
      classification: "confidential",
      provenance: %{"trace_ref" => "trace://synapse/run-1"},
      causal_parent_refs: ["artifact://outer-brain/prompt-1"],
      producing_operation_ref: "operation://jido/attempt-1",
      retention: %{"class" => "product_run", "delete_after" => "2026-08-15T00:00:00Z"},
      deletion_state: "active",
      location_ref: "object://nshkr-artifacts/acme/reply-1"
    }
  end

  test "constructs and canonically encodes immutable metadata" do
    assert {:ok, descriptor} = ArtifactDescriptor.new(attrs())
    assert descriptor.content_digest == @digest
    assert ArtifactDescriptor.encode!(descriptor) =~ "artifact_ref"
    assert String.starts_with?(ArtifactDescriptor.digest(descriptor), "sha256:")
  end

  test "rejects secret-bearing metadata and invalid digests" do
    assert {:error, {:raw_credential_key_forbidden, "api_key"}} =
             attrs()
             |> put_in([:provenance], %{"api_key" => "sentinel-secret"})
             |> ArtifactDescriptor.new()

    assert {:error, {:raw_credential_key_forbidden, "api_key"}} =
             attrs() |> Map.put(:api_key, "sentinel-secret") |> ArtifactDescriptor.new()

    assert {:error, {:invalid_field, :content_digest}} =
             attrs()
             |> Map.put(:content_digest, "sha256:not-a-digest")
             |> ArtifactDescriptor.new()
  end

  test "enforces tombstone before deletion and removes the location" do
    descriptor = ArtifactDescriptor.new!(attrs())

    assert {:error, :invalid_deletion_transition} = ArtifactDescriptor.mark_deleted(descriptor)
    assert {:ok, tombstoned} = ArtifactDescriptor.tombstone(descriptor, "tombstone://artifact/1")
    assert tombstoned.deletion_state == "tombstoned"
    assert is_nil(tombstoned.location_ref)

    assert {:ok, deleted} = ArtifactDescriptor.mark_deleted(tombstoned)
    assert deleted.deletion_state == "deleted"
  end

  test "rejects a deleted descriptor that still exposes a location" do
    assert {:error, :deleted_artifact_has_location} =
             attrs()
             |> Map.put(:deletion_state, "deleted")
             |> ArtifactDescriptor.new()
  end
end
