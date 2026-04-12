defmodule GroundPlane.Contracts.IdTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.Id

  test "builds normalized ids" do
    assert Id.build("Turn ID", "Root/Unit") == "turn_id_root_unit"
    assert Id.valid?(Id.build("turn", "123"))
  end

  test "generates random ids with the expected prefix" do
    value = Id.random("handoff")

    assert String.starts_with?(value, "handoff_")
    assert Id.valid?(value)
  end
end
