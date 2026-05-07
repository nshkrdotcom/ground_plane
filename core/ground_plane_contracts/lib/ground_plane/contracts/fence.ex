defmodule GroundPlane.Contracts.Fence do
  @moduledoc """
  Struct and comparison helpers for fenced ownership.
  """

  alias GroundPlane.Contracts.Lease
  alias GroundPlane.Contracts.PersistencePosture

  defstruct [
    :resource,
    :holder,
    :lease_id,
    :epoch,
    :tenant_id,
    :provider_family,
    :provider_account_ref,
    :connector_instance_ref,
    :credential_handle_ref,
    :credential_lease_ref,
    :operation_class,
    :target_ref,
    :attach_grant_ref,
    :operation_policy_ref,
    :installation_revision_ref,
    :policy_revision_ref,
    :target_grant_revision,
    :rotation_epoch,
    :fence_token,
    :persistence_posture
  ]

  @type t :: %__MODULE__{
          resource: String.t(),
          holder: String.t(),
          lease_id: String.t(),
          epoch: non_neg_integer(),
          tenant_id: String.t() | nil,
          provider_family: String.t() | nil,
          provider_account_ref: String.t() | nil,
          connector_instance_ref: String.t() | nil,
          credential_handle_ref: String.t() | nil,
          credential_lease_ref: String.t() | nil,
          operation_class: String.t() | nil,
          target_ref: String.t() | nil,
          attach_grant_ref: String.t() | nil,
          operation_policy_ref: String.t() | nil,
          installation_revision_ref: String.t() | nil,
          policy_revision_ref: String.t() | nil,
          target_grant_revision: String.t() | nil,
          rotation_epoch: non_neg_integer() | nil,
          fence_token: String.t() | nil,
          persistence_posture: map() | nil
        }

  @credential_scope_checks [
    tenant_id: :tenant_mismatch,
    provider_family: :provider_family_mismatch,
    provider_account_ref: :provider_account_mismatch,
    connector_instance_ref: :connector_mismatch,
    credential_handle_ref: :credential_handle_mismatch,
    credential_lease_ref: :credential_lease_mismatch,
    operation_class: :operation_class_mismatch,
    target_ref: :target_mismatch,
    attach_grant_ref: :attach_grant_mismatch,
    operation_policy_ref: :operation_policy_mismatch,
    installation_revision_ref: :stale_installation_revision,
    policy_revision_ref: :stale_policy_revision,
    target_grant_revision: :stale_target_grant,
    rotation_epoch: :rotation_epoch_mismatch,
    fence_token: :fence_token_mismatch
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
    :workflow_resume
  ]

  @spec from_lease(Lease.t()) :: t()
  def from_lease(%Lease{} = lease) do
    %__MODULE__{
      resource: lease.resource,
      holder: lease.holder,
      lease_id: lease.lease_id,
      epoch: lease.epoch,
      tenant_id: lease.tenant_id,
      provider_family: lease.provider_family,
      provider_account_ref: lease.provider_account_ref,
      connector_instance_ref: lease.connector_instance_ref,
      credential_handle_ref: lease.credential_handle_ref,
      credential_lease_ref: lease.credential_lease_ref,
      operation_class: lease.operation_class,
      target_ref: lease.target_ref,
      attach_grant_ref: lease.attach_grant_ref,
      operation_policy_ref: lease.operation_policy_ref,
      installation_revision_ref: lease.installation_revision_ref,
      policy_revision_ref: lease.policy_revision_ref,
      target_grant_revision: lease.target_grant_revision,
      rotation_epoch: lease.rotation_epoch,
      fence_token: lease.fence_token,
      persistence_posture:
        lease.persistence_posture || PersistencePosture.memory(:credential_lease_fence)
    }
  end

  @spec newer_than?(t(), t()) :: boolean()
  def newer_than?(%__MODULE__{epoch: left}, %__MODULE__{epoch: right}) do
    left > right
  end

  @spec authorize_restart_reuse(Lease.t(), t(), DateTime.t()) ::
          {:ok, map()} | {:error, {atom(), map()}}
  def authorize_restart_reuse(%Lease{} = lease, %__MODULE__{} = fence, %DateTime{} = now) do
    details = restart_details(lease, fence, now)

    cond do
      lease.resource != fence.resource ->
        {:error, {:lease_resource_mismatch_after_restart, details}}

      lease.holder != fence.holder ->
        {:error, {:lease_holder_mismatch_after_restart, details}}

      lease.lease_id != fence.lease_id ->
        {:error, {:lease_id_mismatch_after_restart, details}}

      Lease.revoked?(lease) ->
        {:error, {:lease_revoked_after_restart, details}}

      Lease.expired?(lease, now) ->
        {:error, {:lease_expired_after_restart, details}}

      fence.epoch > lease.epoch ->
        {:error, {:stale_lease_epoch_after_restart, details}}

      lease.epoch > fence.epoch ->
        {:error, {:stale_fence_epoch_after_restart, details}}

      true ->
        {:ok, details}
    end
  end

  @spec authorize_credential_materialization(Lease.t(), t(), map(), DateTime.t()) ::
          {:ok, map()} | {:error, {atom(), map()}}
  def authorize_credential_materialization(
        %Lease{} = lease,
        %__MODULE__{} = fence,
        context,
        %DateTime{} = now
      )
      when is_map(context) do
    with {:ok, _restart_details} <- authorize_restart_reuse(lease, fence, now),
         :ok <- ensure_scope_matches_fence(lease, fence, now),
         :ok <- ensure_scope_matches_context(lease, context, fence, now) do
      {:ok, credential_details(lease, fence, now)}
    end
  end

  @spec authorize_retry_dispatch(Lease.t(), t(), map(), DateTime.t()) ::
          {:ok, map()} | {:error, {atom(), map()}}
  def authorize_retry_dispatch(
        %Lease{} = lease,
        %__MODULE__{} = fence,
        context,
        %DateTime{} = now
      )
      when is_map(context) do
    with {:ok, materialization} <-
           authorize_credential_materialization(lease, fence, context, now),
         :ok <- ensure_retry_context(lease, fence, context, now),
         :ok <- ensure_single_active_execution(lease, fence, context, now),
         :ok <- ensure_retry_materialization_epoch(lease, fence, context, now),
         :ok <- ensure_no_old_lease_materialization(lease, fence, context, now),
         :ok <- ensure_restart_event_revalidated(lease, fence, context, now) do
      {:ok,
       materialization
       |> Map.merge(%{
         idempotency_key: context_value(context, :idempotency_key),
         dispatch_ref: context_value(context, :dispatch_ref),
         active_execution_ref: context_value(context, :active_execution_ref),
         retry_authority_ref: context_value(context, :retry_authority_ref),
         restart_event: context_value(context, :restart_event),
         retry_dispatch_status: :authorized_revalidated
       })
       |> Enum.reject(fn {_key, value} -> is_nil(value) end)
       |> Map.new()}
    end
  end

  defp restart_details(%Lease{} = lease, %__MODULE__{} = fence, %DateTime{} = now) do
    %{
      resource: lease.resource,
      holder: lease.holder,
      lease_id: lease.lease_id,
      lease_epoch: lease.epoch,
      fence_epoch: fence.epoch,
      checked_at: now,
      revoked_at: lease.revoked_at,
      revocation_ref: lease.revocation_ref
    }
    |> Map.put(:persistence_posture, lease.persistence_posture || fence.persistence_posture)
  end

  defp add_persistence_posture(details, %Lease{} = lease, %__MODULE__{} = fence) do
    Map.put(details, :persistence_posture, lease.persistence_posture || fence.persistence_posture)
  end

  defp credential_details(%Lease{} = lease, %__MODULE__{} = fence, now, mismatch_field \\ nil) do
    lease
    |> Lease.credential_scope()
    |> Map.merge(%{
      resource: lease.resource,
      holder: lease.holder,
      lease_id: lease.lease_id,
      lease_epoch: lease.epoch,
      fence_epoch: fence.epoch,
      checked_at: now,
      mismatch_field: mismatch_field,
      redacted: true
    })
    |> add_persistence_posture(lease, fence)
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp ensure_scope_matches_fence(%Lease{} = lease, %__MODULE__{} = fence, now) do
    case first_scope_mismatch(lease, Map.from_struct(fence)) do
      nil -> :ok
      {field, reason} -> {:error, {reason, credential_details(lease, fence, now, field)}}
    end
  end

  defp ensure_scope_matches_context(%Lease{} = lease, context, %__MODULE__{} = fence, now) do
    case first_scope_mismatch(lease, context) do
      nil -> :ok
      {field, reason} -> {:error, {reason, credential_details(lease, fence, now, field)}}
    end
  end

  defp first_scope_mismatch(%Lease{} = lease, values) do
    Enum.find(@credential_scope_checks, fn {field, _reason} ->
      expected = Map.fetch!(Map.from_struct(lease), field)
      actual = Map.get(values, field, Map.get(values, Atom.to_string(field)))

      not is_nil(expected) and not is_nil(actual) and expected != actual
    end)
  end

  defp ensure_retry_context(%Lease{} = lease, %__MODULE__{} = fence, context, now) do
    missing =
      Enum.reject(@retry_required_context, fn field ->
        present?(context_value(context, field))
      end)

    case missing do
      [] ->
        :ok

      _ ->
        {:error, {:missing_retry_dispatch_refs, credential_details(lease, fence, now, missing)}}
    end
  end

  defp ensure_single_active_execution(%Lease{} = lease, %__MODULE__{} = fence, context, now) do
    active = context_value(context, :active_execution_ref)
    current = context_value(context, :current_execution_ref)

    if active == current do
      :ok
    else
      {:error, {:duplicate_active_execution_after_restart, credential_details(lease, fence, now)}}
    end
  end

  defp ensure_retry_materialization_epoch(%Lease{} = lease, %__MODULE__{} = fence, context, now) do
    expected = lease.rotation_epoch || lease.epoch

    if context_value(context, :materialization_epoch) == expected do
      :ok
    else
      {:error,
       {:stale_materialization_epoch_after_restart,
        credential_details(lease, fence, now, :materialization_epoch)}}
    end
  end

  defp ensure_no_old_lease_materialization(%Lease{} = lease, %__MODULE__{} = fence, context, now) do
    old_ref = context_value(context, :materialized_credential_lease_ref)

    cond do
      is_nil(old_ref) ->
        :ok

      old_ref == lease.credential_lease_ref ->
        :ok

      true ->
        {:error,
         {:duplicate_dispatch_old_lease_reuse,
          credential_details(lease, fence, now, :materialized_credential_lease_ref)}}
    end
  end

  defp ensure_restart_event_revalidated(%Lease{} = lease, %__MODULE__{} = fence, context, now) do
    case context_value(context, :restart_event) do
      nil ->
        :ok

      event when event in @restart_revalidation_events ->
        :ok

      event ->
        details =
          lease
          |> credential_details(fence, now, :restart_event)
          |> Map.put(:restart_event, event)

        {:error, {:unsupported_restart_revalidation_event, details}}
    end
  end

  defp context_value(context, field) do
    Map.get(context, field, Map.get(context, Atom.to_string(field)))
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_value), do: true
end
