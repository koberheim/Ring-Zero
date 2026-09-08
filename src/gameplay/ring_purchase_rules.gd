class_name RingPurchaseRules
extends RefCounted

static func failure(message: String, field: String = "state") -> Dictionary:
	return {"ok": false, field: null, "errors": PackedStringArray([message])}

static func number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

static func valid_profile(profile: BalanceProfile) -> bool:
	return profile != null and profile.is_validated()

static func validate_state(state: Dictionary, profile: BalanceProfile) -> PackedStringArray:
	if not valid_profile(profile):
		return PackedStringArray(["Invalid balance profile"])
	if not number(state.get("energy")) or state.energy < 0 or not state.get("rings") is Dictionary or state.rings.is_empty():
		return PackedStringArray(["State requires nonnegative finite energy and owned rings"])
	for ring in state.rings:
		if typeof(ring) != TYPE_INT or ring < 1 or ring > state.rings.size():
			return PackedStringArray(["Owned rings must be contiguous positive integer IDs"])
		var record: Variant = state.rings[ring]
		if not record is Dictionary or not record.get("wedges") is Dictionary or record.wedges.size() != PolarGrid.WEDGE_COUNT or not record.get("relay") is Dictionary:
			return PackedStringArray(["Ring requires all 12 wedges and relay reference"])
		var relay: Dictionary = record.relay
		if typeof(record.get("collapsed", false)) != TYPE_BOOL:
			return PackedStringArray(["Collapsed marker must be bool"])
		var collapsed: bool = record.get("collapsed", false)
		# D-104: the relay floats within the ring rather than occupying a wedge
		# slot. It is a simple presence marker, not a positional reference —
		# every owned, non-collapsed ring has exactly one, collapse clears it.
		if collapsed and not relay.is_empty():
			return PackedStringArray(["Collapsed ring requires empty relay"])
		if not collapsed and relay != {"active": true}:
			return PackedStringArray(["Ring requires an active relay"])
		# D-108: relay_hp/relay_max_hp is a separate pool from any wedge's HP -
		# every owned, non-collapsed ring has one; a collapsed ring has none.
		if collapsed and (record.has("relay_hp") or record.has("relay_max_hp")):
			return PackedStringArray(["Collapsed ring must not retain relay HP"])
		if not collapsed:
			if not number(record.get("relay_hp")) or not number(record.get("relay_max_hp")):
				return PackedStringArray(["Ring requires numeric relay HP"])
			if record.relay_max_hp <= 0 or record.relay_hp < 0 or record.relay_hp > record.relay_max_hp:
				return PackedStringArray(["Invalid relay HP bounds"])
		var max_armor_stacks: int = profile.value("structure.armor_plating_max_stacks")
		for wedge in record.wedges:
			if typeof(wedge) != TYPE_INT or wedge < 1 or wedge > PolarGrid.WEDGE_COUNT:
				return PackedStringArray(["Invalid wedge ID"])
			var plate: Variant = record.wedges[wedge]
			if not plate is Dictionary or not number(plate.get("hp")) or not number(plate.get("max_hp")):
				return PackedStringArray(["Invalid wedge HP"])
			if plate.max_hp <= 0 or plate.hp < 0 or plate.hp > plate.max_hp or typeof(plate.get("slot_count")) != TYPE_INT or plate.slot_count < 1 or not plate.get("occupants") is Dictionary:
				return PackedStringArray(["Invalid wedge health or slots"])
			if collapsed and (plate.hp != 0 or not plate.occupants.is_empty()):
				return PackedStringArray(["Collapsed wedges require zero HP and empty occupants"])
			if plate.has("wall"):
				if collapsed:
					return PackedStringArray(["Collapsed wedges must not retain walls"])
				var wall: Variant = plate.wall
				if not wall is Dictionary or wall.size() != 2 or not number(wall.get("hp")) or not number(wall.get("max_hp")):
					return PackedStringArray(["Wall requires only finite numeric hp and max_hp"])
				if wall.hp <= 0 or wall.max_hp <= 0 or wall.hp > wall.max_hp:
					return PackedStringArray(["Wall HP must be positive and no greater than positive max_hp"])
			var armor_stacks := 0
			var lanes := 0
			for slot in plate.occupants:
				if typeof(slot) != TYPE_INT or slot < 0 or slot >= plate.slot_count:
					return PackedStringArray(["Invalid occupied slot"])
				var occupant: Variant = plate.occupants[slot]
				if not occupant is Dictionary or typeof(occupant.get("kind")) != TYPE_STRING_NAME or occupant.kind not in [&"flak", &"mass_driver", &"emp_node", &"lance_emitter", &"point_defense", &"armor_plating", &"repair_node", &"debris_field", &"tractor_lane", &"occlusion_screen"]:
					return PackedStringArray(["Invalid occupant kind"])
				if occupant.kind == &"tractor_lane":
					lanes += 1
					if typeof(occupant.get("direction")) != TYPE_INT or occupant.direction not in [-1, 1]:
						return PackedStringArray(["Tractor direction must be -1 or 1"])
				elif occupant.kind == &"armor_plating":
					armor_stacks += 1
			if lanes > 1: return PackedStringArray(["Wedge already has a Tractor Lane"])
			if armor_stacks > max_armor_stacks:
				return PackedStringArray(["Armor Plating exceeds the approved stack limit"])
	return PackedStringArray()

