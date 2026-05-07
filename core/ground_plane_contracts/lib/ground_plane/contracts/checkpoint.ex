defmodule GroundPlane.Contracts.Checkpoint do
  @moduledoc """
  Shared checkpoint vocabulary for replay and projection positions.
  """

  alias GroundPlane.Contracts.PersistencePosture

  defstruct [:stream, :position, :reason, :persistence_posture]

  @type t :: %__MODULE__{
          stream: String.t(),
          position: non_neg_integer(),
          reason: String.t(),
          persistence_posture: map() | nil
        }

  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs) do
    case attrs do
      %{stream: stream, position: position, reason: reason}
      when is_binary(stream) and is_integer(position) and position >= 0 and is_binary(reason) ->
        {:ok,
         %__MODULE__{
           stream: stream,
           position: position,
           reason: reason,
           persistence_posture: PersistencePosture.resolve(:restart_checkpoint, attrs)
         }}

      _ ->
        {:error, :invalid_checkpoint}
    end
  end

  @spec advance(t(), non_neg_integer(), String.t()) :: {:ok, t()} | {:error, term()}
  def advance(%__MODULE__{stream: stream, position: current} = checkpoint, next_position, reason)
      when is_integer(next_position) and next_position >= current and is_binary(reason) do
    {:ok,
     %__MODULE__{
       stream: stream,
       position: next_position,
       reason: reason,
       persistence_posture: checkpoint.persistence_posture
     }}
  end

  def advance(%__MODULE__{}, _next_position, _reason) do
    {:error, :checkpoint_regressed}
  end
end
