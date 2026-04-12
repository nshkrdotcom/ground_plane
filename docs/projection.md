# Projection

`ground_plane_projection` provides generic projection publication helpers.

The package owns:

- publication record building
- generic payload shaping
- adapter behavior for external sync surfaces

The package does not choose the primary sync product itself.
It stays adapter-shaped so higher repos can bind the chosen sync surface later
without hard-coding that decision into the lower shared layer.
