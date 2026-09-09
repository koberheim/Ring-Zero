extends "res://tests/presentation/test_weapon_catalogue_view.gd"

func key(code: Key, pressed: bool = true, echo: bool = false, modifier: String = "") -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	event.ctrl_pressed = modifier == "ctrl"
	event.alt_pressed = modifier == "alt"
	event.meta_pressed = modifier == "meta"
	root.push_input(event)

func reset_fixture() -> void:
	funded_fixture()
	view.choose_build(&"")
	view.camera.position = Vector2.ZERO
	view._set_zoom(0.9)
	view.camera.force_update_scroll()

func purchase_checks() -> void:
	for entry in [[KEY_1,&"flak"],[KEY_2,&"mass_driver"],[KEY_3,&"emp_node"],[KEY_4,&"lance_emitter"],[KEY_5,&"point_defense"],[KEY_H,&"wall"],[KEY_E,&"armor"],[KEY_R,&"repair_node"],[KEY_C,&"debris_field"],[KEY_V,&"tractor_lane"],[KEY_B,&"occlusion_screen"]]:
		reset_fixture()
		var before_state: Dictionary = view.state.duplicate(true)
		key(entry[0])
		check(view.build_mode == entry[1] and view.state == before_state, "%s key arms without transaction" % entry[1])
		var expected: Dictionary = view._place_build(1,3,0,entry[1])
		check(expected.ok, "Expected command fixture succeeds")
		# Restore the entire simulation; expected command only supplies the authoritative price/state.
		var expected_state: Dictionary = expected.state.duplicate(true)
		reset_fixture()
		key(entry[0])
		slot_click(1,3,0)
		check(view.state == expected_state and view.build_mode == entry[1], "%s actual key/world matches authoritative transaction and stays active" % entry[1])
		var first_energy: float = view.state.energy
		slot_click(1,4,0)
		check(view.state.energy < first_energy and view.build_mode == entry[1], "%s second distinct click buys without reselecting" % entry[1])
		var placed: Dictionary = view.state.duplicate(true)
		slot_click(1,4,0)
		check(view.state == placed and view.build_mode == entry[1], "%s occupied/duplicate click is atomic" % entry[1])
		view.state.energy = 0
		placed = view.state.duplicate(true)
		slot_click(1,5,0)
		check(view.state == placed and view.build_mode == entry[1], "%s insufficient funds remain atomic" % entry[1])
	reset_fixture()
	key(KEY_Q)
	check(view.state.rings.size() == 2 and view.build_mode == &"", "Q purchases one whole ring immediately")
	var purchased: Dictionary = view.state.duplicate(true)
	key(KEY_Q,true,true)
	check(view.state == purchased,"Held Q echo cannot repeat purchase")
	slot_click(3,3,0)
	check(view.state == purchased,"World click after Q cannot purchase another ring")
	key(KEY_Q)
	check(view.state.rings.size() == 3 and view.build_mode == &"", "Second deliberate Q purchases next ring")
	reset_fixture()
	for wedge in [3,4]:
		view.state.rings[1].wedges[wedge].hp = 40
	key(KEY_T)
	for wedge in [3,4]:
		slot_click(1,wedge,0)
		check(view.state.rings[1].wedges[wedge].hp == 100 and view.build_mode == &"repair", "T persists across actual repair clicks")
	reset_fixture()
	check(view.simulation.purchase_ring().ok, "Reclaim fixture buys outer ring")
	view.sync_simulation()
	for ring in [1,2]:
		view.state.rings[ring].collapsed = true
		view.state.rings[ring].relay = {}
		view.state.rings[ring].erase("relay_hp")
		view.state.rings[ring].erase("relay_max_hp")
		for wedge in view.state.rings[ring].wedges.values():
			wedge.hp = 0
			wedge.occupants = {}
	view.sync_simulation()
	key(KEY_Y)
	for ring in [1,2]:
		slot_click(ring,3,0)
		check(not view.state.rings[ring].get("collapsed",false) and view.build_mode == &"reclaim", "Y persists across reclaim clicks")
	reset_fixture()
	key(KEY_V)
	var direction: int = view.tractor_direction
	key(KEY_F)
	slot_click(1,3,0)
	check(TerrainRules.tractor_direction(view.state,1,3) == -direction, "F supplies actual lane direction")
	# Full perimeter rejection through a hotkey-selected tool.
	reset_fixture()
	check(view.simulation.purchase_ring().ok, "Unsafe fixture expansion")
	for wedge in range(1,12):
		check(view.simulation.place_terrain(2,wedge,1 if wedge == 6 else 0,&"debris_field").ok, "Unsafe fixture frontier")
	view.sync_simulation()
	key(KEY_C)
	var before_state: Dictionary = view.state.duplicate(true)
	slot_click(2,12,0)
	check(view.state == before_state and view.build_mode == &"debris_field" and view.feedback_label.text.contains("seal"), "Hotkey unsafe terrain rejected atomically")

