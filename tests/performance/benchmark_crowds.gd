extends SceneTree
## Headless microbenchmarks: no frame-rate or final crowd-cap inference.

const WARMUPS := 3
const SAMPLES := 10
var _checksum := 0

func _initialize() -> void:
	var loaded: Dictionary = BalanceProfile.load_json("res://data/balance/testing.json")
	if not loaded.ok:
		_fail(str(loaded.errors))
		return
	var profile = loaded.profile
	var created: Dictionary = BuildingRules.create_default_testing_state(profile)
	if not created.ok:
		_fail(str(created.errors))
		return
	var state = created.state
	state.energy = 1000
	for wedge in range(1, 12):
		if wedge == 6:
			continue
		var placed: Dictionary = BuildingRules.place_weapon(state, profile, 1, wedge, 0, &"flak")
		if not placed.ok:
			_fail(str(placed.errors))
			return
		state = placed.state
	print("crowd benchmark: headless, warmups=%d samples=%d, durations_us" % [WARMUPS, SAMPLES])
	for capacity in [500, 1000, 5000]:
		var pool := EntityPool.new(capacity)
		var measurements := {"spawn": [], "iteration": [], "release": [], "reuse": [], "ready_volley": []}
		var targets: Array[Dictionary] = []
		for index in range(capacity):
			targets.append({"id": index, "position": PolarPosition.new(2, index % 12 + 1, 0.5, 0.5), "hp": 1.0e12})
		for sample in range(WARMUPS + SAMPLES):
			var started := Time.get_ticks_usec()
			for index in range(capacity):
				pool.spawn({"value": index})
			_record(measurements, "spawn", started, sample)
			started = Time.get_ticks_usec()
			for id in pool.active_ids():
				_checksum += int(pool.payload_for(id).value)
			_record(measurements, "iteration", started, sample)
			var ids := pool.active_ids()
			started = Time.get_ticks_usec()
			for id in ids:
				pool.release(id)
			_record(measurements, "release", started, sample)
			started = Time.get_ticks_usec()
			for index in range(capacity):
				pool.spawn({"value": index})
			_record(measurements, "reuse", started, sample)
			for id in pool.active_ids():
				pool.release(id)
			started = Time.get_ticks_usec()
			var combat: Dictionary = WeaponRules.step(state, profile, targets, {}, 1.0 / 60.0)
			var combat_us := Time.get_ticks_usec() - started
			if not combat.ok:
				_fail(str(combat.errors))
				return
			if sample >= WARMUPS:
				measurements.ready_volley.append(combat_us)
			for index in range(capacity):
				if targets[index].hp != 1.0e12 or targets[index].id != index:
					_fail("Input target mutation")
					return
			if pool.allocated_record_count != capacity or not combat.kill_ids.is_empty():
				_fail("Storage growth or unexpected kills")
				return
			if sample == WARMUPS:
				print("capacity=%d first_measured_volley_hits=%d kills=%d" % [capacity, combat.hits.size(), combat.kill_ids.size()])
			if combat_us > 2000000:
				print("Slow sample >2 seconds; bounded early stop for this capacity")
				break
		for operation in measurements:
			var times: Array = measurements[operation]
			if times.is_empty():
				print("capacity=%d operation=%s no measured samples" % [capacity, operation])
				continue
			times.sort()
			var median: float = (float(times[(times.size() - 1) / 2]) + float(times[times.size() / 2])) / 2.0
			print("capacity=%d operation=%s n=%d median_us=%.1f p90_us=%d max_us=%d" % [capacity, operation, times.size(), median, times[ceili(times.size() * 0.9) - 1], times[-1]])
	print("checksum=%d" % _checksum)
	quit(0)

func _record(measurements: Dictionary, operation: String, started: int, sample: int) -> void:
	var duration := Time.get_ticks_usec() - started
	if sample >= WARMUPS:
		measurements[operation].append(duration)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
