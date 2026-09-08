class_name TerrainRules
extends RefCounted

const KINDS: Array[StringName] = [&"debris_field", &"tractor_lane", &"occlusion_screen"]

static func _active_plate(state: Dictionary, ring: int, wedge: int) -> Dictionary:
	if not state.rings.has(ring) or not state.rings[ring].wedges.has(wedge): return {}
	var record: Dictionary = state.rings[ring]
	var plate: Dictionary = record.wedges[wedge]
	return plate if not record.get("collapsed", false) and plate.hp > 0 else {}

static func is_debris_blocking(state: Dictionary, ring: int, wedge: int) -> bool:
	var plate := _active_plate(state, ring, wedge)
	for occupant in plate.get("occupants", {}).values():
		if occupant.kind == &"debris_field": return true
	return false

static func tractor_direction(state: Dictionary, ring: int, wedge: int) -> int:
	var plate := _active_plate(state, ring, wedge)
	for occupant in plate.get("occupants", {}).values():
		if occupant.kind == &"tractor_lane": return occupant.direction
	return 0

static func has_screen(state: Dictionary, ring: int, wedge: int) -> bool:
	var plate := _active_plate(state, ring, wedge)
	for occupant in plate.get("occupants", {}).values():
		if occupant.kind == &"occlusion_screen": return true
	return false

static func surface_speed_multiplier(state: Dictionary, profile: BalanceProfile, position: PolarPosition) -> float:
	var span: int = profile.value("occlusion_screen.shadow_rings")
	for ring in range(maxi(1, position.ring - span), mini(position.ring, state.rings.size() + 1)):
		if has_screen(state, ring, position.wedge): return float(profile.value("occlusion_screen.speed_multiplier"))
	return 1.0

static func frontier_errors(navigation: WallNavigation, horizon: int) -> PackedStringArray:
	for wedge in range(1, PolarGrid.WEDGE_COUNT + 1):
		if not navigation.route_for(Vector2i(horizon, wedge)).ok:
			return PackedStringArray(["Terrain would seal the outer frontier"])
	return PackedStringArray()

static func place(state: Dictionary, profile: BalanceProfile, ring: int, wedge: int, slot: int, kind: StringName, direction: int = 1) -> Dictionary:
	var errors := RingPurchaseRules.validate_state(state, profile)
	if not errors.is_empty(): return {"ok": false, "state": null, "errors": errors}
	if kind not in KINDS or not state.rings.has(ring) or not state.rings[ring].wedges.has(wedge):
		return RingPurchaseRules.failure("Invalid terrain or owned wedge")
	var plate: Dictionary = state.rings[ring].wedges[wedge]
	if plate.hp <= 0 or slot < 0 or slot >= plate.slot_count or plate.occupants.has(slot):
		return RingPurchaseRules.failure("Wedge broken or slot invalid/occupied")
	if kind == &"tractor_lane":
		if direction not in [-1, 1]: return RingPurchaseRules.failure("Tractor direction must be -1 or 1")
		if tractor_direction(state, ring, wedge) != 0: return RingPurchaseRules.failure("Wedge already has a Tractor Lane")
	var cost: int = profile.value("economy.%s_cost" % kind)
	if state.energy < cost: return RingPurchaseRules.failure("Insufficient energy")
	var updated := state.duplicate(true)
	var occupant := {"kind": kind}
	if kind == &"tractor_lane": occupant.direction = direction
	updated.rings[ring].wedges[wedge].occupants[slot] = occupant
	updated.energy -= cost
	var horizon: int = updated.rings.size() + 1
	var built := WallNavigation.build(updated, horizon, profile)
	if not built.ok: return {"ok": false, "state": null, "errors": built.errors}
	errors = frontier_errors(built.navigation, horizon)
	return {"ok": errors.is_empty(), "state": updated if errors.is_empty() else null, "errors": errors}

