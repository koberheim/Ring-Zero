extends "res://src/presentation/grid_inspection.gd"
## Neutral purchase view. All state transitions belong to the rule services.
@export var balance_path: String = "res://data/balance/testing.json"
@export var ring_limit: int = 3
@export var industrial_ui := false
var ui_font_scale := 1.0
var profile: BalanceProfile
var state: Dictionary = {}
var build_mode: StringName = &""
var menu_open := false
var energy_label: Label
var feedback_label: Label
var selected_slot := -1
var tabs: TabContainer
var flak_button: Button
var mass_driver_button: Button
var emp_node_button: Button
var lance_emitter_button: Button
var point_defense_button: Button
const BUILDING_NAMES := {&"flak": "Flak", &"mass_driver": "Mass Driver", &"emp_node": "EMP Node", &"lance_emitter": "Lance Emitter", &"point_defense": "Point Defense", &"relay": "Relay", &"armor_plating": "Armor Plating", &"repair_node": "Repair Node", &"debris_field": "Debris Field", &"tractor_lane": "Tractor Lane", &"occlusion_screen": "Occlusion Screen"}
var expand_button: Button
var menu_button: Button
var resume_button: Button
var menu_panel: PanelContainer
var ui_panel: PanelContainer
var catalogue_toggle: Button
var help_button: Button
var help_panel: PanelContainer
var switching_category := false
const TOOL_KEYS := {KEY_1: &"flak", KEY_2: &"mass_driver", KEY_3: &"emp_node", KEY_4: &"lance_emitter", KEY_5: &"point_defense", KEY_Q: &"expand", KEY_W: &"wall", KEY_E: &"armor", KEY_R: &"repair_node", KEY_T: &"repair", KEY_Y: &"reclaim", KEY_G: &"rebuild_relay", KEY_A: &"debris_field", KEY_S: &"tractor_lane", KEY_D: &"occlusion_screen"}
const TOOL_LABELS := {&"flak":"1", &"mass_driver":"2", &"emp_node":"3", &"lance_emitter":"4", &"point_defense":"5", &"expand":"Q", &"wall":"W", &"armor":"E", &"repair_node":"R", &"repair":"T", &"reclaim":"Y", &"rebuild_relay":"G", &"debris_field":"A", &"tractor_lane":"S", &"occlusion_screen":"D"}
var prior_pause := false
var setup_ok := false
var next_ring_quote: Dictionary = {}
var last_expansion_result: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ring_count = maxi(1, ring_limit)
	super._ready()
	_create_ui()
	var loaded := BalanceProfile.load_json(balance_path)
	if loaded.ok and ring_limit > 0:
		profile = loaded.profile
		var initial := BuildingRules.create_default_testing_state(profile)
		if initial.ok and initial.state.rings.size() <= ring_limit:
			state = initial.state
			setup_ok = true
	feedback_label.text = _mode_prompt(&"") if setup_ok else "Unable to load starting setup. Purchases unavailable."
	refresh_view()

func _button(text_value: String, parent: Node, action: Callable) -> Button:
	var result := Button.new()
	result.text = text_value
	parent.add_child(result)
	result.pressed.connect(action)
	return result

