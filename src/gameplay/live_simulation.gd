class_name LiveSimulation
extends RefCounted

# Split only at a shadow-speed boundary; the caller retains its route waypoint.
# Exact boundaries sample the open interval immediately ahead of travel.
static func _motion_interval(p: PolarPosition, destination: PolarPosition, navigation: WallNavigation) -> Dictionary:
	var cell := Vector2i(p.ring, p.wedge)
	var stop := destination
	var boundary := false
	if p.ring != destination.ring or p.radial_fraction != destination.radial_fraction:
		var inward := float(destination.ring) + destination.radial_fraction < float(p.ring) + p.radial_fraction
		if inward and p.radial_fraction == 0: cell.x -= 1
	else:
		var delta := fposmod(float(destination.wedge - p.wedge) + destination.angular_fraction - p.angular_fraction + 6.0, 12.0) - 6.0
		if delta > 0:
			var remaining := 1.0 - p.angular_fraction
			if delta > remaining:
				stop = PolarPosition.new(p.ring, p.wedge % 12 + 1, p.radial_fraction, 0.0)
				boundary = true
		elif delta < 0:
			var remaining := p.angular_fraction if p.angular_fraction > 0 else 1.0
			if p.angular_fraction == 0: cell.y = (p.wedge + 10) % 12 + 1
			if -delta > remaining:
				stop = PolarPosition.new(p.ring, p.wedge if p.angular_fraction > 0 else cell.y, p.radial_fraction, 0.0)
				boundary = true
	return {"destination": stop, "multiplier": navigation.surface_speed(cell), "boundary": boundary}

const FIXED_STEP := 1.0 / 60.0
const MAX_INTEGER := 9223372036854775807
var state: Dictionary
var core_hp: float
var elapsed_seconds := 0.0
var ended := false
var cooldowns: Dictionary = {}
var ability_cooldowns: Dictionary = {}
var last_events: Dictionary = _empty_events()
var pool: EntityPool
var profile: BalanceProfile
var ring_limit: int
var skipped_arrivals := 0
var skipped_tunneler_arrivals := 0
var total_kills := 0
var highest_owned_ring := 1
var relay_rebuild_count := 0
var _transfer_navigation: Dictionary = {}
var allowed_build_modes: Array[StringName] = []
var allowed_abilities: Array[StringName] = []
var campaign_access := false
var run_is_practice := false

var tunnelers_enabled := false
var foundry_enabled := false
var skipped_foundry_arrivals := 0
var transfer_enabled := false
var skipped_transfer_arrivals := 0
var sapper_enabled := false
var skipped_sapper_arrivals := 0
var breacher_enabled := false
var skipped_breacher_arrivals := 0
var assembler_enabled := false
var skipped_assembler_arrivals := 0
const TUNNELER_FIELDS := ["kind", "phase", "targetable", "start_position", "destination", "surface_cell", "burrow_elapsed_seconds", "burrow_duration_seconds"]
const TRANSFER_FIELDS := ["hopped", "hop_cell"]
# Union used by generic per-tick field copy and by malformed-field guards; the
# strict tunneler-required check below still uses TUNNELER_FIELDS alone.
const KIND_FIELDS := ["kind", "phase", "targetable", "start_position", "destination", "surface_cell", "burrow_elapsed_seconds", "burrow_duration_seconds", "hopped", "hop_cell", "growth_stacks"]
var _ticks := 0
var _navigation: WallNavigation
var _nav_fingerprint := PackedByteArray()
var _nav_horizon := 0
var _waypoints: Dictionary = {}
var route_rebuild_count := 0
# Opt-in bounded review instrumentation; normal gameplay does not read the clock.
var _measure_costs := false
var _last_step_costs: Dictionary = {}

static func _empty_events() -> Dictionary:
	var ids: Array[int] = []
	var kills: Array[int] = []
	var broken: Array[Vector2i] = []
	var collapsed: Array[int] = []
	var hits: Array[Dictionary] = []
	var walls: Array[Vector2i] = []
	var relays_lost: Array[int] = []
	return {"walls_broken": walls, "spawned_ids": ids, "kill_ids": kills, "broken_wedges": broken, "collapsed_rings": collapsed, "relays_lost": relays_lost, "hits": hits, "energy_awarded": 0.0, "core_lost": false}

static func create(source_profile: BalanceProfile, limit: int, include_tunnelers: bool = false, include_foundry: bool = false, include_transfer: bool = false, include_sapper: bool = false, include_breacher: bool = false, include_assembler: bool = false) -> Dictionary:
	if not RingPurchaseRules.valid_profile(source_profile) or limit < 1:
		return {"ok": false, "simulation": null, "errors": PackedStringArray(["Valid profile and positive ring limit required"])}
	var copied_profile: BalanceProfile = BalanceProfile.from_dict(source_profile.snapshot()).profile
	var created := BuildingRules.create_default_testing_state(copied_profile)
	if not created.ok:
		return {"ok": false, "simulation": null, "errors": created.errors}
	var empty: Array[Dictionary] = []
	var weapon_check := WeaponRules.step(created.state, copied_profile, empty, {}, FIXED_STEP)
	if not weapon_check.ok or not is_finite(float(copied_profile.value("pressure.speed_ring_widths_per_second")) * PolarGrid.RING_WIDTH):
		return {"ok": false, "simulation": null, "errors": PackedStringArray(["Unusable computed weapon range or machine speed"])}
	var simulation := LiveSimulation.new()
	simulation.profile = copied_profile
	simulation.ring_limit = limit
	simulation.tunnelers_enabled = include_tunnelers
	simulation.foundry_enabled = include_foundry
	simulation.transfer_enabled = include_transfer
	simulation.sapper_enabled = include_sapper
	simulation.breacher_enabled = include_breacher
	simulation.assembler_enabled = include_assembler
	simulation.state = created.state
	simulation.core_hp = copied_profile.value("health.core_hp")
	simulation.pool = EntityPool.new(copied_profile.value("pressure.max_active_machines"))
	return {"ok": true, "simulation": simulation, "errors": PackedStringArray()}

static func _target_record(id: int, payload: Dictionary, copy_position: bool = true) -> Dictionary:
	var p: PolarPosition = payload.position
	var stacks: Variant = payload.get("assimilation_stacks", [])
	if copy_position and stacks is Array: stacks = stacks.duplicate(true)
	var result := {"id": id, "position": PolarPosition.new(p.ring, p.wedge, p.radial_fraction, p.angular_fraction) if copy_position else p, "hp": payload.hp, "damage_per_second": payload.damage_per_second, "speed_ring_widths_per_second": payload.speed_ring_widths_per_second, "assimilation_stacks": stacks, "stun_remaining": payload.get("stun_remaining", 0.0)}
	if payload.size() > 6:
		for field in KIND_FIELDS:
			if payload.has(field):
				var value: Variant = payload[field]
				result[field] = PolarPosition.new(value.ring, value.wedge, value.radial_fraction, value.angular_fraction) if copy_position and value is PolarPosition else value
	return result

func targets_snapshot() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for id in pool.active_ids(): targets.append(_target_record(id, pool.payload_for(id)))
	return targets
func _step_targets() -> Array[Dictionary]:
	# Astra verified PolarMotion and WeaponRules never mutate input positions.
	# Private staging may retain those read-only references until motion replaces
	# them. Owned combat changes only scratch HP; public snapshots always clone positions.
	var targets: Array[Dictionary] = []
	for id in pool.active_ids(): targets.append(_target_record(id, pool.payload_for(id), false))
	return targets

func run_summary(outcome: String = "defeat") -> Dictionary:
	return {"outcome": "practice" if run_is_practice else outcome, "elapsed_seconds": elapsed_seconds, "kills": total_kills, "highest_ring": highest_owned_ring, "relay_rebuilds": relay_rebuild_count}

func abilities_snapshot() -> Dictionary:
	return ability_cooldowns.duplicate(true)

