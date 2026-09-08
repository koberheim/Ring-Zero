extends SceneTree
var checks := 0
var failures := 0
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _target(id: int, ring: int = 2, wedge: int = 12, hp: float = 10, fraction: float = 0.5) -> Dictionary:
	return {"id": id, "position": PolarPosition.new(ring, wedge, 0.5, fraction), "hp": hp}
func _step(state: Dictionary, profile: BalanceProfile, targets: Array[Dictionary], cooldowns: Dictionary = {}, delta: float = 0.0) -> Dictionary:
	return WeaponRules.step(state, profile, targets, cooldowns, delta)
func _initialize() -> void:
	var profile: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile
	if "--public-cost-review" in OS.get_cmdline_user_args() or "--owned-cost-review" in OS.get_cmdline_user_args():
		_public_cost_review(profile)
		quit(1 if failures else 0)
		return
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	_targetable_checks(state, profile)
	var before := state.duplicate(true)
	var targets: Array[Dictionary] = [_target(3)]
	var fired := _step(state, profile, targets)
	_check(fired.ok and fired.hits.size() == 1 and fired.targets[0].hp == 8 and fired.cooldowns[&"1:12:0"] == 0.25, "Automatic Flak firing")
	_check(targets[0].hp == 10 and state == before, "Input target and state isolated")
	fired.targets[0].position.ring = 9
	_check(targets[0].position.ring == 2, "Returned mutable position cloned")
	var wait := _step(state, profile, targets, fired.cooldowns, 0.1)
	_check(wait.ok and wait.hits.is_empty() and is_equal_approx(wait.cooldowns[&"1:12:0"], 0.15), "No early refire")
	_check(_step(state, profile, targets, wait.cooldowns, 0.15).hits.size() == 1, "Cycle expires")
	_check(_step(state, profile, targets, {}, 100).hits.size() == 1, "At most one volley for large delta")
	var empty: Array[Dictionary] = []
	var idle := _step(state, profile, empty)
	_check(idle.ok and idle.cooldowns[&"1:12:0"] == 0 and _step(state, profile, targets, idle.cooldowns).hits.size() == 1, "Empty targets retain readiness")
	var capped: BalanceProfile = profile.with_overrides({"flak": {"max_targets": 1}}).profile
	var tied: Array[Dictionary] = [_target(9), _target(2), _target(1, 3)]
	var selected := _step(state, capped, tied)
	_check(selected.hits.size() == 1 and selected.hits[0].target_id == 2, "Nearest then exact-distance lowest ID tie")
	var many: Array[Dictionary] = []
	for id in range(7): many.append(_target(id))
	_check(_step(state, profile, many).hits.size() == 5, "Profile target cap")
	var excluded: Array[Dictionary] = [_target(1, 1, 11), _target(2, 5, 12)]
	_check(_step(state, profile, excluded).hits.is_empty(), "Flak rear arc and range exclude")
	var inward: Array[Dictionary] = [_target(1, 1, 11)]
	state.energy = 100
	state = BuildingRules.place_weapon(state, profile, 1, 11, 0, &"mass_driver").state
	var mass := _step(state, profile, inward)
	_check(mass.hits.size() == 1 and mass.hits[0].weapon_id == &"1:11:0" and mass.hits[0].damage == 10 and mass.kill_ids == [1] and mass.energy_awarded == 2, "360 Mass Driver clamps damage and rewards once")
	var dead := _step(state, profile, mass.targets)
	_check(dead.hits.is_empty() and dead.kill_ids.is_empty() and dead.energy_awarded == 0, "Dead targets never rehit/reward")
	var tuned: BalanceProfile = profile.with_overrides({"flak": {"damage": 7}, "economy": {"kill_energy": 4}}).profile
	var lethal: Array[Dictionary] = [_target(8, 2, 12, 3)]
	var killed := _step(state, tuned, lethal)
	_check(killed.kill_ids == [8] and killed.energy_awarded == 4 and killed.hits.size() == 1 and killed.hits[0].damage == 3, "Ordered weapons cannot duplicate kill/reward")
	state.rings[1].wedges[11].hp = 0
	state.rings[1].wedges[12].hp = 0
	_check(_step(state, profile, targets).hits.is_empty(), "Broken wedges suppress armed buildings and relay does not attack")
	var stale := _step(state, profile, targets, {&"99:1:0": 2})
	_check(stale.ok and not stale.cooldowns.has(&"99:1:0"), "Stale cooldown removed")
	for cooldown in [{"1:12:0": 0}, {&"bad": 0}, {&"1:13:0": 0}, {&"1:12:0": true}, {&"1:12:0": INF}, {&"1:12:0": -1}]:
		var invalid := _step(state, profile, targets, cooldown)
		_check(not invalid.ok and invalid.targets.is_empty() and invalid.cooldowns.is_empty() and invalid.hits.is_empty() and invalid.kill_ids.is_empty() and invalid.energy_awarded == 0, "Malformed cooldown no partial output")
	for delta in [-1, INF, NAN]:
		_check(not _step(state, profile, targets, {}, delta).ok, "Invalid delta")
	for bad in [{}, {"id": true, "hp": 1, "position": PolarPosition.new()}, {"id": 0, "hp": NAN, "position": PolarPosition.new()}, {"id": 0, "hp": 1, "position": null}, {"id": 0, "hp": 1, "position": PolarPosition.new(1, 0)}, {"id": 0, "hp": 1, "position": PolarPosition.new(0, 0, 0, 0.5)}]:
		var invalid_targets: Array[Dictionary] = [bad]
		_check(not _step(state, profile, invalid_targets).ok, "Malformed target")
	var duplicate: Array[Dictionary] = [_target(1), _target(1)]
	_check(not _step(state, profile, duplicate).ok and not _step({}, profile, targets).ok and not _step(state, BalanceProfile.new(), targets).ok, "Duplicate IDs/invalid state/profile")
	# These boundary-precision checks assume the starter Flak sits at each
	# wedge's exact center bearing (denominator 1), so this section pins
	# slots_per_wedge_per_ring to 1 regardless of the live default (D-105
	# raised it to 2 for real gameplay's multi-weapon-per-wedge capacity).
	var single_slot: BalanceProfile = profile.with_overrides({"scaling": {"slots_per_wedge_per_ring": 1}}).profile
	state = BuildingRules.create_default_testing_state(single_slot).state
	var long_range: BalanceProfile = profile.with_overrides({"flak": {"range_ring_widths": 20}}).profile
	var distant: Array[Dictionary] = [_target(1, 9)]
	_check(_step(state, long_range, distant).hits.size() == 1, "Supplied targets beyond scene ring limit")
	var grid := PolarGrid.new(10)
	var origin := grid.polar_to_world(BuildingRules.slot_position(1, 12, 0, 1))
	var direction := origin.normalized()
	var boundary_world := origin + direction.rotated(PI / 4) * 96.0
	var boundary: Array[Dictionary] = [{"id": 55, "hp": 10, "position": grid.world_to_polar(boundary_world)}]
	_check(_step(state, profile, boundary).hits.size() == 1, "Flak inclusive 45 degree boundary")
	var narrower: BalanceProfile = profile.with_overrides({"flak": {"arc_degrees": 89}}).profile
	_check(_step(state, narrower, boundary).hits.is_empty(), "Tuned arc excludes boundary")
	var exact_range: Array[Dictionary] = [_target(1, 3)]
	_check(_step(state, profile, exact_range).hits.size() == 1, "Inclusive exact two-ring-width range")
	exact_range[0].position.radial_fraction = 0.501
	_check(_step(state, profile, exact_range).hits.is_empty(), "Beyond range excluded")
	var tuned_damage: BalanceProfile = profile.with_overrides({"flak": {"damage": 7, "cycle_seconds": 0.6}}).profile
	var damage_result := _step(state, tuned_damage, targets)
	_check(damage_result.targets[0].hp == 3 and damage_result.cooldowns[&"1:12:0"] == 0.6, "Data controls nonlethal damage and cycle")
	state.energy = 1000
	state = RingPurchaseRules.purchase_next_ring(state, single_slot, 3).state
	state = BuildingRules.place_weapon(state, profile, 2, 12, 0, &"flak").state
	state.rings[1].wedges[12].hp = 0
	var own_bearing: Array[Dictionary] = [_target(1, 3, 12, 10, 0.25)]
	var narrow: BalanceProfile = profile.with_overrides({"flak": {"arc_degrees": 1}}).profile
	_check(_step(state, narrow, own_bearing).hits.size() == 1, "Flak faces own slot bearing, not wedge center")
	state = BuildingRules.create_default_testing_state(profile).state
	state.energy = 100
	state = BuildingRules.place_weapon(state, profile, 1, 11, 0, &"mass_driver").state
	var rear: Array[Dictionary] = [{"id": 1, "hp": 100, "position": PolarPosition.new(0, 0, 0, 0)}]
	_check(_step(state, profile, rear).hits.size() == 1, "Mass Driver attacks behind itself")
	var mass_narrow: BalanceProfile = profile.with_overrides({"mass_driver": {"arc_degrees": 90}}).profile
	_check(_step(state, mass_narrow, rear).hits.is_empty(), "Tuned Mass Driver uses same outward arc")
	var cadence: Dictionary = {}
	state = BuildingRules.create_default_testing_state(profile).state
	var durable: Array[Dictionary] = [_target(1, 2, 12, 1000)]
	cadence = _step(state, profile, durable).cooldowns
	for tick in range(1, 16):
		var tick_result := _step(state, profile, durable, cadence, 1.0 / 60.0)
		_check(tick_result.hits.size() == (1 if tick == 15 else 0), "Flak fixed-step cadence tick %d" % tick)
		cadence = tick_result.cooldowns
	state.energy = 100
	state = BuildingRules.place_weapon(state, profile, 1, 11, 0, &"mass_driver").state
	state.rings[1].wedges[12].hp = 0
	cadence = _step(state, profile, durable).cooldowns
	var early := false
	var final_hits := 0
	for tick in range(1, 121):
		var tick_result := _step(state, profile, durable, cadence, 1.0 / 60.0)
		if tick < 120 and not tick_result.hits.is_empty(): early = true
		if tick == 120: final_hits = tick_result.hits.size()
		cadence = tick_result.cooldowns
	_check(not early and final_hits == 1, "Mass Driver fixed-step 120-tick cadence")
	_equivalence_checks(profile)
	_owned_contract_checks(profile)
	_t043_status_checks(profile)
	_t043_eligibility(profile)
	_emp_node_checks(profile)
	_lance_emitter_checks(profile)
	_point_defense_checks(profile)
	print("Weapon rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)




# Independent oracle: rank all living targets first, then filter by geometry and
# take the requested count. Deliberately repeats conversions and fully sorts;
# it shares no selection/caching helpers or constants with WeaponRules.
func _reference_step(state: Dictionary, profile: BalanceProfile, source: Array[Dictionary], cooldowns: Dictionary, delta: float) -> Dictionary:
	var targets: Array[Dictionary] = []
	var grid := PolarGrid.new(20)
	for original in source:
		var copied := original.duplicate(true)
		var p: PolarPosition = original.position
		copied.position = PolarPosition.new(p.ring, p.wedge, p.radial_fraction, p.angular_fraction)
		targets.append(copied)
	var weapons: Array[Dictionary] = []
	for ring in state.rings:
		for wedge in state.rings[ring].wedges:
			var plate: Dictionary = state.rings[ring].wedges[wedge]
			for slot in plate.occupants:
				if plate.occupants[slot].kind != &"relay":
					weapons.append({"ring": ring, "wedge": wedge, "slot": slot, "plate": plate, "kind": plate.occupants[slot].kind})
	weapons.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.ring != b.ring: return a.ring < b.ring
		if a.wedge != b.wedge: return a.wedge < b.wedge
		return a.slot < b.slot)
	var result := {"ok": true, "targets": targets, "cooldowns": {}, "hits": [], "kill_ids": [], "energy_awarded": 0.0, "errors": PackedStringArray()}
	for weapon in weapons:
		var key := StringName("%d:%d:%d" % [weapon.ring, weapon.wedge, weapon.slot])
		var timer := maxf(0, float(cooldowns.get(key, 0)) - delta)
		if timer <= 1e-12: timer = 0
		result.cooldowns[key] = timer
		if timer > 0 or weapon.plate.hp <= 0: continue
		var origin := grid.polar_to_world(PolarPosition.new(weapon.ring, weapon.wedge, 0.5, (weapon.slot + 0.5) / weapon.plate.slot_count))
		var ranked: Array[Dictionary] = []
		for target in targets:
			if target.hp > 0: ranked.append(target)
		ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var da := (grid.polar_to_world(a.position) - origin).length()
			var db := (grid.polar_to_world(b.position) - origin).length()
			return da < db or (da == db and a.id < b.id))
		var selected: Array[Dictionary] = []
		var tuning: Dictionary = profile.value(String(weapon.kind))
		for target in ranked:
			var offset := grid.polar_to_world(target.position) - origin
			if offset.length() > tuning.range_ring_widths * 96 + 0.00001: continue
			if tuning.arc_degrees < 360 and offset.length() > 0.00001 and absf(origin.angle_to(offset)) > deg_to_rad(tuning.arc_degrees) / 2 + 0.00001: continue
			selected.append(target)
			if selected.size() == tuning.max_targets: break
		if selected.is_empty(): continue
		result.cooldowns[key] = tuning.cycle_seconds
		for target in selected:
			var damage := minf(target.hp, tuning.damage)
			target.hp = maxf(0, target.hp - damage)
			result.hits.append({"weapon_id": key, "target_id": target.id, "damage": damage})
			if target.hp == 0:
				result.kill_ids.append(target.id)
				result.energy_awarded += profile.value("economy.kill_energy")
	return result

