# GroundPlane Generalized Stack Boundary

## Responsibility

GroundPlane owns reusable lower primitives: ids, refs, leases, fences,
checkpoints, persistence profile contracts, debug capture posture, generic
Postgres helpers, and projection publication helpers.

It does not own product workflow, provider adapters, connector behavior,
policy, semantic runtime, agent turns, Temporal workflow semantics, or UI.

## Public Interfaces

Primary package groups:

- `core/ground_plane_contracts`;
- `core/execution_fencing`;
- `core/persistence_policy`;
- `core/persistence_policy_data_extension`;
- `core/ground_plane_postgres`;
- `core/ground_plane_projection`;
- `examples/projection_smoke`.

## Dependency Rules

Allowed dependencies:

- standard library, package-local dependencies, and primitive-supporting
  libraries already declared in package Mix projects;
- no dependency on higher repo internals.

Forbidden dependencies:

- AppKit, Mezzanine, Citadel, Jido Integration, OuterBrain, Extravaganza, or
  Execution Plane implementation modules;
- provider, product, workflow, model, connector, or policy terms in primitive
  code;
- raw secrets, environment-driven provider selection, or live network calls;
- unsupervised processes.

## Provider Vocabulary Zoning

Provider or product terms may appear only in documentation that explains what
GroundPlane must not own. They must not appear in primitive APIs, tests,
fixtures, or package names unless a test is explicitly proving rejection of
higher semantics.

## Migration And Cleanup Ownership

GroundPlane cleanup work removes higher-layer concepts from primitive packages,
deletes duplicate lower helpers after a canonical primitive exists, and keeps
old examples out of public guidance.
