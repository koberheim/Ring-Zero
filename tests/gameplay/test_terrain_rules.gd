extends SceneTree
var checks := 0
var failures := 0
var profile: BalanceProfile
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _state(rings: int = 2) -> Dictionary:
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	state.energy = 100000
	for ring in range(2, rings + 1): state = RingPurchaseRules.purchase_next_ring(state, profile, 12).state
	return state
func _initialize() -> void:
	profile = BalanceProfile.load_json("res://data/balance/testing.json").profile
	var state := _state()
	var before := state.duplicate(true)
	var placed := TerrainRules.place(state, profile, 2, 1, 0, &"tractor_lane", -1)
	_check(placed.ok and placed.state.energy == state.energy - 25 and TerrainRules.tractor_direction(placed.state, 2, 1) == -1 and state == before, "Pure slot-occupying terrain placement costs energy and isolates input")
	_check(PowerRules.ring_demand(placed.state, profile, 2) == PowerRules.ring_demand(state, profile, 2), "Terrain has no power demand")
	_check(not TerrainRules.place(placed.state, profile, 2, 1, 1, &"tractor_lane", 1).ok, "One lane per wedge")
	_check(not TerrainRules.place(state, profile, 2, 1, 0, &"tractor_lane", 0).ok, "Invalid direction rejected")
	_check(not TerrainRules.place(placed.state, profile, 2, 1, 0, &"debris_field").ok and not TerrainRules.place(state, profile, 2, 1, 4, &"debris_field").ok, "Occupied/out-of-bounds slots rejected")
	var poor := state.duplicate(true)
	poor.energy = 0
	_check(not TerrainRules.place(poor, profile, 2, 1, 0, &"debris_field").ok, "Insufficient funds rejected")
	_check(not TerrainRules.place(state, profile, 2, 1, 0, &"unknown").ok, "Unknown terrain rejected")
	for direction in [true, 0, 2, "1"]:
		var malformed: Dictionary = placed.state.duplicate(true)
		malformed.rings[2].wedges[1].occupants[0].direction = direction
		_check(not RingPurchaseRules.validate_state(malformed, profile).is_empty(), "Strict lane direction validation")
	var duplicate: Dictionary = placed.state.duplicate(true)
	duplicate.rings[2].wedges[1].occupants[1] = {"kind": &"tractor_lane", "direction": 1}
	_check(not RingPurchaseRules.validate_state(duplicate, profile).is_empty(), "Duplicate lanes rejected by state validator")
	_check(not WallNavigation.build(placed.state, 3).ok, "Numeric terrain rejects null profile")
	_check(WallNavigation.build(state, 3).ok, "Terrain-free null-profile compatibility")
	var debris := TerrainRules.place(state, profile, 2, 1, 0, &"debris_field")
	debris.state.rings[2].wedges[1].wall = {"hp": 50.0, "max_hp": 50.0}
	var nav: WallNavigation = WallNavigation.build(debris.state, 3, profile).navigation
	_check(nav.route_for(Vector2i(3, 1)).target_cell != Vector2i(2, 1), "Debris masks exposed surface and wall behind it")
	_check(WallNavigation.build(debris.state, 3).ok, "Debris-only navigation needs no numeric profile")
	var sealed := _state()
	for wedge in range(1, 12):
		var result := TerrainRules.place(sealed, profile, 2, wedge, 1, &"debris_field")
		_check(result.ok, "Partial debris perimeter remains eligible")
		sealed = result.state
	sealed.rings[2].wedges[12].wall = {"hp": 50.0, "max_hp": 50.0}
	nav = WallNavigation.build(sealed, 3, profile).navigation
	_check(nav.route_for(Vector2i(3, 1)).target_kind == &"wall" and nav.route_for(Vector2i(3, 1)).target_cell == Vector2i(2, 12), "Mixed debris/wall perimeter retains reachable destructible fallback")
	before = sealed.duplicate(true)
	_check(not TerrainRules.place(sealed, profile, 2, 12, 1, &"debris_field").ok and sealed == before, "Empty-map full debris seal rejected atomically")
	sealed.rings[2].wedges[12].occupants[1] = {"kind": &"debris_field"}
	sealed.rings[2].wedges[12].hp = 0
	before = sealed.duplicate(true)
	_check(not RingPurchaseRules.quote_repair_wedge(sealed, profile, 2, 12).ok and not RingPurchaseRules.repair_wedge(sealed, profile, 2, 12).ok and sealed == before, "Pure quote and repair reject reactivated full debris seal without mutation")
	_direction_checks()
	_shadow_checks()
	print("Terrain rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func _direction_checks() -> void:
	var state := _state(1)
	for wedge in range(1, 13):
		if wedge not in [2, 12]: state.rings[1].wedges[wedge].wall = {"hp": 50.0, "max_hp": 50.0}
	for direction in [-1, 1]:
		var placed := TerrainRules.place(state, profile, 1, 1, 0, &"tractor_lane", direction)
		var nav: WallNavigation = WallNavigation.build(placed.state, 2, profile).navigation
		var route := nav.route_for(Vector2i(2, 1))
		_check(route.target_kind == &"wedge" and route.next_cell == Vector2i(2, 12 if direction == -1 else 2), "Directed detour follows configured clockwise/counterclockwise preference and wrap")
		_check(is_equal_approx(nav._exposed.distance_for(Vector2i(2, 1)), 192.0 * TAU / 12.0 * 0.5), "Only selected outgoing angular arc receives route-cost discount")
		_check(nav.route_for(Vector2i(2, 2)).next_cell == Vector2i(2, 2), "Exposed goal attacks immediately despite steering nearby")
	var blocked := _state(2)
	blocked.rings[2].wedges[1].hp = 0
	blocked.rings[2].wedges[2].hp = 0
	blocked.rings[1].wedges[1].wall = {"hp": 50.0, "max_hp": 50.0}
	blocked = TerrainRules.place(blocked, profile, 1, 1, 0, &"tractor_lane", -1).state
	var nav: WallNavigation = WallNavigation.build(blocked, 3, profile).navigation
	_check(nav.route_for(Vector2i(2, 1)).next_cell == Vector2i(2, 2) and nav.route_for(Vector2i(2, 1)).target_kind == &"wedge", "Blocked preferred direction keeps legal opposite route and exposed-before-wall priority")
func _shadow_checks() -> void:
	var state := _state(3)
	state = TerrainRules.place(state, profile, 1, 1, 0, &"occlusion_screen").state
	for ring in range(1, 7):
		_check(TerrainRules.surface_speed_multiplier(state, profile, PolarPosition.new(ring, 1, 0, 0.5)) == (0.5 if ring in [2, 3, 4] else 1.0), "Exact outward shadow bands")
	_check(TerrainRules.surface_speed_multiplier(state, profile, PolarPosition.new(2, 2, 0, 0.5)) == 1.0, "Shadow excludes adjacent wedge")
	state = TerrainRules.place(state, profile, 2, 1, 0, &"occlusion_screen").state
	state = TerrainRules.place(state, profile, 2, 1, 1, &"occlusion_screen").state
	_check(TerrainRules.surface_speed_multiplier(state, profile, PolarPosition.new(3, 1, 0, 0.5)) == 0.5, "Overlapping identical screens use strongest once")
	state.rings[1].wedges[1].hp = 0
	_check(TerrainRules.surface_speed_multiplier(state, profile, PolarPosition.new(2, 1, 0, 0.5)) == 1.0, "Broken support disables retained screen")
	state = RingPurchaseRules.repair_wedge(state, profile, 1, 1).state
	_check(TerrainRules.surface_speed_multiplier(state, profile, PolarPosition.new(2, 1, 0, 0.5)) == 0.5, "Repair reactivates retained screen")
	var disabled := _state()
	disabled = TerrainRules.place(disabled, profile, 2, 1, 0, &"debris_field").state
	disabled = TerrainRules.place(disabled, profile, 2, 1, 1, &"tractor_lane", 1).state
	disabled.rings[2].wedges[1].hp = 0
	_check(not TerrainRules.is_debris_blocking(disabled, 2, 1) and TerrainRules.tractor_direction(disabled, 2, 1) == 0, "Broken support disables debris and lane without removing occupants")