func _plain_targets(targets: Array) -> Array:
	var result := []
	for target in targets:
		var copied: Dictionary = target.duplicate(true)
		var p: PolarPosition = target.position
		copied.position = [p.ring, p.wedge, p.radial_fraction, p.angular_fraction]
		result.append(copied)
	return result

func _equivalence_checks(profile: BalanceProfile) -> void:
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	state.energy = 10000
	state = RingPurchaseRules.purchase_next_ring(state, profile, 3).state
	for spec in [[1, 1, 0, &"mass_driver"], [1, 11, 0, &"flak"], [2, 12, 0, &"flak"], [2, 12, 1, &"mass_driver"], [2, 3, 0, &"flak"]]:
		state = BuildingRules.place_weapon(state, profile, spec[0], spec[1], spec[2], spec[3]).state
	state.rings[2].wedges[3].hp = 0
	var targets: Array[Dictionary] = []
	for index in range(120):
		# Deliberately unordered IDs, varied rings/fractions/bearings, dead HP,
		# and groups at identical positions for exact-distance tie checks.
		var group := index / 3
		targets.append({"id": 500 - index, "hp": 0.0 if index % 11 == 0 else float(index % 9 + 1), "position": PolarPosition.new(group % 7 + 1, group % 12 + 1, (group % 5 + 0.5) / 5, (group % 4 + 0.5) / 4), "extra": {"tag": index}})
	# Ensure several shared nearby low-HP candidates are killed in order.
	for index in range(8): targets.append(_target(900 + index, 2, 12, 1 + index % 3))
	var original_targets := _plain_targets(targets)
	var original_state := state.duplicate(true)
	for cap in [1, 5, 16, 17, 80, 250]:
		for arc in [1.0, 90.0, 360.0]:
			var tuned: BalanceProfile = profile.with_overrides({"flak": {"max_targets": cap, "arc_degrees": arc, "range_ring_widths": 2 if arc == 90 else 8, "damage": 3.5}, "mass_driver": {"max_targets": cap, "arc_degrees": arc, "range_ring_widths": 0.3 if arc == 1 else 8, "damage": 2.5}, "economy": {"kill_energy": 7}}).profile
			var current: Array[Dictionary] = targets
			var cooldowns := {&"99:1:0": 2.0, &"1:11:0": 0.05}
			for delta in [0.0, 1.0 / 60.0, 2.0]:
				var input_before := _plain_targets(current)
				var timers_before := cooldowns.duplicate(true)
				var actual := _step(state, tuned, current, cooldowns, delta)
				var expected := _reference_step(state, tuned, current, cooldowns, delta)
				var owned_targets: Array[Dictionary] = current.duplicate(true)
				var owned := WeaponRules._step_owned(state, tuned, owned_targets, cooldowns, delta)
				_check(_plain_result(owned) == _plain_result(actual), "Owned/public/oracle combat equivalence")
				var positions_retained := true
				for index in range(owned_targets.size()):
					positions_retained = positions_retained and owned_targets[index].position == current[index].position
				_check(positions_retained, "Owned path retains all read-only position identities")
				_check(actual.ok and actual.hits == expected.hits and actual.kill_ids == expected.kill_ids and actual.energy_awarded == expected.energy_awarded and actual.cooldowns == expected.cooldowns and _plain_targets(actual.targets) == _plain_targets(expected.targets), "Independent oracle cap=%d arc=%s delta=%s" % [cap, arc, delta])
				_check(_plain_targets(current) == input_before and cooldowns == timers_before and state == original_state, "Oracle scenario input isolation")
				var returned: Array[Dictionary] = actual.targets
				if not returned.is_empty():
					var old_ring: int = returned[0].position.ring
					returned[0].position.ring = 19
					returned[0].extra.tag = -10
					_check(_plain_targets(current) == input_before, "Oracle scenario position and nested record isolation")
					returned[0].position.ring = old_ring
					returned[0].extra.tag = current[0].extra.tag
				current = returned
				cooldowns = actual.cooldowns
	_check(_plain_targets(targets) == original_targets, "All oracle scenarios preserve original fixture")


