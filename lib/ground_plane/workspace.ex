defmodule GroundPlane.Workspace do
  @moduledoc """
  Introspection helpers for the GroundPlane workspace root.
  """

  alias GroundPlane.WorkspaceContract

  @spec package_paths() :: [String.t()]
  def package_paths do
    WorkspaceContract.package_paths()
  end

  @spec active_project_globs() :: [String.t()]
  def active_project_globs do
    WorkspaceContract.active_project_globs()
  end
end
