extends "res://tests/presentation/test_application.gd"

func _run() -> void:
	root.size = Vector2i(1440,810)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/perf-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	app.begin_run(false)
	var helper = load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base := BalanceProfile.load_json("res://data/balance/release.json")
	var sim: LiveSimulation = helper._fixture(base.profile,12,128)
	helper = null
	app.live.simulation = sim
	app.live.profile = sim.profile
	app.live.clock = FixedStepClock.new(60,app.live._simulation_tick)
	app.live.sync_simulation()
	app.live._set_zoom(0.23)
	app.live.camera.force_update_scroll()
	for frame in 60: await process_frame
	var frames: Array[float] = []
	var start := Time.get_ticks_usec()
	var last := start
	var simulated_start := sim.elapsed_seconds
	var worst_sim := 0.0
	var sync_ms: Array[float] = []
	var draw_ms: Array[float] = []
	var quote_ms: Array[float] = []
	for frame in 180:
		await process_frame
		var now := Time.get_ticks_usec()
		frames.append((now-last)/1000.0)
		last = now
		worst_sim = maxf(worst_sim,app.live.simulation_cpu_usec/1000.0)
		sync_ms.append(app.live.sync_cpu_usec/1000.0)
		draw_ms.append(app.live.draw_cpu_usec/1000.0)
		quote_ms.append(app.live.quote_cpu_usec/1000.0)
		check(app.live.last_error.is_empty() and sim.pool.active_count() == 128,"Cap fixture stays valid")
	frames.sort()
	sync_ms.sort()
	draw_ms.sort()
	quote_ms.sort()
	var elapsed := (Time.get_ticks_usec()-start)/1e6
	print(JSON.stringify({"actors":128,"rings":12,"effects":true,"frames":180,"median_frame_ms":frames[90],"p95_frame_ms":frames[171],"max_frame_ms":frames[-1],"median_sync_ms":sync_ms[90],"median_draw_ms":draw_ms[90],"median_quote_ms":quote_ms[90],"max_simulation_callback_ms":worst_sim,"simulation_wall_ratio":(sim.elapsed_seconds-simulated_start)/elapsed}))
	app.queue_free()
	paused = false
	await process_frame
	quit(1 if failures else 0)
