defmodule GroundPlane.Projection.PublicationTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Projection.Publication

  defmodule FakeAdapter do
    @behaviour GroundPlane.Projection.Adapter

    @impl true
    def publish(publication) do
      {:ok, {:published, publication.name}}
    end
  end

  test "builds normalized publication records" do
    publication =
      Publication.build("workspace_activity", "upsert", [%{id: "one"}],
        metadata: %{scope: "workspace"}
      )

    assert publication.name == "workspace_activity"
    assert publication.operation == "upsert"
    assert is_map(publication.metadata)
  end

  test "delegates publication to the adapter" do
    publication = Publication.build("workspace_activity", "upsert", [%{id: "one"}])

    assert {:ok, {:published, "workspace_activity"}} =
             Publication.publish(FakeAdapter, publication)
  end
end
