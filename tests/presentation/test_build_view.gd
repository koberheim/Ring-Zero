extends SceneTree
var checks := 0
var failures := 0
var view: Node2D
var capture := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func button(index: MouseButton, pressed: bool, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	event.position = point
	event.global_position = point
	root.push_input(event)

func click(point: Vector2) -> void:
	button(MOUSE_BUTTON_LEFT, true, point)
	button(MOUSE_BUTTON_LEFT, false, point)

func slot_click(ring: int, wedge: int, slot: int) -> void:
	view.camera.force_update_scroll()
	var position := BuildingRules.slot_position(ring, wedge, slot, view._slot_count(ring, wedge))
	click(root.get_canvas_transform() * view.grid.polar_to_world(position))

func control_click(control: Control) -> void:
	click(control.get_global_rect().get_center())

func screenshot(name: String) -> void:
	if not capture:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered != null and not rendered.is_empty(), "Rendered image exists")
	check(rendered.get_size() == Vector2i(1280, 900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-011-" + name + ".png") == OK, "Capture saved")

func _run() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/build_view.tscn").instantiate()
	root.add_child(view)
	await process_frame
	await process_frame
	check(view.setup_ok and view.state.energy == 200, "Startup energy")
	check(view.state.rings.keys() == [1], "Only ring one owned")
	check(view.state.rings[1].wedges[12].occupants[0].kind == &"flak", "Starter Flak")
	check(view.state.rings[1].relay == {"active": true}, "Starter Relay is automatic, not slot-attached")
	var initial: Dictionary = view.state.duplicate(true)
	for frame in 8:
		await process_frame
	check(view.state == initial, "No passive income")
	check(view.expand_button.text.contains("240"), "Unaffordable quote still shows price")
	check(view.tabs.is_tab_disabled(2), "Terrain disabled")
	await screenshot("startup")
	slot_click(1, 3, 0)
	check(view.selected_cell == Vector2i(1, 3) and view.selected_slot == 0, "Actual slot selection")
	check(view.status_label.text.contains("owned"), "Ownership status")
	control_click(view.flak_button)
	check(view.build_mode == &"flak" and view.state == initial, "Button arms without spending or click through")
	slot_click(1, 3, 0)
	check(view.state.energy == 180 and view.build_mode == &"flak", "Flak spends exactly once and remains selected")
	check(view.state.rings[1].wedges[3].occupants[0].kind == &"flak", "New occupancy")
	# Drain to a deliberately insufficient balance so the unaffordable-placement
	# scenarios below stay genuinely unaffordable at the higher D-033 testing
	# starting grant (raised 2026-09-07 for player playtesting survivability).
	view.state.energy = 0
	var placed: Dictionary = view.state.duplicate(true)
	slot_click(1, 3, 0)
	check(view.state == placed, "Subsequent click never paints")
	await screenshot("placed-weapon")
	view.flak_button.pressed.emit()
	var selected_before: Vector2i = view.selected_cell
	# The five-row catalogue makes the bottom corner overlap Menu; use the
	# panel's top border to exercise background interception, not a button.
	click(view.ui_panel.get_global_rect().position + Vector2(1, 1))
	check(view.state == placed and view.selected_cell == selected_before and view.build_mode == &"flak", "Panel background blocks active placement and selection")
	slot_click(1, 3, 0)
	check(view.state == placed and view.build_mode == &"flak", "Occupied failure retains mode and state")
	slot_click(1, 4, 0)
	check(view.state == placed and view.feedback_label.text.contains("Not enough"), "Unaffordable failure")
	slot_click(2, 3, 0)
	check(view.state == placed and view.build_mode == &"flak", "Unowned failure")
	click(root.get_canvas_transform() * Vector2.ZERO)
	check(view.state == placed, "Invalid core failure")
	button(MOUSE_BUTTON_RIGHT, true, Vector2(950, 700))
	button(MOUSE_BUTTON_RIGHT, false, Vector2(950, 700))
	check(view.build_mode == &"" and view.state == placed, "Right cancel")
	view.flak_button.pressed.emit()
	selected_before = view.selected_cell
	var panel_point: Vector2 = view.ui_panel.get_global_rect().get_center()
	button(MOUSE_BUTTON_RIGHT, true, panel_point)
	button(MOUSE_BUTTON_RIGHT, false, panel_point)
	check(view.build_mode == &"" and view.state == placed and view.selected_cell == selected_before, "Right cancel over panel preserves state and selection")
	view.choose_build(&"relay")
	check(view.build_mode == &"", "Unsupported mode rejected")
	view.flak_button.pressed.emit()
	view.tabs.current_tab = 1
	check(view.build_mode == &"" and view.state == placed, "Switch tabs cancels without spend")
	await process_frame
	control_click(view.expand_button)
	check(view.build_mode == &"" and view.feedback_label.text.contains("energy"), "Expansion button explains unaffordable quote")
	slot_click(2, 3, 1)
	check(view.state == placed and view.build_mode == &"", "Unaffordable expansion atomic")
	control_click(view.menu_button)
	check(view.menu_open and paused and view.build_mode == &"", "Menu pauses and cancels")
	slot_click(1, 4, 0)
	view.choose_build(&"flak")
	check(view.state == placed and view.build_mode == &"", "Paused placement blocked")
	await screenshot("menu")
	control_click(view.resume_button)
	check(not paused and not view.menu_open and view.state == placed, "Resume via actual button input")
	var old_zoom: Vector2 = view.camera.zoom
	button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(950, 700))
	check(view.camera.zoom.is_equal_approx(old_zoom * 1.1), "Wheel factor")
	button(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(950, 700))
	check(view.camera.zoom.is_equal_approx(old_zoom), "Inverse wheel")
	button(MOUSE_BUTTON_MIDDLE, true, Vector2(950, 700))
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(990, 680)
	motion.relative = Vector2(40, -20)
	root.push_input(motion)
	button(MOUSE_BUTTON_MIDDLE, false, Vector2(990, 680))
	check(view.camera.position.is_equal_approx(-Vector2(40, -20) / old_zoom), "Middle pan")
	button(MOUSE_BUTTON_MIDDLE, true, Vector2(950, 700))
	button(MOUSE_BUTTON_MIDDLE, false, view.ui_panel.get_global_rect().get_center())
	var released_position: Vector2 = view.camera.position
	root.push_input(motion)
	check(not view.dragging and view.camera.position == released_position, "Release over panel ends drag")
	button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(950, 700))
	slot_click(2, 3, 1)
	check(view.selected_cell == Vector2i(2, 3) and view.selected_slot == 1, "Pan and zoom slot targeting")
	check(view.status_label.text.contains("unowned"), "Unowned status")
	check(view.camera.rotation == 0, "No rotation")
	view.camera.position = Vector2.ZERO
	view._set_zoom(old_zoom.x)
	view.camera.force_update_scroll()
	# Test fixture only: never exposed to the player.
	view.state.energy = 500
	view.refresh_view()
	view.expand_button.pressed.emit()
	slot_click(1, 4, 0)
	check(view.state.energy == 260 and view.build_mode == &"", "Immediate button purchase; later world click does not spend")
	slot_click(2, 3, 1)
	check(view.state.energy == 260 and view.state.rings.size() == 2, "Full ring purchase deducts quote")
	check(view.state.rings[2].wedges.size() == 12, "Twelve wedges included")
	check(view.state.rings[2].relay == {"active": true}, "New ring's Relay is automatic")
	check(view.state.rings[2].wedges[3].occupants.is_empty(), "Clicked wedge is not occupied by anything")
	check(view.build_mode == &"", "Expansion does not arm world placement")
	await screenshot("ring2-purchase")
	view.tabs.current_tab = 0
	await process_frame
	view.mass_driver_button.pressed.emit()
	var before_mass: float = view.state.energy
	slot_click(2, 3, 0)
	check(view.state.energy == before_mass - view.profile.value("economy.mass_driver_cost"), "Mass Driver uses profile price")
	check(view.state.rings[2].wedges[3].occupants[0].kind == &"mass_driver" and view.build_mode == &"mass_driver", "Mass Driver occupies selected slot")
	view.tabs.current_tab = 1
	await process_frame
	view.state.energy = 500
	view.state.rings[2].wedges[1].hp = 0
	var broken: Dictionary = view.state.duplicate(true)
	view.expand_button.pressed.emit()
	check(view.state == broken and view.feedback_label.text.contains("broken"), "Broken inward ring rejected at purchase")
	check(view.expand_button.disabled, "Broken expansion disabled on refresh")
	paused = true
	view.set_menu_open(true)
	view.set_menu_open(false)
	check(paused, "Menu restores preexisting pause")
	paused = false
	view.queue_free()
	await process_frame
	view = load("res://scenes/build_view.tscn").instantiate()
	view.balance_path = "res://data/balance/does-not-exist.json"
	root.add_child(view)
	await process_frame
	check(not view.setup_ok and view.state.is_empty(), "Bad profile does not mint fallback state")
	check(view.flak_button.disabled and view.mass_driver_button.disabled and view.expand_button.disabled, "Bad profile disables purchases")
	check(view.feedback_label.text.contains("Unable"), "Bad profile visible explanation")
	view.flak_button.pressed.emit()
	click(Vector2(800, 500))
	check(view.state.is_empty() and view.build_mode == &"", "Bad profile safe input")
	print("Build view checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
