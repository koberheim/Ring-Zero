extends SceneTree
## Deterministic, unfunded purchase bot. Evidence of one strategy, not human balance.
func _initialize() -> void:
	var base := BalanceProfile.load_json("res://data/balance/release.json")
	var prepared := RunRules.create_run(base.profile,RunRules.default_choices(),ProfileStore.defaults(),false,12)
	if not prepared.ok: push_error(str(prepared.errors)); quit(1); return
	var sim: LiveSimulation = prepared.simulation
	var start := Time.get_ticks_msec()
	for tick in 54000:
		if tick % 60 == 0:
			# Fill outward coverage first, then add density; save for expansion.
			var outer: int = sim.state.rings.size()
			for ring in range(1,outer+1):
				if sim.state.rings[ring].get("collapsed",false): continue
				if sim.state.rings[ring].get("relay_hp",0) == 0: sim.rebuild_relay(ring)
				for wedge in range(1,13):
					var plate: Dictionary = sim.state.rings[ring].wedges[wedge]
					if plate.hp > 0 and plate.hp < plate.max_hp*0.5: sim.repair_wedge(ring,wedge)
					if plate.hp > 0 and plate.occupants.is_empty(): sim.place_weapon(ring,wedge,0,&"flak")
			if tick > 1800: sim.purchase_ring()
			if sim.pool.active_count() > 0 and sim.ability_cooldowns.get(&"emp_burst",0.0) <= 0:
				var target: Dictionary = sim.pool.payload_for(sim.pool.active_ids()[0])
				sim.cast_ability(&"emp_burst",target.position)
		var result := sim.step(1.0/60.0)
		if not result.ok: push_error(str(result.errors)); quit(1); return
		if tick % 3600 == 0: print(JSON.stringify({"seconds":sim.elapsed_seconds,"core":sim.core_hp,"rings":sim.state.rings.size(),"kills":sim.total_kills,"actors":sim.pool.active_count(),"energy":sim.state.energy}))
		if sim.ended: break
	print(JSON.stringify({"summary":sim.run_summary("defeat" if sim.ended else "victory"),"wall_seconds":(Time.get_ticks_msec()-start)/1000.0,"strategy":"starter profile, deterministic unfunded coverage bot"}))
	quit(0)
