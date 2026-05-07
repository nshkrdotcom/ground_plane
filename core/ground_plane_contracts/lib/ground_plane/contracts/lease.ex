defmodule GroundPlane.Contracts.Lease do
  @moduledoc """
  Struct and validation helpers for lease records.
  """

  alias GroundPlane.Contracts.PersistencePosture

  defstruct [
    :resource,
    :holder,
    :lease_id,
    :epoch,
    :expires_at,
    :revoked_at,
    :revocation_ref,
    :tenant_id,
    :subject_ref,
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
          expires_at: DateTime.t(),
          revoked_at: DateTime.t() | nil,
          revocation_ref: String.t() | nil,
          tenant_id: String.t() | nil,
          subject_ref: String.t() | nil,
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

  @required_fields [:resource, :holder, :lease_id, :epoch, :expires_at]
  @scope_string_fields [
    :tenant_id,
    :subject_ref,
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
    :fence_token
  ]

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    with :ok <- ensure_required_fields(attrs),
         {:ok, epoch} <- fetch_non_negative_integer(attrs, :epoch),
         {:ok, expires_at} <- fetch_datetime(attrs, :expires_at),
         {:ok, revoked_at} <- fetch_optional_datetime(attrs, :revoked_at),
         {:ok, revocation_ref} <- fetch_optional_string(attrs, :revocation_ref),
         {:ok, rotation_epoch} <- fetch_optional_non_negative_integer(attrs, :rotation_epoch),
         :ok <- ensure_revocation_pair(revoked_at, revocation_ref) do
      {:ok,
       %__MODULE__{
         resource: Map.fetch!(attrs, :resource),
         holder: Map.fetch!(attrs, :holder),
         lease_id: Map.fetch!(attrs, :lease_id),
         epoch: epoch,
         expires_at: expires_at,
         revoked_at: revoked_at,
         revocation_ref: revocation_ref,
         tenant_id: optional_string(attrs, :tenant_id),
         subject_ref: optional_string(attrs, :subject_ref),
         provider_family: optional_string(attrs, :provider_family),
         provider_account_ref: optional_string(attrs, :provider_account_ref),
         connector_instance_ref: optional_string(attrs, :connector_instance_ref),
         credential_handle_ref: optional_string(attrs, :credential_handle_ref),
         credential_lease_ref: optional_string(attrs, :credential_lease_ref),
         operation_class: optional_string(attrs, :operation_class),
         target_ref: optional_string(attrs, :target_ref),
         attach_grant_ref: optional_string(attrs, :attach_grant_ref),
         operation_policy_ref: optional_string(attrs, :operation_policy_ref),
         installation_revision_ref: optional_string(attrs, :installation_revision_ref),
         policy_revision_ref: optional_string(attrs, :policy_revision_ref),
         target_grant_revision: optional_string(attrs, :target_grant_revision),
         rotation_epoch: rotation_epoch,
         fence_token: optional_string(attrs, :fence_token),
         persistence_posture: PersistencePosture.resolve(:credential_lease_fence, attrs)
       }}
    end
  end

  @spec expired?(t(), DateTime.t()) :: boolean()
  def expired?(%__MODULE__{expires_at: expires_at}, %DateTime{} = now) do
    DateTime.compare(expires_at, now) != :gt
  end

  @spec revoked?(t()) :: boolean()
  def revoked?(%__MODULE__{revoked_at: %DateTime{}}), do: true
  def revoked?(%__MODULE__{}), do: false

  @spec active?(t(), DateTime.t()) :: boolean()
  def active?(%__MODULE__{} = lease, %DateTime{} = now) do
    not expired?(lease, now) and not revoked?(lease)
  end

  @spec credential_scope(t()) :: map()
  def credential_scope(%__MODULE__{} = lease) do
    lease
    |> Map.from_struct()
    |> Map.take(@scope_string_fields ++ [:rotation_epoch])
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  @spec cleanup_event(t(), map()) :: {:ok, map()} | {:error, term()}
  def cleanup_event(%__MODULE__{} = lease, attrs) when is_map(attrs) do
    cleaned_at = Map.get(attrs, :cleaned_at)
    cleanup_ref = Map.get(attrs, :cleanup_ref)

    with %DateTime{} <- cleaned_at || {:error, :cleanup_time_required},
         value when is_binary(value) and value != "" <-
           cleanup_ref || {:error, :cleanup_ref_required},
         :ok <- ensure_cleanup_terminal(lease, cleaned_at) do
      {:ok,
       lease
       |> credential_scope()
       |> Map.merge(%{
         event: "ground_plane.credential_lease.cleaned",
         lease_id: lease.lease_id,
         credential_lease_ref: lease.credential_lease_ref || lease.lease_id,
         cleanup_ref: cleanup_ref,
         cleaned_at: cleaned_at,
         persistence_posture: lease.persistence_posture,
         status: :cleaned,
         redacted: true
       })}
    else
      {:error, reason} -> {:error, reason}
      _other -> {:error, :cleanup_time_required}
    end
  end

  defp ensure_required_fields(attrs) do
    missing =
      Enum.reject(@required_fields, fn field ->
        Map.has_key?(attrs, field)
      end)

    case missing do
      [] -> :ok
      _ -> {:error, {:missing_fields, missing}}
    end
  end

  defp fetch_non_negative_integer(attrs, field) do
    case Map.fetch!(attrs, field) do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _ -> {:error, {:invalid_non_negative_integer, field}}
    end
  end

  defp fetch_datetime(attrs, field) do
    case Map.fetch!(attrs, field) do
      %DateTime{} = value -> {:ok, value}
      _ -> {:error, {:invalid_datetime, field}}
    end
  end

  defp fetch_optional_datetime(attrs, field) do
    case Map.get(attrs, field) do
      nil -> {:ok, nil}
      %DateTime{} = value -> {:ok, value}
      _ -> {:error, {:invalid_datetime, field}}
    end
  end

  defp fetch_optional_string(attrs, field) do
    case Map.get(attrs, field) do
      nil -> {:ok, nil}
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, {:invalid_string, field}}
    end
  end

  defp fetch_optional_non_negative_integer(attrs, field) do
    case Map.get(attrs, field) do
      nil -> {:ok, nil}
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _ -> {:error, {:invalid_non_negative_integer, field}}
    end
  end

  defp ensure_revocation_pair(nil, nil), do: :ok
  defp ensure_revocation_pair(%DateTime{}, ref) when is_binary(ref), do: :ok
  defp ensure_revocation_pair(nil, _ref), do: {:error, :revoked_lease_missing_revoked_at}
  defp ensure_revocation_pair(%DateTime{}, nil), do: {:error, :revoked_lease_missing_ref}

  defp optional_string(attrs, field) do
    case Map.get(attrs, field) do
      value when is_binary(value) and value != "" -> value
      _other -> nil
    end
  end

  defp ensure_cleanup_terminal(%__MODULE__{} = lease, %DateTime{} = cleaned_at) do
    if active?(lease, cleaned_at),
      do: {:error, :active_lease_cleanup_rejected},
      else: :ok
  end
end
