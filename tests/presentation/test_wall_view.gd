extends "res://tests/presentation/test_live_view.gd"

func wall_fixture(gap: int = 12) -> void:
	fixture({"flak": {"damage": 0}, "health": {"wedge_base_hp": 100000, "standard_machine_hp": 100000}})
	view.simulation.state.energy = 100000
	for wedge in range(1, 13):
		if wedge != gap:
			check(view.simulation.place_wall(1, wedge).ok, "Fixture wall placement")
	view.sync_simulation()

func wall_health(ring: int = 1) -> Dictionary:
	var result := {}
	for wedge in view.state.rings[ring].wedges:
		var record: Dictionary = view.state.rings[ring].wedges[wedge]
		if record.has("wall"):
			result[wedge] = record.wall.hp
	return result

func wall_collapse_fixture() -> void:
	fixture()
	view.simulation.state.energy = 100000
	check(view.simulation.purchase_ring().ok, "Collapse fixture outer ring")
	for wedge in [8, 9, 10, 11, 12]:
		check(view.simulation.place_wall(1, wedge).ok, "Collapse fixture inner wall")
	check(view.simulation.place_wall(2, 3).ok, "Collapse fixture outer wall beside Relay")
	check(view.simulation.place_wall(2, 4).ok, "Collapse fixture second outer wall")
	for wedge in range(1, 7):
		view.simulation.state.rings[1].wedges[wedge].hp = 0
	view.simulation.state.rings[1].wedges[7].hp = 0.01
	view.simulation.state.rings[2].wedges[7].hp = 0
	spawn_at(2, 7, 0.0, 1000, 6)
	ticks(1)

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	view.tabs.current_tab = 1
	await process_frame
	check(view.wall_button.text == "[W] Wall %s 5" % String.chr(8212), "Wall price from profile")
	var before_state: Dictionary = view.state.duplicate(true)
	control_click(view.wall_button)
	check(view.build_mode == &"wall" and view.state == before_state, "Actual Wall button arms without spending")
	slot_click(1, 12, 0)
	check(view.simulation.state.energy == 195 and view.build_mode == &"wall", "Wall wedge click spends once and retains mode")
	check(view.state.rings[1].wedges[12].wall.hp == 50 and view.state.rings[1].wedges[12].occupants == before_state.rings[1].wedges[12].occupants, "Wall independent of occupied Flak slot")
	check(view.wall_edges.has(Vector2i(1, 12)) and view.wall_edges[Vector2i(1, 12)].size() == 13, "Outer arc line present")
	check(view.status_label.text.contains("Wall HP: 50"), "Selected Wall HP visible")
	for point in view.wall_edges[Vector2i(1, 12)]:
		check(is_equal_approx(point.length(), 192), "Wall vertices lie on outer radius only")
	control_click(view.wall_button)
	before_state = view.state.duplicate(true)
	slot_click(1, 12, 0)
	check(view.state == before_state and view.build_mode == &"wall", "Duplicate rejection retains mode and funds")
	slot_click(2, 3, 0)
	check(view.state == before_state, "Unowned wall rejected")
	view.simulation.state.rings[1].wedges[3].hp = 0
	view.sync_simulation()
	before_state = view.state.duplicate(true)
	slot_click(1, 3, 0)
	check(view.state == before_state, "Broken support rejected")
	view.simulation.state.energy = 4
	view.sync_simulation()
	before_state = view.state.duplicate(true)
	slot_click(1, 4, 0)
	check(view.state == before_state and view.feedback_label.text.contains("Not enough"), "Insufficient wall funds isolated")
	var selected_before: Vector2i = view.selected_cell
	click(view.ui_panel.get_global_rect().position + Vector2(1,1))
	check(view.state == before_state and view.selected_cell == selected_before, "Wall mode panel clickthrough blocked")
	button(MOUSE_BUTTON_RIGHT, true, view.wall_button.get_global_rect().get_center())
	button(MOUSE_BUTTON_RIGHT, false, view.wall_button.get_global_rect().get_center())
	check(view.build_mode == &"" and view.state == before_state, "Wall mode right cancel over UI")
	button(MOUSE_BUTTON_MIDDLE, true, Vector2(950, 700))
	button(MOUSE_BUTTON_MIDDLE, false, view.wall_button.get_global_rect().get_center())
	check(not view.dragging, "Wall UI middle release")
	view.simulation.state.rings[1].wedges[12].hp = 0
	view.sync_simulation()
	check(not view.wall_edges.has(Vector2i(1, 12)), "Broken support removes blocking line")
	wall_fixture(12)
	spawn_at(2, 3, 0, 100000, 8)
	ticks(1)
	if view.rendered_targets.is_empty():
		check(false, "Open-gap fixture did not render target: " + view.last_error)
		quit(1)
		return
	var initial_walls := wall_health()
	var first_position: PolarPosition = view.rendered_targets[0].position
	var first_point: Vector2 = view.target_points[0]
	ticks(1)
	var second_position: PolarPosition = view.rendered_targets[0].position
	check(not is_equal_approx(first_position.angular_fraction, second_position.angular_fraction), "Open gap produces continuous angular detour")
	check(not first_point.is_equal_approx(view.target_points[0]) and view.target_points[0].is_equal_approx(view.target_grid.polar_to_world(second_position)), "Marker cache follows angular motion without snapping")
	ticks(30)
	check(wall_health() == initial_walls and view.wall_edges.size() == 11, "Reachable opening causes no wall damage")
	control_click(view.menu_button)
	var frozen_targets := target_values()
	var frozen_elapsed: float = view.simulation.elapsed_seconds
	view._process(2.0)
	control_click(view.wall_button)
	slot_click(1, 12, 0)
	check(view.wall_button.disabled and target_values() == frozen_targets and view.simulation.elapsed_seconds == frozen_elapsed and wall_health() == initial_walls, "Menu freezes movement and prevents wall purchase")
	control_click(view.resume_button)
	ticks(1)
	check(not paused and target_values() != frozen_targets, "Resume continues detour")
	wall_fixture(0)
	spawn_at(2, 3, 0, 100000, 8)
	var wedge_hp: float = view.state.rings[1].wedges[3].hp
	ticks(1)
	check(is_equal_approx(view.state.rings[1].wedges[3].wall.hp, 50.0 - 8.0 * 0.25 / 60.0), "Sealed region permits quarter-DPS wall damage")
	check(view.state.rings[1].wedges[3].hp == wedge_hp, "Sealed wall protects supporting wedge")
	view.simulation.state.rings[1].wedges[3].wall.hp = 0.01
	ticks(1)
	check(not view.state.rings[1].wedges[3].has("wall") and not view.wall_edges.has(Vector2i(1, 3)), "Wall destruction removes line")
	check(view.feedback_label.text.contains("Wall") and view.feedback_label.text.contains("broken"), "Wall break feedback")
	var later_id := spawn_at(2, 4, 0, 100000, 8)
	var before_angle := 0.5
	ticks(1)
	check(not is_equal_approx(view.simulation.pool.payload_for(later_id).position.angular_fraction, before_angle), "Later machine redirects toward wall breach")
	wall_collapse_fixture()
	check(view.state.rings[1].collapsed and view.feedback_label.text.contains("collapsed"), "Collapse feedback has priority")
	check(view.wall_edges.size() == 2 and view.wall_edges.has(Vector2i(2, 3)) and view.wall_edges.has(Vector2i(2, 4)), "Collapse removes inner lines and preserves outer walls")
	check(view.state.rings[2].relay == {"active": true}, "Surviving outer Relay unaffected")
	loss_fixture()
	check(view.wall_button.disabled, "Core loss disables Wall control")
	before_state = view.state.duplicate(true)
	view.wall_button.pressed.emit()
	slot_click(1, 3, 0)
	check(view.build_mode == &"" and view.state == before_state, "Loss prevents wall purchase")
	fixture()
	view.simulation.state.energy = -1
	ticks(1)
	check(view.wall_button.disabled and not view.last_error.is_empty(), "Runtime error disables Wall control")
	print("Wall view checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
