defmodule GroundPlane.Contracts.EnterprisePrecutPrimitivesTest do
  use ExUnit.Case, async: true

  alias GroundPlane.Contracts.{
    Checkpoint,
    EpochRef,
    GraphEdgeRef,
    GraphNodeRef,
    HandoffState,
    Id,
    Lease,
    ResourcePath
  }

  test "builds resource paths, epochs, graph refs, ids, leases, checkpoints, and handoffs" do
    assert Id.valid?(Id.build("tenant", "acme"))

    assert {:ok, resource_path} =
             ResourcePath.new(%{
               tenant_id: "tenant-acme",
               segments: ["tenant-acme", "workflow", "resource-work-1"],
               resource_kind_path: ["tenant", "workflow"],
               terminal_resource_id: "resource-work-1"
             })

    assert resource_path.terminal_resource_id == "resource-work-1"

    assert {:ok, epoch} =
             EpochRef.new(%{
               epoch_ref: "epoch-1",
               tenant_id: "tenant-acme",
               resource_id: "resource-work-1",
               epoch: 1,
               trace_id: "trace-109"
             })

    assert epoch.epoch == 1

    assert {:ok, node} =
             GraphNodeRef.new(%{
               node_ref: "node-command-105",
               tenant_id: "tenant-acme",
               node_kind: "command",
               trace_id: "trace-116"
             })

    assert {:ok, edge} =
             GraphEdgeRef.new(%{
               edge_ref: "edge-command-workflow-1",
               tenant_id: "tenant-acme",
               source_ref: node.node_ref,
               target_ref: "node-workflow-110",
               edge_kind: "caused",
               trace_id: "trace-116"
             })

    assert edge.edge_kind == "caused"

    assert {:ok, _lease} =
             Lease.new(%{
               resource: "resource-work-1",
               holder: "worker-1",
               lease_id: "lease-112",
               epoch: 1,
               expires_at: DateTime.utc_now()
             })

    assert {:ok, checkpoint} =
             Checkpoint.new(%{stream: "trace-116", position: 1, reason: "incident-proof"})

    assert {:ok, _advanced} = Checkpoint.advance(checkpoint, 2, "projection-proof")

    assert HandoffState.valid?("committed_local")
    assert HandoffState.transition_allowed?("committed_local", "accepted_downstream")
  end

  test "resource path and epoch refs fail closed on missing tenant scope" do
    assert {:error, {:missing_required_fields, [:tenant_id]}} =
             ResourcePath.new(%{
               segments: ["workflow", "resource-work-1"],
               resource_kind_path: ["workflow"],
               terminal_resource_id: "resource-work-1"
             })

    assert {:error, {:missing_required_fields, [:tenant_id]}} =
             EpochRef.new(%{
               epoch_ref: "epoch-1",
               resource_id: "resource-work-1",
               epoch: 1,
               trace_id: "trace-109"
             })
  end
end
