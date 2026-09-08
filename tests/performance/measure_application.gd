extends "res://tests/presentation/test_application.gd"

func _initialize() -> void:
	create_timer(50.0).timeout.connect(func(): push_error("Rendered probe deadline"); quit(1))
	call_deferred("_run")

func stats(values: Array) -> Dictionary:
	var ordered := values.duplicate()
	ordered.sort()
	return {"median":(ordered[59]+ordered[60])/2.0,"p90":ordered[107],"max":ordered[-1]}

func _run() -> void:
	root.size = Vector2i(1440,810)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/t067-profiles/measure-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	await click_control(find_button("Start run"))
	var helper = load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base := BalanceProfile.load_json("res://data/balance/testing.json")
	var sim: LiveSimulation = helper._fixture(base.profile,12,1000)
	check(sim != null,"Mixed fixture valid")
	app.live.simulation = sim
	app.live.profile = sim.profile
	app.live.clock = FixedStepClock.new(60.0,app.live._simulation_tick)
	var effects: bool = "--effects-on" in OS.get_cmdline_user_args()
	app.live.apply_interface_settings({"ui_scale":1.0,"effects":effects,"reduced_motion":false,"fullscreen":false})
	app.live.sync_simulation()
	app.live._set_zoom(0.23)
	app.live.camera.force_update_scroll()
	print("Rendered fixture started effects=",effects," vsync=",DisplayServer.window_get_vsync_mode()," initial=",JSON.stringify(helper._counts(sim)))
	var began := Time.get_ticks_usec()
	while Time.get_ticks_usec()-began < 3000000:
		await process_frame
		if not app.live.last_error.is_empty():
			push_error(app.live.last_error)
			quit(1)
			return
	var frame_ms: Array = []
	var sim_ms: Array = []
	var sync_ms: Array = []
	var draw_ms: Array = []
	var ticks: Array = []
	var simulated_start := sim.elapsed_seconds
	var wall_start := Time.get_ticks_usec()
	var last := wall_start
	var max_effects := 0
	for sample in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		frame_ms.append((now-last)/1000.0)
		last = now
		sim_ms.append(app.live.simulation_cpu_usec/1000.0)
		sync_ms.append(app.live.sync_cpu_usec/1000.0)
		draw_ms.append(app.live.draw_cpu_usec/1000.0)
		ticks.append(app.live.simulation_ticks_per_frame)
		max_effects = maxi(max_effects,app.live.hit_effects.size())
		if sample % 20 == 0: print("Measured sample=",sample," wall_ms=",frame_ms[-1]," ticks=",ticks[-1])
		if sim.pool.active_count() != 1000 or not app.live.last_error.is_empty() or now-began > 45000000:
			print("Bounded probe failure sample=",sample," active=",sim.pool.active_count()," error=",app.live.last_error)
			quit(1)
			return
	var wall_seconds := (Time.get_ticks_usec()-wall_start)/1e6
	print(JSON.stringify({"effects":effects,"frames":stats(frame_ms),"simulation_callback_ms":stats(sim_ms),"sync_ms":stats(sync_ms),"draw_submission_ms":stats(draw_ms),"ticks_per_frame":stats(ticks),"wall_seconds":wall_seconds,"simulated_seconds":sim.elapsed_seconds-simulated_start,"simulation_wall_ratio":(sim.elapsed_seconds-simulated_start)/wall_seconds,"max_live_effects":max_effects,"final":helper._counts(sim),"raw_frame_ms":frame_ms}))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/reviews/artifacts/T-071-crowd-%s.png" % ("effects" if effects else "no-effects"))
	quit(0)
