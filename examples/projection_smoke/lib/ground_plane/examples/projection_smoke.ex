defmodule GroundPlane.Examples.ProjectionSmoke do
  @moduledoc """
  Smoke example that builds a normalized projection publication.
  """

  alias GroundPlane.Projection.Publication

  @spec build_publication() :: map()
  def build_publication do
    Publication.build("workspace_activity", "upsert", [%{id: "entry_1", state: "visible"}])
  end
end
