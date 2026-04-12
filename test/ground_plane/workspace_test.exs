defmodule GroundPlane.WorkspaceTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Workspace

  test "lists workspace packages" do
    assert "core/ground_plane_contracts" in Workspace.package_paths()
    assert "examples/projection_smoke" in Workspace.package_paths()
  end

  test "lists active project globs" do
    assert Workspace.active_project_globs() == [".", "core/*", "examples/*"]
  end
end
