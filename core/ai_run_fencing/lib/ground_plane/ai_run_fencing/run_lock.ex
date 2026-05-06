defmodule GroundPlane.AIRunFencing.RunLock do
  @moduledoc """
  Run lock fence for idempotent adaptive AI run execution.
  """

  alias GroundPlane.AIRunFencing.Validation

  @required_refs [
    :ai_run_ref,
    :idempotency_ref,
    :active_execution_ref,
    :current_execution_ref
  ]

  @spec authorize(map(), DateTime.t()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs, %DateTime{} = now) when is_map(attrs) do
    with :ok <- Validation.require_non_empty_refs(attrs, @required_refs),
         {:ok, lock_epoch} <- Validation.fetch_non_negative_integer(attrs, :lock_epoch),
         :ok <- ensure_single_active_execution(attrs, now) do
      {:ok,
       %{
         status: :authorized,
         fence_family: :run_lock,
         ai_run_ref: Validation.fetch_string!(attrs, :ai_run_ref),
         idempotency_ref: Validation.fetch_string!(attrs, :idempotency_ref),
         active_execution_ref: Validation.fetch_string!(attrs, :active_execution_ref),
         lock_epoch: lock_epoch,
         checked_at: now,
         redacted: true
       }}
    end
  end

  defp ensure_single_active_execution(attrs, now) do
    active = Validation.fetch_string!(attrs, :active_execution_ref)
    current = Validation.fetch_string!(attrs, :current_execution_ref)

    if active == current do
      :ok
    else
      {:error,
       {:duplicate_active_run,
        %{
          ai_run_ref: Validation.fetch_string!(attrs, :ai_run_ref),
          active_execution_ref: active,
          current_execution_ref: current,
          checked_at: now,
          redacted: true
        }}}
    end
  end
end
