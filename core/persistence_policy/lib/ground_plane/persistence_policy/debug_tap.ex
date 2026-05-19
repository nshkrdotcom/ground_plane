defmodule GroundPlane.PersistencePolicy.DebugTap do
  @moduledoc "Debug tap behaviour. Taps are optional and must not own truth."

  @callback emit(tap :: term(), event :: map()) :: {:ok, term()} | {:error, term()}
end
