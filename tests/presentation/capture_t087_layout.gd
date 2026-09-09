extends "res://tests/presentation/test_application.gd"
var output_dir := "res://docs/reviews/presentation-v3/T-087/before"
var records: Array = []
var phase := "before"
var scale_value := 1.0

func _initialize() -> void:
	create_timer(240.0).timeout.connect(func(): push_error("T087 capture deadline"); quit(1))
	call_deferred("_run")

func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var filename := "%s-%dx%d-%d.png" % [label,root.size.x,root.size.y,roundi(scale_value*100)]
	check(root.get_texture().get_image().save_png(output_dir.path_join(filename)) == OK,"Capture "+filename)
	var row := {"file":filename,"root":[root.size.x,root.size.y],"stage":[app.stage.size.x,app.stage.size.y],"ui_scale":scale_value,"diagnostic":true,"palette":1,"tick":0,"actors":0,"zoom":null,"camera":null}
	if app.live != null:
		row.tick = app.live.simulation._ticks
		row.actors = app.live.simulation.pool.active_count()
		row.zoom = [app.live.camera.zoom.x,app.live.camera.zoom.y]
		row.camera = [app.live.camera.position.x,app.live.camera.position.y]
		row["albedo"] = [app.live.board_viewport.size.x,app.live.board_viewport.size.y]
		row["material"] = [app.live.material_viewport.size.x,app.live.material_viewport.size.y]
	records.append(row)

func fixture(rings: int) -> void:
	var helper = load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base := BalanceProfile.load_json("res://data/balance/testing.json")
	app.live.simulation = helper._fixture(base.profile,rings,120)
	app.live.profile = app.live.simulation.profile
	app.live.sync_simulation()
	app.live._set_zoom(0.85 if rings == 6 else 0.41)
	app.live.camera.force_update_scroll()
	app.live._refresh_board_cache()
	app.live.queue_redraw()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--after": phase = "after"
		if argument.begins_with("--evidence-dir="): output_dir = argument.trim_prefix("--evidence-dir=")
	if phase == "after" and output_dir.ends_with("before"): output_dir = output_dir.trim_suffix("before")+"after"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/t087-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	app.set_process(false)
	for resolution in ([Vector2i(1920,1080)] if "--quick" in OS.get_cmdline_user_args() else [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]):
		root.size = resolution
		await create_timer(0.1).timeout
		for text_scale in ([1.0] if "--quick" in OS.get_cmdline_user_args() else [1.0,1.3]):
			scale_value = text_scale
			app.progress.settings.ui_scale = scale_value
			app._apply_settings()
			app.show_start()
			await shot("start")
			app.show_settings("start")
			await shot("settings")
			app.show_controls()
			await shot("controls")
			app.begin_run(false)
			app.live.set_process(false)
			await shot("opening")
			for palette in [0,2]:
				app.live.sun.material.set_shader_parameter("palette",palette)
				app.live.update_core_lighting(palette,1.0)
				await shot("opening-palette-%d" % palette)
			app.live.sun.material.set_shader_parameter("palette",1)
			app.live.update_core_lighting(1,1.0)
			app.live.set_menu_open(true)
			await shot("pause")
			app.live.set_menu_open(false)
			fixture(6)
			await shot("six-ring")
			fixture(12)
			await shot("twelve-ring")
			app.live.tactical = true
			app.live._refresh_board_cache()
			app.live.queue_redraw()
			await shot("tactical")
			app.live.simulation.elapsed_seconds = 900.0
			app.finish_run("victory")
			await shot("victory-diagnostic")
			app.show_start()
			app.begin_run(false)
			app.live.set_process(false)
			app.finish_run("defeat")
			await shot("defeat-diagnostic")
	var file := FileAccess.open(output_dir.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase":phase,"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"checks":checks,"failures":failures,"captures":records},"\t"))
	file.close()
	print("T087 ",phase,": ",checks," captures, ",failures," failures")
	await app.audio.shutdown()
	app.queue_free()
	paused = false
	await process_frame
	quit(1 if failures else 0)
