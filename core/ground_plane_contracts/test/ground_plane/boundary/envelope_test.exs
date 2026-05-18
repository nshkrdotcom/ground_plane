defmodule GroundPlane.Boundary.EnvelopeTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Boundary.Codec
  alias GroundPlane.Boundary.DispatchResult
  alias GroundPlane.Boundary.Envelope
  alias GroundPlane.Boundary.Fixtures
  alias GroundPlane.Boundary.Protocol

  defmodule EchoHandler do
    @behaviour Protocol

    @impl true
    def dispatch(%Envelope{} = envelope) do
      DispatchResult.new(%{
        status: "completed",
        response: %{
          envelope_digest: Envelope.digest(envelope),
          target: envelope.target
        },
        receipt_refs: ["receipt://tenant-a/boundary"]
      })
    end
  end

  test "envelope encodes and digests as canonical boundary data" do
    envelope = Fixtures.boundary_envelopes().appkit_mezzanine

    assert envelope.origin == "app_kit"
    assert envelope.target == "mezzanine"
    assert String.starts_with?(Envelope.digest(envelope), "sha256:")

    assert %{"origin" => "app_kit", "target" => "mezzanine"} =
             envelope |> Envelope.encode!() |> Codec.decode!()
  end

  test "envelope rejects non-serializable payloads" do
    assert {:error, :boundary_pid_not_serializable} =
             Envelope.new(%{
               id: "boundary://bad",
               origin: "app_kit",
               target: "mezzanine",
               operation: "bad",
               tenant_id: "tenant-a",
               payload: %{pid: self()}
             })
  end

  test "envelope rejects ambiguous inline and ref payload locations" do
    assert {:error, :ambiguous_boundary_payload_location} =
             Envelope.new(%{
               id: "boundary://bad",
               origin: "app_kit",
               target: "mezzanine",
               operation: "bad",
               tenant_id: "tenant-a",
               payload: %{ok: true},
               payload_ref: "payload://tenant-a/one"
             })
  end

  test "direct-module protocol dispatch uses the same serializable contract" do
    envelope = Fixtures.boundary_envelopes().mezzanine_jido

    assert {:ok, result} = Protocol.dispatch(EchoHandler, envelope)
    assert result.status == "completed"
    assert result.response.target == "jido_integration"
    assert String.starts_with?(result.response.envelope_digest, "sha256:")
  end

  test "all first-pass plane fixtures are serializable" do
    envelopes = Fixtures.boundary_envelopes()

    assert Enum.sort(Map.keys(envelopes)) == [
             :appkit_mezzanine,
             :mezzanine_ai_trace,
             :mezzanine_citadel,
             :mezzanine_execution_plane,
             :mezzanine_jido
           ]

    for {_key, envelope} <- envelopes do
      assert {:ok, _encoded} = Codec.encode(envelope)
    end
  end
end
