# T-087/T-088 preparation: native frame and screen composition

Stream D / Luna, 2026-09-09. Base `c76a45c`; A adapter `../T-081/adapter.md`, C audio handoff `../T-085/audio-interface-handoff.md`, D tokens `../T-086/full-theme-preparation.md`. B's early-collapse writer lease is active: this document changes no source/assets and launches no Godot. T-087 begins after B's reviewed adapter and full T-086 tokens; T-088 follows accepted layout. Named human checks remain pending.

## Layout choices

Use actual root dimensions as the stage dimensions, with `frame.scale=Vector2.ONE`, frame covering the window and shell sized/anchored to the stage. Preserve the isolated World3D and opaque stage from A. Keep a live world beneath HUD CanvasLayer1 and shell CanvasLayer100; neither layer enters glow. Apply anchors/containers to outer composition and retain useful VBox/Grid inner groups.

Breakpoints use the available width after density/text minimums, not fixed aspect-ratio labels: compact when width <1600*density or the normal arrangement's measured minimum widths cannot fit; normal otherwise; wide at aspect >=2.15 with enough measured room. At 130% scale a screen can move to compact without reducing text. Wide grants additional world space; telemetry/build/radar controls do not spread across all extra width.

Normal live layout reserves a top telemetry housing, left build dock, right status rail, and bottom selection/tutorial strip. Start/reset camera frames the one-ring fortress in the exact remaining map rectangle. Initial provisional native1080 reservations: outer margin24, gap16, telemetry92, dock360, status224, bottom strip80; dock/status grow to measured minimums with text scale. The radar remains its own truthful instrument supplied by E; no aggregation mechanic is invented. Collapsing the catalogue releases its dock width in the rectangle but never forcibly moves the user's camera.

```text
Normal — 1920×1080 / 2560×1440
+----------------------------------------------------------+
| Stored energy | Core integrity | Machines | Time | Menu   |
+------------+---------------------------------+-----------+
| Build      |                                 | Radar     |
| W/S/T tabs |      Usable map rectangle        | Truthful  |
| tool rows  |      centered at start/reset     | status    |
| (scroll)   |                                 | summaries |
| Solar      |                                 |           |
+------------+---------------------------------+-----------+
| Selected tool / cost / targeting instruction / tutorial  |
+----------------------------------------------------------+

Compact — 1280×720 or measured narrow layout at large text
+----------------------------------------------------------+
| Energy | Core | Time | Machines              Help | Menu  |
+-----------+----------------------------------------------+
| Build     |   Usable map                 compact radar   |
| tabs      |   (radar reserves a narrow right strip)       |
| scroll    |                                              |
| Solar     |                                              |
+-----------+----------------------------------------------+
| Selected tool / explanation (wrap; bounded scroll)        |
+----------------------------------------------------------+

Wide — 3440×1440
+-------------------------------------------------------------------+
| Telemetry sized to contents                                  Menu |
+-----------+---------------------------------------------+---------+
| Build     |           Additional usable world space      | Radar   |
| same      |                                             | Status  |
| readable  |         Star centered in actual free map     | same    |
| dock      |                                             | width   |
+-----------+---------------------------------------------+---------+
| Selection strip aligned to free map; no full-width prose            |
+-------------------------------------------------------------------+
```

Compact keeps core numeric telemetry, selected action and build access visible. Catalogue content scrolls in a fixed-height well; existing Tab visibility/hotkey behavior remains. If the build well is collapsed, its toggle remains reachable. Secondary status explanation can scroll inside the reserved rail; essential core/ring truth remains in the radar and HUD. No auto-hide based on gameplay pressure. Controls stay outside the map hit rectangle, with GUI filtering preventing click-through.

Start normal/wide: one aligned wordmark/copy lockup and live star/fortress hero on the left, operation well on the right, Start/Tutorial pinned under its scrollable choices. Secondary navigation wraps into rows below the hero; it is never six text-width buttons stretched across the full window. Compact: shorter hero band above choices, choices scroll while Start remains pinned. Generic pages use bounded content width with left-aligned headings; Settings switches from two columns to one at measured minimum width. Controls use device tabs then Camera / Weapons / Structure / Terrain / Abilities / System groups, with action label and actual remapped keycap as separate aligned columns.