func cast_ability(kind: StringName, aim: PolarPosition) -> Dictionary:
	var events := _empty_events()
	if campaign_access and kind not in allowed_abilities: return {"ok": false, "errors": PackedStringArray(["Ability is locked"]), "events": events}
	if ended: return {"ok": false, "errors": PackedStringArray(["Run ended"]), "events": events}
	var errors := RingPurchaseRules.validate_state(state, profile)
	if not errors.is_empty(): return {"ok": false, "errors": errors, "events": events}
	var horizon: int = state.rings.size() + 1
	for id in pool.active_ids():
		var payload := pool.payload_for(id)
		if not WeaponRules._valid_position(payload.get("position")) or not WeaponRules._valid_statuses(payload) or not RingPurchaseRules.number(payload.get("hp")) or payload.hp < 0 or not RingPurchaseRules.number(payload.get("damage_per_second")) or payload.damage_per_second < 0 or not RingPurchaseRules.number(payload.get("speed_ring_widths_per_second")) or payload.speed_ring_widths_per_second <= 0:
			return {"ok": false, "errors": PackedStringArray(["Malformed live ability target"]), "events": events}
		horizon = maxi(horizon, payload.position.ring)
	var targets := _step_targets()
	# A local validation graph never replaces or mutates the live route cache.
	var built := WallNavigation.build(state, horizon, profile)
	if not built.ok: return {"ok": false, "errors": built.errors, "events": events}
	for target in targets:
		if not _valid_machine_source(target, built.navigation, state.rings.size()):
			return {"ok": false, "errors": PackedStringArray(["Invalid live ability target lifecycle or cell"]), "events": events}
	var result := AbilityRules.cast(profile, targets, ability_cooldowns, kind, aim)
	if not result.ok: return {"ok": false, "errors": result.errors, "events": events}
	if total_kills > MAX_INTEGER - result.kill_ids.size(): return {"ok": false, "errors": PackedStringArray(["Run kill counter overflow"]), "events": events}
	# Commit only scalar combat state; commands do not move entities or time.
	for target in result.targets:
		var payload := pool.payload_for(target.id)
		payload.hp = target.hp
		payload.stun_remaining = target.get("stun_remaining", 0.0)
	for id in result.kill_ids: pool.release(id)
	ability_cooldowns = result.cooldowns
	total_kills += result.kill_ids.size()
	events.hits = result.hits
	events.kill_ids = result.kill_ids
	return {"ok": true, "errors": PackedStringArray(), "events": events.duplicate(true)}

func outer_owned_ring() -> int:
	for ring in range(state.rings.size(), 0, -1):
		if not state.rings[ring].get("collapsed", false): return ring
	return 0

func quote_expansion() -> Dictionary:
	if ended: return RingPurchaseRules.failure("Run ended", "quote")
	var candidate: int = state.rings.size() + 1
	for id in pool.active_ids():
		var machine := pool.payload_for(id)
		if machine.hp > 0 and machine.position.ring == candidate:
			return RingPurchaseRules.failure("Living machine occupies candidate ring", "quote")
	return RingPurchaseRules.quote_next_ring(state, profile, ring_limit)

func purchase_ring() -> Dictionary:
	var quote := quote_expansion()
	if not quote.ok: return {"ok": false, "state": null, "errors": quote.errors}
	var purchased := RingPurchaseRules.purchase_next_ring(state, profile, ring_limit)
	if purchased.ok:
		state = purchased.state
		highest_owned_ring = maxi(highest_owned_ring, state.rings.size())
		purchased.state = state.duplicate(true)
	return purchased

func place_weapon(ring: int, wedge: int, slot: int, kind: StringName) -> Dictionary:
	if campaign_access and kind not in allowed_build_modes: return RingPurchaseRules.failure("Building is locked")
	if ended: return RingPurchaseRules.failure("Run ended")
	var placed := BuildingRules.place_weapon(state, profile, ring, wedge, slot, kind)
	if placed.ok:
		state = placed.state
		placed.state = state.duplicate(true)
	return placed

func place_armor(ring: int, wedge: int, slot: int) -> Dictionary:
	if ended: return RingPurchaseRules.failure("Run ended")
	var placed := BuildingRules.place_armor(state, profile, ring, wedge, slot)
	if placed.ok:
		state = placed.state
		placed.state = state.duplicate(true)
	return placed

func place_repair_node(ring: int, wedge: int, slot: int) -> Dictionary:
	if ended: return RingPurchaseRules.failure("Run ended")
	var placed := BuildingRules.place_repair_node(state, profile, ring, wedge, slot)
	if placed.ok:
		state = placed.state
		placed.state = state.duplicate(true)
	return placed

func place_wall(ring: int, wedge: int) -> Dictionary:
	if ended: return RingPurchaseRules.failure("Run ended")
	var placed := WallRules.place(state, profile, ring, wedge)
	if placed.ok:
		state = placed.state
		placed.state = state.duplicate(true)
	return placed

func quote_reclaim(ring: int) -> Dictionary:
	if ended: return RingPurchaseRules.failure("Run ended", "quote")
	for id in pool.active_ids():
		var machine := pool.payload_for(id)
		if machine.hp > 0 and machine.position.ring == ring:
			return RingPurchaseRules.failure("Living machine occupies candidate ring", "quote")
	var quote := RingPurchaseRules.quote_reclaim_ring(state, profile, ring)
	if not quote.ok: return quote
	# Only the isolated validation candidate receives sufficient preview funds.
	var preview := state.duplicate(true)
	preview.energy = maxf(float(preview.energy), float(quote.quote.cost))
	var restored := RingPurchaseRules.reclaim_ring(preview, profile, ring)
	if not restored.ok: return RingPurchaseRules.failure("Invalid reclaim preview", "quote")
	var errors := _terrain_candidate_errors(restored.state)
	return quote if errors.is_empty() else {"ok": false, "quote": null, "errors": errors}

func reclaim_ring(ring: int) -> Dictionary:
	var quote := quote_reclaim(ring)
	if not quote.ok: return {"ok": false, "state": null, "errors": quote.errors}
	var reclaimed := RingPurchaseRules.reclaim_ring(state, profile, ring)
	if reclaimed.ok:
		state = reclaimed.state
		reclaimed.state = state.duplicate(true)
	return reclaimed

func quote_repair(ring: int, wedge: int) -> Dictionary:
	if ended: return RingPurchaseRules.failure("Run ended", "quote")
	var quote := RingPurchaseRules.quote_repair_wedge(state, profile, ring, wedge)
	if not quote.ok: return quote
	if state.rings[ring].wedges[wedge].hp == 0:
		for id in pool.active_ids():
			var machine := pool.payload_for(id)
			if machine.hp > 0 and machine.position.ring == ring and machine.position.wedge == wedge:
				return RingPurchaseRules.failure("Living machine occupies broken wedge", "quote")
		var preview := state.duplicate(true)
		preview.rings[ring].wedges[wedge].hp = preview.rings[ring].wedges[wedge].max_hp
		var errors := _terrain_candidate_errors(preview)
		if not errors.is_empty(): return {"ok": false, "quote": null, "errors": errors}
	return quote

func repair_wedge(ring: int, wedge: int) -> Dictionary:
	var quote := quote_repair(ring, wedge)
	if not quote.ok: return {"ok": false, "state": null, "errors": quote.errors}
	var repaired := RingPurchaseRules.repair_wedge(state, profile, ring, wedge)
	if repaired.ok:
		state = repaired.state
		repaired.state = state.duplicate(true)
	return repaired

func quote_rebuild_relay(ring: int) -> Dictionary:
	if ended: return RingPurchaseRules.failure("Run ended", "quote")
	return RingPurchaseRules.quote_rebuild_relay(state, profile, ring)

