extends SceneTree
var checks := 0
var failures := 0
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
## D-033 testing tuning: pressure.spawn_delay_seconds holds off the first
## normal-machine arrival to give the player a preliminary build window.
func _spawn_delay_checks(zero_delay_profile: BalanceProfile) -> void:
	var delayed: BalanceProfile = zero_delay_profile.with_overrides({"pressure": {"spawn_delay_seconds": 10.0, "spawn_per_second": 2.0}}).profile
	_check(MachineSpawnRules.arrivals_between(delayed, 0, 10).count == 0, "No arrivals due before the delay elapses")
	_check(MachineSpawnRules.arrivals_between(delayed, 0, 10.5).count == 1, "First arrival is due exactly delay + 1/rate seconds in")
	var first := MachineSpawnRules.arrivals_between(delayed, 0, 10.5)
	var spawn := MachineSpawnRules.spawn_descriptor(delayed, first.first_sequence, 1)
	_check(spawn.ok and is_equal_approx(spawn.spawn.elapsed_seconds, 10.5), "Descriptor elapsed_seconds accounts for the delay, not just the rate")
	var undelayed: BalanceProfile = zero_delay_profile.with_overrides({"pressure": {"spawn_per_second": 2.0}}).profile
	_check(MachineSpawnRules.arrivals_between(undelayed, 0, 10).count == 20, "Zero delay reproduces the plain rate schedule")

