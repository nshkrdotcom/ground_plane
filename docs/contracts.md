# Contracts

`ground_plane_contracts` holds the lower shared contract surface.

Current contract families:

- ids
- handoff states
- leases
- fences
- checkpoints
- adaptive execution fence receipts
- boundary protocol command envelopes

## Boundary Protocol Command Envelope

`GroundPlane.BoundaryProtocol.CommandEnvelope` is the governed-operation
boundary wrapper used by the Synapse live lift. It is a pure value object and
uses `GroundPlane.Boundary.Codec.encode!/1` and `GroundPlane.Boundary.Codec.digest/1`
for canonical JSON and `sha256:` integrity hashes. It does not introduce a
second canonicalization implementation.

The internal stack names map to GAOP RFC-0002 names at external protocol
edges:

| Internal field | GAOP field |
| --- | --- |
| `protocol_version` | `protocol_version` |
| `command_ref` | `command_id` |
| `tenant_ref` | `tenant_id` |
| `actor_ref` | `actor_ref` |
| `idempotency_key` | `idempotency_key` |
| `trace_ref` | `trace_id` |
| `operation_type` | `requested_capability.operation` |
| `operation_type` | `requested_capability.capability_id` |
| `effect_class` | `requested_capability.effect_class` |
| `intent` | `intent` |
| `resource_scopes` | `resource_scopes` |
| `created_at` | `created_at` |
| `installation_ref` | `metadata.installation_ref` |
| `schema_ref` | `metadata.schema_ref` |
| `authority_ref` | `metadata.authority_ref` |
| `expected_version` | `metadata.expected_version` |

The boundary error taxonomy is deliberately small:

- `missing_tenant`
- `invalid_schema`
- `duplicate_idempotency`
- `version_conflict`
- `non_serializable`

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
