defmodule GroundPlane.Contracts.EnterprisePrecutSupport do
  @moduledoc false

  @spec build(module(), [atom()], [atom()], map()) :: {:ok, struct()} | {:error, term()}
  def build(module, fields, required_fields, attrs) when is_map(attrs) do
    case missing_required_fields(attrs, required_fields) do
      [] -> {:ok, struct(module, Map.take(attrs, fields))}
      missing -> {:error, {:missing_required_fields, missing}}
    end
  end

  def build(_module, _fields, _required_fields, _attrs), do: {:error, :invalid_attrs}

  defp missing_required_fields(attrs, required_fields) do
    Enum.reject(required_fields, &present?(Map.get(attrs, &1)))
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value) when is_list(value), do: value != []
  defp present?(value), do: not is_nil(value)
end

defmodule GroundPlane.Contracts.ResourcePath do
  @moduledoc """
  Tenant-scoped hierarchical resource path used by policy and incident joins.
  """

  alias GroundPlane.Contracts.EnterprisePrecutSupport

  @fields [:tenant_id, :segments, :resource_kind_path, :terminal_resource_id]
  defstruct @fields

  @type t :: %__MODULE__{}

  def new(attrs),
    do:
      EnterprisePrecutSupport.build(
        __MODULE__,
        @fields,
        [:tenant_id, :segments, :resource_kind_path, :terminal_resource_id],
        attrs
      )
end

defmodule GroundPlane.Contracts.EpochRef do
  @moduledoc """
  Revision/lease epoch reference used by stale-write and revocation gates.
  """

  alias GroundPlane.Contracts.EnterprisePrecutSupport

  @fields [:epoch_ref, :tenant_id, :resource_id, :epoch, :trace_id]
  defstruct @fields

  @type t :: %__MODULE__{}

  def new(attrs) do
    with {:ok, epoch_ref} <-
           EnterprisePrecutSupport.build(
             __MODULE__,
             @fields,
             [:epoch_ref, :tenant_id, :resource_id, :epoch, :trace_id],
             attrs
           ),
         true <- is_integer(epoch_ref.epoch) and epoch_ref.epoch >= 0 do
      {:ok, epoch_ref}
    else
      false -> {:error, :invalid_epoch}
      error -> error
    end
  end
end

defmodule GroundPlane.Contracts.GraphNodeRef do
  @moduledoc "Typed projection/trace graph node reference."

  alias GroundPlane.Contracts.EnterprisePrecutSupport

  @fields [:node_ref, :tenant_id, :node_kind, :trace_id]
  defstruct @fields

  @type t :: %__MODULE__{}

  def new(attrs),
    do:
      EnterprisePrecutSupport.build(
        __MODULE__,
        @fields,
        [:node_ref, :tenant_id, :node_kind, :trace_id],
        attrs
      )
end

defmodule GroundPlane.Contracts.GraphEdgeRef do
  @moduledoc "Typed projection/trace graph edge reference."

  alias GroundPlane.Contracts.EnterprisePrecutSupport

  @fields [:edge_ref, :tenant_id, :source_ref, :target_ref, :edge_kind, :trace_id]
  defstruct @fields

  @type t :: %__MODULE__{}

  def new(attrs),
    do:
      EnterprisePrecutSupport.build(
        __MODULE__,
        @fields,
        [:edge_ref, :tenant_id, :source_ref, :target_ref, :edge_kind, :trace_id],
        attrs
      )
end
