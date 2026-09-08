extends SceneTree
const DT := 1.0 / 60.0
var checks := 0
var failures := 0
var baseline: BalanceProfile
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _sim(overrides: Dictionary = {}) -> LiveSimulation:
	# D-033 testing tuning added pressure.spawn_delay_seconds (2026-09-07) as a
	# gameplay-only preliminary-build window; this suite's arrival-timing
	# fixtures predate it and assume the plain rate schedule, so it's zeroed
	# here by default (a test can still override it back to check the delay).
	var zeroed: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_delay_seconds": 0}}).profile
	return LiveSimulation.create(zeroed.with_overrides(overrides).profile, 5).simulation
func _add(sim: LiveSimulation, wedge: int, radius: float, hp: float = 100, dps: float = 6, speed: float = 1) -> int:
	var band := (radius - 96) / 96
	return sim.pool.spawn({"position": PolarPosition.new(int(floorf(band)) + 1, wedge, band - floorf(band), 0.5), "hp": hp, "damage_per_second": dps, "speed_ring_widths_per_second": speed})
func _radius(sim: LiveSimulation, id: int) -> float:
	var p: PolarPosition = sim.pool.payload_for(id).position
	return 96 + (p.ring - 1 + p.radial_fraction) * 96
func _collapse_fixture(sim: LiveSimulation, ring: int) -> void:
	var record: Dictionary = sim.state.rings[ring]
	record.collapsed = true
	record.relay = {}
	record.erase("relay_hp")
	record.erase("relay_max_hp")
	for plate in record.wedges.values():
		plate.hp = 0
		plate.occupants = {}
func _initialize() -> void:
	baseline = BalanceProfile.load_json("res://data/balance/testing.json").profile
	if "--cost-review" in OS.get_cmdline_user_args() or "--cost-angular-only" in OS.get_cmdline_user_args() or "--cost-sealed-only" in OS.get_cmdline_user_args():
		_cost_review()
		quit(1 if failures else 0)
		return
	_check(not LiveSimulation.create(null, 3).ok and not LiveSimulation.create(BalanceProfile.new(), 3).ok and not LiveSimulation.create(baseline, 0).ok, "Create validation")
	var sim := _sim()
	_check(sim.state.energy == 200 and sim.core_hp == 200 and sim.outer_owned_ring() == 1 and sim.pool.active_count() == 0, "Approved startup")
	for tick in range(1, 31):
		var result := sim.step(DT)
		_check(result.ok and result.events.spawned_ids.size() == (1 if tick == 30 else 0), "Default due arrival tick %d" % tick)
	var first: int = sim.pool.active_ids()[0]
	_check(sim.elapsed_seconds == 0.5 and _radius(sim, first) == 384, "New default arrival has zero movement at due boundary")
	sim.step(DT)
	_check(is_equal_approx(_radius(sim, first), 382.4), "Next tick moves exactly speed times dt")
	var paused_radius := _radius(sim, first)
	var paused_time := sim.elapsed_seconds
	var saved := sim.targets_snapshot()
	saved[0].position.ring = 20
	saved[0].hp = 0
	_check(_radius(sim, first) == paused_radius and sim.elapsed_seconds == paused_time and sim.pool.payload_for(first).hp > 0, "No stepping means pause; snapshots cannot mutate live targets")
	var old_state := sim.state.duplicate(true)
	var old_events := sim.last_events.duplicate(true)
	for delta in [0, -DT, DT * 2, INF, NAN]:
		_check(not sim.step(delta).ok and sim.state == old_state and sim.last_events == old_events and sim.elapsed_seconds == paused_time, "Invalid fixed step rejected before mutation")
	var placed := sim.place_weapon(1, 1, 0, &"flak")
	_check(placed.ok and sim.elapsed_seconds == paused_time, "Building does not advance or pause clock")
	placed.state.energy = 99999
	_check(sim.state.energy == 180, "Placement result state isolated")
	sim.step(DT)
	_check(sim.elapsed_seconds > paused_time, "Simulation continues after building")
	sim = _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	first = _add(sim, 1, 192.8)
	var contact := sim.step(DT)
	_check(contact.ok and _radius(sim, first) == 192 and is_equal_approx(sim.state.rings[1].wedges[1].hp, 99.95), "Half-tick travel leaves half-tick continuous DPS")
	_check(sim.pool.payload_for(first).position.ring == 2 and sim.pool.payload_for(first).position.radial_fraction == 0, "Surface contact owns outward band")
	sim.step(DT)
	_check(_radius(sim, first) == 192 and is_equal_approx(sim.state.rings[1].wedges[1].hp, 99.85), "Intact surface blocks further movement while DPS continues")
	var overlapping := _add(sim, 1, 192)
	sim.step(DT)
	_check(_radius(sim, first) == _radius(sim, overlapping) and is_equal_approx(sim.state.rings[1].wedges[1].hp, 99.65), "Overlapping machines both attack without crowd blocking")
	sim.state.rings[1].wedges[1].hp = 0.05
	var broken := sim.step(DT)
	_check(broken.events.broken_wedges == [Vector2i(1, 1)] and _radius(sim, first) == 192 and is_equal_approx(_radius(sim, overlapping), 190.4), "Lifetime ID order: first breaks, later machine advances immediately through gap")
	var core_before := sim.core_hp
	sim.step(DT)
	_check(_radius(sim, first) < 192 and sim.core_hp == core_before, "Breaker resumes next tick without carryover damage")
	var fast := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	var fast_id := _add(fast, 2, 400, 100, 6, 1000)
	fast.step(DT)
	_check(_radius(fast, fast_id) == 192 and is_equal_approx(fast.state.rings[1].wedges[2].hp, 100 - 6 * (DT - 208.0 / 96000.0)) and fast.core_hp == 200, "Fast machine cannot tunnel through intact wedge or over-attack")
	var timed := _sim({"pressure": {"spawn_per_second": 100, "speed_ring_widths_per_second": 2, "spawn_offset_ring_widths": 0.5}, "flak": {"damage": 0}})
	timed.step(DT)
	var timed_id: int = timed.pool.active_ids()[0]
	_check(is_equal_approx(_radius(timed, timed_id), 240 - 192 * (DT - 0.01)), "Fractional due time uses only elapsed portion of tick")
	var growth := _sim({"pressure": {"spawn_per_second": 2, "speed_ring_widths_per_second": 2, "stat_increase_per_minute": 0.25}, "health": {"standard_machine_hp": 20}, "standard_machine": {"damage_per_second": 8}, "flak": {"damage": 0}})
	var old_id := _add(growth, 2, 384, 20, 8, 2)
	growth._ticks = 3599
	growth.elapsed_seconds = 3599.0 / 60.0
	var grown := growth.step(DT)
	var new_id: int = grown.events.spawned_ids[0]
	_check(growth.pool.payload_for(new_id).hp == 25 and growth.pool.payload_for(new_id).damage_per_second == 10 and growth.pool.payload_for(new_id).speed_ring_widths_per_second == 2 and growth.pool.payload_for(old_id).hp == 20 and growth.pool.payload_for(old_id).damage_per_second == 8, "Minute stats apply only to new arrival; tuned movement stats retained")
	_collapse_checks()
	_capacity_and_transactions()
	_error_rollback()
	_owned_combat_rollback()
	_tunneler_checks()
	_benchmark()
	_wall_integration_checks()
	_wall_benchmarks()
	_repair_reclaim_checks()
	_armor_repair_node_checks()
	_assimilation_checks()
	_stun_checks()
	_t043_checks()
	_t048_checks()
	_t050_checks()
	_foundry_checks()
	_transfer_checks()
	_sapper_checks()
	_breacher_checks()
	_assembler_checks()
	print("Live simulation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _repair_reclaim_checks() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 0}})
	sim.state.energy = 10000
	_check(sim.purchase_ring().ok and sim.purchase_ring().ok, "Repair/reclaim fixture owns rings 1-3")
	sim.state.rings[1].wedges[2].hp = 75
	var repair_quote := sim.quote_repair(1, 2)
	_check(repair_quote.ok and is_equal_approx(repair_quote.quote.cost, 2.5) and repair_quote.quote.affordable, "Live quote_repair matches the pure rule")
	var before_energy: float = sim.state.energy
	var repaired := sim.repair_wedge(1, 2)
	_check(repaired.ok and sim.state.rings[1].wedges[2].hp == 100 and is_equal_approx(sim.state.energy, before_energy - 2.5), "Live repair_wedge commits to the running simulation")
	repaired.state.rings[1].wedges[2].hp = 1
	_check(sim.state.rings[1].wedges[2].hp == 100, "Repair result is an independent snapshot, not an alias of live state")
	_collapse_fixture(sim, 2)
	var living := _add(sim, 3, 200)
	_check(sim.pool.payload_for(living).position.ring == 2, "Occupancy fixture machine sits inside the candidate ring")
	_check(not sim.quote_reclaim(2).ok, "A living machine in the collapsed ring blocks reclaim")
	sim.pool.release(living)
	var reclaim_quote := sim.quote_reclaim(2)
	_check(reclaim_quote.ok and is_equal_approx(reclaim_quote.quote.cost, 180.0) and reclaim_quote.quote.affordable, "Live quote_reclaim matches the pure rule once the ring is clear")
	before_energy = sim.state.energy
	var reclaimed := sim.reclaim_ring(2)
	_check(reclaimed.ok and not sim.state.rings[2].get("collapsed", false) and sim.state.rings[2].wedges[1].hp == 200 and is_equal_approx(sim.state.energy, before_energy - 180.0), "Live reclaim_ring commits to the running simulation")
	_check(sim.state.rings[3].wedges[1].hp == 300, "Reclaiming ring 2 leaves ring 3 untouched in the live simulation")
	sim.core_hp = 0
	sim.ended = true
	_check(not sim.quote_repair(1, 2).ok and not sim.repair_wedge(1, 2).ok and not sim.quote_reclaim(2).ok and not sim.reclaim_ring(2).ok, "Ended run blocks repair and reclaim")

func _armor_repair_node_checks() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	sim.state.energy = 10000
	_check(sim.purchase_ring().ok, "Armor/repair fixture owns ring 2")
	var before_energy: float = sim.state.energy
	var armored := sim.place_armor(1, 7, 0)
	_check(armored.ok and sim.state.rings[1].wedges[7].max_hp == 150 and sim.state.rings[1].wedges[7].hp == 150 and is_equal_approx(sim.state.energy, before_energy - 15), "Live place_armor commits to the running simulation")
	before_energy = sim.state.energy
	var node_placed := sim.place_repair_node(2, 5, 0)
	_check(node_placed.ok and sim.state.rings[2].wedges[5].occupants[0].kind == &"repair_node" and is_equal_approx(sim.state.energy, before_energy - 40), "Live place_repair_node commits to the running simulation")
	sim.state.rings[2].wedges[7].hp = 20.0
	sim.state.rings[2].wedges[9].hp = 50.0
	sim.state.rings[2].wedges[1].hp = 0.0
	var before_worst: float = sim.state.rings[2].wedges[7].hp
	sim.step(DT)
	_check(sim.state.rings[2].wedges[7].hp > before_worst and is_equal_approx(sim.state.rings[2].wedges[7].hp - before_worst, 200.0 * 0.02 * DT), "Repair Node heals the ring's most-damaged standing wedge by the trial 2%/second rate")
	_check(sim.state.rings[2].wedges[9].hp == 50.0, "Repair Node does not touch a less-damaged wedge while a worse one exists")
	_check(sim.state.rings[2].wedges[1].hp == 0.0, "Repair Node never heals a fully broken wedge")
	for tick in range(600): sim.step(DT)
	_check(sim.state.rings[2].wedges[7].hp > before_worst and sim.state.rings[2].wedges[7].hp <= 200.0, "Sustained healing never exceeds max HP")
	sim.ended = true
	_check(not sim.place_armor(1, 8, 0).ok and not sim.place_repair_node(2, 6, 0).ok, "Ended run blocks Armor Plating and Repair Node placement")

func _assimilation_checks() -> void:
	# A destroyed wall grants one stack to every currently active machine, and
	# the +5%/stack damage buff takes effect starting the tick after the grant.
	# Fully sealed (no open gap): D-066-068 route every machine to attack its
	# own local wall, so neither machine detours toward the other's wedge.
	var sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}, "health": {"wedge_base_hp": 1e8}})
	_seal(sim)
	var observer := _add(sim, 6, 192, 100, 5.0)
	var wall_hp_before: float = sim.state.rings[1].wedges[6].wall.hp
	sim.step(DT)
	var wall_hp_after: float = sim.state.rings[1].wedges[6].wall.hp
	var base_damage := wall_hp_before - wall_hp_after
	_check(base_damage > 0.0, "Assimilation fixture observer deals baseline wall damage")
	_check(sim.pool.payload_for(observer).get("assimilation_stacks", []).is_empty(), "No stacks before any destruction")
	sim.state.rings[1].wedges[1].wall.hp = 0.01
	var attacker := _add(sim, 1, 192, 100, 8.0)
	sim.step(DT)
	_check(sim.last_events.walls_broken == [Vector2i(1, 1)], "Assimilation fixture wall breaks")
	_check(sim.pool.payload_for(observer).assimilation_stacks.size() == 1 and sim.pool.payload_for(attacker).assimilation_stacks.size() == 1, "A destroyed wall grants one stack to every active machine, including the one that broke it")
	# Measured on an independent, still-fully-sealed fixture: once wedge 1's
	# wall breaks above, that ring is no longer sealed, and D-066-068 would
	# route machines toward the new opening on the next tick — a real routing
	# effect, not a bug, but it would confound a same-fixture before/after
	# damage comparison. Isolate the multiplier's effect from that instead.
	var buffed_sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}, "health": {"wedge_base_hp": 1e8}})
	_seal(buffed_sim)
	var buffed_observer := _add(buffed_sim, 6, 192, 100, 5.0)
	buffed_sim.pool.payload_for(buffed_observer).assimilation_stacks = [buffed_sim.elapsed_seconds + 15.0]
	var buffed_before: float = buffed_sim.state.rings[1].wedges[6].wall.hp
	buffed_sim.step(DT)
	var buffed_after: float = buffed_sim.state.rings[1].wedges[6].wall.hp
	var buffed_damage := buffed_before - buffed_after
	_check(is_equal_approx(buffed_damage, base_damage * 1.05), "One active stack raises damage output by 5%")

	# A ring collapse grants one stack per occupant/wall it clears, all at once,
	# never a separate flat bonus on top.
	var collapse_sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	var far_observer := _add(collapse_sim, 6, 192, 100, 5.0)
	for wedge in range(1, 7): collapse_sim.state.rings[1].wedges[wedge].hp = 0
	var occupant_and_wall_count: int = collapse_sim.state.rings[1].wedges[12].occupants.size() + collapse_sim.state.rings[1].wedges[6].occupants.size()
	collapse_sim.state.rings[1].wedges[7].hp = 0.01
	_add(collapse_sim, 7, 192, 100, 6.0)
	var result := collapse_sim.step(DT)
	_check(result.events.collapsed_rings == [1], "Collapse fixture ring 1 collapses this tick")
	_check(collapse_sim.pool.payload_for(far_observer).assimilation_stacks.size() == occupant_and_wall_count, "Collapse grants exactly one stack per occupant it clears, not a flat bonus")

	# Cap: at most 10 active stacks (+50%), regardless of how many are stored.
	var capped: Dictionary = {"assimilation_stacks": []}
	var many: Array = []
	for i in range(15): many.append(15.0)
	capped.assimilation_stacks = many
	_check(is_equal_approx(LiveSimulation._assimilation_multiplier(capped, 0.0, baseline), 1.5), "Damage multiplier caps at +50% (10 stacks) even if more are stored")

	# Normal grant flow never grows storage past the cap in the first place.
	# Fresh, still-fully-sealed fixture: the wedge-1 gap from the first fixture
	# would otherwise reroute this new machine before it ever reaches wedge 2.
	var cap_sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	_seal(cap_sim)
	var cap_observer := _add(cap_sim, 6, 192, 100, 5.0)
	var at_cap: Array = []
	for i in range(10): at_cap.append(cap_sim.elapsed_seconds + 15.0)
	cap_sim.pool.payload_for(cap_observer).assimilation_stacks = at_cap
	cap_sim.state.rings[1].wedges[2].wall.hp = 0.01
	_add(cap_sim, 2, 192, 100, 8.0)
	cap_sim.step(DT)
	_check(cap_sim.last_events.walls_broken == [Vector2i(1, 2)] and cap_sim.pool.payload_for(cap_observer).assimilation_stacks.size() == 10, "A machine already at the cap gains no further stacks from a fresh grant")

	# Decay: a stack whose own 15-second timer has elapsed no longer counts,
	# and pruning it frees room for a new one (never a permanent tax). Same
	# isolation reasoning as above: a fresh, still-fully-sealed fixture.
	_check(is_equal_approx(LiveSimulation._assimilation_multiplier({"assimilation_stacks": [0.0]}, 0.0, baseline), 1.0), "An expired stack no longer contributes to the multiplier")
	var decay_sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	_seal(decay_sim)
	var decay_observer := _add(decay_sim, 6, 192, 100, 5.0)
	decay_sim.pool.payload_for(decay_observer).assimilation_stacks = [0.0]
	decay_sim.state.rings[1].wedges[3].wall.hp = 0.01
	_add(decay_sim, 3, 192, 100, 8.0)
	decay_sim.step(DT)
	_check(decay_sim.last_events.walls_broken == [Vector2i(1, 3)] and decay_sim.pool.payload_for(decay_observer).assimilation_stacks.size() == 1 and decay_sim.pool.payload_for(decay_observer).assimilation_stacks[0] > decay_sim.elapsed_seconds, "An expired stack is pruned from storage, making room for a fresh grant")

	# Only machines active at grant time benefit — never future spawns.
	var late_arrival := _add(sim, 6, 192, 100, 5.0)
	_check(sim.pool.payload_for(late_arrival).get("assimilation_stacks", []).is_empty(), "A machine spawned after a grant receives no retroactive stacks")

