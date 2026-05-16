# GroundPlane Execution Fencing

Lower-primitive fencing for long-running execution refs, endpoint leases, resource
pool leases, checkpoint epochs, replay epochs, router artifact epochs, and
promotion epochs.

This package owns ref-only validation and fail-closed receipts. It does not own
higher-layer behavior, state machines, or governance policy.

Phase 6 receipts now include persistence posture for execution fences. The default
profile is memory-only; durable profiles add store/tier/receipt refs to lease,
epoch, and top-level fence receipts without carrying raw external payloads,
prompts, histories, or policy decisions.

## Persistence Documentation

See `docs/persistence.md` for tiers, defaults, adapters, unsupported selections, config examples, restart claims, durability claims, debug sidecar behavior, redaction guarantees, migration or preflight behavior, and no-bypass scope when applicable.
