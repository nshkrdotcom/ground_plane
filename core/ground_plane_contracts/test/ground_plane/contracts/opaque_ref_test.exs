defmodule GroundPlane.Contracts.OpaqueRefTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.ActorRef
  alias GroundPlane.Contracts.BindingRef
  alias GroundPlane.Contracts.CorrelationRef
  alias GroundPlane.Contracts.IdempotencyKey
  alias GroundPlane.Contracts.InstallationRef
  alias GroundPlane.Contracts.LeaseRef
  alias GroundPlane.Contracts.OperationRef
  alias GroundPlane.Contracts.RevisionRef
  alias GroundPlane.Contracts.TenantRef
  alias GroundPlane.Contracts.TraceRef

  test "builds canonical opaque refs for stack identity and dispatch primitives" do
    assert {:ok, tenant} = TenantRef.new("tenant-1")
    assert TenantRef.to_string(tenant) == "tenant://tenant-1"

    assert {:ok, actor} = ActorRef.new("tenant-1", "operator-a")
    assert ActorRef.to_string(actor) == "actor://tenant-1/operator-a"

    assert {:ok, installation} = InstallationRef.new("tenant-1", "extravaganza", "prod")
    assert InstallationRef.to_string(installation) == "installation://tenant-1/extravaganza/prod"

    assert {:ok, trace} = TraceRef.new("tenant-1", "trace-1")
    assert TraceRef.to_string(trace) == "trace://tenant-1/trace-1"

    assert {:ok, binding} =
             BindingRef.new("tenant-1", "installation-1", "source", "issue-tracker")

    assert BindingRef.to_string(binding) ==
             "binding://tenant-1/installation-1/source/issue-tracker"

    assert {:ok, operation} = OperationRef.new("tenant-1", "run-1", "op-1")
    assert OperationRef.to_string(operation) == "operation://tenant-1/run-1/op-1"

    assert {:ok, revision} = RevisionRef.new("tenant-1", "installation-1", "rev-1")
    assert RevisionRef.to_string(revision) == "revision://tenant-1/installation-1/rev-1"

    assert {:ok, lease} = LeaseRef.new("tenant-1", "credential-lease", "lease-1")
    assert LeaseRef.to_string(lease) == "lease://tenant-1/credential-lease/lease-1"

    assert {:ok, idempotency} = IdempotencyKey.new("tenant-1", "request-1")
    assert IdempotencyKey.to_string(idempotency) == "idempotency://tenant-1/request-1"

    assert {:ok, correlation} = CorrelationRef.new("tenant-1", "correlation-1")
    assert CorrelationRef.to_string(correlation) == "correlation://tenant-1/correlation-1"
  end

  test "parses canonical opaque refs and rejects non-canonical strings" do
    assert {:ok, parsed} =
             BindingRef.parse("binding://tenant-1/installation-1/source/issue-tracker")

    assert parsed.segments == ["tenant-1", "installation-1", "source", "issue-tracker"]

    assert BindingRef.valid?("binding://tenant-1/installation-1/source/issue-tracker")
    refute BindingRef.valid?("Binding://tenant-1/installation-1/source/issue-tracker")
    refute BindingRef.valid?("binding://tenant-1/installation-1/source")
    refute BindingRef.valid?("binding://tenant-1//source/issue-tracker")
    refute BindingRef.valid?("binding://tenant 1/installation-1/source/issue-tracker")
  end

  test "normalizes constructor input without accepting ambiguous parsed refs" do
    assert {:ok, trace} = TraceRef.new(" Tenant 1 ", " Trace 1 ")
    assert TraceRef.to_string(trace) == "trace://tenant_1/trace_1"

    assert {:error, :non_canonical_opaque_ref} = TraceRef.parse("trace://Tenant 1/Trace 1")
  end
end