func rebuild_relay(ring: int) -> Dictionary:
	var quote := quote_rebuild_relay(ring)
	if not quote.ok: return {"ok": false, "state": null, "errors": quote.errors}
	if relay_rebuild_count == MAX_INTEGER: return RingPurchaseRules.failure("Relay rebuild counter overflow")
	var rebuilt := RingPurchaseRules.rebuild_relay(state, profile, ring)
	if rebuilt.ok:
		state = rebuilt.state
		relay_rebuild_count += 1
		rebuilt.state = state.duplicate(true)
	return rebuilt

func place_terrain(ring: int, wedge: int, slot: int, kind: StringName, direction: int = 1) -> Dictionary:
	if campaign_access and kind not in allowed_build_modes: return RingPurchaseRules.failure("Building is locked")
	if ended: return RingPurchaseRules.failure("Run ended")
	var placed := TerrainRules.place(state, profile, ring, wedge, slot, kind, direction)
	if not placed.ok: return placed
	var errors := _terrain_candidate_errors(placed.state)
	if not errors.is_empty(): return {"ok": false, "state": null, "errors": errors}
	state = placed.state
	placed.state = state.duplicate(true)
	return placed

func _terrain_candidate_errors(candidate: Dictionary) -> PackedStringArray:
	var horizon: int = candidate.rings.size() + 1
	for id in pool.active_ids():
		var machine := pool.payload_for(id)
		if machine.hp > 0: horizon = maxi(horizon, machine.position.ring)
	var built := WallNavigation.build(candidate, horizon, profile)
	if not built.ok: return built.errors
	var errors := TerrainRules.frontier_errors(built.navigation, horizon)
	if not errors.is_empty(): return errors
	for id in pool.active_ids():
		var machine := pool.payload_for(id)
		if machine.hp <= 0: continue
		if machine.get("kind") == &"tunneler" and machine.get("phase") in [&"burrowing", &"surface_attack"]: continue
		if machine.get("kind") == &"transfer" and machine.get("hopped", false):
			var hop_cell: Vector2i = machine.get("hop_cell", Vector2i(-1, -1))
			if machine.position.ring == hop_cell.x: continue
		if not built.navigation.route_for(Vector2i(machine.position.ring, machine.position.wedge)).ok:
			return PackedStringArray(["Terrain would trap a living surface machine"])
	return PackedStringArray()

func _failed_tick(errors: PackedStringArray, admitted: Array[int] = []) -> Dictionary:
	# Admissions are tentative until commit. Their consumed lifetime IDs stay spent.
	for id in admitted: pool.release(id)
	return {"ok": false, "errors": errors, "events": _empty_events()}

func step(delta_seconds: float) -> Dictionary:
	var measured_start := Time.get_ticks_usec() if _measure_costs else 0
	if not is_finite(delta_seconds) or delta_seconds <= 0 or absf(delta_seconds - FIXED_STEP) > 1e-12:
		return _failed_tick(PackedStringArray(["Step must equal positive 1/60 second within 1e-12"]))
	if ended:
		last_events = _empty_events()
		return {"ok": true, "errors": PackedStringArray(), "events": last_events.duplicate(true)}
	var errors := RingPurchaseRules.validate_state(state, profile)
	if not errors.is_empty(): return _failed_tick(errors)
	if not AbilityRules.valid_cooldowns(ability_cooldowns): return _failed_tick(PackedStringArray(["Malformed ability cooldowns"]))
	var staged_abilities := ability_cooldowns.duplicate(true)
	for key in staged_abilities:
		var remaining := maxf(0.0, float(staged_abilities[key]) - FIXED_STEP)
		staged_abilities[key] = 0.0 if remaining <= WeaponRules.COOLDOWN_EPSILON else remaining
	if _ticks == MAX_INTEGER: return _failed_tick(PackedStringArray(["Tick counter overflow"]))
	var next_elapsed := float(_ticks + 1) / 60.0
	if not is_finite(1.0 + float(profile.value("assimilation.bonus_per_stack")) * float(profile.value("assimilation.max_stacks"))) or not is_finite(next_elapsed + float(profile.value("assimilation.stack_seconds"))):
		return _failed_tick(PackedStringArray(["Unusable computed assimilation effect or expiry"]))
	var arrivals := MachineSpawnRules.arrivals_between(profile, elapsed_seconds, next_elapsed)
	if not arrivals.ok: return _failed_tick(arrivals.errors)
	var admission := _admission_plan(arrivals, next_elapsed)
	if not admission.ok: return _failed_tick(admission.errors)
	var skipped: int = admission.skipped
	var skipped_tunnelers: int = admission.skipped_tunnelers
	var skipped_foundry: int = admission.skipped_foundry
	var skipped_transfer: int = admission.skipped_transfer
	var skipped_sapper: int = admission.skipped_sapper
	var skipped_breacher: int = admission.skipped_breacher
	var skipped_assembler: int = admission.skipped_assembler
	var descriptors: Array[Dictionary] = admission.descriptors
	var context := {"navigation": _navigation, "fingerprint": _nav_fingerprint, "horizon": _nav_horizon, "waypoints": _waypoints.duplicate(), "rebuilds": route_rebuild_count, "dirty": false, "measure": _measure_costs, "motion_us": 0, "attack_calls": 0, "assimilation_grants": 0, "transfer_navigation": _transfer_navigation.duplicate(), "errors": PackedStringArray()}
	var required_horizon: int = state.rings.size() + 1
	for id in pool.active_ids():
		if not WeaponRules._valid_statuses(pool.payload_for(id)): return _failed_tick(PackedStringArray(["Malformed target status"]))
	for descriptor in descriptors:
		if not WeaponRules._valid_statuses(descriptor): return _failed_tick(PackedStringArray(["Malformed spawn status"]))
	var existing := _step_targets()
	for target in existing: required_horizon = maxi(required_horizon, target.position.ring)
	for descriptor in descriptors: required_horizon = maxi(required_horizon, descriptor.position.ring)
	var nav_errors := _ensure_navigation(state, context, required_horizon, profile)
	if not nav_errors.is_empty(): return _failed_tick(nav_errors)
	for target in existing:
		if not _valid_machine_source(target, context.navigation, state.rings.size()): return _failed_tick(PackedStringArray(["Machine occupies invalid or intact cell interior"]))
	for descriptor in descriptors:
		if not _valid_machine_source(descriptor, context.navigation, state.rings.size()): return _failed_tick(PackedStringArray(["Spawn occupies invalid or intact cell interior"]))
	var events := _empty_events()
	var active_time := {}
	for descriptor in descriptors:
		var payload := _target_record(0, descriptor, false)
		payload.erase("id")
		var id := pool.spawn(payload)
		if id < 0: return _failed_tick(PackedStringArray(["Unexpected pool admission failure"]), events.spawned_ids)
		events.spawned_ids.append(id)
		existing.append(_target_record(id, descriptor, false))
		active_time[id] = clampf(next_elapsed - descriptor.elapsed_seconds, 0.0, FIXED_STEP)
	var staged_state := state.duplicate(true)
	var targets := existing
	var staged_core := core_hp
	var movement_start := Time.get_ticks_usec() if _measure_costs else 0
	for machine in targets:
		if machine.hp <= 0: continue
		var machine_time: float = active_time.get(machine.id, FIXED_STEP)
		# D-088: a stunned machine skips movement and attack entirely for this
		# tick; its remaining stun still counts down by the time it would have acted.
		var stun: float = float(machine.get("stun_remaining", 0.0))
		if stun > 0:
			machine.stun_remaining = maxf(0.0, stun - machine_time)
			if machine.stun_remaining <= WeaponRules.COOLDOWN_EPSILON: machine.stun_remaining = 0.0
			continue
		var kind: StringName = machine.get("kind", &"")
		var movement: Dictionary
		if kind == &"tunneler": movement = _advance_tunneler(machine, staged_state, staged_core, machine_time, events, context)
		elif kind == &"transfer": movement = _advance_transfer(machine, staged_state, staged_core, machine_time, events, context)
		else: movement = _advance_machine(machine, staged_state, staged_core, machine_time, events, context)
		if not movement.ok: return _failed_tick(movement.errors, events.spawned_ids)
		if not context.errors.is_empty(): return _failed_tick(context.errors, events.spawned_ids)
		staged_core = movement.core_hp
		if staged_core <= 0:
			events.core_lost = true
			break
	var movement_end := Time.get_ticks_usec() if _measure_costs else 0
	var weapon_us := 0
	var staged_cooldowns := cooldowns
	if not events.core_lost:
		var weapon_start := Time.get_ticks_usec() if _measure_costs else 0
		# These dictionaries are exclusive tick scratch; positions remain read-only.
		# A failed owned call may change scratch HP, so discard it via rollback.
		var combat := WeaponRules._step_owned(staged_state, profile, targets, cooldowns, FIXED_STEP)
		if _measure_costs: weapon_us = Time.get_ticks_usec() - weapon_start
		if not combat.ok: return _failed_tick(combat.errors, events.spawned_ids)
		if not is_finite(float(staged_state.energy) + float(combat.energy_awarded)):
			return _failed_tick(PackedStringArray(["Energy bank overflow"]), events.spawned_ids)
		targets = combat.targets
		staged_cooldowns = combat.cooldowns
		events.hits = combat.hits
		events.kill_ids = combat.kill_ids
		events.energy_awarded = combat.energy_awarded
		staged_state.energy += combat.energy_awarded
		_apply_repair_nodes(staged_state)
		_apply_assimilation(targets, context.assimilation_grants, next_elapsed)
	if total_kills > MAX_INTEGER - events.kill_ids.size(): return _failed_tick(PackedStringArray(["Run kill counter overflow"]), events.spawned_ids)
	var persistence_start := Time.get_ticks_usec() if _measure_costs else 0
	# Commit: no fallible rule calls remain. Copy results before releasing kills.
	for target in targets:
		var payload := pool.payload_for(target.id)
		payload.position = target.position
		payload.hp = target.hp
		payload.assimilation_stacks = target.assimilation_stacks
		payload.stun_remaining = target.stun_remaining
		if target.get("kind") == &"tunneler":
			for field in TUNNELER_FIELDS: payload[field] = target[field]
		elif target.get("kind") == &"transfer":
			payload.hopped = target.hopped
			if target.has("hop_cell"): payload.hop_cell = target.hop_cell
		elif target.get("kind") == &"assembler":
			payload.growth_stacks = target.growth_stacks
	for id in events.kill_ids: pool.release(id)
	for id in context.waypoints.keys():
		if not pool.contains(id): context.waypoints.erase(id)
	_navigation = context.navigation
	_transfer_navigation = context.transfer_navigation
	total_kills += events.kill_ids.size()
	_nav_fingerprint = context.fingerprint
	_nav_horizon = context.horizon
	_waypoints = context.waypoints
	route_rebuild_count = context.rebuilds
	state = staged_state
	core_hp = staged_core
	ended = events.core_lost
	cooldowns = staged_cooldowns
	ability_cooldowns = staged_abilities
	_ticks += 1
	elapsed_seconds = next_elapsed
	skipped_arrivals += skipped
	skipped_tunneler_arrivals += skipped_tunnelers
	skipped_foundry_arrivals += skipped_foundry
	skipped_transfer_arrivals += skipped_transfer
	skipped_sapper_arrivals += skipped_sapper
	skipped_breacher_arrivals += skipped_breacher
	skipped_assembler_arrivals += skipped_assembler
	last_events = events
	if _measure_costs:
		_last_step_costs = {"preflight_us": movement_start - measured_start, "movement_us": movement_end - movement_start, "motion_us": context.motion_us, "weapon_us": weapon_us, "persistence_us": Time.get_ticks_usec() - persistence_start, "attack_calls": context.attack_calls}
	return {"ok": true, "errors": PackedStringArray(), "events": events.duplicate(true)}

