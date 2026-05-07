# GroundPlane AI Run Fencing

Lower-primitive fencing for adaptive AI run refs, endpoint leases, provider
pool leases, checkpoint epochs, replay epochs, router artifact epochs, and
promotion epochs.

This package owns ref-only validation and fail-closed receipts. It does not own
provider SDKs, product behavior, workflow state machines, or governance policy.

Phase 6 receipts now include persistence posture for AI run fences. The default
profile is memory-only; durable profiles add store/tier/receipt refs to lease,
epoch, and top-level fence receipts without carrying provider payloads, prompts,
workflow histories, or product-policy decisions.
