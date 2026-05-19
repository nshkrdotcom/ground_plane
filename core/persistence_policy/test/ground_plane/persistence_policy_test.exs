defmodule GroundPlane.PersistencePolicyTest do
  use ExUnit.Case, async: true

  alias GroundPlane.PersistencePolicy
  alias GroundPlane.PersistencePolicy.DebugTap

  defmodule FailingTap do
    @behaviour DebugTap

    @impl true
    def emit(tap, _event), do: {:error, {:tap_down, tap}}
  end

  test "no-config boot resolves to mickey mouse memory mode" do
    assert %PersistencePolicy.Profile{} = profile = PersistencePolicy.resolve!([])
    assert profile.id == :mickey_mouse
    assert profile.default_tier == :memory_ephemeral
    assert profile.capture_level == :off
    assert profile.debug_tap == DebugTap.Noop
    refute profile.durable?
  end

  test "memory default uses only memory stores and no durable preflight calls" do
    profile = PersistencePolicy.resolve!([])

    assert :ok =
             PersistencePolicy.preflight(profile, [], fn _capability ->
               send(self(), :durable_preflight_called)
               :ok
             end)

    refute_received :durable_preflight_called
  end

  test "unsupported profile and tier fail closed" do
    assert {:error, {:unsupported_profile, :unknown}} =
             PersistencePolicy.resolve(profile: :unknown)

    assert {:error, {:unsupported_tier, :external_optional}} =
             PersistencePolicy.Tier.validate(:external_optional)
  end

  test "resolver uses explicit platform precedence without external reads" do
    assert {:ok, profile} =
             PersistencePolicy.resolve(%{
               "global_profile" => :integration_postgres,
               "tenant_policy_profile" => :memory_debug,
               "profile" => :mickey_mouse
             })

    assert profile.id == :mickey_mouse

    assert {:ok, fallback_profile} =
             PersistencePolicy.resolve(%{
               "global_profile" => :integration_postgres,
               "tenant_policy_profile" => :memory_debug
             })

    assert fallback_profile.id == :memory_debug
  end

  test "resolver preserves false and nil atom-key precedence over string fallback" do
    assert {:error, {:unsupported_profile, false}} =
             PersistencePolicy.resolve(%{"profile" => :mickey_mouse, profile: false})

    assert {:ok, profile} =
             PersistencePolicy.resolve(%{
               "profile" => :memory_debug,
               profile: nil,
               global_profile: :integration_postgres
             })

    assert profile.id == :integration_postgres
  end

  test "resolver handles empty string and string-key profile values explicitly" do
    assert {:ok, profile} = PersistencePolicy.resolve(%{"profile" => :memory_debug})
    assert profile.id == :memory_debug

    assert {:ok, fallback_profile} =
             PersistencePolicy.resolve(%{
               "profile" => "",
               "global_profile" => :integration_postgres
             })

    assert fallback_profile.id == :integration_postgres
  end

  test "store capability preserves explicit false atom and string values" do
    assert {:ok, atom_key_capability} =
             PersistencePolicy.StoreCapability.new(%{
               "restart_safe?" => true,
               store_ref: :memory,
               tier: :memory_ephemeral,
               data_classes: [:all],
               adapter: :memory,
               restart_safe?: false
             })

    refute atom_key_capability.restart_safe?

    assert {:ok, string_key_capability} =
             PersistencePolicy.StoreCapability.new(%{
               "store_ref" => :memory,
               "tier" => :memory_ephemeral,
               "data_classes" => [:all],
               "adapter" => :memory,
               "restart_safe?" => false
             })

    refute string_key_capability.restart_safe?
  end

  test "store capability preserves nil atom keys instead of falling through to string keys" do
    assert {:error, {:unsupported_tier, nil}} =
             PersistencePolicy.StoreCapability.new(%{
               "tier" => :memory_ephemeral,
               store_ref: :memory,
               tier: nil,
               data_classes: [:all],
               adapter: :memory
             })
  end

  test "store capability rejects missing or blank store refs" do
    assert {:error, {:invalid_store_ref, nil}} =
             PersistencePolicy.StoreCapability.new(
               tier: :memory_ephemeral,
               data_classes: [:all],
               adapter: :memory
             )

    assert {:error, {:invalid_store_ref, ""}} =
             PersistencePolicy.StoreCapability.new(
               store_ref: "",
               tier: :memory_ephemeral,
               data_classes: [:all],
               adapter: :memory
             )
  end

  test "store capability rejects invalid adapters" do
    assert {:error, {:invalid_adapter, nil}} =
             PersistencePolicy.StoreCapability.new(
               store_ref: :memory,
               tier: :memory_ephemeral,
               data_classes: [:all]
             )

    assert {:error, {:invalid_adapter, "memory"}} =
             PersistencePolicy.StoreCapability.new(
               store_ref: :memory,
               tier: :memory_ephemeral,
               data_classes: [:all],
               adapter: "memory"
             )
  end

  test "store capability validates and converts partitions" do
    assert {:ok, capability} =
             PersistencePolicy.StoreCapability.new(
               store_ref: :memory,
               tier: :memory_ephemeral,
               data_classes: [:all],
               adapter: :memory,
               partitions: [%{"tenant_ref" => "tenant-1", resource_ref: "resource-1"}]
             )

    assert [
             %PersistencePolicy.Partition{
               tenant_ref: "tenant-1",
               resource_ref: "resource-1"
             }
           ] = capability.partitions

    assert {:error, {:invalid_partition, :bad_partition}} =
             PersistencePolicy.StoreCapability.new(
               store_ref: :memory,
               tier: :memory_ephemeral,
               data_classes: [:all],
               adapter: :memory,
               partitions: [:bad_partition]
             )
  end

  test "durable profile preflight fails early instead of falling back to memory" do
    profile = PersistencePolicy.resolve!(profile: :integration_postgres)

    assert profile.durable?

    assert {:error, {:missing_store_capability, :postgres_shared}} =
             PersistencePolicy.preflight(profile, [], fn _capability -> :ok end)
  end

  test "durable profile preflight uses caller supplied capabilities" do
    profile = PersistencePolicy.resolve!(profile: :integration_postgres)

    assert {:ok, capability} =
             PersistencePolicy.StoreCapability.new(
               store_ref: :primary_postgres,
               tier: :postgres_shared,
               data_classes: [:all],
               adapter: :ground_plane_postgres
             )

    assert capability.durable?
    assert :ok = PersistencePolicy.preflight(profile, [capability], fn ^capability -> :ok end)
  end

  test "raw secret, prompt, and external payload capture is rejected" do
    for key <- [:raw_secret, :raw_prompt, :external_payload, "authorization_header"] do
      assert {:error, {:raw_debug_capture_forbidden, ^key}} =
               PersistencePolicy.Redaction.validate_event(%{key => "raw"})
    end
  end

  test "debug tap failure does not mutate tap state" do
    tap = %{events: []}

    assert {:error, {:debug_tap_failed, {:tap_down, ^tap}}, ^tap} =
             PersistencePolicy.emit_debug(FailingTap, tap, %{safe_ref: "trace://a"})
  end

  test "memory ring stores bounded redacted metadata only" do
    tap = DebugTap.MemoryRing.new(limit: 2)

    assert {:ok, tap} = PersistencePolicy.emit_debug(DebugTap.MemoryRing, tap, %{safe_ref: "a"})
    assert {:ok, tap} = PersistencePolicy.emit_debug(DebugTap.MemoryRing, tap, %{safe_ref: "b"})
    assert {:ok, tap} = PersistencePolicy.emit_debug(DebugTap.MemoryRing, tap, %{safe_ref: "c"})

    assert Enum.map(tap.events, & &1.safe_ref) == ["b", "c"]
  end

  test "test matrix names built-in profiles and capture levels" do
    matrix = PersistencePolicy.test_matrix()

    assert :mickey_mouse in matrix.profiles
    assert :memory_debug in matrix.profiles
    assert :off in matrix.capture_levels
    assert :redacted_debug in matrix.capture_levels
  end
end
