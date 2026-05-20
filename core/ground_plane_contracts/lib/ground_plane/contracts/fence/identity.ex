defmodule GroundPlane.Contracts.Fence.Identity do
  @moduledoc "Stable identity facts for a fenced lease."

  @fields [:resource, :holder, :lease_id]

  @enforce_keys @fields
  defstruct @fields

  @type t :: %__MODULE__{
          resource: String.t(),
          holder: String.t(),
          lease_id: String.t()
        }

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_list(attrs), do: attrs |> Map.new() |> new()

  def new(attrs) when is_map(attrs) do
    with {:ok, resource} <- fetch_non_empty_string(attrs, :resource),
         {:ok, holder} <- fetch_non_empty_string(attrs, :holder),
         {:ok, lease_id} <- fetch_non_empty_string(attrs, :lease_id) do
      {:ok, %__MODULE__{resource: resource, holder: holder, lease_id: lease_id}}
    end
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = identity), do: Map.from_struct(identity)

  defp fetch_non_empty_string(attrs, field) do
    case value(attrs, field) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, {:invalid_identity_field, field}}
    end
  end

  defp value(attrs, field), do: Map.get(attrs, field, Map.get(attrs, Atom.to_string(field)))
end