static func _fingerprint(build_state: Dictionary) -> PackedByteArray:
	# Two topology bytes per historical wedge, bounded by current map size.
	var result := PackedByteArray()
	for ring in range(1, build_state.rings.size() + 1):
		for wedge in range(1, PolarGrid.WEDGE_COUNT + 1):
			result.append(1 if build_state.rings[ring].wedges[wedge].hp > 0 else 0)
			var effects := 1 if WallRules.is_blocking(build_state, ring, wedge) else 0
			if build_state.rings[ring].wedges[wedge].hp > 0:
				for occupant in build_state.rings[ring].wedges[wedge].occupants.values():
					if occupant.kind == &"debris_field": effects |= 2
					elif occupant.kind == &"tractor_lane": effects |= 4 if occupant.direction == 1 else 8
					elif occupant.kind == &"occlusion_screen": effects |= 16
			result.append(effects)
	return result

static func _ensure_navigation(build_state: Dictionary, context: Dictionary, horizon: int, source_profile: BalanceProfile = null) -> PackedStringArray:
	var fingerprint := _fingerprint(build_state)
	var required := maxi(horizon, context.horizon)
	if context.navigation != null and context.fingerprint == fingerprint and context.horizon >= required: return PackedStringArray()
	var built := WallNavigation.build(build_state, required, source_profile)
	if not built.ok: return built.errors
	context.navigation = built.navigation
	context.fingerprint = fingerprint
	context.horizon = required
	context.waypoints = {}
	context.transfer_navigation = {}
	context.rebuilds += 1
	context.dirty = false
	return PackedStringArray()

static func _valid_source(p: PolarPosition, navigation: WallNavigation) -> bool:
	return p != null and is_finite(p.radial_fraction) and is_finite(p.angular_fraction) and p.radial_fraction >= 0 and p.radial_fraction < 1 and p.angular_fraction >= 0 and p.angular_fraction < 1 and navigation.has_cell(Vector2i(p.ring, p.wedge))

static func _node(cell: Vector2i) -> PolarPosition:
	return PolarPosition.new(cell.x, cell.y, 0, 0.5)

