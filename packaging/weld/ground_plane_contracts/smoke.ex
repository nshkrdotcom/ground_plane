defmodule GroundPlane.Contracts.WeldSmoke do
  @moduledoc false

  alias GroundPlane.Boundary.Codec
  alias GroundPlane.Boundary.Envelope

  def round_trip do
    envelope =
      Envelope.new!(%{
        id: "boundary://ground-plane/contracts/smoke",
        origin: "consumer",
        target: "execution_plane",
        operation: "effect.execute",
        tenant_id: "tenant-smoke",
        payload: %{checkpoint_ref: "checkpoint://tenant-smoke/one"}
      })

    envelope
    |> Envelope.encode!()
    |> Codec.decode!()
  end
end
