class_name WeaponRules
extends RefCounted

# Boundary tolerance: 0.00001 world units for range and radians for arc.
const BOUNDARY_EPSILON := 0.00001
# Only absorb subtraction roundoff (seconds), avoiding a one-tick cadence delay.
const COOLDOWN_EPSILON := 0.000000000001
# Algorithm crossover only: larger profile caps still use all eligible targets.
const BOUNDED_SELECTION_THRESHOLD := 16

static func _failure(message: String) -> Dictionary:
	var targets: Array[Dictionary] = []
	var hits: Array[Dictionary] = []
	var kills: Array[int] = []
	return {"ok": false, "targets": targets, "cooldowns": {}, "hits": hits, "kill_ids": kills, "energy_awarded": 0, "errors": PackedStringArray([message])}

static func _valid_position(position: Variant) -> bool:
	if not position is PolarPosition:
		return false
	if position.ring == 0 and position.radial_fraction == 0 and position.angular_fraction != 0:
		return false
	return position.ring >= 0 and ((position.ring == 0 and position.wedge == 0) or (position.ring > 0 and position.wedge >= 1 and position.wedge <= PolarGrid.WEDGE_COUNT)) and is_finite(position.radial_fraction) and position.radial_fraction >= 0 and position.radial_fraction < 1 and is_finite(position.angular_fraction) and position.angular_fraction >= 0 and position.angular_fraction < 1

# Shared preflight for optional status fields on legacy and live targets.
static func _valid_statuses(target: Dictionary) -> bool:
	if target.has("stun_remaining") and (not RingPurchaseRules.number(target.stun_remaining) or target.stun_remaining < 0): return false
	if target.has("assimilation_stacks"):
		if not target.assimilation_stacks is Array: return false
		for expiry in target.assimilation_stacks:
			if not RingPurchaseRules.number(expiry) or expiry < 0: return false
	return true

static func _valid_key(key: Variant) -> bool:
	if typeof(key) != TYPE_STRING_NAME:
		return false
	var parts := String(key).split(":")
	if parts.size() != 3:
		return false
	for part in parts:
		if not part.is_valid_int() or str(part.to_int()) != part:
			return false
	return parts[0].to_int() > 0 and parts[1].to_int() >= 1 and parts[1].to_int() <= PolarGrid.WEDGE_COUNT and parts[2].to_int() >= 0

static func step(state: Dictionary, profile: BalanceProfile, targets: Array[Dictionary], cooldowns: Dictionary, delta_seconds: float) -> Dictionary:
	return _step_impl(state, profile, targets, cooldowns, delta_seconds, true)

# Consumes exclusive scratch records. HP may change before a later failure;
# callers must discard failed scratch. Position objects and nested extra data
# are read-only and may be borrowed. State/profile/cooldowns are never consumed.
static func _step_owned(state: Dictionary, profile: BalanceProfile, targets: Array[Dictionary], cooldowns: Dictionary, delta_seconds: float) -> Dictionary:
	return _step_impl(state, profile, targets, cooldowns, delta_seconds, false)

