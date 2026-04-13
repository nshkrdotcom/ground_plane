# `GroundPlane.Contracts.Checkpoint`

Shared checkpoint vocabulary for replay and projection positions.

# `t`

```elixir
@type t() :: %GroundPlane.Contracts.Checkpoint{
  position: non_neg_integer(),
  reason: String.t(),
  stream: String.t()
}
```

# `advance`

```elixir
@spec advance(t(), non_neg_integer(), String.t()) :: {:ok, t()} | {:error, term()}
```

# `new`

```elixir
@spec new(map()) :: {:ok, t()} | {:error, term()}
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
