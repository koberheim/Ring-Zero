extends SceneTree
## T068 explicit durable mixed fixture; no baseline writes or production overrides.
const DT := 1.0 / 60.0
const WARMUP := 3
const SAMPLES := 20
const SURFACE: Array[StringName] = [&"normal", &"foundry", &"transfer", &"sapper", &"breacher", &"assembler"]
var errors := PackedStringArray()
var rows: Array[Dictionary] = []

func _initialize() -> void:
	var loaded := BalanceProfile.load_json("res://data/balance/testing.json")
	if not loaded.ok:
		push_error("Cannot load testing profile")
		quit(1)
		return
	for rings in [1, 6, 12]:
		for count in [100, 500, 1000]:
			for forced_ready in [false, true]:
				var row := _measure(loaded.profile, rings, count, forced_ready)
				rows.append(row)
				print(JSON.stringify(row))
				if not row.ok:
					quit(1)
					return
	print("T068 whole-step probe: %d fixtures; failures=%d; headless only; no baseline written" % [rows.size(), errors.size()])
	quit(0 if errors.is_empty() else 1)

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

func _skipped(sim: LiveSimulation) -> Dictionary:
	return {"normal":sim.skipped_arrivals, "tunneler":sim.skipped_tunneler_arrivals, "foundry":sim.skipped_foundry_arrivals, "transfer":sim.skipped_transfer_arrivals, "sapper":sim.skipped_sapper_arrivals, "breacher":sim.skipped_breacher_arrivals, "assembler":sim.skipped_assembler_arrivals}

func _measure(base: BalanceProfile, rings: int, count: int, forced_ready: bool) -> Dictionary:
	var sim := _fixture(base, rings, count)
	if sim == null: return {"ok":false, "errors":errors}
	var initial := _counts(sim)
	var times: Array[int] = []
	var hits: Array[int] = []
	var rebuilds: Array[int] = []
	var spawned := 0
	var total_kills := 0
	var topology_sample := 10
	var topology_command_us := 0
	for tick in range(WARMUP + SAMPLES):
		# Explicit synthetic peak-work comparison; natural mode keeps real cadence.
		if forced_ready: sim.cooldowns = {}
		if tick == WARMUP + topology_sample:
			var command_started := Time.get_ticks_usec()
			var command := sim.place_wall(rings, 2)
			topology_command_us = Time.get_ticks_usec() - command_started
			if not _require(command, "mid-window topology command"): return {"ok":false, "errors":errors}
		var before_rebuild := sim.route_rebuild_count
		var started := Time.get_ticks_usec()
		var result := sim.step(DT)
		var duration := Time.get_ticks_usec() - started
		if not _require(result, "step") or sim.ended or sim.pool.active_count() != count:
			return {"ok":false, "errors":errors, "rings":rings, "requested_actors":count, "forced_ready":forced_ready, "tick_index":tick, "elapsed_seconds":sim.elapsed_seconds, "active":sim.pool.active_count(), "ended":sim.ended}
		spawned += result.events.spawned_ids.size()
		total_kills += result.events.kill_ids.size()
		if tick >= WARMUP:
			times.append(duration)
			hits.append(result.events.hits.size())
			rebuilds.append(sim.route_rebuild_count - before_rebuild)
	var ordered := times.duplicate()
	ordered.sort()
	var total_usec := 0
	for duration in times: total_usec += duration
	return {"ok":true, "rings":rings, "requested_actors":count, "mode":"forced_ready" if forced_ready else "normal_cadence", "warmup":WARMUP, "samples":SAMPLES, "step_seconds":DT, "median_ms":(ordered[9] + ordered[10]) / 2000.0, "p95_ms":ordered[18] / 1000.0, "max_ms":ordered[19] / 1000.0, "step_cpu_simulation_rate":SAMPLES * DT / (total_usec / 1e6), "initial":initial, "final":_counts(sim), "skipped":_skipped(sim), "spawned":spawned, "kills":total_kills, "hits":hits, "route_rebuilds":rebuilds, "topology_sample":topology_sample, "topology_command_us":topology_command_us, "raw_us":times, "tunneler_omission":"no valid two-band burrow at one ring" if rings == 1 else ""}