func input_checks() -> void:
	reset_fixture()
	key(KEY_X)
	check(view.ability_mode == &"emp_burst" and view.simulation.abilities_snapshot().is_empty(), "X selects without casting")
	for modifier in ["ctrl","alt","meta"]:
		key(KEY_1,true,false,modifier)
		key(KEY_F,true,false,modifier)
		check(view.ability_mode == &"emp_burst", "Modified key does not clear ability")
	key(KEY_1,true,true)
	key(KEY_1,false)
	check(view.ability_mode == &"emp_burst", "Echo/release ignored")
	var edit := LineEdit.new()
	view.status_label.get_parent().add_child(edit)
	edit.grab_focus()
	key(KEY_1)
	key(KEY_ESCAPE)
	check(view.ability_mode == &"emp_burst" and not view.menu_open, "Text focus protects all keys")
	edit.release_focus()
	edit.queue_free()
	paused = true
	key(KEY_1)
	check(view.ability_mode == &"emp_burst", "External pause protects ability from selection key")
	paused = false
	key(KEY_C)
	check(view.tabs.current_tab == 2 and view.build_mode == &"debris_field" and view.ability_mode == &"", "Category switch leaves chosen tool active")
	key(KEY_Z)
	check(view.ability_mode == &"focused_flare" and view.build_mode == &"", "Z selects Flare")
	key(KEY_F1)
	check(view.help_panel.visible and view.ability_mode == &"focused_flare" and not paused, "F1 nonpausing help")
	key(KEY_ESCAPE)
	check(not view.help_panel.visible and view.ability_mode == &"focused_flare", "First Escape closes help only")
	key(KEY_ESCAPE)
	check(view.ability_mode == &"" and not view.menu_open, "Second Escape cancels ability")
	key(KEY_ESCAPE)
	check(view.menu_open and paused, "Idle Escape opens Menu")
	key(KEY_1)
	key(KEY_X)
	check(view.build_mode == &"" and view.ability_mode == &"", "Menu blocks gameplay shortcuts")
	key(KEY_ESCAPE)
	check(not view.menu_open and not paused, "Escape closes paused Menu")
	for code in [KEY_Z,KEY_X]:
		key(code)
		click(root.get_canvas_transform() * Vector2(220,100))
		var ability: StringName = &"focused_flare" if code == KEY_Z else &"emp_burst"
		check(view.ability_mode == &"" and view.simulation.abilities_snapshot().get(ability,0) > 0, "Solar key plus world click casts once")
		var cooldowns: Dictionary = view.simulation.abilities_snapshot()
		click(root.get_canvas_transform() * Vector2(220,100))
		key(code)
		check(view.ability_mode == &"" and view.simulation.abilities_snapshot() == cooldowns and view.feedback_label.text.contains("cooling"), "Ability remains one-shot and cooldown blocks reselection")
	reset_fixture()
	key(KEY_1)
	var held_point: Vector2 = root.get_canvas_transform() * view.grid.polar_to_world(BuildingRules.slot_position(1,3,0,1))
	button(MOUSE_BUTTON_LEFT,true,held_point)
	var held_state: Dictionary = view.state.duplicate(true)
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_canvas_transform() * view.grid.polar_to_world(BuildingRules.slot_position(1,4,0,1))
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion)
	key(KEY_1,true,true)
	button(MOUSE_BUTTON_LEFT,false,motion.position)
	check(view.state == held_state and view.build_mode == &"flak", "Held pointer motion/release and echoed shortcut never paint or spend")
	key(KEY_ESCAPE)
	check(view.build_mode == &"" and not view.menu_open, "Escape cancels build before Menu")
	key(KEY_1)
	var before_state: Dictionary = view.state.duplicate(true)
	button(MOUSE_BUTTON_MIDDLE,true,Vector2(800,650))
	button(MOUSE_BUTTON_MIDDLE,false,view.ui_panel.get_global_rect().get_center())
	check(not view.dragging, "Cross-panel release retained")
	button(MOUSE_BUTTON_RIGHT,true,view.ui_panel.get_global_rect().get_center())
	check(view.build_mode == &"" and view.state == before_state, "Right cancel over panel retained")
	view.simulation.ended = true
	key(KEY_1)
	key(KEY_X)
	check(view.build_mode == &"" and view.ability_mode == &"", "Ended run blocks shortcuts")
	view.simulation.ended = false
	key(KEY_1)
	control_click(view.menu_button)
	control_click(view.retry_button)
	check(view.build_mode == &"" and view.ability_mode == &"" and view.state.energy == 200, "Actual Retry resets tools and run")

