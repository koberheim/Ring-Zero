class_name BreacherRules
extends RefCounted

# D-109: same scheduled-arrival shape as Tunneler/Foundry/Transfer/Sapper, but
# Breacher carries no stat multipliers - its distinct threat is entirely its
# routing (always prefers the nearest wall over any detour) and full,
# unpenalized wall damage, both implemented in LiveSimulation/WallNavigation.
const ARRIVAL_EPSILON := 1e-12
const INTEGER_LIMIT_EXCLUSIVE := 9223372036854775808.0
const MAX_INTEGER := 9223372036854775807

static func _arrival_failure(message: String) -> Dictionary:
	return {"ok": false, "first_sequence": 0, "count": 0, "errors": PackedStringArray([message])}

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "spawn": null, "errors": PackedStringArray([message])}

static func _valid_profile(profile: BalanceProfile) -> bool:
	return profile != null and profile.is_validated()

static func _completed(time: float, first: float, interval: float) -> float:
	if time == 0.0: return 0.0
	var units := (time - first) / interval
	if units == -INF: return 0.0
	return maxf(0.0, floorf(units + ARRIVAL_EPSILON) + 1.0)

static func arrivals_between(profile: BalanceProfile, start_seconds: float, end_seconds: float) -> Dictionary:
	if not _valid_profile(profile):
		return _arrival_failure("Invalid balance profile")
	if not is_finite(start_seconds) or not is_finite(end_seconds) or start_seconds < 0 or end_seconds < start_seconds:
		return _arrival_failure("Arrival interval must be finite and satisfy 0 <= start <= end")
	var first := float(profile.value("breacher.first_arrival_seconds"))
	var interval := float(profile.value("breacher.arrival_interval_seconds"))
	if not is_finite(first) or not is_finite(interval) or interval <= 0:
		return _arrival_failure("Breacher schedule requires a finite positive interval")
	var previous := _completed(start_seconds, first, interval)
	var completed := _completed(end_seconds, first, interval)
	if not is_finite(previous) or not is_finite(completed) or previous >= INTEGER_LIMIT_EXCLUSIVE or completed >= INTEGER_LIMIT_EXCLUSIVE:
		return _arrival_failure("Breacher arrival counts exceed supported signed integer range")
	var previous_count := int(previous)
	if previous_count == MAX_INTEGER:
		return _arrival_failure("Next Breacher sequence exceeds supported signed integer range")
	return {"ok": true, "first_sequence": previous_count + 1, "count": int(completed) - previous_count, "errors": PackedStringArray()}

static func spawn_descriptor(profile: BalanceProfile, sequence: int, outer_ring: int) -> Dictionary:
	if not _valid_profile(profile):
		return _failure("Invalid balance profile")
	if sequence < 1 or outer_ring < 0:
		return _failure("Sequence must be positive and outer ring nonnegative")
	var due := float(profile.value("breacher.first_arrival_seconds")) + float(sequence - 1) * float(profile.value("breacher.arrival_interval_seconds"))
	if not is_finite(due):
		return _failure("Breacher due time must be finite")
	var stats_result := MachineSpawnRules.stats_at(profile, due)
	if not stats_result.ok: return {"ok": false, "spawn": null, "errors": stats_result.errors}
	var stats: Dictionary = stats_result.stats
	# Same perimeter-band spawn placement and bearing cycle as a standard machine.
	var offset := float(profile.value("pressure.spawn_offset_ring_widths"))
	var offset_bands := floorf(offset)
	if offset_bands >= INTEGER_LIMIT_EXCLUSIVE or int(offset_bands) > MAX_INTEGER - outer_ring - 1:
		return _failure("Spawn ring exceeds supported signed integer range")
	var bands := int(offset_bands)
	var radius := float(PolarGrid.CORE_RADIUS) + float(outer_ring) * PolarGrid.RING_WIDTH + offset * PolarGrid.RING_WIDTH
	if not is_finite(radius):
		return _failure("Spawn radius must be finite")
	var bearing_index := (sequence - 1) % PolarGrid.WEDGE_COUNT
	var wedge := PolarGrid.WEDGE_COUNT if bearing_index == 0 else bearing_index
	var position := PolarPosition.new(outer_ring + bands + 1, wedge, offset - offset_bands, 0.5)
	return {"ok": true, "spawn": {
		"sequence": sequence, "elapsed_seconds": due, "kind": &"breacher",
		"position": position, "hp": stats.hp, "damage_per_second": stats.damage_per_second, "speed_ring_widths_per_second": stats.speed_ring_widths_per_second,
	}, "errors": PackedStringArray()}
