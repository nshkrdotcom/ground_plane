defmodule GroundPlane.Contracts.CheckpointTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.Checkpoint
  alias GroundPlane.Contracts.PersistencePosture

  test "builds and advances checkpoints monotonically" do
    assert {:ok, checkpoint} =
             Checkpoint.new(%{
               stream: "projection:workspace",
               position: 12,
               reason: "bootstrap"
             })

    assert {:ok, advanced} = Checkpoint.advance(checkpoint, 13, "caught_up")
    assert advanced.position == 13

    assert advanced.persistence_posture.persistence_profile_ref ==
             "persistence-profile://mickey_mouse"

    assert {:error, :checkpoint_regressed} = Checkpoint.advance(checkpoint, 11, "regressed")
  end

  test "restart checkpoint durable posture requires matching durable capability" do
    assert {:ok, checkpoint} =
             Checkpoint.new(%{
               stream: "projection:workspace",
               position: 12,
               reason: "bootstrap",
               profile: :local_restart_safe
             })

    assert checkpoint.persistence_posture.durable? == true

    assert {:error, {:missing_store_capability, :local_restart_safe}} =
             PersistencePosture.preflight(
               checkpoint.persistence_posture,
               []
             )

    assert :ok =
             PersistencePosture.preflight(checkpoint.persistence_posture, [
               PersistencePosture.capability(:restart_checkpoint, :local_restart_safe)
             ])
  end
end