func _public_cost_review(profile: BalanceProfile) -> void:
	var owned_mode := "--owned-cost-review" in OS.get_cmdline_user_args()
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	state.energy = 10000
	for wedge in range(1, 12):
		if wedge != 6: state = BuildingRules.place_weapon(state, profile, 1, wedge, 0, &"flak").state
	var targets: Array[Dictionary] = []
	for id in range(1000): targets.append(_target(id, 2, id % 12 + 1, 1e8))
	var cooldowns := {}
	var durations: Array[int] = []
	var hits: Array[int] = []
	for sample in range(123):
		var started := Time.get_ticks_usec()
		var result := WeaponRules._step_owned(state, profile, targets, cooldowns, 1.0 / 60.0) if owned_mode else WeaponRules.step(state, profile, targets, cooldowns, 1.0 / 60.0)
		var elapsed := Time.get_ticks_usec() - started
		_check(result.ok and result.targets.size() == 1000 and result.kill_ids.is_empty(), "Pure combat timing fixture valid")
		cooldowns = result.cooldowns
		if sample >= 3:
			durations.append(elapsed)
			hits.append(result.hits.size())
	durations.sort()
	_check((targets[0].hp == 1e8 or owned_mode) and targets[0].position.ring == 2, "Benchmark preserves positions and public input HP")
	print("COMBAT mode=%s n=120 warmups=3 median_us=%.1f p90_us=%d hits=%s" % ["owned" if owned_mode else "public", (durations[59] + durations[60]) / 2.0, durations[107], hits])
	print("Combat cost review: %d checks, %d failures" % [checks, failures])



