# Installation

## Hex

After 0.1.0 is published, add the package to `mix.exs`:

```elixir
{:ground_plane_persistence_policy, "~> 0.1.0"}
```

## Release-candidate source

Before publication, consumers should use the program-owned clean-consumer
fixture or an explicit path/tarball override. Production package manifests
must use the Hex requirement and must not retain sibling-workspace paths or Git
fallbacks.

The package requires Elixir `~> 1.19` and has no runtime dependencies.
