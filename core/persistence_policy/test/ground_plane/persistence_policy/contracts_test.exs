defmodule GroundPlane.PersistencePolicy.ContractsTest do
  use ExUnit.Case, async: true

  alias GroundPlane.PersistencePolicy
  alias GroundPlane.PersistencePolicy.CaptureLevel
  alias GroundPlane.PersistencePolicy.Partition
  alias GroundPlane.PersistencePolicy.Profile
  alias GroundPlane.PersistencePolicy.StoreCapability
  alias GroundPlane.PersistencePolicy.StoreSet
  alias GroundPlane.PersistencePolicy.Tier

  test "tier contract names supported durable and memory tiers" do
    assert :memory_ephemeral in Tier.all()
    assert :postgres_shared in Tier.durable()
    refute Tier.durable?(:memory_ephemeral)
    assert Tier.durable?(:temporal_durable)

    assert {:ok, :object_store} = Tier.validate(:object_store)
    assert {:error, {:unsupported_tier, :external_blob}} = Tier.validate(:external_blob)
  end

  test "capture level contract validates supported debug levels" do
    assert :off in CaptureLevel.all()
    assert :redacted_debug in CaptureLevel.all()

    assert {:ok, :full_debug} = CaptureLevel.validate(:full_debug)

    assert {:error, {:unsupported_capture_level, :raw_payloads}} =
             CaptureLevel.validate(:raw_payloads)
  end

  test "partition contract converts known atom and string fields only" do
    assert {:ok, partition} =
             Partition.new(%{
               "tenant_ref" => "tenant-1",
               resource_ref: "issue-1",
               retention_class: :short_lived
             })

    assert %Partition{
             tenant_ref: "tenant-1",
             resource_ref: "issue-1",
             retention_class: :short_lived
           } = partition

    assert {:error, {:invalid_partition_field, "unknown_ref"}} =
             Partition.new(%{"unknown_ref" => "value"})
  end

  test "store capability contract composes tier and partition validation" do
    assert {:ok, capability} =
             StoreCapability.new(
               store_ref: "store://memory",
               tier: :memory_ephemeral,
               data_classes: [:events],
               adapter: :memory,
               partitions: [tenant_ref: "tenant-1"]
             )

    assert %StoreCapability{
             tier: :memory_ephemeral,
             durable?: false,
             partitions: [%Partition{tenant_ref: "tenant-1"}]
           } = capability

    assert {:error, {:invalid_partition_field, :unknown_ref}} =
             StoreCapability.new(
               store_ref: :memory,
               tier: :memory_ephemeral,
               data_classes: [:events],
               adapter: :memory,
               partitions: %{unknown_ref: "value"}
             )
  end

  test "profile placement contract keeps memory and durable store sets distinct" do
    assert {:ok, memory_profile} = PersistencePolicy.resolve(profile: :mickey_mouse)

    assert %Profile{
             durable?: false,
             store_set: %StoreSet{
               default_tier: :memory_ephemeral,
               capabilities: [%StoreCapability{adapter: :memory, durable?: false}],
               partitions: []
             }
           } = memory_profile

    assert {:ok, durable_profile} = PersistencePolicy.resolve(profile: :integration_postgres)

    assert %Profile{
             durable?: true,
             default_tier: :postgres_shared,
             store_set: %StoreSet{
               default_tier: :postgres_shared,
               capabilities: [%StoreCapability{adapter: :postgres_shared, durable?: true}],
               partitions: [%Partition{}]
             }
           } = durable_profile
  end

  test "retention and restart claim contract follows profile tier family" do
    assert PersistencePolicy.resolve!(profile: :mickey_mouse).metadata.restart_claim == :none

    assert PersistencePolicy.resolve!(profile: :local_restart_safe).metadata.restart_claim ==
             :restart_safe

    assert PersistencePolicy.resolve!(profile: :integration_postgres).metadata.restart_claim ==
             :durable

    assert PersistencePolicy.resolve!(profile: :ops_durable).metadata.restart_claim ==
             :durable_restart
  end
end
