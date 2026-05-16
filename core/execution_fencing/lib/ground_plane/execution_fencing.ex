defmodule GroundPlane.ExecutionFencing do
  @moduledoc """
  Ref-only authorization for adaptive execution fence sets.
  """

  alias GroundPlane.Contracts.PersistencePosture
  alias GroundPlane.ExecutionFencing.CheckpointEpoch
  alias GroundPlane.ExecutionFencing.EndpointLease
  alias GroundPlane.ExecutionFencing.ReplayEpoch
  alias GroundPlane.ExecutionFencing.ResourcePoolLease
  alias GroundPlane.ExecutionFencing.RunLock
  alias GroundPlane.ExecutionFencing.Validation

  @required_refs [:tenant_ref, :execution_ref]

  @spec authorize(map()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs) when is_map(attrs) do
    with {:ok, now} <- Validation.fetch_datetime(attrs, :checked_at),
         :ok <- Validation.require_non_empty_refs(attrs, @required_refs),
         {:ok, run_lock} <- RunLock.authorize(Validation.fetch_map!(attrs, :run_lock), now),
         {:ok, checkpoint} <-
           CheckpointEpoch.authorize(Validation.fetch_map!(attrs, :checkpoint_epoch), now),
         {:ok, endpoint} <-
           EndpointLease.authorize(Validation.fetch_map!(attrs, :endpoint_lease), now),
         {:ok, resource_pool} <-
           ResourcePoolLease.authorize(Validation.fetch_map!(attrs, :resource_pool_lease), now),
         {:ok, replay} <- ReplayEpoch.authorize(Validation.fetch_map!(attrs, :replay_epoch), now) do
      {:ok,
       %{
         status: :authorized,
         tenant_ref: Validation.fetch_string!(attrs, :tenant_ref),
         execution_ref: Validation.fetch_string!(attrs, :execution_ref),
         checked_at: now,
         redacted: true,
         persistence_posture: PersistencePosture.resolve(:execution_fence_receipt, attrs),
         fence_receipts: %{
           run_lock: run_lock,
           checkpoint_epoch: checkpoint,
           endpoint_lease: endpoint,
           resource_pool_lease: resource_pool,
           replay_epoch: replay
         }
       }}
    end
  end
end
