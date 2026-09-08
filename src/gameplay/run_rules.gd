class_name RunRules
extends RefCounted

const CAMPAIGN_PATH := "res://data/balance/campaign.json"
const MAX_SAFE_INTEGER := 9007199254740991
const WEAPONS: Array[StringName] = [&"flak", &"mass_driver", &"point_defense", &"emp_node", &"lance_emitter"]

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message]), "profile": null}

static func _whole(value: Variant, minimum: int = 0) -> bool:
	return RingPurchaseRules.number(value) and float(value) >= minimum and float(value) <= MAX_SAFE_INTEGER and floorf(float(value)) == float(value)

static func _campaign() -> Dictionary:
	var file := FileAccess.open(CAMPAIGN_PATH, FileAccess.READ)
	if file == null: return {}
	var raw: Variant = JSON.parse_string(file.get_as_text())
	return raw if raw is Dictionary and _valid_catalogue(raw) else {}

static func _valid_modifier_path(path: Variant) -> bool:
	if not path is String: return false
	var parts: PackedStringArray = path.split(".")
	return parts.size() == 2 and BalanceProfile.SCHEMA.get(parts[0]) is Dictionary and BalanceProfile.SCHEMA[parts[0]].has(parts[1])

static func _valid_catalogue(raw: Dictionary) -> bool:
	if raw.size() != 7: return false
	for group in ["doctrines", "loadouts", "mutators", "unlocks", "upgrades", "reference", "rules"]:
		if not raw.get(group) is Dictionary or raw[group].is_empty(): return false
	for group in ["doctrines", "loadouts", "mutators", "unlocks", "upgrades", "reference"]:
		for id in raw[group]:
			if not id is String or id.is_empty() or not raw[group][id] is Dictionary: return false
			var entry: Dictionary = raw[group][id]
			if not entry.get("label") is String or not entry.get("description") is String: return false
			if group in ["doctrines", "mutators"]:
				if not entry.get("modifiers") is Array: return false
				for mod in entry.modifiers:
					if not mod is Dictionary or mod.size() != 3 or not mod.get("path") is String or mod.get("rounding") not in ["none", "ceil", "nearest"] or not RingPurchaseRules.number(mod.get("factor")) or mod.factor <= 0: return false
					if not _valid_modifier_path(mod.path): return false
			if group == "mutators" and (not RingPurchaseRules.number(entry.get("reward_multiplier")) or entry.reward_multiplier <= 0): return false
			if group == "loadouts" and (entry.get("weapon") not in ["flak", "mass_driver"] or typeof(entry.get("wall")) != TYPE_BOOL): return false
			if group == "unlocks" and (not _whole(entry.get("cost")) or entry.get("category") not in ["build", "ability", "loadout"] or not entry.get("target") is String): return false
			if group == "unlocks":
				if entry.category == "build" and entry.target not in ["emp_node", "tractor_lane", "occlusion_screen", "lance_emitter"]: return false
				if entry.category == "ability" and entry.target != "focused_flare": return false
				if entry.category == "loadout" and not raw.loadouts.has(entry.target): return false
			if group == "upgrades":
				if not _whole(entry.get("max_level"), 1) or entry.max_level > 3 or not entry.get("costs") is Array or entry.costs.size() != entry.max_level: return false
				for cost in entry.costs:
					if not _whole(cost): return false
				if entry.get("operation") not in ["percent", "energy"] or not entry.get("path") is String or not RingPurchaseRules.number(entry.get("amount")) or entry.amount < 0: return false
				if entry.operation == "percent" and not _valid_modifier_path(entry.path): return false
				if entry.operation == "energy" and not _whole(entry.amount): return false
	var rules: Dictionary = raw.rules
	if not _whole(rules.get("starting_energy")) or not rules.get("reward") is Dictionary: return false
	for key in ["starter_build_modes", "structural_modes", "starter_abilities"]:
		if not rules.get(key) is Array: return false
		var seen := {}
		for id in rules[key]:
			if not id is String or id.is_empty() or seen.has(id): return false
			seen[id] = true
			if key == "starter_build_modes" and id not in ["flak", "mass_driver", "point_defense", "emp_node", "lance_emitter", "debris_field", "tractor_lane", "occlusion_screen"]: return false
			if key == "starter_abilities" and id not in ["emp_burst", "focused_flare"]: return false
			if key == "structural_modes" and id not in ["expand", "wall", "armor", "repair_node", "repair", "reclaim", "rebuild_relay"]: return false
	for key in ["seconds_per_unit", "survival_per_unit", "kills_per_unit", "ring_bonus", "survival_challenge_seconds", "survival_challenge_bonus", "kill_challenge_count", "kill_challenge_bonus", "relay_challenge_count", "relay_challenge_bonus"]:
		if not _whole(rules.reward.get(key), 1 if key in ["seconds_per_unit", "kills_per_unit"] else 0): return false
	return raw.doctrines.has("conservator") and raw.loadouts.has("balanced")