func _advance_machine(machine: Dictionary, staged: Dictionary, staged_core: float, available: float, events: Dictionary, context: Dictionary) -> Dictionary:
	var errors := _ensure_navigation(staged, context, context.horizon, profile) if context.dirty else PackedStringArray()
	if not errors.is_empty(): return {"ok": false, "errors": errors}
	var navigation: WallNavigation = context.navigation
	var speed: float = machine.speed_ring_widths_per_second * PolarGrid.RING_WIDTH
	if not is_finite(speed) or speed <= 0: return {"ok": false, "errors": PackedStringArray(["Invalid machine world speed"])}
	var segments := 0
	var boundary_stops := 0
	var progressed := false
	# A shortest positive-cost route visits at most each cell once, plus alignment.
	while available > 0:
		var p: PolarPosition = machine.position
		if not _valid_source(p, navigation): return {"ok": false, "errors": PackedStringArray(["Machine left traversable cells"])}
		var destination: PolarPosition
		if context.waypoints.has(machine.id):
			destination = context.waypoints[machine.id]
		elif p.radial_fraction != 0:
			destination = PolarPosition.new(p.ring, p.wedge, 0, p.angular_fraction)
		elif p.angular_fraction != 0.5:
			destination = _node(Vector2i(p.ring, p.wedge))
		else:
			var cell := Vector2i(p.ring, p.wedge)
			var route_kind: StringName = machine.get("kind", &"")
			# D-109: Breacher always prefers the nearest wall over any open
			# detour. D-110: Assembler ignores walls entirely, treating a
			# walled wedge exactly like a bare one. Both swap only the route
			# source; every other machine keeps the ordinary route.
			var route: Dictionary
			if route_kind == &"breacher": route = navigation.wall_route_for(cell)
			elif route_kind == &"assembler": route = navigation.assembler_route_for(cell)
			else: route = navigation.route_for(cell)
			if not route.ok: return {"ok": false, "errors": route.errors}
			if route.goal_cell == cell:
				# D-107: an unhopped Transfer spends its one hop the first time it
				# reaches an intact ring's boundary instead of attacking it - no
				# damage either way, landing in the band it just skipped past.
				if machine.get("kind") == &"transfer" and not machine.hopped and route.target_kind != &"core":
					var skip_cell: Vector2i = route.target_cell
					machine.position = PolarPosition.new(skip_cell.x, skip_cell.y, 0.0, 0.5)
					machine.hopped = true
					machine.hop_cell = skip_cell
					return {"ok": true, "core_hp": staged_core, "errors": PackedStringArray()}
				staged_core = _attack_surface(machine, route, staged, staged_core, available, events, context)
				return {"ok": true, "core_hp": staged_core, "errors": PackedStringArray()}
			destination = _node(route.next_cell)
		context.waypoints[machine.id] = destination
		var motion_destination := destination
		var motion_speed := speed
		var speed_boundary := false
		if navigation.has_shadows:
			var interval := _motion_interval(p, destination, navigation)
			motion_destination = interval.destination
			motion_speed *= interval.multiplier
			speed_boundary = interval.boundary
		var motion_start := Time.get_ticks_usec() if context.measure else 0
		var motion := PolarMotion.advance(p, motion_destination, motion_speed, available)
		if context.measure: context.motion_us += Time.get_ticks_usec() - motion_start
		if not motion.ok:
			# After actual travel reaches an endpoint, subtraction can leave a
			# sub-picosecond tail whose next displacement cannot be represented.
			# Consume only that failed residual, retaining the next waypoint.
			# Initial/slow full-tick failures and all representable motion retain
			# PolarMotion semantics; this never suppresses other failure types.
			var residual_distance: float = motion_speed * available
			var radius: float = PolarGrid.CORE_RADIUS + (float(p.ring - 1) + p.radial_fraction) * PolarGrid.RING_WIDTH
			if progressed and available <= FIXED_STEP * 1e-12 and residual_distance <= PolarMotion.RADIAL_TOLERANCE and residual_distance / radius / TAU <= PolarMotion.ANGULAR_TOLERANCE and motion.errors.size() == 1 and motion.errors[0] in ["Angular progress is too small to represent.", "Radial progress is too small to represent."]:
				break
			return {"ok": false, "errors": motion.errors}
		if motion.time_used < 0 or not is_finite(motion.time_used) or (motion.time_used == 0 and not motion.reached): return {"ok": false, "errors": PackedStringArray(["Navigation segment made no positive progress"])}
		# Accepted motion may reach a tolerance-close endpoint in zero time.
		# Consume it once; the finite segment bound also covers these transitions.
		machine.position = motion.position
		progressed = progressed or motion.time_used > 0
		available = maxf(0, available - motion.time_used)
		if not motion.reached: break
		if speed_boundary:
			boundary_stops += 1
			# An adjacent-cell angular edge crosses at most one wedge boundary.
			# Keep node-cycle detection unchanged and bound these extra stops separately.
			if boundary_stops > navigation.cell_count + 2: return {"ok": false, "errors": PackedStringArray(["Shadow traversal exceeded finite boundary bound"])}
			continue
		context.waypoints.erase(machine.id)
		segments += 1
		if segments > navigation.cell_count + 2: return {"ok": false, "errors": PackedStringArray(["Navigation exceeded finite segment bound"])}
	return {"ok": true, "core_hp": staged_core, "errors": PackedStringArray()}

## D-021: +5% damage per active assimilation stack, capped at +50% (10 stacks).
## Stacks already expired (per their own 15s timer) are simply not counted;
## _apply_assimilation prunes them from storage separately.
static func _assimilation_multiplier(machine: Dictionary, now: float, source_profile: BalanceProfile) -> float:
	var active := 0
	for expiry in machine.get("assimilation_stacks", []):
		if expiry > now: active += 1
	return 1.0 + float(source_profile.value("assimilation.bonus_per_stack")) * mini(int(source_profile.value("assimilation.max_stacks")), active)

## D-110 Option C: a permanent, non-decaying damage buff personal to this one
## Assembler, separate from D-021's global assimilation - every wedge/wall/
## occupant it personally destroys grants a stack for the rest of its own life.
static func _assembler_growth_multiplier(machine: Dictionary, source_profile: BalanceProfile) -> float:
	if machine.get("kind") != &"assembler": return 1.0
	return 1.0 + float(source_profile.value("assembler.growth_damage_per_stack")) * int(machine.get("growth_stacks", 0))

func _grant_assembler_growth(machine: Dictionary, stacks: int, source_profile: BalanceProfile, context: Dictionary) -> void:
	var old: int = machine.get("growth_stacks", 0)
	var hp: float = machine.hp + float(source_profile.value("assembler.growth_hp_per_stack")) * stacks
	if stacks > MAX_INTEGER - old or not is_finite(hp) or not is_finite(1.0 + float(source_profile.value("assembler.growth_damage_per_stack")) * (float(old) + stacks)):
		context.errors.append("Unusable computed Assembler growth")
		return
	machine.growth_stacks = old + stacks
	machine.hp = hp

func _attack_surface(machine: Dictionary, route: Dictionary, staged: Dictionary, staged_core: float, available: float, events: Dictionary, context: Dictionary) -> float:
	if context.measure: context.attack_calls += 1
	var damage: float = machine.damage_per_second * available * _assimilation_multiplier(machine, elapsed_seconds, profile) * _assembler_growth_multiplier(machine, profile)
	if not is_finite(damage) or damage < 0:
		context.errors.append("Unusable computed machine damage")
		return staged_core
	if route.target_kind == &"core": return maxf(0, staged_core - damage)
	var cell: Vector2i = route.target_cell
	var plate: Dictionary = staged.rings[cell.x].wedges[cell.y]
	# D-108: a Sapper interacts with walls exactly like a standard machine (wall
	# redundancy still matters), but once it is attacking a bare wedge its
	# damage drains that ring's relay_hp pool instead - the wedge itself is
	# never touched by a Sapper's own attacks.
	if machine.get("kind") == &"sapper" and route.target_kind == &"wedge":
		var record: Dictionary = staged.rings[cell.x]
		if float(record.relay_hp) > 0:
			record.relay_hp = maxf(0.0, float(record.relay_hp) - damage)
			if record.relay_hp == 0.0:
				events.relays_lost.append(cell.x)
		return staged_core
	if route.target_kind == &"wall":
		# D-109: smashing walls is Breacher's entire purpose, not a last-resort
		# fallback - it deals full, unpenalized wall damage, skipping the
		# 25% sealed-only multiplier every other machine is limited to.
		var wall_multiplier: float = 1.0 if machine.get("kind") == &"breacher" else float(profile.value("standard_machine.wall_damage_multiplier"))
		plate.wall.hp = maxf(0, float(plate.wall.hp) - damage * wall_multiplier)
		if plate.wall.hp == 0:
			plate.erase("wall")
			events.walls_broken.append(cell)
			context.dirty = true
			context.assimilation_grants += 1
		return staged_core
	plate.hp = maxf(0.0, float(plate.hp) - damage)
	if plate.hp == 0:
		events.broken_wedges.append(cell)
		context.dirty = true
		if machine.get("kind") == &"assembler": _grant_assembler_growth(machine, 1, profile, context)
		var broken := 0
		for wedge in staged.rings[cell.x].wedges.values():
			if wedge.hp == 0: broken += 1
		if broken >= int(profile.value("structure.collapse_broken_wedges")):
			var record: Dictionary = staged.rings[cell.x]
			record.collapsed = true
			record.relay = {}
			record.erase("relay_hp")
			record.erase("relay_max_hp")
			# Count every occupant and wall on the collapsing ring once each,
			# before they're cleared — never a separate flat "collapse bonus".
			var collapse_grants := 0
			for wedge in record.wedges.values():
				collapse_grants += wedge.occupants.size()
				if wedge.has("wall"): collapse_grants += 1
				wedge.hp = 0.0
				wedge.occupants = {}
				wedge.erase("wall")
			context.assimilation_grants += collapse_grants
			if machine.get("kind") == &"assembler" and collapse_grants > 0: _grant_assembler_growth(machine, collapse_grants, profile, context)
			events.collapsed_rings.append(cell.x)
	return staged_core

