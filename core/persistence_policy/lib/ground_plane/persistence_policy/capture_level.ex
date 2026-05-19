defmodule GroundPlane.PersistencePolicy.CaptureLevel do
  @moduledoc "Debug capture-level enum."

  @levels [
    :off,
    :refs_only,
    :metadata,
    :redacted_debug,
    :full_debug
  ]

  @spec all() :: [atom()]
  def all, do: @levels

  @spec validate(atom()) :: {:ok, atom()} | {:error, term()}
  def validate(level) when level in @levels, do: {:ok, level}
  def validate(level), do: {:error, {:unsupported_capture_level, level}}
end