func layout_checks(is_art: bool) -> void:
	reset_fixture()
	var camera_before: Transform2D = view.camera.transform
	for dimensions in [Vector2i(1280,900),Vector2i(1024,768)]:
		root.size = dimensions
		await process_frame
		await process_frame
		check(view.camera.transform == camera_before, "UI resize does not move camera")
		for category in range(3):
			view.tabs.current_tab = category
			await process_frame
			check(view.ui_panel.size.x <= 270 and view.ui_panel.position.y+view.ui_panel.size.y < view.solar_panel.position.y, "Catalogue fits compact width and avoids solar")
		check(view.ring_status_hud.size == Vector2(160,160), "Minimap footprint")
		var bar: TabBar = view.tabs.get_tab_bar()
		check(bar.get_tab_rect(0).size.x > 0 and bar.get_tab_rect(2).size.x > 0 and bar.get_tab_rect(0).position.x >= 0 and bar.get_tab_rect(2).end.x <= bar.size.x, "All three nonempty category names fit without scrolling")
		for category in range(3):
			click(bar.global_position + bar.get_tab_rect(category).get_center())
			await process_frame
			check(view.tabs.current_tab == category, "Every visible category accepts actual click without scrolling")
			print("Category %d footprint %s" % [category,view.ui_panel.size])
		check(view.menu_button.get_global_rect().end.x <= dimensions.x, "Menu anchored inside viewport")
		var hud: RingStatusHud = view.ring_status_hud
		var radius := hud.CORE_RADIUS + 0.5*hud.BAND_WIDTH
		click(hud.global_position+hud._point(radius,3.0/12))
		check(view.selected_cell == Vector2i(1,3), "Resized minimap actual focus")
		view.camera.transform = camera_before
		view.camera.force_update_scroll()
		key(KEY_1)
		var old_panel: Rect2 = view.ui_panel.get_global_rect()
		key(KEY_TAB)
		check(not view.ui_panel.visible and view.build_mode == &"flak" and view.solar_panel.visible, "Tab hides entire blocking catalogue and retains tool/solar")
		key(KEY_B)
		check(not view.ui_panel.visible and view.build_mode == &"occlusion_screen", "Hidden hotkey category stays hidden")
		key(KEY_ESCAPE)
		view.selected_cell = Vector2i(-9,-9)
		click(old_panel.get_center())
		check(view.selected_cell != Vector2i(-9,-9), "Former catalogue rectangle passes world input")
		key(KEY_TAB)
		check(view.ui_panel.visible, "Tab restores catalogue")
		key(KEY_F1)
		check(view.help_panel.visible and Rect2(Vector2.ZERO,dimensions).encloses(view.help_panel.get_global_rect()), "Help fits viewport")
		key(KEY_F1)
		if is_art:
			check(not view.preview_panel.visible, "Art drawer initially collapsed")
			key(KEY_F2)
			await process_frame
			check(view.preview_panel.visible and Rect2(Vector2.ZERO,dimensions).encloses(view.preview_panel.get_global_rect()), "F2 art drawer reachable and fitted")
			control_click(view.treatment_selector)
			check(view.treatment == 1, "Art option works inside drawer")
			control_click(view.treatment_selector)
			var old_art: Rect2 = view.preview_panel.get_global_rect()
			key(KEY_F2)
			view.selected_cell = Vector2i(-9,-9)
			click(old_art.get_center())
			check(not view.preview_panel.visible and view.selected_cell != Vector2i(-9,-9), "Hidden art rectangle passes world input")
		print("UI size %s: catalogue=%s minimap=%s" % [dimensions,view.ui_panel.size,view.ring_status_hud.size])
	root.size = Vector2i(1280,900)
	await process_frame

func _run() -> void:
	root.size = Vector2i(1280,900)
	for scene in ["live_view","art_preview"]:
		view = load("res://scenes/%s.tscn" % scene).instantiate()
		root.add_child(view)
		view.set_process(false)
		await process_frame
		await process_frame
		purchase_checks()
		input_checks()
		await layout_checks(scene == "art_preview")
		view.queue_free()
		await process_frame
	print("Hotkey/compact UI checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)

