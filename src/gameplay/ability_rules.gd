class_name AbilityRules
extends RefCounted

const KINDS: Array[StringName] = [&"focused_flare", &"emp_burst"]

static func valid_cooldowns(cooldowns: Dictionary) -> bool:
	for key in cooldowns:
		if typeof(key) != TYPE_STRING_NAME or key not in KINDS or not RingPurchaseRules.number(cooldowns[key]) or cooldowns[key] < 0: return false
	return true

# PolarGrid's scalar mapping, retained as doubles rather than Vector2 float32.
# The stable polar distance avoids subtracting large rounded world coordinates.
static func _geometry(position: PolarPosition) -> Dictionary:
	if position.ring == 0:
		return {"radius": position.radial_fraction * PolarGrid.CORE_RADIUS, "angle": position.angular_fraction * TAU}
	return {"radius": PolarGrid.CORE_RADIUS + (float(position.ring) - 1.0 + position.radial_fraction) * PolarGrid.RING_WIDTH, "angle": (float(position.wedge % 12) / 12.0 - 1.0 / 24.0 + position.angular_fraction / 12.0) * TAU}

static func _angle_difference(a: float, b: float) -> float:
	return fposmod(a - b + PI, TAU) - PI

static func cast(profile: BalanceProfile, targets: Array[Dictionary], cooldowns: Dictionary, kind: StringName, aim: PolarPosition) -> Dictionary:
	if not RingPurchaseRules.valid_profile(profile): return WeaponRules._failure("Invalid ability profile")
	if kind not in KINDS or not valid_cooldowns(cooldowns): return WeaponRules._failure("Invalid ability or cooldowns")
	if not WeaponRules._valid_position(aim): return WeaponRules._failure("Invalid ability aim")
	if float(cooldowns.get(kind, 0.0)) > 0: return WeaponRules._failure("Ability is cooling down")
	var ids := {}
	for target in targets:
		if typeof(target.get("id")) != TYPE_INT or target.id < 0 or ids.has(target.id) or not RingPurchaseRules.number(target.get("hp")) or target.hp < 0 or not WeaponRules._valid_position(target.get("position")) or not WeaponRules._valid_statuses(target): return WeaponRules._failure("Malformed ability target")
		if target.has("targetable") and typeof(target.targetable) != TYPE_BOOL: return WeaponRules._failure("Targetable must be a boolean")
		for field in ["start_position", "destination"]:
			if target.has(field) and not WeaponRules._valid_position(target[field]): return WeaponRules._failure("Malformed target endpoint")
		ids[target.id] = true
	var aim_geometry := _geometry(aim)
	if not is_finite(aim_geometry.radius) or not is_finite(aim_geometry.angle): return WeaponRules._failure("Nonfinite ability aim")
	if kind == &"focused_flare" and aim_geometry.radius == 0: return WeaponRules._failure("Flare requires a nonzero bearing")
	var radius := float(profile.value("%s.%s" % [kind, "range_ring_widths" if kind == &"focused_flare" else "radius_ring_widths"])) * PolarGrid.RING_WIDTH
	if not is_finite(radius): return WeaponRules._failure("Nonfinite ability range")
	var half_arc := deg_to_rad(float(profile.value("focused_flare.arc_degrees"))) * 0.5
	var damage_value := float(profile.value("%s.damage" % kind))
	var updated: Array[Dictionary] = []
	var hits: Array[Dictionary] = []
	var kills: Array[int] = []
	for target in targets:
		var position: PolarPosition = target.position
		var geometry := _geometry(position)
		var angle_difference := _angle_difference(geometry.angle, aim_geometry.angle)
		var radial_difference: float = geometry.radius - aim_geometry.radius
		var half_sine := sin(angle_difference * 0.5)
		var distance: float = geometry.radius if kind == &"focused_flare" else sqrt(radial_difference * radial_difference + 4.0 * geometry.radius * aim_geometry.radius * half_sine * half_sine)
		if not is_finite(geometry.radius) or not is_finite(geometry.angle) or not is_finite(distance): return WeaponRules._failure("Nonfinite ability geometry")
		var copied := target.duplicate(true)
		for field in ["position", "start_position", "destination"]:
			if target.has(field):
				var p: PolarPosition = target[field]
				copied[field] = PolarPosition.new(p.ring, p.wedge, p.radial_fraction, p.angular_fraction)
		updated.append(copied)
		if target.hp <= 0 or not target.get("targetable", true) or distance > radius + WeaponRules.BOUNDARY_EPSILON: continue
		if kind == &"focused_flare" and distance > WeaponRules.BOUNDARY_EPSILON and absf(angle_difference) > half_arc + WeaponRules.BOUNDARY_EPSILON: continue
		var damage := minf(float(target.hp), damage_value)
		copied.hp = maxf(0.0, float(target.hp) - damage)
		if kind == &"emp_burst" and copied.hp > 0:
			copied.stun_remaining = maxf(float(target.get("stun_remaining", 0.0)), float(profile.value("emp_burst.stun_seconds")))
		hits.append({"ability_id": kind, "target_id": target.id, "damage": damage})
		if copied.hp == 0: kills.append(target.id)
	var updated_cooldowns := cooldowns.duplicate(true)
	updated_cooldowns[kind] = float(profile.value("%s.cooldown_seconds" % kind))
	return {"ok": true, "errors": PackedStringArray(), "targets": updated, "cooldowns": updated_cooldowns, "hits": hits, "kill_ids": kills, "energy_awarded": 0}
