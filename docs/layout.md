# Layout

`ground_plane` is a non-umbrella workspace root.

The root owns only workspace wiring, docs, and verification.

Internal packages live in:

- `core/ground_plane_contracts`
- `core/ai_run_fencing`
- `core/ground_plane_postgres`
- `core/ground_plane_projection`

The proving example lives in:

- `examples/projection_smoke`

This keeps the repo split between:

- root orchestration and quality wiring
- internal reusable libraries
- one smoke consumer that proves the packages compose cleanly
