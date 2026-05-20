defmodule GroundPlane.Contracts.Fence.CredentialScope do
  @moduledoc "Credential materialization scope facts for a fenced lease."

  @fields [
    :tenant_id,
    :resource_family,
    :resource_account_ref,
    :resource_instance_ref,
    :credential_handle_ref,
    :credential_lease_ref,
    :operation_class,
    :target_ref,
    :attach_grant_ref,
    :operation_policy_ref,
    :fence_token
  ]

  @required_when_scoped [
    :tenant_id,
    :resource_family,
    :resource_account_ref,
    :resource_instance_ref,
    :credential_handle_ref,
    :credential_lease_ref,
    :operation_class
  ]

  defstruct @fields

  @type t :: %__MODULE__{}

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_list(attrs), do: attrs |> Map.new() |> new()

  def new(attrs) when is_map(attrs) do
    values = Map.new(@fields, fn field -> {field, optional_string(attrs, field)} end)

    with :ok <- validate_required_scope(values) do
      {:ok, struct(__MODULE__, values)}
    end
  end

  @spec checks() :: keyword(atom())
  def checks do
    [
      tenant_id: :tenant_mismatch,
      resource_family: :resource_family_mismatch,
      resource_account_ref: :resource_account_mismatch,
      resource_instance_ref: :resource_instance_mismatch,
      credential_handle_ref: :credential_handle_mismatch,
      credential_lease_ref: :credential_lease_mismatch,
      operation_class: :operation_class_mismatch,
      target_ref: :target_mismatch,
      attach_grant_ref: :attach_grant_mismatch,
      operation_policy_ref: :operation_policy_mismatch,
      fence_token: :fence_token_mismatch
    ]
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = scope) do
    scope
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp validate_required_scope(values) do
    if scoped?(values) do
      validate_required_fields(values)
    else
      :ok
    end
  end

  defp scoped?(values), do: Enum.any?(values, fn {_field, value} -> not is_nil(value) end)

  defp validate_required_fields(values) do
    missing = Enum.filter(@required_when_scoped, &is_nil(Map.fetch!(values, &1)))

    case missing do
      [] -> :ok
      _ -> {:error, {:missing_credential_scope_fields, missing}}
    end
  end

  defp optional_string(attrs, field) do
    case value(attrs, field) do
      nil -> nil
      value when is_binary(value) and value != "" -> value
      _ -> :invalid
    end
    |> case do
      :invalid -> nil
      value -> value
    end
  end

  defp value(attrs, field), do: Map.get(attrs, field, Map.get(attrs, Atom.to_string(field)))
end
