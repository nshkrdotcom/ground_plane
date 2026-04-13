# Projection

`ground_plane_projection` provides generic projection publication helpers.

The package owns:

- publication record building
- generic payload shaping
- adapter behavior for external sync surfaces

The package does not choose the primary sync product itself.
It stays adapter-shaped so higher repos can bind the chosen sync surface later
without hard-coding that decision into the lower shared layer.

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