static func catalogue() -> Dictionary:
	var result := _campaign()
	result.erase("rules")
	# JSON represents whole numbers as doubles; shop APIs require integer prices.
	for entry in result.get("unlocks", {}).values(): entry.cost = int(entry.cost)
	for entry in result.get("upgrades", {}).values():
		entry.max_level = int(entry.max_level)
		for index in range(entry.costs.size()): entry.costs[index] = int(entry.costs[index])
	return result

static func default_choices() -> Dictionary:
	return {"doctrine": "conservator", "loadout": "balanced", "mutators": []}

static func _modify(raw: Dictionary, path: String, factor: float, rounding: String = "none") -> bool:
	var parts: PackedStringArray = path.split(".")
	if parts.size() != 2 or not raw.get(parts[0]) is Dictionary or not RingPurchaseRules.number(raw[parts[0]].get(parts[1])): return false
	var value: float = float(raw[parts[0]][parts[1]]) * factor
	if not is_finite(value): return false
	if rounding == "ceil": value = ceilf(value)
	elif rounding == "nearest": value = roundf(value)
	raw[parts[0]][parts[1]] = value
	return true

static func prepare(base: BalanceProfile, choices: Dictionary, progress: Dictionary, practice: bool = false) -> Dictionary:
	var data := _campaign()
	if data.is_empty(): return _failure("Invalid campaign catalogue")
	if not RingPurchaseRules.valid_profile(base): return _failure("Invalid base profile")
	if choices.size() != 3 or not choices.get("doctrine") is String or not choices.get("loadout") is String or not choices.get("mutators") is Array: return _failure("Malformed run choices")
	if not data.doctrines.has(choices.doctrine) or not data.loadouts.has(choices.loadout): return _failure("Unknown doctrine or loadout")
	var unlocks: Variant = progress.get("unlocks", [])
	var upgrades: Variant = progress.get("upgrades", {})
	if not unlocks is Array or not upgrades is Dictionary: return _failure("Malformed progression")
	var seen := {}
	for id in unlocks:
		if not id is String or not data.unlocks.has(id) or seen.has(id): return _failure("Unknown or duplicate unlock")
		seen[id] = true
	for id in upgrades:
		if not id is String or not data.upgrades.has(id) or typeof(upgrades[id]) != TYPE_INT or upgrades[id] < 0 or upgrades[id] > data.upgrades[id].max_level: return _failure("Invalid upgrade level")
	if choices.loadout != "balanced" and not practice and choices.loadout not in unlocks: return _failure("Loadout is locked")
	seen = {}
	for id in choices.mutators:
		if not id is String or not data.mutators.has(id) or seen.has(id): return _failure("Unknown or duplicate mutator")
		seen[id] = true
	var normalized := choices.duplicate(true)
	normalized.mutators.sort()
	var raw := base.snapshot()
	var modifiers: Array = data.doctrines[choices.doctrine].modifiers.duplicate(true)
	var multiplier := 1.0
	for id in normalized.mutators:
		modifiers.append_array(data.mutators[id].modifiers)
		multiplier *= float(data.mutators[id].reward_multiplier)
	if not is_finite(multiplier): return _failure("Nonfinite reward multiplier")
	for mod in modifiers:
		if not _modify(raw, mod.path, mod.factor, mod.rounding): return _failure("Invalid campaign modifier")
	var energy: float = data.rules.starting_energy
	for id in upgrades:
		var upgrade: Dictionary = data.upgrades[id]
		if upgrade.operation == "energy": energy += float(upgrade.amount) * upgrades[id]
		elif not _modify(raw, upgrade.path, 1.0 + float(upgrade.amount) * upgrades[id]): return _failure("Invalid upgrade modifier")
	var loaded := BalanceProfile.from_dict(raw)
	if not loaded.ok: return _failure("Invalid computed campaign profile: " + " ".join(loaded.errors))
	var build_modes: Array[StringName] = []
	var abilities: Array[StringName] = []
	for id in data.rules.starter_build_modes + data.rules.structural_modes: build_modes.append(StringName(id))
	for id in data.rules.starter_abilities: abilities.append(StringName(id))
	for id in data.unlocks:
		if not practice and id not in unlocks: continue
		var item: Dictionary = data.unlocks[id]
		if item.category == "build": build_modes.append(StringName(item.target))
		elif item.category == "ability": abilities.append(StringName(item.target))
	var loadout: Dictionary = data.loadouts[choices.loadout]
	if loadout.wall: energy -= float(loaded.profile.value("economy.wall_cost"))
	energy -= maxf(0, float(loaded.profile.value("economy.%s_cost" % loadout.weapon)) - float(loaded.profile.value("economy.flak_cost")))
	if not _whole(energy): return _failure("Invalid computed starting energy")
	return {"ok": true, "errors": PackedStringArray(), "profile": loaded.profile, "build_modes": build_modes, "abilities": abilities, "reward_multiplier": 0.0 if practice else multiplier, "choices": normalized, "starting_energy": int(energy), "practice": practice}