static func _step_impl(state: Dictionary, profile: BalanceProfile, targets: Array[Dictionary], cooldowns: Dictionary, delta_seconds: float, copy_targets: bool) -> Dictionary:
	var errors := RingPurchaseRules.validate_state(state, profile)
	if not errors.is_empty():
		return _failure("\n".join(errors))
	if not is_finite(delta_seconds) or delta_seconds < 0:
		return _failure("Delta seconds must be finite and nonnegative")
	for key in cooldowns:
		if not _valid_key(key) or not RingPurchaseRules.number(cooldowns[key]) or cooldowns[key] < 0:
			return _failure("Malformed cooldown key or duration")
	var updated_targets: Array[Dictionary] = []
	if not copy_targets: updated_targets = targets
	var ids := {}
	for target in targets:
		if typeof(target.get("id")) != TYPE_INT or target.id < 0 or ids.has(target.id) or not RingPurchaseRules.number(target.get("hp")) or target.hp < 0 or not _valid_position(target.get("position")):
			return _failure("Malformed or duplicate target")
		if target.has("targetable") and typeof(target.targetable) != TYPE_BOOL:
			return _failure("Targetable must be a boolean")
		if not _valid_statuses(target): return _failure("Malformed target status")
		ids[target.id] = true
		if copy_targets:
			var copied := target.duplicate(true)
			var position: PolarPosition = target.position
			copied.position = PolarPosition.new(position.ring, position.wedge, position.radial_fraction, position.angular_fraction)
			for field in ["start_position", "destination"]:
				if target.get(field) is PolarPosition:
					var extra: PolarPosition = target[field]
					copied[field] = PolarPosition.new(extra.ring, extra.wedge, extra.radial_fraction, extra.angular_fraction)
			updated_targets.append(copied)
	var updated_cooldowns := {}
	var hits: Array[Dictionary] = []
	var kills: Array[int] = []
	var reward := 0.0
	var maximum_ring: int = state.rings.size()
	for target in updated_targets:
		maximum_ring = maxi(maximum_ring, target.position.ring)
	var grid := PolarGrid.new(maximum_ring)
	var world_positions: Array[Vector2] = []
	for target in updated_targets:
		world_positions.append(grid.polar_to_world(target.position))
	for ring in range(1, state.rings.size() + 1):
		# D-023: fixed per-ring power budget, spent in fixed ring/wedge/slot order.
		# A weapon that no longer fits (brownout, or simply over capacity) goes
		# fully inert for this tick rather than firing at reduced effect.
		var power_available := PowerRules.ring_output(state, profile, ring)
		var power_used := 0.0
		for wedge in range(1, PolarGrid.WEDGE_COUNT + 1):
			var plate: Dictionary = state.rings[ring].wedges[wedge]
			var slots: Array = plate.occupants.keys()
			slots.sort()
			for slot in slots:
				var kind: StringName = plate.occupants[slot].kind
				if kind not in [&"flak", &"mass_driver", &"emp_node", &"lance_emitter", &"point_defense"]:
					continue
				var key := StringName("%d:%d:%d" % [ring, wedge, slot])
				var remaining: float = maxf(0.0, float(cooldowns.get(key, 0.0)) - delta_seconds)
				if remaining <= COOLDOWN_EPSILON:
					remaining = 0.0
				updated_cooldowns[key] = remaining
				var demand: float = float(profile.value("%s.power_demand" % kind))
				var powered := power_used + demand <= power_available + 1e-9
				if powered: power_used += demand
				if plate.hp <= 0 or remaining > 0 or not powered:
					continue
				var position := BuildingRules.slot_position(ring, wedge, slot, plate.slot_count)
				var origin: Vector2 = grid.polar_to_world(position)
				var radius := float(profile.value("%s.range_ring_widths" % kind)) * PolarGrid.RING_WIDTH
				var arc := deg_to_rad(float(profile.value("%s.arc_degrees" % kind)))
				if not is_finite(radius):
					return _failure("Unusable computed weapon range")
				# EMP and Lance are approved all-eligible attacks. max_targets
				# remains valid legacy profile data but does not limit these kinds.
				var all_targets := kind in [&"emp_node", &"lance_emitter"]
				var cap: int = updated_targets.size() if all_targets else profile.value("%s.max_targets" % kind)
				var bounded := cap <= BOUNDED_SELECTION_THRESHOLD
				var candidates: Array[Dictionary] = []
				for target_index in range(updated_targets.size()):
					var target: Dictionary = updated_targets[target_index]
					if target.hp <= 0 or not target.get("targetable", true):
						continue
					if kind == &"emp_node" and target.position.ring != ring: continue
					var offset: Vector2 = world_positions[target_index] - origin
					var distance := offset.length()
					if not is_finite(distance):
						return _failure("Unusable target geometry")
					if kind == &"point_defense":
						# D-090: engages only a machine already standing in this
						# weapon's own ring+wedge cell — an exact cell match, not
						# a distance/arc computation ("defends only its own tile").
						if target.position.ring != ring or target.position.wedge != wedge:
							continue
					elif distance > radius + BOUNDARY_EPSILON:
						continue
					elif kind == &"lance_emitter":
						# D-089: a piercing beam along its own wedge column, not a
						# bearing-based arc — every machine standing in the same
						# wedge, at any angular offset, is in the corridor.
						if target.position.wedge != wedge or (float(target.position.ring) + target.position.radial_fraction - float(position.ring) - position.radial_fraction) * PolarGrid.RING_WIDTH < -BOUNDARY_EPSILON:
							continue
					elif arc < TAU and distance > BOUNDARY_EPSILON and absf(origin.angle_to(offset)) > arc * 0.5 + BOUNDARY_EPSILON:
						continue
					if bounded:
						# Keep the exact best cap candidates, ordered by distance then ID.
						# Every target is still checked; worse candidates need no allocation.
						if candidates.size() == cap:
							var worst: Dictionary = candidates[-1]
							if distance > worst.distance or (distance == worst.distance and target.id >= worst.target.id):
								continue
						var insertion := candidates.size()
						while insertion > 0:
							var previous: Dictionary = candidates[insertion - 1]
							if distance > previous.distance or (distance == previous.distance and target.id > previous.target.id):
								break
							insertion -= 1
						candidates.insert(insertion, {"target": target, "distance": distance})
						if candidates.size() > cap:
							candidates.pop_back()
					else:
						candidates.append({"target": target, "distance": distance})
				if not bounded:
					candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
						return a.distance < b.distance or (a.distance == b.distance and a.target.id < b.target.id))
				if candidates.is_empty():
					continue
				updated_cooldowns[key] = profile.value("%s.cycle_seconds" % kind)
				for index in range(mini(cap, candidates.size())):
					var target: Dictionary = candidates[index].target
					var damage := minf(float(target.hp), float(profile.value("%s.damage" % kind)))
					target.hp = maxf(0.0, float(target.hp) - damage)
					# D-088: EMP Node deals minimal damage but also refreshes (never
					# stacks) the target's stun clock, up to this pulse's duration.
					# A killing hit applies no stun; the field stays defined either way.
					if kind == &"emp_node":
						var stun_seconds: float = float(profile.value("emp_node.stun_seconds")) if target.hp > 0 else 0.0
						target.stun_remaining = maxf(float(target.get("stun_remaining", 0.0)), stun_seconds)
					hits.append({"weapon_id": key, "target_id": target.id, "damage": damage})
					if target.hp == 0:
						kills.append(target.id)
						reward += float(profile.value("economy.kill_energy"))
						if not is_finite(reward):
							return _failure("Nonfinite total kill reward")
	return {"ok": true, "targets": updated_targets, "cooldowns": updated_cooldowns, "hits": hits, "kill_ids": kills, "energy_awarded": reward, "errors": PackedStringArray()}




