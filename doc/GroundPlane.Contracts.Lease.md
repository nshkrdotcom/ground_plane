# `GroundPlane.Contracts.Lease`

Struct and validation helpers for lease records.

# `t`

```elixir
@type t() :: %GroundPlane.Contracts.Lease{
  epoch: non_neg_integer(),
  expires_at: DateTime.t(),
  holder: String.t(),
  lease_id: String.t(),
  resource: String.t()
}
```

# `expired?`

```elixir
@spec expired?(t(), DateTime.t()) :: boolean()
```

# `new`

```elixir
@spec new(map()) :: {:ok, t()} | {:error, term()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