## D-088: a stunned machine skips movement and attack for the tick, and its
## stun clock counts down by whatever time it would have spent acting.
func _stun_checks() -> void:
	var move_sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	var mover := _add(move_sim, 1, 200, 100, 6.0, 1.0)
	move_sim.pool.payload_for(mover).stun_remaining = DT / 2.0
	var radius_before := _radius(move_sim, mover)
	move_sim.step(DT)
	_check(_radius(move_sim, mover) == radius_before, "A stunned machine does not move this tick")
	_check(move_sim.pool.payload_for(mover).stun_remaining == 0.0, "Stun clock clamps to zero rather than going negative")
	move_sim.step(DT)
	_check(_radius(move_sim, mover) < radius_before, "Once its stun expires, the machine resumes moving on the next tick")

	var attack_sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	var attacker := _add(attack_sim, 1, 192, 100, 6.0)
	attack_sim.pool.payload_for(attacker).stun_remaining = 1.0
	var hp_before: float = attack_sim.state.rings[1].wedges[1].hp
	attack_sim.step(DT)
	_check(attack_sim.state.rings[1].wedges[1].hp == hp_before, "A stunned machine deals no damage this tick even already in contact")
	_check(is_equal_approx(attack_sim.pool.payload_for(attacker).stun_remaining, 1.0 - DT), "Stun clock still counts down while the machine does nothing else")

func _collapse_checks() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	sim.state.energy = 1000
	_check(sim.purchase_ring().ok, "Fixture buys outer ring through public API")
	var energy: float = sim.state.energy
	for wedge in range(1, 7): sim.state.rings[1].wedges[wedge].hp = 0
	sim.step(DT)
	_check(not sim.state.rings[1].get("collapsed", false) and sim.state.rings[1].wedges[12].occupants.size() == 1, "Six distinct breaks retain ring and occupants")
	# Physical approach gap: no normal machine may occupy intact ring2 interior.
	sim.state.rings[2].wedges[7].hp = 0
	sim.state.rings[1].wedges[7].hp = 0.05
	_add(sim, 7, 192)
	var result := sim.step(DT)
	_check(result.events.collapsed_rings == [1] and result.events.broken_wedges == [Vector2i(1, 7)] and sim.state.energy == energy, "Seventh break collapses immediately with no refund")
	var all_empty := true
	for plate in sim.state.rings[1].wedges.values(): all_empty = all_empty and plate.hp == 0 and plate.occupants.is_empty()
	_check(all_empty and sim.state.rings[1].relay.is_empty() and sim.state.rings[1].collapsed, "Collapse clears all occupants and relay and zeroes all HP")
	_check(sim.state.rings[2].wedges[1].hp == 200 and sim.outer_owned_ring() == 2 and sim.state.rings.size() == 2, "Outer ring survives inner loss; historical IDs retained")
	_check(RingPurchaseRules.validate_state(sim.state, baseline).is_empty(), "Valid tombstone accepted")
	var inner_id: int = sim.pool.active_ids()[0]
	sim.step(DT)
	_check(_radius(sim, inner_id) < 192 and sim.state.rings[2].wedges[8].hp == 200 and sim.state.rings[2].relay == {"active": true}, "Machine already inside surviving outer ring advances through collapsed inner gap")
	for kind in ["marker", "hp", "relay", "occupants", "slots", "maxhp", "missing"]:
		var bad := sim.state.duplicate(true)
		match kind:
			"marker": bad.rings[1].collapsed = 1
			"hp": bad.rings[1].wedges[1].hp = 1
			"relay": bad.rings[1].relay = {"wedge": 1, "slot": 0}
			"occupants": bad.rings[1].wedges[1].occupants[0] = {"kind": &"flak"}
			"slots": bad.rings[1].wedges[1].slot_count = 0
			"maxhp": bad.rings[1].wedges[1].max_hp = 0
			"missing": bad.rings[1].wedges.erase(1)
		_check(not RingPurchaseRules.validate_state(bad, baseline).is_empty(), "Malformed tombstone rejected: " + kind)
	_collapse_fixture(sim, 2)
	_check(sim.outer_owned_ring() == 0 and not sim.quote_expansion().ok, "No retake of collapsed historical rings")
	sim.core_hp = 0.05
	var killer := _add(sim, 1, 96, 100, 6)
	var later := _add(sim, 2, 200)
	var before := _radius(sim, later)
	result = sim.step(DT)
	_check(sim.ended and sim.core_hp == 0 and result.events.core_lost and _radius(sim, later) == before and result.events.hits.is_empty(), "Core death stops later machine updates and weapon phase")
	var elapsed := sim.elapsed_seconds
	var saved := sim.state.duplicate(true)
	result = sim.step(DT)
	_check(result.ok and not result.events.core_lost and result.events.spawned_ids.is_empty() and sim.elapsed_seconds == elapsed and sim.state == saved and sim.pool.payload_for(killer).hp == 100, "Ended step has empty events and no gameplay changes")
	_check(not sim.purchase_ring().ok and not sim.place_weapon(1, 1, 0, &"flak").ok and not sim.quote_expansion().ok, "Ended run blocks all purchases")

func _capacity_and_transactions() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 0}})
	var victim := _add(sim, 12, 240, 1, 0)
	var result := sim.step(DT)
	_check(result.events.kill_ids == [victim] and result.events.energy_awarded == 2 and sim.state.energy == 202 and sim.pool.active_count() == 0, "Weapon kill banks reward and releases pool entry once")
	result.events.kill_ids.append(999)
	_check(sim.last_events.kill_ids == [victim], "Returned events isolated from last events")
	result = sim.step(DT)
	_check(result.events.kill_ids.is_empty() and sim.state.energy == 202, "Successive tick cannot bank kill twice")
	sim = _sim({"pressure": {"spawn_per_second": 120, "max_active_machines": 2}, "flak": {"damage": 0}})
	result = sim.step(DT)
	_check(result.events.spawned_ids.size() == 2 and sim.pool.active_count() == 2 and sim.skipped_arrivals == 0, "Configured small capacity admits earliest arrivals")
	sim.step(DT)
	_check(sim.skipped_arrivals == 2 and sim.pool.active_count() == 2, "Full pool permanently skips arrivals")
	sim.pool.release(sim.pool.active_ids()[0])
	result = sim.step(DT)
	_check(result.events.spawned_ids.size() == 1 and sim.skipped_arrivals == 3 and sim.pool.payload_for(result.events.spawned_ids[0]).position.wedge == 4, "Freed capacity admits sequence 5 with no deferred burst")
	sim = _sim({"pressure": {"spawn_per_second": 0}})
	sim.state.energy = 1000
	var blocker := _add(sim, 1, 240)
	var saved := sim.state.duplicate(true)
	_check(not sim.quote_expansion().ok and not sim.purchase_ring().ok and sim.state == saved, "Occupied candidate band rejects quote and purchase without spend")
	sim.pool.release(blocker)
	var boundary_blocker := _add(sim, 1, 192)
	_check(not sim.quote_expansion().ok, "Exact inner boundary belongs to candidate outward band and blocks expansion")
	sim.pool.release(boundary_blocker)
	var outside_band := _add(sim, 1, 288)
	_check(sim.quote_expansion().ok, "Exact outer boundary belongs to next outward band and permits candidate purchase")
	_check(sim.pool.payload_for(outside_band).position.ring == 3, "Boundary fixture authoritative polar band")
	var bought := sim.purchase_ring()
	_check(bought.ok and sim.state.energy == 760 and sim.state.rings.size() == 2, "Clear candidate band purchase succeeds")
	bought.state.rings[2].wedges[2].hp = 0
	_check(sim.state.rings[2].wedges[2].hp == 200, "Purchase return state independent")
	var spawn_sim := _sim({"pressure": {"spawn_per_second": 60}})
	_collapse_fixture(spawn_sim, 1)
	var spawn_result := spawn_sim.step(DT)
	_check(spawn_sim.pool.payload_for(spawn_result.events.spawned_ids[0]).position.ring == 3, "Spawn radius uses outer owned zero rather than collapsed history")

func _error_rollback() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 60}})
	var old_id := _add(sim, 1, 200)
	var saved := sim.state.duplicate(true)
	var before := _radius(sim, old_id)
	var original_position: PolarPosition = sim.pool.payload_for(old_id).position
	var original_fraction := original_position.radial_fraction
	sim.cooldowns[&"malformed"] = 0
	var result := sim.step(DT)
	_check(not result.ok and sim.pool.active_count() == 1 and _radius(sim, old_id) == before and sim.state == saved and sim.elapsed_seconds == 0 and sim.skipped_arrivals == 0 and sim.last_events.spawned_ids.is_empty(), "Unexpected downstream error rolls back gameplay and tentative admissions")
	_check(sim.pool.payload_for(old_id).position == original_position and original_position.radial_fraction == original_fraction, "Private staged position reference remains unchanged after moved/admitted failed tick")
	sim.cooldowns = {}
	result = sim.step(DT)
	_check(result.ok and result.events.spawned_ids[0] > old_id + 1, "Rolled-back admission lifetime ID remains consumed")
	var bad := _sim({"pressure": {"spawn_per_second": 60, "spawn_offset_ring_widths": 1e308}})
	result = bad.step(DT)
	_check(not result.ok and bad.pool.active_count() == 0 and bad.elapsed_seconds == 0, "Invalid candidate descriptor fails before admissions")

