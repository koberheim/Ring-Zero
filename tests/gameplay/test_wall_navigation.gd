extends SceneTree
var checks := 0
var failures := 0
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _open(state: Dictionary, cell: Vector2i, horizon: int) -> bool:
	return cell.x >= 1 and cell.x <= horizon and cell.y >= 1 and cell.y <= 12 and (not state.rings.has(cell.x) or state.rings[cell.x].get("collapsed", false) or state.rings[cell.x].wedges[cell.y].hp == 0)
func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [cell + Vector2i(1, 0), cell - Vector2i(1, 0), Vector2i(cell.x, cell.y % 12 + 1), Vector2i(cell.x, (cell.y + 10) % 12 + 1)]
# Independent unweighted connectivity oracle; does not use route fields or grid.
func _reachable_goal_kind(state: Dictionary, source: Vector2i, horizon: int) -> StringName:
	if not _open(state, source, horizon): return &""
	var queue: Array[Vector2i] = [source]
	var seen := {source: true}
	var wall := false
	var exposed := false
	for cell in queue:
		if cell.x == 1: exposed = true
		elif state.rings.has(cell.x - 1):
			var inward: Dictionary = state.rings[cell.x - 1].wedges[cell.y]
			if inward.hp > 0:
				if inward.has("wall") and inward.wall.hp > 0: wall = true
				else: exposed = true
		for neighbor in _neighbors(cell):
			if _open(state, neighbor, horizon) and not seen.has(neighbor):
				seen[neighbor] = true
				queue.append(neighbor)
	return &"exposed" if exposed else (&"wall" if wall else &"")
func _compare(state: Dictionary, horizon: int) -> WallNavigation:
	var built := WallNavigation.build(state, horizon)
	_check(built.ok, "Graph builds")
	var nav: WallNavigation = built.navigation
	for ring in range(1, horizon + 1):
		for wedge in range(1, 13):
			var cell := Vector2i(ring, wedge)
			var expected := _reachable_goal_kind(state, cell, horizon)
			var route := nav.route_for(cell)
			_check(route.ok == (expected != &"") and (not route.ok or (route.target_kind == &"wall") == (expected == &"wall")), "Independent BFS component policy at %s" % cell)
			if route.ok:
				_check(_open(state, route.next_cell, horizon) and (route.next_cell == cell or route.next_cell in _neighbors(cell)), "Chosen edge is legal radial/angular open-cell edge")
				var cursor := cell
				var visited := {}
				while cursor != route.goal_cell and not visited.has(cursor):
					visited[cursor] = true
					cursor = nav.route_for(cursor).next_cell
				_check(cursor == route.goal_cell, "Chosen edges reach shared selected goal without cycle")
	return nav
func _wall(state: Dictionary, ring: int, wedge: int) -> void:
	state.rings[ring].wedges[wedge].wall = {"hp": 50.0, "max_hp": 50.0}
