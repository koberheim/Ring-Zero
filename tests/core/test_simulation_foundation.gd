extends SceneTree

var _failures := 0
var _calls := 0
var _seconds := 0.0
var _pause_clock: FixedStepClock

func _initialize() -> void:
	_test_pool()
	_test_clock()
	print("simulation_foundation: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		push_error(label)

func _tick(seconds: float) -> void:
	_calls += 1
	_seconds += seconds
	_check(is_equal_approx(seconds, 1.0 / 60.0), "callback fixed step")

func _tick_and_pause(_step: float) -> void:
	_calls += 1
	_pause_clock.paused = true

func _test_pool() -> void:
	_check(EntityPool.new(0).spawn({}) == -1, "zero capacity")
	_check(EntityPool.new(-1).capacity == 0, "negative capacity inert")
	var pool := EntityPool.new(2)
	var nested := {"value": 1}
	var input := {"nested": nested, "tag": "original"}
	var first := pool.spawn(input)
	input["tag"] = "changed"
	_check(pool.payload_for(first)["tag"] == "original", "top-level isolation")
	nested["value"] = 2
	_check(pool.payload_for(first)["nested"]["value"] == 2, "mutable domain value retained")
	pool.payload_for(first)["live"] = true
	_check(pool.payload_for(first).get("live", false), "live lookup")
	var second := pool.spawn({})
	_check(pool.spawn({}) == -1 and pool.active_count() == 2, "full no mutation")
	var snapshot := pool.active_ids()
	snapshot[0] = -999
	_check(pool.contains(first), "independent active IDs")
	var expired_reference := pool.payload_for(first)
	_check(pool.release(first) and not pool.release(first), "release and double release")
	_check(expired_reference.is_empty(), "release clears live storage")
	var third := pool.spawn({"new": true})
	_check(is_same(expired_reference, pool.payload_for(third)), "same payload dictionary reused")
	_check(third == second + 1 and not pool.contains(first) and pool.payload_for(first).is_empty(), "stale ID rejected")
	_check(not pool.payload_for(third).has("nested"), "slot cleared")
	_check(pool.active_ids() == PackedInt64Array([second, third]), "ascending IDs")
	for cycle in range(1000):
		for id in pool.active_ids():
			_check(pool.release(id), "churn release")
		_check(pool.active_count() == 0, "churn empty count")
		pool.spawn({"cycle": cycle})
		pool.spawn({})
		_check(pool.active_count() == 2 and pool.allocated_record_count == 2, "churn stable storage")
	var exhausted := EntityPool.new(2)
	exhausted._next_id = 9223372036854775807
	_check(exhausted.spawn({}) == 9223372036854775807, "last ID supported")
	_check(exhausted.spawn({}) == -1 and exhausted.active_count() == 1, "ID exhaustion no wrap")

func _test_clock() -> void:
	for parts in [1, 3, 7, 60, 144, 1000]:
		_calls = 0
		_seconds = 0.0
		var clock := FixedStepClock.new(60.0, _tick)
		var advanced := 0
		for index in range(parts):
			advanced += clock.advance(1.0 / parts)
		_check(advanced == 60 and clock.tick_count == 60 and _calls == 60, "partition %d" % parts)
		_check(is_equal_approx(clock.elapsed_seconds(), 1.0) and is_equal_approx(_seconds, 1.0), "elapsed and callback sum")
	var clock := FixedStepClock.new(60.0, _tick)
	var varied := FixedStepClock.new(60.0, _tick)
	for delta in [0.001, 0.123, 0.007, 0.369, 0.2, 0.3]:
		varied.advance(delta)
	_check(varied.tick_count == 60, "unequal partitions one second")
	_check(clock.advance(0.005) == 0, "fraction retained")
	clock.paused = true
	_check(clock.advance(10.0) == 0, "paused no callback")
	clock.paused = false
	_check(clock.advance(1.0 / 60.0 - 0.005) == 1 and clock.tick_count == 1, "resume remainder no catchup")
	for delta in [-1.0, INF, NAN]:
		_check(clock.advance(delta) == 0 and clock.tick_count == 1, "invalid delta inert")
	_check(clock.advance(0.0) == 0, "zero delta")
	for rate in [0.0, -1.0, INF, NAN]:
		var invalid := FixedStepClock.new(rate, _tick)
		_check(invalid.advance(1.0) == 0 and invalid.elapsed_seconds() == 0.0, "invalid rate inert")
	_check(FixedStepClock.new(60.0, Callable()).advance(1.0) == 0, "invalid callback inert")
	_calls = 0
	_pause_clock = FixedStepClock.new(60.0, _tick_and_pause)
	_check(_pause_clock.advance(1.0) == 1 and _calls == 1, "callback pause stops current advance")
	_pause_clock.paused = false
	_check(_pause_clock.advance(0.0) == 0, "callback pause discards remaining paused time")
	_check(_pause_clock.advance(1.0 / 60.0) == 1 and _calls == 2, "callback pause resumes normally")
	_pause_clock = null