static func _dimensions(profile: BalanceProfile, ring: int) -> Dictionary:
	var hp := float(profile.value("health.wedge_base_hp")) * pow(ring, profile.value("scaling.wedge_hp_ring_exponent"))
	var slots := float(ring) * float(profile.value("scaling.slots_per_wedge_per_ring"))
	var cost := float(PolarGrid.WEDGE_COUNT) * float(profile.value("economy.ring_plate_base_cost")) * pow(ring, profile.value("scaling.claim_cost_ring_exponent"))
	if not is_finite(hp) or hp <= 0 or not is_finite(slots) or slots < 1 or slots >= 9223372036854775808.0 or not is_finite(cost) or cost < 0:
		return {}
	return {"wedge_hp": hp, "slots_per_wedge": int(slots), "cost": cost}

## D-104: the relay is automatic on every owned, non-collapsed ring and never
## occupies a wedge slot. _empty_ring always produces an active relay; a ring
## record only ever loses it by being collapsed (relay: {}), set elsewhere.
## D-108: relay_hp/relay_max_hp is a second, separate pool a Sapper drains -
## reaching zero browns out the ring's own power without collapsing it.
static func _empty_ring(dimensions: Dictionary, relay_max_hp: float) -> Dictionary:
	var wedges := {}
	for wedge in range(1, PolarGrid.WEDGE_COUNT + 1):
		wedges[wedge] = {"hp": dimensions.wedge_hp, "max_hp": dimensions.wedge_hp, "slot_count": dimensions.slots_per_wedge, "occupants": {}}
	return {"wedges": wedges, "relay": {"active": true}, "relay_hp": relay_max_hp, "relay_max_hp": relay_max_hp}

static func create_testing_state(profile: BalanceProfile, placements: Array[Dictionary]) -> Dictionary:
	if not valid_profile(profile):
		return failure("Invalid balance profile")
	var count: int = profile.value("starting_test_setup.owned_ring_count")
	if count < 1:
		return failure("Startup needs at least one owned ring")
	var grant := float(profile.value("economy.flak_cost")) * float(profile.value("starting_test_setup.energy_in_flak_purchases"))
	if not is_finite(grant):
		return failure("Starting energy is not finite")
	var state := {"energy": grant, "rings": {}}
	for ring in range(1, count + 1):
		var dimensions := _dimensions(profile, ring)
		if dimensions.is_empty():
			return failure("Unusable startup ring dimensions")
		state.rings[ring] = _empty_ring(dimensions, profile.value("structure.relay_max_hp"))
	var counts := {&"flak": 0}
	for placement in placements:
		for field in ["ring", "wedge", "slot"]:
			if typeof(placement.get(field)) != TYPE_INT:
				return failure("Placement IDs must be integers")
		var kind: Variant = placement.get("kind")
		if typeof(kind) != TYPE_STRING_NAME or not counts.has(kind):
			return failure("Startup kind must be flak StringName")
		if not state.rings.has(placement.ring) or placement.wedge != profile.value("starting_test_setup.%s_wedge" % kind):
			return failure("Startup placement disagrees with configured ring or wedge")
		var record: Dictionary = state.rings[placement.ring]
		var plate: Dictionary = record.wedges[placement.wedge]
		if placement.slot < 0 or placement.slot >= plate.slot_count or plate.occupants.has(placement.slot):
			return failure("Startup slot invalid or occupied")
		plate.occupants[placement.slot] = {"kind": kind}
		counts[kind] += 1
	for kind in counts:
		if counts[kind] != profile.value("starting_test_setup.%s_count" % kind):
			return failure("Explicit starter counts disagree with profile")
	var errors := validate_state(state, profile)
	return {"ok": errors.is_empty(), "state": state if errors.is_empty() else null, "errors": errors}