```text
Start normal/wide                   Start compact
+------------------+-------------+  +--------------------------+
| Ring Zero        | Operation   |  | Ring Zero + living star   |
| Hold the star.   | doctrine    |  +--------------------------+
| Living star /    | loadout     |  | Operation choices scroll |
| fortress hero   | challenges  |  |                          |
| navigation wrap | Start  Help |  | Start run       Tutorial |
+------------------+-------------+  | navigation wraps         |
                                    +--------------------------+

Outcome (T-088 after accepted layout)
+----------------------------------+-------------------------+
| Captured actual peak fortress    | Outcome and saved reward|
|                                  | Key actual run measures|
| Actual radius history            | Breakdown (scroll)     |
+----------------------------------+-------------------------+
| Retry saving if needed / return action subject to save gate|
+------------------------------------------------------------+
```

T-088 outcome image/history are bounded read-only run presentation records, not reconstructed history from final state. No-data history explicitly says unavailable; practice/abandonment/defeat have honest headings and actual values. Display exactly one durable saved-reward total; keep breakdown, failure/retry and idempotency behavior. Capture the peak image only when an actual new peak is observed, bounded to one retained texture; keep radius samples bounded and tied to simulation time. Design/implementation details for truthful sampling are deferred to the actual T-088 lease, not fabricated in preparation.

## Source integration audit

| Location / current behavior | Required implementation action and preservation |
|---|---|
| `application._resize`: resets 2560×1440 stage, scales/letterboxes frame | Native stage/frame dimensions; size shell/backgrounds. Reflow current controls without recreating live simulation, page, focused widget or pending rebinding. Keep stage World3D and opaque background |
| `_new_page`, `_page_label`, `show_start`: absolute page/wordmark/nav positions | Outer Margin/Box/Grid structure with pinned footer and scrollable body. Stop drawing the old fixed `command_frame` home rule; application can omit that decoration, no new lease to its source needed |
| Settings: two fixed910px columns, 90px gap, audio values unnamed visually | Reflow columns, numeric slider values, five independent saved categories, visible save failure. Native resolution copy must describe current rendering truth |
| Controls: three fixed650px button columns | Device tabs retained, semantic groups with label/keycap grid. Preserve swapped mappings, reset rollback and actual physical-input capture |
| `live_view.apply_interface_settings` / `_industrial_layout`: hard-coded bays,540px dock, labels scattered | Stable HUD container roots, measured native tokens, grouped strip, no forced per-frame camera change. `instrument_strip` separators receive real bay boundaries or derive from children instead of fixed x422/832/1192/1602 |
| Live/build loops iterate category children directly | Keep button children discoverable; avoid silently wrapping each tab in a ScrollContainer that breaks `_compact_buttons`, `_compact_live_buttons`, availability updates and tooltip refresh. Prefer one external scrolling catalogue well around the TabContainer |
| `release_view.objective`: fixed offset/24px size | Compose with usable-map selection/objective anchor; preserve truthful 15-minute goal and draw lifecycle |
| Shipping `ThemeDB.fallback_font` calls in live/release | Replace drawing AND width measurement with shared Barlow roles. Release board override means prototype base `_draw_board` is not shipping drawing. Do not modify historical art-review typography/evidence |
| `camera_navigation`: width/2560 scales held-pan speed | Use a documented physical-pixel speed independent of ultrawide width, converted through actual canvas zoom. Preserve key release, focus-loss clear, pause and text-edit guards |
| `controller_pointer`: width/1440 speed + fixed offsets | Approved added lease: physical-pixel motion, current frame transform, resize clamp even while pointer hidden. Keep device -8 virtual mouse routing, remaps, trigger zoom and D-pad scrolling |
| A `_refresh_board_cache`: two cached raster surfaces | Keep paired size, canvas_transform, UPDATE_ONCE and shader raster uniforms synchronized. Resize invalidates once; palette/HP does not invalidate geometry. Preserve fully-covered pan fast path and 256px close-view margins unless separately measured |
| B event adapter (pending reviewed handoff) | Preserve event snapshot ordering, world-space effect parent and pause/reduced-motion lifecycle. Consume immutable facts; resize transforms presentation only |
| E status/LOD helpers (preparation in parallel) | Reserve layout inputs for truthful bearing/status projections. D positions radar and rail; E owns state interpretation. No theme-driven gameplay projection |
| `game_audio.apply_levels` / `PCSettings` | Approved added lease: independent UI/Ambience keys/mapping. Preserve input schema2 and legacy migration; absent keys inherit Effects/Music. B owns gameplay cue IDs; D owns screen/UI/music/pause integration at agreed boundaries |

