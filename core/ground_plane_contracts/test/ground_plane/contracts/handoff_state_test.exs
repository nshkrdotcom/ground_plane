defmodule GroundPlane.Contracts.HandoffStateTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.HandoffState

  test "exposes the shared vocabulary" do
    assert "committed_local" in HandoffState.values()
    assert HandoffState.valid?("user_notified")
    refute HandoffState.valid?("made_up")
  end

  test "allows forward-only transitions" do
    assert HandoffState.transition_allowed?("pending_local", "committed_local")
    refute HandoffState.transition_allowed?("committed_local", "pending_local")
  end
end