func _create_ui() -> void:
	var overlay := status_label.get_parent()
	status_label.position = Vector2(12, 42)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_label = Label.new()
	energy_label.position = Vector2(12, 10)
	overlay.add_child(energy_label)
	ui_panel = PanelContainer.new()
	ui_panel.position = Vector2(12, 104)
	ui_panel.custom_minimum_size = Vector2(260, 0)
	overlay.add_child(ui_panel)
	var column := VBoxContainer.new()
	ui_panel.add_child(column)
	tabs = TabContainer.new()
	tabs.use_hidden_tabs_for_min_size = false
	tabs.add_theme_font_size_override("font_size", 14)
	column.add_child(tabs)
	var weapons := VBoxContainer.new()
	weapons.name = "Weapons"
	tabs.add_child(weapons)
	flak_button = _button("Flak", weapons, choose_build.bind(&"flak"))
	mass_driver_button = _button("Mass Driver", weapons, choose_build.bind(&"mass_driver"))
	emp_node_button = _button("EMP Node", weapons, choose_build.bind(&"emp_node"))
	lance_emitter_button = _button("Lance Emitter", weapons, choose_build.bind(&"lance_emitter"))
	point_defense_button = _button("Point Defense", weapons, choose_build.bind(&"point_defense"))
	var structures := VBoxContainer.new()
	structures.name = "Structure"
	tabs.add_child(structures)
	expand_button = _button("Ring Plate", structures, choose_build.bind(&"expand"))
	var terrain := VBoxContainer.new()
	terrain.name = "Terrain"
	tabs.add_child(terrain)
	tabs.set_tab_disabled(2, true)
	tabs.tab_changed.connect(func(_index: int):
		if not switching_category:
			choose_build(&"")
		ui_panel.reset_size()
	)
	feedback_label = Label.new()
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(feedback_label)
	catalogue_toggle = _button("Hide build [Tab]", overlay, toggle_catalogue)
	menu_button = _button("Menu [Esc]", overlay, set_menu_open.bind(true))
	help_button = _button("Help [F1]", overlay, toggle_help)
	menu_panel = PanelContainer.new()
	menu_panel.position = Vector2(510, 350)
	menu_panel.custom_minimum_size = Vector2(260, 130)
	overlay.add_child(menu_panel)
	var menu_column := VBoxContainer.new()
	menu_panel.add_child(menu_column)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_column.add_child(title)
	resume_button = _button("Resume", menu_column, set_menu_open.bind(false))
	menu_panel.hide()
	help_panel = PanelContainer.new()
	help_panel.custom_minimum_size = Vector2(560, 0)
	overlay.add_child(help_panel)
	var help_margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]:
		help_margin.add_theme_constant_override("margin_" + side,8)
	help_panel.add_child(help_margin)
	var help_column := VBoxContainer.new()
	help_margin.add_child(help_column)
	var help_text := Label.new()
	help_text.text = "SHORTCUTS  /  physical key positions\n\n1 Flak   2 Mass Driver   3 EMP Node\n4 Lance Emitter   5 Point Defense\nQ Ring Plate   W Wall   E Armor Plating\nR Repair Node   T Repair Wedge   Y Reclaim Ring   G Rebuild Relay\nA Debris Field   S Tractor Lane   D Occlusion Screen\nF Tractor direction   Z Focused Flare   X EMP Burst\n\nChoose a tool, then click its wedge or slot. Q buys a whole ring.\nBuild tools stay selected; every click spends separately.\nSolar tools cast once. Right click / Esc cancels.\nDebris blocks the outer boundary; Screens slow outward.\nRepair damaged wedges; reclaim collapsed rings.\n\nMiddle drag: pan   Wheel: zoom   Minimap: focus\nTab: catalogue   F1: help   F2: art settings (preview)\nEsc: close help, cancel tool, then Menu."
	help_column.add_child(help_text)
	_button("Close help [F1 / Esc]", help_column, toggle_help)
	help_panel.hide()
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()

func refresh_view() -> void:
	energy_label.text = "Energy: %s" % str(state.energy) if setup_ok else "Energy: unavailable"
	flak_button.disabled = not _can_build() or menu_open
	mass_driver_button.disabled = not _can_build() or menu_open
	for button in [emp_node_button, lance_emitter_button, point_defense_button]:
		button.disabled = not _can_build() or menu_open
	expand_button.disabled = not _can_build() or menu_open
	if setup_ok:
		flak_button.text = "Flak — %s energy" % str(profile.value("economy.flak_cost"))
		mass_driver_button.text = "Mass Driver — %s energy" % str(profile.value("economy.mass_driver_cost"))
		for entry in [[emp_node_button, &"emp_node"], [lance_emitter_button, &"lance_emitter"], [point_defense_button, &"point_defense"]]:
			entry[0].text = "%s — %s energy" % [BUILDING_NAMES[entry[1]], str(profile.value("economy.%s_cost" % entry[1]))]
		var quote := _quote_expansion()
		last_expansion_result = quote
		next_ring_quote = quote.quote if quote.ok else {}
		expand_button.disabled = menu_open or not _can_build() or not quote.ok
		expand_button.text = "Ring Plate — %s energy" % str(quote.quote.cost) if quote.ok else "Ring Plate unavailable"
	_compact_buttons()
	_update_status()
	queue_redraw()

func _compact_buttons() -> void:
	for category in tabs.get_children():
		for child in category.get_children():
			if child is Button:
				child.add_theme_font_size_override("font_size", roundi(16*ui_font_scale) if industrial_ui else 14)
				child.text = child.text.replace(" energy", "")
				child.tooltip_text = child.text + ". " + _button_instruction(child)
	for entry in [[flak_button,&"flak"],[mass_driver_button,&"mass_driver"],[emp_node_button,&"emp_node"],[lance_emitter_button,&"lance_emitter"],[point_defense_button,&"point_defense"],[expand_button,&"expand"]]:
		entry[0].text = "[%s] %s" % [TOOL_LABELS[entry[1]],entry[0].text]
	ui_panel.reset_size()