func _benchmark() -> void:
	for forced_ready in [false, true]:
		var sim := _sim({"pressure": {"spawn_per_second": 0}, "health": {"wedge_base_hp": 1e12, "standard_machine_hp": 1e12}, "standard_machine": {"damage_per_second": 0.01}})
		sim.state.energy = 10000
		for wedge in range(1, 12):
			if wedge != 6: sim.place_weapon(1, wedge, 0, &"flak")
		for index in range(1000): _add(sim, index % 12 + 1, 192, 1e12, 0.01)
		var times: Array[int] = []
		var hit_counts: Array[int] = []
		for sample in range(13):
			# Test-only peak-work fixture; production cadence remains unchanged.
			if forced_ready: sim.cooldowns = {}
			var started := Time.get_ticks_usec()
			var result := sim.step(DT)
			var duration := Time.get_ticks_usec() - started
			_check(result.ok and not sim.ended and sim.pool.active_count() == 1000 and result.events.kill_ids.is_empty(), "Bounded durable-contact benchmark remains valid")
			if sample >= 3:
				times.append(duration)
				hit_counts.append(result.events.hits.size())
		times.sort()
		print("Integrated 1000-machine full-step: mode=%s warmups=3 n=10 median_us=%.1f p90_us=%d max_us=%d measured_hits=%s" % ["forced_ready" if forced_ready else "normal_cadence", (times[4] + times[5]) / 2.0, times[8], times[9], hit_counts])


func _seal(sim: LiveSimulation, except_wedge: int = -1) -> void:
	sim.state.energy = 10000
	for wedge in range(1, 13):
		if wedge != except_wedge:
			var result := sim.place_wall(1, wedge)
			_check(result.ok, "Fixture wall placement succeeds")
func _angle_units(p: PolarPosition) -> float:
	return fposmod(p.wedge % 12 + p.angular_fraction - 0.5, 12)
func _wall_integration_checks() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	var placed := sim.place_wall(1, 12)
	_check(placed.ok and sim.state.energy == 195 and sim.state.rings[1].wedges[12].occupants[0].kind == &"flak" and sim.elapsed_seconds == 0, "Live wall transaction preserves slot, deducts once, and does not pause")
	placed.state.rings[1].wedges[12].wall.hp = 1
	_check(sim.state.rings[1].wedges[12].wall.hp == 50 and not sim.place_wall(1, 12).ok, "Wall return isolated; duplicate rejected")
	sim = _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	_seal(sim)
	var id := _add(sim, 1, 192, 100, 8)
	var result := sim.step(DT)
	_check(result.ok and is_equal_approx(sim.state.rings[1].wedges[1].wall.hp, 50 - 8 * 0.25 * DT) and sim.state.rings[1].wedges[1].hp == 100, "Sealed region damages wall at25percent and protects wedge")
	var builds := sim.route_rebuild_count
	sim.step(DT)
	_check(sim.route_rebuild_count == builds, "HP-only damage reuses shared fields")
	sim.state.rings[1].wedges[1].wall.hp = 0.01
	var later := _add(sim, 2, 192, 100, 8)
	var energy: float = sim.state.energy
	result = sim.step(DT)
	_check(result.ok and result.events.walls_broken == [Vector2i(1, 1)] and not sim.state.rings[1].wedges[1].has("wall") and sim.state.rings[1].wedges[1].hp == 100 and sim.state.energy == energy and result.events.energy_awarded == 0, "Wall destruction erases record once without wedge spill or reward")
	_check(sim.state.rings[1].wedges[2].wall.hp == 50 and sim.pool.payload_for(later).position.angular_fraction != 0.5 and sim.route_rebuild_count == builds + 1, "Later ID routes toward new opening instead of attacking another wall in same tick")
	sim.step(DT)
	_check(sim.state.rings[1].wedges[1].hp < 100 and sim.pool.payload_for(id).hp == 100 and sim.last_events.walls_broken.is_empty(), "Wall breaker resumes exposed-wedge attack next tick")
	var zero := _sim({"pressure": {"spawn_per_second": 0}, "standard_machine": {"wall_damage_multiplier": 0}, "flak": {"damage": 0}})
	_seal(zero)
	_add(zero, 1, 192)
	zero.step(DT)
	_check(zero.state.rings[1].wedges[1].wall.hp == 50, "Zero multiplier prevents wall damage without wedge substitution")
	var support := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	_seal(support)
	support.state.rings[1].wedges[1].hp = 0
	id = _add(support, 1, 192)
	support.step(DT)
	_check(_radius(support, id) < 192 and support.state.rings[1].wedges[1].wall.hp == 50, "Broken supporting wedge opens inward path despite retained wall record")
	var collapse := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	_seal(collapse, 7)
	for wedge in range(1, 7): collapse.state.rings[1].wedges[wedge].hp = 0
	collapse.state.rings[1].wedges[7].hp = 0.01
	_add(collapse, 7, 192)
	result = collapse.step(DT)
	var no_walls := true
	for plate in collapse.state.rings[1].wedges.values(): no_walls = no_walls and not plate.has("wall")
	_check(result.ok and result.events.collapsed_rings == [1] and no_walls and RingPurchaseRules.validate_state(collapse.state, baseline).is_empty(), "Ring collapse erases all walls before tombstone validation")
	var angular := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	angular.place_wall(1, 1)
	id = _add(angular, 1, 192, 100, 8)
	for tick in range(1, 61):
		result = angular.step(DT)
		_check(result.ok and is_equal_approx(_radius(angular, id), 192) and angular.state.rings[1].wedges[2].hp == 100, "Angular approach stays on boundary and cannot attack before goal node")
	var p: PolarPosition = angular.pool.payload_for(id).position
	_check(p.wedge == 2 and p.angular_fraction < 0.5 and is_equal_approx((_angle_units(p) - 1) * TAU / 12 * 192, 96), "Waypoint crosses wedge seam at physical arc speed without chord or center snap")
	var nav_before := angular._navigation
	var waypoint_before: PolarPosition = angular._waypoints[id]
	var angle_before := _angle_units(p)
	var elapsed_before := angular.elapsed_seconds
	angular.cooldowns[&"malformed"] = 0
	result = angular.step(DT)
	_check(not result.ok and angular._navigation == nav_before and angular._waypoints[id] == waypoint_before and angular.elapsed_seconds == elapsed_before and _angle_units(angular.pool.payload_for(id).position) == angle_before, "Failed angular tick preserves navigation and private waypoint state")
	angular.cooldowns = {}
	for tick in range(3): angular.step(DT)
	_check(angular.state.rings[1].wedges[2].hp < 100 and angular.route_rebuild_count == 1, "Node arrival spends fractional remaining time on DPS without extra pause or rebuild")
	var reroute := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	reroute.place_wall(1, 1)
	id = _add(reroute, 1, 192)
	for tick in range(32): reroute.step(DT)
	p = reroute.pool.payload_for(id).position
	angle_before = _angle_units(p)
	reroute.place_wall(1, 2)
	reroute.step(DT)
	_check(reroute.route_rebuild_count == 2 and is_equal_approx((_angle_units(reroute.pool.payload_for(id).position) - angle_before) * TAU / 12 * 192, 1.6), "Topology change mid-seam aligns safely within current cell without teleport")
	var expansion := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	id = _add(expansion, 1, 384)
	expansion.step(DT)
	expansion.state.energy = 1000
	_check(expansion.purchase_ring().ok, "Route refresh expansion fixture clear candidate band")
	expansion.step(DT)
	_check(expansion.route_rebuild_count == 2 and expansion._navigation.route_for(Vector2i(3, 1)).target_cell == Vector2i(2, 1), "Ring purchase rebuilds route to new outer surface")
	var bad := _sim({"pressure": {"spawn_per_second": 60}})
	_add(bad, 1, 150)
	result = bad.step(DT)
	_check(not result.ok and bad.pool.active_count() == 1 and bad.elapsed_seconds == 0 and bad.route_rebuild_count == 0, "Embedded intact-cell source rejected before admissions/cache mutation")
	var horizon := _sim({"pressure": {"spawn_per_second": 0}})
	id = _add(horizon, 1, 576, 100, 0)
	horizon.step(DT)
	builds = horizon.route_rebuild_count
	horizon.step(DT)
	_check(horizon._nav_horizon == 6 and horizon.route_rebuild_count == builds, "Horizon grows for far machine and does not shrink as it moves inward")
	var near_node := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	id = _add(near_node, 1, 192)
	near_node.pool.payload_for(id).position.angular_fraction = 0.5 - 1e-14
	result = near_node.step(DT)
	_check(result.ok and is_equal_approx(near_node.state.rings[1].wedges[1].hp, 99.9), "Tolerance-close zero-time node reach consumes waypoint and applies leftover DPS")
	var previous_navigation := reroute._navigation
	var previous_waypoints := reroute._waypoints.duplicate()
	builds = reroute.route_rebuild_count
	reroute.state.energy = 1000
	reroute.place_wall(1, 3)
	reroute.cooldowns[&"malformed"] = 0
	result = reroute.step(DT)
	_check(not result.ok and reroute._navigation == previous_navigation and reroute._waypoints == previous_waypoints and reroute.route_rebuild_count == builds, "Downstream failure rolls back newly rebuilt topology and reset waypoints")
	reroute.cooldowns = {}
	reroute.step(DT)
	_check(reroute.route_rebuild_count == builds + 1, "Retry rebuilds pending topology successfully")
	var stale := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	stale.place_wall(1, 1)
	var stale_id := _add(stale, 1, 192)
	stale.step(DT)
	_check(stale._waypoints.has(stale_id), "Moving lifetime gets private endpoint")
	stale.pool.release(stale_id)
	stale.step(DT)
	_check(not stale._waypoints.has(stale_id), "Membership cleanup removes released lifetime endpoint even with no active targets")
	sim.ended = true
	_check(not sim.place_wall(1, 3).ok, "Ended run rejects wall placement")

func _wall_benchmarks() -> void:
	for mode in ["sealed_contact", "angular_funnel"]:
		var sim := _sim({"pressure": {"spawn_per_second": 0}, "health": {"wedge_base_hp": 1e12, "wall_hp": 1e12, "standard_machine_hp": 1e12}, "standard_machine": {"damage_per_second": 0.01}})
		_seal(sim, 12 if mode == "angular_funnel" else -1)
		for wedge in range(1, 12):
			if wedge != 6: sim.place_weapon(1, wedge, 0, &"flak")
		for index in range(1000): _add(sim, index % 11 + 1 if mode == "angular_funnel" else index % 12 + 1, 192, 1e12, 0.01)
		var times: Array[int] = []
		var hits: Array[int] = []
		var rebuilds: Array[int] = []
		for sample in range(13):
			var before := sim.route_rebuild_count
			var started := Time.get_ticks_usec()
			var result := sim.step(DT)
			var duration := Time.get_ticks_usec() - started
			_check(result.ok and sim.pool.active_count() == 1000 and not sim.ended, "Wall benchmark full crowd remains valid")
			if sample >= 3:
				times.append(duration)
				hits.append(result.events.hits.size())
				rebuilds.append(sim.route_rebuild_count - before)
		times.sort()
		print("Wall full-step1000 mode=%s warmups=3 n=10 median_us=%.1f p90_us=%d hits=%s rebuilds=%s total_builds=%d" % [mode, (times[4] + times[5]) / 2.0, times[8], hits, rebuilds, sim.route_rebuild_count])



func _cost_fixture(mode: String) -> LiveSimulation:
	# power.base_output raised: this fixture predates D-023 and places up to 11
	# Flak on a single ring purely for load-testing; it is not a power-balance
	# scenario, and the digest baseline must see identical resulting state.
	var sim := _sim({"pressure": {"spawn_per_second": 0}, "health": {"wedge_base_hp": 1e8, "wall_hp": 1e8, "standard_machine_hp": 1e8}, "standard_machine": {"damage_per_second": 1.0}, "power": {"base_output": 1.0e6}})
	sim.state.energy = 10000
	var ring := 1 if mode == "sustained_sealed" else 3
	for outer in range(2, ring + 1): sim.purchase_ring()
	for wedge in range(1, 13):
		if mode == "sustained_sealed" or wedge != 12: sim.place_wall(ring, wedge)
		if wedge != 6 and (ring != 1 or wedge != 12): sim.place_weapon(ring, wedge, 0 if ring == 1 else 1, &"flak")
	for index in range(1000): _add(sim, index % 12 + 1 if ring == 1 else index % 7 + 3, 96.0 + ring * 96.0, 1e8, 1.0)
	sim._measure_costs = true
	return sim
func _state_digest(sim: LiveSimulation, result: Dictionary) -> String:
	var targets := []
	for target in sim.targets_snapshot():
		var p: PolarPosition = target.position
		target.position = [p.ring, p.wedge, p.radial_fraction, p.angular_fraction]
		targets.append(target)
	var endpoints := []
	var ids: Array = sim._waypoints.keys()
	ids.sort()
	for id in ids:
		var p: PolarPosition = sim._waypoints[id]
		endpoints.append([id, p.ring, p.wedge, p.radial_fraction, p.angular_fraction])
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(var_to_bytes([sim.state, sim.core_hp, sim.elapsed_seconds, sim.ended, sim.cooldowns, result, sim.last_events, sim.skipped_arrivals, targets, endpoints, sim._nav_fingerprint, sim._nav_horizon, sim.route_rebuild_count]))
	return digest.finish().hex_encode()
