extends "res://tests/presentation/test_hotkeys_compact_ui.gd"

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered.get_size() == root.size, "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-053-"+name+".png") == OK, "PNG saved")

func _run() -> void:
	for scene in ["live_view","art_preview"]:
		root.size = Vector2i(1280,900)
		view = load("res://scenes/%s.tscn" % scene).instantiate()
		root.add_child(view)
		view.set_process(false)
		await process_frame
		await process_frame
		await screenshot(scene+"-startup")
		key(KEY_TAB)
		await screenshot(scene+"-hidden")
		key(KEY_F1)
		await screenshot(scene+"-help")
		key(KEY_ESCAPE)
		key(KEY_TAB)
		root.size = Vector2i(1024,768)
		await process_frame
		await process_frame
		reset_fixture()
		key(KEY_Q)
		slot_click(2,3,0)
		await screenshot(scene+"-1024-structure-active")
		view.state.rings[1].wedges[3].hp = 40
		key(KEY_T)
		hover_slot(1,3)
		await screenshot(scene+"-1024-repair-quote")
		if scene == "art_preview":
			key(KEY_F2)
			view.set_treatment(1)
			await screenshot(scene+"-1024-art-drawer")
		view.queue_free()
		await process_frame
	print("Hotkey UI capture checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
