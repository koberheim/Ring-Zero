# Phase 1 foundation contract — T-002 / T-003

**Date:** 2026-09-06. **Owner:** Astra. **Implementation:** Sol.
**Authority:** Kevin approved D-004 and D-006–D-009 recommendations. This contract settles reversible names and data conventions only. D-005 and D-025 remain pending.

## Approved foundation

Godot 4.7.2 stable, verified locally as 4.7.2.stable.official.ed1daf0bf, executable E:/Godot/Godot_v4.7.2-stable_win64.exe. GDScript, compatibility renderer, Windows prototype, 60 physics updates/second. The 60 FPS goal and later 500/1,000-machine trials are provisional targets, not measured performance or an approved hard cap. Reference hardware is not yet named.

Core is ring 0, one separate future HP pool, no build slots. Three buildable rings are rings 1–3. Core radius and each band width are 96 world units. Circles are uncompressed for the inspection view. Wedge 12 is centered north, 3 east; clockwise angular ties select the clockwise wedge. No hard ring-count limit.

## Ownership and files

Sol may create only project.godot, .gitignore, src/core/polar_grid.gd, src/core/polar_position.gd, scenes/foundation.tscn, tests/core/test_polar_grid.gd, and docs/reviews/T-003.md. Necessary corrections within these paths are allowed. Do not edit the spec or root memory documents.

Luna later owns src/presentation/, scenes/grid_inspection.tscn, and any required switch of the main scene after review. These paths are reserved, not an assignment. No rendering, controls, game rules, HP values, build slots, spawning, or combat in T-003.

project.godot opens the empty Node2D scene scenes/foundation.tscn, uses gl_compatibility for desktop/mobile rendering method, and 60 physics ticks. An empty launchable scene verifies project setup without making unapproved visual or input choices. .gitignore ignores .godot/ and export output, never the source or generated Godot resource identifiers.

## Shared data

PolarPosition extends RefCounted. Public typed fields:
- ring: int, default 0.
- wedge: int, default 0.
- radial_fraction: float, default 0.0.
- angular_fraction: float, default 0.0.

Constructor signature: _init(p_ring: int = 0, p_wedge: int = 0, p_radial_fraction: float = 0.0, p_angular_fraction: float = 0.0).
Construction stores the supplied values; validation is explicit in PolarGrid. Do not silently clamp malformed positions.

For rings 1+, wedge is 1–12; radial_fraction is in [0,1) across that band's width; angular_fraction is in [0,1) clockwise across the wedge, starting 15 degrees counterclockwise of its center. For ring 0, wedge is the sentinel 0, radial_fraction spans core radius, and angular_fraction spans a full turn clockwise from north. At the exact origin, the canonical position is all zeros.

Cells use Vector2i(ring, wedge) as two integer identifiers, not Cartesian coordinates. Core identifier is Vector2i(0,0). Geometry returned in Vector2 is temporary display/input data, never authoritative gameplay position. Future building slot identifiers are separate from position and deferred to D-011.

## Grid API

PolarGrid extends RefCounted; constants WEDGE_COUNT = 12, CORE_RADIUS = 96.0, RING_WIDTH = 96.0.
Public read-only-in-practice property ring_count: int.
Constructor _init(p_ring_count: int = 3): configure the available outer bands; nonnegative integer, with 0 permitting core-only inspection. Reject negative counts with a clear diagnostic and use 0; never silently cap large valid counts.

Required signatures:
- is_valid_cell(cell: Vector2i) -> bool
- all_cells() -> Array[Vector2i]
- ring_bounds(ring: int) -> Vector2
- cell_center(cell: Vector2i) -> PolarPosition
- cell_neighbors(cell: Vector2i) -> Array[Vector2i]
- is_valid_position(position: PolarPosition) -> bool
- polar_to_world(position: PolarPosition) -> Vector2
- world_to_polar(point: Vector2) -> PolarPosition
- world_to_cell(point: Vector2) -> Vector2i

all_cells returns core first, then each ring ascending, wedges 1 through 12. ring_bounds returns inner/outer radii; core [0,96], ring 1 [96,192], ring 3 [288,384]. Invalid ring returns Vector2(-1,-1).

cell_center returns radial_fraction 0.5 and angular_fraction 0.5 for ordinary wedges; core returns the origin. Invalid cell returns null.

cell_neighbors is geometric adjacency only, not a pathing policy: ordinary cell order is counterclockwise wedge, clockwise wedge, inward, outward, omitting unavailable bands. Ring 1 inward is the single core. Core neighbors are all ring-1 wedges in ascending order, or empty with zero rings. Invalid cell returns empty. No diagonal neighbors.

is_valid_position rejects null, invalid cells, nonfinite fractions, and fractions outside [0,1). For core origin, require angular_fraction = 0 when radial_fraction = 0. polar_to_world assumes a valid position; invalid input emits a diagnostic and returns Vector2(INF,INF). It must never manufacture an owned cell from malformed data.

Godot world coordinates: positive x east, positive y south. For a band, radius = CORE_RADIUS + (ring - 1 + radial_fraction) * RING_WIDTH. Bearing in turns clockwise from north = (wedge mod 12)/12 - 1/24 + angular_fraction/12. World x = radius * sin(bearing), y = -radius * cos(bearing), with turns converted to radians. Core bearing is angular_fraction turns and radius is radial_fraction * CORE_RADIUS.

world_to_polar returns null for nonfinite points or any point at/outside the configured outer radius. Core includes radius 0 and excludes radius 96. Ring boundaries belong to the outward ring; the last outer boundary is outside. Angular boundaries belong clockwise, including wedge 12/1. Use a tiny documented numerical tolerance only to stabilize floating-point ties; test points on both sides beyond that tolerance. Return canonical fractions in [0,1). world_to_cell returns Vector2i(-1,-1) for outside/invalid input, otherwise identifiers from the conversion.

## Required checks

The headless test runner extends SceneTree, preloads implementation files, exits nonzero on failure, prints a concise summary, and does not require graphical output. Cover:
- 3-band enumeration = 37 cells; core-only = 1; 12-band = 145; a larger configuration such as 100 demonstrates no slice cap.
- North/east/south/west, both sides of wedge 12/1, exact 15-degree boundary clockwise, radial boundaries including outer exclusion, origin, and outside/nonfinite points.
- Core and band adjacency, wrapping, and bidirectional neighbor membership.
- Round trips of cell centers and noncenter fractional positions across all 12 bearings and several rings, including ring 12.
- Invalid identifiers/fractions return the specified results. Expected diagnostics must be identified as such; tests must not mistake an engine exception for a pass.

Validation commands (use workspace-local --log-file to avoid external log writes):
1. Godot --headless --path <repo> --log-file <repo>/.godot/import.log --editor --import
2. Godot --headless --path <repo> --log-file <repo>/.godot/grid-tests.log --script res://tests/core/test_polar_grid.gd
3. Godot --headless --path <repo> --log-file <repo>/.godot/launch.log --quit-after 2

## Done and review

Sol records actual commands, engine version, checks, and limitations in docs/reviews/T-003.md, then reports delivery for Astra review. Astra reads only the delivered files, verifies the contract and checks, and returns divergences to Sol. T-003 is not done until review passes. Luna remains blocked by D-025 and reviewed T-003; this task does not satisfy the visible-grid phase exit.