func _cost_review() -> void:
	var angular_only := "--cost-angular-only" in OS.get_cmdline_user_args()
	var sealed_only := "--cost-sealed-only" in OS.get_cmdline_user_args()
	var omit_digest := "--cost-no-digest" in OS.get_cmdline_user_args()
	# Isolated diagnostics omit preceding fixtures while preserving digest offsets.
	if not angular_only and not sealed_only: _wall_benchmarks()
	var record := "--record-cost-baseline" in OS.get_cmdline_user_args()
	var baseline_path := "res://tests/performance/baselines/t-023-sustained-cost-digests.bin"
	var expected: Array = []
	if not record:
		var source := FileAccess.open(baseline_path, FileAccess.READ)
		_check(source != null, "Recorded baseline exists")
		if source == null: return
		expected = source.get_var()
		source.close()
	var recorded := []
	var compared := 123 if angular_only else 0
	for mode in ["sustained_sealed", "sustained_ring3_angular"]:
		if angular_only and mode != "sustained_ring3_angular": continue
		if sealed_only and mode != "sustained_sealed": continue
		var sim := _cost_fixture(mode)
		var initial_energy: float = sim.state.energy
		var samples := {"total_us": [], "preflight_us": [], "movement_us": [], "motion_us": [], "weapon_us": [], "persistence_us": []}
		var hits: Array[int] = []
		var moved: Array[int] = []
		var attacking: Array[int] = []
		var rebuilds: Array[int] = []
		for sample in range(123):
			var before := sim.targets_snapshot()
			var previous_builds := sim.route_rebuild_count
			var started := Time.get_ticks_usec()
			var result := sim.step(DT)
			var duration := Time.get_ticks_usec() - started
			_check(result.ok and not sim.ended and sim.pool.active_count() == 1000 and result.events.kill_ids.is_empty() and result.events.collapsed_rings.is_empty() and result.events.walls_broken.is_empty() and sim.state.energy == initial_energy, "Sustained fixture lifecycle maintained")
			if not omit_digest:
				var digest := _state_digest(sim, result)
				recorded.append(digest)
				if not record:
					_check(compared < expected.size() and expected[compared] == digest, "Exact baseline full-state/event/waypoint digest tick %d" % compared)
			compared += 1
			if sample >= 3:
				samples.total_us.append(duration)
				for key in sim._last_step_costs:
					if samples.has(key): samples[key].append(sim._last_step_costs[key])
				hits.append(result.events.hits.size())
				attacking.append(sim._last_step_costs.attack_calls)
				rebuilds.append(sim.route_rebuild_count - previous_builds)
				var moved_count := 0
				for target in before:
					var p: PolarPosition = sim.pool.payload_for(target.id).position
					var old: PolarPosition = target.position
					if p.ring != old.ring or p.wedge != old.wedge or p.radial_fraction != old.radial_fraction or p.angular_fraction != old.angular_fraction: moved_count += 1
				moved.append(moved_count)
				_check(moved_count == (0 if mode == "sustained_sealed" else 1000) and sim._last_step_costs.attack_calls == (1000 if mode == "sustained_sealed" else 0), "All sustained machines retain expected moving/attacking role")
		var volley_count := 0
		for count in hits:
			if count > 0: volley_count += 1
		_check((volley_count == 8 if mode == "sustained_sealed" else volley_count >= 2) and rebuilds.all(func(count: int) -> bool: return count == 0), "Sustained sample includes multiple normal-cadence volleys and no topology rebuilds")
		print("COST_CHRONOLOGY mode=%s omit_digest=%s total_us=%s" % [mode, omit_digest, samples.total_us])
		var summary := {}
		for phase in samples:
			var times: Array = samples[phase]
			times.sort()
			summary[phase] = {"median": (float(times[59]) + float(times[60])) / 2.0, "p90": times[107]}
		print("COST_PHASES mode=%s n=120 warmups=3 units=us %s" % [mode, JSON.stringify(summary)])
		print("COST_COUNTS mode=%s hits=%s moved=%s attacking=%s rebuilds=%s" % [mode, hits, moved, attacking, rebuilds])
	if record and not omit_digest:
		var output := FileAccess.open(baseline_path, FileAccess.WRITE)
		output.store_var(recorded)
		output.close()
	elif not omit_digest: _check(compared == (123 if sealed_only else expected.size()), "All selected recorded baseline states compared at original offsets")
	if omit_digest: print("DIAGNOSTIC ONLY: outside-timed full-state digests omitted; ordinary correctness mode is unchanged")
	print("Cost review: %d checks, %d failures" % [checks, failures])







func _owned_combat_rollback() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 60}, "mass_driver": {"range_ring_widths": 1e308}})
	sim.state.energy = 10000
	sim.place_weapon(1, 1, 0, &"flak")
	sim.place_weapon(1, 11, 0, &"mass_driver")
	var id := _add(sim, 1, 192, 10, 6)
	var p: PolarPosition = sim.pool.payload_for(id).position
	var original_state := sim.state.duplicate(true)
	var original_events := sim.last_events.duplicate(true)
	var original_core := sim.core_hp
	var result := sim.step(DT)
	_check(not result.ok and result.events.hits.is_empty(), "Late owned combat failure publishes no scratch hits")
	_check(sim.pool.active_count() == 1 and sim.pool.payload_for(id).hp == 10 and sim.pool.payload_for(id).position == p and _radius(sim, id) == 192, "Earlier owned HP damage never reaches pool on later weapon failure")
	_check(sim.state == original_state and sim.core_hp == original_core and sim.elapsed_seconds == 0 and sim.cooldowns.is_empty() and sim.last_events == original_events and sim.route_rebuild_count == 0 and sim._navigation == null and sim._waypoints.is_empty() and sim.skipped_arrivals == 0, "Late combat failure rolls back surface damage, navigation, admission, events and clock")

func _tunnel_sim(overrides: Dictionary = {}, rings: int = 2) -> LiveSimulation:
	var profile: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 0, "spawn_delay_seconds": 0}, "flak": {"damage": 0}, "tunneler": {"first_arrival_seconds": DT}}).profile.with_overrides(overrides).profile
	var sim: LiveSimulation = LiveSimulation.create(profile, 5, true).simulation
	sim.state.energy = 100000
	for ring in range(2, rings + 1): _check(sim.purchase_ring().ok, "Tunneler fixture expansion %d" % ring)
	return sim

func _ticks_ok(sim: LiveSimulation, count: int, label: String) -> Dictionary:
	var result := {}
	var all_ok := true
	for tick in range(count):
		result = sim.step(DT)
		if not result.ok:
			all_ok = false
			break
	_check(all_ok, label + " " + str(result.get("errors", [])))
	return result

func _foundry_sim(overrides: Dictionary = {}, rings: int = 2) -> LiveSimulation:
	var profile: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 0, "spawn_delay_seconds": 0}, "flak": {"damage": 0}, "foundry": {"first_arrival_seconds": DT}}).profile.with_overrides(overrides).profile
	var sim: LiveSimulation = LiveSimulation.create(profile, 5, false, true).simulation
	sim.state.energy = 100000
	for ring in range(2, rings + 1): _check(sim.purchase_ring().ok, "Foundry fixture expansion %d" % ring)
	return sim

## D-106: Foundry is a standard machine with a "kind" tag and no special
## movement or targeting at all — reuses _advance_machine and ordinary combat.
func _foundry_checks() -> void:
	_check(not _sim().foundry_enabled, "Legacy create defaults to normals only")
	var sim := _foundry_sim()
	var result := sim.step(DT)
	_check(result.ok and result.events.spawned_ids.size() == 1 and sim.pool.active_count() == 1, "Foundry admitted at its own scheduled due time")
	var id: int = result.events.spawned_ids[0]
	var payload := sim.pool.payload_for(id)
	_check(payload.get("kind") == &"foundry", "Admitted machine carries the foundry kind tag")
	var base: Dictionary = MachineSpawnRules.stats_at(sim.profile, DT).stats
	_check(is_equal_approx(payload.hp, base.hp * float(sim.profile.value("foundry.hp_multiplier"))), "Foundry HP uses the configured multiplier")

	# Reuses ordinary movement/attack: no special handling, so it moves toward
	# the core exactly like a standard machine of the same speed. Arrival lands
	# with zero leftover time at the due boundary, so movement needs a further tick.
	var moving := _foundry_sim({"pressure": {"speed_ring_widths_per_second": 100}, "foundry": {"speed_multiplier": 1.0}})
	moving.step(DT)
	var moving_id: int = moving.pool.active_ids()[0]
	var radius_at_arrival := _radius(moving, moving_id)
	moving.step(DT)
	_check(_radius(moving, moving_id) < radius_at_arrival, "Foundry advances toward the core exactly like a standard machine")

	# Capacity/skip counter parity with Tunneler's own dedicated counter.
	var full := _foundry_sim({"pressure": {"max_active_machines": 1}}, 1)
	_add(full, 1, 200)
	full.step(DT)
	_check(full.skipped_foundry_arrivals == 1, "A full pool permanently skips a due Foundry, tracked in its own counter")

	# Exact-time tie priority: Tunneler beats Foundry beats normal.
	var tied: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 60, "spawn_delay_seconds": 0, "max_active_machines": 1}, "tunneler": {"first_arrival_seconds": DT}, "foundry": {"first_arrival_seconds": DT}, "flak": {"damage": 0}}).profile
	var tied_sim: Dictionary = LiveSimulation.create(tied, 2, true, true)
	_check(tied_sim.ok, "Tie fixture simulation valid")
	var tied_live: LiveSimulation = tied_sim.simulation
	tied_live.state.energy = 100000
	_check(tied_live.purchase_ring().ok, "Tie fixture owns a second ring")
	tied_live.step(DT)
	var tied_ids := tied_live.pool.active_ids()
	_check(tied_ids.size() == 1 and tied_live.pool.payload_for(tied_ids[0]).get("kind") == &"tunneler", "On an exact-time tie, Tunneler is admitted ahead of Foundry and normal")

func _transfer_sim(overrides: Dictionary = {}, rings: int = 2) -> LiveSimulation:
	var profile: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 0, "spawn_delay_seconds": 0}, "flak": {"damage": 0}, "transfer": {"first_arrival_seconds": DT}}).profile.with_overrides(overrides).profile
	var sim: LiveSimulation = LiveSimulation.create(profile, 5, false, false, true).simulation
	sim.state.energy = 100000
	for ring in range(2, rings + 1): _check(sim.purchase_ring().ok, "Transfer fixture expansion %d" % ring)
	return sim

func _add_transfer(sim: LiveSimulation, wedge: int, radius: float, hp: float = 100, dps: float = 6, speed: float = 1) -> int:
	var band := (radius - 96) / 96
	# A raw normal-machine spawn descriptor is always exactly 6 keys (sequence,
	# elapsed_seconds, position, hp, damage_per_second, speed); the generic
	# per-tick kind-field copy in _target_record only runs above that size, so
	# a hand-built fixture must clear it too or its "kind"/"hopped" tag is
	# silently dropped on the very first tick.
	return sim.pool.spawn({"kind": &"transfer", "hopped": false, "position": PolarPosition.new(int(floorf(band)) + 1, wedge, band - floorf(band), 0.5), "hp": hp, "damage_per_second": dps, "speed_ring_widths_per_second": speed, "assimilation_stacks": [], "stun_remaining": 0.0})

## D-107: Transfer paths inward as a standard machine, spends its one hop the
## first time it reaches an intact ring's boundary (skipping that ring's
## wedge/wall untouched), then behaves as an entirely standard machine again.
func _transfer_checks() -> void:
	_check(not _sim().transfer_enabled, "Legacy create defaults to normals only")
	var sim := _transfer_sim()
	var result := sim.step(DT)
	_check(result.ok and result.events.spawned_ids.size() == 1, "Transfer admitted at its own scheduled due time")
	var id: int = result.events.spawned_ids[0]
	var payload := sim.pool.payload_for(id)
	_check(payload.get("kind") == &"transfer" and payload.get("hopped") == false, "Admitted machine carries the transfer kind tag, hop unspent")
	var base: Dictionary = MachineSpawnRules.stats_at(sim.profile, DT).stats
	_check(is_equal_approx(payload.hp, base.hp), "No stat multiplier - identical HP to a standard machine")

	# Single owned ring: the hop past ring 1's intact wedge lands directly in
	# front of the core (nothing behind ring 1 but the core itself).
	var single := _transfer_sim({}, 1)
	var t1 := _add_transfer(single, 1, 192)
	var core_before := single.core_hp
	var wedge_before: float = single.state.rings[1].wedges[1].hp
	var hop := single.step(DT)
	_check(hop.ok, "Hop tick succeeds")
	var hopped_payload := single.pool.payload_for(t1)
	_check(hopped_payload.hopped == true and hopped_payload.hop_cell == Vector2i(1, 1), "Hop spent, landing band recorded")
	_check(hopped_payload.position.ring == 1 and hopped_payload.position.wedge == 1 and hopped_payload.position.radial_fraction == 0.0 and hopped_payload.position.angular_fraction == 0.5, "Lands exactly at the boundary of the ring behind the one it skipped")
	_check(single.core_hp == core_before and single.state.rings[1].wedges[1].hp == wedge_before, "No damage either way on the hop itself")
	var second := single.step(DT)
	_check(second.ok and single.core_hp < core_before, "Standing in the phantom landing band, it now attacks the core directly - ring 1's own wall was never touched")
	_check(single.state.rings[1].wedges[1].hp == wedge_before, "Skipped ring's wedge remains untouched for the rest of its life")

	# Two owned rings: hop past ring 2, then grind ring 1's wedge like a
	# standard machine, then resume ordinary pathing once ring 1 opens.
	var deep := _transfer_sim({"flak": {"damage": 0}}, 2)
	var t2 := _add_transfer(deep, 1, 288, 100, 1000)
	deep.step(DT)
	var landed := deep.pool.payload_for(t2)
	_check(landed.hopped and landed.hop_cell == Vector2i(2, 1) and landed.position.ring == 2, "Hops past ring 2, landing in band 2")
	_check(deep.state.rings[2].wedges[1].hp == deep.state.rings[2].wedges[1].max_hp, "Ring 2's own wedge (the one skipped) is never damaged")
	var ring1_hp: float = deep.state.rings[1].wedges[1].hp
	deep.step(DT)
	_check(deep.state.rings[1].wedges[1].hp < ring1_hp and deep.pool.payload_for(t2).position.ring == 2, "From the landing band it grinds ring 1's wedge exactly like a standard machine")
	deep.state.rings[1].wedges[1].hp = 0.01
	deep.step(DT)
	_check(deep.state.rings[1].wedges[1].hp == 0 and deep.pool.payload_for(t2).position.ring == 2, "T065 breaking ring 1 does not grant an extra instantaneous traversal")
	var deep_core_before := deep.core_hp
	deep.step(DT)
	_check(deep.core_hp == deep_core_before and deep.pool.payload_for(t2).position.radial_fraction > 0.9, "T065 post-hop gap traversal spends physical time")
	_ticks_ok(deep, 60, "T065 normal radial travel to core")
	_check(deep.core_hp < deep_core_before, "After physical traversal it attacks the core through ordinary navigation")
	_check(deep.state.rings[2].wedges[1].hp == deep.state.rings[2].wedges[1].max_hp, "The originally skipped ring 2 wedge was never damaged across its whole life")

	# Capacity/skip counter parity with Tunneler/Foundry's own dedicated counters.
	var full := _transfer_sim({"pressure": {"max_active_machines": 1}}, 1)
	_add(full, 1, 200)
	full.step(DT)
	_check(full.skipped_transfer_arrivals == 1, "A full pool permanently skips a due Transfer, tracked in its own counter")

	# Exact-time tie priority: Transfer beats normal, loses to Foundry.
	var tied: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 60, "spawn_delay_seconds": 0, "max_active_machines": 1}, "foundry": {"first_arrival_seconds": DT}, "transfer": {"first_arrival_seconds": DT}, "flak": {"damage": 0}}).profile
	var tied_sim: Dictionary = LiveSimulation.create(tied, 2, false, true, true)
	_check(tied_sim.ok, "Tie fixture simulation valid")
	var tied_live: LiveSimulation = tied_sim.simulation
	tied_live.state.energy = 100000
	_check(tied_live.purchase_ring().ok, "Tie fixture owns a second ring")
	tied_live.step(DT)
	var tied_ids := tied_live.pool.active_ids()
	_check(tied_ids.size() == 1 and tied_live.pool.payload_for(tied_ids[0]).get("kind") == &"foundry", "On an exact-time tie, Foundry is admitted ahead of Transfer and normal")

	var transfer_over_normal: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 60, "spawn_delay_seconds": 0, "max_active_machines": 1}, "transfer": {"first_arrival_seconds": DT}, "flak": {"damage": 0}}).profile
	var normal_tied: LiveSimulation = LiveSimulation.create(transfer_over_normal, 2, false, false, true).simulation
	normal_tied.state.energy = 100000
	normal_tied.step(DT)
	_check(normal_tied.pool.payload_for(normal_tied.pool.active_ids()[0]).get("kind") == &"transfer", "On an exact-time tie, Transfer is admitted ahead of normal")

