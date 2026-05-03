# Postgres Helpers

`ground_plane_postgres` provides generic helpers for persistence patterns that
multiple repos will need.

Current helper families:

- transaction helpers
- advisory-lock key helpers
- outbox and inbox row helpers
- checkpoint row helpers

## Environment Authority Boundary

Postgres helpers do not read `DATABASE_URL`, `PG*`, home-directory config, or
application env. Callers own adapter setup and connection authority outside
GroundPlane. These helpers only transform explicit row values and adapter
modules passed by the caller.

These helpers are intentionally generic over the caller's schemas and tables.
They return or transform generic row maps and helper values instead of owning
product semantics.
