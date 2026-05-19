defmodule GroundPlane.PersistencePolicy.Profile do
  @moduledoc "Resolved persistence profile."

  alias GroundPlane.PersistencePolicy.StoreSet

  @enforce_keys [:id, :default_tier, :capture_level, :store_set, :debug_tap]
  defstruct [
    :id,
    :default_tier,
    :capture_level,
    :store_set,
    :debug_tap,
    durable?: false,
    required_live_state?: false,
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          id: atom(),
          default_tier: atom(),
          capture_level: atom(),
          store_set: StoreSet.t(),
          debug_tap: module(),
          durable?: boolean(),
          required_live_state?: boolean(),
          metadata: map()
        }
end
