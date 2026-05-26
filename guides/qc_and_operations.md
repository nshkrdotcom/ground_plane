# GroundPlane QC And Operations

## Local Commands

```bash
mix ci
mix release.prepare
mix release.track
mix release.archive
```

Run package-local tests for focused primitive changes, then root `mix ci`
before commit. Run release tracking only when contract artifacts change.

## Scanner And Proof Obligations

GroundPlane changes must keep these obligations green:

- package-local tests for contracts, fencing, persistence policy, Postgres
  helpers, projection helpers, and smoke examples;
- Weld/release artifact checks when public packages change;
- StackLab artifact ledger and primitive posture checks when downstream
  contracts change;
- boundary codec rejection fixtures for `raw`/`raw_*`, credential,
  authorization, session, and token-shaped metadata keys;
- no Regex usage in touched code/tests;
- no dynamic atom construction from runtime input;
- no unsupervised process starts.

## Secrets And Live Providers

GroundPlane must not read, store, lease, or materialize provider credentials.
It has no GitHub or Linear live command surface. Any higher proof that uses
GroundPlane primitives and reaches those providers must be run by the higher
owner with:

```bash
~/scripts/with_bash_secrets
```

## Tenant, Observability, And Replay

Primitive refs should be tenant-capable when used by higher repos, but
GroundPlane does not decide tenant policy. It provides stable refs, hashes,
lease/fence epochs, persistence profile facts, and projection receipts that
higher repos can join into AITrace or StackLab evidence.

## Documentation Checks

After doc edits, run:

```bash
test -f README.md
find guides -maxdepth 1 -type f -name '*.md' -print | sort
git diff --check -- README.md guides
```