## Proposed frozen D interface

Expose these methods on the shipping live view, with inputs/outputs in stage-native physical pixels unless marked world:

```gdscript
usable_map_rect() -> Rect2
# Excludes current dock, telemetry, radar/status and bottom selection reserves.
# It is not the full viewport and does not restrict user panning.

world_to_stage(world_point: Vector2) -> Vector2
stage_to_world(stage_point: Vector2) -> Vector2
# Both use the current full canvas transform, including projection/shake.
# Force camera scroll current before conversion; never duplicate zoom arithmetic.

frame_map(world_focus: Vector2 = Vector2.ZERO) -> void
# Explicit startup/reset/radar focus operation. Choose camera position so
# world_focus maps to usable_map_rect().get_center(). User pan otherwise stays free.

map_audio_pan(world_point: Vector2) -> float
# clamp(2*(world_to_stage(point).x-map.position.x)/map.size.x-1,-1,1)
# Returns 0 if rectangle is not valid. C applies its own audible +/-0.85 bound.
```

Application frame/root conversion uses `frame.get_global_transform_with_canvas()` and its inverse, not hard-coded 0.75. Return valid finite rectangles after layout; consumers should use a layout-changed signal/cache rather than recalculate minimum sizes per event. Camera framing updates explicit startup/reset focus, not `_process`. Resizing keeps the user's current world focus stable; layout changes may reproject that focus to the new map center once, preserving pan intent and selected cell. Tests decide the exact one-time resize behavior before freezing the interface.

## Verification work prepared

Before source mutation capture A+B frozen current start/settings/controls/pause/opening/six-ring/twelve-ring/tactical/victory/defeat at 1920×1080, 2560×1440, 3440×1440, 100%/130%; include all star palettes for world composition. Diagnostic world fixture must retain seed/tick/actor count/camera; no density retuning. Additional T-087 compatibility/layout sizes: 1280×720,1600×1000,3840×2160. Include saved115% in behavior checks. Record direct root/stage/cache sizes and compare native outputs, not resized mockups.

Actual input sequence: begin run, choose/place via pointer, hold/release WASD, wheel zoom, radar focus, controller pointer and A, cancel, pause, remap, resize repeatedly through all sizes with focus and pending tool retained, toggle130%, repeat picking/Alt, return from settings, teardown. Assert no unexpected simulation reset/tick/energy/reward change; build spends once at the intended slot and UI clicks spend zero. Frame-sequence evidence records actual event timing and screen positions.

Two existing test suites contain assertions of the superseded fixed stage contract: `test_application.gd` checks letterboxing/2560stage and 0.5frame scale at1280; `test_native_presentation.gd` checks fixed2560stage on resize. Replace only those assertions with required direct native size, isotropic transform, reachable controls, map framing and picking behavior under approved T-087. Preserve their gameplay and input assertions. This is an explicit approved behavior change, not silent test weakening. Existing `test_pc_navigation.gd` provides a stable mock-stage held movement/remap baseline; add size-invariance checks when speed scaling changes.

Run complete discovered suite count (current accepted44, retained minimum42) after each integrated D delivery. Then native lighting/cache readback, three paired1440p performance runs within A's documented limits, pan/Alt/pan+Alt. Retain failed samples and diagnose within latest steering; do not average away breaches. Native ultrawide/4K evidence establishes layout, not an unsupported frame-rate guarantee.

Preparation pass/fail: contracts and frozen A/C interfaces read PASS; actual construction/implicit widget inventory PASS; source integration risks and scope additions recorded PASS; source implementation/native proof PENDING reviewed B adapter and full D lease; human screen/readability acceptance PENDING T-093. No commits or planning-log edits by D.
