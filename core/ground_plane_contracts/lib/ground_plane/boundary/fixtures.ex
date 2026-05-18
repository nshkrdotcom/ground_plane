defmodule GroundPlane.Boundary.Fixtures do
  @moduledoc """
  Shared canonical boundary fixtures for stack plane tests.
  """

  alias GroundPlane.Boundary.Envelope

  @boundaries [
    appkit_mezzanine: {"app_kit", "mezzanine", "intake.fetch_candidates"},
    mezzanine_citadel: {"mezzanine", "citadel", "authority.authorize_operation"},
    mezzanine_jido: {"mezzanine", "jido_integration", "lower.invoke_operation"},
    mezzanine_execution_plane: {"mezzanine", "execution_plane", "effect.execute"},
    mezzanine_ai_trace: {"mezzanine", "AITrace", "trace.export_events"}
  ]

  @codec_consumers [
    "AITrace",
    "citadel",
    "execution_plane",
    "ground_plane",
    "jido_integration",
    "mezzanine",
    "outer_brain",
    "stack_lab"
  ]

  @spec canonical_terms() :: [map()]
  def canonical_terms do
    base_terms = [
      %{
        tenant_id: "tenant-a",
        operation: "intake.fetch_candidates",
        payload: %{limit: 2, role_ref: "role://issue-tracker"},
        trace: %{trace_id: "trace-a", span_id: "span-a"}
      },
      %{
        "tenant_id" => "tenant-a",
        "payload_ref" => "payload://tenant-a/sha256/abc",
        "metadata" => %{"redaction" => "payload-ref-only"}
      }
    ]

    consumer_terms =
      Enum.map(@codec_consumers, fn consumer ->
        %{
          tenant_id: "tenant-a",
          codec_consumer: consumer,
          payload: %{
            fixture_class: "canonical-boundary-codec",
            schema_version: "ground-plane.boundary.v1"
          }
        }
      end)

    base_terms ++ consumer_terms
  end

  @spec boundary_envelopes() :: %{atom() => Envelope.t()}
  def boundary_envelopes do
    @boundaries
    |> Enum.map(fn {key, {origin, target, operation}} ->
      envelope =
        Envelope.new!(%{
          id: "boundary://#{origin}/#{target}/#{operation}",
          origin: origin,
          target: target,
          operation: operation,
          tenant_id: "tenant-a",
          payload: %{
            operation_context_ref: "operation-context://tenant-a/run-a",
            role_ref: "role://generic/#{operation}",
            payload_ref: "payload://tenant-a/#{origin}/#{target}"
          },
          trace: %{trace_id: "trace-a", causation_id: "cause-a"},
          metadata: %{transport: "direct-module"}
        })

      {key, envelope}
    end)
    |> Map.new()
  end

  @spec negative_terms() :: %{atom() => term()}
  def negative_terms do
    %{
      atom_binary_key_ambiguity: %{:tenant_id => "tenant-a", "tenant_id" => "tenant-b"},
      raw_credential: %{tenant_id: "tenant-a", api_key: "secret"},
      unsupported_reference: %{tenant_id: "tenant-a", ref: make_ref()},
      unsupported_pid: %{tenant_id: "tenant-a", pid: self()},
      unsupported_task: %Task{
        owner: self(),
        pid: self(),
        ref: make_ref(),
        mfa: {:erlang, :apply, 2}
      },
      unsupported_stream: Stream.map([1], & &1)
    }
  end
end
