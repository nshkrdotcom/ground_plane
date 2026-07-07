# Monorepo Project Map

- `./core/ground_plane_contracts/mix.exs`: Pure shared lower contracts for the GroundPlane workspace
- `./core/execution_fencing/mix.exs`: Ref-only adaptive execution fence and epoch contracts
- `./core/ground_plane_postgres/mix.exs`: Generic lower Postgres helpers for the GroundPlane workspace
- `./core/ground_plane_projection/mix.exs`: Generic lower projection helpers for the GroundPlane workspace
- `./examples/projection_smoke/mix.exs`: Smoke example for the GroundPlane workspace
- `./mix.exs`: Workspace root for the GroundPlane lower infrastructure monorepo

# AGENTS.md

## Onboarding

Read `ONBOARDING.md` first for the repo's one-screen ownership, first command,
and proof path.

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

## Dependency Sources

- Dependency source selection is handled by `build_support/dependency_sources.exs` and `build_support/dependency_sources.config.exs`.
- Local dependency overrides use `.dependency_sources.local.exs`.
- Dependency source selection must not use environment variables.
- Same-repo workspace package paths may stay in their local `mix.exs` files; cross-repo dependencies that need fallback behavior belong in the dependency-source manifest.
- Weld checks helper drift, dependency-source manifests, clone/publish checks, and publish order for this repo; keep the committed dependency on the released Hex Weld line.

## Runtime Env

- Runtime application code under `lib/**`, package `lib/**`, example `lib/**`, and Mix task modules must not call direct OS env APIs such as `System.get_env`, `System.fetch_env`, `System.put_env`, or `System.delete_env`.
- Runtime/deployment env reads belong in `config/runtime.exs` or a `Config.Provider`.
- Mix tasks, examples, and harnesses should accept explicit flags, app config, or caller-supplied env maps instead of reading or mutating process env.

## Design intent — cross-node substrate

- These primitives (refs, ids, fences, leases, checkpoints) are the substrate
  that must stay valid **across the node boundary** in the target architecture,
  where Execution Plane runs as a separate, hard-isolated effect node (see
  execution_plane/AGENTS.md → *Design Intent — Effect Isolation*). A ref, lease,
  or fence minted on the governance node must remain meaningful and enforceable
  when the effect executes on a different node.
- Keep primitives node-portable and free of local-process assumptions. That
  portability is what makes effect isolation coherent rather than just a
  deployment detail — the boundary between deciding and doing can only be
  hardened if identity, fencing, and leasing survive the crossing.

<!-- gn-ten:repo-agent:start repo=ground_plane source_sha=ab276c0640772b73065ab12bf05d77be51f1bb67 -->
# ground_plane Agent Instructions Draft

## Owns

- Universal lower primitives.
- IDs and refs.
- Fences and leases.
- Checkpoints.
- Generic persistence and projection helpers.

## Does Not Own

- AI semantics.
- Provider names.
- Product names.
- Governance policy.
- Execution lane behavior.
- Workflow state machines.

## Allowed Dependencies

- Standard library and minimal generic dependencies required for primitives.

## Forbidden Imports

- Any ranked repo above GroundPlane.
- Provider SDKs.
- Product packages.

## Verification

- `mix ci`
- Focused tests in `core/ground_plane_contracts` for new primitives.

## Escalation

Promote a primitive only when it is truly universal and can be named without
referencing a product, provider, or mechanism.
<!-- gn-ten:repo-agent:end -->

## Blitz 0.3.0 operational note

Root workspace Blitz uses published Hex `~> 0.3.0` by default; `.blitz/` is committed compact impact state after green QC. Source and `mix.exs` changes cascade through reverse workspace dependencies; docs-only changes should stay owner-local.
