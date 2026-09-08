class_name WallNavigation
extends RefCounted

const INVALID := Vector2i(-1, -1)
var _open: Dictionary = {}
# Immutable-by-convention records bounded by the graph's cells.
var _routes: Dictionary = {}
var _exposed: PolarRouteField
var _walls: PolarRouteField
var _ignore_walls: PolarRouteField
var _shadow_speeds: Dictionary = {}
var has_shadows := false
var cell_count: int

static func build(state: Dictionary, outer_band: int, profile: BalanceProfile = null, transfer_boundary: int = 0) -> Dictionary:
	if outer_band < 1 or outer_band < state.rings.size() + 1:
		return {"ok": false, "navigation": null, "errors": PackedStringArray(["Navigation horizon must contain all historical rings and an outer band"])}
	if profile != null:
		var errors := RingPurchaseRules.validate_state(state, profile)
		if not errors.is_empty(): return {"ok": false, "navigation": null, "errors": errors}
	var directed := false
	var screens := false
	for record in state.rings.values():
		for plate in record.wedges.values():
			for occupant in plate.occupants.values():
				if occupant.kind in [&"tractor_lane", &"occlusion_screen"]:
					if profile == null: return {"ok": false, "navigation": null, "errors": PackedStringArray(["Terrain requires a balance profile"])}
					if plate.hp > 0 and not record.get("collapsed", false):
						directed = directed or occupant.kind == &"tractor_lane"
						screens = screens or occupant.kind == &"occlusion_screen"
	var navigation := WallNavigation.new()
	var cells: Array[Vector2i] = []
	var exposed_goals: Array[Vector2i] = []
	var wall_goals: Array[Vector2i] = []
	var ignore_wall_goals: Array[Vector2i] = []
	for ring in range(1, outer_band + 1):
		for wedge in range(1, PolarGrid.WEDGE_COUNT + 1):
			if ring != transfer_boundary and state.rings.has(ring) and not state.rings[ring].get("collapsed", false) and state.rings[ring].wedges[wedge].hp > 0:
				continue
			var cell := Vector2i(ring, wedge)
			navigation._open[cell] = true
			cells.append(cell)
			if ring == 1:
				exposed_goals.append(cell)
				ignore_wall_goals.append(cell)
			elif state.rings.has(ring - 1) and state.rings[ring - 1].wedges[wedge].hp > 0:
				if TerrainRules.is_debris_blocking(state, ring - 1, wedge): continue
				# D-110: Assembler ignores walls entirely - a walled wedge is just
				# as valid an ignore-walls target as a bare one, unlike _exposed/_walls.
				ignore_wall_goals.append(cell)
				if WallRules.is_blocking(state, ring - 1, wedge): wall_goals.append(cell)
				else: exposed_goals.append(cell)
	var grid := PolarGrid.new(outer_band)
	var edges: Array[Dictionary] = []
	for cell in cells:
		for neighbor in grid.cell_neighbors(cell):
			# A hopped Transfer owns only the inner boundary corridor, never an
			# outward crossing through its skipped ring's intact material.
			if transfer_boundary > 0 and mini(cell.x, neighbor.x) == transfer_boundary and cell.x != neighbor.x: continue
			if not navigation._open.has(neighbor) or (not directed and not _less(cell, neighbor)): continue
			var cost := float(PolarGrid.RING_WIDTH) if cell.x != neighbor.x else (PolarGrid.CORE_RADIUS + (cell.x - 1) * float(PolarGrid.RING_WIDTH)) * TAU / PolarGrid.WEDGE_COUNT
			if directed and cell.x == neighbor.x:
				var direction := TerrainRules.tractor_direction(state, cell.x - 1, cell.y)
				if direction != 0 and neighbor.y == (cell.y - 1 + direction + 12) % 12 + 1:
					cost *= float(profile.value("tractor_lane.path_cost_multiplier"))
			edges.append({"a": cell, "b": neighbor, "cost": cost})
	var exposed := PolarRouteField.build(grid, cells, edges, exposed_goals, directed)
	if not exposed.ok: return {"ok": false, "navigation": null, "errors": exposed.errors}
	var walls := PolarRouteField.build(grid, cells, edges, wall_goals, directed)
	if not walls.ok: return {"ok": false, "navigation": null, "errors": walls.errors}
	var ignore_walls := PolarRouteField.build(grid, cells, edges, ignore_wall_goals, directed)
	if not ignore_walls.ok: return {"ok": false, "navigation": null, "errors": ignore_walls.errors}
	navigation._exposed = exposed.field
	navigation._walls = walls.field
	navigation._ignore_walls = ignore_walls.field
	navigation.cell_count = cells.size()
	for cell in cells:
		navigation._routes[cell] = navigation._compute_route(cell)
		if screens:
			var multiplier := TerrainRules.surface_speed_multiplier(state, profile, PolarPosition.new(cell.x, cell.y, 0, 0.5))
			if multiplier < 1.0: navigation._shadow_speeds[cell] = multiplier
	navigation.has_shadows = not navigation._shadow_speeds.is_empty()
	return {"ok": true, "navigation": navigation, "errors": PackedStringArray()}

