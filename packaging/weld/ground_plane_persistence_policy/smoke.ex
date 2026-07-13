defmodule GroundPlane.PersistencePolicy.WeldSmoke do
  @moduledoc false

  alias GroundPlane.PersistencePolicy

  def representative_policy do
    profile = PersistencePolicy.resolve!(profile: :memory_debug)

    %{
      profile: profile.id,
      tier: profile.default_tier,
      capture_level: profile.capture_level,
      durable?: profile.durable?
    }
  end
end
