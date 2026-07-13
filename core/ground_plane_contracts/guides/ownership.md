# Ownership

`ground_plane_contracts` owns universal, node-portable lower primitives: IDs,
opaque refs, leases, fences, checkpoints, boundary envelopes, and canonical
boundary encoding.

It does not own AI or provider semantics, product vocabulary, governance
policy, execution lane behavior, workflow state machines, storage services, or
projection runtimes. Consumers attach those higher meanings outside this
package.
