# GroundPlane Code Smell Remediation

This guide records the repo-local implementation posture after the GN-TEN code
smell remediation pass.

## What Changed

- Persistence policy contracts are split into smaller value and policy modules.
- Store capability constructors validate required fields and preserve explicit
  false values.
- Fence structs are decomposed so adaptive execution primitives stay small and
  ref-only.
- Epoch compatibility policy is documented as lower primitive policy, not
  higher workflow semantics.

## Maintainer Rules

- GroundPlane owns boring lower primitives only.
- It must not accumulate product, provider, connector, workflow, or authority
  semantics.
- Preserve exact boolean and nil semantics in constructors; do not use truthy
  fallback when `false` is meaningful.

## QC

Use the repo root gate:

```bash
mix ci
```
