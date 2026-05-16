# Contracts

`ground_plane_contracts` holds the lower shared contract surface.

Current contract families:

- ids
- handoff states
- leases
- fences
- checkpoints
- adaptive execution fence receipts

`ground_plane_execution_fencing` owns adaptive lower-primitive fences for run
locks, checkpoint epochs, endpoint leases, resource pool leases, router
artifact epochs, replay epochs, promotion epochs, and revoked candidate
artifacts. It stays ref-only and does not own higher-layer SDKs, domain logic,
state machines, or governance policy.

## Environment Authority Boundary

Contract helpers do not read environment variables, home-directory config,
provider tokens, target grants, or process application environment as
authority. Restart reuse is authorized only from the explicit `Lease`, `Fence`,
and check time supplied by the caller. Revocation and rotation state must be
present in the lease value itself; ambient env cannot complete missing
revocation refs, tenant refs, auth roots, or target grants.

The package is intentionally pure. It should remain reusable across:

- `outer_brain`
- `citadel`
- `jido_integration`
- `app_kit`

It must not depend on product truth or runtime-specific side effects.