## D-021: apply this tick's destroyed-occupant grants to every machine active
## right now (spec: never future spawns), then prune stacks whose own 15s
## timer has already elapsed so a machine that was ever capped can accrue
## new stacks again once old ones decay. Runs once per tick, not per grant.
func _apply_assimilation(targets: Array[Dictionary], grants: int, tick_elapsed: float) -> void:
	var stack_cap: int = profile.value("assimilation.max_stacks")
	var expiry_time: float = tick_elapsed + float(profile.value("assimilation.stack_seconds"))
	for target in targets:
		var stacks: Array = target.assimilation_stacks
		var pruned: Array = []
		for expiry in stacks:
			if expiry > tick_elapsed: pruned.append(expiry)
		if target.hp > 0:
			for i in range(grants):
				if pruned.size() >= stack_cap: break
				pruned.append(expiry_time)
		target.assimilation_stacks = pruned







## D-027 Repair Node: passive, per-tick healing. Each repair_node occupant in a
## ring independently heals that ring's currently most-damaged wedge (positive
## but below max HP — never a fully broken wedge, which needs D-022 Tier 1
## Repair instead). Multiple nodes on the same ring compound on that wedge.
func _apply_repair_nodes(staged: Dictionary) -> void:
	var fraction: float = profile.value("structure.repair_node_heal_fraction_per_second")
	for ring in staged.rings:
		var record: Dictionary = staged.rings[ring]
		if record.get("collapsed", false): continue
		var node_count := 0
		for plate in record.wedges.values():
			for occupant in plate.occupants.values():
				if occupant.kind == &"repair_node": node_count += 1
		if node_count == 0: continue
		var target: Dictionary = {}
		var target_fraction := 1.0
		for plate in record.wedges.values():
			if plate.hp > 0 and plate.hp < plate.max_hp:
				var hp_fraction: float = plate.hp / plate.max_hp
				if target.is_empty() or hp_fraction < target_fraction:
					target = plate
					target_fraction = hp_fraction
		if target.is_empty(): continue
		target.hp = minf(target.max_hp, target.hp + target.max_hp * fraction * FIXED_STEP * node_count)

func _admission_plan(normal: Dictionary, next_elapsed: float) -> Dictionary:
	var descriptors: Array[Dictionary] = []
	var free_slots: int = int(profile.value("pressure.max_active_machines")) - pool.active_count()
	var normal_admitted := 0
	var tunneler_admitted := 0
	var foundry_admitted := 0
	var transfer_admitted := 0
	var sapper_admitted := 0
	var breacher_admitted := 0
	var assembler_admitted := 0
	var tunnel := {"first_sequence": 1, "count": 0}
	if tunnelers_enabled:
		tunnel = TunnelerRules.arrivals_between(profile, elapsed_seconds, next_elapsed)
		if not tunnel.ok: return tunnel
	var foundry := {"first_sequence": 1, "count": 0}
	if foundry_enabled:
		foundry = FoundryRules.arrivals_between(profile, elapsed_seconds, next_elapsed)
		if not foundry.ok: return foundry
	var transfer := {"first_sequence": 1, "count": 0}
	if transfer_enabled:
		transfer = TransferRules.arrivals_between(profile, elapsed_seconds, next_elapsed)
		if not transfer.ok: return transfer
	var sapper := {"first_sequence": 1, "count": 0}
	if sapper_enabled:
		sapper = SapperRules.arrivals_between(profile, elapsed_seconds, next_elapsed)
		if not sapper.ok: return sapper
	var breacher := {"first_sequence": 1, "count": 0}
	if breacher_enabled:
		breacher = BreacherRules.arrivals_between(profile, elapsed_seconds, next_elapsed)
		if not breacher.ok: return breacher
	var assembler := {"first_sequence": 1, "count": 0}
	if assembler_enabled:
		assembler = AssemblerRules.arrivals_between(profile, elapsed_seconds, next_elapsed)
		if not assembler.ok: return assembler
	var normal_index := 0
	var tunnel_index := 0
	var foundry_index := 0
	var transfer_index := 0
	var sapper_index := 0
	var breacher_index := 0
	var assembler_index := 0
	var pending_normal: Dictionary = {}
	var pending_tunnel: Dictionary = {}
	var pending_foundry: Dictionary = {}
	var pending_transfer: Dictionary = {}
	var pending_sapper: Dictionary = {}
	var pending_breacher: Dictionary = {}
	var pending_assembler: Dictionary = {}
	# Only admitted candidates plus at most one 12-bearing cycle are inspected
	# per slot. A full pool counts the remaining streams without enumeration.
	while descriptors.size() < free_slots:
		if pending_normal.is_empty() and normal_index < normal.count:
			var candidate := MachineSpawnRules.spawn_descriptor(profile, normal.first_sequence + normal_index, outer_owned_ring())
			if not candidate.ok: return candidate
			pending_normal = candidate.spawn
		if pending_tunnel.is_empty() and tunnel_index < tunnel.count:
			var searched := 0
			while tunnel_index < tunnel.count and searched < PolarGrid.WEDGE_COUNT:
				var candidate := TunnelerRules.spawn_descriptor(profile, state, tunnel.first_sequence + tunnel_index)
				if not candidate.ok: return candidate
				tunnel_index += 1
				searched += 1
				if candidate.eligible:
					pending_tunnel = candidate.spawn
					break
			if pending_tunnel.is_empty(): tunnel_index = tunnel.count
		if pending_foundry.is_empty() and foundry_index < foundry.count:
			var candidate := FoundryRules.spawn_descriptor(profile, foundry.first_sequence + foundry_index, outer_owned_ring())
			if not candidate.ok: return candidate
			foundry_index += 1
			pending_foundry = candidate.spawn
		if pending_transfer.is_empty() and transfer_index < transfer.count:
			var candidate := TransferRules.spawn_descriptor(profile, transfer.first_sequence + transfer_index, outer_owned_ring())
			if not candidate.ok: return candidate
			transfer_index += 1
			pending_transfer = candidate.spawn
		if pending_sapper.is_empty() and sapper_index < sapper.count:
			var candidate := SapperRules.spawn_descriptor(profile, sapper.first_sequence + sapper_index, outer_owned_ring())
			if not candidate.ok: return candidate
			sapper_index += 1
			pending_sapper = candidate.spawn
		if pending_breacher.is_empty() and breacher_index < breacher.count:
			var candidate := BreacherRules.spawn_descriptor(profile, breacher.first_sequence + breacher_index, outer_owned_ring())
			if not candidate.ok: return candidate
			breacher_index += 1
			pending_breacher = candidate.spawn
		if pending_assembler.is_empty() and assembler_index < assembler.count:
			var candidate := AssemblerRules.spawn_descriptor(profile, assembler.first_sequence + assembler_index, outer_owned_ring())
			if not candidate.ok: return candidate
			assembler_index += 1
			pending_assembler = candidate.spawn
		if pending_normal.is_empty() and pending_tunnel.is_empty() and pending_foundry.is_empty() and pending_transfer.is_empty() and pending_sapper.is_empty() and pending_breacher.is_empty() and pending_assembler.is_empty(): break
		# Exact-time tie priority: Tunneler, then Foundry, then Transfer, then Sapper, then Breacher, then Assembler, then normal.
		if not pending_tunnel.is_empty() and (pending_normal.is_empty() or pending_tunnel.elapsed_seconds <= pending_normal.elapsed_seconds) and (pending_foundry.is_empty() or pending_tunnel.elapsed_seconds <= pending_foundry.elapsed_seconds) and (pending_transfer.is_empty() or pending_tunnel.elapsed_seconds <= pending_transfer.elapsed_seconds) and (pending_sapper.is_empty() or pending_tunnel.elapsed_seconds <= pending_sapper.elapsed_seconds) and (pending_breacher.is_empty() or pending_tunnel.elapsed_seconds <= pending_breacher.elapsed_seconds) and (pending_assembler.is_empty() or pending_tunnel.elapsed_seconds <= pending_assembler.elapsed_seconds):
			descriptors.append(pending_tunnel)
			pending_tunnel = {}
			tunneler_admitted += 1
		elif not pending_foundry.is_empty() and (pending_normal.is_empty() or pending_foundry.elapsed_seconds <= pending_normal.elapsed_seconds) and (pending_transfer.is_empty() or pending_foundry.elapsed_seconds <= pending_transfer.elapsed_seconds) and (pending_sapper.is_empty() or pending_foundry.elapsed_seconds <= pending_sapper.elapsed_seconds) and (pending_breacher.is_empty() or pending_foundry.elapsed_seconds <= pending_breacher.elapsed_seconds) and (pending_assembler.is_empty() or pending_foundry.elapsed_seconds <= pending_assembler.elapsed_seconds):
			descriptors.append(pending_foundry)
			pending_foundry = {}
			foundry_admitted += 1
		elif not pending_transfer.is_empty() and (pending_normal.is_empty() or pending_transfer.elapsed_seconds <= pending_normal.elapsed_seconds) and (pending_sapper.is_empty() or pending_transfer.elapsed_seconds <= pending_sapper.elapsed_seconds) and (pending_breacher.is_empty() or pending_transfer.elapsed_seconds <= pending_breacher.elapsed_seconds) and (pending_assembler.is_empty() or pending_transfer.elapsed_seconds <= pending_assembler.elapsed_seconds):
			descriptors.append(pending_transfer)
			pending_transfer = {}
			transfer_admitted += 1
		elif not pending_sapper.is_empty() and (pending_normal.is_empty() or pending_sapper.elapsed_seconds <= pending_normal.elapsed_seconds) and (pending_breacher.is_empty() or pending_sapper.elapsed_seconds <= pending_breacher.elapsed_seconds) and (pending_assembler.is_empty() or pending_sapper.elapsed_seconds <= pending_assembler.elapsed_seconds):
			descriptors.append(pending_sapper)
			pending_sapper = {}
			sapper_admitted += 1
		elif not pending_breacher.is_empty() and (pending_normal.is_empty() or pending_breacher.elapsed_seconds <= pending_normal.elapsed_seconds) and (pending_assembler.is_empty() or pending_breacher.elapsed_seconds <= pending_assembler.elapsed_seconds):
			descriptors.append(pending_breacher)
			pending_breacher = {}
			breacher_admitted += 1
		elif not pending_assembler.is_empty() and (pending_normal.is_empty() or pending_assembler.elapsed_seconds <= pending_normal.elapsed_seconds):
			descriptors.append(pending_assembler)
			pending_assembler = {}
			assembler_admitted += 1
		else:
			descriptors.append(pending_normal)
			pending_normal = {}
			normal_index += 1
			normal_admitted += 1
	var skipped: int = normal.count - normal_admitted
	var skipped_tunnelers: int = tunnel.count - tunneler_admitted
	var skipped_foundry: int = foundry.count - foundry_admitted
	var skipped_transfer: int = transfer.count - transfer_admitted
	var skipped_sapper: int = sapper.count - sapper_admitted
	var skipped_breacher: int = breacher.count - breacher_admitted
	var skipped_assembler: int = assembler.count - assembler_admitted
	if skipped > MAX_INTEGER - skipped_arrivals or skipped_tunnelers > MAX_INTEGER - skipped_tunneler_arrivals or skipped_foundry > MAX_INTEGER - skipped_foundry_arrivals or skipped_transfer > MAX_INTEGER - skipped_transfer_arrivals or skipped_sapper > MAX_INTEGER - skipped_sapper_arrivals or skipped_breacher > MAX_INTEGER - skipped_breacher_arrivals or skipped_assembler > MAX_INTEGER - skipped_assembler_arrivals:
		return {"ok": false, "errors": PackedStringArray(["Skipped arrival counter overflow"])}
	return {"ok": true, "descriptors": descriptors, "skipped": skipped, "skipped_tunnelers": skipped_tunnelers, "skipped_foundry": skipped_foundry, "skipped_transfer": skipped_transfer, "skipped_sapper": skipped_sapper, "skipped_breacher": skipped_breacher, "skipped_assembler": skipped_assembler}

