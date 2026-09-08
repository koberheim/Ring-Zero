# T-004 — Procedural grid inspection

**Owner:** Luna. **Coordinator/reviewer:** Astra. **Date:** 2026-09-06.
**Start gate:** T-003 must pass Astra review. This document is a prepared brief, not an assignment.
**Approved:** D-006/D-008 Option A and D-025 foundation controls. Core plus three bands, 96-unit core and widths, circular neutral placeholders, left select, middle drag pan, wheel zoom by 10%, north-up. No combat, build controls, collapse effects, final art, audio, or meta layer.

## Read only what you need

Read this brief and the foundation contract. Do not read the full design spec or root logs. Consume Sol's public API from that contract; do not edit or redesign the core. Report mismatches to Astra.

## Own these files

Create src/presentation/grid_inspection.gd, scenes/grid_inspection.tscn, tests/presentation/test_grid_inspection.gd, and docs/reviews/T-004.md. May change only run/main_scene and display/window settings in project.godot. May create review images under docs/reviews/artifacts/. Godot-generated .uid files alongside your scripts are allowed.

The main scene is Node2D with grid_inspection.gd. The script may construct its Camera2D, generated polygons/lines, and an unstyled CanvasLayer status Label. Use only built-in Godot drawing/text, neutral grayscale placeholders and default font/theme; do not select a production palette, shaders, decorations, or audio.

## Contract

Expose these for the verification scene:
- @export var ring_count: int = 3
- var grid: PolarGrid
- var selected_cell: Vector2i = Vector2i(-1,-1)
- var camera: Camera2D
- var status_label: Label
- func rebuild_grid(new_ring_count: int) -> void
- func select_at_world(point: Vector2) -> void

rebuild_grid replaces old generated geometry, constructs a new PolarGrid, resets selection, and fits the whole structure in the viewport. Core appears as a disk; each wedge is a generated annular polygon with visible boundaries. Generate from ring_bounds and polar conversion, not a duplicate coordinate formula. Endpoints at excluded cell boundaries may be constructed from the adjacent boundary radius/bearing for rendering only. Arc sampling is a rendering quality setting, never a new gameplay subdivision or ring limit.

Use ring_count=3 normally. Test ring_count=12 by scene property/rebuild_grid, not an extra in-game mode. No fixed ceiling on valid ring_count. Initialize camera at the core, rotation 0, with a view fit calculated from radius and viewport size. A 1280x900 initial window is a reversible inspection setting. Resize adjusts the canvas correctly; no automatic recenter during manual navigation.

The persistent status Label shows selected core or ring/wedge, or no selection. Place default-font clock-bearing labels around the outside if useful for orientation. Highlight the selected cell with a neutral outline. Core must remain selectable; clicking outside clears selection. All selection uses grid.world_to_cell on the camera-corrected world point.

Input:
- Left-button press selects the clicked world point once.
- Middle-button press begins drag; mouse motion pans by screen delta divided by current zoom; release stops drag. It must not rotate or select.
- Wheel up multiplies uniform camera zoom by 1.1; wheel down divides by 1.1. Keep the view center fixed. This makes one up/down pair reversible.
- Protect against zero/nonfinite zoom with numerical safeguards; do not impose a ring-count ceiling. Camera rotation remains 0.
- No new keyboard bindings, auto-follow, shake, build placement, or gameplay pause.

Display geometry uses world coordinates only as derived data. The authoritative selected identifiers and grid stay polar.

## Done checks and evidence

1. Import project with the pinned Godot executable and run foundation tests to check integration.
2. Run a meaningful presentation check in Godot: instantiate the scene, verify 3-band/12-band rebuilding without leftover geometry, core/bearing/outside selection, and selection after camera pan and zoom. Exercise InputEventMouseButton/InputEventMouseMotion through the actual input path. Verify wheel inverse pair, drag release, and rotation 0.
3. Capture actual rendered viewport images for three bands, twelve bands, and a panned/zoomed selected cell. Save PNGs under docs/reviews/artifacts/. Use an engine-rendered capture after frames have drawn; a headless server may not supply a texture. Any non-headless helper process must use Start-Process -WindowStyle Hidden. Do not open a visible window for this automated check.
4. Record exact checks, results, image paths, and limits in docs/reviews/T-004.md. Do not claim human readability approval.
5. Report delivery; Astra inspects source, check results, and PNGs. Fix review findings in your files when requested. Kevin's human readability review remains a Phase 1 exit condition.

Use E:/Godot/Godot_v4.7.2-stable_win64.exe, workspace-local logs under .godot/, and no package installation. Exit tests nonzero on failure. Report if rendering capture is unavailable instead of fabricating images.
