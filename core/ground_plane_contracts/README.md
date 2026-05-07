# GroundPlane Contracts

Pure shared lower contract helpers for ids, repository refs, artifact refs,
handoff states, leases, fences, and checkpoints.

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
- `GroundPlane.Contracts.WorkspaceRef` owns canonical
  `workspace://<owner>/<workspace>` references.

These references are opaque identifiers. They do not carry product, provider,
governance, workflow, release, or audit semantics.
