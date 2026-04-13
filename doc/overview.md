# Overview

GroundPlane is the shared lower infrastructure layer for the platform core.

It exists to keep lower reusable primitives out of higher runtime repos.

The repo owns:

- replay-safe ids
- shared handoff-state vocabulary
- lease and fence structs
- checkpoint vocabulary
- generic Postgres helper modules
- generic projection publication helpers

The repo does not own:

- semantic journals
- policy truth
- run and attempt truth
- operator or governed-run semantics
- product trust or review logic