func _sapper_sim(overrides: Dictionary = {}, rings: int = 2) -> LiveSimulation:
	var profile: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 0, "spawn_delay_seconds": 0}, "flak": {"damage": 0}, "sapper": {"first_arrival_seconds": DT}}).profile.with_overrides(overrides).profile
	var sim: LiveSimulation = LiveSimulation.create(profile, 5, false, false, false, true).simulation
	sim.state.energy = 100000
	for ring in range(2, rings + 1): _check(sim.purchase_ring().ok, "Sapper fixture expansion %d" % ring)
	return sim

func _add_sapper(sim: LiveSimulation, wedge: int, radius: float, hp: float = 100, dps: float = 6, speed: float = 1) -> int:
	var band := (radius - 96) / 96
	return sim.pool.spawn({"kind": &"sapper", "position": PolarPosition.new(int(floorf(band)) + 1, wedge, band - floorf(band), 0.5), "hp": hp, "damage_per_second": dps, "speed_ring_widths_per_second": speed, "assimilation_stacks": [], "stun_remaining": 0.0})

## D-108: Sapper reuses ordinary movement/wall interaction completely; only
## its attack target differs - it drains a ring's relay_hp instead of wedge
## HP once attacking a bare wedge, but a standing wall remains a normal
## obstacle, damaged exactly like any standard machine would.
func _sapper_checks() -> void:
	_check(not _sim().sapper_enabled, "Legacy create defaults to normals only")
	var sim := _sapper_sim()
	var result := sim.step(DT)
	_check(result.ok and result.events.spawned_ids.size() == 1, "Sapper admitted at its own scheduled due time")
	var id: int = result.events.spawned_ids[0]
	var payload := sim.pool.payload_for(id)
	_check(payload.get("kind") == &"sapper", "Admitted machine carries the sapper kind tag")
	var base: Dictionary = MachineSpawnRules.stats_at(sim.profile, DT).stats
	_check(is_equal_approx(payload.hp, base.hp), "No stat multiplier - identical HP to a standard machine")

	# Attacking a bare wedge (no wall): damage drains relay_hp, wedge HP untouched.
	var drain := _sapper_sim({}, 1)
	var wedge_before: float = drain.state.rings[1].wedges[1].hp
	var relay_before: float = drain.state.rings[1].relay_hp
	_add_sapper(drain, 1, 192)
	drain.step(DT)
	_check(drain.state.rings[1].wedges[1].hp == wedge_before, "Attacking a bare wedge never touches its own HP")
	_check(drain.state.rings[1].relay_hp < relay_before, "Damage instead drains the ring's relay_hp pool")

	# A standing wall is a normal obstacle: damaged like any standard machine;
	# relay_hp and wedge HP both untouched while the wall stands. The whole
	# ring must be sealed (no exposed alternative) or funneling would route the
	# Sapper around to an open wedge instead, exactly like a standard machine.
	var walled := _sapper_sim({}, 1)
	walled.state.energy = 100000
	for wedge in range(1, 13): _check(walled.place_wall(1, wedge).ok, "Wall fixture placement succeeds")
	var wall_hp_before: float = walled.state.rings[1].wedges[2].wall.hp
	var wall_relay_before: float = walled.state.rings[1].relay_hp
	var wall_wedge_before: float = walled.state.rings[1].wedges[2].hp
	_add_sapper(walled, 2, 192)
	walled.step(DT)
	_check(walled.state.rings[1].wedges[2].wall.hp < wall_hp_before, "A standing wall is damaged normally, exactly like a standard machine")
	_check(walled.state.rings[1].relay_hp == wall_relay_before and walled.state.rings[1].wedges[2].hp == wall_wedge_before, "Relay and wedge both untouched while a wall stands")

	# Relay HP reaching zero browns out the ring - its own output, and every
	# ring beyond it - without collapsing anything.
	var brownout := _sapper_sim({"structure": {"relay_max_hp": 1.0}}, 1)
	_add_sapper(brownout, 1, 192, 100, 1000)
	var boundary_before := PowerRules.chain_boundary(brownout.state)
	var tick := brownout.step(DT)
	_check(brownout.state.rings[1].relay_hp == 0.0 and tick.events.relays_lost == [1], "Relay HP reaches exactly zero and is reported as lost")
	_check(not brownout.state.rings[1].get("collapsed", false) and brownout.state.rings[1].wedges[1].hp > 0, "Wedges/walls remain intact - this is a brownout, not a collapse")
	_check(boundary_before == 1 and PowerRules.chain_boundary(brownout.state) == 0, "Chain boundary now stops before the browned-out ring, dropping it and everything beyond to brownout")
	var expected_output: float = float(brownout.profile.value("power.base_output")) * pow(1, brownout.profile.value("scaling.power_ring_exponent")) * float(brownout.profile.value("power.brownout_fraction"))
	_check(is_equal_approx(PowerRules.ring_output(brownout.state, brownout.profile, 1), expected_output), "Browned-out ring's own output drops to the brownout fraction")

	# D-108 Option C: Rebuild Relay restores relay_hp to full for a flat cost.
	var relay_quote := brownout.quote_rebuild_relay(1)
	_check(relay_quote.ok and is_equal_approx(relay_quote.quote.cost, float(brownout.profile.value("economy.rebuild_relay_cost"))) and relay_quote.quote.affordable, "Rebuild Relay quote available for a browned-out ring")
	var energy_before: float = brownout.state.energy
	var rebuilt := brownout.rebuild_relay(1)
	_check(rebuilt.ok and brownout.state.rings[1].relay_hp == brownout.state.rings[1].relay_max_hp and is_equal_approx(brownout.state.energy, energy_before - relay_quote.quote.cost), "Rebuild Relay restores relay_hp to full for a flat cost")
	_check(not brownout.rebuild_relay(1).ok, "Rebuild Relay rejected once already at full HP")
	_check(not brownout.rebuild_relay(99).ok, "Rebuild Relay rejected for an unowned ring")

	# Capacity/skip counter parity with the other elites' own dedicated counters.
	var full := _sapper_sim({"pressure": {"max_active_machines": 1}}, 1)
	_add(full, 1, 200)
	full.step(DT)
	_check(full.skipped_sapper_arrivals == 1, "A full pool permanently skips a due Sapper, tracked in its own counter")

	# Exact-time tie priority: Transfer beats Sapper beats normal.
	var tied: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 60, "spawn_delay_seconds": 0, "max_active_machines": 1}, "transfer": {"first_arrival_seconds": DT}, "sapper": {"first_arrival_seconds": DT}, "flak": {"damage": 0}}).profile
	var tied_sim: Dictionary = LiveSimulation.create(tied, 2, false, false, true, true)
	_check(tied_sim.ok, "Tie fixture simulation valid")
	var tied_live: LiveSimulation = tied_sim.simulation
	tied_live.state.energy = 100000
	_check(tied_live.purchase_ring().ok, "Tie fixture owns a second ring")
	tied_live.step(DT)
	var tied_ids := tied_live.pool.active_ids()
	_check(tied_ids.size() == 1 and tied_live.pool.payload_for(tied_ids[0]).get("kind") == &"transfer", "On an exact-time tie, Transfer is admitted ahead of Sapper and normal")

	var sapper_over_normal: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 60, "spawn_delay_seconds": 0, "max_active_machines": 1}, "sapper": {"first_arrival_seconds": DT}, "flak": {"damage": 0}}).profile
	var normal_tied2: LiveSimulation = LiveSimulation.create(sapper_over_normal, 2, false, false, false, true).simulation
	normal_tied2.state.energy = 100000
	normal_tied2.step(DT)
	_check(normal_tied2.pool.payload_for(normal_tied2.pool.active_ids()[0]).get("kind") == &"sapper", "On an exact-time tie, Sapper is admitted ahead of normal")

func _breacher_sim(overrides: Dictionary = {}, rings: int = 1) -> LiveSimulation:
	var profile: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 0, "spawn_delay_seconds": 0}, "flak": {"damage": 0}, "breacher": {"first_arrival_seconds": DT}}).profile.with_overrides(overrides).profile
	var sim: LiveSimulation = LiveSimulation.create(profile, 5, false, false, false, false, true).simulation
	sim.state.energy = 100000
	for ring in range(2, rings + 1): _check(sim.purchase_ring().ok, "Breacher fixture expansion %d" % ring)
	return sim

func _add_breacher(sim: LiveSimulation, wedge: int, radius: float, hp: float = 100, dps: float = 6, speed: float = 1) -> int:
	var band := (radius - 96) / 96
	return sim.pool.spawn({"kind": &"breacher", "position": PolarPosition.new(int(floorf(band)) + 1, wedge, band - floorf(band), 0.5), "hp": hp, "damage_per_second": dps, "speed_ring_widths_per_second": speed, "assimilation_stacks": [], "stun_remaining": 0.0})

## D-109: Breacher's routing always prefers the nearest wall over any open
## detour, and it deals full (unpenalized) wall damage - the exact opposite
## of a standard machine, which funnels around a single wall to any reachable
## exposed wedge and only ever attacks a wall at a reduced rate when fully sealed.
func _breacher_checks() -> void:
	_check(not _sim().breacher_enabled, "Legacy create defaults to normals only")
	var sim := _breacher_sim()
	var result := sim.step(DT)
	_check(result.ok and result.events.spawned_ids.size() == 1, "Breacher admitted at its own scheduled due time")
	var id: int = result.events.spawned_ids[0]
	var payload := sim.pool.payload_for(id)
	_check(payload.get("kind") == &"breacher", "Admitted machine carries the breacher kind tag")
	var base: Dictionary = MachineSpawnRules.stats_at(sim.profile, DT).stats
	_check(is_equal_approx(payload.hp, base.hp), "No stat multiplier - identical HP to a standard machine")

	# Only wedge 1 is walled; every other wedge on the ring is wide open, so a
	# standard machine would funnel away from the wall rather than attack it.
	var normal := _breacher_sim()
	_check(normal.place_wall(1, 1).ok, "Wall fixture placed")
	var normal_wall_before: float = normal.state.rings[1].wedges[1].wall.hp
	var away_id := _add(normal, 1, 192, 100, 6)
	normal.step(DT)
	_check(normal.state.rings[1].wedges[1].wall.hp == normal_wall_before, "A standard machine funnels away from a single wall toward the open perimeter")
	_check(normal.pool.payload_for(away_id).position.angular_fraction != 0.5, "Standard machine actually moved off the walled bearing")

	var breached := _breacher_sim()
	_check(breached.place_wall(1, 1).ok, "Wall fixture placed")
	var breach_wall_before: float = breached.state.rings[1].wedges[1].wall.hp
	_add_breacher(breached, 1, 192, 100, 6)
	breached.step(DT)
	_check(is_equal_approx(breached.state.rings[1].wedges[1].wall.hp, breach_wall_before - 6.0 * DT), "Breacher targets the adjacent wall directly despite an open detour, and deals full undiscounted damage")
	_check(breached.state.rings[1].wedges[1].hp == breached.state.rings[1].wedges[1].max_hp, "The wedge behind the wall is untouched while the wall stands")

	# With no wall anywhere, Breacher has nothing to prefer and behaves exactly
	# like a standard machine (attacks the bare wedge in front of it).
	var bare := _breacher_sim()
	var bare_wedge_before: float = bare.state.rings[1].wedges[1].hp
	_add_breacher(bare, 1, 192, 100, 6)
	bare.step(DT)
	_check(bare.state.rings[1].wedges[1].hp < bare_wedge_before, "No wall anywhere: Breacher attacks the bare wedge like a standard machine")

	# Capacity/skip counter parity with the other elites' own dedicated counters.
	var full := _breacher_sim({"pressure": {"max_active_machines": 1}}, 1)
	_add(full, 1, 200)
	full.step(DT)
	_check(full.skipped_breacher_arrivals == 1, "A full pool permanently skips a due Breacher, tracked in its own counter")

	# Exact-time tie priority: Sapper beats Breacher beats normal.
	var tied: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 60, "spawn_delay_seconds": 0, "max_active_machines": 1}, "sapper": {"first_arrival_seconds": DT}, "breacher": {"first_arrival_seconds": DT}, "flak": {"damage": 0}}).profile
	var tied_sim: Dictionary = LiveSimulation.create(tied, 2, false, false, false, true, true)
	_check(tied_sim.ok, "Tie fixture simulation valid")
	var tied_live: LiveSimulation = tied_sim.simulation
	tied_live.state.energy = 100000
	_check(tied_live.purchase_ring().ok, "Tie fixture owns a second ring")
	tied_live.step(DT)
	var tied_ids := tied_live.pool.active_ids()
	_check(tied_ids.size() == 1 and tied_live.pool.payload_for(tied_ids[0]).get("kind") == &"sapper", "On an exact-time tie, Sapper is admitted ahead of Breacher and normal")

	var breacher_over_normal: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 60, "spawn_delay_seconds": 0, "max_active_machines": 1}, "breacher": {"first_arrival_seconds": DT}, "flak": {"damage": 0}}).profile
	var normal_tied3: LiveSimulation = LiveSimulation.create(breacher_over_normal, 2, false, false, false, false, true).simulation
	normal_tied3.state.energy = 100000
	normal_tied3.step(DT)
	_check(normal_tied3.pool.payload_for(normal_tied3.pool.active_ids()[0]).get("kind") == &"breacher", "On an exact-time tie, Breacher is admitted ahead of normal")

