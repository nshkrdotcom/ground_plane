defmodule GroundPlane.BoundaryProtocol.CommandEnvelopeTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Boundary.Codec
  alias GroundPlane.BoundaryProtocol.CommandEnvelope

  test "constructs and canonicalizes a governed command envelope" do
    assert {:ok, envelope} = CommandEnvelope.new(valid_attrs())

    assert envelope.protocol_version == "gaop.v1"
    assert envelope.command_ref == "command://tenant-a/diagnostic/001"
    assert envelope.tenant_ref == "tenant-a"
    assert envelope.actor_ref == "actor://user/operator-a"
    assert envelope.schema_ref == "schema://synapse/diagnostic-command/v1"
    assert envelope.idempotency_key == "idem-tenant-a-diagnostic-001"
    assert envelope.trace_ref == "trace-tenant-a-diagnostic-001"
    assert envelope.expected_version == 1
    assert String.starts_with?(CommandEnvelope.digest(envelope), "sha256:")
  end

  test "round-trips through the GroundPlane boundary codec" do
    envelope = CommandEnvelope.new!(valid_attrs())

    assert %{
             "command_ref" => "command://tenant-a/diagnostic/001",
             "tenant_ref" => "tenant-a",
             "resource_scopes" => [%{"kind" => "endpoint_class"}]
           } = envelope |> CommandEnvelope.encode!() |> Codec.decode!()
  end

  test "maps internal names to GAOP command envelope names" do
    envelope = CommandEnvelope.new!(valid_attrs())

    assert %{
             "protocol_version" => "gaop.v1",
             "command_id" => "command://tenant-a/diagnostic/001",
             "tenant_id" => "tenant-a",
             "actor_ref" => "actor://user/operator-a",
             "trace_id" => "trace-tenant-a-diagnostic-001",
             "idempotency_key" => "idem-tenant-a-diagnostic-001",
             "requested_capability" => %{
               "capability_id" => "diagnostic.echo",
               "operation" => "diagnostic.echo",
               "effect_class" => "observe"
             },
             "intent" => %{"summary" => "Run a bounded diagnostic echo"},
             "resource_scopes" => [%{"kind" => "endpoint_class"}],
             "created_at" => "2026-05-20T08:00:00Z",
             "metadata" => %{
               "authority_ref" => "authority://tenant-a/diagnostic/allow",
               "expected_version" => 1,
               "installation_ref" => "installation://tenant-a/synapse",
               "schema_ref" => "schema://synapse/diagnostic-command/v1"
             }
           } = CommandEnvelope.to_gaop_map(envelope)
  end

  test "rejects missing and invalid required boundary fields with typed errors" do
    assert {:error, :missing_tenant} = CommandEnvelope.new(Map.delete(valid_attrs(), :tenant_ref))

    assert {:error, {:missing_field, :actor_ref}} =
             CommandEnvelope.new(Map.delete(valid_attrs(), :actor_ref))

    assert {:error, :invalid_schema} =
             CommandEnvelope.new(%{valid_attrs() | schema_ref: ""})

    assert {:error, {:missing_field, :idempotency_key}} =
             CommandEnvelope.new(Map.delete(valid_attrs(), :idempotency_key))

    assert {:error, {:missing_field, :trace_ref}} =
             CommandEnvelope.new(Map.delete(valid_attrs(), :trace_ref))
  end

  test "rejects invalid expected versions as version conflicts" do
    assert {:error, :version_conflict} =
             CommandEnvelope.new(%{valid_attrs() | expected_version: 0})

    assert {:error, :version_conflict} =
             CommandEnvelope.new(%{valid_attrs() | expected_version: -1})
  end

  test "rejects non-serializable payloads with the boundary taxonomy" do
    assert {:error, {:non_serializable, :boundary_pid_not_serializable}} =
             CommandEnvelope.new(%{valid_attrs() | payload: %{pid: self()}})
  end

  test "publishes the boundary protocol error taxonomy" do
    assert CommandEnvelope.error_taxonomy() == %{
             duplicate_idempotency:
               "idempotency_key was already accepted for this tenant boundary",
             invalid_schema: "schema_ref or schema-governed payload is invalid",
             missing_tenant: "tenant_ref is required before dispatch",
             non_serializable: "envelope contains a value the boundary codec cannot encode",
             version_conflict: "expected_version is not a positive optimistic concurrency value"
           }
  end

  defp valid_attrs do
    %{
      command_ref: "command://tenant-a/diagnostic/001",
      tenant_ref: "tenant-a",
      actor_ref: "actor://user/operator-a",
      installation_ref: "installation://tenant-a/synapse",
      schema_ref: "schema://synapse/diagnostic-command/v1",
      idempotency_key: "idem-tenant-a-diagnostic-001",
      trace_ref: "trace-tenant-a-diagnostic-001",
      operation_type: "diagnostic.echo",
      payload: %{"message" => "hello"},
      authority_ref: "authority://tenant-a/diagnostic/allow",
      expected_version: 1,
      resource_scopes: [%{"kind" => "endpoint_class"}],
      intent: %{"summary" => "Run a bounded diagnostic echo"},
      created_at: "2026-05-20T08:00:00Z"
    }
  end
end