func _plain_result(result: Dictionary) -> Dictionary:
	var plain := result.duplicate(true)
	plain.targets = _plain_targets(result.targets)
	return plain
func _owned_contract_checks(profile: BalanceProfile) -> void:
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	state.energy = 1000
	state = BuildingRules.place_weapon(state, profile, 1, 1, 0, &"flak").state
	state = BuildingRules.place_weapon(state, profile, 1, 11, 0, &"mass_driver").state
	var target := _target(1, 2, 1, 20)
	target.extra = {"tags": ["original"], "nested": {"value": 4}}
	var targets: Array[Dictionary] = [target, _target(2, 3, 1, 20), _target(3, 2, 1, 20)]
	var owned_targets: Array[Dictionary] = targets.duplicate(true)
	var before := _plain_targets(targets)
	var public_result := WeaponRules.step(state, profile, targets, {}, 0)
	var owned_result := WeaponRules._step_owned(state, profile, owned_targets, {}, 0)
	_check(_plain_result(public_result) == _plain_result(owned_result), "Owned/public multiple weapons, exact range and distance ties")
	public_result.targets[0].extra.tags.append("mutated")
	public_result.targets[0].extra.nested.value = 9
	public_result.targets[0].position.angular_fraction = 0
	_check(_plain_targets(targets) == before and owned_targets[0].extra.tags == ["original"] and owned_targets[0].extra.nested.value == 4, "Public output cannot mutate source nested data, positions, or owned records")
	for cooldowns in [{&"1:1:0": 0.1}, {&"invalid": 0}, {&"1:1:0": NAN}]:
		owned_targets = targets.duplicate(true)
		_check(_plain_result(WeaponRules.step(state, profile, targets, cooldowns, 0.01)) == _plain_result(WeaponRules._step_owned(state, profile, owned_targets, cooldowns, 0.01)), "Partial/invalid cooldown parity")
	var malformed: Array[Dictionary] = [target, {"id": 1, "hp": 20, "position": PolarPosition.new(2, 1)}]
	var original_hp: float = malformed[0].hp
	var failure := WeaponRules._step_owned(state, profile, malformed, {}, 0)
	_check(not failure.ok and malformed[0].hp == original_hp and failure.targets.is_empty(), "All records validate before owned combat; duplicate late record cannot partially damage")
	for bad_target in [{}, {"id": 7, "hp": NAN, "position": PolarPosition.new(2, 1)}, {"id": 8, "hp": 10, "position": null}]:
		var bad: Array[Dictionary] = [target, bad_target]
		_check(not WeaponRules._step_owned(state, profile, bad, {}, 0).ok and bad[0].hp == original_hp, "Malformed record rejects before any owned HP writes")
	var collapsed := state.duplicate(true)
	collapsed.rings[1].collapsed = true
	collapsed.rings[1].relay = {}
	collapsed.rings[1].erase("relay_hp")
	collapsed.rings[1].erase("relay_max_hp")
	for plate in collapsed.rings[1].wedges.values():
		plate.hp = 0
		plate.occupants = {}
	owned_targets = targets.duplicate(true)
	_check(_plain_result(WeaponRules.step(collapsed, profile, targets, {}, 0)) == _plain_result(WeaponRules._step_owned(collapsed, profile, owned_targets, {}, 0)), "Collapsed structures have identical owned/public behavior")
	var grid := PolarGrid.new(6)
	var origin := grid.polar_to_world(PolarPosition.new(1, 1, 0.5, 0.5))
	var exact_arc := grid.world_to_polar(origin + origin.normalized().rotated(PI / 4) * 96)
	var boundaries: Array[Dictionary] = [{"id": 77, "hp": 100, "position": exact_arc}, _target(78, 3, 1, 100)]
	for arc in [90.0, 89.0]:
		var boundary_profile: BalanceProfile = profile.with_overrides({"flak": {"arc_degrees": arc}}).profile
		_check(_plain_result(WeaponRules.step(state, boundary_profile, boundaries, {}, 0)) == _plain_result(WeaponRules._step_owned(state, boundary_profile, boundaries.duplicate(true), {}, 0)), "Owned/public exact arc and range boundary parity")
	var late_profile: BalanceProfile = profile.with_overrides({"mass_driver": {"range_ring_widths": 1e308}}).profile
	owned_targets = targets.duplicate(true)
	var saved_state := state.duplicate(true)
	var cooldowns := {&"1:12:0": 0.2}
	var saved_cooldowns := cooldowns.duplicate(true)
	failure = WeaponRules._step_owned(state, late_profile, owned_targets, cooldowns, 0)
	_check(not failure.ok and failure.targets.is_empty() and owned_targets[0].hp < targets[0].hp, "Late owned error exposes no partial result but may consume scratch HP")
	_check(state == saved_state and cooldowns == saved_cooldowns and _plain_targets(targets) == before, "Late owned error leaves state, cooldowns and borrowed positions/extras unchanged")
	_check(not WeaponRules._step_owned({}, profile, targets.duplicate(true), {}, 0).ok and not WeaponRules._step_owned(state, null, targets.duplicate(true), {}, 0).ok, "Owned path keeps state/profile validation")

	# D-023: placement respects the ring's fixed power budget.
	var tight: BalanceProfile = profile.with_overrides({"power": {"base_output": 15}}).profile
	var power_state: Dictionary = BuildingRules.create_default_testing_state(tight).state
	power_state.energy = 10000
	_check(is_equal_approx(PowerRules.ring_output(power_state, tight, 1), 15.0) and is_equal_approx(PowerRules.ring_demand(power_state, tight, 1), 10.0), "Default startup Flak already uses 10 of ring 1's 15 power")
	_check(not BuildingRules.place_weapon(power_state, tight, 1, 1, 0, &"flak").ok, "A second Flak exceeding ring 1's power capacity is rejected at placement")

	# D-023: a weapon that no longer fits the budget goes fully inert in combat,
	# while an earlier one (in fixed ring/wedge/slot order) still fires.
	var inert_profile: BalanceProfile = profile.with_overrides({"power": {"base_output": 10}}).profile
	var inert_state: Dictionary = BuildingRules.create_default_testing_state(inert_profile).state
	inert_state.rings[1].wedges[1].occupants[0] = {"kind": &"flak"}
	var inert_targets: Array[Dictionary] = [_target(201, 2, 1), _target(202, 2, 12)]
	var inert_result := WeaponRules.step(inert_state, inert_profile, inert_targets, {}, 0)
	_check(inert_result.ok and inert_result.hits.size() == 1 and inert_result.hits[0].weapon_id == &"1:1:0", "Wedge 1's Flak claims the whole 10-power budget first; wedge 12's identical Flak goes inert rather than firing")



