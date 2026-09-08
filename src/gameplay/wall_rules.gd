class_name WallRules
extends RefCounted

static func place(state: Dictionary, profile: BalanceProfile, ring: int, wedge: int) -> Dictionary:
	var errors := RingPurchaseRules.validate_state(state, profile)
	if not errors.is_empty():
		return {"ok": false, "state": null, "errors": errors}
	if ring < 1 or not state.rings.has(ring) or wedge < 1 or wedge > PolarGrid.WEDGE_COUNT:
		return RingPurchaseRules.failure("Wall requires an owned ring and valid wedge")
	var record: Dictionary = state.rings[ring]
	var plate: Dictionary = record.wedges[wedge]
	if record.get("collapsed", false) or plate.hp <= 0:
		return RingPurchaseRules.failure("Wall requires an unbroken supporting wedge")
	if plate.has("wall"):
		return RingPurchaseRules.failure("Outer edge already has a wall")
	var cost: int = profile.value("economy.wall_cost")
	var hp: float = profile.value("health.wall_hp")
	if state.energy < cost:
		return RingPurchaseRules.failure("Insufficient energy")
	var updated := state.duplicate(true)
	updated.energy -= cost
	updated.rings[ring].wedges[wedge].wall = {"hp": hp, "max_hp": hp}
	return {"ok": true, "state": updated, "errors": PackedStringArray()}

# Lightweight query for maintained validated state; placement uses full validation.
static func is_blocking(state: Dictionary, ring: int, wedge: int) -> bool:
	var rings: Dictionary = state.get("rings", {})
	if not rings.has(ring): return false
	var record: Dictionary = rings[ring]
	if record.get("collapsed", false) or not record.wedges.has(wedge): return false
	var plate: Dictionary = record.wedges[wedge]
	return plate.hp > 0 and plate.has("wall") and plate.wall.hp > 0
