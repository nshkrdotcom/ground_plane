defmodule GroundPlane.Projection.Adapter do
  @moduledoc """
  Adapter behavior for publishing normalized projections.
  """

  @callback publish(map()) :: {:ok, term()} | {:error, term()}
end
