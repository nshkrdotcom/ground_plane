<p align="center">
  <img src="assets/ground_plane.svg" width="200" height="200" alt="GroundPlane logo" />
</p>

<p align="center">
  <a href="https://github.com/nshkrdotcom/ground_plane/actions/workflows/ci.yml">
    <img alt="GitHub Actions Workflow Status" src="https://github.com/nshkrdotcom/ground_plane/actions/workflows/ci.yml/badge.svg" />
  </a>
  <a href="https://github.com/nshkrdotcom/ground_plane/blob/main/LICENSE">
    <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-0b0f14.svg" />
  </a>
</p>

# GroundPlane

GroundPlane is the shared lower infrastructure workspace for the nshkr platform
core.

It holds the reusable lower primitives that sit underneath `outer_brain`,
Citadel, `jido_integration`, and `app_kit`.

## Scope

- shared contracts and state vocabulary
- Postgres transaction, outbox, inbox, and checkpoint helpers
- generic projection publication helpers

## Internal Libraries

- `ground_plane_contracts`
- `ground_plane_postgres`
- `ground_plane_projection`

## Status

Workspace root established. The internal packages are intentionally small and
generic.

## Development

The project targets Elixir `~> 1.19` and Erlang/OTP `28`.

```bash
mix ci
```

## Documentation

Workspace docs cover the overview, layout, contracts, Postgres helpers, and
projection helpers.

## License

MIT. Copyright (c) 2026 nshkrdotcom.
