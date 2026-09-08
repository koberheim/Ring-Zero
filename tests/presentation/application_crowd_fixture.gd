extends RefCounted
## Exact T068 durable fixture copied for rendered comparison; no production overrides.
const SURFACE: Array[StringName] = [&"normal", &"foundry", &"transfer", &"sapper", &"breacher", &"assembler"]
var errors := PackedStringArray()
func _require(result: Dictionary, label: String) -> bool:
	if result.get("ok", false): return true
	errors.append(label + ": " + str(result.get("errors", [])))
	return false

func _fixture(base: BalanceProfile, rings: int, count: int) -> LiveSimulation:
	var changes := {"pressure":{"spawn_per_second":60, "spawn_delay_seconds":0, "max_active_machines":count}, "health":{"wedge_base_hp":1e9, "core_hp":1e9, "wall_hp":1e9}, "power":{"base_output":150.0 * rings}}
	for kind in [&"tunneler", &"foundry", &"transfer", &"sapper", &"breacher", &"assembler"]:
		changes[String(kind)] = {"first_arrival_seconds":0.1, "arrival_interval_seconds":1.0}
	changes.assembler = {"first_arrival_seconds":0.1, "interval_seconds":1.0}
	var tuned := base.with_overrides(changes)
	if not _require(tuned, "profile"): return null
	var created := LiveSimulation.create(tuned.profile, rings, true, true, true, true, true, true)
	if not _require(created, "create"): return null
	var sim: LiveSimulation = created.simulation
	sim.state.energy = 1e9
	for ring in range(2, rings + 1):
		if not _require(sim.purchase_ring(), "ring purchase"): return null
	for wedge in [1, 3, 5, 7, 9]:
		if not _require(sim.place_wall(rings, wedge), "wall"): return null
	for entry in [[11, &"debris_field"], [4, &"tractor_lane"], [2, &"occlusion_screen"]]:
		if not _require(sim.place_terrain(rings, entry[0], 0, entry[1]), "terrain"): return null
	var weapons: Array[StringName] = [&"flak", &"mass_driver", &"emp_node", &"lance_emitter", &"point_defense"]
	for index in weapons.size():
		if not _require(sim.place_weapon(rings, index + 6, 0, weapons[index]), "weapon"): return null
	var kinds: Array[StringName] = SURFACE.duplicate()
	if rings >= 2: kinds.append(&"tunneler")
	for index in count:
		var kind: StringName = kinds[index % kinds.size()]
		var wedge: int = index % 12 + 1
		var position := PolarPosition.new(rings + 1, wedge, 0.0 if index % 2 == 0 else 0.2, 0.5)
		var payload := {"position":position, "hp":1e9, "damage_per_second":0.01, "speed_ring_widths_per_second":1.0, "assimilation_stacks":[10.0] if index % 3 == 0 else [], "stun_remaining":0.2 if index % 5 == 0 else 0.0}
		if kind != &"normal": payload.kind = kind
		if kind == &"transfer": payload.hopped = false
		if kind == &"assembler": payload.growth_stacks = 1
		if kind == &"tunneler":
			payload.position = PolarPosition.new(rings + 1, wedge, 0.0, 0.5)
			payload.start_position = PolarPosition.new(rings + 1, wedge, 0.0, 0.5)
			payload.destination = PolarPosition.new(rings - 1, wedge, 0.5, 0.5)
			payload.surface_cell = Vector2i(rings - 1, wedge)
			payload.phase = &"burrowing"
			payload.targetable = false
			payload.burrow_elapsed_seconds = 0.0
			payload.burrow_duration_seconds = 2.0
			if index % 2 == 0:
				payload.position = PolarPosition.new(rings - 1, wedge, 0.5, 0.5)
				payload.phase = &"surface_attack"
				payload.targetable = true
				payload.burrow_elapsed_seconds = 2.0
		if sim.pool.spawn(payload) < 0:
			errors.append("Fixture admission failed")
			return null
	return sim

func _counts(sim: LiveSimulation) -> Dictionary:
	var counts := {"active":sim.pool.active_count(), "kinds":{}, "stunned":0, "assimilated":0, "burrowing":0, "surface_attack":0, "roaming":0, "hopped":0}
	for target in sim.targets_snapshot():
		var kind := String(target.get("kind", &"normal"))
		counts.kinds[kind] = counts.kinds.get(kind, 0) + 1
		if target.stun_remaining > 0: counts.stunned += 1
		if not target.assimilation_stacks.is_empty(): counts.assimilated += 1
		if target.get("phase") == &"burrowing": counts.burrowing += 1
		if target.get("phase") == &"surface_attack": counts.surface_attack += 1
		if target.get("phase") == &"roaming": counts.roaming += 1
		if target.get("hopped", false): counts.hopped += 1
	return counts

