extends SceneTree
var checks := 0
var failures := 0
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _reject_unchanged(state: Dictionary, profile: BalanceProfile, ring: int, wedge: int, label: String) -> void:
	var before := var_to_bytes(state)
	var result := WallRules.place(state, profile, ring, wedge)
	_check(not result.ok and result.state == null and result.errors is PackedStringArray and not result.errors.is_empty(), label + " failure contract")
	_check(var_to_bytes(state) == before, label + " input preserved")
func _initialize() -> void:
	var profile: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile
	var profile_before := profile.snapshot()
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	var original := state.duplicate(true)
	_check(RingPurchaseRules.validate_state(state, profile).is_empty(), "Previous no-wall state still valid")
	_check(not WallRules.is_blocking(state, 1, 12) and not WallRules.is_blocking(state, 0, 12) and not WallRules.is_blocking(state, 1, 13) and not WallRules.is_blocking({}, 1, 1), "Missing wall/ring/wedge query false")
	for wedge in [12, 6]:
		var placed := WallRules.place(state, profile, 1, wedge)
		_check(placed.ok and placed.state.energy == 195 and placed.state.rings[1].wedges[wedge].wall == {"hp": 50.0, "max_hp": 50.0}, "Default data-driven outer-edge cost and HP on starter wedge %d" % wedge)
		_check(placed.state.rings[1].wedges[wedge].occupants == state.rings[1].wedges[wedge].occupants and placed.state.rings[1].wedges[wedge].slot_count == 2 and placed.state.rings[1].relay == state.rings[1].relay, "Wall preserves starter occupant normal slot and relay")
		_check(WallRules.is_blocking(placed.state, 1, wedge), "Positive wall on unbroken support blocks")
		_reject_unchanged(placed.state, profile, 1, wedge, "Duplicate wall")
		placed.state.rings[1].wedges[wedge].wall.hp = 1
		placed.state.rings[1].wedges[wedge].occupants.clear()
		_check(state == original and profile.snapshot() == profile_before, "Returned nested wall/occupants isolated from original and profile")
	state.energy = 1000
	state = RingPurchaseRules.purchase_next_ring(state, profile, 4).state
	var inner := WallRules.place(state, profile, 1, 1)
	var outer := WallRules.place(inner.state, profile, 2, 1)
	_check(inner.ok and outer.ok and outer.state.energy == state.energy - 10 and WallRules.is_blocking(outer.state, 1, 1) and WallRules.is_blocking(outer.state, 2, 1), "Inner and outer owned edges each cost once with no ring scaling")
	_check(outer.state.rings[2].wedges[1].occupants.is_empty() and outer.state.rings[2].wedges[1].slot_count == 4, "Empty normal slots remain empty and unchanged")
	var tuned: BalanceProfile = profile.with_overrides({"economy": {"wall_cost": 13}, "health": {"wall_hp": 72.5}}).profile
	var tuned_wall := WallRules.place(state, tuned, 2, 2)
	_check(tuned_wall.ok and tuned_wall.state.energy == state.energy - 13 and tuned_wall.state.rings[2].wedges[2].wall.hp == 72.5 and tuned_wall.state.rings[2].wedges[2].wall.max_hp == 72.5, "Tuned cost and fractional HP")
	var free: BalanceProfile = profile.with_overrides({"economy": {"wall_cost": 0}}).profile
	var poor := state.duplicate(true)
	poor.energy = 0
	var free_wall := WallRules.place(poor, free, 1, 1)
	_check(free_wall.ok and free_wall.state.energy == 0 and WallRules.is_blocking(free_wall.state, 1, 1), "Free wall override works at zero energy")
	_reject_unchanged(poor, profile, 1, 1, "Insufficient funds")
	for ids in [[0, 1], [-1, 1], [3, 1], [1, 0], [1, 13]]:
		_reject_unchanged(state, profile, ids[0], ids[1], "Invalid/unowned IDs")
	var damaged := state.duplicate(true)
	damaged.rings[1].wedges[1].hp = 1
	_check(WallRules.place(damaged, profile, 1, 1).ok, "Partially damaged unbroken support remains eligible")
	damaged.rings[1].wedges[1].hp = 0
	_reject_unchanged(damaged, profile, 1, 1, "Broken support")
	var inactive: Dictionary = outer.state.duplicate(true)
	inactive.rings[1].wedges[1].hp = 0
	_check(RingPurchaseRules.validate_state(inactive, profile).is_empty() and not WallRules.is_blocking(inactive, 1, 1) and inactive.rings[1].wedges[1].wall.hp == 50, "Broken support retains valid positive wall but disables blocking")
	var collapsed := state.duplicate(true)
	collapsed.rings[1].collapsed = true
	collapsed.rings[1].relay = {}
	collapsed.rings[1].erase("relay_hp")
	collapsed.rings[1].erase("relay_max_hp")
	for plate in collapsed.rings[1].wedges.values():
		plate.hp = 0
		plate.occupants = {}
	_check(RingPurchaseRules.validate_state(collapsed, profile).is_empty() and not WallRules.is_blocking(collapsed, 1, 1), "Wall-free tombstone still valid")
	_reject_unchanged(collapsed, profile, 1, 1, "Collapsed support")
	collapsed.rings[1].wedges[1].wall = {"hp": 50.0, "max_hp": 50.0}
	_check(not RingPurchaseRules.validate_state(collapsed, profile).is_empty() and not WallRules.is_blocking(collapsed, 1, 1), "Collapsed tombstone cannot retain wall")
	for wall in [null, [], 5, {}, {"hp": 1}, {"hp": 1, "max_hp": 1, "side": "outer"}, {"hp": true, "max_hp": 1}, {"hp": 1, "max_hp": false}, {"hp": "1", "max_hp": 1}, {"hp": 0, "max_hp": 1}, {"hp": -1, "max_hp": 1}, {"hp": 2, "max_hp": 1}, {"hp": 1, "max_hp": 0}, {"hp": 1, "max_hp": -1}, {"hp": INF, "max_hp": INF}, {"hp": 1, "max_hp": INF}, {"hp": NAN, "max_hp": 1}]:
		var malformed := state.duplicate(true)
		malformed.rings[1].wedges[1].wall = wall
		_check(not RingPurchaseRules.validate_state(malformed, profile).is_empty(), "Malformed wall rejected by shared validator")
		_reject_unchanged(malformed, profile, 2, 2, "Malformed wall elsewhere blocks transaction")
	var partial := state.duplicate(true)
	partial.rings[1].wedges[1].wall = {"hp": 1.25, "max_hp": 72.5}
	_check(RingPurchaseRules.validate_state(partial, profile).is_empty() and WallRules.is_blocking(partial, 1, 1), "Positive damaged wall valid and active")
	for invalid_profile in [null, BalanceProfile.new()]:
		_reject_unchanged(state, invalid_profile, 1, 1, "Invalid profile")
	var invalid_state := state.duplicate(true)
	invalid_state.rings[1].relay.slot = 1
	_reject_unchanged(invalid_state, profile, 1, 1, "Existing relay validation preserved")
	_check(profile.snapshot() == profile_before, "All wall transactions preserve source profile")
	print("Wall rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

