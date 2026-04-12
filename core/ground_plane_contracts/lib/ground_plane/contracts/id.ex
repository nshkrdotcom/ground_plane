defmodule GroundPlane.Contracts.Id do
  @moduledoc """
  Helpers for replay-safe identifier construction.
  """

  @id_pattern ~r/^[a-z0-9]+(?:_[a-z0-9]+)+$/

  @spec build(String.t(), String.t()) :: String.t()
  def build(prefix, suffix) when is_binary(prefix) and is_binary(suffix) do
    normalized_prefix = normalize_segment(prefix)
    normalized_suffix = normalize_segment(suffix)

    "#{normalized_prefix}_#{normalized_suffix}"
  end

  @spec random(String.t()) :: String.t()
  def random(prefix) when is_binary(prefix) do
    prefix
    |> build(random_suffix())
  end

  @spec valid?(term()) :: boolean()
  def valid?(value) when is_binary(value) do
    String.match?(value, @id_pattern)
  end

  def valid?(_value), do: false

  defp random_suffix do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp normalize_segment(segment) do
    segment
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
  end
end
