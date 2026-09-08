class_name FoundryRules
extends RefCounted
## D-106: Foundry is a standard machine with no special movement or targeting
## (Option A) — its own scheduled arrival (mirroring Tunneler's admission
## shape) producing a much tankier, slower, harder-hitting variant. It uses
## LiveSimulation's ordinary _advance_machine path once admitted.

# Same scheduled-arrival roundoff allowance as Tunneler, in count units.
const ARRIVAL_EPSILON := 1e-12
const INTEGER_LIMIT_EXCLUSIVE := 9223372036854775808.0
const MAX_INTEGER := 9223372036854775807

static func _arrival_failure(message: String) -> Dictionary:
	return {"ok": false, "first_sequence": 0, "count": 0, "errors": PackedStringArray([message])}

static func _failure(errors: PackedStringArray) -> Dictionary:
	return {"ok": false, "spawn": null, "errors": errors}

static func _completed(time: float, first: float, interval: float) -> float:
	# All schedules begin strictly after zero, even within roundoff tolerance.
	if time == 0.0: return 0.0
	var units := (time - first) / interval
	if units == -INF: return 0.0
	return maxf(0.0, floorf(units + ARRIVAL_EPSILON) + 1.0)

static func arrivals_between(profile: BalanceProfile, start_seconds: float, end_seconds: float) -> Dictionary:
	if profile == null or not profile.is_validated():
		return _arrival_failure("Invalid balance profile")
	if not is_finite(start_seconds) or not is_finite(end_seconds) or start_seconds < 0 or end_seconds < start_seconds:
		return _arrival_failure("Arrival interval must be finite and satisfy 0 <= start <= end")
	var first := float(profile.value("foundry.first_arrival_seconds"))
	var interval := float(profile.value("foundry.arrival_interval_seconds"))
	var previous := _completed(start_seconds, first, interval)
	var completed := _completed(end_seconds, first, interval)
	if not is_finite(previous) or not is_finite(completed) or previous >= INTEGER_LIMIT_EXCLUSIVE or completed >= INTEGER_LIMIT_EXCLUSIVE:
		return _arrival_failure("Foundry arrival counts exceed supported signed integer range")
	var previous_count := int(previous)
	if previous_count == MAX_INTEGER:
		return _arrival_failure("Next Foundry sequence exceeds supported signed integer range")
	return {"ok": true, "first_sequence": previous_count + 1, "count": int(completed) - previous_count, "errors": PackedStringArray()}

static func spawn_descriptor(profile: BalanceProfile, sequence: int, outer_ring: int) -> Dictionary:
	if profile == null or not profile.is_validated():
		return _failure(PackedStringArray(["Invalid balance profile"]))
	if sequence < 1 or outer_ring < 0:
		return _failure(PackedStringArray(["Sequence must be positive and outer ring nonnegative"]))
	var first := float(profile.value("foundry.first_arrival_seconds"))
	var interval := float(profile.value("foundry.arrival_interval_seconds"))
	var due := first + float(sequence - 1) * interval
	if not is_finite(due):
		return _failure(PackedStringArray(["Foundry due time must be finite"]))
	var stats_result := MachineSpawnRules.stats_at(profile, due)
	if not stats_result.ok:
		return _failure(stats_result.errors)
	var stats: Dictionary = stats_result.stats
	var hp: float = float(stats.hp) * float(profile.value("foundry.hp_multiplier"))
	var damage: float = float(stats.damage_per_second) * float(profile.value("foundry.damage_multiplier"))
	var speed: float = float(stats.speed_ring_widths_per_second) * float(profile.value("foundry.speed_multiplier"))
	if not is_finite(hp) or hp <= 0 or not is_finite(damage) or damage < 0 or not is_finite(speed) or speed <= 0:
		return _failure(PackedStringArray(["Computed Foundry stats must be finite, HP/speed positive"]))
	var offset := float(profile.value("pressure.spawn_offset_ring_widths"))
	var offset_bands := floorf(offset)
	if offset_bands >= INTEGER_LIMIT_EXCLUSIVE:
		return _failure(PackedStringArray(["Spawn ring exceeds supported signed integer range"]))
	var bands := int(offset_bands)
	if bands > MAX_INTEGER - outer_ring - 1:
		return _failure(PackedStringArray(["Spawn ring exceeds supported signed integer range"]))
	var radius := float(PolarGrid.CORE_RADIUS) + float(outer_ring) * PolarGrid.RING_WIDTH + offset * PolarGrid.RING_WIDTH
	if not is_finite(radius):
		return _failure(PackedStringArray(["Spawn radius must be finite"]))
	var bearing_index := (sequence - 1) % PolarGrid.WEDGE_COUNT
	var wedge := PolarGrid.WEDGE_COUNT if bearing_index == 0 else bearing_index
	var position := PolarPosition.new(outer_ring + bands + 1, wedge, offset - offset_bands, 0.5)
	return {"ok": true, "spawn": {
		"sequence": sequence, "elapsed_seconds": due, "kind": &"foundry", "position": position,
		"hp": hp, "damage_per_second": damage, "speed_ring_widths_per_second": speed,
	}, "errors": PackedStringArray()}
