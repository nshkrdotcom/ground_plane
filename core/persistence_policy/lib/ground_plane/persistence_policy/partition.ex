defmodule GroundPlane.PersistencePolicy.Partition do
  @moduledoc "Store-set partition dimensions."

  @fields [
    :tenant_ref,
    :installation_ref,
    :resource_family,
    :resource_ref,
    :resource_account_ref,
    :resource_instance_ref,
    :target_ref,
    :environment_ref,
    :region_ref,
    :data_class,
    :capture_level,
    :retention_class
  ]

  @field_lookup Map.new(@fields, fn field -> {Atom.to_string(field), field} end)

  @enforce_keys []
  defstruct @fields

  @type t :: %__MODULE__{}

  @spec fields() :: [atom()]
  def fields, do: @fields

  @spec new(t() | map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(%__MODULE__{} = partition), do: {:ok, partition}

  def new(attrs) when is_map(attrs) do
    attrs
    |> Enum.reduce_while({:ok, %{}}, &normalize_field/2)
    |> case do
      {:ok, normalized_attrs} -> {:ok, struct(__MODULE__, normalized_attrs)}
      {:error, _reason} = error -> error
    end
  end

  def new(attrs) when is_list(attrs) do
    if Keyword.keyword?(attrs) do
      attrs |> Map.new() |> new()
    else
      {:error, {:invalid_partition, attrs}}
    end
  end

  def new(partition), do: {:error, {:invalid_partition, partition}}

  defp normalize_field({field, value}, {:ok, normalized_attrs}) do
    case field_ref(field) do
      {:ok, field} -> {:cont, {:ok, Map.put(normalized_attrs, field, value)}}
      :error -> {:halt, {:error, {:invalid_partition_field, field}}}
    end
  end

  defp field_ref(field) when field in @fields, do: {:ok, field}
  defp field_ref(field) when is_binary(field), do: Map.fetch(@field_lookup, field)
  defp field_ref(_field), do: :error
end