func _assembler_sim(overrides: Dictionary = {}, rings: int = 1) -> LiveSimulation:
	var profile: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 0, "spawn_delay_seconds": 0}, "flak": {"damage": 0}, "assembler": {"first_arrival_seconds": DT}}).profile.with_overrides(overrides).profile
	var sim: LiveSimulation = LiveSimulation.create(profile, 5, false, false, false, false, false, true).simulation
	sim.state.energy = 100000
	for ring in range(2, rings + 1): _check(sim.purchase_ring().ok, "Assembler fixture expansion %d" % ring)
	return sim

func _add_assembler(sim: LiveSimulation, wedge: int, radius: float, hp: float = 100, dps: float = 6, speed: float = 1) -> int:
	var band := (radius - 96) / 96
	return sim.pool.spawn({"kind": &"assembler", "growth_stacks": 0, "position": PolarPosition.new(int(floorf(band)) + 1, wedge, band - floorf(band), 0.5), "hp": hp, "damage_per_second": dps, "speed_ring_widths_per_second": speed, "assimilation_stacks": [], "stun_remaining": 0.0})

## D-110: Assembler ignores walls entirely (treats a walled wedge exactly like
## a bare one) and carries its own permanent, non-decaying growth from every
## wedge/wall/occupant it personally destroys - separate from D-021's global
## assimilation, and never decaying for the rest of its own life.
func _assembler_checks() -> void:
	_check(not _sim().assembler_enabled, "Legacy create defaults to normals only")
	var sim := _assembler_sim()
	var result := sim.step(DT)
	_check(result.ok and result.events.spawned_ids.size() == 1, "Assembler admitted at its own scheduled due time")
	var id: int = result.events.spawned_ids[0]
	var payload := sim.pool.payload_for(id)
	_check(payload.get("kind") == &"assembler" and payload.get("growth_stacks") == 0, "Admitted machine carries the assembler kind tag, growth unspent")
	var base: Dictionary = MachineSpawnRules.stats_at(sim.profile, DT).stats
	_check(is_equal_approx(payload.hp, base.hp * float(sim.profile.value("assembler.hp_multiplier"))), "Assembler HP uses the configured boss-scale multiplier")

	# Only wedge 1 is walled; a standard machine would funnel away, but
	# Assembler ignores the wall entirely and attacks the wedge behind it.
	var walled := _assembler_sim()
	_check(walled.place_wall(1, 1).ok, "Wall fixture placed")
	var wall_before: float = walled.state.rings[1].wedges[1].wall.hp
	var wedge_before: float = walled.state.rings[1].wedges[1].hp
	_add_assembler(walled, 1, 192, 100, 6)
	walled.step(DT)
	_check(walled.state.rings[1].wedges[1].wall.hp == wall_before, "The wall itself is never touched - it simply doesn't exist for Assembler's purposes")
	_check(walled.state.rings[1].wedges[1].hp < wedge_before, "It attacks the wedge behind the wall directly, exactly like a bare one")

	# Personal growth: breaking its own wedge grants a stack; if that break
	# also collapses the ring, every occupant/wall found in the same sweep
	# grants additional stacks - all non-decaying, boosting its own damage
	# and HP for the rest of its life.
	var growth := _assembler_sim()
	for wedge in range(1, 13): growth.state.rings[1].wedges[wedge].occupants = {}
	for wedge in range(1, 7): growth.state.rings[1].wedges[wedge].hp = 0
	growth.state.rings[1].wedges[2].occupants[0] = {"kind": &"armor_plating"}
	growth.state.rings[1].wedges[7].hp = 0.01
	var gid := _add_assembler(growth, 7, 192, 100, 1000)
	var core_before := growth.core_hp
	growth.step(DT)
	_check(growth.state.rings[1].get("collapsed", false), "Its own attack breaks the 7th wedge and collapses the ring")
	var grown := growth.pool.payload_for(gid)
	_check(grown.growth_stacks == 2, "One stack for its own broken wedge, one more for the single occupant swept up in the collapse it caused")
	_check(is_equal_approx(grown.hp, 100.0 + 2.0 * float(growth.profile.value("assembler.growth_hp_per_stack"))), "Each stack also grants an immediate, permanent HP bonus")
	_check(growth.core_hp == core_before, "No carryover damage to the core on the same tick as the collapse")
	# The tick after a collapse is spent crossing into the newly-opened ring,
	# not attacking - step until it actually reaches and starts hitting the core.
	var damage_before := growth.core_hp
	var reached := false
	for _tick in range(120):
		var before: float = growth.core_hp
		growth.step(DT)
		if growth.core_hp < before:
			reached = true
			# The same collapse that granted growth also granted this Assembler
			# one ordinary D-021 assimilation stack (global, separate mechanism) -
			# both multipliers apply together to its damage.
			var assimilation_multiplier: float = 1.0 + float(growth.profile.value("assimilation.bonus_per_stack"))
			var expected_damage: float = 1000.0 * DT * assimilation_multiplier * (1.0 + 2.0 * float(growth.profile.value("assembler.growth_damage_per_stack")))
			_check(is_equal_approx(before - growth.core_hp, expected_damage), "Once it reaches the core, it already deals the grown, boosted damage - permanent and non-decaying")
			break
	_check(reached, "Assembler reaches and attacks the core after the ring it broke through collapses")
	_check(damage_before == core_before, "Sanity: nothing damaged the core before it actually arrived")

	# Capacity/skip counter parity with the other elites' own dedicated counters.
	var full := _assembler_sim({"pressure": {"max_active_machines": 1}}, 1)
	_add(full, 1, 200)
	full.step(DT)
	_check(full.skipped_assembler_arrivals == 1, "A full pool permanently skips a due Assembler, tracked in its own counter")

	# Exact-time tie priority: Breacher beats Assembler beats normal.
	var tied: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 60, "spawn_delay_seconds": 0, "max_active_machines": 1}, "breacher": {"first_arrival_seconds": DT}, "assembler": {"first_arrival_seconds": DT}, "flak": {"damage": 0}}).profile
	var tied_sim: Dictionary = LiveSimulation.create(tied, 2, false, false, false, false, true, true)
	_check(tied_sim.ok, "Tie fixture simulation valid")
	var tied_live: LiveSimulation = tied_sim.simulation
	tied_live.state.energy = 100000
	_check(tied_live.purchase_ring().ok, "Tie fixture owns a second ring")
	tied_live.step(DT)
	var tied_ids := tied_live.pool.active_ids()
	_check(tied_ids.size() == 1 and tied_live.pool.payload_for(tied_ids[0]).get("kind") == &"breacher", "On an exact-time tie, Breacher is admitted ahead of Assembler and normal")

	var assembler_over_normal: BalanceProfile = baseline.with_overrides({"pressure": {"spawn_per_second": 60, "spawn_delay_seconds": 0, "max_active_machines": 1}, "assembler": {"first_arrival_seconds": DT}, "flak": {"damage": 0}}).profile
	var normal_tied4: LiveSimulation = LiveSimulation.create(assembler_over_normal, 2, false, false, false, false, false, true).simulation
	normal_tied4.state.energy = 100000
	normal_tied4.step(DT)
	_check(normal_tied4.pool.payload_for(normal_tied4.pool.active_ids()[0]).get("kind") == &"assembler", "On an exact-time tie, Assembler is admitted ahead of normal")

func _tunneler_checks() -> void:
	_check(not _sim().tunnelers_enabled, "Legacy create defaults to normals only")
	var scheduled := _tunnel_sim({"tunneler": {"first_arrival_seconds": 60}}, 1)
	_ticks_ok(scheduled, 3600, "Natural 60-second schedule")
	_check(scheduled.pool.active_count() == 0 and scheduled.skipped_tunneler_arrivals == 1, "No-inner arrival skipped at 60 seconds")
	_check(scheduled.purchase_ring().ok, "Expand before next scheduled arrival")
	_ticks_ok(scheduled, 1800, "Natural 90-second schedule")
	_check(scheduled.pool.active_count() == 1 and scheduled.targets_snapshot()[0].position.wedge == 1 and scheduled.skipped_tunneler_arrivals == 1, "90-second bearing advances with no backlog")
	var sim := _tunnel_sim({"tunneler": {"first_arrival_seconds": 60}})
	_ticks_ok(sim, 3600, "Eligible natural 60-second arrival")
	var id: int = sim.pool.active_ids()[0]
	var payload := sim.pool.payload_for(id)
	_check(payload.phase == &"burrowing" and not payload.targetable and payload.burrow_elapsed_seconds == 0 and payload.hp == 22, "Scheduled admission starts underground at scaled HP")
	var hp_before: float = sim.state.rings[1].wedges[12].hp
	_ticks_ok(sim, 119, "Fixed-step burrow progression")
	_check(payload.phase == &"burrowing" and is_equal_approx(payload.burrow_elapsed_seconds, 119.0 / 60) and sim.state.rings[1].wedges[12].hp == hp_before and sim.last_events.hits.is_empty(), "No underground attacks or weapon hits")
	var snapshot := sim.targets_snapshot()
	for field in ["position", "start_position", "destination"]: snapshot[0][field].ring = 99
	_check(payload.position.ring != 99 and payload.start_position.ring == 3 and payload.destination.ring == 1, "All exposed PolarPositions independently copied")
	var paused_elapsed: float = payload.burrow_elapsed_seconds
	_check(payload.burrow_elapsed_seconds == paused_elapsed, "Pause with no step retains burrow countdown")
	_ticks_ok(sim, 1, "Two-second exact emergence")
	_check(payload.phase == &"surface_attack" and payload.targetable and payload.burrow_elapsed_seconds == 2 and payload.position.radial_fraction == 0.5 and sim.state.rings[1].wedges[12].hp == hp_before, "Emergence at exact locked middle without extra damage time")
	_ticks_ok(sim, 1, "Underfoot attack")
	_check(is_equal_approx(sim.state.rings[1].wedges[12].hp, hp_before - 5.5 * DT), "Surfaced Tunneler damages destination from inside")
	var slow := _tunnel_sim({"tunneler": {"burrow_seconds": 1e9}})
	_ticks_ok(slow, 20, "Long representable burrow preserves progress")
	var slow_target: Dictionary = slow.targets_snapshot()[0]
	var expected_radius := 288.0 - 144.0 * (19 * DT / 1e9)
	_check(absf(_radius(slow, slow_target.id) - expected_radius) <= PolarMotion.RADIAL_TOLERANCE and _radius(slow, slow_target.id) < 288.0 and slow_target.phase == &"burrowing", "Initial sub-tolerance piece cannot erase repeated slow motion")
	var partial := _tunnel_sim({"tunneler": {"first_arrival_seconds": 0.01, "burrow_seconds": 0.01}})
	_ticks_ok(partial, 1, "Partial tick admission")
	var partial_id: int = partial.pool.active_ids()[0]
	_check(is_equal_approx(partial.pool.payload_for(partial_id).burrow_elapsed_seconds, DT - 0.01), "Only post-arrival time advances burrow")
	_ticks_ok(partial, 1, "Partial tick emergence")
	_check(is_equal_approx(partial.state.rings[1].wedges[12].hp, 100 - 5 * (2 * DT - 0.02)), "Emergence spends exact leftover time attacking")
	var killed := _tunnel_sim({"tunneler": {"burrow_seconds": DT}, "flak": {"damage": 100, "arc_degrees": 360}})
	_ticks_ok(killed, 1, "Untargetable initial tick")
	_check(killed.pool.active_count() == 1 and killed.last_events.hits.is_empty(), "Ready weapon ignores underground target")
	var energy_before: float = killed.state.energy
	_ticks_ok(killed, 1, "Weapon phase sees emergence")
	_check(killed.pool.active_count() == 0 and killed.last_events.kill_ids.size() == 1 and killed.state.energy == energy_before + 2, "Surfaced target killed once with shared reward")
	_ticks_ok(killed, 1, "No repeated kill credit")
	_check(killed.last_events.kill_ids.is_empty() and killed.state.energy == energy_before + 2, "Released Tunneler cannot award twice")
	var wall := _tunnel_sim({"tunneler": {"burrow_seconds": DT}})
	_check(wall.place_wall(1, 12).ok, "Inner outer-edge wall fixture")
	var wall_hp: float = wall.state.rings[1].wedges[12].wall.hp
	_ticks_ok(wall, 3, "Burrow passes outer-edge wall")
	_check(wall.state.rings[1].wedges[12].wall.hp == wall_hp and wall.state.rings[1].wedges[12].hp < 100, "Inside attack bypasses supporting wedge wall")
	wall.state.rings[1].wedges[12].hp = 0.01
	_ticks_ok(wall, 1, "Underfoot wedge destruction")
	var wall_id: int = wall.pool.active_ids()[0]
	_check(wall.last_events.broken_wedges == [Vector2i(1, 12)] and wall.pool.payload_for(wall_id).phase == &"roaming", "Wedge breaker transitions to normal roaming")
	_check(wall.state.rings[1].wedges[12].has("wall") and not WallRules.is_blocking(wall.state, 1, 12), "Broken support retains inactive nonblocking wall record")
	_ticks_ok(wall, 40, "Roaming reaches core from inner gap")
	_check(wall.core_hp < 200, "Post-break Tunneler applies normal core pressure")
	var changed := _tunnel_sim()
	_ticks_ok(changed, 1, "Locked target admission")
	var changed_id: int = changed.pool.active_ids()[0]
	changed.state.rings[1].wedges[12].hp = 0
	_ticks_ok(changed, 121, "Target disappears during burrow")
	_check(changed.pool.payload_for(changed_id).phase == &"roaming" and changed.pool.payload_for(changed_id).destination.ring == 1 and _radius(changed, changed_id) < 144, "Gone destination emerges into gap and follows normal movement")
	var expanded := _tunnel_sim()
	_ticks_ok(expanded, 2, "Burrow moves clear of expansion band")
	_check(expanded.purchase_ring().ok, "Expansion during burrow")
	_ticks_ok(expanded, 119, "Expansion cannot relocate target")
	_check(expanded.targets_snapshot()[0].destination.ring == 1 and expanded.targets_snapshot()[0].phase == &"surface_attack", "Locked destination survives expansion")
	var gaps := _tunnel_sim({}, 3)
	_collapse_fixture(gaps, 2)
	_ticks_ok(gaps, 1, "Runtime skips collapsed ring")
	_check(gaps.targets_snapshot()[0].start_position.ring == 4 and gaps.targets_snapshot()[0].destination.ring == 1, "Runtime selects next intact inner ring across collapsed gap")
	var bearings := _tunnel_sim({"tunneler": {"arrival_interval_seconds": DT}})
	_ticks_ok(bearings, 12, "All twelve scheduled bearings admitted")
	_ticks_ok(bearings, 120, "All twelve bearings finish real fixed-step burrows")
	for target in bearings.targets_snapshot().slice(0, 12):
		_check(target.phase == &"surface_attack" and target.targetable and target.position.wedge == target.destination.wedge, "Every bearing tolerates motion reconstruction")
	_tunneler_admission_checks()
	_tunneler_rollback_checks()

