defmodule GroundPlane.WorkspaceContract do
  @moduledoc false

  @package_paths [
    "core/ai_run_fencing",
    "core/ground_plane_contracts",
    "core/persistence_policy_ai_extension",
    "core/ground_plane_postgres",
    "core/ground_plane_projection",
    "examples/projection_smoke"
  ]

  @active_project_globs [".", "core/*", "examples/*"]

  def package_paths, do: @package_paths
  def active_project_globs, do: @active_project_globs
end
