extends "res://tests/presentation/test_weapon_catalogue_view.gd"
func _run() -> void:
	root.size = Vector2i(1440,810)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	funded_fixture()
	view._set_zoom(0.23)
	view.selected_cell = Vector2i(-1,-1)
	view.selected_slot = -1
	var cell := Vector2i(1,3)
	var count: int = view._slot_count(1,3)
	check(view._visible_board_slots(cell,count).is_empty(),"Crowded empty slots suppressed strategically")
	key_input(KEY_1)
	view.camera.force_update_scroll()
	slot_click(1,3,0)
	check(view.state.rings[1].wedges[3].occupants.has(0),"Hidden marker does not remove actual slot purchase target")
	check(0 in view._visible_board_slots(cell,count),"Occupied and selected marker retained")
	check(view._slot_label_visible(cell,0,count,"Flak"),"Selected building label retained at strategic zoom")
	view.selected_cell = Vector2i(-1,-1)
	view.selected_slot = -1
	view.detail_hover_cell = Vector2i(-1,-1)
	view.detail_hover_slot = -1
	check(not view._slot_label_visible(cell,0,count,"Flak"),"Crowded unselected label suppressed")
	var point: Vector2 = view.get_viewport().get_canvas_transform()*view.grid.polar_to_world(BuildingRules.slot_position(1,3,1,count))
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion)
	check(1 in view._visible_board_slots(cell,count),"Actual hovered empty target remains visible")
	motion = InputEventMouseMotion.new()
	motion.position = view.ui_panel.get_global_rect().get_center()
	root.push_input(motion)
	check(view.detail_hover_slot == -1,"GUI motion clears world hover affordance")
	view._set_zoom(3.0)
	check(view._visible_board_slots(cell,count).size() == count and view._slot_label_visible(cell,0,count,"Flak"),"Close zoom restores distinguishable slot and label detail")
	view.state.rings[1].wedges[3].hp = 0
	check(view._visible_board_slots(cell,view._slot_count(1,3)).is_empty(),"Broken wedge retaining occupant cannot create invalid slot geometry")
	print("Strategic detail checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)

func key_input(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)
