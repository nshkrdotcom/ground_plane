defmodule GroundPlane.Contracts.ArtifactDescriptor do
  @moduledoc """
  Immutable, secret-free metadata for an artifact shared across owner boundaries.

  Object-store locations remain opaque owner-authorized references. This
  contract never carries credentials, presigned URLs, or mutable object bodies.
  """

  alias GroundPlane.Boundary.Codec

  @classifications ~w(public internal confidential restricted)
  @deletion_states ~w(active tombstoned deleted)
  @required_string_fields ~w(
    artifact_ref tenant_ref owner_ref content_digest media_type schema_ref
    classification producing_operation_ref
  )a
  @fields @required_string_fields ++
            [
              :size_bytes,
              :schema_version,
              :provenance,
              :retention,
              :deletion_state,
              :location_ref,
              :causal_parent_refs
            ]
  @enforce_keys @required_string_fields ++
                  [:size_bytes, :schema_version, :provenance, :retention, :deletion_state]
  defstruct @required_string_fields ++
              [
                :size_bytes,
                :schema_version,
                :provenance,
                :retention,
                :deletion_state,
                :location_ref,
                causal_parent_refs: []
              ]

  @type t :: %__MODULE__{
          artifact_ref: String.t(),
          tenant_ref: String.t(),
          owner_ref: String.t(),
          content_digest: String.t(),
          size_bytes: non_neg_integer(),
          media_type: String.t(),
          schema_ref: String.t(),
          schema_version: pos_integer(),
          classification: String.t(),
          provenance: map(),
          causal_parent_refs: [String.t()],
          producing_operation_ref: String.t(),
          retention: map(),
          deletion_state: String.t(),
          location_ref: String.t() | nil
        }

  @spec new(map() | keyword() | t()) :: {:ok, t()} | {:error, term()}
  def new(%__MODULE__{} = descriptor), do: validate(descriptor)

  def new(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = Map.new(attrs)

    with {:ok, _normalized} <- Codec.normalize(attrs),
         true <- known_fields?(attrs) do
      descriptor = %__MODULE__{
        artifact_ref: value(attrs, :artifact_ref),
        tenant_ref: value(attrs, :tenant_ref),
        owner_ref: value(attrs, :owner_ref),
        content_digest: value(attrs, :content_digest),
        size_bytes: value(attrs, :size_bytes),
        media_type: value(attrs, :media_type),
        schema_ref: value(attrs, :schema_ref),
        schema_version: value(attrs, :schema_version),
        classification: normalize_string(value(attrs, :classification)),
        provenance: value(attrs, :provenance),
        causal_parent_refs: value(attrs, :causal_parent_refs, []),
        producing_operation_ref: value(attrs, :producing_operation_ref),
        retention: value(attrs, :retention),
        deletion_state: normalize_string(value(attrs, :deletion_state)),
        location_ref: value(attrs, :location_ref)
      }

      validate(descriptor)
    else
      {:error, _reason} = error -> error
      _other -> {:error, :invalid_artifact_descriptor}
    end
  end

  def new(_attrs), do: {:error, :invalid_artifact_descriptor}

  @spec new!(map() | keyword() | t()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, descriptor} -> descriptor
      {:error, reason} -> raise ArgumentError, "invalid artifact descriptor: #{inspect(reason)}"
    end
  end

  @spec dump(t()) :: map()
  def dump(%__MODULE__{} = descriptor) do
    descriptor
    |> Map.from_struct()
    |> Map.reject(fn {_key, nested} -> is_nil(nested) end)
  end

  @spec encode!(t()) :: String.t()
  def encode!(%__MODULE__{} = descriptor), do: descriptor |> dump() |> Codec.encode!()

  @spec digest(t()) :: String.t()
  def digest(%__MODULE__{} = descriptor), do: descriptor |> dump() |> Codec.digest()

  @spec tombstone(t(), String.t()) :: {:ok, t()} | {:error, term()}
  def tombstone(%__MODULE__{deletion_state: "active"} = descriptor, tombstone_ref)
      when is_binary(tombstone_ref) and tombstone_ref != "" do
    retention = Map.put(descriptor.retention, "tombstone_ref", tombstone_ref)
    new(%{descriptor | deletion_state: "tombstoned", retention: retention, location_ref: nil})
  end

  def tombstone(%__MODULE__{}, _tombstone_ref), do: {:error, :invalid_deletion_transition}

  @spec mark_deleted(t()) :: {:ok, t()} | {:error, term()}
  def mark_deleted(%__MODULE__{deletion_state: "tombstoned"} = descriptor) do
    new(%{descriptor | deletion_state: "deleted", location_ref: nil})
  end

  def mark_deleted(%__MODULE__{}), do: {:error, :invalid_deletion_transition}

  defp validate(%__MODULE__{} = descriptor) do
    with :ok <- validate_required_strings(descriptor),
         :ok <- validate_digest(descriptor.content_digest),
         :ok <- validate_non_negative_integer(:size_bytes, descriptor.size_bytes),
         :ok <- validate_positive_integer(:schema_version, descriptor.schema_version),
         :ok <- validate_member(:classification, descriptor.classification, @classifications),
         :ok <- validate_member(:deletion_state, descriptor.deletion_state, @deletion_states),
         :ok <- validate_string_list(:causal_parent_refs, descriptor.causal_parent_refs),
         :ok <- validate_optional_string(:location_ref, descriptor.location_ref),
         {:ok, _provenance} <- Codec.normalize(descriptor.provenance),
         {:ok, _retention} <- Codec.normalize(descriptor.retention),
         :ok <- validate_deleted_location(descriptor) do
      {:ok, descriptor}
    else
      {:error, _reason} = error -> error
      _other -> {:error, :invalid_artifact_descriptor}
    end
  end

  defp validate_required_strings(descriptor) do
    case Enum.find(@required_string_fields, fn field ->
           not present_string?(Map.fetch!(descriptor, field))
         end) do
      nil -> :ok
      field -> {:error, {:invalid_field, field}}
    end
  end

  defp validate_digest("sha256:" <> hex) when byte_size(hex) == 64 do
    if String.match?(hex, ~r/\A[0-9a-f]{64}\z/),
      do: :ok,
      else: {:error, {:invalid_field, :content_digest}}
  end

  defp validate_digest(_digest), do: {:error, {:invalid_field, :content_digest}}

  defp validate_non_negative_integer(_field, value) when is_integer(value) and value >= 0,
    do: :ok

  defp validate_non_negative_integer(field, _value), do: {:error, {:invalid_field, field}}

  defp validate_positive_integer(_field, value) when is_integer(value) and value > 0, do: :ok
  defp validate_positive_integer(field, _value), do: {:error, {:invalid_field, field}}

  defp validate_member(field, value, allowed) do
    if value in allowed, do: :ok, else: {:error, {:invalid_field, field}}
  end

  defp validate_string_list(_field, values) when is_list(values) do
    if Enum.all?(values, &present_string?/1),
      do: :ok,
      else: {:error, {:invalid_field, :causal_parent_refs}}
  end

  defp validate_string_list(field, _values), do: {:error, {:invalid_field, field}}

  defp validate_optional_string(_field, nil), do: :ok
  defp validate_optional_string(_field, value) when is_binary(value) and value != "", do: :ok
  defp validate_optional_string(field, _value), do: {:error, {:invalid_field, field}}

  defp validate_deleted_location(%__MODULE__{deletion_state: state, location_ref: nil})
       when state in ~w(tombstoned deleted),
       do: :ok

  defp validate_deleted_location(%__MODULE__{deletion_state: state})
       when state in ~w(tombstoned deleted),
       do: {:error, :deleted_artifact_has_location}

  defp validate_deleted_location(_descriptor), do: :ok

  defp value(attrs, key, default \\ nil),
    do: Map.get(attrs, key, Map.get(attrs, Atom.to_string(key), default))

  defp known_fields?(attrs) do
    allowed = MapSet.new(Enum.flat_map(@fields, &[&1, Atom.to_string(&1)]))
    Enum.all?(Map.keys(attrs), &MapSet.member?(allowed, &1))
  end

  defp normalize_string(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_string(value), do: value
  defp present_string?(value), do: is_binary(value) and String.trim(value) != ""
end
