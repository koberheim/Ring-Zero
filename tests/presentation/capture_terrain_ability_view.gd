extends "res://tests/presentation/test_terrain_ability_view.gd"

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered.get_size() == Vector2i(1280,900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-051-"+name+".png") == OK, "PNG saved")

func _run() -> void:
	root.size = Vector2i(1280,900)
	for scene in ["live_view","art_preview"]:
		view = load("res://scenes/%s.tscn" % scene).instantiate()
		root.add_child(view)
		view.set_process(false)
		await process_frame
		await process_frame
		funded_fixture()
		check(view.simulation.purchase_ring().ok, "Capture purchases second ring")
		view.sync_simulation()
		view.tabs.current_tab = 2
		await process_frame
		for entry in [[view.debris_field_button,2],[view.tractor_lane_button,3],[view.occlusion_screen_button,4]]:
			control_click(entry[0])
			slot_click(2,entry[1],0)
		if scene == "art_preview":
			view.set_treatment(1)
		await screenshot(scene+"-terrain")
		control_click(view.emp_burst_button)
		aim_world(Vector2(250,100))
		await screenshot(scene+"-emp-aim")
		control_click(view.focused_flare_button)
		aim_world(Vector2(220,-80))
		await screenshot(scene+"-flare-aim")
		view.queue_free()
		await process_frame
	print("Terrain/ability capture checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
