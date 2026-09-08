# T-046 — Directed route costs

Owner: Sol. Own src/core/polar_route_field.gd, tests/core/test_polar_route_field.gd and docs/reviews/T-046.md only. No delegation. Supports approved D-092 directional Tractor Lane preference; no terrain rules in core.

Extend build(grid: PolarGrid, cells: Array[Vector2i], edges: Array[Dictionary], goals: Array[Vector2i], directed: bool = false) -> Dictionary. Existing four-argument calls retain exact behavior. Edge shape remains a,b,cost. In directed mode an edge permits travel from a to b only. Reciprocal edges may have different positive costs; duplicate ordered edges fail. Undirected duplicate behavior remains unchanged. Retain finite positive costs, adjacent cells, deterministic goal/next-step ties, precision/overflow rejection and existing result methods.

Compute distance to goals using incoming edges in directed mode. A route must never traverse a missing reverse edge. Do not alter physical motion, pooling, gameplay or baseline recordings.

Done: focused tests for one-way reachability, reverse unreachability, reciprocal unequal costs, directed cycles, multiple goals/ties, duplicate rejection, and all legacy cases. Use pinned Godot 4.7.2, hidden bounded tracked processes and workspace caches. Coordinate the exclusive test window with Astra; no tests while Luna captures. Report changes, exact checks/logs and limitations, freeze source for review.