func _initialize() -> void:
	# D-033 testing tuning added pressure.spawn_delay_seconds (2026-09-07) as a
	# gameplay-only preliminary-build window; this suite exercises the raw
	# scheduling math itself, so it zeroes the delay here and verifies the
	# delay mechanism separately in _spawn_delay_checks.
	var profile: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile.with_overrides({"pressure": {"spawn_delay_seconds": 0}}).profile
	var baseline := profile.snapshot()
	for sample in [[0.0, 10.0, 5.0], [59.999999, 10.0, 5.0], [60.0, 11.0, 5.5], [119.999999, 11.0, 5.5], [120.0, 12.0, 6.0], [600.0, 20.0, 10.0]]:
		var result := MachineSpawnRules.stats_at(profile, sample[0])
		_check(result.ok and is_equal_approx(result.stats.hp, sample[1]) and is_equal_approx(result.stats.damage_per_second, sample[2]) and result.stats.speed_ring_widths_per_second == 1, "Minute-step additive stats at %s" % sample[0])
	var tuned: BalanceProfile = profile.with_overrides({"health": {"standard_machine_hp": 7.5}, "standard_machine": {"damage_per_second": 2.5}, "pressure": {"stat_increase_per_minute": 0.25, "speed_ring_widths_per_second": 1.75}}).profile
	var tuned_stats := MachineSpawnRules.stats_at(tuned, 120)
	_check(tuned_stats.ok and tuned_stats.stats == {"hp": 11.25, "damage_per_second": 3.75, "speed_ring_widths_per_second": 1.75}, "Tuned original-base additive stats remain fractional")
	var flat: BalanceProfile = profile.with_overrides({"pressure": {"stat_increase_per_minute": 0}}).profile
	_check(MachineSpawnRules.stats_at(flat, 1e100).stats.hp == 10, "Zero escalation preserves base stats")
	var prior := MachineSpawnRules.stats_at(profile, 0)
	MachineSpawnRules.stats_at(profile, 120)
	_check(prior.stats.hp == 10 and prior.stats.damage_per_second == 5 and profile.snapshot() == baseline, "Later stats leave earlier spawn stats and profile unchanged")
	for invalid in [-1.0, INF, NAN]:
		var result := MachineSpawnRules.stats_at(profile, invalid)
		_check(not result.ok and result.stats == null and not result.errors.is_empty(), "Invalid elapsed stats failure shape")
	for invalid_profile in [null, BalanceProfile.new()]:
		_check(not MachineSpawnRules.stats_at(invalid_profile, 0).ok and not MachineSpawnRules.arrivals_between(invalid_profile, 0, 1).ok and not MachineSpawnRules.spawn_descriptor(invalid_profile, 1, 1).ok, "Invalid profiles safe across API")
	var overflowing: BalanceProfile = profile.with_overrides({"pressure": {"stat_increase_per_minute": 1e308}}).profile
	_check(not MachineSpawnRules.stats_at(overflowing, 120).ok, "Computed stat overflow rejected")
	for sample in [[0.0, 0.0, 1, 0], [0.0, 0.499999, 1, 0], [0.0, 0.5, 1, 1], [0.5, 0.5, 2, 0], [0.5, 1.0, 2, 1], [0.0, 1.0, 1, 2], [1.0, 2.25, 3, 2]]:
		var result := MachineSpawnRules.arrivals_between(profile, sample[0], sample[1])
		_check(result.ok and result.first_sequence == sample[2] and result.count == sample[3], "Independent half-second schedule interval %s..%s" % [sample[0], sample[1]])
	var time := 0.0
	var seen: Array[int] = []
	for tick in range(1, 61):
		var end := time + 1.0 / 60.0
		var result := MachineSpawnRules.arrivals_between(profile, time, end)
		_check(result.ok and result.count == (1 if tick in [30, 60] else 0), "60Hz scheduled arrival tick %d" % tick)
		for arrival in range(result.count): seen.append(result.first_sequence + arrival)
		time = end
	_check(seen == [1, 2], "Repeated 60Hz additions neither lose nor duplicate arrivals")
	var sum := 0
	var previous := 0.0
	for endpoint in [0.1, 0.49, 0.5, 1.75, 4.0, 9.9, 10.0]:
		var result := MachineSpawnRules.arrivals_between(profile, previous, endpoint)
		sum += result.count
		previous = endpoint
	_check(sum == 20 and sum == MachineSpawnRules.arrivals_between(profile, 0, 10).count, "Irregular partitions equal whole interval")
	var zero: BalanceProfile = profile.with_overrides({"pressure": {"spawn_per_second": 0}}).profile
	var none := MachineSpawnRules.arrivals_between(zero, 0, 1e300)
	_check(none.ok and none.first_sequence == 0 and none.count == 0 and not MachineSpawnRules.spawn_descriptor(zero, 1, 1).ok, "Zero rate returns no schedule and rejects descriptors")
	var slow: BalanceProfile = profile.with_overrides({"pressure": {"spawn_per_second": 0.25}}).profile
	_check(MachineSpawnRules.arrivals_between(slow, 0, 12).count == 3 and MachineSpawnRules.spawn_descriptor(slow, 1, 0).spawn.elapsed_seconds == 4, "Tuned rate schedule")
	for interval in [[-1.0, 0.0], [1.0, 0.0], [0.0, INF], [NAN, 1.0], [0.0, 1e300], [1e300, 1e300]]:
		var result := MachineSpawnRules.arrivals_between(profile, interval[0], interval[1])
		_check(not result.ok and result.first_sequence == 0 and result.count == 0 and not result.errors.is_empty(), "Invalid/unrepresentable interval failure shape")
	var fast: BalanceProfile = profile.with_overrides({"pressure": {"spawn_per_second": 1e308}}).profile
	_check(not MachineSpawnRules.arrivals_between(fast, 0, 2).ok, "Arrival product overflow rejected")
	var coverage := {}
	for sequence in range(1, 25):
		var result := MachineSpawnRules.spawn_descriptor(profile, sequence, 1)
		var expected_wedge := 12 if sequence in [1, 13] else (sequence - 1) % 12
		_check(result.ok and result.spawn.position.wedge == expected_wedge and result.spawn.position.angular_fraction == 0.5 and result.spawn.elapsed_seconds == sequence / 2.0, "Stable sequence coverage %d" % sequence)
		coverage[result.spawn.position.wedge] = coverage.get(result.spawn.position.wedge, 0) + 1
	_check(coverage.size() == 12 and coverage.values().all(func(count: int) -> bool: return count == 2), "24 arrivals cover each wedge exactly twice")
	for outer in [0, 1, 4, 20]:
		var spawn: Dictionary = MachineSpawnRules.spawn_descriptor(profile, 1, outer).spawn
		_check(spawn.position.ring == outer + 3 and spawn.position.radial_fraction == 0, "Integer offset chooses outward band at outer ring %d" % outer)
		var radius: float = 96.0 + (spawn.position.ring - 1 + spawn.position.radial_fraction) * 96.0
		_check(radius == 96.0 + outer * 96.0 + 192.0, "Offset measured from outer boundary, outer %d" % outer)
	var fractional: BalanceProfile = profile.with_overrides({"pressure": {"spawn_offset_ring_widths": 0.25}}).profile
	for outer in [0, 2, 7]:
		var spawn: Dictionary = MachineSpawnRules.spawn_descriptor(fractional, 1, outer).spawn
		_check(spawn.position.ring == outer + 1 and spawn.position.radial_fraction == 0.25 and spawn.position.angular_fraction == 0.5, "Fractional offset polar geometry")
	for sample in [[1, 10.0, 5.0], [119, 10.0, 5.0], [120, 11.0, 5.5], [240, 12.0, 6.0]]:
		var spawn: Dictionary = MachineSpawnRules.spawn_descriptor(profile, sample[0], 1).spawn
		_check(is_equal_approx(spawn.hp, sample[1]) and is_equal_approx(spawn.damage_per_second, sample[2]), "Stats use descriptor due time %d" % sample[0])
	var a := MachineSpawnRules.spawn_descriptor(profile, 1, 1)
	var b := MachineSpawnRules.spawn_descriptor(profile, 1, 1)
	a.spawn.position.ring = 99
	a.spawn.hp = 0
	_check(b.spawn.position.ring == 4 and b.spawn.hp == 10 and profile.snapshot() == baseline, "Descriptors and positions independently owned")
	_check(b.spawn.keys().size() == 6 and not b.spawn.has("id") and not b.spawn.has("world_position"), "Descriptor contains stats/polar fields only and no entity ID")
	for ids in [[0, 1], [-1, 1], [1, -1], [1, 9223372036854775807]]:
		var result := MachineSpawnRules.spawn_descriptor(profile, ids[0], ids[1])
		_check(not result.ok and result.spawn == null and not result.errors.is_empty(), "Invalid sequence/outer/overflow ring")
	var huge_offset: BalanceProfile = profile.with_overrides({"pressure": {"spawn_offset_ring_widths": 1e308}}).profile
	_check(not MachineSpawnRules.spawn_descriptor(huge_offset, 1, 1).ok, "Unrepresentable offset rejected")
	var tiny_rate: BalanceProfile = profile.with_overrides({"pressure": {"spawn_per_second": 1e-308}}).profile
	_check(not MachineSpawnRules.spawn_descriptor(tiny_rate, 2, 1).ok, "Nonfinite due time rejected")
	var unit_rate: BalanceProfile = profile.with_overrides({"pressure": {"spawn_per_second": 1}}).profile
	var large := MachineSpawnRules.arrivals_between(unit_rate, 0, 1e12)
	_check(large.ok and large.first_sequence == 1 and large.count == 1000000000000, "Large interval represented as scalar count without arrival allocation")
	var near_limit := MachineSpawnRules.arrivals_between(unit_rate, 9223372036854774784.0, 9223372036854774784.0)
	_check(near_limit.ok and near_limit.first_sequence == 9223372036854774785 and near_limit.count == 0, "Representable empty interval near signed integer limit")
	_check(not MachineSpawnRules.arrivals_between(unit_rate, 0, 9223372036854775808.0).ok, "Exclusive signed integer count limit rejected")
	var last_ring := MachineSpawnRules.spawn_descriptor(profile, 1, 9223372036854775804)
	_check(last_ring.ok and last_ring.spawn.position.ring == 9223372036854775807, "Last representable spawn ring accepted without integer wrap")
	_check(not MachineSpawnRules.spawn_descriptor(profile, 1, 9223372036854775805).ok, "First unrepresentable spawn ring rejected")
	_check(MachineSpawnRules.arrivals_between(unit_rate, 0, 1.0 - 0.5e-12).count == 1 and MachineSpawnRules.arrivals_between(unit_rate, 0, 1.0 - 2e-12).count == 0, "Only documented arrival-count boundary tolerance applied")
	_spawn_delay_checks(profile)
	print("Machine spawn rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


