class_name BuildingRules
extends RefCounted

static func create_default_testing_state(profile: BalanceProfile) -> Dictionary:
	if not RingPurchaseRules.valid_profile(profile):
		return RingPurchaseRules.failure("Invalid balance profile")
	if profile.value("starting_test_setup.owned_ring_count") != 1 or profile.value("starting_test_setup.flak_count") != 1:
		return RingPurchaseRules.failure("Default setup requires one ring and Flak; use explicit T-008 placements")
	var placements: Array[Dictionary] = [
		{"ring": 1, "wedge": profile.value("starting_test_setup.flak_wedge"), "slot": 0, "kind": &"flak"},
	]
	return RingPurchaseRules.create_testing_state(profile, placements)

static func slot_position(ring: int, wedge: int, slot: int, slot_count: int) -> PolarPosition:
	if ring < 1 or wedge < 1 or wedge > PolarGrid.WEDGE_COUNT or slot_count < 1 or slot < 0 or slot >= slot_count:
		return null
	return PolarPosition.new(ring, wedge, 0.5, (slot + 0.5) / slot_count)

static func slot_for_fraction(angular_fraction: float, slot_count: int) -> int:
	if not is_finite(angular_fraction) or angular_fraction < 0 or angular_fraction >= 1 or slot_count < 1:
		return -1
	return int(floor(angular_fraction * slot_count))

static func place_weapon(state: Dictionary, profile: BalanceProfile, ring: int, wedge: int, slot: int, kind: StringName) -> Dictionary:
	var errors := RingPurchaseRules.validate_state(state, profile)
	if not errors.is_empty():
		return {"ok": false, "state": null, "errors": errors}
	if kind not in [&"flak", &"mass_driver", &"emp_node", &"lance_emitter", &"point_defense"] or not state.rings.has(ring) or not state.rings[ring].wedges.has(wedge):
		return RingPurchaseRules.failure("Invalid weapon or owned wedge")
	var plate: Dictionary = state.rings[ring].wedges[wedge]
	if plate.hp <= 0 or slot < 0 or slot >= plate.slot_count or plate.occupants.has(slot):
		return RingPurchaseRules.failure("Wedge broken or slot invalid/occupied")
	if not PowerRules.can_afford(state, profile, ring, kind):
		return RingPurchaseRules.failure("Ring lacks power capacity for this weapon")
	var cost: int = profile.value("economy.%s_cost" % kind)
	if state.energy < cost:
		return RingPurchaseRules.failure("Insufficient energy")
	var updated := state.duplicate(true)
	updated.energy -= cost
	updated.rings[ring].wedges[wedge].occupants[slot] = {"kind": kind}
	return {"ok": true, "state": updated, "errors": PackedStringArray()}

## D-027: Armor Plating occupies a normal slot and immediately raises a
## wedge's HP ceiling (and current HP by the same amount), stacking up to
## structure.armor_plating_max_stacks per wedge.
static func place_armor(state: Dictionary, profile: BalanceProfile, ring: int, wedge: int, slot: int) -> Dictionary:
	var errors := RingPurchaseRules.validate_state(state, profile)
	if not errors.is_empty():
		return {"ok": false, "state": null, "errors": errors}
	if not state.rings.has(ring) or not state.rings[ring].wedges.has(wedge):
		return RingPurchaseRules.failure("Invalid owned wedge")
	var plate: Dictionary = state.rings[ring].wedges[wedge]
	if plate.hp <= 0 or slot < 0 or slot >= plate.slot_count or plate.occupants.has(slot):
		return RingPurchaseRules.failure("Wedge broken or slot invalid/occupied")
	var max_stacks: int = profile.value("structure.armor_plating_max_stacks")
	var current_stacks := 0
	for occupant in plate.occupants.values():
		if occupant.kind == &"armor_plating":
			current_stacks += 1
	if current_stacks >= max_stacks:
		return RingPurchaseRules.failure("Armor Plating stack limit reached")
	var cost: int = profile.value("economy.armor_plating_cost")
	if state.energy < cost:
		return RingPurchaseRules.failure("Insufficient energy")
	var bonus: float = profile.value("structure.armor_plating_hp_bonus")
	if not is_finite(float(plate.max_hp) + bonus) or not is_finite(float(plate.hp) + bonus):
		return RingPurchaseRules.failure("Unusable computed armor HP")
	var updated := state.duplicate(true)
	updated.energy -= cost
	var updated_plate: Dictionary = updated.rings[ring].wedges[wedge]
	updated_plate.max_hp += bonus
	updated_plate.hp += bonus
	updated_plate.occupants[slot] = {"kind": &"armor_plating"}
	return {"ok": true, "state": updated, "errors": PackedStringArray()}

## D-027: Repair Node occupies a normal slot; its healing is passive and
## applied per-tick by LiveSimulation, not at placement time.
static func place_repair_node(state: Dictionary, profile: BalanceProfile, ring: int, wedge: int, slot: int) -> Dictionary:
	var errors := RingPurchaseRules.validate_state(state, profile)
	if not errors.is_empty():
		return {"ok": false, "state": null, "errors": errors}
	if not state.rings.has(ring) or not state.rings[ring].wedges.has(wedge):
		return RingPurchaseRules.failure("Invalid owned wedge")
	var plate: Dictionary = state.rings[ring].wedges[wedge]
	if plate.hp <= 0 or slot < 0 or slot >= plate.slot_count or plate.occupants.has(slot):
		return RingPurchaseRules.failure("Wedge broken or slot invalid/occupied")
	var cost: int = profile.value("economy.repair_node_cost")
	if state.energy < cost:
		return RingPurchaseRules.failure("Insufficient energy")
	var updated := state.duplicate(true)
	updated.energy -= cost
	updated.rings[ring].wedges[wedge].occupants[slot] = {"kind": &"repair_node"}
	return {"ok": true, "state": updated, "errors": PackedStringArray()}
