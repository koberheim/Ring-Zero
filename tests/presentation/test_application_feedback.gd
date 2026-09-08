extends "res://tests/presentation/test_application.gd"
func _run() -> void:
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/t067-profiles/feedback-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	await click_control(find_button("Start run"))
	app.live.set_process(false)
	var helper = load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base := BalanceProfile.load_json("res://data/balance/testing.json")
	app.live.simulation = helper._fixture(base.profile,12,7)
	app.live.profile = app.live.simulation.profile
	app.live.clock = FixedStepClock.new(60.0,app.live._simulation_tick)
	app.live.sync_simulation()
	check(app.live.rendered_targets.size() == 7 and app.live.elite_points.size() == 5,"Seven kinds preserve all markers with five elite shapes")
	check(app.live.seen_elites.size() == 5,"Encounter notices bounded by kind rather than lifetime IDs")
	for kind in ["Standard machine","Foundry","Transfer","Sapper","Breacher","Tunneler","Assembler"]:
		check(app.reference_text().contains(kind),"Reference contains counter for "+kind)
	for tick in 60:
		app.live._process(1.0/60.0)
		if not app.live.hit_effects.is_empty(): break
	check(app.live.last_error.is_empty() and not app.live.hit_effects.is_empty(),"Committed mixed-encounter weapon hits produce cosmetic feedback")
	app.live.set_menu_open(true)
	var effects: Array = app.live.hit_effects.duplicate(true)
	app.live._process(1.0)
	check(app.live.hit_effects == effects,"Pause freezes cosmetic traces")
	app.live.set_menu_open(false)
	app.live.simulation.ended = true
	app.live._process(0.3)
	check(app.live.hit_effects.is_empty(),"Final trace expires even when no future simulation tick redraws")
	app.live.apply_interface_settings({"effects":false,"reduced_motion":true,"ui_scale":1.0,"fullscreen":false})
	check(app.live.hit_effects.is_empty(),"Disabling feedback clears pending traces")
	print("Application feedback checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
