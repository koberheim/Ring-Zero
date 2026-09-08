class_name MachineSpawnRules
extends RefCounted

# Tolerance in arrival-count units, only for roundoff at scheduled boundaries.
const ARRIVAL_EPSILON := 0.000000000001
const INTEGER_LIMIT_EXCLUSIVE := 9223372036854775808.0
const MAX_INTEGER := 9223372036854775807

static func _valid_profile(profile: BalanceProfile) -> bool:
	return profile != null and BalanceProfile.from_dict(profile.snapshot()).ok

static func _failure(message: String, field: String) -> Dictionary:
	return {"ok": false, field: null, "errors": PackedStringArray([message])}

static func _arrival_failure(message: String) -> Dictionary:
	return {"ok": false, "first_sequence": 0, "count": 0, "errors": PackedStringArray([message])}

static func stats_at(profile: BalanceProfile, elapsed_seconds: float) -> Dictionary:
	if not _valid_profile(profile):
		return _failure("Invalid balance profile", "stats")
	if not is_finite(elapsed_seconds) or elapsed_seconds < 0:
		return _failure("Elapsed seconds must be finite and nonnegative", "stats")
	var factor := 1.0 + floorf(elapsed_seconds / 60.0) * float(profile.value("pressure.stat_increase_per_minute"))
	var hp := float(profile.value("health.standard_machine_hp")) * factor
	var damage := float(profile.value("standard_machine.damage_per_second")) * factor
	var speed := float(profile.value("pressure.speed_ring_widths_per_second"))
	if not is_finite(factor) or not is_finite(hp) or not is_finite(damage):
		return _failure("Computed machine stats must be finite", "stats")
	return {"ok": true, "stats": {"hp": hp, "damage_per_second": damage, "speed_ring_widths_per_second": speed}, "errors": PackedStringArray()}

static func arrivals_between(profile: BalanceProfile, start_seconds: float, end_seconds: float) -> Dictionary:
	if not _valid_profile(profile):
		return _arrival_failure("Invalid balance profile")
	if not is_finite(start_seconds) or not is_finite(end_seconds) or start_seconds < 0 or end_seconds < start_seconds:
		return _arrival_failure("Arrival interval must be finite and satisfy 0 <= start <= end")
	var rate := float(profile.value("pressure.spawn_per_second"))
	if rate == 0:
		return {"ok": true, "first_sequence": 0, "count": 0, "errors": PackedStringArray()}
	# D-033 testing tuning: no normal machine is due before spawn_delay_seconds
	# of match time has passed, giving the player a preliminary build window.
	var delay := float(profile.value("pressure.spawn_delay_seconds"))
	var effective_start := maxf(0.0, start_seconds - delay)
	var effective_end := maxf(0.0, end_seconds - delay)
	var previous := floorf(effective_start * rate + ARRIVAL_EPSILON)
	var completed := floorf(effective_end * rate + ARRIVAL_EPSILON)
	if not is_finite(previous) or not is_finite(completed) or previous >= INTEGER_LIMIT_EXCLUSIVE or completed >= INTEGER_LIMIT_EXCLUSIVE:
		return _arrival_failure("Arrival counts exceed supported signed integer range")
	var previous_count := int(previous)
	var completed_count := int(completed)
	if previous_count == MAX_INTEGER:
		return _arrival_failure("Next sequence exceeds supported signed integer range")
	return {"ok": true, "first_sequence": previous_count + 1, "count": completed_count - previous_count, "errors": PackedStringArray()}

static func spawn_descriptor(profile: BalanceProfile, sequence: int, outer_ring: int) -> Dictionary:
	if not _valid_profile(profile):
		return _failure("Invalid balance profile", "spawn")
	if sequence < 1 or outer_ring < 0:
		return _failure("Sequence must be positive and outer ring nonnegative", "spawn")
	var rate := float(profile.value("pressure.spawn_per_second"))
	if rate <= 0:
		return _failure("Spawn descriptor requires positive spawn rate", "spawn")
	var elapsed := float(profile.value("pressure.spawn_delay_seconds")) + float(sequence) / rate
	var stats_result := stats_at(profile, elapsed)
	if not stats_result.ok:
		return {"ok": false, "spawn": null, "errors": stats_result.errors}
	var offset := float(profile.value("pressure.spawn_offset_ring_widths"))
	var offset_bands := floorf(offset)
	if offset_bands >= INTEGER_LIMIT_EXCLUSIVE:
		return _failure("Spawn ring exceeds supported signed integer range", "spawn")
	var bands := int(offset_bands)
	if bands > MAX_INTEGER - outer_ring - 1:
		return _failure("Spawn ring exceeds supported signed integer range", "spawn")
	var radius := float(PolarGrid.CORE_RADIUS) + float(outer_ring) * PolarGrid.RING_WIDTH + offset * PolarGrid.RING_WIDTH
	if not is_finite(radius):
		return _failure("Spawn radius must be finite", "spawn")
	var bearing_index := (sequence - 1) % PolarGrid.WEDGE_COUNT
	var wedge := PolarGrid.WEDGE_COUNT if bearing_index == 0 else bearing_index
	var position := PolarPosition.new(outer_ring + bands + 1, wedge, offset - offset_bands, 0.5)
	var stats: Dictionary = stats_result.stats
	return {"ok": true, "spawn": {"sequence": sequence, "elapsed_seconds": elapsed, "position": position, "hp": stats.hp, "damage_per_second": stats.damage_per_second, "speed_ring_widths_per_second": stats.speed_ring_widths_per_second}, "errors": PackedStringArray()}

