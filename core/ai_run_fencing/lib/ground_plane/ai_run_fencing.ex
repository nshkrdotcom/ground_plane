defmodule GroundPlane.AIRunFencing do
  @moduledoc """
  Ref-only authorization for adaptive AI run fence sets.
  """

  alias GroundPlane.AIRunFencing.CheckpointEpoch
  alias GroundPlane.AIRunFencing.EndpointLease
  alias GroundPlane.AIRunFencing.ProviderPoolLease
  alias GroundPlane.AIRunFencing.ReplayEpoch
  alias GroundPlane.AIRunFencing.RunLock
  alias GroundPlane.AIRunFencing.Validation
  alias GroundPlane.Contracts.PersistencePosture

  @required_refs [:tenant_ref, :ai_run_ref]

  @spec authorize(map()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs) when is_map(attrs) do
    with {:ok, now} <- Validation.fetch_datetime(attrs, :checked_at),
         :ok <- Validation.require_non_empty_refs(attrs, @required_refs),
         {:ok, run_lock} <- RunLock.authorize(Validation.fetch_map!(attrs, :run_lock), now),
         {:ok, checkpoint} <-
           CheckpointEpoch.authorize(Validation.fetch_map!(attrs, :checkpoint_epoch), now),
         {:ok, endpoint} <-
           EndpointLease.authorize(Validation.fetch_map!(attrs, :endpoint_lease), now),
         {:ok, provider_pool} <-
           ProviderPoolLease.authorize(Validation.fetch_map!(attrs, :provider_pool_lease), now),
         {:ok, replay} <- ReplayEpoch.authorize(Validation.fetch_map!(attrs, :replay_epoch), now) do
      {:ok,
       %{
         status: :authorized,
         tenant_ref: Validation.fetch_string!(attrs, :tenant_ref),
         ai_run_ref: Validation.fetch_string!(attrs, :ai_run_ref),
         checked_at: now,
         redacted: true,
         persistence_posture: PersistencePosture.resolve(:ai_run_fence_receipt, attrs),
         fence_receipts: %{
           run_lock: run_lock,
           checkpoint_epoch: checkpoint,
           endpoint_lease: endpoint,
           provider_pool_lease: provider_pool,
           replay_epoch: replay
         }
       }}
    end
  end
end
