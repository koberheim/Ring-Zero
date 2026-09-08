extends SceneTree

var checks := 0
var failures := 0
var view: Node2D
var capture := false

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func button(index: MouseButton, pressed: bool, at := Vector2.ZERO) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = at
	root.push_input(event)

func motion(delta: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = delta
	root.push_input(event)

func click_world(point: Vector2) -> void:
	view.camera.force_update_scroll()
	var screen: Vector2 = root.get_canvas_transform() * point
	button(MOUSE_BUTTON_LEFT, true, screen)
	button(MOUSE_BUTTON_LEFT, false, screen)

func geometry(expected: int) -> void:
	check(view.cell_polygons.size() == expected, "Generated geometry count")
	check(view.cells.size() == expected, "Cell count")
	for index in view.cells.size():
		var cell: Vector2i = view.cells[index]
		var polygon: PackedVector2Array = view.cell_polygons[index]
		var bounds: Vector2 = view.grid.ring_bounds(cell.x)
		check(polygon.size() == (144 if cell.x == 0 else 26), "Arc sampling count")
		check(Geometry2D.is_point_in_polygon(view.grid.polar_to_world(view.grid.cell_center(cell)), polygon), "Center inside polygon")
		for vertex in polygon:
			check(absf(vertex.length() - bounds.x) < 0.002 or absf(vertex.length() - bounds.y) < 0.002, "Vertices follow API radii")

func screenshot(name: String) -> void:
	if not capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var texture := root.get_texture()
	var image := texture.get_image()
	check(image != null and not image.is_empty(), "Rendered image exists")
	if image != null and not image.is_empty():
		check(image.save_png("res://docs/reviews/artifacts/" + name + ".png") == OK, "PNG saved")

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/grid_inspection.tscn").instantiate()
	root.add_child(view)
	await process_frame
	geometry(37)
	check(view.camera.position == Vector2.ZERO, "Initially centered")
	await screenshot("T-004-three-bands")
	click_world(Vector2.ZERO)
	check(view.selected_cell == Vector2i.ZERO, "Core input selection")
	check(view.status_label.text.begins_with("Selected core"), "Core status")
	for wedge in [12, 3, 6, 9]:
		click_world(view.grid.polar_to_world(view.grid.cell_center(Vector2i(2, wedge))))
		check(view.selected_cell == Vector2i(2, wedge), "Bearing input selection")
	click_world(Vector2(500, 0))
	check(view.selected_cell == Vector2i(-1, -1), "Outside clears")
	var previous_zoom: Vector2 = view.camera.zoom
	var previous_center: Vector2 = view.camera.position
	button(MOUSE_BUTTON_WHEEL_UP, true)
	check(view.camera.zoom.is_equal_approx(previous_zoom * 1.1), "Wheel up factor")
	button(MOUSE_BUTTON_WHEEL_DOWN, true)
	check(view.camera.zoom.is_equal_approx(previous_zoom), "Wheel inverse pair")
	check(view.camera.position == previous_center, "Zoom center fixed")
	button(MOUSE_BUTTON_MIDDLE, true)
	motion(Vector2(80, -40))
	check(view.camera.position.is_equal_approx(previous_center - Vector2(80, -40) / previous_zoom), "Screen delta pan")
	check(view.selected_cell == Vector2i(-1, -1), "Drag does not select")
	button(MOUSE_BUTTON_MIDDLE, false)
	var panned_center: Vector2 = view.camera.position
	motion(Vector2(100, 100))
	check(view.camera.position == panned_center and not view.dragging, "Release ends drag")
	button(MOUSE_BUTTON_WHEEL_UP, true)
	button(MOUSE_BUTTON_WHEEL_UP, true)
	click_world(view.grid.polar_to_world(view.grid.cell_center(Vector2i(2, 3))))
	check(view.selected_cell == Vector2i(2, 3), "Selection after pan and zoom")
	check(view.camera.rotation == 0, "North up")
	await screenshot("T-004-panned-selected")
	root.size = Vector2i(1100, 800)
	await process_frame
	check(view.camera.position == panned_center, "Resize preserves navigation")
	click_world(view.grid.polar_to_world(view.grid.cell_center(Vector2i(1, 12))))
	check(view.selected_cell == Vector2i(1, 12), "Selection after resize")
	root.size = Vector2i(1280, 900)
	await process_frame
	view.rebuild_grid(12)
	geometry(145)
	check(view.selected_cell == Vector2i(-1, -1), "Rebuild resets selection")
	check(view.camera.position == Vector2.ZERO, "Rebuild fits and centers")
	check(is_equal_approx(view.camera.zoom.x * view.grid.ring_bounds(12).y, 900.0 * 0.42), "Twelve-band fit")
	await screenshot("T-004-twelve-bands")
	for wedge in [12, 1]:
		click_world(view.grid.polar_to_world(view.grid.cell_center(Vector2i(12, wedge))))
		check(view.selected_cell == Vector2i(12, wedge), "Ring twelve input selection")
		check(view.status_label.text.begins_with("Selected ring 12 / wedge %d" % wedge), "Ring twelve selection status")
	view.rebuild_grid(3)
	geometry(37)
	view.rebuild_grid(0)
	geometry(1)
	view.rebuild_grid(100)
	check(view.cell_polygons.size() == 1201, "No twelve-band ceiling")
	view._set_zoom(0.0)
	check(view.camera.zoom.x > 0.0 and is_finite(view.camera.zoom.x), "Zero zoom protection")
	view._set_zoom(INF)
	check(view.camera.zoom.x > 0.0 and is_finite(view.camera.zoom.x), "Nonfinite zoom protection")
	print("Presentation checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
