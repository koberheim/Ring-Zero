extends "res://tests/presentation/test_application.gd"
func _run() -> void:
	seed(81081)
	root.size = Vector2i(2560,1440)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/t081-motion-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	var output := "res://docs/reviews/presentation-v3/T-081/motion/"+RenderingServer.get_current_rendering_method()+"/"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="): output = argument.trim_prefix("--evidence-dir=").trim_suffix("/")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.add_child(app)
	await process_frame
	app.begin_run(false)
	app.live.set_process(false)
	var helper = load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base := BalanceProfile.load_json("res://data/balance/testing.json")
	app.live.simulation = helper._fixture(base.profile,6,120)
	helper = null
	app.live.profile = app.live.simulation.profile
	app.live.sync_simulation()
	app.live.sun.material.set_shader_parameter("palette",1)
	app.live.update_core_lighting(1,1)
	app.live._set_zoom(0.85)
	var timeline := []
	var start := Time.get_ticks_usec()
	for index in 24:
		var mode := "pan" if index<8 else ("alt" if index<16 else "pan-alt")
		app.live.tactical = index>=8
		if index<8 or index>=16: app.live.camera.position.x += 12.0
		app.live.camera.force_update_scroll()
		app.live._refresh_board_cache()
		app.live.queue_redraw()
		await create_timer(1.0/12.0).timeout
		await RenderingServer.frame_post_draw
		var file := "frame-%03d.png" % index
		check(root.get_texture().get_image().save_png(output+file)==OK,"Motion frame saved")
		timeline.append({"file":file,"time_seconds":(Time.get_ticks_usec()-start)/1e6,"mode":mode,"camera":str(app.live.camera.position),"simulation_seconds":app.live.simulation.elapsed_seconds,"actors":120,"board_redraws":app.live.board_redraw_count,"material_redraws":app.live.material_redraw_count})
	var record := FileAccess.open(output+"timestamps.json",FileAccess.WRITE)
	record.store_string(JSON.stringify(timeline,"\t"))
	record.close()
	await app.audio.shutdown()
	app.queue_free()
	paused=false
	await process_frame
	print("T081 native motion checks: ",checks," failures: ",failures)
	quit(1 if failures else 0)