static func create_run(base: BalanceProfile, choices: Dictionary, progress: Dictionary, practice: bool = false, ring_limit: int = 9223372036854775807) -> Dictionary:
	var result := prepare(base, choices, progress, practice)
	if not result.ok: return result
	var made := LiveSimulation.create(result.profile, ring_limit, true, true, true, true, true, true)
	if not made.ok: return _failure("Unable to create configured run: " + " ".join(made.errors))
	var simulation: LiveSimulation = made.simulation
	var loadout: Dictionary = _campaign().loadouts[choices.loadout]
	var wedge: int = result.profile.value("starting_test_setup.flak_wedge")
	simulation.state.energy = result.starting_energy
	simulation.state.rings[1].wedges[wedge].occupants[0].kind = StringName(loadout.weapon)
	if loadout.wall:
		var hp: float = result.profile.value("health.wall_hp")
		simulation.state.rings[1].wedges[12].wall = {"hp": hp, "max_hp": hp}
	var errors := RingPurchaseRules.validate_state(simulation.state, result.profile)
	if not errors.is_empty() or PowerRules.ring_demand(simulation.state, result.profile, 1) > PowerRules.ring_output(simulation.state, result.profile, 1): return _failure("Invalid or unpowered starting loadout")
	simulation.campaign_access = true
	simulation.run_is_practice = practice
	simulation.allowed_build_modes = result.build_modes.duplicate()
	simulation.allowed_abilities = result.abilities.duplicate()
	result.simulation = simulation
	return result

static func reward(summary: Dictionary, multiplier: float = 1.0) -> Dictionary:
	var fail := {"ok": false, "errors": PackedStringArray(["Invalid run summary or reward multiplier"]), "amount": 0, "breakdown": {}}
	if summary.size() != 5 or summary.get("outcome") not in ["defeat", "abandoned", "error", "practice"] or not RingPurchaseRules.number(summary.get("elapsed_seconds")) or summary.elapsed_seconds < 0 or not is_finite(multiplier) or multiplier < 0: return fail
	for key in ["kills", "highest_ring", "relay_rebuilds"]:
		if typeof(summary.get(key)) != TYPE_INT or not _whole(summary[key], 1 if key == "highest_ring" else 0): return fail
	var data := _campaign()
	if data.is_empty(): return fail
	if summary.outcome != "defeat": return {"ok": true, "errors": PackedStringArray(), "amount": 0, "breakdown": {"eligible": false, "outcome": summary.outcome}}
	var r: Dictionary = data.rules.reward
	var breakdown := {"survival": floorf(float(summary.elapsed_seconds) / r.seconds_per_unit) * r.survival_per_unit, "kills": floorf(float(summary.kills) / r.kills_per_unit), "rings": r.ring_bonus * maxi(0, summary.highest_ring - 1), "survive_300": r.survival_challenge_bonus if summary.elapsed_seconds >= r.survival_challenge_seconds else 0.0, "kills_250": r.kill_challenge_bonus if summary.kills >= r.kill_challenge_count else 0.0, "rebuild_relay": r.relay_challenge_bonus if summary.relay_rebuilds >= r.relay_challenge_count else 0.0}
	var subtotal := 0.0
	for value in breakdown.values(): subtotal += float(value)
	var amount := floorf(subtotal * multiplier)
	if not _whole(amount): return fail
	breakdown.subtotal = subtotal
	breakdown.multiplier = multiplier
	breakdown.eligible = true
	return {"ok": true, "errors": PackedStringArray(), "amount": int(amount), "breakdown": breakdown}
