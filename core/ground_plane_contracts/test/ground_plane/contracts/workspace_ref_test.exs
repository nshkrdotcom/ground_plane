defmodule GroundPlane.Contracts.WorkspaceRefTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.WorkspaceRef

  test "builds canonical workspace refs" do
    assert {:ok, workspace_ref} = WorkspaceRef.new("NSHKRDOTCOM", "gn-ten")

    assert workspace_ref.owner == "nshkrdotcom"
    assert workspace_ref.name == "gn-ten"
    assert workspace_ref.ref == "workspace://nshkrdotcom/gn-ten"
    assert WorkspaceRef.valid?(workspace_ref.ref)
  end

  test "parses canonical refs and round-trips to canonical string form" do
    ref = "workspace://nshkrdotcom/gn-ten"

    assert {:ok, workspace_ref} = WorkspaceRef.parse(ref)
    assert workspace_ref.owner == "nshkrdotcom"
    assert workspace_ref.name == "gn-ten"
    assert WorkspaceRef.to_string(workspace_ref) == ref
  end

  test "rejects non-canonical owner case" do
    assert {:error, :non_canonical_workspace_ref} =
             WorkspaceRef.parse("workspace://NSHKRDOTCOM/gn-ten")
  end

  test "rejects invalid refs and segments" do
    refute WorkspaceRef.valid?("workspace://bad owner/gn-ten")
    refute WorkspaceRef.valid?("workspace://nshkrdotcom/gn ten")
    refute WorkspaceRef.valid?("workspace://nshkrdotcom")

    assert {:error, {:invalid_segment, :name}} = WorkspaceRef.new("nshkrdotcom", "bad/name")
    assert {:error, :invalid_workspace_ref} = WorkspaceRef.parse("repo://nshkrdotcom/gn-ten")
  end
end
