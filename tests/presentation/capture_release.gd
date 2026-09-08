extends "res://tests/presentation/test_application.gd"

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://.godot/release-qa/"+label+".png"
	check(root.get_texture().get_image().save_png(path) == OK,"Capture "+label)

func _run() -> void:
	root.size = Vector2i(1440,810)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/capture-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/release-qa"))
	root.add_child(app)
	await process_frame
	await capture("release-start")
	app.begin_run(false)
	await process_frame
	app.live.set_process(false)
	await capture("release-opening")
	var helper = load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base := BalanceProfile.load_json("res://data/balance/testing.json")
	var sim: LiveSimulation = helper._fixture(base.profile,6,120)
	helper = null
	app.live.simulation = sim
	app.live.profile = sim.profile
	app.live.sync_simulation()
	app.live._set_zoom(0.48)
	app.live.camera.force_update_scroll()
	await capture("release-fortress")
	app.live.tactical = true
	app.live._set_zoom(1.1)
	await capture("release-tactical")
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
	print("Final menu Start=",find_button("Start run").get_global_rect().get_center()," Quit=",find_button("Quit").get_global_rect().get_center())
	app.queue_free()
	paused = false
	await process_frame
	quit(1 if failures else 0)
