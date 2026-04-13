# Postgres Helpers

`ground_plane_postgres` provides generic helpers for persistence patterns that
multiple repos will need.

Current helper families:

- transaction helpers
- advisory-lock key helpers
- outbox and inbox row helpers
- checkpoint row helpers

These helpers are intentionally generic over the caller's schemas and tables.
They return or transform generic row maps and helper values instead of owning
product semantics.