func _initialize() -> void:
	var profile: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	_check(not WallNavigation.build(state, 0).ok and not WallNavigation.build(state, 1).ok, "Insufficient horizon rejected")
	var nav := _compare(state, 3)
	for wedge in range(1, 13):
		var route := nav.route_for(Vector2i(2, wedge))
		_check(route.target_kind == &"wedge" and route.target_cell == Vector2i(1, wedge) and route.next_cell == Vector2i(2, wedge), "Open perimeter attacks exposed adjacent wedge")
	_check(nav._exposed.distance_for(Vector2i(3, 1)) == 96, "Physical radial edge cost96")
	# D-109: with no wall anywhere, Breacher's wall_route_for has nothing to
	# prefer and falls back to the ordinary route exactly.
	for wedge in range(1, 13):
		var cell := Vector2i(2, wedge)
		_check(nav.wall_route_for(cell) == nav.route_for(cell), "No wall anywhere: wall_route_for matches the ordinary route")
		# D-110: with no wall anywhere, ignoring walls changes nothing either.
		_check(nav.assembler_route_for(cell) == nav.route_for(cell), "No wall anywhere: assembler_route_for matches the ordinary route")
	for wedge in range(1, 13):
		if wedge != 12: _wall(state, 1, wedge)
	nav = _compare(state, 3)
	_check(nav.route_for(Vector2i(2, 1)).goal_cell == Vector2i(2, 12) and nav.route_for(Vector2i(2, 1)).target_kind == &"wedge", "One opening funnels around walls")
	_check(is_equal_approx(nav._exposed.distance_for(Vector2i(2, 1)), 192 * TAU / 12), "Physical angular arc cost at inner boundary radius")
	# D-109: an ordinary machine funnels around to the one exposed opening, but
	# Breacher's wall_route_for always prefers the nearest standing wall instead.
	var breacher_route := nav.wall_route_for(Vector2i(2, 1))
	_check(breacher_route.ok and breacher_route.target_kind == &"wall" and breacher_route.goal_cell == Vector2i(2, 1) and breacher_route.target_cell == Vector2i(1, 1), "An open detour exists, but wall_route_for still targets the immediately adjacent wall")
	# D-110: Assembler ignores the wall entirely and attacks the wedge behind
	# it directly, treating the walled wedge exactly like a bare one - it
	# never funnels away and never resolves to target_kind &"wall".
	var assembler_route := nav.assembler_route_for(Vector2i(2, 1))
	_check(assembler_route.ok and assembler_route.target_kind == &"wedge" and assembler_route.goal_cell == Vector2i(2, 1) and assembler_route.target_cell == Vector2i(1, 1), "A walled wedge is just as valid an ignore-walls target as a bare one")
	_wall(state, 1, 12)
	nav = _compare(state, 3)
	_check(nav.route_for(Vector2i(2, 1)).target_kind == &"wall", "Sealed perimeter permits wall fallback")
	_check(nav.assembler_route_for(Vector2i(2, 1)).target_kind == &"wedge", "Even fully sealed, Assembler still resolves to the wedge, never a wall")
	var invalid := nav.route_for(Vector2i(1, 1))
	_check(not invalid.ok and invalid.next_cell == Vector2i(-1, -1) and invalid.goal_cell == Vector2i(-1, -1) and invalid.target_kind == &"" and not invalid.errors.is_empty(), "Intact interior source fails with sentinel")
	_check(not nav.route_for(Vector2i(4, 1)).ok, "Outside horizon unreachable source fails")
	state.energy = 1000
	state = RingPurchaseRules.purchase_next_ring(state, profile, 4).state
	state.rings[2].wedges[7].hp = 0
	for wedge in range(1, 13):
		if wedge != 7: _wall(state, 2, wedge)
	nav = _compare(state, 4)
	_check(nav.route_for(Vector2i(3, 7)).target_kind == &"wall", "Mixed-ring sealed connected perimeter falls back with only11 outer walls")
	state.rings[1].wedges[7].hp = 0
	nav = _compare(state, 4)
	_check(nav.route_for(Vector2i(3, 1)).target_kind == &"core" and nav.route_for(Vector2i(3, 1)).target_cell == Vector2i.ZERO, "Reachable core takes precedence over any wall fallback")
	var cached := nav.route_for(Vector2i(3, 1))
	var reference := cached.duplicate(true)
	cached.ok = false
	cached.next_cell = Vector2i(99, 99)
	cached.goal_cell = Vector2i(98, 98)
	cached.target_kind = &"wall"
	cached.target_cell = Vector2i(97, 97)
	cached.errors.append("caller mutation")
	_check(nav.route_for(Vector2i(3, 1)) == reference, "Public route records and nested errors cannot corrupt cached route")
	cached = nav.route_for(Vector2i(3, 1))
	cached.clear()
	_check(nav.route_for(Vector2i(3, 1)) == reference, "Cleared caller result leaves cache intact")
	state.rings[1].wedges[7].hp = 100
	_check(nav.route_for(Vector2i(3, 1)) == reference and WallNavigation.build(state, 4).navigation.route_for(Vector2i(3, 1)).target_kind == &"wall", "New topology produces new cache while previous snapshot stays immutable")
	var bad_a := nav.route_for(Vector2i(99, 1))
	bad_a.errors.append("caller mutation")
	_check(nav.route_for(Vector2i(99, 1)).errors.size() == 1, "Invalid routes also return independent error containers")
	print("Wall navigation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

