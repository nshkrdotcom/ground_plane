# GroundPlane Contracts

Pure shared lower contract helpers for ids, repository refs, artifact refs,
handoff states, leases, fences, and checkpoints.

Phase 6 boundary contracts are owned here. `GroundPlane.Boundary.Codec` provides
canonical encoding, decoding, and SHA-256 digests for boundary-significant
payloads. `GroundPlane.Boundary.Envelope`, `DispatchResult`, and `Protocol`
define direct-module cross-plane request/response contracts that are
serializable today and ready for a future governed remote transport.
`GroundPlane.BoundaryProtocol.CommandEnvelope` is the governed-operation
boundary wrapper for GAOP-style command dispatch and maps the stack's `_ref`
field vocabulary to GAOP RFC-0002 names at external edges. The codec rejects
PIDs, references, ports, functions, streams, tasks, raw credential keys,
ambiguous atom/binary keys, and unsupported structs.

Phase 14 restart authorization is owned here. `GroundPlane.Contracts.Fence`
checks revoked credentials, expired leases, stale installation revisions,
stale target grants, rotated handle epochs, duplicate active executions,
old credential lease materialization, delayed retry, target detach, sandbox
restart, process crash, stream reconnect, and workflow resume before any
credential materialization can be reused.

Phase 6 persistence posture is owned here for lower lease/fence/checkpoint
evidence. `GroundPlane.Contracts.PersistencePosture` keeps public contracts
ref-only and memory-by-default while mirroring the shared GroundPlane persistence
profile names for durable evidence. Leases, fences, restart checkpoints, and
cleanup/duplicate-dispatch details carry storage refs but never credential
material, process payloads, or workflow histories.

## Canonical References

- `GroundPlane.Contracts.RepoRef` owns canonical
  `repo://<owner>/<repo>` references.
- `GroundPlane.Contracts.ArtifactRef` owns canonical
  `artifact://<owner>/<repo>/<artifact>` references.
- `GroundPlane.Contracts.ContentAddress` owns primitive `sha256:` content
  address facts with canonical codec, byte-size, and media-type metadata.
- `GroundPlane.Contracts.WorkspaceRef` owns canonical
  `workspace://<owner>/<workspace>` references.

These references are opaque identifiers. They do not carry product, provider,
governance, workflow, release, or audit semantics.

## Persistence Documentation

See `docs/persistence.md` for tiers, defaults, adapters, unsupported selections, config examples, restart claims, durability claims, debug sidecar behavior, redaction guarantees, migration or preflight behavior, and no-bypass scope when applicable.
