extends "res://tests/presentation/test_growing_world_view.gd"

func select_option(control: Button, index: int) -> void:
	for attempt in 3:
		var current: int = view.treatment if control == view.treatment_selector else view.sun_palette
		if current == index:
			break
		control_click(control)
		await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/art_preview.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	await process_frame
	control_click(view.art_toggle)
	await process_frame
	quiet_main()
	var actor := spawn_at(2, 12, 0.0)
	ticks(1)
	view.simulation.pool.release(actor)
	view.sync_simulation()
	check(not view.simulation.cooldowns.is_empty(), "Comparison fixture has an authentic weapon cooldown")
	var cooldowns: Dictionary = view.simulation.cooldowns.duplicate(true)
	var state_before: Dictionary = view.state.duplicate(true)
	var elapsed: float = view.simulation.elapsed_seconds
	var selection: Vector2i = view.selected_cell
	await select_option(view.treatment_selector, 1)
	check(view.treatment == 1, "Actual treatment selector chooses painterly")
	for palette in range(3):
		await select_option(view.sun_selector, palette)
		check(view.sun_palette == palette and view.sun_material.get_shader_parameter("palette") == palette, "Actual sun selector applies palette %d" % palette)
	control_click(view.motion_toggle)
	check(not view.sun_motion and view.state == state_before and view.simulation.elapsed_seconds == elapsed and view.selected_cell == selection and view.simulation.cooldowns == cooldowns, "Presentation controls preserve gameplay state time cooldowns and selection")
	var phase: float = view.sun_phase
	view._process(0.1)
	check(view.sun_phase == phase, "Sun motion off freezes its explicit shader clock")
	control_click(view.motion_toggle)
	view._process(0.1)
	check(view.sun_phase > phase, "Sun motion on advances its explicit shader clock")
	var children := view.get_child_count()
	for index in 20:
		spawn_at(4, 3, 0.8)
	view.sync_simulation()
	check(view.get_child_count() == children and view.marker_instances.instance_count == 20, "Preview keeps batched machines without per-enemy nodes")
	for id in view.simulation.pool.active_ids():
		view.simulation.pool.release(id)
	view.sync_simulation()
	control_click(view.emp_node_button)
	slot_click(1, 3, 0)
	check(view.state.rings[1].wedges[3].occupants[0].kind == &"emp_node", "Preview actual building input uses live rules")
	view.simulation.state.rings[1].wedges[12].hp = 0
	view.sync_simulation()
	view.strategic_view()
	await process_frame
	check(view.state.rings[1].wedges[12].occupants.has(0) and view._slot_count(1,12) == 0, "Broken wedge retained occupant is not drawn through an invalid zero-slot position")
	control_click(view.menu_button)
	await process_frame
	phase = view.sun_phase
	view._process(1.0)
	check(paused and view.sun_phase == phase, "Menu pauses sun motion with game")
	control_click(view.retry_button)
	check(not paused and view.state.rings[1].wedges[3].occupants.is_empty() and view.state.energy == 200 and view.treatment == 1 and view.sun_palette == 2, "Retry resets game and retains comparison preferences")
	view.simulation.state.energy = 1000000
	view.sync_simulation()
	await grow_to_twelve()
	print("Art preview checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
