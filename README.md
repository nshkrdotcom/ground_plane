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

GroundPlane is the shared lower infrastructure monorepo for the nshkr platform core.

The repository is intentionally generic at this stage. It exists to hold the common lower-layer building blocks that should be reused across `outer_brain`, Citadel, `jido_integration`, and app-facing composition surfaces without forcing those repos to re-invent ids, leases, projection glue, or Postgres runtime helpers independently.

## Scope

- shared contracts
- Postgres durability helpers
- projection publication helpers
- lease and fence primitives
- replay-safe lower infrastructure

## Internal Libraries

- `ground_plane_contracts`
- `ground_plane_postgres`
- `ground_plane_projection`

## Status

Starter repository. The exact internal package boundaries will tighten as the first real consumers land.

## Development

The project targets Elixir `~> 1.19` and Erlang/OTP `28`. The pinned toolchain lives in [`.tool-versions`](./.tool-versions).

```bash
mix deps.get
mix test
```

## Documentation

- [docs/overview.md](./docs/overview.md)
- [docs/internal_libraries.md](./docs/internal_libraries.md)
- [docs/integration_boundaries.md](./docs/integration_boundaries.md)
- [CHANGELOG.md](./CHANGELOG.md)

## License

MIT. Copyright (c) 2026 nshkrdotcom. See [LICENSE](./LICENSE).
