defmodule GroundPlane.Contracts.PersistencePosture do
  @moduledoc """
  Ref-only persistence posture for lower leases, fences, and checkpoints.

  This module mirrors the built-in GroundPlane policy vocabulary without
  reading environment, starting durable substrates, or authorizing effects.
  """

  @components [
    :credential_lease_fence,
    :revocation_epoch,
    :restart_checkpoint,
    :duplicate_dispatch_fence,
    :ai_run_fence_receipt
  ]

  @profiles %{
    mickey_mouse: %{
      tier: :memory_ephemeral,
      capture_level: :off,
      store_set: :mickey_mouse_memory,
      durable?: false,
      restart_claim: :none,
      retention: "retention://process-lifetime"
    },
    memory_debug: %{
      tier: :memory_ephemeral,
      capture_level: :redacted_debug,
      store_set: :mickey_mouse_memory,
      durable?: false,
      restart_claim: :none,
      retention: "retention://process-lifetime",
      debug_tap: "debug-tap://memory-ring"
    },
    local_restart_safe: %{
      tier: :local_restart_safe,
      capture_level: :metadata,
      store_set: :local_restart_safe,
      durable?: true,
      restart_claim: :restart_safe,
      retention: "retention://local_restart_safe"
    },
    integration_postgres: %{
      tier: :postgres_shared,
      capture_level: :refs_only,
      store_set: :integration_postgres,
      durable?: true,
      restart_claim: :durable,
      retention: "retention://postgres_shared"
    },
    ops_durable: %{
      tier: :temporal_durable,
      capture_level: :refs_only,
      store_set: :ops_durable,
      durable?: true,
      restart_claim: :durable_workflow,
      retention: "retention://temporal_durable"
    },
    full_debug_tracked: %{
      tier: :postgres_shared,
      capture_level: :full_debug,
      store_set: :full_debug_tracked,
      durable?: true,
      restart_claim: :durable,
      retention: "retention://postgres_shared",
      debug_tap: "debug-tap://memory-ring"
    },
    distributed_partitioned: %{
      tier: :postgres_shared,
      capture_level: :metadata,
      store_set: :distributed_partitioned,
      durable?: true,
      restart_claim: :durable,
      retention: "retention://postgres_shared"
    }
  }

  @type t :: map()

  @spec components() :: [atom()]
  def components, do: @components

  @spec memory(atom()) :: t()
  def memory(component), do: resolve(component, profile: :mickey_mouse)

  @spec resolve(atom(), map() | keyword()) :: t()
  def resolve(component, attrs \\ []) when component in @components do
    attrs = normalize_attrs(attrs)

    case value(attrs, :persistence_posture) do
      posture when is_map(posture) -> normalize_posture(component, posture)
      _missing -> profile_posture(component, profile_id(attrs))
    end
  end

  @spec durable?(t()) :: boolean()
  def durable?(posture) when is_map(posture), do: value(posture, :durable?) == true

  @spec preflight(t(), [map()]) :: :ok | {:error, term()}
  def preflight(posture, capabilities) when is_map(posture) and is_list(capabilities) do
    if durable?(posture) do
      tier = value(posture, :tier)

      case Enum.find(capabilities, &(value(&1, :tier) == tier)) do
        nil -> {:error, {:missing_store_capability, tier}}
        _capability -> :ok
      end
    else
      :ok
    end
  end

  @spec capability(atom(), atom()) :: map()
  def capability(component, tier) when component in @components do
    %{
      component: component,
      tier: tier,
      store_ref: "store://#{Atom.to_string(tier)}",
      durable?: tier in [:local_restart_safe, :postgres_shared, :temporal_durable, :object_store]
    }
  end

  defp profile_posture(component, profile_id) do
    profile = Map.fetch!(@profiles, profile_id)
    tier = Map.fetch!(profile, :tier)

    %{
      component: component,
      profile: profile_id,
      tier: tier,
      persistence_profile_ref: "persistence-profile://#{Atom.to_string(profile_id)}",
      persistence_tier_ref: "persistence-tier://#{Atom.to_string(tier)}",
      capture_level_ref: "capture-level://#{Atom.to_string(Map.fetch!(profile, :capture_level))}",
      store_set_ref: "store-set://#{Atom.to_string(Map.fetch!(profile, :store_set))}",
      store_partition_ref: partition_ref(profile),
      retention_policy_ref: Map.fetch!(profile, :retention),
      debug_tap_ref: Map.get(profile, :debug_tap),
      persistence_receipt_ref:
        "persistence-receipt://ground-plane/#{Atom.to_string(component)}/#{Atom.to_string(profile_id)}",
      store_ref: "store://#{Atom.to_string(tier)}",
      durable?: Map.fetch!(profile, :durable?),
      restart_durability_claim: Map.fetch!(profile, :restart_claim)
    }
  end

  defp normalize_posture(component, posture) do
    default = profile_posture(component, :mickey_mouse)

    %{
      component: component,
      profile: value(posture, :profile) || :external,
      tier: value(posture, :tier) || :memory_ephemeral,
      persistence_profile_ref:
        string_or_default(posture, :persistence_profile_ref, default.persistence_profile_ref),
      persistence_tier_ref:
        string_or_default(posture, :persistence_tier_ref, default.persistence_tier_ref),
      capture_level_ref:
        string_or_default(posture, :capture_level_ref, default.capture_level_ref),
      store_set_ref: string_or_default(posture, :store_set_ref, default.store_set_ref),
      store_partition_ref: optional_string(posture, :store_partition_ref),
      retention_policy_ref:
        string_or_default(posture, :retention_policy_ref, default.retention_policy_ref),
      debug_tap_ref: optional_string(posture, :debug_tap_ref),
      persistence_receipt_ref:
        string_or_default(posture, :persistence_receipt_ref, default.persistence_receipt_ref),
      store_ref: string_or_default(posture, :store_ref, default.store_ref),
      durable?: value(posture, :durable?) == true,
      restart_durability_claim: value(posture, :restart_durability_claim) || :none
    }
  end

  defp partition_ref(%{durable?: true, tier: tier}),
    do: "store-partition://#{Atom.to_string(tier)}/default"

  defp partition_ref(_profile), do: nil

  defp profile_id(attrs) do
    attrs
    |> Enum.find_value(fn {key, candidate} ->
      if key in [:profile, "profile", :persistence_profile, "persistence_profile"] do
        profile_candidate(candidate)
      end
    end)
    |> case do
      nil -> :mickey_mouse
      profile -> profile
    end
  end

  defp profile_candidate(value) when is_atom(value) and is_map_key(@profiles, value), do: value

  defp profile_candidate(value) when is_binary(value) do
    Enum.find(Map.keys(@profiles), fn profile -> Atom.to_string(profile) == value end)
  end

  defp profile_candidate(_value), do: nil

  defp normalize_attrs(attrs) when is_list(attrs), do: Map.new(attrs)
  defp normalize_attrs(attrs) when is_map(attrs), do: attrs

  defp string_or_default(attrs, key, default) do
    case value(attrs, key) do
      current when is_binary(current) and current != "" -> current
      _other -> default
    end
  end

  defp optional_string(attrs, key) do
    case value(attrs, key) do
      current when is_binary(current) and current != "" -> current
      _other -> nil
    end
  end

  defp value(attrs, field) when is_atom(field),
    do: Map.get(attrs, field) || Map.get(attrs, Atom.to_string(field))
end