## D-088: EMP Node deals minimal damage and refreshes (never stacks past one
## pulse's duration) the target's stun clock; it does not stun a kill.
func _emp_node_checks(profile: BalanceProfile) -> void:
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	state.energy = 1000
	state = BuildingRules.place_weapon(state, profile, 1, 1, 0, &"emp_node").state
	var hit: Array[Dictionary] = [_target(1, 1, 1, 10)]
	var fired := _step(state, profile, hit)
	_check(fired.ok and fired.hits.size() == 1 and fired.hits[0].damage == 1.0 and fired.targets[0].hp == 9 and fired.targets[0].stun_remaining == 1.5, "EMP Node hit deals minimal damage and applies its stun duration")
	var already_stunned: Array[Dictionary] = [_target(1, 1, 1, 10)]
	already_stunned[0].stun_remaining = 5.0
	var refreshed := _step(state, profile, already_stunned)
	_check(refreshed.ok and refreshed.targets[0].stun_remaining == 5.0, "EMP Node never shortens an existing longer stun")
	var lethal: Array[Dictionary] = [_target(2, 1, 1, 1.0)]
	var killed := _step(state, profile, lethal)
	_check(killed.ok and killed.kill_ids == [2] and killed.targets[0].hp == 0 and killed.targets[0].stun_remaining == 0.0, "A killing EMP Node hit does not also apply stun")
	var cooldown_key := &"1:1:0"
	_check(fired.cooldowns.has(cooldown_key) and is_equal_approx(fired.cooldowns[cooldown_key], 3.0), "EMP Node uses the same cooldown-key/cycle-seconds mechanism as other weapons")

