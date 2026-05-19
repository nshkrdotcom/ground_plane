defmodule GroundPlane.PersistencePolicy.DebugTap.Noop do
  @moduledoc "Debug tap that records nothing."
  @behaviour GroundPlane.PersistencePolicy.DebugTap

  @impl true
  def emit(tap, _event), do: {:ok, tap}
end
