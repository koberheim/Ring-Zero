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
	# D-106: same scheduling shape as Tunneler (first_arrival_seconds/arrival_interval_seconds).
	for example in [[0.0, 89.0, 1, 0], [0.0, 90.0, 1, 1], [90.0, 135.0, 2, 1], [135.0, 135.0, 3, 0], [0.0, 225.0, 1, 4]]:
		var arrivals := FoundryRules.arrivals_between(profile, example[0], example[1])
		_check(arrivals.ok and arrivals.first_sequence == example[2] and arrivals.count == example[3] and arrivals.errors.is_empty(), "Exact schedule boundary")
	var total := 0
	var previous := 0.0
	for endpoint in [45.0, 89.0, 90.0, 90.1, 134.0, 135.0, 180.0, 267.0]:
		var part := FoundryRules.arrivals_between(profile, previous, endpoint)
		_check(part.ok and part.first_sequence == total + 1, "Partition sequence continuity")
		total += part.count
		previous = endpoint
	_check(total == FoundryRules.arrivals_between(profile, 0, 267).count, "Partition equals whole interval")
	var tolerance: BalanceProfile = profile.with_overrides({"foundry": {"first_arrival_seconds": 1.0, "arrival_interval_seconds": 1.0}}).profile
	_check(FoundryRules.arrivals_between(tolerance, 0, 1.0 - 0.5e-12).count == 1, "Arrival tolerance includes tiny residual")
	_check(FoundryRules.arrivals_between(tolerance, 0, 1.0 - 2e-12).count == 0, "Arrival tolerance is bounded")
	for interval in [[-1.0, 1.0], [2.0, 1.0], [0.0, INF], [NAN, 1.0], [0.0, 1e308]]:
		var bad := FoundryRules.arrivals_between(profile, interval[0], interval[1])
		_check(not bad.ok and bad.count == 0 and bad.first_sequence == 0 and not bad.errors.is_empty(), "Invalid interval has no partial count")
	for invalid in [null, BalanceProfile.new()]:
		_check(not FoundryRules.arrivals_between(invalid, 0, 90).ok, "Invalid schedule profile")
		_check(not FoundryRules.spawn_descriptor(invalid, 1, 1).ok, "Invalid descriptor profile")
	_check(not FoundryRules.spawn_descriptor(profile, 0, 1).ok and not FoundryRules.spawn_descriptor(profile, 1, -1).ok, "Sequence/outer ring bounds")

	# D-106: no burrow/eligibility phase — every due sequence is an ordinary
	# standard-machine descriptor, just tankier, harder-hitting, and slower.
	for sequence in range(1, 6):
		var result := FoundryRules.spawn_descriptor(profile, sequence, 2)
		_check(result.ok and result.errors.is_empty(), "Foundry descriptor always succeeds once due")
		var spawn: Dictionary = result.spawn
		_check(spawn.size() == 7 and spawn.sequence == sequence and spawn.elapsed_seconds == 90.0 + (sequence - 1) * 45.0, "Exact descriptor schedule/shape")
		_check(spawn.kind == &"foundry", "Kind tag present")
		var wedge := 12 if (sequence - 1) % 12 == 0 else (sequence - 1) % 12
		_check(spawn.position.ring == 5 and spawn.position.wedge == wedge and spawn.position.radial_fraction == 0.0 and spawn.position.angular_fraction == 0.5, "Spawns at the perimeter band like a standard machine, bearing cycles")
	var base: Dictionary = MachineSpawnRules.stats_at(profile, 90.0).stats
	var early: Dictionary = FoundryRules.spawn_descriptor(profile, 1, 0).spawn
	_check(is_equal_approx(early.hp, base.hp * 20.0) and is_equal_approx(early.damage_per_second, base.damage_per_second * 3.0) and is_equal_approx(early.speed_ring_widths_per_second, base.speed_ring_widths_per_second * 0.4), "Multipliers apply to the same growing base stats as standard machines")
	var late: Dictionary = FoundryRules.spawn_descriptor(profile, 3, 0).spawn
	_check(late.hp > early.hp, "Later Foundries inherit the same minute-based stat growth as standard machines")

	var overflow: BalanceProfile = profile.with_overrides({"foundry": {"hp_multiplier": 1e308}}).profile
	_check(not FoundryRules.spawn_descriptor(overflow, 1, 0).ok, "Nonfinite computed stats rejected")
	var zero_speed: BalanceProfile = profile.with_overrides({"foundry": {"speed_multiplier": 1e-300}, "pressure": {"speed_ring_widths_per_second": 1e-300}}).profile
	var tiny := FoundryRules.spawn_descriptor(zero_speed, 1, 0)
	_check(tiny.ok or not tiny.errors.is_empty(), "Degenerate speed handled without a crash")

	print("Foundry rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