## D-089: Lance Emitter hits every machine standing in its own wedge column,
## at any ring within range, and never a different wedge even at equal range.
func _lance_emitter_checks(profile: BalanceProfile) -> void:
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	state.energy = 1000
	state = BuildingRules.place_weapon(state, profile, 1, 5, 0, &"lance_emitter").state
	var same_wedge_near := _target(1, 2, 5, 10)
	var same_wedge_far := _target(2, 4, 5, 10)
	var other_wedge := _target(3, 2, 6, 10)
	var targets: Array[Dictionary] = [same_wedge_near, same_wedge_far, other_wedge]
	var fired := _step(state, profile, targets)
	_check(fired.ok and fired.hits.size() == 2, "Lance Emitter hits every machine in its own wedge column across rings, not other wedges")
	var hit_ids: Array = []
	for hit in fired.hits: hit_ids.append(hit.target_id)
	hit_ids.sort()
	_check(hit_ids == [1, 2], "Lance Emitter's hit set is exactly the same-wedge targets regardless of ring")
	for target in fired.targets:
		if target.id in [1, 2]:
			_check(target.hp == 2.0, "Lance Emitter deals its flat damage to every target it pierces")
		elif target.id == 3:
			_check(target.hp == 10, "A different wedge at equal or lesser range is never hit")
	_check(fired.cooldowns[&"1:5:0"] == 4.0, "Lance Emitter uses the same cooldown/cycle mechanism as other weapons")

