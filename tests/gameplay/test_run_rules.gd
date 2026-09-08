extends SceneTree
const DT := 1.0/60.0
var checks := 0
var failures := 0
var base: BalanceProfile
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func choices(doctrine: String = "conservator", loadout: String = "balanced", mutators: Array = []) -> Dictionary:
	return {"doctrine":doctrine,"loadout":loadout,"mutators":mutators}
func _initialize() -> void:
	base=BalanceProfile.load_json("res://data/balance/testing.json").profile
	var original:=base.snapshot()
	var catalogue:=RunRules.catalogue()
	check(catalogue.size()==6 and catalogue.doctrines.size()==3 and catalogue.mutators.size()==3 and catalogue.reference.size()==7,"Complete public catalogue")
	catalogue.unlocks.emp_node.cost=999
	check(RunRules.catalogue().unlocks.emp_node.cost==25,"Catalogue isolated")
	catalogue=RunRules.catalogue()
	var c:=choices()
	var progress:Dictionary={"unlocks":[],"upgrades":{}}
	var before:=progress.duplicate(true)
	var result:=RunRules.prepare(base,c,progress)
	check(result.ok and result.profile.value("flak.damage")==base.value("flak.damage")*.9 and result.profile.value("economy.repair_discount")==.75,"Conservator damage and repair modifier")
	check(result.profile.value("economy.reclaim_discount")==base.value("economy.reclaim_discount")*.75 and result.profile.value("structure.armor_plating_hp_bonus")==base.value("structure.armor_plating_hp_bonus")*1.25,"Conservator reclaim and armor")
	check(base.snapshot()==original and progress==before and c==choices(),"Preparation leaves all input immutable")
	check(result.build_modes.has(&"point_defense") and result.build_modes.has(&"debris_field") and not result.build_modes.has(&"emp_node") and result.abilities==[&"emp_burst"],"Starter access")
	var made:=RunRules.create_run(base,c,progress)
	check(made.ok,"Configured run creates")
	var sim:LiveSimulation=made.simulation
	check(sim.state.energy==200 and sim.state.rings[1].wedges[12].occupants[0].kind==&"flak","Production starter remains Flak and 200 energy")
	check(sim.tunnelers_enabled and sim.foundry_enabled and sim.transfer_enabled and sim.sapper_enabled and sim.breacher_enabled and sim.assembler_enabled,"Every elite and boss enabled")
	check(not sim.place_weapon(1,1,0,&"emp_node").ok and not sim.place_terrain(1,1,0,&"tractor_lane").ok and not sim.cast_ability(&"focused_flare",PolarPosition.new(1,12,0,.5)).ok,"Gameplay guards reject locked actions even without UI")
	check(sim.place_weapon(1,1,0,&"point_defense").ok and sim.place_terrain(1,2,0,&"debris_field").ok,"Unlocked actions execute")
	result=RunRules.prepare(base,choices("prospector"),{})
	check(result.ok and result.profile.value("health.wedge_base_hp")==base.value("health.wedge_base_hp")*.8 and result.profile.value("economy.kill_energy")==roundf(base.value("economy.kill_energy")*1.5),"Prospector modifies HP and integer kill credit")
	result=RunRules.prepare(base,choices("interdictor"),{})
	check(result.ok and result.profile.value("economy.tractor_lane_cost")==ceilf(base.value("economy.tractor_lane_cost")*.75) and result.profile.value("occlusion_screen.speed_multiplier")==base.value("occlusion_screen.speed_multiplier")*.8,"Interdictor integer costs and stronger single slow")
	var mutators:Array=["rapid_elites","fragile_core","dense_swarm"]
	result=RunRules.prepare(base,choices("prospector","balanced",mutators),{})
	check(result.ok and is_equal_approx(result.reward_multiplier,1.875) and result.profile.value("pressure.spawn_per_second")==base.value("pressure.spawn_per_second")*1.5 and result.profile.value("health.core_hp")==base.value("health.core_hp")*.75,"Stackable mutators multiply exactly once")
	check(result.choices.mutators==["dense_swarm","fragile_core","rapid_elites"] and mutators[0]=="rapid_elites","Canonical choice order without mutating caller")
	for kind in ["tunneler","foundry","transfer","sapper","breacher","assembler"]:
		check(result.profile.value(kind+".first_arrival_seconds")==base.value(kind+".first_arrival_seconds")*.75,"Rapid elites first arrival "+kind)
		var interval:String=kind+(".interval_seconds" if kind=="assembler" else ".arrival_interval_seconds")
		check(result.profile.value(interval)==base.value(interval)*.75,"Rapid elites interval "+kind)
	check(result.profile.value("pressure.max_active_machines")==base.value("pressure.max_active_machines") and result.profile.value("pressure.stat_increase_per_minute")==base.value("pressure.stat_increase_per_minute"),"Cap and stat ramp unchanged")
	for loadout in ["bulwark","battery"]:
		check(not RunRules.create_run(base,choices("conservator",loadout),{}).ok,"Locked loadout rejected")
		made=RunRules.create_run(base,choices("conservator",loadout),{"unlocks":[loadout]})
		check(made.ok,"Unlocked loadout creates")
		sim=made.simulation
		if loadout=="bulwark": check(sim.state.rings[1].wedges[12].has("wall") and sim.state.energy==200-base.value("economy.wall_cost"),"Bulwark wall paid once")
		else: check(sim.state.rings[1].wedges[12].occupants[0].kind==&"mass_driver" and sim.state.energy==200-maxf(0,base.value("economy.mass_driver_cost")-base.value("economy.flak_cost")),"Battery replaces starter and pays only positive price difference")
	var all_unlocks:Array=catalogue.unlocks.keys()
	result=RunRules.prepare(base,choices(),{"unlocks":all_unlocks,"upgrades":{"core_hp":3,"wedge_hp":3,"starting_energy":3}})
	check(result.ok and result.starting_energy==230 and result.profile.value("health.core_hp")==base.value("health.core_hp")*1.15 and result.profile.value("health.wedge_base_hp")==base.value("health.wedge_base_hp")*1.15,"Capped upgrades apply once from base")
	check(result.build_modes.has(&"emp_node") and result.build_modes.has(&"lance_emitter") and result.build_modes.has(&"tractor_lane") and result.build_modes.has(&"occlusion_screen") and result.abilities.has(&"focused_flare"),"All purchases grant corresponding access")
	for id in catalogue.upgrades: check(catalogue.upgrades[id].max_level==3 and catalogue.upgrades[id].costs==[25,50,75],"Upgrade capped cost schedule")
	for invalid in [{"doctrine":"unknown","loadout":"balanced","mutators":[]},{"doctrine":"conservator","loadout":"balanced","mutators":["dense_swarm","dense_swarm"]},{"doctrine":"conservator","loadout":"balanced","mutators":["unknown"]},{"doctrine":true,"loadout":"balanced","mutators":[]},{"doctrine":"conservator","loadout":"balanced","mutators":[],"extra":1}]:
		check(not RunRules.prepare(base,invalid,{}).ok,"Invalid choices fail")
	for invalid in [{"upgrades":{"core_hp":4}},{"upgrades":{"core_hp":-1}},{"upgrades":{"core_hp":true}},{"upgrades":{"unknown":1}},{"unlocks":["emp_node","emp_node"]},{"unlocks":["unknown"]},{"unlocks":true}]:
		check(not RunRules.prepare(base,choices(),invalid).ok,"Invalid progression fails")
	made=RunRules.create_run(base,choices("conservator","battery"),{},true)
	check(made.ok and made.reward_multiplier==0 and made.abilities.has(&"focused_flare") and made.simulation.run_summary().outcome=="practice","Practice full access never yields an eligible defeat summary")
	_rewards()
	_accounting()
	_catalogue_validation()
	_mixed_roster()
	print("Run rules: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
func _rewards() -> void:
	var summary:Dictionary={"outcome":"defeat","elapsed_seconds":601.0,"kills":300,"highest_ring":3,"relay_rebuilds":1}
	var reward:=RunRules.reward(summary,1.5)
	check(reward.ok and reward.amount==100 and reward.breakdown.subtotal==67,"Exact formula, challenges, multiplier then floor once")
	for outcome in ["abandoned","error","practice"]:
		var copy:=summary.duplicate(true);copy.outcome=outcome
		check(RunRules.reward(copy,5).amount==0,"Ineligible outcome never pays")
	for field in ["elapsed_seconds","kills","highest_ring","relay_rebuilds"]:
		for value in [-1,INF,NAN,true,"2"]:
			var copy:=summary.duplicate(true);copy[field]=value
			check(not RunRules.reward(copy).ok,"Strict reward field validation")
	for multiplier in [-1.0,INF,NAN,1e308]: check(not RunRules.reward(summary,multiplier).ok,"Reward overflow/invalid multiplier fails")
	var boundary:Dictionary={"outcome":"defeat","elapsed_seconds":59.999,"kills":24,"highest_ring":1,"relay_rebuilds":0}
	check(RunRules.reward(boundary).amount==0,"No premature unit rewards")
	boundary.elapsed_seconds=60;boundary.kills=25
	check(RunRules.reward(boundary).amount==3,"Exact reward unit boundaries")
func _accounting() -> void:
	var tuned:BalanceProfile=base.with_overrides({"pressure":{"spawn_per_second":0},"flak":{"damage":100}}).profile
	var sim:LiveSimulation=LiveSimulation.create(tuned,5).simulation
	var id:=sim.pool.spawn({"position":PolarPosition.new(2,12,0,.5),"hp":1.0,"damage_per_second":0.0,"speed_ring_widths_per_second":1.0})
	var energy:float=sim.state.energy
	check(sim.step(DT).ok and sim.total_kills==1 and not sim.pool.contains(id) and sim.state.energy==energy+tuned.value("economy.kill_energy"),"Committed weapon kill counted once with energy")
	check(sim.step(DT).ok and sim.total_kills==1,"No duplicate tick kill")
	id=sim.pool.spawn({"position":PolarPosition.new(2,12,0,.5),"hp":1.0,"damage_per_second":0.0,"speed_ring_widths_per_second":1.0})
	energy=sim.state.energy
	check(sim.cast_ability(&"focused_flare",PolarPosition.new(1,12,0,.5)).ok and sim.total_kills==2 and sim.state.energy==energy,"Ability kill counted once without energy")
	check(not sim.cast_ability(&"focused_flare",PolarPosition.new(1,12,0,.5)).ok and sim.total_kills==2,"Failed cast preserves totals")
	sim.state.energy=10000
	check(sim.purchase_ring().ok and sim.highest_owned_ring==2,"Highest owned ring tracked on commit")
	sim.state.rings[1].relay_hp=0
	check(sim.rebuild_relay(1).ok and sim.relay_rebuild_count==1,"Relay rebuild tracked")
	check(not sim.rebuild_relay(1).ok and sim.relay_rebuild_count==1,"Failed rebuild not counted")
	var before:=sim.run_summary()
	sim.cooldowns={&"bad":1.0}
	check(not sim.step(DT).ok and sim.run_summary()==before,"Failed tick leaves authoritative summary unchanged")
	before.kills=999
	check(sim.run_summary().kills==2,"Summary is independent")
func _catalogue_validation() -> void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/campaign.json"))
	check(RunRules._valid_catalogue(data),"Editable data validated")
	for bad in [-1,INF,true,"25"]:
		var copy:=data.duplicate(true);copy.unlocks.emp_node.cost=bad
		check(not RunRules._valid_catalogue(copy),"Invalid catalogue cost rejected")
	var copy:=data.duplicate(true);copy.upgrades.core_hp.max_level=4
	check(not RunRules._valid_catalogue(copy),"Uncapped catalogue upgrade rejected")
	copy=data.duplicate(true);copy.mutators.dense_swarm.modifiers[0].factor=INF
	check(not RunRules._valid_catalogue(copy),"Nonfinite modifier rejected")

func _mixed_roster() -> void:
	var overrides:Dictionary={"pressure":{"spawn_per_second":1,"spawn_delay_seconds":0,"max_active_machines":128},"health":{"core_hp":1000000,"wedge_base_hp":1000000},"flak":{"damage":0}}
	for kind in ["tunneler","foundry","transfer","sapper","breacher","assembler"]:
		overrides[kind]={"first_arrival_seconds":DT,"interval_seconds" if kind=="assembler" else "arrival_interval_seconds":15.0}
	overrides.tunneler.burrow_seconds=.1
	var tuned:BalanceProfile=base.with_overrides(overrides).profile
	var made:=RunRules.create_run(tuned,choices(),{},true,5)
	check(made.ok,"Mixed-roster run prepared")
	var sim:LiveSimulation=made.simulation
	sim.state.energy=100000
	check(sim.purchase_ring().ok and sim.purchase_ring().ok,"Explicit mixed fixture owns three rings")
	var before:=sim.state.duplicate(true)
	sim.cooldowns={&"bad":1.0}
	check(not sim.step(DT).ok and sim.pool.active_count()==0 and sim.state==before and sim.elapsed_seconds==0 and sim.total_kills==0 and sim.skipped_assembler_arrivals==0,"All due elite admissions rolled back on downstream error")
	sim.cooldowns={}
	var kinds:Dictionary={}
	var ok:=true
	var peak:=0
	for tick in range(5400):
		var step:=sim.step(DT)
		if not step.ok: ok=false;push_error(str(step.errors));break
		peak=maxi(peak,sim.pool.active_count())
		for target in sim.targets_snapshot(): kinds[String(target.get("kind",&"normal"))]=true
	check(ok and sim.elapsed_seconds==90 and not sim.ended,"Ninety simulated seconds of the complete mixed roster without error")
	check(kinds.size()==7 and peak<=128,"All seven kinds actually admitted under unchanged editable cap")
	check(sim.run_summary().outcome=="practice" and RunRules.reward(sim.run_summary()).amount==0,"Long fixture remains explicitly ineligible practice")
	print("T065 mixed roster: seconds=",sim.elapsed_seconds," kinds=",kinds.keys()," peak=",peak," errors=",not ok)
