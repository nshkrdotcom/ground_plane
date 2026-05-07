defmodule GroundPlane.PersistencePolicy do
  @moduledoc """
  Pure persistence profile, tier, capture, store-set, partition, and debug
  contract.

  The built-in default is `:mickey_mouse`: memory-only and free of durable
  infrastructure requirements.
  """

  defmodule Tier do
    @moduledoc "Persistence tier enum."

    @tiers [
      :off,
      :memory_ephemeral,
      :local_restart_safe,
      :postgres_shared,
      :temporal_durable,
      :object_store
    ]

    @durable_tiers [
      :local_restart_safe,
      :postgres_shared,
      :temporal_durable,
      :object_store
    ]

    @spec all() :: [atom()]
    def all, do: @tiers

    @spec durable() :: [atom()]
    def durable, do: @durable_tiers

    @spec validate(atom()) :: {:ok, atom()} | {:error, term()}
    def validate(tier) when tier in @tiers, do: {:ok, tier}
    def validate(tier), do: {:error, {:unsupported_tier, tier}}

    @spec durable?(atom()) :: boolean()
    def durable?(tier), do: tier in @durable_tiers
  end

  defmodule CaptureLevel do
    @moduledoc "Debug capture-level enum."

    @levels [
      :off,
      :refs_only,
      :metadata,
      :redacted_debug,
      :full_debug
    ]

    @spec all() :: [atom()]
    def all, do: @levels

    @spec validate(atom()) :: {:ok, atom()} | {:error, term()}
    def validate(level) when level in @levels, do: {:ok, level}
    def validate(level), do: {:error, {:unsupported_capture_level, level}}
  end

  defmodule Partition do
    @moduledoc "Store-set partition dimensions."

    @fields [
      :tenant_ref,
      :installation_ref,
      :provider_family,
      :provider_ref,
      :provider_account_ref,
      :connector_instance_ref,
      :target_ref,
      :environment_ref,
      :region_ref,
      :data_class,
      :capture_level,
      :retention_class
    ]

    @enforce_keys []
    defstruct @fields

    @type t :: %__MODULE__{}

    @spec fields() :: [atom()]
    def fields, do: @fields
  end

  defmodule StoreCapability do
    @moduledoc "Descriptor for an available persistence adapter capability."

    @enforce_keys [:store_ref, :tier, :data_classes, :adapter]
    defstruct [
      :store_ref,
      :tier,
      :data_classes,
      :adapter,
      restart_safe?: false,
      durable?: false,
      partitions: []
    ]

    @type t :: %__MODULE__{
            store_ref: String.t() | atom(),
            tier: atom(),
            data_classes: [atom()],
            adapter: atom(),
            restart_safe?: boolean(),
            durable?: boolean(),
            partitions: [Partition.t()]
          }

    @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
    def new(attrs) do
      attrs = Map.new(attrs)

      with {:ok, tier} <- Tier.validate(value(attrs, :tier)),
           true <- is_list(value(attrs, :data_classes)) do
        {:ok,
         %__MODULE__{
           store_ref: value(attrs, :store_ref),
           tier: tier,
           data_classes: value(attrs, :data_classes),
           adapter: value(attrs, :adapter),
           restart_safe?: value(attrs, :restart_safe?) || false,
           durable?: Tier.durable?(tier),
           partitions: List.wrap(value(attrs, :partitions) || [])
         }}
      else
        false -> {:error, {:invalid_store_capability, :data_classes}}
        error -> error
      end
    end

    defp value(attrs, field), do: Map.get(attrs, field) || Map.get(attrs, Atom.to_string(field))
  end

  defmodule StoreSet do
    @moduledoc "Selected store set and partition posture."

    @enforce_keys [:id, :default_tier, :capabilities]
    defstruct [
      :id,
      :default_tier,
      :capabilities,
      partitions: []
    ]

    @type t :: %__MODULE__{
            id: atom(),
            default_tier: atom(),
            capabilities: [StoreCapability.t()],
            partitions: [Partition.t()]
          }
  end

  defmodule Profile do
    @moduledoc "Resolved persistence profile."

    @enforce_keys [:id, :default_tier, :capture_level, :store_set, :debug_tap]
    defstruct [
      :id,
      :default_tier,
      :capture_level,
      :store_set,
      :debug_tap,
      durable?: false,
      required_live_state?: false,
      metadata: %{}
    ]

    @type t :: %__MODULE__{
            id: atom(),
            default_tier: atom(),
            capture_level: atom(),
            store_set: StoreSet.t(),
            debug_tap: module(),
            durable?: boolean(),
            required_live_state?: boolean(),
            metadata: map()
          }
  end

  defmodule Redaction do
    @moduledoc "Debug capture redaction constraints."

    @forbidden_keys [
      :raw_secret,
      :secret,
      :api_key,
      :oauth_secret,
      :token_file,
      :credential_body,
      :authorization_header,
      :auth_header,
      :raw_prompt,
      :prompt_body,
      :provider_payload,
      :raw_provider_payload,
      :provider_account_identifier,
      "raw_secret",
      "secret",
      "api_key",
      "oauth_secret",
      "token_file",
      "credential_body",
      "authorization_header",
      "auth_header",
      "raw_prompt",
      "prompt_body",
      "provider_payload",
      "raw_provider_payload",
      "provider_account_identifier"
    ]

    @spec forbidden_keys() :: [atom() | String.t()]
    def forbidden_keys, do: @forbidden_keys

    @spec validate_event(map()) :: :ok | {:error, term()}
    def validate_event(event) when is_map(event) do
      case Enum.find(@forbidden_keys, &has_key_deep?(event, &1)) do
        nil -> :ok
        key -> {:error, {:raw_debug_capture_forbidden, key}}
      end
    end

    def validate_event(_event), do: {:error, :invalid_debug_event}

    defp has_key_deep?(attrs, key) when is_map(attrs) do
      Map.has_key?(attrs, key) or Enum.any?(Map.values(attrs), &has_key_deep?(&1, key))
    end

    defp has_key_deep?(items, key) when is_list(items),
      do: Enum.any?(items, &has_key_deep?(&1, key))

    defp has_key_deep?(_value, _key), do: false
  end

  defmodule DebugTap do
    @moduledoc "Debug tap behaviour. Taps are optional and must not own truth."

    @callback emit(tap :: term(), event :: map()) :: {:ok, term()} | {:error, term()}

    defmodule Noop do
      @moduledoc "Debug tap that records nothing."
      @behaviour GroundPlane.PersistencePolicy.DebugTap

      @impl true
      def emit(tap, _event), do: {:ok, tap}
    end

    defmodule MemoryRing do
      @moduledoc "Bounded in-memory debug tap for redacted metadata."
      @behaviour GroundPlane.PersistencePolicy.DebugTap

      defstruct limit: 32, events: []

      @type t :: %__MODULE__{limit: pos_integer(), events: [map()]}

      @spec new(keyword()) :: t()
      def new(opts \\ []) do
        limit = Keyword.get(opts, :limit, 32)
        %__MODULE__{limit: max(limit, 1), events: []}
      end

      @impl true
      def emit(%__MODULE__{} = tap, event) when is_map(event) do
        with :ok <- Redaction.validate_event(event) do
          event = normalize_event(event)
          {:ok, %{tap | events: keep_latest(tap.events ++ [event], tap.limit)}}
        end
      end

      def emit(%__MODULE__{} = _tap, _event), do: {:error, :invalid_debug_event}

      defp normalize_event(event) do
        %{
          safe_ref: value(event, :safe_ref),
          hash_ref: value(event, :hash_ref),
          metadata: value(event, :metadata) || %{}
        }
      end

      defp keep_latest(events, limit) do
        events
        |> Enum.reverse()
        |> Enum.take(limit)
        |> Enum.reverse()
      end

      defp value(attrs, field), do: Map.get(attrs, field) || Map.get(attrs, Atom.to_string(field))
    end
  end

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
    :workflow_profile,
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
    profile_id = first_present_profile(attrs) || :mickey_mouse
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
  defp restart_claim(:temporal_durable), do: :durable_workflow
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

  defp value(attrs, field), do: Map.get(attrs, field) || Map.get(attrs, Atom.to_string(field))
end
