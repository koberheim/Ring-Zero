extends SceneTree
var checks := 0
var failures := 0
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _initialize() -> void:
	var profile: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile
	var result := BuildingRules.create_default_testing_state(profile)
	_check(result.ok, "Startup")
	var state: Dictionary = result.state
	_check(state.energy == 200 and state.rings[1].wedges[12].occupants[0].kind == &"flak" and state.rings[1].relay == {"active": true}, "Derived startup and approved slots")
	var tuned: BalanceProfile = profile.with_overrides({"economy": {"flak_cost": 37}, "health": {"wedge_base_hp": 123}}).profile
	var changed := BuildingRules.create_default_testing_state(tuned)
	_check(changed.state.energy == 37 * 10 and changed.state.rings[1].wedges[1].hp == 123, "Tuned grant and HP")
	_check(not BuildingRules.create_default_testing_state(BalanceProfile.new()).ok, "Invalid profile safe")
	_check(not BuildingRules.create_default_testing_state(null).ok, "Null profile safe")
	_check(not BuildingRules.create_default_testing_state(profile.with_overrides({"starting_test_setup": {"flak_count": 2}}).profile).ok, "Unsupported default count explicit failure")
	var empty: Array[Dictionary] = []
	_check(not RingPurchaseRules.create_testing_state(profile, empty).ok, "Missing placements")
	var duplicate: Array[Dictionary] = [{"ring": 1, "wedge": 12, "slot": 0, "kind": &"flak"}, {"ring": 1, "wedge": 12, "slot": 0, "kind": &"flak"}]
	_check(not RingPurchaseRules.create_testing_state(profile, duplicate).ok, "Duplicate starter occupancy")
	var poor_quote := RingPurchaseRules.quote_next_ring(state, profile, 3)
	_check(poor_quote.ok and poor_quote.quote.cost == 240 and not poor_quote.quote.affordable, "Unaffordable quote still shows current cost")
	var before := state.duplicate(true)
	_check(not RingPurchaseRules.purchase_next_ring(state, profile, 3).ok and state == before, "Poor expansion atomic")
	state.energy = 10000
	before = state.duplicate(true)
	var quote := RingPurchaseRules.quote_next_ring(state, profile, 3)
	_check(quote.ok and quote.quote.cost == 240 and state == before, "Ring 2 quote")
	result = RingPurchaseRules.purchase_next_ring(state, profile, 3)
	_check(result.ok and result.state.energy == 9760 and state == before, "Single deduction and input preserved")
	var second: Dictionary = result.state
	_check(second.rings[2].wedges.size() == 12 and second.rings[2].wedges[1].hp == 200 and second.rings[2].wedges[1].slot_count == 4 and second.rings[2].relay == {"active": true} and second.rings[2].wedges[1].occupants.is_empty(), "Whole ring dimensions and automatic relay, no occupant")
	_check(RingPurchaseRules.quote_next_ring(second, profile, 3).quote.cost == 360, "Ring 3 quote")
	var third := RingPurchaseRules.purchase_next_ring(second, profile, 3)
	_check(not RingPurchaseRules.quote_next_ring(third.state, profile, 3).ok and RingPurchaseRules.quote_next_ring(third.state, profile, 4).ok, "Caller limit only")
	state.rings[1].wedges[1].hp = 1
	_check(RingPurchaseRules.quote_next_ring(state, profile, 3).ok, "Partly damaged inward wedge eligible")
	state.rings[1].wedges[1].hp = 0
	before = state.duplicate(true)
	_check(not RingPurchaseRules.purchase_next_ring(state, profile, 3).ok and state == before, "Stale quote cannot bypass broken inward wedge")
	state.rings[1].wedges[1].hp = 100
	for malformed in [{}, {"energy": true, "rings": state.rings}, {"energy": NAN, "rings": state.rings}, {"energy": 1, "rings": {2: state.rings[1]}}]:
		_check(not BuildingRules.place_weapon(malformed, profile, 1, 1, 0, &"flak").ok, "Malformed state safely rejected")
	for mutation in ["missing", "hp", "slots", "occupant", "relay"]:
		var bad := state.duplicate(true)
		match mutation:
			"missing": bad.rings[1].wedges.erase(2)
			"hp": bad.rings[1].wedges[2].hp = INF
			"slots": bad.rings[1].wedges[2].slot_count = true
			"occupant": bad.rings[1].wedges[2].occupants[0] = {"kind": "flak"}
			"relay": bad.rings[1].relay.slot = 1
		_check(not RingPurchaseRules.quote_next_ring(bad, profile, 3).ok, "Reject malformed " + mutation)
	before = state.duplicate(true)
	var placed := BuildingRules.place_weapon(state, profile, 1, 1, 0, &"mass_driver")
	_check(placed.ok and placed.state.energy == state.energy - 40 and state == before, "Weapon purchase copy and cost")
	for args in [[1,12,0,&"flak"], [1,1,0,&"relay"], [2,1,0,&"flak"], [1,0,0,&"flak"], [1,1,-1,&"flak"]]:
		_check(not BuildingRules.place_weapon(state, profile, args[0], args[1], args[2], args[3]).ok and state == before, "Illegal placement atomic")
	var pos := BuildingRules.slot_position(4, 12, 1, 3)
	_check(pos.ring == 4 and pos.radial_fraction == 0.5 and pos.angular_fraction == 0.5, "Even slots middle radius")
	_check(BuildingRules.slot_position(0, 1, 0, 1) == null and BuildingRules.slot_position(1, 1, 1, 1) == null, "Bad slot geometry")
	_check(BuildingRules.slot_for_fraction(0, 3) == 0 and BuildingRules.slot_for_fraction(0.5, 3) == 1 and BuildingRules.slot_for_fraction(0.999, 3) == 2, "Clockwise fraction mapping")
	_check(BuildingRules.slot_for_fraction(1, 3) == -1 and BuildingRules.slot_for_fraction(NAN, 3) == -1, "Invalid selection")
	var overflow: BalanceProfile = profile.with_overrides({"scaling": {"wedge_hp_ring_exponent": 1e308}}).profile
	_check(not RingPurchaseRules.quote_next_ring(state, overflow, 3).ok, "Computed overflow rejected")
	var priced: BalanceProfile = profile.with_overrides({"economy": {"mass_driver_cost": 71, "ring_plate_base_cost": 15}, "scaling": {"slots_per_wedge_per_ring": 2, "wedge_hp_ring_exponent": 2}}).profile
	_check(BuildingRules.place_weapon(state, priced, 1, 1, 0, &"mass_driver").state.energy == state.energy - 71, "Tuned building cost")
	var tuned_ring := RingPurchaseRules.purchase_next_ring(state, priced, 4)
	_check(tuned_ring.ok and tuned_ring.state.energy == state.energy - 360 and tuned_ring.state.rings[2].wedges[1].hp == 400 and tuned_ring.state.rings[2].wedges[1].slot_count == 4, "Tuned ring cost HP and slots")
	var poor := state.duplicate(true)
	poor.energy = 0
	var poor_before := poor.duplicate(true)
	_check(not BuildingRules.place_weapon(poor, profile, 1, 1, 0, &"flak").ok and poor == poor_before, "Poor building placement atomic")
	poor.rings[1].wedges[1].hp = 0
	poor.energy = 100
	poor_before = poor.duplicate(true)
	_check(not BuildingRules.place_weapon(poor, profile, 1, 1, 0, &"flak").ok and poor == poor_before, "Broken wedge placement atomic")

	# D-022 Tier 1: Repair a damaged wedge for a cost proportional to HP restored.
	var repair_state: Dictionary = state.duplicate(true)
	repair_state.energy = 10000
	var expand2 := RingPurchaseRules.purchase_next_ring(repair_state, profile, 4)
	_check(expand2.ok, "Repair/reclaim fixture buys ring 2")
	var expand3 := RingPurchaseRules.purchase_next_ring(expand2.state, profile, 4)
	_check(expand3.ok, "Repair/reclaim fixture buys ring 3")
	repair_state = expand3.state
	repair_state.energy = 10000
	repair_state.rings[1].wedges[2].hp = 75
	var repair_quote := RingPurchaseRules.quote_repair_wedge(repair_state, profile, 1, 2)
	_check(repair_quote.ok and is_equal_approx(repair_quote.quote.cost, 10.0 * 1.0 * (25.0 / 100.0)) and repair_quote.quote.affordable, "Repair quote proportional to missing HP")
	var repair_before := repair_state.duplicate(true)
	var repaired := RingPurchaseRules.repair_wedge(repair_state, profile, 1, 2)
	_check(repaired.ok and repaired.state.rings[1].wedges[2].hp == 100 and is_equal_approx(repaired.state.energy, repair_state.energy - 2.5) and repair_state == repair_before, "Repair restores full HP, single deduction, input preserved")
	_check(not RingPurchaseRules.quote_repair_wedge(repaired.state, profile, 1, 2).ok, "Full-HP wedge has nothing to repair")
	repair_state.rings[1].wedges[5].hp = 0
	var occupant_state: Dictionary = repair_state.duplicate(true)
	occupant_state.rings[1].wedges[5].occupants[0] = {"kind": &"flak"}
	var repaired_with_occupant := RingPurchaseRules.repair_wedge(occupant_state, profile, 1, 5)
	_check(repaired_with_occupant.ok and repaired_with_occupant.state.rings[1].wedges[5].occupants[0].kind == &"flak", "Repair never touches surviving occupants")
	var collapsed_repair_state: Dictionary = repair_state.duplicate(true)
	collapsed_repair_state.rings[1].collapsed = true
	_check(not RingPurchaseRules.quote_repair_wedge(collapsed_repair_state, profile, 1, 5).ok, "Cannot repair a wedge on a collapsed ring")
	var poor_repair := repair_state.duplicate(true)
	poor_repair.energy = 0
	_check(not RingPurchaseRules.repair_wedge(poor_repair, profile, 1, 5).ok, "Poor repair rejected")

	# D-022 Tier 2: Reclaim a fully collapsed ring at a discount via the same whole-ring shape.
	var reclaim_state: Dictionary = repair_state.duplicate(true)
	var collapsed_ring: Dictionary = reclaim_state.rings[2]
	collapsed_ring.collapsed = true
	collapsed_ring.relay = {}
	collapsed_ring.erase("relay_hp")
	collapsed_ring.erase("relay_max_hp")
	for plate in collapsed_ring.wedges.values():
		plate.hp = 0
		plate.occupants = {}
	_check(not RingPurchaseRules.quote_reclaim_ring(reclaim_state, profile, 3).ok, "Cannot reclaim a ring that never collapsed")
	var reclaim_quote := RingPurchaseRules.quote_reclaim_ring(reclaim_state, profile, 2)
	_check(reclaim_quote.ok and is_equal_approx(reclaim_quote.quote.cost, 240.0 * 0.75) and reclaim_quote.quote.affordable, "Reclaim quote is 75% of the normal whole-ring cost")
	var reclaim_before := reclaim_state.duplicate(true)
	var reclaimed := RingPurchaseRules.reclaim_ring(reclaim_state, profile, 2)
	_check(reclaimed.ok and not reclaimed.state.rings[2].get("collapsed", false) and reclaimed.state.rings[2].wedges[1].hp == 200 and reclaimed.state.rings[2].relay == {"active": true} and is_equal_approx(reclaimed.state.energy, reclaim_state.energy - 180.0) and reclaim_state == reclaim_before, "Reclaim rebuilds a full empty ring at a discount, single deduction, input preserved")
	_check(reclaimed.state.rings[3].wedges[1].hp == 300, "Reclaiming ring 2 leaves ring 3 untouched")
	var poor_reclaim := reclaim_state.duplicate(true)
	poor_reclaim.energy = 0
	_check(not RingPurchaseRules.reclaim_ring(poor_reclaim, profile, 2).ok, "Poor reclaim rejected")

	# D-027: Armor Plating raises a wedge's HP ceiling and stacks to a limit.
	# Ring 3 has plenty of slots, isolating the stack-limit check from slot scarcity.
	var armor_state: Dictionary = reclaimed.state.duplicate(true)
	var armored := BuildingRules.place_armor(armor_state, profile, 3, 5, 0)
	_check(armored.ok and armored.state.rings[3].wedges[5].max_hp == 350 and armored.state.rings[3].wedges[5].hp == 350 and armored.state.rings[3].wedges[5].occupants[0].kind == &"armor_plating" and is_equal_approx(armored.state.energy, armor_state.energy - 15), "Armor Plating raises max HP and current HP together for its cost")
	var double_armored := BuildingRules.place_armor(armored.state, profile, 3, 5, 1)
	_check(double_armored.ok and double_armored.state.rings[3].wedges[5].max_hp == 400, "A second Armor Plating on the same wedge stacks")
	_check(not BuildingRules.place_armor(double_armored.state, profile, 3, 5, 2).ok, "Armor Plating stack limit enforced even with a free slot")
	_check(not BuildingRules.place_armor(armor_state, profile, 1, 12, 0).ok, "Armor Plating cannot occupy an already-occupied slot")
	var poor_armor := armor_state.duplicate(true)
	poor_armor.energy = 0
	_check(not BuildingRules.place_armor(poor_armor, profile, 1, 7, 0).ok, "Poor Armor Plating rejected")

	# D-027: Repair Node just occupies a slot at placement time; its healing is a live-simulation behavior.
	var node_placed := BuildingRules.place_repair_node(armor_state, profile, 1, 8, 0)
	_check(node_placed.ok and node_placed.state.rings[1].wedges[8].occupants[0].kind == &"repair_node" and is_equal_approx(node_placed.state.energy, armor_state.energy - 40), "Repair Node placement costs energy and occupies its slot with no immediate HP effect")
	var poor_node := armor_state.duplicate(true)
	poor_node.energy = 0
	_check(not BuildingRules.place_repair_node(poor_node, profile, 1, 8, 0).ok, "Poor Repair Node rejected")

	# D-088: EMP Node is an ordinary power-gated weapon slot, like Flak/Mass Driver.
	var emp_placed := BuildingRules.place_weapon(armor_state, profile, 1, 9, 0, &"emp_node")
	_check(emp_placed.ok and emp_placed.state.rings[1].wedges[9].occupants[0].kind == &"emp_node" and is_equal_approx(emp_placed.state.energy, armor_state.energy - 30), "EMP Node placement costs energy and occupies its slot")
	var poor_emp := armor_state.duplicate(true)
	poor_emp.energy = 0
	_check(not BuildingRules.place_weapon(poor_emp, profile, 1, 9, 0, &"emp_node").ok, "Poor EMP Node rejected")
	var tight_power: BalanceProfile = profile.with_overrides({"power": {"base_output": 15}}).profile
	var tight_state: Dictionary = BuildingRules.create_default_testing_state(tight_power).state
	tight_state.energy = 10000
	_check(not BuildingRules.place_weapon(tight_state, tight_power, 1, 1, 0, &"emp_node").ok, "EMP Node exceeding ring 1's power capacity is rejected at placement, same as any other weapon")

	# D-089: Lance Emitter is also an ordinary power-gated weapon slot.
	var lance_placed := BuildingRules.place_weapon(armor_state, profile, 1, 10, 0, &"lance_emitter")
	_check(lance_placed.ok and lance_placed.state.rings[1].wedges[10].occupants[0].kind == &"lance_emitter" and is_equal_approx(lance_placed.state.energy, armor_state.energy - 60), "Lance Emitter placement costs energy and occupies its slot")
	var poor_lance := armor_state.duplicate(true)
	poor_lance.energy = 0
	_check(not BuildingRules.place_weapon(poor_lance, profile, 1, 10, 0, &"lance_emitter").ok, "Poor Lance Emitter rejected")
	_check(not BuildingRules.place_weapon(tight_state, tight_power, 1, 1, 0, &"lance_emitter").ok, "Lance Emitter exceeding ring 1's power capacity is rejected at placement")

	# D-090: Point Defense is also an ordinary power-gated weapon slot.
	var pd_placed := BuildingRules.place_weapon(armor_state, profile, 1, 11, 0, &"point_defense")
	_check(pd_placed.ok and pd_placed.state.rings[1].wedges[11].occupants[0].kind == &"point_defense" and is_equal_approx(pd_placed.state.energy, armor_state.energy - 25), "Point Defense placement costs energy and occupies its slot")
	var poor_pd := armor_state.duplicate(true)
	poor_pd.energy = 0
	_check(not BuildingRules.place_weapon(poor_pd, profile, 1, 11, 0, &"point_defense").ok, "Poor Point Defense rejected")
	_check(not BuildingRules.place_weapon(tight_state, tight_power, 1, 1, 0, &"point_defense").ok, "Point Defense exceeding ring 1's power capacity is rejected at placement")

	# D-023: fixed per-ring power table and brownout cascade.
	_check(PowerRules.chain_boundary(armor_state) == 3, "All three rings intact: full chain")
	_check(is_equal_approx(PowerRules.ring_output(armor_state, profile, 1), 150.0) and is_equal_approx(PowerRules.ring_output(armor_state, profile, 2), 75.0) and is_equal_approx(PowerRules.ring_output(armor_state, profile, 3), 50.0), "Ring output follows base_output/ring index while the chain holds")
	var broken_chain: Dictionary = armor_state.duplicate(true)
	broken_chain.rings[1].collapsed = true
	broken_chain.rings[1].relay = {}
	broken_chain.rings[1].erase("relay_hp")
	broken_chain.rings[1].erase("relay_max_hp")
	for plate in broken_chain.rings[1].wedges.values():
		plate.hp = 0
		plate.occupants = {}
	_check(PowerRules.chain_boundary(broken_chain) == 0, "Ring 1 collapsed breaks the chain at the core")
	_check(is_equal_approx(PowerRules.ring_output(broken_chain, profile, 2), 7.5) and is_equal_approx(PowerRules.ring_output(broken_chain, profile, 3), 5.0), "Rings beyond a broken chain brown out to 10% output, regardless of their own relay")
	_check(not PowerRules.can_afford(broken_chain, profile, 2, &"flak"), "Brownout output cannot afford a Flak that fit under full power")

	var extreme: BalanceProfile = profile.with_overrides({"health": {"wedge_base_hp": 1e308}, "structure": {"armor_plating_hp_bonus": 1e308}}).profile
	var extreme_state: Dictionary = BuildingRules.create_default_testing_state(extreme).state
	extreme_state.energy = 1000
	var extreme_before := extreme_state.duplicate(true)
	var overflow_armor := BuildingRules.place_armor(extreme_state, extreme, 1, 1, 0)
	_check(not overflow_armor.ok and overflow_armor.state == null and extreme_state == extreme_before, "T043 computed armor HP overflow fails without mutation")
	print("Building rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

