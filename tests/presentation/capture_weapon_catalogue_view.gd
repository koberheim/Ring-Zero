extends "res://tests/presentation/test_weapon_catalogue_view.gd"

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered != null and not rendered.is_empty(), "Rendered image exists")
	check(rendered.get_size() == Vector2i(1280, 900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-045-" + name + ".png") == OK, "PNG saved")

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	await process_frame
	funded_fixture({"flak": {"damage": 0}})
	check(view.simulation.purchase_ring().ok, "Capture buys second ring")
	view.sync_simulation()
	for entry in [[&"emp_node", 2], [&"lance_emitter", 3], [&"point_defense", 4]]:
		control_click(catalogue_button(entry[0]))
		slot_click(1, entry[1], 0)
		check(view.state.rings[1].wedges[entry[1]].occupants[0].kind == entry[0], "Captured catalogue placed via actual input")
	await screenshot("weapon-catalogue")
	view.tabs.current_tab = 1
	await process_frame
	control_click(view.armor_button)
	slot_click(2, 2, 0)
	control_click(view.repair_node_button)
	slot_click(2, 4, 0)
	view.simulation.state.rings[1].wedges[3].hp = 40
	view.sync_simulation()
	control_click(view.repair_button)
	hover_slot(1, 3)
	await screenshot("structure-quote")
	print("Weapon catalogue capture checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
