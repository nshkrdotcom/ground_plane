defmodule GroundPlane.ExecutionFencing.EpochCompatibilityPolicy do
  @moduledoc """
  Policy data for epoch fence-family aliases.

  Canonical families stay in the public receipts. Compatibility aliases are
  input-side only and must be declared as policy data.
  """

  @default %{
    checkpoint_epoch: [:checkpoint],
    replay_epoch: [:replay],
    promotion_epoch: [:promotion]
  }

  @spec default() :: %{atom() => [atom()]}
  def default, do: @default

  @spec compatible?(atom() | nil, atom(), map() | keyword() | nil) :: boolean()
  def compatible?(actual, expected, policy \\ @default)
  def compatible?(nil, _expected, _policy), do: true
  def compatible?(actual, expected, _policy) when actual == expected, do: true

  def compatible?(actual, expected, policy) do
    policy
    |> normalize()
    |> Map.get(expected, [])
    |> Enum.member?(actual)
  end

  defp normalize(nil), do: @default
  defp normalize(policy) when is_map(policy), do: policy
  defp normalize(policy) when is_list(policy), do: Map.new(policy)
end
