# Contracts

`ground_plane_contracts` holds the lower shared contract surface.

Current contract families:

- ids
- handoff states
- leases
- fences
- checkpoints

The package is intentionally pure. It should remain reusable across:

- `outer_brain`
- `citadel`
- `jido_integration`
- `app_kit`

It must not depend on product truth or runtime-specific side effects.
