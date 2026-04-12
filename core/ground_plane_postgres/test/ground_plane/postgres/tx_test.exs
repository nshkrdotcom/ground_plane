defmodule GroundPlane.Postgres.TxTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Postgres.Tx

  defmodule FakeRepo do
    def transaction(fun) do
      {:ok, fun.()}
    end
  end

  test "delegates transaction work to the adapter" do
    assert {:ok, :done} = Tx.run(FakeRepo, fn -> :done end)
  end
end
