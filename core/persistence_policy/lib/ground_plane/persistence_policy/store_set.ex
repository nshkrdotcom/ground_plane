defmodule GroundPlane.PersistencePolicy.StoreSet do
  @moduledoc "Selected store set and partition posture."

  alias GroundPlane.PersistencePolicy.Partition
  alias GroundPlane.PersistencePolicy.StoreCapability

  @enforce_keys [:id, :default_tier, :capabilities]
  defstruct [
    :id,
    :default_tier,
    :capabilities,
    partitions: []
  ]

  @type t :: %__MODULE__{
          id: atom(),
          default_tier: atom(),
          capabilities: [StoreCapability.t()],
          partitions: [Partition.t()]
        }
end