func _button_instruction(button: Button) -> String:
	return "Choose this tool, then click its wedge or slot. Right click cancels."

func _tool_context(kind: StringName) -> String:
	if kind == &"":
		return "Choose a tool. [F1] controls / instructions."
	var name: String = _tool_name(kind)
	var cost := _tool_cost(kind)
	return "%s%s active. Click a wedge / slot; Esc cancels." % [name," - " + cost if not cost.is_empty() else ""]

func _tool_name(kind: StringName) -> String:
	return BUILDING_NAMES.get(kind, {&"expand":"Ring Plate", &"wall":"Wall", &"armor":"Armor Plating", &"repair":"Repair Wedge", &"reclaim":"Reclaim Ring", &"rebuild_relay":"Rebuild Relay"}.get(kind,str(kind)))
func _tool_cost(kind: StringName) -> String:
	if kind == &"expand":
		return str(next_ring_quote.cost) + " energy" if not next_ring_quote.is_empty() else "unavailable"
	var key: String = {&"armor":"armor_plating"}.get(kind,str(kind))
	if kind in [&"repair",&"reclaim"]:
		return "inspect cost"
	return str(profile.value("economy.%s_cost" % key)) + " energy" if profile != null else ""


func _layout_ui() -> void:
	if menu_button == null:
		return
	var viewport_size := get_viewport_rect().size
	menu_button.position = Vector2(viewport_size.x - 118, 8)
	menu_button.size = Vector2(106, 28)
	help_button.position = Vector2(viewport_size.x - 224, 8)
	help_button.size = Vector2(100, 28)
	catalogue_toggle.position = Vector2(12, 74)
	catalogue_toggle.size = Vector2(120, 26)
	status_label.size = Vector2(viewport_size.x - 200, 26)
	feedback_label.position = Vector2(288, 74)
	feedback_label.size = Vector2(viewport_size.x - 480, 54)
	menu_panel.position = (viewport_size - menu_panel.get_combined_minimum_size()) * 0.5
	help_panel.position = (viewport_size - help_panel.get_combined_minimum_size()) * 0.5

func toggle_catalogue() -> void:
	ui_panel.visible = not ui_panel.visible
	catalogue_toggle.text = "Build [Tab]" if not ui_panel.visible else "Hide build [Tab]"

func toggle_help() -> void:
	help_panel.visible = not help_panel.visible
	_layout_ui()

func _has_active_tool() -> bool:
	return build_mode != &""

func _extra_key(_key: Key) -> bool:
	return false

func _handle_key(event: InputEventKey) -> bool:
	if not event.pressed or event.echo or event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return false
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return false
	var key := event.physical_keycode
	if key == KEY_ESCAPE:
		if help_panel.visible:
			help_panel.hide()
		elif menu_open:
			set_menu_open(false)
		elif _has_active_tool():
			choose_build(&"")
		else:
			set_menu_open(true)
		return true
	if menu_open or get_tree().paused or not _can_build():
		return false
	if key == KEY_TAB:
		toggle_catalogue()
		return true
	if key == KEY_F1:
		toggle_help()
		return true
	if TOOL_KEYS.has(key):
		var kind: StringName = TOOL_KEYS[key]
		if _supports_mode(kind):
			var category := 0 if key in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5] else (2 if key in [KEY_A,KEY_S,KEY_D] else 1)
			switching_category = true
			tabs.current_tab = category
			switching_category = false
			choose_build(kind)
		return true
	return _extra_key(key)

func choose_build(kind: StringName) -> void:
	if menu_open or get_tree().paused or not _can_build():
		return
	if not _supports_mode(kind):
		return
	if kind == &"expand":
		if expand_button.disabled:
			feedback_label.text = "Ring Plate unavailable. " + expand_button.tooltip_text
			return
		var purchase: Dictionary = _purchase_ring()
		if purchase.ok:
			state = purchase.state
			build_mode = &""
			refresh_view()
			feedback_label.text = "Ring %d purchased." % state.rings.size()
		else:
			refresh_view()
			feedback_label.text = _purchase_error(purchase.errors)
		return
	build_mode = kind
	feedback_label.text = _tool_context(kind)
	_update_status()
	if kind == &"expand":
		var quote := _quote_expansion()
		if quote.ok and not quote.quote.affordable:
			feedback_label.text = "Not enough energy. Ring Plate costs %s." % str(quote.quote.cost)

