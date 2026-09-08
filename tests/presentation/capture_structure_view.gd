extends "res://tests/presentation/test_structure_view.gd"
## Isolated capture for the Phase 7 Structure tab (Armor/Repair Node/Repair/Reclaim); never attached to the playable scene.

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered != null and not rendered.is_empty(), "Rendered image exists")
	check(rendered.get_size() == Vector2i(1280, 900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-038-" + name + ".png") == OK, "PNG saved")

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	view.tabs.current_tab = 1
	await process_frame
	fixture()
	view.simulation.state.energy = 10000
	view.simulation.state.rings[1].wedges[9].hp = 40.0
	view.sync_simulation()
	await screenshot("structure-tab")
	print("Structure view capture checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
