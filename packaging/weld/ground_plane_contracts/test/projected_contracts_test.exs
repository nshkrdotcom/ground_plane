defmodule GroundPlane.ProjectedContractsTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Boundary.Codec
  alias GroundPlane.Boundary.Envelope
  alias GroundPlane.Contracts.HandoffState

  test "projected contract artifact exposes the shared handoff vocabulary" do
    assert HandoffState.valid?("committed_local")
  end

  test "projected contract artifact round-trips a boundary envelope" do
    envelope =
      Envelope.new!(%{
        id: "boundary://ground-plane/contracts/projected-test",
        origin: "governance_node",
        target: "effect_node",
        operation: "effect.execute",
        tenant_id: "tenant-test",
        payload: %{lease_ref: "lease://tenant-test/effect/one"}
      })

    assert %{
             "origin" => "governance_node",
             "target" => "effect_node",
             "payload" => %{"lease_ref" => "lease://tenant-test/effect/one"}
           } = envelope |> Envelope.encode!() |> Codec.decode!()
  end

  test "projected package excludes workspace and unrelated package trees" do
    package_files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files)
    rendered = Enum.join(package_files, "\n")

    assert "components/core/ground_plane_contracts" in package_files

    for forbidden <- [
          "deps",
          "_build",
          ".git",
          "examples",
          "priv/plts",
          "credentials",
          "core/persistence_policy",
          "core/ground_plane_postgres",
          "core/ground_plane_projection"
        ] do
      refute rendered =~ forbidden
    end
  end
end
