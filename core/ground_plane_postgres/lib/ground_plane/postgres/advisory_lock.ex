defmodule GroundPlane.Postgres.AdvisoryLock do
  @moduledoc """
  Stable advisory-lock key helpers.
  """

  @max_int_32 2_147_483_647

  @spec pair(term(), term()) :: {non_neg_integer(), non_neg_integer()}
  def pair(namespace, subject) do
    {
      :erlang.phash2(namespace, @max_int_32),
      :erlang.phash2(subject, @max_int_32)
    }
  end
end
