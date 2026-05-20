defmodule GroundPlane.Contracts.Fence.Epoch do
  @moduledoc "Epoch facts for a fenced lease and materialization."

  defstruct [:epoch, :rotation_epoch]

  @type t :: %__MODULE__{
          epoch: non_neg_integer(),
          rotation_epoch: non_neg_integer() | nil
        }

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_list(attrs), do: attrs |> Map.new() |> new()

  def new(attrs) when is_map(attrs) do
    with {:ok, epoch} <- fetch_non_negative_integer(attrs, :epoch),
         {:ok, rotation_epoch} <- fetch_optional_non_negative_integer(attrs, :rotation_epoch) do
      {:ok, %__MODULE__{epoch: epoch, rotation_epoch: rotation_epoch}}
    end
  end

  @spec scope_checks() :: keyword(atom())
  def scope_checks, do: [rotation_epoch: :rotation_epoch_mismatch]

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = epoch) do
    epoch
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp fetch_non_negative_integer(attrs, field) do
    case value(attrs, field) do
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _ -> {:error, {:invalid_epoch_field, field}}
    end
  end

  defp fetch_optional_non_negative_integer(attrs, field) do
    case value(attrs, field) do
      nil -> {:ok, nil}
      value when is_integer(value) and value >= 0 -> {:ok, value}
      _ -> {:error, {:invalid_epoch_field, field}}
    end
  end

  defp value(attrs, field), do: Map.get(attrs, field, Map.get(attrs, Atom.to_string(field)))
end
