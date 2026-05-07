# GroundPlane Postgres Persistence

## Scope

GroundPlane Postgres owns generic Postgres transaction, outbox, inbox, lock, and checkpoint helper owner. This document is package-local and is the persistence contract for `core/ground_plane_postgres` in `ground_plane`.

## Available Tiers

- `:mickey_mouse`: memory or ref-only default. No restart durability claim.
- `:memory_debug`: memory or ref-only with redacted debug evidence only.
- `:local_restart_safe`: supported only when this package or a named adapter package owns a local durable store and preflight proof.
- `:integration_postgres`: supported only when a named Postgres or AshPostgres adapter and migration proof are configured.
- `:ops_durable`: supported only for Temporal-owning runtime packages after explicit substrate proof.
- `:full_debug_tracked`: supported only when durable storage and redacted debug capture are both explicitly preflighted.

## Default Tier

The default tier is `:mickey_mouse`. It is memory-only or ref-only and is lost on restart unless this package explicitly states that a local durable adapter has been selected by the caller.

## Capture Levels

Supported capture levels are `:off`, `:metadata`, `:refs_only`, `:redacted_debug`, and `:full_debug` when the package explicitly supports full debug. Raw credentials, auth headers, token files, credential bodies, raw prompt bodies, raw provider payload bodies, native auth file content, private keys, session cookies, refresh tokens, access tokens, database URLs with credentials, and object-store signed URLs are always forbidden.

## Supported Adapters

Postgres helper package only. It is not selected by any caller unless explicitly configured.

## Unsupported Adapters

Unsupported adapter selections fail before mutation. Silent fallback from durable selection to memory is invalid. Product code must not import lower store modules directly to compensate for a missing adapter.

## Configuration Precedence

Configuration is explicit caller data first, package option second, release profile third, and built-in default last. Governed flows do not read process environment, local credential files, provider defaults, singleton clients, or application configuration as authority unless this package names a standalone boot boundary.

## Example Config

```elixir
# Default deterministic profile.
[persistence_profile: :mickey_mouse]

# Redacted in-memory debug profile.
[persistence_profile: :memory_debug, capture_level: :redacted_debug]

# Durable opt-in example. The caller must also pass adapter capability and preflight proof.
[persistence_profile: :integration_postgres]
```

## Test Commands

```bash
cd core/ground_plane_postgres && mix test; root mix ci
```

## Lost-On-Restart Claims

`:mickey_mouse` and `:memory_debug` data is lost on BEAM or process restart unless the package explicitly says a local durable adapter was selected. Memory profiles may prove semantics, validation, and receipt shape; they do not prove restart durability.

## Valid Durability Claims

Valid durability claims require explicit profile selection, adapter capability, migration or substrate preflight, redacted evidence, focused tests, repo QC, and a pushed commit. :integration_postgres style selections require caller-owned database config and migration proof.

## Invalid Durability Claims

Invalid claims include ambient provider credentials, default database reachability, default Temporal reachability, object-store availability without opt-in, network reachability, raw debug capture, raw prompt capture, raw provider payload capture, and product direct lower-store imports.

## Debug Sidecar Behavior

Debug sidecars are disabled by default. When enabled, they are read-only or append-only redacted evidence surfaces. Debug failure must be non-mutating and must not alter authority, lease, run, workflow, store, projection, or product state.

## Redaction Guarantees

Evidence stores opaque refs, stable redacted ids, hashes, bounded metadata, claim-check refs, capture tags, receipt refs, store refs without credentials, and partition refs without secrets. Raw secret and raw payload fields are rejected before persistence or export.

## Migration And Preflight Behavior

Schema owners above this helper define migrations; this package supplies lower helper primitives.

## Phase 12 No-Application-Schema Closeout

- Tier: helper-only for `:integration_postgres` callers.
- Schema owner: none in this package for the overlay release.
- Migration owner: none in this package for the overlay release.
- Migration command: not applicable.
- Migration preflight command: caller-owned Postgres adapter preflight; this helper does not make a release durability claim by itself.
- Failure behavior: callers that select durable Postgres without their own schema owner, migration proof, and store capability must fail before mutation.
- Rollback behavior: rollback is caller-owned because this helper owns no application tables.
- Tagged test command: `cd core/ground_plane_postgres && mix test` plus root `mix ci` when docs or helper contracts change.
- Release claim boundary: this package can support caller durability but cannot be used as standalone proof of application-schema migration, restart safety, or product persistence.