static func _valid_machine_source(machine: Dictionary, navigation: WallNavigation, historical_rings: int) -> bool:
	if not machine.has("kind"):
		if machine.size() > 6:
			for field in KIND_FIELDS:
				if machine.has(field): return false
		return _valid_source(machine.position, navigation) or (machine.hp == 0 and WeaponRules._valid_position(machine.position))
	if machine.kind == &"foundry":
		# Foundry is a standard machine with a "kind" tag and no other tunneler-only
		# fields; still reject it if malformed with any of those present.
		if machine.size() > 7:
			for field in KIND_FIELDS:
				if field != "kind" and machine.has(field): return false
		return _valid_source(machine.position, navigation) or (machine.hp == 0 and WeaponRules._valid_position(machine.position))
	if machine.kind == &"assembler":
		# Assembler is a standard machine with a "kind" tag plus one persistent
		# int (growth_stacks, D-110 Option C) - its wall immunity lives in
		# _advance_machine/WallNavigation, not in its own position shape.
		if not machine.has("growth_stacks") or typeof(machine.growth_stacks) != TYPE_INT or machine.growth_stacks < 0: return false
		if machine.size() > 8:
			for field in KIND_FIELDS:
				if field != "kind" and field != "growth_stacks" and machine.has(field): return false
		return _valid_source(machine.position, navigation) or (machine.hp == 0 and WeaponRules._valid_position(machine.position))
	if machine.kind == &"breacher":
		# Breacher is a standard machine with a "kind" tag and no other
		# tunneler-only fields - its distinct routing/wall-damage behavior
		# lives in _advance_machine/_attack_surface, not in its own shape.
		if machine.size() > 7:
			for field in KIND_FIELDS:
				if field != "kind" and machine.has(field): return false
		return _valid_source(machine.position, navigation) or (machine.hp == 0 and WeaponRules._valid_position(machine.position))
	if machine.kind == &"sapper":
		# Sapper is a standard machine with a "kind" tag and no other tunneler-only
		# fields - it reuses ordinary movement/wall interaction completely (D-108);
		# only its attack target differs, elsewhere in LiveSimulation.
		if machine.size() > 7:
			for field in KIND_FIELDS:
				if field != "kind" and machine.has(field): return false
		return _valid_source(machine.position, navigation) or (machine.hp == 0 and WeaponRules._valid_position(machine.position))
	if machine.kind == &"transfer":
		if typeof(machine.kind) != TYPE_STRING_NAME or not machine.has("hopped") or typeof(machine.hopped) != TYPE_BOOL: return false
		for field in TUNNELER_FIELDS:
			if field != "kind" and machine.has(field): return false
		if not machine.hopped:
			if machine.has("hop_cell"): return false
			return _valid_source(machine.position, navigation) or (machine.hp == 0 and WeaponRules._valid_position(machine.position))
		if not machine.has("hop_cell") or typeof(machine.hop_cell) != TYPE_VECTOR2I: return false
		var hop_cell: Vector2i = machine.hop_cell
		if hop_cell.x < 1 or hop_cell.x > historical_rings or hop_cell.y < 1 or hop_cell.y > 12: return false
		if machine.position.ring == hop_cell.x:
			# Standing in the band it hopped past; that band is intentionally
			# excluded from the shared navigation graph while its skipped
			# ring's wall stands, so it is validated positionally instead.
			if hop_cell.x < 1 or hop_cell.x > historical_rings or hop_cell.y < 1 or hop_cell.y > 12 or machine.position.radial_fraction != 0.0: return false
			return WeaponRules._valid_position(machine.position)
		return _valid_source(machine.position, navigation) or (machine.hp == 0 and WeaponRules._valid_position(machine.position))
	if machine.kind != &"tunneler" or typeof(machine.kind) != TYPE_STRING_NAME: return false
	for field in TUNNELER_FIELDS:
		if not machine.has(field): return false
	if typeof(machine.phase) != TYPE_STRING_NAME or machine.phase not in [&"burrowing", &"surface_attack", &"roaming"] or typeof(machine.targetable) != TYPE_BOOL: return false
	if machine.targetable != (machine.phase != &"burrowing"): return false
	if not RingPurchaseRules.number(machine.burrow_duration_seconds) or machine.burrow_duration_seconds <= 0 or not RingPurchaseRules.number(machine.burrow_elapsed_seconds) or machine.burrow_elapsed_seconds < 0 or machine.burrow_elapsed_seconds > machine.burrow_duration_seconds: return false
	if not RingPurchaseRules.number(machine.damage_per_second) or machine.damage_per_second < 0 or not RingPurchaseRules.number(machine.speed_ring_widths_per_second) or machine.speed_ring_widths_per_second <= 0: return false
	var start: Variant = machine.start_position
	var destination: Variant = machine.destination
	if not WeaponRules._valid_position(start) or not WeaponRules._valid_position(destination) or not WeaponRules._valid_position(machine.position): return false
	if start.ring > historical_rings + 1 or destination.ring > historical_rings: return false
	if start.ring < destination.ring + 2 or destination.ring < 1 or start.radial_fraction != 0 or destination.radial_fraction != 0.5 or start.angular_fraction != 0.5 or destination.angular_fraction != 0.5 or start.wedge != destination.wedge: return false
	if typeof(machine.surface_cell) != TYPE_VECTOR2I or machine.surface_cell != Vector2i(destination.ring, destination.wedge): return false
	var burrow_speed: float = (float(start.ring) - float(destination.ring) - 0.5) * PolarGrid.RING_WIDTH / machine.burrow_duration_seconds
	if not is_finite(burrow_speed) or burrow_speed <= 0: return false
	if machine.phase == &"roaming":
		return machine.burrow_elapsed_seconds == machine.burrow_duration_seconds and _valid_source(machine.position, navigation)
	if machine.position.wedge != destination.wedge or absf(machine.position.angular_fraction - 0.5) / PolarGrid.WEDGE_COUNT > PolarMotion.ANGULAR_TOLERANCE: return false
	var expected: float = float(start.ring) + (float(destination.ring) + 0.5 - float(start.ring)) * (machine.burrow_elapsed_seconds / machine.burrow_duration_seconds)
	if absf(float(machine.position.ring) + machine.position.radial_fraction - expected) * PolarGrid.RING_WIDTH > PolarMotion.RADIAL_TOLERANCE: return false
	return machine.burrow_elapsed_seconds < machine.burrow_duration_seconds if machine.phase == &"burrowing" else machine.burrow_elapsed_seconds == machine.burrow_duration_seconds

