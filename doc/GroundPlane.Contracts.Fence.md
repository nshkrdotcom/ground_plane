# `GroundPlane.Contracts.Fence`

Struct and comparison helpers for fenced ownership.

# `t`

```elixir
@type t() :: %GroundPlane.Contracts.Fence{
  epoch: non_neg_integer(),
  holder: String.t(),
  lease_id: String.t(),
  resource: String.t()
}
```

# `from_lease`

```elixir
@spec from_lease(GroundPlane.Contracts.Lease.t()) :: t()
```

# `newer_than?`

```elixir
@spec newer_than?(t(), t()) :: boolean()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
