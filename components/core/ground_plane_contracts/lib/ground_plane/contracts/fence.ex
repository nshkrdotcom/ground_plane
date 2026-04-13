defmodule GroundPlane.Contracts.Fence do
  @moduledoc """
  Struct and comparison helpers for fenced ownership.
  """

  alias GroundPlane.Contracts.Lease

  defstruct [:resource, :holder, :lease_id, :epoch]

  @type t :: %__MODULE__{
          resource: String.t(),
          holder: String.t(),
          lease_id: String.t(),
          epoch: non_neg_integer()
        }

  @spec from_lease(Lease.t()) :: t()
  def from_lease(%Lease{} = lease) do
    %__MODULE__{
      resource: lease.resource,
      holder: lease.holder,
      lease_id: lease.lease_id,
      epoch: lease.epoch
    }
  end

  @spec newer_than?(t(), t()) :: boolean()
  def newer_than?(%__MODULE__{epoch: left}, %__MODULE__{epoch: right}) do
    left > right
  end
end
