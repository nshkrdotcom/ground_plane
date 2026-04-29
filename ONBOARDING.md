# ground_plane Onboarding

Read `AGENTS.md` first; the managed gn-ten section is the repo contract.
`CLAUDE.md` must stay a one-line compatibility shim containing `@AGENTS.md`.

## Owns

Universal lower primitives: IDs, refs, fences, leases, checkpoints, and generic
persistence/projection helpers.

## Does Not Own

AI semantics, provider behavior, product logic, governance policy, execution
lane behavior, or workflow state machines.

## First Task

```bash
cd /home/home/p/g/n/ground_plane
mix ci
cd /home/home/p/g/n/stack_lab
mix gn_ten.plan --repo ground_plane
```

## Proofs

StackLab owns assembled proof. Use `/home/home/p/g/n/stack_lab/proof_matrix.yml`
and `/home/home/p/g/n/stack_lab/docs/gn_ten_proof_matrix.md`.

## Common Changes

For new primitives, add focused tests in the owning child package first, then run
repo `mix ci`. Promote only primitives that remain product-, provider-, and
mechanism-neutral.
