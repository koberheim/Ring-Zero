extends "res://tests/presentation/test_application.gd"

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://.godot/release-qa/presentation-v2/"+label+".png"
	check(root.get_texture().get_image().save_png(path) == OK,"Capture "+label)

func _run() -> void:
	root.size = Vector2i(2560,1440)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/capture-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/release-qa/presentation-v2"))
	root.add_child(app)
	await process_frame
	await create_timer(0.8).timeout
	check(app.stage.size == Vector2i(2560,1440),"Native 1440p render buffer")
	await capture("release-start")
	var points := {"start":find_button("Start run").get_global_rect().get_center(),"quit":find_button("Quit").get_global_rect().get_center()}
	app.begin_run(false)
	await process_frame
	app.live.set_process(false)
	app.live.sun.material.set_shader_parameter("palette",1)
	app.live.camera.force_update_scroll()
	var build_position := BuildingRules.slot_position(1,3,0,app.live._slot_count(1,3))
	points["build"] = app.stage.get_canvas_transform()*app.live.grid.polar_to_world(build_position)
	await capture("release-opening")
	for palette in [0,2]:
		app.live.sun.material.set_shader_parameter("palette",palette)
		await capture("release-star-"+str(palette))
	app.live.sun.material.set_shader_parameter("palette",1)
	app.live.set_menu_open(true)
	await process_frame
	points["abandon"] = find_button("Abandon run and return",app.live).get_global_rect().get_center()
	await capture("release-pause")
	app.live.set_menu_open(false)
	var helper = load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base := BalanceProfile.load_json("res://data/balance/testing.json")
	var sim: LiveSimulation = helper._fixture(base.profile,6,120)
	helper = null
	app.live.simulation = sim
	app.live.profile = sim.profile
	app.live.sync_simulation()
	app.live._set_zoom(0.85)
	app.live.camera.force_update_scroll()
	await capture("release-fortress")
	app.live.tactical = true
	app.live._set_zoom(1.95)
	app.live.camera.force_update_scroll()
	await capture("release-tactical")
	app.live.tactical = false
	app.live._set_zoom(3.0)
	app.live.camera.force_update_scroll()
	await capture("release-detail")
	app.live.set_menu_open(true)
	app.show_settings("game")
	await capture("release-settings")
	app.show_controls()
	await capture("release-controls")
	app.live.simulation.elapsed_seconds = 900
	app.finish_run("victory")
	await capture("release-victory")
	app.show_records()
	await capture("release-records")
	app.show_credits()
	await capture("release-credits")
	app.show_start()
	root.size = Vector2i(1280,720)
	await capture("release-minimum")
	root.size = Vector2i(1920,1080)
	await capture("release-1080")
	var serializable := {}
	for action in points:
		serializable[action] = {"x":points[action].x,"y":points[action].y}
	var point_file := FileAccess.open("res://.godot/release-qa/presentation-v2/input-points.json",FileAccess.WRITE)
	point_file.store_string(JSON.stringify(serializable,"\t"))
	point_file.close()
	print("Native 1440p package input coordinates: ",JSON.stringify(serializable))
	root.size = Vector2i(2560,1440)
	app.show_settings("start")
	app._change_setting("ui_scale",1.3)
	await capture("release-settings-130")
	app.show_controls()
	await capture("release-controls-130")
	app.show_start()
	await capture("release-start-130")
	app.begin_run(false)
	app.live.set_process(false)
	app.live.sun.material.set_shader_parameter("palette",1)
	await capture("release-opening-130")
	app.live.set_menu_open(true)
	await capture("release-pause-130")
	await app.audio.shutdown()
	app.queue_free()
	paused = false
	await process_frame
	quit(1 if failures else 0)
