defmodule GroundPlane.Postgres.AdvisoryLockTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Postgres.AdvisoryLock

  test "builds stable key pairs" do
    assert AdvisoryLock.pair("semantic", "session-1") ==
             AdvisoryLock.pair("semantic", "session-1")

    refute AdvisoryLock.pair("semantic", "session-1") ==
             AdvisoryLock.pair("semantic", "session-2")
  end
end
