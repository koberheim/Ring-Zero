extends "res://tests/presentation/test_application.gd"

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == root.size,"Native capture dimensions")
	check(image.save_png("res://docs/reviews/artifacts/T-067-"+name+".png") == OK,"Application PNG saved")

func _run() -> void:
	root.size = Vector2i(1280,720)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/t067-profiles/capture-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	await process_frame
	print("Capture stage=",app.stage.size," update=",app.stage.render_target_update_mode," frame=",app.frame.get_global_rect()," visible=",app.frame.is_visible_in_tree()," page=",app.page.get_global_rect())
	await RenderingServer.frame_post_draw
	app.stage.get_texture().get_image().save_png("res://.godot/t067-stage.png")
	await capture("start-1280")
	await click_control(find_button("Start run"))
	app.live.set_process(false)
	await capture("hud-1280")
	app.live.selected_cell = Vector2i(1,3)
	app.live.selected_slot = 0
	app.live.state.rings[1].relay_hp = 0
	app.live.refresh_view()
	await capture("relay-1280")
	key(KEY_G)
	await capture("structure-relay-1280")
	app.live.set_menu_open(true)
	app.show_settings("game")
	await capture("settings-1280")
	app._change_setting("ui_scale",1.3)
	await capture("settings-130-1280")
	app.close_settings()
	app.live.set_menu_open(false)
	await capture("hud-130-1280")
	app.live.simulation.elapsed_seconds = 300
	app.live.simulation.total_kills = 250
	app.live.simulation.ended = true
	await process_frame
	await capture("results-130-1280")
	await click_control(find_button("Return to start"))
	await capture("start-130-1280")
	await click_control(find_button("Shop"))
	await capture("shop-130-1280")
	await click_control(find_button("Starting reserve  25 credits"))
	await capture("shop-upgrades-130-1280")
	app._change_setting("ui_scale",1.0)
	app.show_start()
	root.size = Vector2i(1920,1080)
	await process_frame
	await capture("start-1920")
	app.show_reference()
	await capture("reference-1920")
	app.show_start()
	await click_control(find_button("Tutorial"))
	app.live.set_process(false)
	await capture("tutorial-1920")
	root.size = Vector2i(1280,720)
	await process_frame
	await capture("tutorial-1280")
	app.live.set_menu_open(true)
	app.show_settings("game")
	await click_control(find_button("Fullscreen"))
	check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,"Native fullscreen applied")
	await capture("fullscreen-settings")
	await click_control(find_button("Fullscreen"))
	app.show_start()
	root.size = Vector2i(1440,810)
	await process_frame
	await capture("start-1440")
	root.size = Vector2i(1600,1000)
	await process_frame
	await capture("letterbox-1600")
	print("Application capture checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
