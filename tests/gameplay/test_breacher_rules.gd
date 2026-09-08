extends SceneTree

var checks := 0
var failures := 0

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var profile: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile
	# D-109: same scheduling shape as Tunneler/Foundry/Transfer/Sapper.
	for example in [[0.0, 54.0, 1, 0], [0.0, 55.0, 1, 1], [55.0, 85.0, 2, 1], [85.0, 85.0, 3, 0], [0.0, 145.0, 1, 4]]:
		var arrivals := BreacherRules.arrivals_between(profile, example[0], example[1])
		_check(arrivals.ok and arrivals.first_sequence == example[2] and arrivals.count == example[3] and arrivals.errors.is_empty(), "Exact schedule boundary")
	var total := 0
	var previous := 0.0
	for endpoint in [30.0, 54.0, 55.0, 55.1, 84.0, 85.0, 115.0, 175.0]:
		var part := BreacherRules.arrivals_between(profile, previous, endpoint)
		_check(part.ok and part.first_sequence == total + 1, "Partition sequence continuity")
		total += part.count
		previous = endpoint
	_check(total == BreacherRules.arrivals_between(profile, 0, 175).count, "Partition equals whole interval")
	var tolerance: BalanceProfile = profile.with_overrides({"breacher": {"first_arrival_seconds": 1.0, "arrival_interval_seconds": 1.0}}).profile
	_check(BreacherRules.arrivals_between(tolerance, 0, 1.0 - 0.5e-12).count == 1, "Arrival tolerance includes tiny residual")
	_check(BreacherRules.arrivals_between(tolerance, 0, 1.0 - 2e-12).count == 0, "Arrival tolerance is bounded")
	for interval in [[-1.0, 1.0], [2.0, 1.0], [0.0, INF], [NAN, 1.0], [0.0, 1e308]]:
		var bad := BreacherRules.arrivals_between(profile, interval[0], interval[1])
		_check(not bad.ok and bad.count == 0 and bad.first_sequence == 0 and not bad.errors.is_empty(), "Invalid interval has no partial count")
	for invalid in [null, BalanceProfile.new()]:
		_check(not BreacherRules.arrivals_between(invalid, 0, 55).ok, "Invalid schedule profile")
		_check(not BreacherRules.spawn_descriptor(invalid, 1, 1).ok, "Invalid descriptor profile")
	_check(not BreacherRules.spawn_descriptor(profile, 0, 1).ok and not BreacherRules.spawn_descriptor(profile, 1, -1).ok, "Sequence/outer ring bounds")

	# D-109: Breacher is otherwise a plain standard machine (no stat multipliers) -
	# its distinct behavior is entirely routing/wall-damage, implemented in
	# LiveSimulation/WallNavigation.
	for sequence in range(1, 6):
		var result := BreacherRules.spawn_descriptor(profile, sequence, 2)
		_check(result.ok and result.errors.is_empty(), "Breacher descriptor always succeeds")
		var spawn: Dictionary = result.spawn
		_check(spawn.size() == 7 and spawn.sequence == sequence and spawn.elapsed_seconds == 55.0 + (sequence - 1) * 30.0, "Exact descriptor schedule/shape")
		_check(spawn.kind == &"breacher", "Kind tag present")
		var wedge := 12 if (sequence - 1) % 12 == 0 else (sequence - 1) % 12
		_check(spawn.position.ring == 5 and spawn.position.wedge == wedge and spawn.position.radial_fraction == 0.0 and spawn.position.angular_fraction == 0.5, "Spawns at the perimeter band like a standard machine, bearing cycles")
	var base: Dictionary = MachineSpawnRules.stats_at(profile, 55.0).stats
	var early: Dictionary = BreacherRules.spawn_descriptor(profile, 1, 0).spawn
	_check(is_equal_approx(early.hp, base.hp) and is_equal_approx(early.damage_per_second, base.damage_per_second) and is_equal_approx(early.speed_ring_widths_per_second, base.speed_ring_widths_per_second), "No stat multipliers - identical to a standard machine's growing base stats")
	var late: Dictionary = BreacherRules.spawn_descriptor(profile, 3, 0).spawn
	_check(late.hp > early.hp, "Later Breachers still inherit standard minute-based stat growth")

	var overflow: BalanceProfile = profile.with_overrides({"pressure": {"spawn_offset_ring_widths": 1e308}}).profile
	_check(not BreacherRules.spawn_descriptor(overflow, 1, 0).ok, "Nonfinite computed spawn radius rejected")

	print("Breacher rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
