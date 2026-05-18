defmodule GroundPlane.Boundary.DispatchResult do
  @moduledoc """
  Serializable response from a boundary protocol handler.
  """

  alias GroundPlane.Boundary.Codec

  @statuses ["accepted", "completed", "failed", "rejected"]

  @enforce_keys [:status]
  defstruct [
    :status,
    :response,
    :response_ref,
    :error,
    receipt_refs: [],
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          status: String.t(),
          response: map() | nil,
          response_ref: String.t() | nil,
          error: map() | nil,
          receipt_refs: [String.t()],
          metadata: map()
        }

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) or is_list(attrs) do
    result = %__MODULE__{
      status: string_value(attrs, :status),
      response: value(attrs, :response),
      response_ref: string_value(attrs, :response_ref),
      error: map_or_nil(attrs, :error),
      receipt_refs: string_list(attrs, :receipt_refs),
      metadata: map_value(attrs, :metadata)
    }

    with :ok <- validate_status(result),
         :ok <- validate_response_location(result),
         {:ok, _encoded} <- Codec.encode(to_map(result)) do
      {:ok, result}
    end
  end

  def new(_other), do: {:error, :invalid_boundary_dispatch_result_attrs}

  @spec new!(map() | keyword()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, result} ->
        result

      {:error, reason} ->
        raise ArgumentError, "invalid boundary dispatch result: #{inspect(reason)}"
    end
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = result) do
    %{
      status: result.status,
      response: result.response,
      response_ref: result.response_ref,
      error: result.error,
      receipt_refs: result.receipt_refs,
      metadata: result.metadata
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp validate_status(%__MODULE__{status: status}) when status in @statuses, do: :ok

  defp validate_status(%__MODULE__{status: status}),
    do: {:error, {:invalid_boundary_status, status}}

  defp validate_response_location(%__MODULE__{response: response, response_ref: ref})
       when not is_nil(response) and not is_nil(ref),
       do: {:error, :ambiguous_boundary_response_location}

  defp validate_response_location(_result), do: :ok

  defp map_value(attrs, key) do
    case value(attrs, key) do
      value when is_map(value) -> value
      _missing -> %{}
    end
  end

  defp map_or_nil(attrs, key) do
    case value(attrs, key) do
      value when is_map(value) -> value
      _missing -> nil
    end
  end

  defp string_list(attrs, key) do
    case value(attrs, key) do
      values when is_list(values) -> Enum.filter(values, &is_binary/1)
      _missing -> []
    end
  end

  defp string_value(attrs, key) do
    case value(attrs, key) do
      nil -> nil
      value when is_atom(value) -> Atom.to_string(value)
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