func set_menu_open(open: bool) -> void:
	if open == menu_open:
		return
	menu_open = open
	dragging = false
	build_mode = &""
	if open:
		prior_pause = get_tree().paused
		get_tree().paused = true
	else:
		get_tree().paused = prior_pause
	menu_panel.visible = open
	refresh_view()

func _slot_count(ring: int, wedge: int) -> int:
	if not setup_ok or ring < 1:
		return 0
	if state.rings.has(ring):
		return state.rings[ring].wedges[wedge].slot_count
	return int(next_ring_quote.slots_per_wedge) if not next_ring_quote.is_empty() and next_ring_quote.ring == ring else 0

func _can_build() -> bool:
	return setup_ok

func _supports_mode(kind: StringName) -> bool:
	return kind in [&"", &"flak", &"mass_driver", &"emp_node", &"lance_emitter", &"point_defense", &"expand"]

func _mode_prompt(kind: StringName) -> String:
	return "Click the next ring to claim it." if kind == &"expand" else ("Click an empty owned slot. Right click cancels." if kind != &"" else "Choose a building, then click a slot.")

func _place_build(ring: int, wedge: int, slot: int, kind: StringName) -> Dictionary:
	return _place_weapon(ring, wedge, slot, kind)

func _quote_expansion() -> Dictionary:
	return RingPurchaseRules.quote_next_ring(state, profile, ring_limit)

func _purchase_ring() -> Dictionary:
	return RingPurchaseRules.purchase_next_ring(state, profile, ring_limit)

func _reclaim_ring(_ring: int) -> Dictionary:
	return RingPurchaseRules.failure("Reclaim is not supported here")

func _place_weapon(ring: int, wedge: int, slot: int, kind: StringName) -> Dictionary:
	return BuildingRules.place_weapon(state, profile, ring, wedge, slot, kind)

func _cell_owned(cell: Vector2i) -> bool:
	return setup_ok and state.rings.has(cell.x)

func _cell_description(cell: Vector2i) -> String:
	return "owned" if _cell_owned(cell) else "unowned"

func _cell_shade(cell: Vector2i) -> float:
	return 0.27 if _cell_owned(cell) else 0.12

func _update_status() -> void:
	if status_label == null:
		return
	var selection := "No selection"
	if selected_cell == Vector2i.ZERO:
		selection = "Selected core"
	elif selected_cell.x > 0:
		selection = "Selected ring %d / wedge %d / slot %d — %s" % [selected_cell.x, selected_cell.y, selected_slot, _cell_description(selected_cell)]
	status_label.text = selection

# Override the inspector's early input entirely. World input runs only after GUI.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		detail_hover_cell = Vector2i(-1,-1)
		detail_hover_slot = -1
		queue_redraw()
	if event is InputEventKey and _handle_key(event):
		get_viewport().set_input_as_handled()
		return
	# Release must end a drag even when a GUI panel consumes the event.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		dragging = false
	# Cancellation also applies over controls; purchases remain in unhandled input.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not menu_open:
		choose_build(&"")
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if menu_open or get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			choose_build(&"")
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			camera.force_update_scroll()
			var point: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
			var polar := grid.world_to_polar(point)
			selected_cell = grid.world_to_cell(point)
			selected_slot = -1 if polar == null else BuildingRules.slot_for_fraction(polar.angular_fraction, _slot_count(polar.ring, polar.wedge))
			var purchased := false
			if build_mode != &"" and _can_build():
				var result: Dictionary
				if build_mode == &"expand":
					if selected_cell.x != state.rings.size() + 1:
						feedback_label.text = "Click the next ring to claim it."
						refresh_view()
						return
					result = _purchase_ring()
				elif build_mode == &"reclaim":
					if not state.rings.has(selected_cell.x) or not state.rings[selected_cell.x].get("collapsed", false):
						feedback_label.text = "Click a collapsed ring to reclaim it."
						refresh_view()
						return
					result = _reclaim_ring(selected_cell.x)
				else:
					result = _place_build(selected_cell.x, selected_cell.y, selected_slot, build_mode)
				if result.ok:
					state = result.state
					purchased = true
				else:
					feedback_label.text = _tool_name(build_mode) + ": " + _purchase_error(result.errors)
			refresh_view()
			if purchased:
				feedback_label.text = "Purchased. " + _tool_context(build_mode)
			return
	super._input(event)
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]):
		_update_detail_hover(event.position)