func _tunneler_admission_checks() -> void:
	for capacity in [1, 2]:
		var tied := _tunnel_sim({"pressure": {"spawn_per_second": 60, "max_active_machines": capacity}})
		_ticks_ok(tied, 1, "Exact simultaneous arrival")
		var ids := tied.pool.active_ids()
		_check(ids.size() == capacity and tied.pool.payload_for(ids[0]).get("kind") == &"tunneler", "Eligible Tunneler wins exact-time lifetime ID and final slot")
		_check(tied.skipped_arrivals == (1 if capacity == 1 else 0) and tied.skipped_tunneler_arrivals == 0, "Separate blocked counters")
		if capacity == 2: _check(not tied.pool.payload_for(ids[1]).has("kind"), "Normal follows equal-time Tunneler")
	var normal_first := _tunnel_sim({"pressure": {"spawn_per_second": 100, "max_active_machines": 1}})
	_ticks_ok(normal_first, 1, "Chronological normal arrival")
	_check(not normal_first.targets_snapshot()[0].has("kind") and normal_first.skipped_tunneler_arrivals == 1, "Earlier normal takes slot before later Tunneler")
	var no_inner := _tunnel_sim({"pressure": {"spawn_per_second": 60, "max_active_machines": 1}}, 1)
	_ticks_ok(no_inner, 1, "Ineligible simultaneous Tunneler")
	_check(not no_inner.targets_snapshot()[0].has("kind") and no_inner.skipped_tunneler_arrivals == 1 and no_inner.skipped_arrivals == 0, "Ineligible Tunneler spends no slot")
	var blocked := _tunnel_sim({"pressure": {"max_active_machines": 1}, "tunneler": {"arrival_interval_seconds": DT}})
	_ticks_ok(blocked, 3, "Capacity skips due Tunnelers")
	_check(blocked.skipped_tunneler_arrivals == 2, "Blocked Tunneler arrivals counted")
	blocked.pool.release(blocked.pool.active_ids()[0])
	_ticks_ok(blocked, 1, "Release admits only current sequence")
	_check(blocked.targets_snapshot()[0].position.wedge == 3 and blocked.skipped_tunneler_arrivals == 2, "No deferred burst or bearing reset")
	var dense := _tunnel_sim({"tunneler": {"first_arrival_seconds": 1e-15, "arrival_interval_seconds": 1e-15}}, 1)
	_ticks_ok(dense, 1, "Huge ineligible schedule remains bounded by bearing cycle")
	_check(dense.pool.active_count() == 0 and dense.skipped_tunneler_arrivals > 1000000000000, "Huge ineligible count skipped without enumeration")

func _tunneler_rollback_checks() -> void:
	var sim := _tunnel_sim({"tunneler": {"arrival_interval_seconds": DT, "burrow_seconds": DT}})
	_ticks_ok(sim, 1, "Rollback fixture admission")
	var id: int = sim.pool.active_ids()[0]
	var payload := sim.pool.payload_for(id)
	var before := _tunneler_snapshot_bytes(sim)
	var state_before := sim.state.duplicate(true)
	var events_before := sim.last_events.duplicate(true)
	var waypoint_before := sim._waypoints.duplicate()
	var rebuilds_before := sim.route_rebuild_count
	sim.cooldowns = {&"malformed": 1.0}
	_check(not sim.step(DT).ok and sim.pool.active_count() == 1 and _tunneler_snapshot_bytes(sim) == before and sim.state == state_before and sim.last_events == events_before and sim.elapsed_seconds == DT and sim._waypoints == waypoint_before and sim.route_rebuild_count == rebuilds_before, "Failed combat rolls back new admission, motion, metadata, events, and navigation")
	sim.cooldowns = {}
	_ticks_ok(sim, 1, "Successful retry after rollback")
	_check(sim.last_events.spawned_ids[0] > id + 1, "Failed admission lifetime ID remains consumed")
	for invalid in [{"phase": &"unknown"}, {"targetable": not payload.targetable}, {"targetable": 0}, {"burrow_duration_seconds": 0}, {"burrow_elapsed_seconds": -1.0}, {"surface_cell": Vector2i(2, 12)}, {"destination": PolarPosition.new(1, 1, 0.5, 0.5)}]:
		var field: String = invalid.keys()[0]
		var original: Variant = payload[field]
		payload[field] = invalid[field]
		var count_before := sim.pool.active_count()
		var time_before := sim.elapsed_seconds
		_check(not sim.step(DT).ok and sim.pool.active_count() == count_before and sim.elapsed_seconds == time_before, "Malformed lifecycle rejected before admission: " + field)
		payload[field] = original
	var overflow := _tunnel_sim({}, 1)
	overflow.skipped_tunneler_arrivals = LiveSimulation.MAX_INTEGER
	_check(not overflow.step(DT).ok and overflow.elapsed_seconds == 0 and overflow.pool.active_count() == 0, "Skipped Tunneler counter overflow rolls back")
	var loss := _tunnel_sim()
	loss.state.rings[1].wedges[1].hp = 0
	loss.state.rings[2].wedges[1].hp = 0
	_add(loss, 1, 96, 100, 100)
	loss.core_hp = 0.01
	_ticks_ok(loss, 1, "Core loss before later burrow")
	_check(loss.ended and loss.targets_snapshot()[1].burrow_elapsed_seconds == 0, "Core loss freezes subsequent burrowers")
	var frozen := _tunneler_snapshot_bytes(loss)
	_ticks_ok(loss, 1, "Ended tick")
	_check(_tunneler_snapshot_bytes(loss) == frozen, "Ended simulation retains frozen Tunneler metadata")

func _tunneler_snapshot_bytes(sim: LiveSimulation) -> PackedByteArray:
	var snapshot := sim.targets_snapshot()
	for target in snapshot:
		for field in ["position", "start_position", "destination"]:
			if target.get(field) is PolarPosition:
				var p: PolarPosition = target[field]
				target[field] = [p.ring, p.wedge, p.radial_fraction, p.angular_fraction]
	return var_to_bytes(snapshot)

func _t043_checks() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	var id := _add(sim, 1, 200)
	sim.pool.payload_for(id).assimilation_stacks = [10.0]
	var snapshot := sim.targets_snapshot()
	snapshot[0].assimilation_stacks.append(20.0)
	snapshot[0].assimilation_stacks[0] = 30.0
	_check(sim.pool.payload_for(id).assimilation_stacks == [10.0], "T043 public snapshot array append/entry isolation")
	snapshot[0].assimilation_stacks.clear()
	_check(sim.pool.payload_for(id).assimilation_stacks == [10.0], "T043 public snapshot clear isolation")
	var stunned := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	var frozen_id := _add(stunned, 1, 400)
	stunned.pool.payload_for(frozen_id).stun_remaining = 1.5
	_ticks_ok(stunned, 90, "T043 exact 1.5-second stun")
	_check(stunned.pool.payload_for(frozen_id).stun_remaining == 0 and _radius(stunned, frozen_id) == 400, "T043 ninety frozen ticks end exactly")
	_ticks_ok(stunned, 1, "T043 first post-stun tick")
	_check(_radius(stunned, frozen_id) < 400, "T043 no extra frozen tick from residual")
	var repair := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	repair.state.energy = 1000
	repair.state.rings[1].wedges[1].hp = 0
	var intruder := _add(repair, 1, 144)
	var before := repair.state.duplicate(true)
	_check(not repair.quote_repair(1, 1).ok and not repair.repair_wedge(1, 1).ok and repair.state == before, "T043 occupied broken-wedge repair rejected without spending")
	_ticks_ok(repair, 1, "T043 rejected repair leaves simulation traversable")
	repair.pool.payload_for(intruder).hp = 0
	_check(repair.quote_repair(1, 1).ok and repair.repair_wedge(1, 1).ok, "T043 dead machine does not block repair")
	_ticks_ok(repair, 1, "T043 dead occupant after repair remains valid")
	var tunneled := _tunnel_sim({"tunneler": {"burrow_seconds": DT}})
	_ticks_ok(tunneled, 3, "T043 intact damaged surface-attack fixture")
	_check(tunneled.targets_snapshot()[0].phase == &"surface_attack" and tunneled.quote_repair(1, 12).ok and tunneled.repair_wedge(1, 12).ok, "T043 intact damaged wedge repair allowed with surfaced Tunneler")
	_ticks_ok(tunneled, 1, "T043 repaired intact Tunneler cell remains valid")
	_t043_status_checks()
	_t043_assimilation_data()

class T043BadAdmission extends LiveSimulation:
	func _admission_plan(normal: Dictionary, next_elapsed: float) -> Dictionary:
		var result := super._admission_plan(normal, next_elapsed)
		if result.ok and not result.descriptors.is_empty(): result.descriptors[0].stun_remaining = INF
		return result

func _t043_status_checks() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 60}, "flak": {"damage": 0}})
	var id := _add(sim, 1, 400)
	var payload := sim.pool.payload_for(id)
	for field in ["stun_remaining", "assimilation_stacks"]:
		var invalids: Array = [-1.0, INF, NAN, true, "1", null] if field == "stun_remaining" else [null, {}, "bad", [true], [-1], [INF], [NAN], ["1"], [null]]
		for invalid in invalids:
			payload[field] = invalid
			var count_before := sim.pool.active_count()
			var events_before := sim.last_events.duplicate(true)
			_check(not sim.step(DT).ok and sim.pool.active_count() == count_before and sim.elapsed_seconds == 0 and sim.last_events == events_before and sim._navigation == null, "T043 malformed live status fails before admission: " + field)
		payload.erase(field)
	payload.stun_remaining = 0.5
	payload.assimilation_stacks = [15.0]
	var borrowed_stacks: Array = payload.assimilation_stacks
	var original_position: PolarPosition = payload.position
	sim.cooldowns = {&"bad": 10.0}
	_check(not sim.step(DT).ok and payload.stun_remaining == 0.5 and borrowed_stacks == [15.0] and payload.position == original_position and sim.pool.active_count() == 1 and sim.elapsed_seconds == 0 and sim.cooldowns == {&"bad": 10.0}, "T043 downstream combat failure discards staged stun progress/admission without touching borrowed status")
	var ordinary := _sim({"pressure": {"spawn_per_second": 60}})
	var bad := T043BadAdmission.new()
	bad.profile = ordinary.profile
	bad.state = ordinary.state
	bad.pool = ordinary.pool
	bad.core_hp = ordinary.core_hp
	bad.ring_limit = ordinary.ring_limit
	_check(not bad.step(DT).ok and bad.pool.active_count() == 0 and bad.elapsed_seconds == 0 and bad._navigation == null, "T043 malformed admitted descriptor rejected before pool/navigation mutation")

