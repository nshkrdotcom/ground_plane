defmodule GroundPlane.Contracts.Fence.PersistenceScope do
  @moduledoc "Persistence posture facts attached to a fenced lease."

  defstruct [:persistence_posture]

  @type t :: %__MODULE__{persistence_posture: map() | nil}

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_list(attrs), do: attrs |> Map.new() |> new()

  def new(attrs) when is_map(attrs) do
    case value(attrs, :persistence_posture) do
      nil -> {:ok, %__MODULE__{}}
      value when is_map(value) -> {:ok, %__MODULE__{persistence_posture: value}}
      value -> {:error, {:invalid_persistence_posture, value}}
    end
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{persistence_posture: nil}), do: %{}
  def to_map(%__MODULE__{persistence_posture: posture}), do: %{persistence_posture: posture}

  defp value(attrs, field), do: Map.get(attrs, field, Map.get(attrs, Atom.to_string(field)))
end
