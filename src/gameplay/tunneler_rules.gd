class_name TunnelerRules
extends RefCounted

# Same scheduled-arrival roundoff allowance as normal machines, in count units.
const ARRIVAL_EPSILON := 1e-12
const INTEGER_LIMIT_EXCLUSIVE := 9223372036854775808.0
const MAX_INTEGER := 9223372036854775807

static func _arrival_failure(message: String) -> Dictionary:
	return {"ok": false, "first_sequence": 0, "count": 0, "errors": PackedStringArray([message])}

static func _failure(errors: PackedStringArray) -> Dictionary:
	return {"ok": false, "eligible": false, "spawn": null, "errors": errors}

static func _completed(time: float, first: float, interval: float) -> float:
	# All schedules begin strictly after zero, even within roundoff tolerance.
	if time == 0.0: return 0.0
	var units := (time - first) / interval
	# A negative overflow before the first due time still means no arrivals.
	if units == -INF: return 0.0
	return maxf(0.0, floorf(units + ARRIVAL_EPSILON) + 1.0)

static func arrivals_between(profile: BalanceProfile, start_seconds: float, end_seconds: float) -> Dictionary:
	if profile == null or not profile.is_validated():
		return _arrival_failure("Invalid balance profile")
	if not is_finite(start_seconds) or not is_finite(end_seconds) or start_seconds < 0 or end_seconds < start_seconds:
		return _arrival_failure("Arrival interval must be finite and satisfy 0 <= start <= end")
	var first := float(profile.value("tunneler.first_arrival_seconds"))
	var interval := float(profile.value("tunneler.arrival_interval_seconds"))
	var previous := _completed(start_seconds, first, interval)
	var completed := _completed(end_seconds, first, interval)
	if not is_finite(previous) or not is_finite(completed) or previous >= INTEGER_LIMIT_EXCLUSIVE or completed >= INTEGER_LIMIT_EXCLUSIVE:
		return _arrival_failure("Tunneler arrival counts exceed supported signed integer range")
	var previous_count := int(previous)
	if previous_count == MAX_INTEGER:
		return _arrival_failure("Next Tunneler sequence exceeds supported signed integer range")
	return {"ok": true, "first_sequence": previous_count + 1, "count": int(completed) - previous_count, "errors": PackedStringArray()}

static func spawn_descriptor(profile: BalanceProfile, state: Dictionary, sequence: int) -> Dictionary:
	var errors := RingPurchaseRules.validate_state(state, profile)
	if not errors.is_empty(): return _failure(errors)
	if sequence < 1: return _failure(PackedStringArray(["Tunneler sequence must be positive"]))
	var due := float(profile.value("tunneler.first_arrival_seconds")) + float(sequence - 1) * float(profile.value("tunneler.arrival_interval_seconds"))
	if not is_finite(due): return _failure(PackedStringArray(["Tunneler due time must be finite"]))
	var stats_result := MachineSpawnRules.stats_at(profile, due)
	if not stats_result.ok: return _failure(stats_result.errors)
	var factor := 1.0 + floorf(due / 60.0) * float(profile.value("pressure.stat_increase_per_minute"))
	var hp := float(profile.value("health.tunneler_hp")) * factor
	if not is_finite(hp): return _failure(PackedStringArray(["Computed Tunneler HP must be finite"]))
	var bearing := (sequence - 1) % PolarGrid.WEDGE_COUNT
	var wedge := PolarGrid.WEDGE_COUNT if bearing == 0 else bearing
	var outer := 0
	var inner := 0
	for ring in range(state.rings.size(), 0, -1):
		if state.rings[ring].get("collapsed", false) or state.rings[ring].wedges[wedge].hp <= 0: continue
		if outer == 0: outer = ring
		else:
			inner = ring
			break
	if inner == 0:
		return {"ok": true, "eligible": false, "spawn": null, "errors": PackedStringArray()}
	if outer == MAX_INTEGER:
		return _failure(PackedStringArray(["Tunneler perimeter band exceeds supported signed integer range"]))
	var stats: Dictionary = stats_result.stats
	return {"ok": true, "eligible": true, "spawn": {
		"sequence": sequence, "elapsed_seconds": due, "kind": &"tunneler", "phase": &"burrowing", "targetable": false,
		"position": PolarPosition.new(outer + 1, wedge, 0, 0.5),
		"start_position": PolarPosition.new(outer + 1, wedge, 0, 0.5),
		"destination": PolarPosition.new(inner, wedge, 0.5, 0.5), "surface_cell": Vector2i(inner, wedge),
		"burrow_elapsed_seconds": 0.0, "burrow_duration_seconds": float(profile.value("tunneler.burrow_seconds")),
		"hp": hp, "damage_per_second": stats.damage_per_second, "speed_ring_widths_per_second": stats.speed_ring_widths_per_second,
	}, "errors": PackedStringArray()}
