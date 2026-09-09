extends "res://tests/presentation/test_application.gd"
## Diagnostic ablations keep simulation, resolution and fixture identical.
func _run() -> void:
	root.size=Vector2i(2560,1440)
	app=load("res://scenes/application.tscn").instantiate()
	app.profile_path="res://.godot/release-profiles/layers-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	app.begin_run(false)
	var helper=load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base:=BalanceProfile.load_json("res://data/balance/release.json")
	var sim: LiveSimulation=helper._fixture(base.profile,12,128)
	helper=null
	app.live.simulation=sim
	app.live.profile=sim.profile
	app.live.clock=FixedStepClock.new(60,app.live._simulation_tick)
	app.live.sync_simulation()
	app.live._set_zoom(0.41)
	app.live.camera.force_update_scroll()
	for mode in ["all","pan","tactical","pan_tactical","no_board","no_space","no_sun","no_hud","no_world"]:
		app.live.tactical=mode in ["tactical","pan_tactical"]
		app.live.board_sprite.visible=mode not in ["no_board","no_world"]
		app.live.space.visible=mode not in ["no_space","no_world"]
		app.live.sun.visible=mode not in ["no_sun","no_world"]
		for node in app.live.get_children():
			if node is CanvasLayer and node.layer>=0: node.visible=mode!="no_hud"
		for frame in 20: await process_frame
		var frames: Array[float]=[]
		var calls: Array[float]=[]
		var prior:=Time.get_ticks_usec()
		var redraws: int=app.live.board_redraw_count
		for frame in 90:
			if mode in ["pan","pan_tactical"]:
				app.live.camera.position.x+=4.0/app.live.camera.zoom.x
				app.live.camera.force_update_scroll()
			await process_frame
			var now:=Time.get_ticks_usec()
			frames.append((now-prior)/1000.0)
			prior=now
			calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		frames.sort()
		calls.sort()
		print(JSON.stringify({"mode":mode,"median_ms":frames[45],"p95_ms":frames[85],"draw_calls":calls[45],"board_redraws":app.live.board_redraw_count-redraws}))
	await app.audio.shutdown()
	app.queue_free()
	paused=false
	await process_frame
	quit()
