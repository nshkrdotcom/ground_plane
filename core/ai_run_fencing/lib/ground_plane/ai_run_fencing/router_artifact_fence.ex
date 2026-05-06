defmodule GroundPlane.AIRunFencing.RouterArtifactFence do
  @moduledoc """
  Router artifact epoch fence for adaptive coordination artifacts.
  """

  alias GroundPlane.AIRunFencing.EpochFence

  @spec authorize(map(), DateTime.t()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now) when is_map(attrs) do
    EpochFence.authorize(attrs, now, %{
      family: :router_artifact,
      stale_reason: :stale_router_artifact,
      revoked_reason: :router_artifact_revoked
    })
  end
end
