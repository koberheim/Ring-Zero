# T-090 isolated preparation interface

Terra Stream E, 2026-09-09. Preparation lease at `c76a45c`. These helpers are not yet called by a shipping view. T-089/T-090/T-091 remain incomplete; native images/performance and human results are not inferred from logical tests.

`src/presentation/readability/swarm_lod.gd` exposes:

```gdscript
update_mode(world_to_physical: Transform2D) -> bool
project(targets: Array[Dictionary], world_points: PackedVector2Array,
        world_to_physical: Transform2D, visible_rect: Rect2,
        classes: Dictionary) -> Dictionary
canvas_world_size(metadata: Dictionary, world_to_physical: Transform2D) -> float
frame_for(metadata: Dictionary, seconds: float, reduced_motion: bool) -> int
frame_rect(metadata: Dictionary, frame: int) -> Rect2
bearing_for(world_point: Vector2) -> int
dominant_bearings(counts: PackedInt32Array) -> PackedInt32Array
```

`targets` is the actual living target snapshot, paired one-for-one with the existing authoritative world positions. HP <=0 and actual `burrowing` are excluded; no other lifecycle is invented. A conservative transformed canvas intersection retains partly offscreen actors. `visible_rect` and the transform are both in **physical root-window pixels**, including current viewport composition, camera tilt/zoom and any outer scale. D should expose that full transform and the usable map rectangle. Passing just `camera.zoom.x` is incorrect at scaled resolutions.

Result fields are `valid_transform:bool`, `mass_mode:bool`, `standards:PackedInt32Array` and `elites:PackedInt32Array` containing source indices, `bearing_counts` and `standard_bearings` (12 integer entries; index0=wedge1, index11=north12), `bins:Array[Dictionary]` and `batches:Array[Vector2i]`. Each bin has `cell:Vector2i`, world-space mean `position:Vector2`, exact integer `count`, and all twelve bearing counts. Ties are returned as all dominant bearings; an empty field has none. The projection stores no state/actor references and never moves actors.

Draw every standard using reusable bounded MultiMesh batches; batch descriptors `(start,count)` cover all returned standard indices. They are allocation granularity, not a capacity cap. At mass LOD use simple inward silhouettes plus a restrained density envelope from exact bins; close LOD keeps individual art/animation. Draw elites after all standards on a dedicated mapped-hardware canvas so standard overdraw cannot bury them. Do not move actor positions or artificially widen spacing. No per-actor shared material uniform writes. Bind F albedo/normal/emission to matching CanvasTexture regions and A's shared `moving_material()`, update core state once per canvas/frame. Standards require an explicit black emission map. F's normal green is flipped exactly once by A; do not decode normal/emission as sRGB.

Provisional versioned constants: enter mass at <=0.50 physical px/world-unit, leave at >=0.62; 48-world-unit fixed density bins (24 px at entry threshold); batches of at most256; standard base canvas15 world units and4 physical px floor. Bins stay anchored under pan and zoom. At most one bin exists per contributing actor, so empty world area allocates no bins. GPU batch buffers should grow to a high-water requirement and clear visible counts on empty/reset/teardown; do not reallocate on every varying actor count. There is no 800/1000 shipping promise or cap change.

F metadata's occupied fraction is the minimum longest alpha extent over all eight poses/twelve bearings. The helper uses the full transform's smallest singular value and a conservative sqrt(2) factor, guaranteeing the known occupied axis spans >=16px (elite) or >=28px (boss) even after additional rotation/shear. This may show a slightly larger form than the absolute minimum. The world footprint/collision stays untouched. Zero-size transforms are explicitly invalid. The formula and logical transform checks are not native measured silhouettes; E integration must measure actual alpha at1080/1440 and all bearings.

`test_t090_readability.gd` checks source immutability, exact1000-standard conservation, dead/burrowing/offscreen exclusions, all six elite families, dominant-bearing ties, batch coverage, pan-stable bins, LOD hysteresis, occupied-axis floors through zoom/tilt/outer-scale/rotation/shear, atlas phases, current power/HP status, and radar geometry. Runtime execution is coordinated with the Godot owner; see `preparation-test-results.md` when available.
