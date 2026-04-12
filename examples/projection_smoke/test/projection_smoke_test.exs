defmodule GroundPlane.Examples.ProjectionSmokeTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Examples.ProjectionSmoke

  test "builds a projection publication with a stable shape" do
    publication = ProjectionSmoke.build_publication()

    assert publication.name == "workspace_activity"
    assert publication.operation == "upsert"
    assert is_list(publication.payload)
  end
end
