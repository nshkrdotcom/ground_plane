defmodule GroundPlaneTest do
  use ExUnit.Case
  doctest GroundPlane

  test "hello/0 returns the starter marker" do
    assert GroundPlane.hello() == :world
  end
end
