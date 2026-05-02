defmodule GroundPlane.Contracts.Lease do
  @moduledoc """
  Struct and validation helpers for lease records.
  """

  defstruct [:resource, :holder, :lease_id, :epoch, :expires_at, :revoked_at, :revocation_ref]

  @type t :: %__MODULE__{
          resource: String.t(),
          holder: String.t(),
          lease_id: String.t(),
          epoch: non_neg_integer(),
          expires_at: DateTime.t(),
          revoked_at: DateTime.t() | nil,
          revocation_ref: String.t() | nil
        }

  @required_fields [:resource, :holder, :lease_id, :epoch, :expires_at]

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    with :ok <- ensure_required_fields(attrs),
         {:ok, epoch} <- fetch_non_negative_integer(attrs, :epoch),
         {:ok, expires_at} <- fetch_datetime(attrs, :expires_at),
         {:ok, revoked_at} <- fetch_optional_datetime(attrs, :revoked_at),
         {:ok, revocation_ref} <- fetch_optional_string(attrs, :revocation_ref),
         :ok <- ensure_revocation_pair(revoked_at, revocation_ref) do
      {:ok,
       %__MODULE__{
         resource: Map.fetch!(attrs, :resource),
         holder: Map.fetch!(attrs, :holder),
         lease_id: Map.fetch!(attrs, :lease_id),
         epoch: epoch,
         expires_at: expires_at,
         revoked_at: revoked_at,
         revocation_ref: revocation_ref
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

  defp ensure_revocation_pair(nil, nil), do: :ok
  defp ensure_revocation_pair(%DateTime{}, ref) when is_binary(ref), do: :ok
  defp ensure_revocation_pair(nil, _ref), do: {:error, :revoked_lease_missing_revoked_at}
  defp ensure_revocation_pair(%DateTime{}, nil), do: {:error, :revoked_lease_missing_ref}
end
