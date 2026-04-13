defmodule GroundPlane.WorkspaceTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Workspace
  alias GroundPlane.Workspace.MixProject

  test "lists workspace packages" do
    assert "core/ground_plane_contracts" in Workspace.package_paths()
    assert "examples/projection_smoke" in Workspace.package_paths()
  end

  test "lists active project globs" do
    assert Workspace.active_project_globs() == [".", "core/*", "examples/*"]
  end

  test "uses the released Weld 0.7.0 line directly" do
    assert {:weld, "~> 0.7.0", runtime: false} in MixProject.project()[:deps]
  end

  test "exposes the release aliases for projection tracking" do
    aliases = MixProject.project()[:aliases]

    assert Keyword.fetch!(aliases, :"release.prepare") == ["weld.release.prepare"]
    assert Keyword.fetch!(aliases, :"release.track") == ["weld.release.track"]
    assert Keyword.fetch!(aliases, :"release.archive") == ["weld.release.archive"]
  end
end
