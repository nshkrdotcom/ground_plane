defmodule GroundPlane.PersistencePolicy do
  @moduledoc """
  Pure persistence profile, tier, capture, store-set, partition, and debug
  contract.

  The built-in default is `:mickey_mouse`: memory-only and free of durable
  infrastructure requirements.
  """

  alias __MODULE__.CaptureLevel
  alias __MODULE__.DebugTap
  alias __MODULE__.Partition
  alias __MODULE__.Profile
  alias __MODULE__.Redaction
  alias __MODULE__.StoreCapability
  alias __MODULE__.StoreSet
  alias __MODULE__.Tier

  @built_in_profiles [
    :mickey_mouse,
    :memory_debug,
    :local_restart_safe,
    :integration_postgres,
    :ops_durable,
    :full_debug_tracked,
    :distributed_partitioned
  ]

  @precedence_keys [
    :profile,
    :persistence_profile,
    :restart_profile,
    :session_profile,
    :authority_profile,
    :tenant_policy_profile,
    :host_profile,
    :release_profile,
    :package_profile,
    :global_profile
  ]

  @spec built_in_profiles() :: [atom()]
  def built_in_profiles, do: @built_in_profiles

  @spec resolve!(keyword() | map()) :: Profile.t()
  def resolve!(attrs) do
    case resolve(attrs) do
      {:ok, profile} -> profile
      {:error, reason} -> raise ArgumentError, message: inspect(reason)
    end
  end

  @spec resolve(keyword() | map()) :: {:ok, Profile.t()} | {:error, term()}
  def resolve(attrs) do
    attrs = normalize_attrs(attrs)

    profile_id =
      case first_present_profile(attrs) do
        nil -> :mickey_mouse
        profile_id -> profile_id
      end

    built_in_profile(profile_id)
  end

  @spec built_in_profile(atom()) :: {:ok, Profile.t()} | {:error, term()}
  def built_in_profile(:mickey_mouse) do
    {:ok,
     %Profile{
       id: :mickey_mouse,
       default_tier: :memory_ephemeral,
       capture_level: :off,
       debug_tap: DebugTap.Noop,
       store_set: memory_store_set(),
       durable?: false,
       required_live_state?: false,
       metadata: %{restart_claim: :none}
     }}
  end

  def built_in_profile(:memory_debug) do
    {:ok,
     %Profile{
       id: :memory_debug,
       default_tier: :memory_ephemeral,
       capture_level: :redacted_debug,
       debug_tap: DebugTap.MemoryRing,
       store_set: memory_store_set(),
       durable?: false,
       required_live_state?: false,
       metadata: %{restart_claim: :none}
     }}
  end

  def built_in_profile(:local_restart_safe) do
    durable_profile(:local_restart_safe, :local_restart_safe, :metadata)
  end

  def built_in_profile(:integration_postgres) do
    durable_profile(:integration_postgres, :postgres_shared, :refs_only)
  end

  def built_in_profile(:ops_durable) do
    durable_profile(:ops_durable, :temporal_durable, :refs_only)
  end

  def built_in_profile(:full_debug_tracked) do
    durable_profile(:full_debug_tracked, :postgres_shared, :full_debug)
  end

  def built_in_profile(:distributed_partitioned) do
    durable_profile(:distributed_partitioned, :postgres_shared, :metadata)
  end

  def built_in_profile(profile), do: {:error, {:unsupported_profile, profile}}

  @spec preflight(Profile.t(), [StoreCapability.t()], (StoreCapability.t() ->
                                                         :ok | {:error, term()})) ::
          :ok | {:error, term()}
  def preflight(%Profile{durable?: false}, _capabilities, _checker), do: :ok

  def preflight(%Profile{} = profile, capabilities, checker) when is_list(capabilities) do
    with {:ok, _tier} <- Tier.validate(profile.default_tier),
         capability when not is_nil(capability) <-
           Enum.find(capabilities, &(&1.tier == profile.default_tier)),
         :ok <- checker.(capability) do
      :ok
    else
      nil -> {:error, {:missing_store_capability, profile.default_tier}}
      {:error, reason} -> {:error, reason}
      error -> error
    end
  end

  @spec emit_debug(module(), term(), map()) :: {:ok, term()} | {:error, term(), term()}
  def emit_debug(tap_module, tap, event) when is_atom(tap_module) do
    case Redaction.validate_event(event) do
      :ok ->
        case tap_module.emit(tap, event) do
          {:ok, next_tap} -> {:ok, next_tap}
          {:error, reason} -> {:error, {:debug_tap_failed, reason}, tap}
        end

      {:error, reason} ->
        {:error, reason, tap}
    end
  end

  @spec test_matrix() :: map()
  def test_matrix do
    %{
      profiles: @built_in_profiles,
      tiers: Tier.all(),
      capture_levels: CaptureLevel.all(),
      partition_fields: Partition.fields()
    }
  end

  defp durable_profile(id, tier, capture_level) do
    with {:ok, tier} <- Tier.validate(tier),
         {:ok, capture_level} <- CaptureLevel.validate(capture_level) do
      {:ok,
       %Profile{
         id: id,
         default_tier: tier,
         capture_level: capture_level,
         debug_tap: debug_tap_for(capture_level),
         store_set: durable_store_set(id, tier),
         durable?: true,
         required_live_state?: tier == :temporal_durable,
         metadata: %{restart_claim: restart_claim(tier)}
       }}
    end
  end

  defp memory_store_set do
    %StoreSet{
      id: :mickey_mouse_memory,
      default_tier: :memory_ephemeral,
      capabilities: [
        %StoreCapability{
          store_ref: :memory_ephemeral,
          tier: :memory_ephemeral,
          data_classes: [:all],
          adapter: :memory,
          restart_safe?: false,
          durable?: false,
          partitions: []
        }
      ],
      partitions: []
    }
  end

  defp durable_store_set(id, tier) do
    %StoreSet{
      id: id,
      default_tier: tier,
      capabilities: [
        %StoreCapability{
          store_ref: tier,
          tier: tier,
          data_classes: [:all],
          adapter: tier,
          restart_safe?: tier in [:local_restart_safe, :postgres_shared, :temporal_durable],
          durable?: true,
          partitions: [%Partition{}]
        }
      ],
      partitions: [%Partition{}]
    }
  end

  defp debug_tap_for(:off), do: DebugTap.Noop
  defp debug_tap_for(:refs_only), do: DebugTap.Noop
  defp debug_tap_for(_capture_level), do: DebugTap.MemoryRing

  defp restart_claim(:local_restart_safe), do: :restart_safe
  defp restart_claim(:postgres_shared), do: :durable
  defp restart_claim(:temporal_durable), do: :durable_restart
  defp restart_claim(:object_store), do: :durable_artifact
  defp restart_claim(_tier), do: :none

  defp normalize_attrs(attrs) when is_list(attrs), do: Map.new(attrs)
  defp normalize_attrs(attrs) when is_map(attrs), do: attrs

  defp first_present_profile(attrs) do
    @precedence_keys
    |> Enum.map(&value(attrs, &1))
    |> Enum.find(&present?/1)
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value), do: not is_nil(value)

  defp value(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} -> value
      :error -> Map.get(attrs, Atom.to_string(field))
    end
  end
end
