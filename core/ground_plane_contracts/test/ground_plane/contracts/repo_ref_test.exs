defmodule GroundPlane.Contracts.RepoRefTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.RepoRef

  test "builds canonical repository refs" do
    assert {:ok, repo_ref} = RepoRef.new("NSHKRDOTCOM", "app_kit")
    assert repo_ref.owner == "nshkrdotcom"
    assert repo_ref.name == "app_kit"
    assert repo_ref.ref == "repo://nshkrdotcom/app_kit"
    assert RepoRef.valid?(repo_ref.ref)
  end

  test "parses canonical refs" do
    assert {:ok, repo_ref} = RepoRef.parse("repo://nshkrdotcom/AITrace")
    assert repo_ref.owner == "nshkrdotcom"
    assert repo_ref.name == "AITrace"
  end

  test "rejects non-canonical owner case" do
    assert {:error, :non_canonical_repo_ref} = RepoRef.parse("repo://NSHKRDOTCOM/app_kit")
  end

  test "rejects invalid refs and segments" do
    refute RepoRef.valid?("repo://bad owner/app kit")
    refute RepoRef.valid?("repo://nshkrdotcom/app.kit")
    assert {:error, {:invalid_segment, :name}} = RepoRef.new("nshkrdotcom", "app kit")
    assert {:error, {:invalid_segment, :name}} = RepoRef.new("nshkrdotcom", "app.kit")
    assert {:error, :invalid_repo_ref} = RepoRef.parse("project://nshkrdotcom/app_kit")
  end
end
