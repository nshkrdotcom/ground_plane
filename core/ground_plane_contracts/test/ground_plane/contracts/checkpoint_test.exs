defmodule GroundPlane.Contracts.CheckpointTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.Checkpoint

  test "builds and advances checkpoints monotonically" do
    assert {:ok, checkpoint} =
             Checkpoint.new(%{
               stream: "projection:workspace",
               position: 12,
               reason: "bootstrap"
             })

    assert {:ok, advanced} = Checkpoint.advance(checkpoint, 13, "caught_up")
    assert advanced.position == 13
    assert {:error, :checkpoint_regressed} = Checkpoint.advance(checkpoint, 11, "regressed")
  end
end
