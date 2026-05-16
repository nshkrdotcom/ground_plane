defmodule GroundPlane.PersistencePolicyDataExtension do
  @moduledoc """
  Data persistence policy extension.

  Every data class defaults to memory. Durable selections must be explicitly
  present in the provided capability set.
  """

  defmodule Profile do
    @moduledoc "Data persistence profile."
    @enforce_keys [:id, :data_classes]
    defstruct [
      :id,
      durable_restart_owner: :disabled,
      debug_sidecar: :disabled,
      vector_store: :disabled,
      data_classes: %{}
    ]

    @type t :: %__MODULE__{
            id: atom(),
            durable_restart_owner: atom(),
            debug_sidecar: atom(),
            vector_store: atom(),
            data_classes: map()
          }
  end

  defmodule Capability do
    @moduledoc "Store capability descriptor."
    @enforce_keys [:data_class, :tier, :adapter]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            data_class: atom(),
            tier: atom(),
            adapter: atom()
          }
  end

  @memory_tier :memory_ephemeral

  @data_classes [
    :cache_entry,
    :index_entry,
    :working_entry,
    :budget_counter,
    :artifact_blob,
    :guard_result,
    :evaluation_bundle,
    :replay_bundle,
    :drift_marker,
    :meter_reading,
    :cost_record,
    :limit_decision,
    :admission_record,
    :projection_record,
    :skill_record,
    :message_record
  ]

  @raw_payload_policies %{
    cache_entry: :no_raw_body_in_projection_or_trace,
    index_entry: :hash_or_redacted_excerpt_only,
    working_entry: :bounded_no_raw_projection,
    budget_counter: :redacted_units,
    artifact_blob: :body_never_exported_by_default,
    guard_result: :bounded_violation_excerpts_only,
    evaluation_bundle: :payload_hash_or_claim_check_only,
    replay_bundle: :external_effects_suppressed,
    drift_marker: :no_raw_evaluation_payloads,
    meter_reading: :count_classes_only,
    cost_record: :redacted_amount_thresholds,
    limit_decision: :no_payment_or_secret_metadata,
    admission_record: :no_secret_or_account_ids,
    projection_record: :dto_only_refs_and_redacted_excerpts,
    skill_record: :no_private_state_bodies,
    message_record: :message_body_hash_or_redacted_excerpt_only
  }

  @spec data_classes() :: [atom()]
  def data_classes, do: @data_classes

  @spec memory_default_profile() :: Profile.t()
  def memory_default_profile do
    %Profile{
      id: :mickey_mouse,
      data_classes: Map.new(@data_classes, &{&1, default_descriptor(&1)})
    }
  end

  @spec default_descriptor(atom()) :: map()
  def default_descriptor(data_class) when data_class in @data_classes do
    %{
      data_class: data_class,
      default_tier: @memory_tier,
      durable_opt_in: durable_options(data_class),
      raw_payload_policy: Map.fetch!(@raw_payload_policies, data_class)
    }
  end

  @spec preflight(Profile.t(), atom(), atom(), [Capability.t()]) :: :ok | {:error, term()}
  def preflight(%Profile{} = profile, data_class, tier, capabilities)
      when data_class in @data_classes and is_list(capabilities) do
    selected_tier = tier || selected_tier(profile, data_class)

    cond do
      selected_tier == @memory_tier ->
        :ok

      selected_tier in durable_options(data_class) ->
        require_capability(data_class, selected_tier, capabilities)

      true ->
        {:error, {:unsupported_data_persistence_tier, data_class, selected_tier}}
    end
  end

  def preflight(%Profile{}, data_class, _tier, _capabilities),
    do: {:error, {:unknown_data_class, data_class}}

  @spec debug_redaction_allowed?(atom()) :: boolean()
  def debug_redaction_allowed?(data_class) when data_class in @data_classes, do: true
  def debug_redaction_allowed?(_data_class), do: false

  defp selected_tier(%Profile{data_classes: data_classes}, data_class) do
    data_classes
    |> Map.get(data_class, default_descriptor(data_class))
    |> Map.get(:selected_tier, @memory_tier)
  end

  defp require_capability(data_class, tier, capabilities) do
    if Enum.any?(capabilities, &capability_matches?(&1, data_class, tier)) do
      :ok
    else
      {:error, {:missing_durable_store_capability, data_class, tier}}
    end
  end

  defp capability_matches?(%Capability{data_class: data_class, tier: tier}, data_class, tier),
    do: true

  defp capability_matches?(_capability, _data_class, _tier), do: false

  defp durable_options(:cache_entry),
    do: [:local_restart_safe, :postgres_shared, :vector_claim_check]

  defp durable_options(:index_entry),
    do: [:local_restart_safe, :postgres_shared, :vector_claim_check]

  defp durable_options(:working_entry), do: [:local_restart_safe]
  defp durable_options(:budget_counter), do: [:postgres_shared, :temporal_durable]
  defp durable_options(:projection_record), do: [:local_restart_safe, :postgres_shared]
  defp durable_options(_data_class), do: [:postgres_shared, :object_store]
end