func _advance_tunneler(machine: Dictionary, staged: Dictionary, staged_core: float, available: float, events: Dictionary, context: Dictionary) -> Dictionary:
	if available <= 0: return {"ok": true, "core_hp": staged_core, "errors": PackedStringArray()}
	if machine.phase == &"burrowing":
		var remaining: float = machine.burrow_duration_seconds - machine.burrow_elapsed_seconds
		var used := minf(available, remaining)
		var distance: float = (float(machine.start_position.ring) - float(machine.destination.ring) - 0.5) * PolarGrid.RING_WIDTH
		var speed: float = distance / machine.burrow_duration_seconds
		if not is_finite(speed) or speed <= 0: return {"ok": false, "errors": PackedStringArray(["Invalid burrow speed"])}
		# Scheduled-time subtraction can leave a sub-tolerance positive tail at
		# an exact due boundary. Consume its time without unrepresentable motion.
		if machine.burrow_elapsed_seconds > 0 or speed * used > PolarMotion.RADIAL_TOLERANCE:
			var motion := PolarMotion.advance(machine.position, machine.destination, speed, used)
			if not motion.ok: return {"ok": false, "errors": motion.errors}
			machine.position = motion.position
		machine.burrow_elapsed_seconds = minf(machine.burrow_duration_seconds, machine.burrow_elapsed_seconds + used)
		available = maxf(0, available - used)
		# Absorb only accumulated fixed-step roundoff at the duration endpoint.
		if machine.burrow_duration_seconds - machine.burrow_elapsed_seconds <= 1e-12:
			machine.burrow_elapsed_seconds = machine.burrow_duration_seconds
			machine.position = machine.destination
			machine.phase = &"surface_attack"
			machine.targetable = true
		else:
			return {"ok": true, "core_hp": staged_core, "errors": PackedStringArray()}
	if machine.phase == &"surface_attack":
		var cell: Vector2i = machine.surface_cell
		if staged.rings.has(cell.x) and staged.rings[cell.x].wedges[cell.y].hp > 0:
			if available > 0:
				staged_core = _attack_surface(machine, {"target_kind": &"wedge", "target_cell": cell}, staged, staged_core, available, events, context)
				if staged.rings[cell.x].wedges[cell.y].hp == 0: machine.phase = &"roaming"
			return {"ok": true, "core_hp": staged_core, "errors": PackedStringArray()}
		machine.phase = &"roaming"
	return _advance_machine(machine, staged, staged_core, available, events, context)

# D-107: once hopped, a Transfer stands in the band it skipped past - a cell
# intentionally absent from the shared navigation graph while its own ring's
# wall is intact (nothing else can ever legitimately be there). It attacks
# whatever is one ring further in (or the core, if it hopped past ring 1)
# using the same manual target dict Tunneler's surface_attack constructs,
# then hands off to ordinary _advance_machine once it moves into a
# genuinely open band.
func _advance_hopped_transfer(machine: Dictionary, staged: Dictionary, staged_core: float, available: float, events: Dictionary, context: Dictionary) -> Dictionary:
	if available <= 0: return {"ok": true, "core_hp": staged_core, "errors": PackedStringArray()}
	var errors := _ensure_navigation(staged, context, context.horizon, profile) if context.dirty else PackedStringArray()
	if not errors.is_empty(): return {"ok": false, "errors": errors}
	var boundary: int = machine.hop_cell.x
	if not context.transfer_navigation.has(boundary):
		var built := WallNavigation.build(staged, context.horizon, profile, boundary)
		if not built.ok: return {"ok": false, "errors": built.errors}
		context.transfer_navigation[boundary] = built.navigation
	var private_nav: WallNavigation = context.transfer_navigation[boundary]
	# A sealed inner debris perimeter has no target: wait until topology changes.
	if not private_nav.route_for(Vector2i(machine.position.ring, machine.position.wedge)).ok:
		context.waypoints.erase(machine.id)
		return {"ok": true, "core_hp": staged_core, "errors": PackedStringArray()}
	var shared: WallNavigation = context.navigation
	context.navigation = private_nav
	var moved := _advance_machine(machine, staged, staged_core, available, events, context)
	context.navigation = shared
	return moved

func _advance_transfer(machine: Dictionary, staged: Dictionary, staged_core: float, available: float, events: Dictionary, context: Dictionary) -> Dictionary:
	if machine.hopped and machine.position.ring == machine.hop_cell.x:
		return _advance_hopped_transfer(machine, staged, staged_core, available, events, context)
	return _advance_machine(machine, staged, staged_core, available, events, context)