## D-090: Point Defense engages only a machine already standing in its own
## ring+wedge cell — not merely its own wedge column (unlike Lance Emitter),
## and not a nearby wedge on the same ring, regardless of range/arc tuning.
func _point_defense_checks(profile: BalanceProfile) -> void:
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	state.energy = 1000
	state = BuildingRules.place_weapon(state, profile, 1, 5, 0, &"point_defense").state
	var own_tile := _target(1, 1, 5, 10)
	var same_wedge_other_ring := _target(2, 2, 5, 10)
	var adjacent_wedge_same_ring := _target(3, 1, 6, 10)
	var targets: Array[Dictionary] = [own_tile, same_wedge_other_ring, adjacent_wedge_same_ring]
	var fired := _step(state, profile, targets)
	_check(fired.ok and fired.hits.size() == 1 and fired.hits[0].target_id == 1, "Point Defense hits only a machine in its exact ring+wedge cell")
	for target in fired.targets:
		if target.id == 1:
			_check(target.hp == 7.0, "Point Defense deals its flat damage to the defended tile")
		else:
			_check(target.hp == 10, "A different ring or a different wedge is never hit, even nearby")
	_check(fired.cooldowns[&"1:5:0"] == 0.1, "Point Defense uses the same cooldown/cycle mechanism as other weapons")

