defmodule GroundPlane.AIRunFencing.StaleArtifactGuardTest do
  use ExUnit.Case, async: true

  alias GroundPlane.AIRunFencing.PromotionEpoch
  alias GroundPlane.AIRunFencing.RouterArtifactFence
  alias GroundPlane.AIRunFencing.StaleArtifactGuard

  test "AOC-010 rejects stale checkpoint router candidate prompt and promotion artifacts before use" do
    now = DateTime.from_unix!(1_700_000_000)

    assert {:ok, receipt} =
             StaleArtifactGuard.authorize(%{
               tenant_ref: "tenant://adaptive/a",
               ai_run_ref: "ai-run://adaptive/run-1",
               artifact_ref: "candidate://adaptive/run-1/current",
               checkpoint_epoch: epoch(:checkpoint),
               router_artifact_fence: epoch(:router_artifact),
               candidate_epoch: epoch(:candidate),
               prompt_promotion_epoch: epoch(:prompt_promotion),
               promotion_epoch: epoch(:promotion),
               checked_at: now
             })

    assert receipt.status == :artifact_authorized
    assert receipt.artifact_ref == "candidate://adaptive/run-1/current"
    assert receipt.epoch_receipts.candidate.fence_family == :candidate
    refute Map.has_key?(receipt, :prompt)
    refute Map.has_key?(receipt, :model_output)

    assert {:error, {:stale_router_artifact, _details}} =
             RouterArtifactFence.authorize(%{epoch(:router_artifact) | observed_epoch: 1}, now)

    assert {:error, {:stale_promotion_epoch, _details}} =
             PromotionEpoch.authorize(%{epoch(:promotion) | observed_epoch: 2}, now)

    assert {:error, {:candidate_revoked, details}} =
             StaleArtifactGuard.authorize(%{
               tenant_ref: "tenant://adaptive/a",
               ai_run_ref: "ai-run://adaptive/run-1",
               artifact_ref: "candidate://adaptive/run-1/current",
               checkpoint_epoch: epoch(:checkpoint),
               router_artifact_fence: epoch(:router_artifact),
               candidate_epoch:
                 Map.merge(epoch(:candidate), %{
                   revoked_at: now,
                   revocation_ref: "revocation://candidate/1"
                 }),
               prompt_promotion_epoch: epoch(:prompt_promotion),
               promotion_epoch: epoch(:promotion),
               checked_at: now
             })

    assert details.revocation_ref == "revocation://candidate/1"
  end

  defp epoch(kind) do
    %{
      fence_family: kind,
      artifact_ref: "#{kind}://adaptive/run-1/current",
      expected_epoch: 5,
      observed_epoch: 5,
      epoch_ref: "epoch://adaptive/run-1/#{kind}/5"
    }
  end
end
