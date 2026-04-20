# Monorepo Project Map

- `./core/ground_plane_contracts/mix.exs`: Pure shared lower contracts for the GroundPlane workspace
- `./core/ground_plane_postgres/mix.exs`: Generic lower Postgres helpers for the GroundPlane workspace
- `./core/ground_plane_projection/mix.exs`: Generic lower projection helpers for the GroundPlane workspace
- `./examples/projection_smoke/mix.exs`: Smoke example for the GroundPlane workspace
- `./mix.exs`: Workspace root for the GroundPlane lower infrastructure monorepo

# AGENTS.md

## Temporal developer environment

Temporal CLI is implicitly available on this workstation as `temporal` for local durable-workflow development. Do not make repo code silently depend on that implicit machine state; prefer explicit scripts, documented versions, and README-tracked ergonomics work.

## Native Temporal development substrate

When Temporal runtime behavior is required, use the stack substrate in `/home/home/p/g/n/mezzanine`:

```bash
just dev-up
just dev-status
just dev-logs
just temporal-ui
```

Do not invent raw `temporal server start-dev` commands for normal work. Do not reset local Temporal state unless the user explicitly approves `just temporal-reset-confirm`.