func _targetable_checks(state: Dictionary, profile: BalanceProfile) -> void:
	for owned in [false, true]:
		var hidden := _target(1)
		hidden.targetable = false
		hidden.start_position = PolarPosition.new(3, 12, 0, 0.5)
		hidden.destination = PolarPosition.new(1, 12, 0.5, 0.5)
		var visible := _target(2)
		visible.targetable = true
		var targets: Array[Dictionary] = [hidden, visible]
		var result := WeaponRules._step_owned(state, profile, targets, {}, 0) if owned else WeaponRules.step(state, profile, targets, {}, 0)
		_check(result.ok and result.hits.size() == 1 and result.hits[0].target_id == 2 and result.targets[0].hp == 10 and result.kill_ids.is_empty(), "Targetable false excluded in both ownership paths")
		if not owned:
			result.targets[0].start_position.ring = 9
			result.targets[0].destination.ring = 9
			_check(hidden.start_position.ring == 3 and hidden.destination.ring == 1, "Public combat clones lifecycle positions")
		for invalid in [0, 1, "false", null]:
			hidden.targetable = invalid
			var bad := WeaponRules._step_owned(state, profile, targets, {}, 0) if owned else WeaponRules.step(state, profile, targets, {}, 0)
			_check(not bad.ok, "Targetable must be exact bool even for skipped targets")
		hidden.targetable = false
		hidden.hp = -1
		_check(not WeaponRules.step(state, profile, targets, {}, 0).ok, "Hidden HP remains validated")
		hidden.hp = 10
		hidden.position.ring = -1
		_check(not WeaponRules.step(state, profile, targets, {}, 0).ok, "Hidden position remains validated")

func _t043_eligibility(profile: BalanceProfile) -> void:
	var tuned: BalanceProfile = profile.with_overrides({"power": {"base_output": 1000}, "emp_node": {"max_targets": 1, "range_ring_widths": 10}, "lance_emitter": {"max_targets": 1, "range_ring_widths": 10}}).profile
	var state: Dictionary = BuildingRules.create_default_testing_state(tuned).state
	state.energy = 10000
	state = RingPurchaseRules.purchase_next_ring(state, tuned, 5).state
	state = BuildingRules.place_weapon(state, tuned, 2, 5, 0, &"emp_node").state
	var targets: Array[Dictionary] = [_target(1, 2, 5), _target(2, 2, 5), _target(3, 1, 5), _target(4, 3, 5)]
	var pulse := WeaponRules.step(state, tuned, targets, {&"1:12:0": 10.0}, 0)
	var ids: Array = []
	for hit in pulse.hits: ids.append(hit.target_id)
	_check(ids == [1, 2], "T043 EMP own-ring all eligible despite cap=1")
	state.rings[2].wedges[5].occupants[0].kind = &"lance_emitter"
	targets = [_target(1, 3, 5), _target(2, 4, 5), _target(3, 1, 5), _target(4, 3, 6)]
	var burst := WeaponRules.step(state, tuned, targets, {&"1:12:0": 10.0}, 0)
	ids = []
	for hit in burst.hits: ids.append(hit.target_id)
	_check(ids == [1, 2], "T043 Lance outward same-column all eligible despite cap=1")

func _t043_status_checks(profile: BalanceProfile) -> void:
	var state: Dictionary = BuildingRules.create_default_testing_state(profile).state
	for owned in [false, true]:
		for field in ["stun_remaining", "assimilation_stacks"]:
			var invalids: Array = [-1.0, INF, NAN, true, "1", null] if field == "stun_remaining" else [null, {}, "bad", [true], [-1], [INF], [NAN], ["1"], [null]]
			for invalid in invalids:
				var target := _target(1)
				target.targetable = false
				target[field] = invalid
				var supplied: Array[Dictionary] = [target]
				var result := WeaponRules._step_owned(state, profile, supplied, {&"1:12:0": 10.0}, 0) if owned else WeaponRules.step(state, profile, supplied, {&"1:12:0": 10.0}, 0)
				_check(not result.ok and result.hits.is_empty() and target.hp == 10, "T043 invalid skipped status rejected even with no ready weapon: " + field)
	var valid := _target(2)
	valid.stun_remaining = 0.25
	valid.assimilation_stacks = [0, 10.5]
	var supplied: Array[Dictionary] = [valid]
	var result := WeaponRules.step(state, profile, supplied, {&"1:12:0": 10.0}, 0)
	_check(result.ok, "T043 valid finite optional statuses accepted")
	result.targets[0].assimilation_stacks.clear()
	_check(valid.assimilation_stacks == [0, 10.5], "T043 public weapon results isolate status arrays")
