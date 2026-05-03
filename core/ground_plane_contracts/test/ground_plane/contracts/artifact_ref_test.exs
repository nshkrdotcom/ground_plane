defmodule GroundPlane.Contracts.ArtifactRefTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.ArtifactRef

  test "builds canonical artifact refs" do
    assert {:ok, artifact_ref} = ArtifactRef.new("NSHKRDOTCOM", "AITrace", "aitrace")

    assert artifact_ref.owner == "nshkrdotcom"
    assert artifact_ref.repo == "AITrace"
    assert artifact_ref.name == "aitrace"
    assert artifact_ref.ref == "artifact://nshkrdotcom/AITrace/aitrace"
    assert ArtifactRef.valid?(artifact_ref.ref)
  end

  test "parses canonical refs and round-trips to canonical string form" do
    ref = "artifact://nshkrdotcom/ground_plane/ground_plane_contracts"

    assert {:ok, artifact_ref} = ArtifactRef.parse(ref)
    assert artifact_ref.owner == "nshkrdotcom"
    assert artifact_ref.repo == "ground_plane"
    assert artifact_ref.name == "ground_plane_contracts"
    assert ArtifactRef.to_string(artifact_ref) == ref
  end

  test "rejects non-canonical owner case" do
    assert {:error, :non_canonical_artifact_ref} =
             ArtifactRef.parse("artifact://NSHKRDOTCOM/ground_plane/ground_plane_contracts")
  end

  test "rejects invalid refs and segments" do
    refute ArtifactRef.valid?("artifact://bad owner/stack_lab/manifest")
    refute ArtifactRef.valid?("artifact://nshkrdotcom/stack lab/manifest")
    refute ArtifactRef.valid?("artifact://nshkrdotcom/stack_lab")
    refute ArtifactRef.valid?("artifact://nshkr.dot/stack_lab/manifest")
    refute ArtifactRef.valid?("artifact://nshkrdotcom/stack.lab/manifest")

    assert {:ok, artifact_ref} = ArtifactRef.new("nshkrdotcom", "stack_lab", "manifest.v1")
    assert artifact_ref.ref == "artifact://nshkrdotcom/stack_lab/manifest.v1"

    assert {:error, {:invalid_segment, :owner}} =
             ArtifactRef.new("nshkr.dot", "stack_lab", "manifest")

    assert {:error, {:invalid_segment, :repo}} =
             ArtifactRef.new("nshkrdotcom", "stack.lab", "manifest")

    assert {:error, {:invalid_segment, :name}} =
             ArtifactRef.new("nshkrdotcom", "stack_lab", "bad/name")

    assert {:error, :invalid_artifact_ref} =
             ArtifactRef.parse("repo://nshkrdotcom/stack_lab/manifest")
  end
end
