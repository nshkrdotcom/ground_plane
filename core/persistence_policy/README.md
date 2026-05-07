# GroundPlane Persistence Policy

Pure persistence profile, tier, capture-level, store-set, partition, and debug
tap contracts for the governed runtime.

The built-in default is `:mickey_mouse`: memory-only, no durable
infrastructure, no live provider credentials, no network requirement, no
object store, and no debug sidecar.

This package does not depend on Ecto, AshPostgres, Temporal, object stores,
provider SDKs, product repos, or optional external substrates. Adapter packages
own their own schemas, migrations, and durable preflights.

## Profiles

Profile resolution is pure data. Callers pass profile hints from their own
platform layer; this package never reads process environment, application
environment, files, provider credentials, or network state.

Profile precedence is:

1. `:profile`
2. `:persistence_profile`
3. `:workflow_profile`
4. `:session_profile`
5. `:authority_profile`
6. `:tenant_policy_profile`
7. `:host_profile`
8. `:release_profile`
9. `:package_profile`
10. `:global_profile`

Built-in profiles:

| Profile | Default tier | Capture level | Durable | Live state required |
|---|---|---|---|---|
| `:mickey_mouse` | `:memory_ephemeral` | `:off` | no | no |
| `:memory_debug` | `:memory_ephemeral` | `:redacted_debug` | no | no |
| `:local_restart_safe` | `:local_restart_safe` | `:metadata` | yes | no |
| `:integration_postgres` | `:postgres_shared` | `:refs_only` | yes | no |
| `:ops_durable` | `:temporal_durable` | `:refs_only` | yes | yes |
| `:full_debug_tracked` | `:postgres_shared` | `:full_debug` | yes | no |
| `:distributed_partitioned` | `:postgres_shared` | `:metadata` | yes | no |

Durable profiles must be explicitly selected and must pass caller-supplied
capability preflight. Missing durable capability is an error, not a fallback to
memory.

## Debug Capture

`GroundPlane.PersistencePolicy.DebugTap.Noop` records nothing.
`GroundPlane.PersistencePolicy.DebugTap.MemoryRing` stores a bounded in-memory
list of redacted metadata events. Debug taps reject forbidden raw fields before
mutating tap state, and tap failures return the original tap unchanged.

Forbidden debug event keys include raw secrets, raw prompts, provider payloads,
auth headers, API keys, OAuth secrets, token files, credential bodies, native
auth file content, and unredacted provider account identifiers.