func _t043_assimilation_data() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}, "assimilation": {"bonus_per_stack": 0.2, "max_stacks": 2, "stack_seconds": 0.5}})
	var id := _add(sim, 1, 192, 100, 10)
	var supplied: Array[Dictionary] = [{"hp": 100, "assimilation_stacks": []}]
	sim._apply_assimilation(supplied, 5, 0.0)
	_check(supplied[0].assimilation_stacks == [0.5, 0.5], "T043 assimilation cap and independent expiry use profile overrides")
	sim.pool.payload_for(id).assimilation_stacks = supplied[0].assimilation_stacks
	_ticks_ok(sim, 1, "T043 tuned assimilation damage")
	_check(is_equal_approx(sim.state.rings[1].wedges[1].hp, 100.0 - 14.0 * DT), "T043 actual attacks use tuned per-stack bonus")
	_check(LiveSimulation._assimilation_multiplier(supplied[0], 0.5, sim.profile) == 1.0, "T043 tuned stacks expire at exact time")
	var malformed := _sim({"pressure": {"spawn_per_second": 60}, "assimilation": {"bonus_per_stack": 1e308}})
	_check(not malformed.step(DT).ok and malformed.pool.active_count() == 0 and malformed.elapsed_seconds == 0, "T043 computed assimilation overflow rejected before admission")

func _t048_checks() -> void:
	var sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	var first := _add(sim, 12, 300, 10)
	var second := _add(sim, 12, 350, 10)
	var survivor := _add(sim, 6, 300, 100)
	_ticks_ok(sim, 1, "T048 initialize route cache")
	var last := sim.last_events.duplicate(true)
	var state_before := sim.state.duplicate(true)
	var nav_before := sim._navigation
	var waypoint_before := sim._waypoints.duplicate()
	var position_before: PolarPosition = sim.pool.payload_for(survivor).position
	var weapon_before := sim.cooldowns.duplicate(true)
	var cast := sim.cast_ability(&"focused_flare", PolarPosition.new(1, 12, 0, 0.5))
	_check(cast.ok and cast.events.kill_ids == [first, second] and cast.events.energy_awarded == 0 and sim.pool.active_count() == 1, "T048 Flare releases multiple kills with zero energy")
	_check(sim.last_events == last and sim.state == state_before and sim._navigation == nav_before and sim._waypoints == waypoint_before and sim.cooldowns == weapon_before and sim.elapsed_seconds == DT and sim.pool.payload_for(survivor).position == position_before, "T048 command preserves structural/time/weapon/navigation/position state and last tick events")
	cast.events.kill_ids.clear()
	var snapshot := sim.abilities_snapshot()
	snapshot[&"focused_flare"] = 0
	_check(sim.ability_cooldowns[&"focused_flare"] == 30, "T048 ability snapshot independent")
	_ticks_ok(sim, 1, "T048 tick after cast")
	_check(sim.last_events.kill_ids.is_empty() and sim.state.energy == state_before.energy and is_equal_approx(sim.ability_cooldowns[&"focused_flare"], 30 - DT), "T048 no duplicate cast kill credit; successful tick advances cooldown")
	var before := _tunneler_snapshot_bytes(sim)
	_check(not sim.cast_ability(&"focused_flare", PolarPosition.new(1, 12, 0, 0.5)).ok and _tunneler_snapshot_bytes(sim) == before, "T048 cooling cast fails atomically")
	var ability_before := sim.abilities_snapshot()
	sim.cooldowns = {&"bad": 1.0}
	_check(not sim.step(DT).ok and sim.abilities_snapshot() == ability_before and _tunneler_snapshot_bytes(sim) == before, "T048 failed tick does not consume cooldown or change moved scratch")
	sim.cooldowns = weapon_before
	sim.pool.payload_for(survivor).stun_remaining = INF
	_check(not sim.cast_ability(&"emp_burst", PolarPosition.new()).ok and sim.abilities_snapshot() == ability_before, "T048 malformed live status fails command atomically")
	sim.pool.payload_for(survivor).stun_remaining = 0.0
	sim.ended = true
	_check(not sim.cast_ability(&"emp_burst", PolarPosition.new()).ok, "T048 ended cast rejected")
	sim.step(DT)
	_check(sim.abilities_snapshot() == ability_before, "T048 ended tick leaves cooldowns frozen")
	var timed := _sim({"pressure": {"spawn_per_second": 0}, "emp_burst": {"cooldown_seconds": 0.25}})
	_check(timed.cast_ability(&"emp_burst", PolarPosition.new()).ok, "T048 valid empty cast consumes cooldown")
	_ticks_ok(timed, 15, "T048 exact ability cooldown cadence")
	_check(timed.ability_cooldowns[&"emp_burst"] == 0 and timed.cast_ability(&"emp_burst", PolarPosition.new()).ok, "T048 cooldown ready after exact duration")
	var tunnel := _tunnel_sim({"tunneler": {"burrow_seconds": DT}})
	_ticks_ok(tunnel, 1, "T048 burrow admission")
	var tunnel_id: int = tunnel.pool.active_ids()[0]
	_check(tunnel.cast_ability(&"focused_flare", PolarPosition.new(1, 12, 0, 0.5)).events.kill_ids.is_empty() and tunnel.pool.contains(tunnel_id), "T048 underground Tunneler immune")
	_ticks_ok(tunnel, 1, "T048 Tunneler emergence")
	var burst := tunnel.cast_ability(&"emp_burst", PolarPosition.new(1, 12, 0.5, 0.5))
	_check(burst.ok and burst.events.hits.size() == 1 and tunnel.pool.payload_for(tunnel_id).stun_remaining == 2, "T048 surfaced Tunneler eligible for other ready ability")

func _terrain_sim(rings: int = 1) -> LiveSimulation:
	var sim := _sim({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}})
	sim.state.energy = 100000
	for ring in range(2, rings + 1): _check(sim.purchase_ring().ok, "T050 fixture expansion")
	return sim

func _t050_checks() -> void:
	var sim := _terrain_sim(3)
	sim.state.rings[2].wedges[1].hp = 0
	sim.state.rings[2].wedges[2].hp = 0
	_check(sim.place_terrain(1, 1, 0, &"debris_field").ok, "T050 live debris placement")
	var id := _add(sim, 1, 240)
	_ticks_ok(sim, 1, "T050 initialize escape route")
	var before := sim.state.duplicate(true)
	var nav := sim._navigation
	var paths := sim._waypoints.duplicate()
	_check(not sim.quote_repair(2, 2).ok and not sim.repair_wedge(2, 2).ok and sim.state == before and sim._navigation == nav and sim._waypoints == paths, "T050 empty broken-wedge repair cannot seal an existing inner source; atomic quote and mutation")
	sim = _terrain_sim(3)
	sim.state.rings[2].wedges[1].hp = 0
	id = _add(sim, 1, 240)
	before = sim.state.duplicate(true)
	_check(not sim.place_terrain(1, 1, 0, &"debris_field").ok and sim.state == before, "T050 living-source guard rejects placement missed by outer frontier")
	sim = _terrain_sim(4)
	sim.state.rings[3].wedges[1].hp = 0
	_collapse_fixture(sim, 4)
	_check(sim.place_terrain(2, 1, 0, &"debris_field").ok, "T050 reclaim escape fixture")
	id = _add(sim, 1, 336)
	before = sim.state.duplicate(true)
	_check(not sim.quote_reclaim(4).ok and not sim.reclaim_ring(4).ok and sim.state == before, "T050 reclaim cannot close a neighboring living source escape")
	for direction in [-1, 1]:
		sim = _terrain_sim()
		for wedge in range(1, 13):
			if wedge not in [2, 12]: sim.state.rings[1].wedges[wedge].wall = {"hp": 50.0, "max_hp": 50.0}
		_check(sim.place_terrain(1, 1, 0, &"tractor_lane", direction).ok, "T050 live tractor placement")
		id = _add(sim, 1, 192)
		_ticks_ok(sim, 1, "T050 tractor movement")
		var traveled := fposmod((_angle_units(sim.pool.payload_for(id).position) - 1.0) * direction, 12.0) * TAU / 12.0 * 192.0
		_check(absf(traveled - 1.6) < 1e-8, "T050 discounted directed route retains physical speed")
		# One complete edge crosses a shadow boundary halfway; the second half is clear.
		sim = _terrain_sim()
		for wedge in range(1, 13):
			if wedge != (12 if direction == -1 else 2): sim.state.rings[1].wedges[wedge].wall = {"hp": 50.0, "max_hp": 50.0}
		_check(sim.place_terrain(1, 1, 0, &"occlusion_screen").ok, "T050 angular screen placement")
		id = _add(sim, 1, 192, 100, 6, 100)
		var target := 12 if direction == -1 else 2
		var hp_before: float = sim.state.rings[1].wedges[target].hp
		_ticks_ok(sim, 1, "T050 angular shadow boundary")
		var travel_time := (192.0 * TAU / 12.0 / 2.0) / 9600.0 * 3.0
		_check(absf(sim.state.rings[1].wedges[target].hp - (hp_before - 6.0 * (DT - travel_time))) < 1e-8, "T050 both angular directions split speed exactly and attack at full DPS with leftover time")
	for start in [480.0, 576.0]:
		sim = _terrain_sim()
		_check(sim.place_terrain(1, 1, 0, &"occlusion_screen").ok, "T050 radial screen placement")
		id = _add(sim, 1, start, 100, 6, 1000)
		var hp_before: float = sim.state.rings[1].wedges[1].hp
		sim.ability_cooldowns[&"focused_flare"] = 1.0
		_ticks_ok(sim, 1, "T050 radial multi-band shadow traversal")
		var travel_time: float = 288.0 / 48000.0 + (start - 480.0) / 96000.0
		_check(absf(sim.state.rings[1].wedges[1].hp - (hp_before - 6 * (DT - travel_time))) < 1e-8 and is_equal_approx(sim.ability_cooldowns[&"focused_flare"], 1.0 - DT), "T050 exact radial boundaries apply only covered interval slow; attacks and cooldowns unaffected")
	sim = _terrain_sim()
	_check(sim.place_terrain(1, 1, 0, &"occlusion_screen").ok, "T050 rollback screen")
	id = _add(sim, 1, 300)
	_ticks_ok(sim, 1, "T050 cache shadow")
	before = sim.state.duplicate(true)
	nav = sim._navigation
	paths = sim._waypoints.duplicate()
	var radius_before := _radius(sim, id)
	sim.cooldowns = {&"invalid": 1.0}
	_check(not sim.step(DT).ok and sim.state == before and sim._navigation == nav and sim._waypoints == paths and _radius(sim, id) == radius_before, "T050 failed tick preserves shadow preferences, route and position")
	sim.cooldowns = {}
	sim.state.rings[1].wedges[1].hp = 0
	_ticks_ok(sim, 1, "T050 broken screen rebuild")
	_check(sim._navigation != nav and not sim._navigation.has_shadows and absf(radius_before - _radius(sim, id) - 1.6) < 1e-8, "T050 support break invalidates shadow cache immediately")
	sim.ended = true
	_check(not sim.place_terrain(1, 2, 0, &"debris_field").ok, "T050 ended terrain command rejected")
	var tunnel := _tunnel_sim({"tunneler": {"burrow_seconds": DT * 2.0}}, 3)
	_check(tunnel.place_terrain(2, 12, 0, &"occlusion_screen").ok, "T050 underground shadow fixture")
	_ticks_ok(tunnel, 3, "T050 shadow does not extend underground duration")
	_check(tunnel.pool.payload_for(tunnel.pool.active_ids()[0]).phase == &"surface_attack", "T050 underground travel bypasses surface slow")
	for target in [6, 8]:
		sim = _terrain_sim()
		for wedge in range(1, 13):
			if wedge != target: sim.state.rings[1].wedges[wedge].wall = {"hp": 50.0, "max_hp": 50.0}
			if wedge not in [6, 12]: sim.state.rings[1].wedges[wedge].occupants[0] = {"kind": &"occlusion_screen"}
		id = _add(sim, 1, 192, 100, 6, 10000)
		_ticks_ok(sim, 1, "T050 long legitimate angular traversal across multiple speed boundaries")
		_check(sim.pool.payload_for(id).position.wedge == target and sim.state.rings[1].wedges[target].hp < 100, "T050 long CW/CCW traversal reaches exposed goal without relaxing node cycle bound")
	# Emerged machines use the same surface movement, while inside attacks remain full rate.
	tunnel = _tunnel_sim({"tunneler": {"burrow_seconds": DT}}, 3)
	tunnel.state.rings[1].wedges[12].occupants[0] = {"kind": &"occlusion_screen"}
	_ticks_ok(tunnel, 2, "T050 shadowed Tunneler emergence")
	id = tunnel.pool.active_ids()[0]
	var surface: Vector2i = tunnel.pool.payload_for(id).surface_cell
	_check(surface.x == 2, "T050 roaming fixture emerges in screen's outward band")
	var surface_hp: float = tunnel.state.rings[surface.x].wedges[surface.y].hp
	var dps: float = tunnel.pool.payload_for(id).damage_per_second
	_ticks_ok(tunnel, 1, "T050 shadowed inside attack")
	_check(absf(tunnel.state.rings[surface.x].wedges[surface.y].hp - surface_hp + dps * DT) < 1e-8, "T050 shadow does not reduce inside Tunneler attack DPS")
	tunnel.state.rings[surface.x].wedges[surface.y].hp = 0
	var old_radius := _radius(tunnel, id)
	var speed: float = tunnel.pool.payload_for(id).speed_ring_widths_per_second
	_ticks_ok(tunnel, 1, "T050 roaming shadow movement")
	_check(tunnel.pool.payload_for(id).phase == &"roaming" and absf(old_radius - _radius(tunnel, id) - speed * 96.0 * DT * 0.5) < 1e-8, "T050 surfaced roaming Tunneler receives exactly one shadow slow")
	sim = _terrain_sim()
	_check(sim.place_terrain(1, 1, 0, &"occlusion_screen").ok, "T050 collapse screen fixture")
	for wedge in [2, 3, 4, 5, 7, 8]: sim.state.rings[1].wedges[wedge].hp = 0
	sim.state.rings[1].wedges[1].hp = 0.01
	id = _add(sim, 1, 192)
	_ticks_ok(sim, 1, "T050 terrain support ring collapse")
	_check(sim.state.rings[1].get("collapsed", false) and sim.state.rings[1].wedges[1].occupants.is_empty() and not TerrainRules.has_screen(sim.state, 1, 1), "T050 full collapse removes retained terrain")
