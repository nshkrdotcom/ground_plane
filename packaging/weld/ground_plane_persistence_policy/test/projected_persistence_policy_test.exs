defmodule GroundPlane.ProjectedPersistencePolicyTest do
  use ExUnit.Case, async: true

  alias GroundPlane.PersistencePolicy

  test "projected artifact resolves a representative pure profile" do
    profile = PersistencePolicy.resolve!(profile: :memory_debug)

    assert profile.id == :memory_debug
    assert profile.default_tier == :memory_ephemeral
    assert profile.capture_level == :redacted_debug
    refute profile.durable?
  end

  test "projected package excludes workspace and unrelated package trees" do
    package_files = Mix.Project.config() |> Keyword.fetch!(:package) |> Keyword.fetch!(:files)
    rendered = Enum.join(package_files, "\n")

    assert "components/core/persistence_policy" in package_files

    for forbidden <- [
          "deps",
          "_build",
          ".git",
          "examples",
          "priv/plts",
          "credentials",
          "core/ground_plane_contracts",
          "core/persistence_policy_data_extension",
          "core/ground_plane_postgres",
          "core/ground_plane_projection"
        ] do
      refute rendered =~ forbidden
    end
  end
end