func _purchase_error(errors: PackedStringArray) -> String:
	var details := " ".join(errors).to_lower()
	if "power" in details:
		return "Not enough power capacity on this ring."
	if "insufficient" in details:
		return "Not enough energy."
	if "inward" in details:
		return "Repair is unavailable. A broken inward wedge blocks expansion."
	if "occupied" in details:
		return "That slot is occupied, invalid, or on a broken wedge."
	return "Cannot build there. Choose an empty slot on an owned, unbroken wedge."

var detail_hover_cell := Vector2i(-1,-1)
var detail_hover_slot := -1

func _update_detail_hover(screen: Vector2) -> void:
	camera.force_update_scroll()
	var point := get_viewport().get_canvas_transform().affine_inverse()*screen
	var polar := grid.world_to_polar(point)
	detail_hover_cell = grid.world_to_cell(point)
	detail_hover_slot = -1 if polar == null else BuildingRules.slot_for_fraction(polar.angular_fraction,_slot_count(polar.ring,polar.wedge))
	queue_redraw()

func _slot_screen_spacing(cell: Vector2i, count: int) -> float:
	if count <= 0: return 0.0
	var bounds := grid.ring_bounds(cell.x)
	var radius := (bounds.x+bounds.y)*0.5
	return 2.0*radius*sin(PI/(12.0*count))*camera.zoom.x

func _detail_slot(cell: Vector2i, slot: int) -> bool:
	return (cell == selected_cell and slot == selected_slot) or (cell == detail_hover_cell and slot == detail_hover_slot)

func _visible_board_slots(cell: Vector2i, count: int) -> Array:
	if count <= 0: return []
	if _slot_screen_spacing(cell,count) >= 12.0 and PolarGrid.RING_WIDTH*camera.zoom.x >= 16.0:
		return range(count)
	var result: Array = state.rings[cell.x].wedges[cell.y].occupants.keys() if _cell_owned(cell) else []
	for entry in [[selected_cell,selected_slot],[detail_hover_cell,detail_hover_slot]]:
		if entry[0] == cell and entry[1] >= 0 and entry[1] < count and entry[1] not in result: result.append(entry[1])
	return result

func _slot_label_visible(cell: Vector2i, slot: int, count: int, label: String) -> bool:
	if _detail_slot(cell,slot): return true
	var width := ThemeDB.fallback_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
	return _slot_screen_spacing(cell,count) >= width+12.0 and PolarGrid.RING_WIDTH*camera.zoom.x >= 40.0

func _draw() -> void:
	_draw_board()

func _draw_board() -> void:
	if camera == null:
		return
	var labels: Array[Dictionary] = []
	for index in cells.size():
		var cell := cells[index]
		var polygon := cell_polygons[index]
		var owned := _cell_owned(cell)
		var shade := _cell_shade(cell)
		draw_colored_polygon(polygon, Color(shade, shade, shade))
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		draw_polyline(outline, Color(0.65, 0.65, 0.65) if owned else Color(0.3, 0.3, 0.3), 1.0 / camera.zoom.x, true)
		if cell == selected_cell:
			draw_polyline(outline, Color.WHITE, 2.0 / camera.zoom.x, true)
		var count := _slot_count(cell.x,cell.y)
		for slot in _visible_board_slots(cell,count):
			var point := grid.polar_to_world(BuildingRules.slot_position(cell.x, cell.y, slot, count))
			var occupant: Dictionary = state.rings[cell.x].wedges[cell.y].occupants.get(slot, {}) if owned else {}
			var radius := 4.0 if occupant.is_empty() else 7.0
			draw_circle(point, radius / camera.zoom.x, Color(0.75, 0.75, 0.75) if owned else Color(0.4, 0.4, 0.4), not occupant.is_empty())
			if cell == selected_cell and slot == selected_slot:
				draw_circle(point, 10.0 / camera.zoom.x, Color.WHITE, false, 2.0 / camera.zoom.x)
			if not occupant.is_empty():
				var label: String = BUILDING_NAMES.get(occupant.kind, "")
				var label_y := -13 if _slot_count(cell.x, cell.y) > 1 and slot % 2 == 0 else 23
				if _slot_label_visible(cell,slot,count,label): labels.append({"text": label, "point": point, "y": label_y})
	# Labels may cross a wedge boundary; later board fills must not erase them.
	var font := ThemeDB.fallback_font
	for label in labels:
		var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_set_transform(label.point + Vector2(-width * 0.5, label.y) / camera.zoom.x, 0, Vector2.ONE / camera.zoom.x)
		draw_string(font, Vector2.ZERO, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		draw_set_transform(Vector2.ZERO)
