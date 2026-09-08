extends SceneTree

var checks := 0
var failures := 0

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _state(profile: BalanceProfile, count: int) -> Dictionary:
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	state.energy = 100000
	for ring in range(2, count + 1):
		var result := RingPurchaseRules.purchase_next_ring(state, profile, count)
		_check(result.ok, "Fixture ring purchase %d" % ring)
		state = result.state
	return state

func _position(position: PolarPosition, ring: int, wedge: int, radial: float) -> bool:
	return position.ring == ring and position.wedge == wedge and position.radial_fraction == radial and position.angular_fraction == 0.5

func _initialize() -> void:
	var profile: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile
	for example in [[0.0, 59.0, 1, 0], [0.0, 60.0, 1, 1], [60.0, 90.0, 2, 1], [90.0, 90.0, 3, 0], [0.0, 150.0, 1, 4]]:
		var arrivals := TunnelerRules.arrivals_between(profile, example[0], example[1])
		_check(arrivals.ok and arrivals.first_sequence == example[2] and arrivals.count == example[3] and arrivals.errors.is_empty(), "Exact schedule boundary")
	var total := 0
	var previous := 0.0
	for endpoint in [12.0, 59.0, 60.0, 60.1, 89.0, 90.0, 120.0, 177.0]:
		var part := TunnelerRules.arrivals_between(profile, previous, endpoint)
		_check(part.ok and part.first_sequence == total + 1, "Partition sequence continuity")
		total += part.count
		previous = endpoint
	_check(total == TunnelerRules.arrivals_between(profile, 0, 177).count, "Partition equals whole interval")
	var tolerance: BalanceProfile = profile.with_overrides({"tunneler": {"first_arrival_seconds": 1.0, "arrival_interval_seconds": 1.0}}).profile
	_check(TunnelerRules.arrivals_between(tolerance, 0, 1.0 - 0.5e-12).count == 1, "Arrival tolerance includes tiny residual")
	_check(TunnelerRules.arrivals_between(tolerance, 0, 1.0 - 2e-12).count == 0, "Arrival tolerance is bounded")
	for interval in [[-1.0, 1.0], [2.0, 1.0], [0.0, INF], [NAN, 1.0], [0.0, 1e308]]:
		var bad := TunnelerRules.arrivals_between(profile, interval[0], interval[1])
		_check(not bad.ok and bad.count == 0 and bad.first_sequence == 0 and not bad.errors.is_empty(), "Invalid interval has no partial count")
	for invalid in [null, BalanceProfile.new()]:
		_check(not TunnelerRules.arrivals_between(invalid, 0, 90).ok, "Invalid schedule profile")
		_check(not TunnelerRules.spawn_descriptor(invalid, {}, 1).ok, "Invalid descriptor profile")
	var one := _state(profile, 1)
	var skipped := TunnelerRules.spawn_descriptor(profile, one, 1)
	_check(skipped.ok and not skipped.eligible and skipped.spawn == null and skipped.errors.is_empty(), "Default one ring is ineligible")
	var two := _state(profile, 2)
	var pristine := var_to_bytes(two)
	for sequence in range(1, 26):
		var result := TunnelerRules.spawn_descriptor(profile, two, sequence)
		_check(result.ok and result.eligible and result.errors.is_empty(), "Two-ring eligible")
		var spawn: Dictionary = result.spawn
		var wedge := 12 if (sequence - 1) % 12 == 0 else (sequence - 1) % 12
		_check(spawn.size() == 14 and spawn.sequence == sequence and spawn.elapsed_seconds == 60.0 + (sequence - 1) * 30.0, "Exact descriptor schedule/shape")
		_check(spawn.kind == &"tunneler" and spawn.phase == &"burrowing" and not spawn.targetable, "Underground admission")
		_check(_position(spawn.position, 3, wedge, 0) and _position(spawn.start_position, 3, wedge, 0), "Independent perimeter positions")
		_check(_position(spawn.destination, 1, wedge, 0.5) and spawn.surface_cell == Vector2i(1, wedge), "Inner middle destination and bearing cycle")
		_check(spawn.burrow_elapsed_seconds == 0 and spawn.burrow_duration_seconds == 2, "Burrow duration")
		var growth := 1.0 + floorf(spawn.elapsed_seconds / 60.0) * 0.1
		_check(is_equal_approx(spawn.hp, 20.0 * growth) and is_equal_approx(spawn.damage_per_second, 5.0 * growth) and spawn.speed_ring_widths_per_second == 1.0, "Own HP and inherited additive stats")
	_check(var_to_bytes(two) == pristine, "Descriptors leave state unchanged")
	var locked: Dictionary = TunnelerRules.spawn_descriptor(profile, two, 1).spawn
	locked.position.ring = 99
	_check(locked.start_position.ring == 3 and locked.destination.ring == 1, "Position references are independent")
	two.rings[1].wedges[12].hp = 0
	_check(_position(locked.destination, 1, 12, 0.5), "Destination stays locked after structural change")
	_check(not TunnelerRules.spawn_descriptor(profile, two, 1).eligible, "Missing inner skips")
	_check(TunnelerRules.spawn_descriptor(profile, two, 2).spawn.position.wedge == 1, "Skipped bearing does not defer next sequence")
	var three := _state(profile, 3)
	_check(TunnelerRules.spawn_descriptor(profile, three, 1).spawn.surface_cell == Vector2i(2, 12), "Three rings bypass exactly one intact wedge")
	three.rings[2].wedges[12].hp = 0
	_check(TunnelerRules.spawn_descriptor(profile, three, 1).spawn.surface_cell == Vector2i(1, 12), "Broken gap does not count")
	three.rings[2].collapsed = true
	three.rings[2].relay = {}
	three.rings[2].erase("relay_hp")
	three.rings[2].erase("relay_max_hp")
	for wedge in range(1, 13):
		three.rings[2].wedges[wedge].hp = 0
		three.rings[2].wedges[wedge].occupants = {}
	_check(TunnelerRules.spawn_descriptor(profile, three, 1).spawn.surface_cell == Vector2i(1, 12), "Collapsed gap does not count")
	three.rings[3].wedges[12].hp = 0
	_check(not TunnelerRules.spawn_descriptor(profile, three, 1).eligible, "Only one surviving wedge skips")
	for sequence in [0, -1]:
		var invalid := TunnelerRules.spawn_descriptor(profile, one, sequence)
		_check(not invalid.ok and not invalid.eligible and invalid.spawn == null and not invalid.errors.is_empty(), "Invalid sequence")
	_check(not TunnelerRules.spawn_descriptor(profile, {}, 1).ok, "Invalid state")
	var tuned: BalanceProfile = profile.with_overrides({"health": {"tunneler_hp": 7.5}, "tunneler": {"first_arrival_seconds": 10.0, "arrival_interval_seconds": 5.0, "burrow_seconds": 0.75}, "pressure": {"speed_ring_widths_per_second": 2.5, "stat_increase_per_minute": 0.2}, "standard_machine": {"damage_per_second": 9.0}}).profile
	var tuned_spawn: Dictionary = TunnelerRules.spawn_descriptor(tuned, _state(tuned, 2), 11).spawn
	_check(tuned_spawn.elapsed_seconds == 60 and is_equal_approx(tuned_spawn.hp, 9) and is_equal_approx(tuned_spawn.damage_per_second, 10.8) and tuned_spawn.speed_ring_widths_per_second == 2.5 and tuned_spawn.burrow_duration_seconds == 0.75, "Complete override package")
	var huge: BalanceProfile = profile.with_overrides({"tunneler": {"arrival_interval_seconds": 1e308}}).profile
	_check(not TunnelerRules.spawn_descriptor(huge, one, 3).ok, "Due overflow rejected even when ineligible")
	var hp_overflow: BalanceProfile = profile.with_overrides({"health": {"tunneler_hp": 1e308}}).profile
	_check(not TunnelerRules.spawn_descriptor(hp_overflow, one, 100).ok, "Own HP overflow rejected")
	var tiny: BalanceProfile = profile.with_overrides({"tunneler": {"arrival_interval_seconds": 1e-308}}).profile
	var early: BalanceProfile = profile.with_overrides({"tunneler": {"first_arrival_seconds": 1e-15}}).profile
	_check(TunnelerRules.arrivals_between(early, 0, 0).count == 0, "Time zero precedes every positive first arrival")
	_check(TunnelerRules.arrivals_between(early, 0, 1e-15).count == 1, "Tiny positive first arrival remains sequence one")
	_check(TunnelerRules.arrivals_between(tiny, 0, 1).count == 0, "Before first arrival handles negative overflow")
	_check(not TunnelerRules.arrivals_between(tiny, 0, 61).ok, "Count overflow rejected")
	print("Tunneler rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
