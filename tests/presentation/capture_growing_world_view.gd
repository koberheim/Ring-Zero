extends "res://tests/presentation/test_growing_world_view.gd"

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered.get_size() == Vector2i(1280, 900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-047-" + name + ".png") == OK, "PNG saved")

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	await process_frame
	quiet_main()
	await grow_to_twelve()
	await large_controls()
	view.camera.position = Vector2.ZERO
	view._set_zoom(0.28)
	view.camera.force_update_scroll()
	view.queue_redraw()
	await screenshot("twelve-rings")
	hud_focus(12, 4)
	view._set_zoom(0.8)
	view.camera.force_update_scroll()
	view.queue_redraw()
	await screenshot("outer-ring-focus")
	print("Growing world capture checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
