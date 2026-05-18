defmodule GroundPlane.Boundary.Envelope do
  @moduledoc """
  Serializable cross-plane request envelope.
  """

  alias GroundPlane.Boundary.Codec

  @enforce_keys [
    :id,
    :source,
    :target,
    :operation,
    :tenant_id,
    :schema_version
  ]
  defstruct [
    :id,
    :source,
    :target,
    :operation,
    :tenant_id,
    :schema_version,
    :payload,
    :payload_ref,
    :issued_at,
    trace: %{},
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          source: String.t(),
          target: String.t(),
          operation: String.t(),
          tenant_id: String.t(),
          schema_version: String.t(),
          payload: map() | nil,
          payload_ref: String.t() | nil,
          issued_at: String.t() | nil,
          trace: map(),
          metadata: map()
        }

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    envelope = %__MODULE__{
      id: string_value(attrs, :id),
      source: string_value(attrs, :source),
      target: string_value(attrs, :target),
      operation: string_value(attrs, :operation),
      tenant_id: string_value(attrs, :tenant_id),
      schema_version: string_value(attrs, :schema_version) || "ground-plane.boundary.v1",
      payload: value(attrs, :payload),
      payload_ref: string_value(attrs, :payload_ref),
      issued_at: string_value(attrs, :issued_at),
      trace: map_value(attrs, :trace),
      metadata: map_value(attrs, :metadata)
    }

    with :ok <- validate_required(envelope),
         :ok <- validate_payload_location(envelope),
         {:ok, _encoded} <- Codec.encode(to_map(envelope)) do
      {:ok, envelope}
    end
  end

  def new(_other), do: {:error, :invalid_boundary_envelope_attrs}

  @spec new!(map() | keyword()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, envelope} -> envelope
      {:error, reason} -> raise ArgumentError, "invalid boundary envelope: #{inspect(reason)}"
    end
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = envelope) do
    %{
      id: envelope.id,
      source: envelope.source,
      target: envelope.target,
      operation: envelope.operation,
      tenant_id: envelope.tenant_id,
      schema_version: envelope.schema_version,
      payload: envelope.payload,
      payload_ref: envelope.payload_ref,
      issued_at: envelope.issued_at,
      trace: envelope.trace,
      metadata: envelope.metadata
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  @spec encode!(t()) :: String.t()
  def encode!(%__MODULE__{} = envelope), do: envelope |> to_map() |> Codec.encode!()

  @spec digest(t()) :: String.t()
  def digest(%__MODULE__{} = envelope), do: envelope |> to_map() |> Codec.digest()

  defp validate_required(%__MODULE__{} = envelope) do
    missing =
      @enforce_keys
      |> Enum.reject(fn key ->
        value = Map.fetch!(envelope, key)
        is_binary(value) and value != ""
      end)

    case missing do
      [] -> :ok
      keys -> {:error, {:missing_boundary_envelope_fields, keys}}
    end
  end

  defp validate_payload_location(%__MODULE__{payload: nil, payload_ref: nil}),
    do: {:error, :missing_boundary_payload}

  defp validate_payload_location(%__MODULE__{payload: payload, payload_ref: ref})
       when not is_nil(payload) and not is_nil(ref),
       do: {:error, :ambiguous_boundary_payload_location}

  defp validate_payload_location(_envelope), do: :ok

  defp map_value(attrs, key) do
    case value(attrs, key) do
      value when is_map(value) -> value
      _missing -> %{}
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
