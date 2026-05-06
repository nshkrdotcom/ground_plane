defmodule GroundPlane.WorkspaceTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Workspace
  alias GroundPlane.Workspace.MixProject

  test "lists workspace packages" do
    assert "core/ai_run_fencing" in Workspace.package_paths()
    assert "core/ground_plane_contracts" in Workspace.package_paths()
    assert "examples/projection_smoke" in Workspace.package_paths()
  end

  test "lists active project globs" do
    assert Workspace.active_project_globs() == [".", "core/*", "examples/*"]
  end

  test "uses the released Weld 0.7.2 line directly" do
    assert {:weld, "~> 0.7.2", runtime: false} in MixProject.project()[:deps]
  end

  test "uses Weld task autodiscovery instead of local release aliases" do
    aliases = MixProject.project()[:aliases]

    for alias_name <- [
          :"weld.inspect",
          :"weld.graph",
          :"weld.project",
          :"weld.verify",
          :"weld.release.prepare",
          :"weld.release.track",
          :"weld.release.archive",
          :"release.prepare",
          :"release.track",
          :"release.archive"
        ] do
      refute Keyword.has_key?(aliases, alias_name)
    end
  end
end
