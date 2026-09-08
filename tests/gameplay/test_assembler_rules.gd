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
	# D-110 Option A: a fixed interval cadence, same scheduling shape as every elite.
	for example in [[0.0, 179.0, 1, 0], [0.0, 180.0, 1, 1], [180.0, 300.0, 2, 1], [300.0, 300.0, 3, 0], [0.0, 420.0, 1, 3]]:
		var arrivals := AssemblerRules.arrivals_between(profile, example[0], example[1])
		_check(arrivals.ok and arrivals.first_sequence == example[2] and arrivals.count == example[3] and arrivals.errors.is_empty(), "Exact schedule boundary")
	var total := 0
	var previous := 0.0
	for endpoint in [100.0, 179.0, 180.0, 180.1, 299.0, 300.0, 400.0, 600.0]:
		var part := AssemblerRules.arrivals_between(profile, previous, endpoint)
		_check(part.ok and part.first_sequence == total + 1, "Partition sequence continuity")
		total += part.count
		previous = endpoint
	_check(total == AssemblerRules.arrivals_between(profile, 0, 600).count, "Partition equals whole interval")
	var tolerance: BalanceProfile = profile.with_overrides({"assembler": {"first_arrival_seconds": 1.0, "interval_seconds": 1.0}}).profile
	_check(AssemblerRules.arrivals_between(tolerance, 0, 1.0 - 0.5e-12).count == 1, "Arrival tolerance includes tiny residual")
	_check(AssemblerRules.arrivals_between(tolerance, 0, 1.0 - 2e-12).count == 0, "Arrival tolerance is bounded")
	for interval in [[-1.0, 1.0], [2.0, 1.0], [0.0, INF], [NAN, 1.0], [0.0, 1e308]]:
		var bad := AssemblerRules.arrivals_between(profile, interval[0], interval[1])
		_check(not bad.ok and bad.count == 0 and bad.first_sequence == 0 and not bad.errors.is_empty(), "Invalid interval has no partial count")
	for invalid in [null, BalanceProfile.new()]:
		_check(not AssemblerRules.arrivals_between(invalid, 0, 180).ok, "Invalid schedule profile")
		_check(not AssemblerRules.spawn_descriptor(invalid, 1, 1).ok, "Invalid descriptor profile")
	_check(not AssemblerRules.spawn_descriptor(profile, 0, 1).ok and not AssemblerRules.spawn_descriptor(profile, 1, -1).ok, "Sequence/outer ring bounds")

	# D-110: a boss-scale stat variant (large, slow), plus an unspent growth
	# counter - its distinct identity (wall immunity, permanent per-kill
	# growth) is implemented in LiveSimulation/WallNavigation, not here.
	for sequence in range(1, 4):
		var result := AssemblerRules.spawn_descriptor(profile, sequence, 2)
		_check(result.ok and result.errors.is_empty(), "Assembler descriptor always succeeds")
		var spawn: Dictionary = result.spawn
		_check(spawn.size() == 8 and spawn.sequence == sequence and spawn.elapsed_seconds == 180.0 + (sequence - 1) * 120.0, "Exact descriptor schedule/shape")
		_check(spawn.kind == &"assembler" and spawn.growth_stacks == 0, "Kind tag and unspent growth counter present")
		var wedge := 12 if (sequence - 1) % 12 == 0 else (sequence - 1) % 12
		_check(spawn.position.ring == 5 and spawn.position.wedge == wedge and spawn.position.radial_fraction == 0.0 and spawn.position.angular_fraction == 0.5, "Spawns at the perimeter band like a standard machine, bearing cycles")
	var base: Dictionary = MachineSpawnRules.stats_at(profile, 180.0).stats
	var early: Dictionary = AssemblerRules.spawn_descriptor(profile, 1, 0).spawn
	_check(is_equal_approx(early.hp, base.hp * float(profile.value("assembler.hp_multiplier"))) and is_equal_approx(early.damage_per_second, base.damage_per_second * float(profile.value("assembler.damage_multiplier"))) and is_equal_approx(early.speed_ring_widths_per_second, base.speed_ring_widths_per_second * float(profile.value("assembler.speed_multiplier"))), "Multipliers apply to the same growing base stats as standard machines")
	var late: Dictionary = AssemblerRules.spawn_descriptor(profile, 2, 0).spawn
	_check(late.hp > early.hp, "Later Assemblers still inherit standard minute-based stat growth")

	var overflow: BalanceProfile = profile.with_overrides({"assembler": {"hp_multiplier": 1e308}}).profile
	_check(not AssemblerRules.spawn_descriptor(overflow, 1, 0).ok, "Nonfinite computed stats rejected")
	var zero_speed: BalanceProfile = profile.with_overrides({"assembler": {"speed_multiplier": 1e-300}, "pressure": {"speed_ring_widths_per_second": 1e-300}}).profile
	var tiny := AssemblerRules.spawn_descriptor(zero_speed, 1, 0)
	_check(tiny.ok or not tiny.errors.is_empty(), "Degenerate speed handled without a crash")

	print("Assembler rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
