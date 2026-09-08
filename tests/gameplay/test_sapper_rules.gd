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
	# D-108: same scheduling shape as Tunneler/Foundry/Transfer.
	for example in [[0.0, 64.0, 1, 0], [0.0, 65.0, 1, 1], [65.0, 100.0, 2, 1], [100.0, 100.0, 3, 0], [0.0, 170.0, 1, 4]]:
		var arrivals := SapperRules.arrivals_between(profile, example[0], example[1])
		_check(arrivals.ok and arrivals.first_sequence == example[2] and arrivals.count == example[3] and arrivals.errors.is_empty(), "Exact schedule boundary")
	var total := 0
	var previous := 0.0
	for endpoint in [35.0, 64.0, 65.0, 65.1, 99.0, 100.0, 135.0, 205.0]:
		var part := SapperRules.arrivals_between(profile, previous, endpoint)
		_check(part.ok and part.first_sequence == total + 1, "Partition sequence continuity")
		total += part.count
		previous = endpoint
	_check(total == SapperRules.arrivals_between(profile, 0, 205).count, "Partition equals whole interval")
	var tolerance: BalanceProfile = profile.with_overrides({"sapper": {"first_arrival_seconds": 1.0, "arrival_interval_seconds": 1.0}}).profile
	_check(SapperRules.arrivals_between(tolerance, 0, 1.0 - 0.5e-12).count == 1, "Arrival tolerance includes tiny residual")
	_check(SapperRules.arrivals_between(tolerance, 0, 1.0 - 2e-12).count == 0, "Arrival tolerance is bounded")
	for interval in [[-1.0, 1.0], [2.0, 1.0], [0.0, INF], [NAN, 1.0], [0.0, 1e308]]:
		var bad := SapperRules.arrivals_between(profile, interval[0], interval[1])
		_check(not bad.ok and bad.count == 0 and bad.first_sequence == 0 and not bad.errors.is_empty(), "Invalid interval has no partial count")
	for invalid in [null, BalanceProfile.new()]:
		_check(not SapperRules.arrivals_between(invalid, 0, 65).ok, "Invalid schedule profile")
		_check(not SapperRules.spawn_descriptor(invalid, 1, 1).ok, "Invalid descriptor profile")
	_check(not SapperRules.spawn_descriptor(profile, 0, 1).ok and not SapperRules.spawn_descriptor(profile, 1, -1).ok, "Sequence/outer ring bounds")

	# D-108: Sapper is otherwise a plain standard machine (no stat multipliers) -
	# its distinct behavior is entirely what its damage applies to, implemented
	# in LiveSimulation.
	for sequence in range(1, 6):
		var result := SapperRules.spawn_descriptor(profile, sequence, 2)
		_check(result.ok and result.errors.is_empty(), "Sapper descriptor always succeeds")
		var spawn: Dictionary = result.spawn
		_check(spawn.size() == 7 and spawn.sequence == sequence and spawn.elapsed_seconds == 65.0 + (sequence - 1) * 35.0, "Exact descriptor schedule/shape")
		_check(spawn.kind == &"sapper", "Kind tag present")
		var wedge := 12 if (sequence - 1) % 12 == 0 else (sequence - 1) % 12
		_check(spawn.position.ring == 5 and spawn.position.wedge == wedge and spawn.position.radial_fraction == 0.0 and spawn.position.angular_fraction == 0.5, "Spawns at the perimeter band like a standard machine, bearing cycles")
	var base: Dictionary = MachineSpawnRules.stats_at(profile, 65.0).stats
	var early: Dictionary = SapperRules.spawn_descriptor(profile, 1, 0).spawn
	_check(is_equal_approx(early.hp, base.hp) and is_equal_approx(early.damage_per_second, base.damage_per_second) and is_equal_approx(early.speed_ring_widths_per_second, base.speed_ring_widths_per_second), "No stat multipliers - identical to a standard machine's growing base stats")
	var late: Dictionary = SapperRules.spawn_descriptor(profile, 3, 0).spawn
	_check(late.hp > early.hp, "Later Sappers still inherit standard minute-based stat growth")

	var overflow: BalanceProfile = profile.with_overrides({"pressure": {"spawn_offset_ring_widths": 1e308}}).profile
	_check(not SapperRules.spawn_descriptor(overflow, 1, 0).ok, "Nonfinite computed spawn radius rejected")

	print("Sapper rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