static func quote_next_ring(state: Dictionary, profile: BalanceProfile, ring_limit: int) -> Dictionary:
	var errors := validate_state(state, profile)
	if not errors.is_empty():
		return {"ok": false, "quote": null, "errors": errors}
	var ring: int = state.rings.size() + 1
	if ring > ring_limit:
		return failure("Ring limit reached", "quote")
	for plate in state.rings[ring - 1].wedges.values():
		if plate.hp <= 0:
			return failure("All inward wedges must be unbroken", "quote")
	var quote := _dimensions(profile, ring)
	if quote.is_empty():
		return failure("Unusable computed ring dimensions or cost", "quote")
	quote.affordable = state.energy >= quote.cost
	quote.merge({"ring": ring})
	return {"ok": true, "quote": quote, "errors": PackedStringArray()}

static func purchase_next_ring(state: Dictionary, profile: BalanceProfile, ring_limit: int) -> Dictionary:
	var result := quote_next_ring(state, profile, ring_limit)
	if not result.ok:
		return {"ok": false, "state": null, "errors": result.errors}
	if not result.quote.affordable:
		return failure("Insufficient energy")
	var updated := state.duplicate(true)
	var quote: Dictionary = result.quote
	updated.rings[quote.ring] = _empty_ring(quote, profile.value("structure.relay_max_hp"))
	updated.energy -= quote.cost
	return {"ok": true, "state": updated, "errors": PackedStringArray()}

## D-022 Tier 2: rebuild a fully collapsed ring at a discount, reusing the same
## whole-ring shape purchase_next_ring produces. Unlike expansion, the target
## ring already exists in state.rings (as a collapsed record); this replaces
## it in place rather than growing state.rings.size().
static func quote_reclaim_ring(state: Dictionary, profile: BalanceProfile, ring: int) -> Dictionary:
	var errors := validate_state(state, profile)
	if not errors.is_empty():
		return {"ok": false, "quote": null, "errors": errors}
	if not state.rings.has(ring) or not state.rings[ring].get("collapsed", false):
		return failure("Ring must be owned and collapsed to reclaim", "quote")
	var quote := _dimensions(profile, ring)
	if quote.is_empty():
		return failure("Unusable computed ring dimensions or cost", "quote")
	var discount: float = profile.value("economy.reclaim_discount")
	quote.cost *= discount
	if float(profile.value("economy.repair_discount")) != 1.0: quote.cost = ceilf(quote.cost)
	if not is_finite(quote.cost) or quote.cost < 0:
		return failure("Unusable computed reclaim cost", "quote")
	quote.affordable = state.energy >= quote.cost
	quote.merge({"ring": ring})
	var candidate := state.duplicate(true)
	candidate.rings[ring] = _empty_ring(quote, profile.value("structure.relay_max_hp"))
	errors = _restoration_frontier_errors(candidate, profile)
	if not errors.is_empty(): return {"ok": false, "quote": null, "errors": errors}
	return {"ok": true, "quote": quote, "errors": PackedStringArray()}

static func reclaim_ring(state: Dictionary, profile: BalanceProfile, ring: int) -> Dictionary:
	var result := quote_reclaim_ring(state, profile, ring)
	if not result.ok:
		return {"ok": false, "state": null, "errors": result.errors}
	if not result.quote.affordable:
		return failure("Insufficient energy")
	var updated := state.duplicate(true)
	var quote: Dictionary = result.quote
	updated.rings[ring] = _empty_ring(quote, profile.value("structure.relay_max_hp"))
	updated.energy -= quote.cost
	return {"ok": true, "state": updated, "errors": PackedStringArray()}

