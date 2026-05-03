# Projection

`ground_plane_projection` provides generic projection publication helpers.

The package owns:

- publication record building
- generic payload shaping
- adapter behavior for external sync surfaces

The package does not choose the primary sync product itself.
It stays adapter-shaped so higher repos can bind the chosen sync surface later
without hard-coding that decision into the lower shared layer.

## Environment Authority Boundary

Projection helpers do not read env, home-directory config, application env, or
ambient provider credentials to select an adapter, tenant, target, or
publication destination. The adapter module, publication metadata, tenant refs,
and target refs must be explicit caller-owned values.

The workspace tracks the welded `ground_plane_contracts` artifact through the
prepared bundle flow:

```bash
mix release.prepare
mix release.track
mix release.archive
```

`mix release.track` updates the orphan-backed
`projection/ground_plane_contracts` branch so downstream repos can pin a real
generated-source ref before any formal release boundary exists.
