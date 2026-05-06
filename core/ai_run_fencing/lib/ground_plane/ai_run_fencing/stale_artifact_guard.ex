defmodule GroundPlane.AIRunFencing.StaleArtifactGuard do
  @moduledoc """
  Fail-closed stale artifact guard for adaptive checkpoint, router, candidate,
  prompt-promotion, and promotion epochs.
  """

  alias GroundPlane.AIRunFencing.CheckpointEpoch
  alias GroundPlane.AIRunFencing.EpochFence
  alias GroundPlane.AIRunFencing.PromotionEpoch
  alias GroundPlane.AIRunFencing.RouterArtifactFence
  alias GroundPlane.AIRunFencing.Validation

  @required_refs [:tenant_ref, :ai_run_ref, :artifact_ref]

  @spec authorize(map()) :: {:ok, map()} | {:error, {atom(), map()}}
  def authorize(attrs) when is_map(attrs) do
    with {:ok, now} <- Validation.fetch_datetime(attrs, :checked_at),
         :ok <- Validation.require_non_empty_refs(attrs, @required_refs),
         {:ok, checkpoint} <-
           CheckpointEpoch.authorize(Validation.fetch_map!(attrs, :checkpoint_epoch), now),
         {:ok, router} <-
           RouterArtifactFence.authorize(
             Validation.fetch_map!(attrs, :router_artifact_fence),
             now
           ),
         {:ok, candidate} <-
           authorize_candidate(Validation.fetch_map!(attrs, :candidate_epoch), now),
         {:ok, prompt_promotion} <-
           authorize_prompt_promotion(Validation.fetch_map!(attrs, :prompt_promotion_epoch), now),
         {:ok, promotion} <-
           PromotionEpoch.authorize(Validation.fetch_map!(attrs, :promotion_epoch), now) do
      {:ok,
       %{
         status: :artifact_authorized,
         tenant_ref: Validation.fetch_string!(attrs, :tenant_ref),
         ai_run_ref: Validation.fetch_string!(attrs, :ai_run_ref),
         artifact_ref: Validation.fetch_string!(attrs, :artifact_ref),
         checked_at: now,
         redacted: true,
         epoch_receipts: %{
           checkpoint: checkpoint,
           router_artifact: router,
           candidate: candidate,
           prompt_promotion: prompt_promotion,
           promotion: promotion
         }
       }}
    end
  end

  defp authorize_candidate(attrs, now) do
    EpochFence.authorize(attrs, now, %{
      family: :candidate,
      stale_reason: :stale_candidate,
      revoked_reason: :candidate_revoked
    })
  end

  defp authorize_prompt_promotion(attrs, now) do
    EpochFence.authorize(attrs, now, %{
      family: :prompt_promotion,
      stale_reason: :stale_prompt_promotion,
      revoked_reason: :prompt_promotion_revoked
    })
  end
end
