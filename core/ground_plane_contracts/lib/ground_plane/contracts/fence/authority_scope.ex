defmodule GroundPlane.Contracts.Fence.AuthorityScope do
  @moduledoc "Authority revision facts for a fenced lease."

  @fields [
    :installation_revision_ref,
    :policy_revision_ref,
    :target_grant_revision
  ]

  @retry_required_context [
    :idempotency_key,
    :dispatch_ref,
    :active_execution_ref,
    :current_execution_ref,
    :retry_authority_ref,
    :materialization_epoch
  ]

  @restart_revalidation_events [
    :target_detach,
    :sandbox_restart,
    :process_crash,
    :stream_reconnect,
    :lifecycle_resume,
    :orchestration_resume
  ]

  defstruct @fields

  @type t :: %__MODULE__{}

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_list(attrs), do: attrs |> Map.new() |> new()

  def new(attrs) when is_map(attrs) do
    Enum.reduce_while(@fields, {:ok, %{}}, fn field, {:ok, values} ->
      case optional_string(attrs, field) do
        {:ok, value} -> {:cont, {:ok, Map.put(values, field, value)}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, struct(__MODULE__, values)}
      {:error, _reason} = error -> error
    end
  end

  @spec checks() :: keyword(atom())
  def checks do
    [
      installation_revision_ref: :stale_installation_revision,
      policy_revision_ref: :stale_policy_revision,
      target_grant_revision: :stale_target_grant
    ]
  end

  @spec retry_required_context() :: [atom()]
  def retry_required_context, do: @retry_required_context

  @spec restart_revalidation_event?(atom()) :: boolean()
  def restart_revalidation_event?(event), do: event in @restart_revalidation_events

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = scope) do
    scope
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp optional_string(attrs, field) do
    case value(attrs, field) do
      nil -> {:ok, nil}
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, {:invalid_authority_field, field}}
    end
  end

  defp value(attrs, field), do: Map.get(attrs, field, Map.get(attrs, Atom.to_string(field)))
end
