# Ownership

`ground_plane_persistence_policy` owns pure persistence-profile data:
selection precedence, tiers, capture levels, store capabilities, partitions,
redaction rules, and bounded in-memory debug taps.

It does not own a database, Temporal runtime, object store, network service,
migration, product policy, provider integration, or workflow. Adapter and
higher-layer repositories own those behaviors and pass explicit capabilities
into this package.