## D-022 Tier 1: heal a damaged (but not collapsed) wedge back to full HP for
## a cost proportional to the HP actually restored. Occupants are untouched —
## breaking a single wedge (unlike a ring collapse) never clears them.
static func quote_repair_wedge(state: Dictionary, profile: BalanceProfile, ring: int, wedge: int) -> Dictionary:
	var errors := validate_state(state, profile)
	if not errors.is_empty():
		return {"ok": false, "quote": null, "errors": errors}
	if not state.rings.has(ring) or state.rings[ring].get("collapsed", false):
		return failure("Ring must be owned and not collapsed", "quote")
	if wedge < 1 or wedge > PolarGrid.WEDGE_COUNT:
		return failure("Invalid wedge", "quote")
	var plate: Dictionary = state.rings[ring].wedges[wedge]
	var missing: float = plate.max_hp - plate.hp
	if missing <= 0:
		return failure("Wedge already at full HP", "quote")
	var cost: float = float(profile.value("economy.ring_plate_base_cost")) * float(ring) * (missing / plate.max_hp)
	if float(profile.value("economy.repair_discount")) != 1.0: cost = ceilf(cost * float(profile.value("economy.repair_discount")))
	if not is_finite(cost) or cost < 0:
		return failure("Unusable computed repair cost", "quote")
	if plate.hp == 0:
		var candidate := state.duplicate(true)
		candidate.rings[ring].wedges[wedge].hp = plate.max_hp
		errors = _restoration_frontier_errors(candidate, profile)
		if not errors.is_empty(): return {"ok": false, "quote": null, "errors": errors}
	return {"ok": true, "quote": {"ring": ring, "wedge": wedge, "cost": cost, "restored_hp": missing, "affordable": state.energy >= cost}, "errors": PackedStringArray()}

static func _restoration_frontier_errors(candidate: Dictionary, profile: BalanceProfile) -> PackedStringArray:
	var horizon: int = candidate.rings.size() + 1
	var built := WallNavigation.build(candidate, horizon, profile)
	if not built.ok: return built.errors
	return TerrainRules.frontier_errors(built.navigation, horizon)

static func repair_wedge(state: Dictionary, profile: BalanceProfile, ring: int, wedge: int) -> Dictionary:
	var result := quote_repair_wedge(state, profile, ring, wedge)
	if not result.ok:
		return {"ok": false, "state": null, "errors": result.errors}
	if not result.quote.affordable:
		return failure("Insufficient energy")
	var updated := state.duplicate(true)
	updated.rings[ring].wedges[wedge].hp = updated.rings[ring].wedges[wedge].max_hp
	updated.energy -= result.quote.cost
	return {"ok": true, "state": updated, "errors": PackedStringArray()}

## D-108: restores a ring's relay_hp pool to full for a flat energy cost -
## the recoverable response to a Sapper browning out a ring's power without
## collapsing it. Never touches wedges/walls/occupants or navigation.
static func quote_rebuild_relay(state: Dictionary, profile: BalanceProfile, ring: int) -> Dictionary:
	var errors := validate_state(state, profile)
	if not errors.is_empty():
		return {"ok": false, "quote": null, "errors": errors}
	if not state.rings.has(ring) or state.rings[ring].get("collapsed", false):
		return failure("Ring must be owned and not collapsed", "quote")
	var record: Dictionary = state.rings[ring]
	if record.relay_hp >= record.relay_max_hp:
		return failure("Relay already at full HP", "quote")
	var cost: float = float(profile.value("economy.rebuild_relay_cost"))
	if not is_finite(cost) or cost < 0:
		return failure("Unusable computed rebuild cost", "quote")
	return {"ok": true, "quote": {"ring": ring, "cost": cost, "affordable": state.energy >= cost}, "errors": PackedStringArray()}

static func rebuild_relay(state: Dictionary, profile: BalanceProfile, ring: int) -> Dictionary:
	var result := quote_rebuild_relay(state, profile, ring)
	if not result.ok:
		return {"ok": false, "state": null, "errors": result.errors}
	if not result.quote.affordable:
		return failure("Insufficient energy")
	var updated := state.duplicate(true)
	updated.rings[ring].relay_hp = updated.rings[ring].relay_max_hp
	updated.energy -= result.quote.cost
	return {"ok": true, "state": updated, "errors": PackedStringArray()}

