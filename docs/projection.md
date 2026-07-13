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

The workspace exposes independent Weld artifacts for the two public lower
leaves. Select each artifact explicitly during preparation:

```bash
mix release.prepare --artifact ground_plane_contracts
mix release.prepare --artifact ground_plane_persistence_policy
```

Optional `mix release.track --artifact <artifact>` commands update the
orphan-backed `projection/ground_plane_contracts` and
`projection/ground_plane_persistence_policy` branches. Those branches are
generated-source references, not publication receipts. Run
`mix release.archive --artifact <artifact>` only after the corresponding Hex
publication has been independently verified.
