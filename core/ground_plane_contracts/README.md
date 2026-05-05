# GroundPlane Contracts

Pure shared lower contract helpers for ids, repository refs, artifact refs,
handoff states, leases, fences, and checkpoints.

Phase 14 restart authorization is owned here. `GroundPlane.Contracts.Fence`
checks revoked credentials, expired leases, stale installation revisions,
stale target grants, rotated handle epochs, duplicate active executions,
old credential lease materialization, delayed retry, target detach, sandbox
restart, process crash, stream reconnect, and workflow resume before any
credential materialization can be reused.

## Canonical References

- `GroundPlane.Contracts.RepoRef` owns canonical
  `repo://<owner>/<repo>` references.
- `GroundPlane.Contracts.ArtifactRef` owns canonical
  `artifact://<owner>/<repo>/<artifact>` references.
- `GroundPlane.Contracts.WorkspaceRef` owns canonical
  `workspace://<owner>/<workspace>` references.

These references are opaque identifiers. They do not carry product, provider,
governance, workflow, release, or audit semantics.
