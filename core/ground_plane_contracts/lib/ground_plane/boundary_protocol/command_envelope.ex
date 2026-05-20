defmodule GroundPlane.BoundaryProtocol.CommandEnvelope do
  @moduledoc """
  Canonical governed-operation command envelope for cross-plane dispatch.

  The internal field names intentionally use the stack's `_ref` vocabulary.
  `to_gaop_map/1` exposes the GAOP RFC-0002 boundary names at external
  protocol edges.
  """

  alias GroundPlane.Boundary.Codec

  @protocol_version "gaop.v1"
  @effect_class "observe"

  @required_string_fields [
    :command_ref,
    :actor_ref,
    :idempotency_key,
    :trace_ref,
    :operation_type,
    :created_at
  ]

  @error_taxonomy %{
    duplicate_idempotency: "idempotency_key was already accepted for this tenant boundary",
    invalid_schema: "schema_ref or schema-governed payload is invalid",
    missing_tenant: "tenant_ref is required before dispatch",
    non_serializable: "envelope contains a value the boundary codec cannot encode",
    version_conflict: "expected_version is not a positive optimistic concurrency value"
  }

  @enforce_keys [
    :command_ref,
    :tenant_ref,
    :actor_ref,
    :schema_ref,
    :idempotency_key,
    :trace_ref,
    :operation_type,
    :payload,
    :resource_scopes,
    :intent,
    :created_at
  ]
  defstruct [
    :command_ref,
    :tenant_ref,
    :actor_ref,
    :installation_ref,
    :schema_ref,
    :idempotency_key,
    :trace_ref,
    :operation_type,
    :payload,
    :authority_ref,
    :expected_version,
    :resource_scopes,
    :intent,
    :created_at,
    protocol_version: @protocol_version,
    effect_class: @effect_class
  ]

  @type t :: %__MODULE__{
          protocol_version: String.t(),
          command_ref: String.t(),
          tenant_ref: String.t(),
          actor_ref: String.t(),
          installation_ref: String.t() | nil,
          schema_ref: String.t(),
          idempotency_key: String.t(),
          trace_ref: String.t(),
          operation_type: String.t(),
          payload: Codec.canonical_value(),
          authority_ref: String.t() | nil,
          expected_version: pos_integer() | nil,
          resource_scopes: [map()],
          intent: map(),
          created_at: String.t(),
          effect_class: String.t()
        }

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    envelope = %__MODULE__{
      protocol_version: string_value(attrs, :protocol_version) || @protocol_version,
      command_ref: string_value(attrs, :command_ref),
      tenant_ref: string_value(attrs, :tenant_ref),
      actor_ref: string_value(attrs, :actor_ref),
      installation_ref: string_value(attrs, :installation_ref),
      schema_ref: string_value(attrs, :schema_ref),
      idempotency_key: string_value(attrs, :idempotency_key),
      trace_ref: string_value(attrs, :trace_ref),
      operation_type: string_value(attrs, :operation_type),
      payload: value(attrs, :payload),
      authority_ref: string_value(attrs, :authority_ref),
      expected_version: value(attrs, :expected_version),
      resource_scopes: list_value(attrs, :resource_scopes),
      intent: map_value(attrs, :intent),
      created_at: string_value(attrs, :created_at),
      effect_class: string_value(attrs, :effect_class) || @effect_class
    }

    with :ok <- validate_required(envelope),
         :ok <- validate_schema(envelope),
         :ok <- validate_expected_version(envelope),
         :ok <- validate_resource_scopes(envelope),
         :ok <- validate_intent(envelope),
         {:ok, _encoded} <- encode_boundary(envelope) do
      {:ok, envelope}
    end
  end

  def new(_other), do: {:error, :invalid_command_envelope_attrs}

  @spec new!(map() | keyword()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, envelope} -> envelope
      {:error, reason} -> raise ArgumentError, "invalid command envelope: #{inspect(reason)}"
    end
  end

  @spec error_taxonomy() :: map()
  def error_taxonomy, do: @error_taxonomy

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = envelope) do
    %{
      protocol_version: envelope.protocol_version,
      command_ref: envelope.command_ref,
      tenant_ref: envelope.tenant_ref,
      actor_ref: envelope.actor_ref,
      installation_ref: envelope.installation_ref,
      schema_ref: envelope.schema_ref,
      idempotency_key: envelope.idempotency_key,
      trace_ref: envelope.trace_ref,
      operation_type: envelope.operation_type,
      payload: envelope.payload,
      authority_ref: envelope.authority_ref,
      expected_version: envelope.expected_version,
      resource_scopes: envelope.resource_scopes,
      intent: envelope.intent,
      created_at: envelope.created_at,
      effect_class: envelope.effect_class
    }
    |> reject_nil_values()
  end

  @spec to_gaop_map(t()) :: map()
  def to_gaop_map(%__MODULE__{} = envelope) do
    %{
      "protocol_version" => envelope.protocol_version,
      "command_id" => envelope.command_ref,
      "tenant_id" => envelope.tenant_ref,
      "actor_ref" => envelope.actor_ref,
      "idempotency_key" => envelope.idempotency_key,
      "trace_id" => envelope.trace_ref,
      "requested_capability" => %{
        "capability_id" => envelope.operation_type,
        "operation" => envelope.operation_type,
        "effect_class" => envelope.effect_class
      },
      "intent" => envelope.intent,
      "resource_scopes" => envelope.resource_scopes,
      "created_at" => envelope.created_at,
      "metadata" =>
        %{
          "authority_ref" => envelope.authority_ref,
          "expected_version" => envelope.expected_version,
          "installation_ref" => envelope.installation_ref,
          "schema_ref" => envelope.schema_ref
        }
        |> reject_nil_values()
    }
  end

  @spec encode!(t()) :: String.t()
  def encode!(%__MODULE__{} = envelope), do: envelope |> to_map() |> Codec.encode!()

  @spec digest(t()) :: String.t()
  def digest(%__MODULE__{} = envelope), do: envelope |> to_map() |> Codec.digest()

  defp validate_required(%__MODULE__{tenant_ref: tenant_ref})
       when not is_binary(tenant_ref) or tenant_ref == "",
       do: {:error, :missing_tenant}

  defp validate_required(%__MODULE__{} = envelope) do
    Enum.reduce_while(@required_string_fields, :ok, fn field, :ok ->
      case Map.fetch!(envelope, field) do
        value when is_binary(value) and value != "" -> {:cont, :ok}
        _missing -> {:halt, {:error, {:missing_field, field}}}
      end
    end)
  end

  defp validate_schema(%__MODULE__{schema_ref: schema_ref})
       when is_binary(schema_ref) and schema_ref != "",
       do: :ok

  defp validate_schema(_envelope), do: {:error, :invalid_schema}

  defp validate_expected_version(%__MODULE__{expected_version: nil}), do: :ok

  defp validate_expected_version(%__MODULE__{expected_version: version})
       when is_integer(version) and version > 0,
       do: :ok

  defp validate_expected_version(_envelope), do: {:error, :version_conflict}

  defp validate_resource_scopes(%__MODULE__{resource_scopes: scopes})
       when is_list(scopes) and scopes != [],
       do: :ok

  defp validate_resource_scopes(_envelope), do: {:error, {:missing_field, :resource_scopes}}

  defp validate_intent(%__MODULE__{intent: intent}) when is_map(intent), do: :ok
  defp validate_intent(_envelope), do: {:error, {:missing_field, :intent}}

  defp encode_boundary(%__MODULE__{} = envelope) do
    case envelope |> to_map() |> Codec.encode() do
      {:ok, encoded} -> {:ok, encoded}
      {:error, reason} -> {:error, {:non_serializable, reason}}
    end
  end

  defp reject_nil_values(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp list_value(attrs, key) do
    case value(attrs, key) do
      values when is_list(values) -> values
      _missing -> []
    end
  end

  defp map_value(attrs, key) do
    case value(attrs, key) do
      value when is_map(value) -> value
      _missing -> nil
    end
  end

  defp string_value(attrs, key) do
    case value(attrs, key) do
      value when is_binary(value) and value != "" -> value
      _missing -> nil
    end
  end

  defp value(attrs, key) when is_map(attrs) do
    case Map.fetch(attrs, key) do
      {:ok, value} -> value
      :error -> Map.get(attrs, Atom.to_string(key))
    end
  end

  defp value(attrs, key) when is_list(attrs), do: Keyword.get(attrs, key)
end
