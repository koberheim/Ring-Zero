extends "res://tests/presentation/test_tunneler_view.gd"

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered != null and not rendered.is_empty(), "Rendered image exists")
	check(rendered.get_size() == Vector2i(1280, 900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-028-" + name + ".png") == OK, "PNG saved")

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	tunneler_fixture()
	ticks(22)
	check(view.tunneler_warnings.size() == 1 and view.marker_instances.instance_count == 0 and view.triangle_instances.instance_count == 0, "Only warning rendered during burrow")
	var destination: Vector2 = view.tunneler_warnings[0].point
	var flak_point: Vector2 = view.grid.polar_to_world(BuildingRules.slot_position(1, 12, 0, 1))
	check(destination.is_equal_approx(flak_point), "Warning fixture coincides with starter Flak")
	await screenshot("underground-warning")
	button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(950, 700))
	button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(950, 700))
	await screenshot("warning-zoom")
	check(view.tunneler_warnings[0].point == destination, "Camera zoom does not move locked destination")
	check(await_phase(&"surface_attack"), "Original overlapping fixture reaches real emergence")
	await screenshot("surfaced-overlap")
	# Separate scheduled three-ring fixture leaves the emergence marker unobscured.
	tunneler_fixture()
	check(view.simulation.purchase_ring().ok, "Surface capture buys third ring")
	check(await_phase(&"surface_attack"), "Capture reaches actual scheduled emergence")
	await process_frame
	await RenderingServer.frame_post_draw
	var marker: Transform2D = view.triangle_instances.get_instance_transform_2d(0)
	check(marker.origin.is_equal_approx(view.target_grid.polar_to_world(first_tunneler().position)), "Rendered triangle at actual surface position")
	check(is_equal_approx(marker.x.length() * view.camera.zoom.x, 3.0), "Triangle keeps three-pixel screen radius after zoom")
	check(view.tunneler_warnings.is_empty() and view.marker_instances.instance_count == 0, "Surfaced Tunneler has no warning or normal-circle duplicate")
	await screenshot("surfaced-triangle")
	button(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(950, 700))
	button(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(950, 700))
	tunneler_collapse_fixture()
	check(view.state.rings[1].get("collapsed", false) and view.state.rings[2].wedges[3].occupants[1].kind == &"relay", "Actual Tunneler collapse preserves outer Relay")
	check(view.triangle_instances.instance_count == 1 and view.tunneler_warnings.is_empty(), "Post-collapse roaming triangle remains visible")
	await screenshot("inner-collapse")
	print("Tunneler render checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
