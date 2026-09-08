# T-011 — Playable startup and build controls

**Owner:** Luna. **Start gate:** Astra accepts T-010. **Date:** 2026-09-06.
**Authority:** D-025 Option A; D-047 Option A; approved neutral placeholders, 1280x900 inspection view, current test startup and purchase rules.
Read this brief and T-010/T-008 contracts (API sections suffice), then only your owned files and existing grid_inspection.gd if reusing it. No full spec/root logs.

## Files and architecture

Own src/presentation/build_view.gd, scenes/build_view.tscn, tests/presentation/test_build_view.gd, docs/reviews/T-011.md, and PNGs under docs/reviews/artifacts/.
May change project.godot run/main_scene only to build_view.tscn. Keep existing grid inspector and its test intact. Adjacent .uid files allowed.
Prefer subclassing the existing grid inspector. It creates Camera2D, grid, cells, cell_polygons, status_label and neutral rendering; its input implementation is _input. Do not allow inherited input to click through Control panels.
No game rules in presentation: consume BalanceProfile, RingPurchaseRules, BuildingRules. No enemy spawning, damage simulation, walls, power, abilities, income cheats, or direct firing buttons. WeaponRules is automatic and tested independently; the later engine loop will call it when movement/spawning are approved.

Expose:
- @export var balance_path:String = "res://data/balance/testing.json"
- @export var ring_limit:int = 3
- var profile:BalanceProfile
- var state:Dictionary
- var build_mode:StringName = &"" (empty, flak, mass_driver, expand)
- var menu_open:bool = false
- var energy_label:Label
- var feedback_label:Label
- func refresh_view() -> void
- func choose_build(kind:StringName) -> void
- func set_menu_open(open:bool) -> void

Load the selected profile and create_default_testing_state once at startup. Fail visibly and disable purchases on invalid setup; do not substitute or mint fallback funds. At current data state has full ring1, Flak wedge12/slot0, relay wedge6/slot0, energy20. Grid displays up to ring_limit to support selecting future relay positions; owned and unowned rings must be distinguishable in neutral grayscale outlines/fills and selected-cell text.

## Approved presentation/input

Use built-in Godot controls, default font/theme, simple grayscale polygons/outlines/labels. No new art direction, effects, audio, or shader work.
Show persistent energy and selected ring/wedge/slot. Show buildings at BuildingRules.slot_position with short spec-derived labels (Flak, Mass Driver, Relay). Render occupied structures distinctly enough to inspect and avoid overlapping labels; no production sprites. Empty slot marks aid selection. The slot centers use polar coordinates; no duplicate placement math.

Use Weapons and Structure tabs and retain a disabled Terrain tab. Weapons offers Flak and Mass Driver with data-driven prices. Structure offers Ring Plate as the whole-ring expansion purchase with current quoted price and included relay. Do not expose independent relay buying. Deflector Wall's rules/edge model are still pending enemy-path work, so do not show an active nonfunctional wall action. This is an intermediate Phase 2 build view, not a completed slice catalogue.

Left click selects when no build mode is active. In a weapon mode, convert cursor through Camera2D and PolarGrid, map angular fraction via BuildingRules.slot_for_fraction, and call place_weapon. On success clear build mode and refresh; on failure retain mode, show a short understandable reason, and keep state unchanged. Do not implement paint-to-build. Right click cancels the active mode without spending.

Ring Plate mode asks the player to click a slot on the next ring for the included relay. Compute candidate slots from approved data, then call purchase_next_ring for full validation and transaction. Do not charge just for entering a mode or selecting a slot. Clear mode on success; show failed eligibility/affordability plainly. State is authoritative, not the visible unowned ring geometry.

Middle drag pans; wheel scales zoom by inverse 1.1 steps; no rotation. Left clicking on UI must never also select/place in the world. Cancelling, switching tabs, and menu actions must not spend. Block invalid button modes. Keep the existing inspector usable for ring12 verification; no new in-game inspection toggle needed.

Menu button opens a simple Resume panel and pauses the SceneTree. The menu/root UI must still process so Resume works. While open, block placement and world input; menus never permit paused building. Closing restores the prior running state. No new keyboard bindings or manual aiming actions; built-in control focus remains available.

Feedback is current state and plain labels only. Do not put internal task IDs or implementation/debug terminology in the player UI.

## Verification and done

Use actual input paths (Viewport.push_input) and button signals/events, not only direct method calls:
- Normal startup owns only ring1 with approved Flak/relay and 20 energy; no passive increase over frames.
- Selecting a slot then building one Flak spends 20 exactly once, clears mode, and marks occupancy.
- Occupied/invalid/unaffordable placement leaves state unchanged.
- Right cancel, UI clicks, menu open/Resume do not place through controls or spend; placement is blocked while paused.
- Pan/zoom then slot click selects the intended slot.
- For test-only snapshots, set enough funds and exercise a full ring2 purchase with a chosen relay slot; verify 12 wedges, energy deduction, included relay and occupied slot. This is fixture setup in the test, never a player-facing grant/cheat.
- For a fixture with a broken inward wedge, expansion fails without mutation.
- Profile error produces a safe visible disabled UI state.

Run Godot import, affected rule/data tests if integration reveals concerns, and focused presentation tests. Preserve phase1 inspector and run its existing presentation suite once to verify reuse did not break it. Do not repeat unrelated checks without cause.
Capture actual rendered 1280x900 startup, placed weapon, ring2 purchase, and menu PNGs after frames draw. Non-headless helpers must use Start-Process -WindowStyle Hidden. Use E:/Godot/Godot_v4.7.2-stable_win64.exe with process-local APPDATA/LOCALAPPDATA under .godot and local --log-file.
Report commands/counts/image paths and limits. No human usability or completed live-combat claim. Deliver for Astra review, then correct findings in your files.
