# GroundPlane Contracts

Pure shared lower contract helpers for ids, repository refs, artifact refs,
handoff states, leases, fences, and checkpoints.

## Canonical References

- `GroundPlane.Contracts.RepoRef` owns canonical
  `repo://<owner>/<repo>` references.
- `GroundPlane.Contracts.ArtifactRef` owns canonical
  `artifact://<owner>/<repo>/<artifact>` references.
- `GroundPlane.Contracts.WorkspaceRef` owns canonical
  `workspace://<owner>/<workspace>` references.

These references are opaque identifiers. They do not carry product, provider,
governance, workflow, release, or audit semantics.
