defmodule GroundPlane.PersistencePolicy.Tier do
  @moduledoc "Persistence tier enum."

  @tiers [
    :off,
    :memory_ephemeral,
    :local_restart_safe,
    :postgres_shared,
    :temporal_durable,
    :object_store
  ]

  @durable_tiers [
    :local_restart_safe,
    :postgres_shared,
    :temporal_durable,
    :object_store
  ]

  @spec all() :: [atom()]
  def all, do: @tiers

  @spec durable() :: [atom()]
  def durable, do: @durable_tiers

  @spec validate(atom()) :: {:ok, atom()} | {:error, term()}
  def validate(tier) when tier in @tiers, do: {:ok, tier}
  def validate(tier), do: {:error, {:unsupported_tier, tier}}

  @spec durable?(atom()) :: boolean()
  def durable?(tier), do: tier in @durable_tiers
end