static func _less(a: Vector2i, b: Vector2i) -> bool:
	return a.x < b.x or (a.x == b.x and a.y < b.y)

func has_cell(cell: Vector2i) -> bool:
	return _open.has(cell)

func route_for(cell: Vector2i) -> Dictionary:
	if _routes.has(cell): return _routes[cell].duplicate(true)
	return _compute_route(cell)

## D-109: Breacher always prefers the nearest wall over any open detour, even
## when one exists - the exact opposite of every other machine's route_for,
## which only ever falls back to _walls when no exposed detour is reachable
## at all. Reuses the same precomputed _walls field (shortest path to the
## nearest wall goal, ignoring detour cost) unconditionally instead of only
## as a last resort. Falls back to the ordinary route when no wall is
## reachable anywhere (nothing to smash, so it behaves like a standard machine).
func wall_route_for(cell: Vector2i) -> Dictionary:
	if not _open.has(cell) or not is_finite(_walls.distance_for(cell)):
		return route_for(cell)
	var goal := _walls.goal_for(cell)
	return {"ok": true, "next_cell": _walls.next_cell(cell), "goal_cell": goal, "target_kind": &"wall", "target_cell": goal - Vector2i(1, 0), "errors": PackedStringArray()}

## D-110: Assembler "ignores walls" - a standing wall never blocks it or even
## registers as a distinct target; it treats any wedge behind a wall exactly
## like a bare one. Reuses a third precomputed field (goals are every open
## cell adjacent to an intact inward wedge, wall or not) so it never resolves
## to target_kind &"wall". Falls back to the ordinary route only if somehow
## nothing is reachable at all (matches route_for/wall_route_for's own guard).
func assembler_route_for(cell: Vector2i) -> Dictionary:
	if not _open.has(cell) or not is_finite(_ignore_walls.distance_for(cell)):
		return route_for(cell)
	var goal := _ignore_walls.goal_for(cell)
	var kind: StringName = &"core" if goal.x == 1 else &"wedge"
	return {"ok": true, "next_cell": _ignore_walls.next_cell(cell), "goal_cell": goal, "target_kind": kind, "target_cell": Vector2i.ZERO if kind == &"core" else goal - Vector2i(1, 0), "errors": PackedStringArray()}

func _compute_route(cell: Vector2i) -> Dictionary:
	var field := _exposed
	var wall := false
	if not is_finite(field.distance_for(cell)):
		field = _walls
		wall = true
	if not _open.has(cell) or not is_finite(field.distance_for(cell)):
		return {"ok": false, "next_cell": INVALID, "goal_cell": INVALID, "target_kind": &"", "target_cell": INVALID, "errors": PackedStringArray(["Source cell is nontraversable or has no reachable surface"])}
	var goal := field.goal_for(cell)
	var kind: StringName = &"wall" if wall else (&"core" if goal.x == 1 else &"wedge")
	return {"ok": true, "next_cell": field.next_cell(cell), "goal_cell": goal, "target_kind": kind, "target_cell": Vector2i.ZERO if kind == &"core" else goal - Vector2i(1, 0), "errors": PackedStringArray()}


func surface_speed(cell: Vector2i) -> float:
	return _shadow_speeds.get(cell, 1.0)
