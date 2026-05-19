defmodule GroundPlane.PersistencePolicy.StoreCapability do
  @moduledoc "Descriptor for an available persistence adapter capability."

  alias GroundPlane.PersistencePolicy.Partition
  alias GroundPlane.PersistencePolicy.Tier

  @enforce_keys [:store_ref, :tier, :data_classes, :adapter]
  defstruct [
    :store_ref,
    :tier,
    :data_classes,
    :adapter,
    restart_safe?: false,
    durable?: false,
    partitions: []
  ]

  @type t :: %__MODULE__{
          store_ref: String.t() | atom(),
          tier: atom(),
          data_classes: [atom()],
          adapter: atom(),
          restart_safe?: boolean(),
          durable?: boolean(),
          partitions: [Partition.t()]
        }

  @spec new(map() | keyword()) :: {:ok, t()} | {:error, term()}
  def new(attrs) do
    attrs = Map.new(attrs)

    with {:ok, store_ref} <- validate_store_ref(value(attrs, :store_ref)),
         {:ok, tier} <- Tier.validate(value(attrs, :tier)),
         {:ok, data_classes} <- validate_data_classes(value(attrs, :data_classes)),
         {:ok, adapter} <- validate_adapter(value(attrs, :adapter)),
         {:ok, partitions} <- validate_partitions(value(attrs, :partitions)) do
      {:ok,
       %__MODULE__{
         store_ref: store_ref,
         tier: tier,
         data_classes: data_classes,
         adapter: adapter,
         restart_safe?: value(attrs, :restart_safe?) || false,
         durable?: Tier.durable?(tier),
         partitions: partitions
       }}
    else
      error -> error
    end
  end

  defp validate_store_ref(store_ref) when is_binary(store_ref) do
    if String.trim(store_ref) == "" do
      {:error, {:invalid_store_ref, store_ref}}
    else
      {:ok, store_ref}
    end
  end

  defp validate_store_ref(store_ref) when is_atom(store_ref) do
    if valid_symbolic_atom?(store_ref) do
      {:ok, store_ref}
    else
      {:error, {:invalid_store_ref, store_ref}}
    end
  end

  defp validate_store_ref(store_ref), do: {:error, {:invalid_store_ref, store_ref}}

  defp validate_data_classes(data_classes) when is_list(data_classes), do: {:ok, data_classes}

  defp validate_data_classes(_data_classes),
    do: {:error, {:invalid_store_capability, :data_classes}}

  defp validate_adapter(adapter) when is_atom(adapter) do
    if valid_symbolic_atom?(adapter) do
      {:ok, adapter}
    else
      {:error, {:invalid_adapter, adapter}}
    end
  end

  defp validate_adapter(adapter), do: {:error, {:invalid_adapter, adapter}}

  defp validate_partitions(nil), do: {:ok, []}
  defp validate_partitions([]), do: {:ok, []}

  defp validate_partitions(%Partition{} = partition), do: {:ok, [partition]}

  defp validate_partitions(partitions) when is_list(partitions) do
    if Keyword.keyword?(partitions) do
      partitions |> Map.new() |> validate_partitions()
    else
      validate_partition_list(partitions)
    end
  end

  defp validate_partitions(partition) when is_map(partition) do
    case Partition.new(partition) do
      {:ok, partition} -> {:ok, [partition]}
      {:error, _reason} = error -> error
    end
  end

  defp validate_partitions(partition), do: {:error, {:invalid_partition, partition}}

  defp validate_partition_list(partitions) do
    partitions
    |> Enum.reduce_while({:ok, []}, &append_partition/2)
    |> reverse_partitions()
  end

  defp append_partition(partition, {:ok, partitions}) do
    case Partition.new(partition) do
      {:ok, partition} -> {:cont, {:ok, [partition | partitions]}}
      {:error, _reason} = error -> {:halt, error}
    end
  end

  defp reverse_partitions({:ok, partitions}), do: {:ok, Enum.reverse(partitions)}
  defp reverse_partitions({:error, _reason} = error), do: error

  defp valid_symbolic_atom?(atom),
    do: atom != nil and atom != true and atom != false and atom != :""

  defp value(attrs, field) do
    case Map.fetch(attrs, field) do
      {:ok, value} -> value
      :error -> Map.get(attrs, Atom.to_string(field))
    end
  end
end
