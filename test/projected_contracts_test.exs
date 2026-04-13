defmodule GroundPlane.ProjectedContractsTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.HandoffState

  test "projected contract artifact exposes the shared handoff vocabulary" do
    assert HandoffState.valid?("committed_local")
  end
end
