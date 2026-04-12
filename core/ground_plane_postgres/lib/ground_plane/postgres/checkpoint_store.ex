defmodule GroundPlane.Postgres.CheckpointStore do
  @moduledoc """
  Generic checkpoint row helpers.
  """

  alias GroundPlane.Contracts.Checkpoint

  @spec record(String.t(), non_neg_integer(), String.t(), keyword()) :: map()
  def record(stream, position, reason, opts \\ []) do
    %{
      checkpoint_id: Keyword.get(opts, :checkpoint_id, "checkpoint"),
      stream: stream,
      position: position,
      reason: reason
    }
  end

  @spec advance(map(), non_neg_integer(), String.t()) :: {:ok, map()} | {:error, term()}
  def advance(current, next_position, reason) do
    with {:ok, checkpoint} <-
           Checkpoint.new(%{
             stream: current.stream,
             position: current.position,
             reason: current.reason
           }),
         {:ok, advanced} <- Checkpoint.advance(checkpoint, next_position, reason) do
      {:ok,
       current
       |> Map.put(:position, advanced.position)
       |> Map.put(:reason, advanced.reason)}
    end
  end
end
