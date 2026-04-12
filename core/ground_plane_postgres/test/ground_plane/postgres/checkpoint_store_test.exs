defmodule GroundPlane.Postgres.CheckpointStoreTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Postgres.CheckpointStore

  test "advances checkpoint rows monotonically" do
    row = CheckpointStore.record("projection:workspace", 8, "bootstrap")

    assert {:ok, advanced} = CheckpointStore.advance(row, 9, "catch_up")
    assert advanced.position == 9
    assert {:error, :checkpoint_regressed} = CheckpointStore.advance(row, 7, "bad")
  end
end
