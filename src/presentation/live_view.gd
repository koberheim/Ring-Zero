extends "res://src/presentation/build_view.gd"
## Presentation of the reviewed fixed-step simulation; no gameplay state rules here.
@export var unbounded_expansion: bool = false
const REPRESENTATIONAL_RING_LIMIT: int = 9223372036854775807
var prepared_run: Dictionary = {}
var application_host: Node
var interface_settings := {"effects":false,"reduced_motion":false,"ui_scale":1.0}
var instrument_panel: PanelContainer
var relay_button: Button
var hit_effects: Array[Dictionary] = []
var effect_positions: Dictionary = {}
var elite_points: Dictionary = {}
var recording_build := false
var seen_elites: Dictionary = {}
var simulation: LiveSimulation
var clock: FixedStepClock
var last_error: String = ""
var combat_label: Label
var rendered_targets: Array[Dictionary] = []
var target_grid: PolarGrid
var simulation_cpu_usec := 0
var sync_cpu_usec := 0
var draw_cpu_usec := 0
var quote_cpu_usec := 0
var simulation_ticks_per_frame := 0
var target_points := PackedVector2Array()
var machine_markers: MultiMeshInstance2D
var marker_instances: MultiMesh
var marker_zoom := -1.0
var wall_button: Button
var wall_edges: Dictionary = {}
var normal_points := PackedVector2Array()
var surfaced_points := PackedVector2Array()
var tunneler_warnings: Array[Dictionary] = []
var triangle_instances: MultiMesh
var triangle_markers: MultiMeshInstance2D
var ring_status_hud: RingStatusHud
var retry_button: Button
var run_kill_count := 0
var armor_button: Button
var repair_node_button: Button
var repair_button: Button
var reclaim_button: Button
var quote_preview_cell := Vector2i(-1, -1)
var quote_preview_slot := -1
var ability_mode: StringName = &""
var ability_aim_world := Vector2.ZERO
var ability_aim_valid := false
var solar_panel: VBoxContainer
var focused_flare_button: Button
var emp_burst_button: Button
var debris_field_button: Button
var tractor_lane_button: Button
var occlusion_screen_button: Button
var tractor_direction_button: Button
var tractor_direction := 1
const TERRAIN_KINDS := [&"debris_field",&"tractor_lane",&"occlusion_screen"]
const ABILITY_NAMES := {&"focused_flare": "Focused Flare", &"emp_burst": "EMP Burst"}
const WEDGE_STATUS_CRITICAL_FRACTION := 0.25

func _create_ui() -> void:
	super._create_ui()
	wall_button = _button("Wall", expand_button.get_parent(), choose_build.bind(&"wall"))
	armor_button = _button("Armor Plating", expand_button.get_parent(), choose_build.bind(&"armor"))
	repair_node_button = _button("Repair Node", expand_button.get_parent(), choose_build.bind(&"repair_node"))
	# Phase 7 (D-022): Repair/Reclaim act on already-owned structure rather than
	# an empty slot, so they live next to Structure purchases, not inside them.
	repair_button = _button("Repair Wedge", expand_button.get_parent(), choose_build.bind(&"repair"))
	reclaim_button = _button("Reclaim Ring", expand_button.get_parent(), choose_build.bind(&"reclaim"))
	relay_button = _button("[G] Rebuild Relay", expand_button.get_parent(), choose_build.bind(&"rebuild_relay"))
	var terrain := tabs.get_child(2)
	tabs.set_tab_disabled(2,false)
	debris_field_button = _button("Debris Field",terrain,choose_build.bind(&"debris_field"))
	tractor_lane_button = _button("Tractor Lane",terrain,choose_build.bind(&"tractor_lane"))
	occlusion_screen_button = _button("Occlusion Screen",terrain,choose_build.bind(&"occlusion_screen"))
	tractor_direction_button = _button("[F] Tractor: Clockwise",terrain,toggle_tractor_direction)
	var solar := VBoxContainer.new()
	solar.name = "Solar"
	solar_panel = solar
	status_label.get_parent().add_child(solar)
	solar.custom_minimum_size = Vector2(260, 0)
	focused_flare_button = _button("Focused Flare",solar,choose_ability.bind(&"focused_flare"))
	emp_burst_button = _button("EMP Burst",solar,choose_ability.bind(&"emp_burst"))
	ring_status_hud = RingStatusHud.new()
	ring_status_hud.position = Vector2(1010, 90)
	ring_status_hud.size = Vector2(160, 160)
	ring_status_hud.custom_minimum_size = Vector2(160, 160)
	ring_status_hud.wedge_focus_requested.connect(_on_ring_status_focus)
	status_label.get_parent().add_child(ring_status_hud)
	# Session lifecycle (Phase 6): a retry option alongside the existing pause/resume menu.
	retry_button = _button("Retry", resume_button.get_parent(), _start_new_run)

func _ready() -> void:
	super._ready()
	combat_label = Label.new()
	combat_label.position = Vector2(1010, 16)
	status_label.get_parent().add_child(combat_label)
	_create_machine_markers()
	clock = FixedStepClock.new(60.0, _simulation_tick)
	_start_new_run()
	_layout_ui()
	if application_host != null:
		_button("Settings",resume_button.get_parent(),application_host.show_settings.bind("game"))
		_button("Abandon run and return",resume_button.get_parent(),application_host.abandon_run)
		var help_column: VBoxContainer = help_panel.get_child(0).get_child(0)
		var text: Label = help_column.get_child(0)
		help_column.remove_child(text)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(600,450)
		help_column.add_child(scroll)
		help_column.move_child(scroll,0)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.text += "\n\n" + application_host.reference_text()
		scroll.add_child(text)
	apply_interface_settings(interface_settings)

func _start_new_run() -> void:
	if application_host != null and simulation != null:
		application_host.request_restart()
		return
	if not setup_ok:
		refresh_view()
		return
	last_error = ""
	run_kill_count = 0
	hit_effects.clear()
	seen_elites.clear()
	build_mode = &""
	ability_mode = &""
	ability_aim_valid = false
	selected_cell = Vector2i(-1, -1)
	selected_slot = -1
	var created: Dictionary
	if not prepared_run.is_empty():
		profile = prepared_run.profile
		created = {"ok":true,"simulation":prepared_run.simulation}
	else:
		created = LiveSimulation.create(profile, REPRESENTATIONAL_RING_LIMIT if unbounded_expansion else ring_limit, true)
	if created.ok:
		simulation = created.simulation
		state = simulation.state
		quote_preview_cell = Vector2i(-1, -1)
		quote_preview_slot = -1
		wall_edges.clear()
		rebuild_grid(maxi(1, ring_limit))
		clock = FixedStepClock.new(60.0, _simulation_tick)
		if menu_open:
			set_menu_open(false)
		sync_simulation()
	else:
		last_error = "Unable to start the live test."
		setup_ok = false
		feedback_label.text = last_error
	refresh_view()

func _process(delta: float) -> void:
	if not get_tree().paused:
		var had_effects := not hit_effects.is_empty()
		for effect in hit_effects:
			effect.remaining -= delta
		hit_effects = hit_effects.filter(func(effect): return effect.remaining > 0)
		if had_effects: queue_redraw()
	simulation_cpu_usec = 0
	sync_cpu_usec = 0
	quote_cpu_usec = 0
	simulation_ticks_per_frame = 0
	if simulation == null or clock == null:
		return
	clock.paused = get_tree().paused or simulation.ended or not last_error.is_empty()
	var advanced := clock.advance(delta)
	simulation_ticks_per_frame = advanced
	if advanced > 0:
		var sync_started := Time.get_ticks_usec()
		sync_simulation()
		sync_cpu_usec = Time.get_ticks_usec() - sync_started

func _simulation_tick(delta_seconds: float) -> void:
	if simulation == null or simulation.ended or get_tree().paused or not last_error.is_empty():
		return
	var started := Time.get_ticks_usec()
	effect_positions.clear()
	if interface_settings.effects:
		for target in simulation.targets_snapshot():
			effect_positions[target.id] = PolarGrid.new(maxi(1,target.position.ring)).polar_to_world(target.position)
	var result := simulation.step(delta_seconds)
	simulation_cpu_usec += Time.get_ticks_usec() - started
	if not result.ok:
		last_error = "Live test stopped: " + " ".join(result.errors)
		clock.paused = true
		build_mode = &""
		ability_mode = &""
		ability_aim_valid = false
		feedback_label.text = "Live test stopped. Simulation error."
		return
	var events: Dictionary = result.events
	_capture_hits(events)
	run_kill_count += events.kill_ids.size()
	if events.core_lost:
		clock.paused = true
		build_mode = &""
		ability_mode = &""
		ability_aim_valid = false
	elif not events.get("relays_lost",[]).is_empty():
		feedback_label.text = "Relay lost on ring %d. Power interrupted; select ring and rebuild [G]." % events.relays_lost.back()
	elif not events.collapsed_rings.is_empty():
		feedback_label.text = "Ring %d collapsed." % events.collapsed_rings.back()
	elif not events.broken_wedges.is_empty():
		var cell: Vector2i = events.broken_wedges.back()
		feedback_label.text = "Ring %d / wedge %d broken." % [cell.x, cell.y]
	elif not events.walls_broken.is_empty():
		var cell: Vector2i = events.walls_broken.back()
		feedback_label.text = "Wall on ring %d / wedge %d broken." % [cell.x, cell.y]

# Called after simulated ticks, or explicitly after isolated test fixture setup.
func sync_simulation() -> void:
	if simulation == null:
		return
	state = simulation.state
	_sync_display_grid()
	rendered_targets = simulation.targets_snapshot()
	var outer := ring_count
	for target in rendered_targets:
		outer = maxi(outer, target.position.ring)
		if target.get("kind", &"") == &"tunneler":
			outer = maxi(outer, target.destination.ring)
	target_grid = PolarGrid.new(outer)
	target_points.resize(rendered_targets.size())
	normal_points.clear()
	surfaced_points.clear()
	tunneler_warnings.clear()
	elite_points.clear()
	for index in rendered_targets.size():
		var target: Dictionary = rendered_targets[index]
		target_points[index] = target_grid.polar_to_world(target.position)
		if target.get("kind", &"") not in [&"",&"standard",&"normal",&"tunneler"]:
			var kind: StringName = target.kind
			if not seen_elites.has(kind):
				seen_elites[kind] = true
				feedback_label.text = "%s incoming. F1 lists counters." % str(kind).capitalize()
			if not elite_points.has(kind): elite_points[kind] = PackedVector2Array()
			elite_points[kind].append(target_points[index])
		elif target.get("kind", &"") != &"tunneler":
			normal_points.append(target_points[index])
		elif target.phase == &"burrowing":
			tunneler_warnings.append({"id": target.id, "point": target_grid.polar_to_world(target.destination), "remaining": maxf(0.0, target.burrow_duration_seconds - target.burrow_elapsed_seconds)})
		else:
			surfaced_points.append(target_points[index])
	_update_machine_markers()
	refresh_view()

func _create_machine_markers() -> void:
	# One shared filled circle, instanced once per machine without deduplication.
	var vertices := PackedVector3Array()
	for segment in 32:
		vertices.append(Vector3.ZERO)
		var start := TAU * float(segment) / 32.0
		var end := TAU * float(segment + 1) / 32.0
		vertices.append(Vector3(cos(start), sin(start), 0))
		vertices.append(Vector3(cos(end), sin(end), 0))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var circle := ArrayMesh.new()
	circle.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	marker_instances = MultiMesh.new()
	marker_instances.transform_format = MultiMesh.TRANSFORM_2D
	marker_instances.mesh = circle
	machine_markers = MultiMeshInstance2D.new()
	machine_markers.multimesh = marker_instances
	machine_markers.modulate = Color(0.88, 0.88, 0.88)
	add_child(machine_markers)
	var triangle_arrays := []
	triangle_arrays.resize(Mesh.ARRAY_MAX)
	triangle_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0, -1, 0), Vector3(0.8660254, 0.5, 0), Vector3(-0.8660254, 0.5, 0)])
	var triangle := ArrayMesh.new()
	triangle.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, triangle_arrays)
	triangle_instances = MultiMesh.new()
	triangle_instances.transform_format = MultiMesh.TRANSFORM_2D
	triangle_instances.mesh = triangle
	triangle_markers = MultiMeshInstance2D.new()
	triangle_markers.multimesh = triangle_instances
	triangle_markers.modulate = Color(0.88, 0.88, 0.88)
	add_child(triangle_markers)

func _update_machine_markers() -> void:
	if marker_instances == null:
		return
	if marker_instances.instance_count != normal_points.size():
		marker_instances.instance_count = normal_points.size()
	if triangle_instances.instance_count != surfaced_points.size():
		triangle_instances.instance_count = surfaced_points.size()
	marker_zoom = camera.zoom.x
	var size := Vector2.ONE * 3.0 / marker_zoom
	for index in normal_points.size():
		marker_instances.set_instance_transform_2d(index, Transform2D(0.0, size, 0.0, normal_points[index]))
	for index in surfaced_points.size():
		triangle_instances.set_instance_transform_2d(index, Transform2D(0.0, size, 0.0, surfaced_points[index]))

func refresh_view() -> void:
	if simulation != null:
		state = simulation.state
		_sync_display_grid()
	super.refresh_view()
	if focused_flare_button != null:
		var cooldowns := simulation.abilities_snapshot() if simulation != null else {}
		for entry in [[focused_flare_button,&"focused_flare"],[emp_burst_button,&"emp_burst"]]:
			var remaining: float = cooldowns.get(entry[1],0.0)
			entry[0].text = "%s — %.1f s" % [ABILITY_NAMES[entry[1]],remaining] if remaining > 0 else "%s — Ready" % ABILITY_NAMES[entry[1]]
			entry[0].disabled = not _can_build() or menu_open
	if debris_field_button != null:
		for entry in [[debris_field_button,&"debris_field"],[tractor_lane_button,&"tractor_lane"],[occlusion_screen_button,&"occlusion_screen"]]:
			entry[0].text = "%s — %s energy" % [BUILDING_NAMES[entry[1]],str(profile.value("economy.%s_cost" % entry[1]))] if profile != null else BUILDING_NAMES[entry[1]]
			entry[0].disabled = not _can_build() or menu_open
		tractor_direction_button.disabled = not _can_build() or menu_open
	if wall_button != null:
		wall_button.disabled = not _can_build() or menu_open
		if profile != null:
			wall_button.text = "Wall — %s energy" % str(profile.value("economy.wall_cost"))
	if armor_button != null:
		armor_button.disabled = not _can_build() or menu_open
		if profile != null:
			armor_button.text = "Armor Plating — %s energy" % str(profile.value("economy.armor_plating_cost"))
	if repair_node_button != null:
		repair_node_button.disabled = not _can_build() or menu_open
		if profile != null:
			repair_node_button.text = "Repair Node — %s energy" % str(profile.value("economy.repair_node_cost"))
	if repair_button != null:
		repair_button.disabled = not _can_build() or menu_open
	if reclaim_button != null:
		reclaim_button.disabled = not _can_build() or menu_open
	if relay_button != null:
		relay_button.disabled = not _can_build() or menu_open
		relay_button.text = "[G] Rebuild Relay - %s" % str(profile.value("economy.rebuild_relay_cost")) if profile != null else "[G] Rebuild Relay"
		relay_button.tooltip_text = "Choose G, then click the ring whose Relay needs rebuilding."
	_refresh_wall_edges()
	if ring_status_hud != null:
		ring_status_hud.set_status(_ring_status_records())
	_compact_live_buttons()
	_refresh_access()
	if industrial_ui: call_deferred("_industrial_layout")
	if combat_label == null:
		return
	if simulation == null:
		combat_label.text = "Live test unavailable"
		return
	combat_label.text = "Core HP: %s   |   Active machines: %d" % [str(snappedf(simulation.core_hp, 0.01)), rendered_targets.size()]
	if industrial_ui:
		combat_label.text += "   |   Ring %d   |   %.0fs" % [state.rings.size(),simulation.elapsed_seconds]
	if simulation.ended:
		feedback_label.text = "Core lost. Survived %.1fs, %d kills." % [simulation.elapsed_seconds, run_kill_count]
	elif not last_error.is_empty():
		feedback_label.text = "Live test stopped. Simulation error."
	else:
		var quote := last_expansion_result
		if not quote.ok and "occup" in " ".join(quote.errors).to_lower():
			expand_button.text = "Ring Plate — ring occupied"
			expand_button.tooltip_text = "Machines occupy the proposed ring."
		else:
			expand_button.tooltip_text = "[Q] Ring Plate. Purchase the next whole ring immediately."

func _compact_live_buttons() -> void:
	for entry in [[wall_button,&"wall"],[armor_button,&"armor"],[repair_node_button,&"repair_node"],[debris_field_button,&"debris_field"],[tractor_lane_button,&"tractor_lane"],[occlusion_screen_button,&"occlusion_screen"]]:
		if entry[0] != null:
			entry[0].text = "[%s] %s" % [TOOL_LABELS[entry[1]],entry[0].text.replace(" energy", "")]
			entry[0].tooltip_text = _mode_prompt(entry[1])
	if repair_button != null:
		repair_button.text = "[T] Repair Wedge - inspect cost"
		reclaim_button.text = "[Y] Reclaim Ring - inspect cost"
		repair_button.tooltip_text = _mode_prompt(&"repair")
		reclaim_button.tooltip_text = _mode_prompt(&"reclaim")
	for entry in [[focused_flare_button,"Z"],[emp_burst_button,"X"]]:
		if entry[0] != null:
			entry[0].text = "[%s] %s" % [entry[1],entry[0].text]
			entry[0].add_theme_font_size_override("font_size",roundi(16*ui_font_scale) if industrial_ui else 14)
			entry[0].tooltip_text = "Select targeting, then click the world to cast once. Right click cancels."
	ui_panel.reset_size()

func _layout_ui() -> void:
	super._layout_ui()
	var viewport_size := get_viewport_rect().size
	if ring_status_hud != null:
		ring_status_hud.position = Vector2(viewport_size.x-172, 74)
	if combat_label != null:
		combat_label.position = Vector2(220,10)
	if solar_panel != null:
		solar_panel.position = Vector2(12, viewport_size.y-72)

func _tool_context(kind: StringName) -> String:
	if kind == &"rebuild_relay": return "Rebuild Relay active. Click the ring; Esc cancels."
	if kind == &"tractor_lane":
		return "Tractor %s active. Click an empty slot; Esc cancels." % ("CW" if tractor_direction == 1 else "CCW")
	if kind == &"debris_field":
		return "Debris active: blocks outer boundary. Click an empty slot."
	return super._tool_context(kind)

func _has_active_tool() -> bool:
	return ability_mode != &"" or super._has_active_tool()

func _extra_key(key: Key) -> bool:
	match key:
		KEY_Z: choose_ability(&"focused_flare")
		KEY_X: choose_ability(&"emp_burst")
		KEY_F: toggle_tractor_direction()
		_: return super._extra_key(key)
	return true

func _can_build() -> bool:
	return super._can_build() and last_error.is_empty() and (simulation == null or not simulation.ended)

func _sync_display_grid() -> void:
	var extent := maxi(1, ring_limit)
	if unbounded_expansion:
		extent = maxi(extent, state.rings.size() + 1)
	if extent != ring_count:
		rebuild_grid(extent, true)

func _supports_mode(kind: StringName) -> bool:
	return kind in [&"wall", &"armor", &"repair_node", &"repair", &"reclaim", &"rebuild_relay"] or kind in TERRAIN_KINDS or super._supports_mode(kind)

func toggle_tractor_direction() -> void:
	tractor_direction = -tractor_direction
	tractor_direction_button.text = "[F] Tractor: " + ("Clockwise" if tractor_direction == 1 else "Counterclockwise")
	if build_mode == &"tractor_lane":
		feedback_label.text = "Tractor: " + ("Clockwise" if tractor_direction == 1 else "Counterclockwise")

func _mode_prompt(kind: StringName) -> String:
	if kind == &"":
		return "Choose a build option, then select its wedge or slot."
	match kind:
		&"debris_field": return "Blocks the wedge's outer boundary. Place in an empty owned slot. Right click cancels."
		&"occlusion_screen": return "Slows surface movement in the same outward wedge column. Place in an empty owned slot. Right click cancels."
		&"tractor_lane": return "Place a %s Tractor Lane in an empty owned slot. Right click cancels." % ("clockwise" if tractor_direction == 1 else "counterclockwise")
		&"wall": return "Click an intact owned wedge for its outer-edge Wall. Right click cancels."
		&"armor": return "Click an empty slot on an intact owned wedge for Armor Plating. Right click cancels."
		&"repair_node": return "Click an empty slot on an intact owned wedge for a Repair Node. Right click cancels."
		&"rebuild_relay": return "Click a ring with a damaged Relay to rebuild it. Right click cancels."
		&"repair": return "Click a damaged owned wedge to repair it. Right click cancels."
		&"reclaim": return "Click a collapsed ring to reclaim it."
		_: return super._mode_prompt(kind)

func _record_command(action: String, args: Dictionary, result: Dictionary) -> Dictionary:
	if application_host != null:
		application_host.record_command(action,args,result)
	return result

func _place_build(ring: int, wedge: int, slot: int, kind: StringName) -> Dictionary:
	recording_build = true
	var result := _place_build_impl(ring,wedge,slot,kind)
	recording_build = false
	return _record_command("place_build",{"ring":ring,"wedge":wedge,"slot":slot,"kind":String(kind),"direction":tractor_direction},result)

func _place_build_impl(ring: int, wedge: int, slot: int, kind: StringName) -> Dictionary:
	if not _mode_available(kind): return RingPurchaseRules.failure("Tool locked: unlock it in the progression shop")
	if kind == &"rebuild_relay": return simulation.rebuild_relay(ring)
	if kind in TERRAIN_KINDS:
		return simulation.place_terrain(ring,wedge,slot,kind,tractor_direction)
	match kind:
		&"wall": return simulation.place_wall(ring, wedge)
		&"armor": return simulation.place_armor(ring, wedge, slot)
		&"repair_node": return simulation.place_repair_node(ring, wedge, slot)
		&"repair": return simulation.repair_wedge(ring, wedge)
		_: return super._place_build(ring, wedge, slot, kind)

func _reclaim_ring(ring: int) -> Dictionary:
	return _record_command("reclaim_ring",{"ring":ring},simulation.reclaim_ring(ring))

func _active_wall(cell: Vector2i) -> bool:
	return _cell_owned(cell) and state.rings[cell.x].wedges[cell.y].hp > 0 and state.rings[cell.x].wedges[cell.y].has("wall")

func _refresh_wall_edges() -> void:
	var active: Dictionary = {}
	for cell in cells:
		if _active_wall(cell):
			if wall_edges.has(cell):
				active[cell] = wall_edges[cell]
			else:
				var points := PackedVector2Array()
				for step in range(ARC_STEPS + 1):
					points.append(_boundary_direction(cell, step) * grid.ring_bounds(cell.x).y)
				active[cell] = points
	wall_edges = active

func _update_status() -> void:
	super._update_status()
	if selected_slot >= 0 and _cell_owned(selected_cell):
		var occupant: Dictionary = state.rings[selected_cell.x].wedges[selected_cell.y].occupants.get(selected_slot,{})
		if not occupant.is_empty():
			var lines := status_label.text.split("\n")
			lines[0] += " / " + BUILDING_NAMES.get(occupant.kind,str(occupant.kind))
			if occupant.kind == &"tractor_lane":
				lines[0] += " / " + ("Clockwise" if occupant.direction == 1 else "Counterclockwise")
			if occupant.kind == &"occlusion_screen":
				lines[0] += " / Rings %d–%d at %s%% speed" % [selected_cell.x+1,selected_cell.x+int(profile.value("occlusion_screen.shadow_rings")),str(float(profile.value("occlusion_screen.speed_multiplier"))*100.0)]
			status_label.text = "\n".join(lines)
	if _active_wall(selected_cell):
		var lines := status_label.text.split("\n")
		lines[0] += " / Wall HP: %s" % str(snappedf(state.rings[selected_cell.x].wedges[selected_cell.y].wall.hp, 0.01))
		status_label.text = "\n".join(lines)
	if simulation != null and build_mode in [&"repair", &"reclaim"]:
		var cell := quote_preview_cell if quote_preview_cell.x > 0 else selected_cell
		if cell.x > 0 and state.rings.has(cell.x):
			var quote := simulation.quote_repair(cell.x, cell.y) if build_mode == &"repair" else simulation.quote_reclaim(cell.x)
			if quote.ok:
				var lines := status_label.text.split("\n")
				lines[0] = "%s ring %d / wedge %d — %s energy" % ["Repair" if build_mode == &"repair" else "Reclaim", cell.x, cell.y, str(quote.quote.cost)]
				status_label.text = "\n".join(lines)
	if industrial_ui:
		var power := _selected_power_text()
		if not power.is_empty(): status_label.text += "\n" + power

func _selected_power_text() -> String:
	if not _cell_owned(selected_cell) or simulation == null: return ""
	var record: Dictionary = state.rings[selected_cell.x]
	if record.get("collapsed",false): return "Power chain interrupted: collapsed ring."
	var text := "Power %.0f / %.0f   Relay %.0f / %.0f" % [PowerRules.ring_demand(state,profile,selected_cell.x),PowerRules.ring_output(state,profile,selected_cell.x),record.relay_hp,record.relay_max_hp]
	var boundary := PowerRules.chain_boundary(state)
	if selected_cell.x > boundary: text += "   Brownout: inward break at ring %d" % (boundary+1)
	if build_mode == &"rebuild_relay":
		var quote := simulation.quote_rebuild_relay(selected_cell.x)
		text += "   Rebuild %s energy" % str(quote.quote.cost) if quote.ok else "   " + " ".join(quote.errors)
	return text

func choose_build(kind: StringName) -> void:
	if not _mode_available(kind):
		feedback_label.text = "Locked. Unlock this tool in the progression shop."
		return
	ability_mode = &""
	ability_aim_valid = false
	quote_preview_cell = Vector2i(-1, -1)
	quote_preview_slot = -1
	super.choose_build(kind)
	queue_redraw()

func choose_ability(kind: StringName) -> void:
	if not prepared_run.is_empty() and kind not in prepared_run.abilities:
		feedback_label.text = "Locked. Unlock this ability in the progression shop."
		return
	if kind not in ABILITY_NAMES or menu_open or get_tree().paused or not _can_build():
		return
	choose_build(&"")
	var remaining: float = simulation.abilities_snapshot().get(kind,0.0)
	if remaining > 0:
		feedback_label.text = "%s is cooling down: %.1f s remaining." % [ABILITY_NAMES[kind],remaining]
		return
	ability_mode = kind
	feedback_label.text = "Aim a sector from the core, then click to cast. Right click cancels." if kind == &"focused_flare" else "Aim the circle, then click to cast. Right click cancels."
	queue_redraw()

func set_menu_open(open: bool) -> void:
	if application_host != null and open != menu_open:
		application_host.record_marker("pause" if open else "resume")
	if open:
		ability_mode = &""
		ability_aim_valid = false
	super.set_menu_open(open)

func _input(event: InputEvent) -> void:
	if application_host != null and (application_host.state not in ["playing","tutorial"] or application_host.lock_notice != null):
		return
	# A GUI-consumed motion must not leave a target outline beneath its panel.
	if (event is InputEventMouseMotion or event is InputEventMouseButton) and ability_mode != &"":
		ability_aim_valid = false
		queue_redraw()
	super._input(event)

func _update_ability_aim(screen_point: Vector2) -> PolarPosition:
	camera.force_update_scroll()
	ability_aim_world = get_viewport().get_canvas_transform().affine_inverse() * screen_point
	ability_aim_valid = false
	if not ability_aim_world.is_finite():
		return null
	var radius := sqrt(float(ability_aim_world.x)*ability_aim_world.x+float(ability_aim_world.y)*ability_aim_world.y)
	var extent: float = floor(radius/PolarGrid.RING_WIDTH)+1.0
	if not is_finite(extent) or extent >= float(REPRESENTATIONAL_RING_LIMIT):
		return null
	# Conversion support has no cells/polygons and imposes no aiming-distance cap.
	var aim_grid := PolarGrid.new(maxi(1,int(extent)))
	var aim := aim_grid.world_to_polar(ability_aim_world)
	ability_aim_valid = aim != null and (ability_mode != &"focused_flare" or ability_aim_world.length_squared() > 0)
	queue_redraw()
	return aim

func ability_outline() -> PackedVector2Array:
	var points := PackedVector2Array()
	if not ability_aim_valid or ability_mode == &"":
		return points
	if ability_mode == &"focused_flare":
		var radius: float = profile.value("focused_flare.range_ring_widths") * PolarGrid.RING_WIDTH
		if not is_finite(radius):
			return points
		var half_arc := deg_to_rad(float(profile.value("focused_flare.arc_degrees"))) * 0.5
		points.append(Vector2.ZERO)
		for step in range(65):
			points.append(Vector2.from_angle(ability_aim_world.angle()-half_arc+2.0*half_arc*step/64.0)*radius)
		points.append(Vector2.ZERO)
	else:
		var radius: float = profile.value("emp_burst.radius_ring_widths") * PolarGrid.RING_WIDTH
		if not is_finite(radius):
			return points
		for step in range(65):
			points.append(ability_aim_world+Vector2.from_angle(TAU*step/64.0)*radius)
	for point in points:
		if not point.is_finite():
			return PackedVector2Array()
	return points

func _unhandled_input(event: InputEvent) -> void:
	if application_host != null and (application_host.state not in ["playing","tutorial"] or application_host.lock_notice != null):
		return
	if ability_mode != &"" and not menu_open and not get_tree().paused and _can_build():
		if event is InputEventMouseMotion or (event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]):
			super._unhandled_input(event)
			_update_ability_aim(event.position)
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var aim := _update_ability_aim(event.position)
			if not ability_aim_valid:
				_record_command("cast_ability",{"kind":String(ability_mode),"invalid_aim":true},RingPurchaseRules.failure("Invalid aim"))
				feedback_label.text = "Choose a finite world point; Flare needs a bearing away from the core center."
				return
			var kind := ability_mode
			var cast := simulation.cast_ability(kind,aim) if prepared_run.is_empty() or kind in prepared_run.abilities else RingPurchaseRules.failure("Ability locked")
			_record_command("cast_ability",{"kind":String(kind),"ring":aim.ring,"wedge":aim.wedge,"radial_fraction":aim.radial_fraction,"angular_fraction":aim.angular_fraction},cast)
			if cast.ok:
				run_kill_count += cast.events.kill_ids.size()
				ability_mode = &""
				ability_aim_valid = false
				sync_simulation()
				feedback_label.text = "%s cast: %d targets hit." % [ABILITY_NAMES[kind],cast.events.hits.size()]
			else:
				feedback_label.text = "Cannot cast: " + " ".join(cast.errors)
			refresh_view()
			return
	if event is InputEventMouseMotion and not menu_open and not get_tree().paused and build_mode in [&"repair", &"reclaim"]:
		camera.force_update_scroll()
		var point: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		quote_preview_cell = grid.world_to_cell(point)
		_update_status()
	super._unhandled_input(event)

func _quote_expansion() -> Dictionary:
	var started := Time.get_ticks_usec()
	var result := super._quote_expansion() if simulation == null else simulation.quote_expansion()
	quote_cpu_usec += Time.get_ticks_usec() - started
	return result

func _purchase_ring() -> Dictionary:
	return _record_command("purchase_ring",{},simulation.purchase_ring())

func _place_weapon(ring: int, wedge: int, slot: int, kind: StringName) -> Dictionary:
	if not _mode_available(kind):
		var rejected := RingPurchaseRules.failure("Weapon locked")
		return rejected if recording_build else _record_command("place_weapon",{"ring":ring,"wedge":wedge,"slot":slot,"kind":String(kind)},rejected)
	var result := simulation.place_weapon(ring,wedge,slot,kind)
	return result if recording_build else _record_command("place_weapon",{"ring":ring,"wedge":wedge,"slot":slot,"kind":String(kind)},result)

func _purchase_error(errors: PackedStringArray) -> String:
	var details := " ".join(errors).to_lower()
	if "living machine occupies candidate ring" in details:
		return "Cannot expand: machines occupy the proposed ring."
	if build_mode == &"rebuild_relay":
		return "Relay rebuild rejected: " + " ".join(errors)
	if "seal" in details:
		return "Blocked: this would seal the outer perimeter."
	if "trap" in details:
		return "Blocked: this would trap a living machine."
	if "already has a tractor lane" in details:
		return "This wedge already has a Tractor Lane."
	if build_mode == &"repair" and "occup" in details:
		return "Cannot repair: machines occupy the broken wedge."
	if build_mode == &"wall":
		return "Not enough energy." if "insufficient" in details else "Choose an intact owned wedge without a wall."
	if "occup" in details and build_mode in [&"expand", &"reclaim"]:
		return "Cannot reclaim: machines occupy the ring." if build_mode == &"reclaim" else "Cannot expand: machines occupy the proposed ring."
	if build_mode in [&"armor", &"repair_node"] and "power" in details:
		return "Not enough power capacity on this ring."
	if build_mode == &"armor" and "stack" in details:
		return "This wedge already has the maximum Armor Plating."
	if build_mode == &"repair" and "full hp" in details:
		return "That wedge is already at full HP."
	if build_mode == &"repair" and "collapsed" in details:
		return "Repair only works on a wedge whose ring hasn't collapsed."
	if build_mode == &"reclaim" and "collapsed" in details:
		return "Reclaim only works on a ring that has fully collapsed."
	return super._purchase_error(errors)

func _cell_owned(cell: Vector2i) -> bool:
	return super._cell_owned(cell) and not state.rings[cell.x].get("collapsed", false)

func _cell_description(cell: Vector2i) -> String:
	if setup_ok and state.rings.has(cell.x):
		if state.rings[cell.x].get("collapsed", false):
			return "collapsed"
		if state.rings[cell.x].wedges[cell.y].hp <= 0:
			return "broken"
	return super._cell_description(cell)

func _cell_shade(cell: Vector2i) -> float:
	if _cell_description(cell) in ["collapsed", "broken"]:
		return 0.06
	return super._cell_shade(cell)

func _slot_count(ring: int, wedge: int) -> int:
	if _cell_description(Vector2i(ring, wedge)) in ["collapsed", "broken"]:
		return 0
	return super._slot_count(ring, wedge)

func _draw() -> void:
	var started := Time.get_ticks_usec()
	super._draw()
	_draw_combat_feedback()
	var target_outline := ability_outline()
	if not target_outline.is_empty():
		draw_polyline(target_outline,Color.WHITE,1.5/camera.zoom.x,true)
	for edge in wall_edges.values():
		draw_polyline(edge, Color(0.95, 0.95, 0.95), 3.0 / camera.zoom.x, true)
	for warning in tunneler_warnings:
		draw_circle(warning.point, 3.0 / camera.zoom.x, Color(0.95, 0.95, 0.95), false, 1.0 / camera.zoom.x, true)
		draw_set_transform(warning.point + Vector2(12, -12) / camera.zoom.x, 0, Vector2.ONE / camera.zoom.x)
		draw_string(ThemeDB.fallback_font, Vector2.ZERO, "Tunneler %.1f s" % warning.remaining, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.95, 0.95, 0.95))
		draw_set_transform(Vector2.ZERO)
	if camera != null and not is_equal_approx(marker_zoom, camera.zoom.x):
		_update_machine_markers()
	draw_cpu_usec = Time.get_ticks_usec() - started

func _ring_status_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if not setup_ok or not state.has("rings"):
		return records
	for ring in range(1, state.rings.size() + 1):
		var ring_record: Dictionary = state.rings[ring]
		var wedges: Array[String] = []
		for wedge in range(1, 13):
			var plate: Dictionary = ring_record.wedges[wedge]
			var hp: float = plate.hp
			# Read each wedge's own authoritative max_hp (RingPurchaseRules/BuildingRules
			# set it at creation); a recomputed profile value would go stale the moment
			# any rule grants a wedge a nonstandard maximum (e.g. future Armor Plating).
			var max_hp: float = plate.max_hp
			if hp <= 0:
				wedges.append("broken")
			elif max_hp > 0 and hp / max_hp < WEDGE_STATUS_CRITICAL_FRACTION:
				wedges.append("critical")
			else:
				wedges.append("ok")
		var relay: Dictionary = ring_record.get("relay", {})
		records.append({"collapsed": ring_record.get("collapsed", false), "wedges": wedges, "relay_active": not relay.is_empty() and float(ring_record.get("relay_hp",1.0)) > 0, "brownout": ring > PowerRules.chain_boundary(state)})
	return records

func _on_ring_status_focus(ring: int, wedge: int) -> void:
	if menu_open:
		return
	if ring == 0:
		camera.position = Vector2.ZERO
		selected_cell = Vector2i.ZERO
	elif state.rings.has(ring):
		var turns := float(wedge % PolarGrid.WEDGE_COUNT) / PolarGrid.WEDGE_COUNT
		var radius := PolarGrid.CORE_RADIUS + (float(ring) - 0.5) * PolarGrid.RING_WIDTH
		camera.position = Vector2(radius * sin(turns * TAU), -radius * cos(turns * TAU))
		selected_cell = Vector2i(ring, wedge)
	else:
		return
	selected_slot = -1
	camera.force_update_scroll()
	_update_status()
	queue_redraw()


func _mode_available(kind: StringName) -> bool:
	return kind == &"" or prepared_run.is_empty() or kind in prepared_run.build_modes

func _refresh_access() -> void:
	if prepared_run.is_empty(): return
	for entry in [[flak_button,&"flak"],[mass_driver_button,&"mass_driver"],[emp_node_button,&"emp_node"],[lance_emitter_button,&"lance_emitter"],[point_defense_button,&"point_defense"],[debris_field_button,&"debris_field"],[tractor_lane_button,&"tractor_lane"],[occlusion_screen_button,&"occlusion_screen"]]:
		if entry[0] != null and not _mode_available(entry[1]):
			entry[0].disabled = true
			entry[0].text += " [locked]"
			entry[0].tooltip_text = "Unlock in the progression shop."
	for entry in [[focused_flare_button,&"focused_flare"],[emp_burst_button,&"emp_burst"]]:
		if entry[0] != null and entry[1] not in prepared_run.abilities:
			entry[0].disabled = true
			entry[0].text += " [locked]"
			entry[0].tooltip_text = "Unlock in the progression shop."

func apply_interface_settings(settings: Dictionary) -> void:
	interface_settings = settings.duplicate(true)
	ui_font_scale = float(settings.get("ui_scale",1.0))
	if not interface_settings.effects: hit_effects.clear()
	if not industrial_ui or status_label == null: return
	var kit = load("res://src/presentation/industrial_theme.gd")
	var theme: Theme = kit.make(float(settings.get("ui_scale",1.0)))
	if instrument_panel == null:
		instrument_panel = PanelContainer.new()
		instrument_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_label.get_parent().add_child(instrument_panel)
		status_label.get_parent().move_child(instrument_panel,0)
	instrument_panel.position = Vector2(10,6)
	instrument_panel.size = Vector2(get_viewport_rect().size.x-20,110)
	for control in status_label.get_parent().get_children():
		if control is Control: control.theme = theme
	tabs.add_theme_font_size_override("font_size",roundi(16*ui_font_scale))
	ui_panel.custom_minimum_size.x = 288
	ui_panel.reset_size()
	status_label.position = Vector2(18,48)
	status_label.size = Vector2(1080,48)
	feedback_label.position = Vector2(324,124)
	feedback_label.size = Vector2(900,72)
	ui_panel.position = Vector2(18,156)
	catalogue_toggle.position = Vector2(18,124)
	for category in tabs.get_children():
		for button in category.get_children():
			if button is Button: button.add_theme_font_size_override("font_size",roundi(16*ui_font_scale))
	call_deferred("_industrial_layout")
	queue_redraw()

func _industrial_layout() -> void:
	if not industrial_ui: return
	var viewport_size := get_viewport_rect().size
	menu_button.reset_size()
	help_button.reset_size()
	menu_button.position = Vector2(viewport_size.x-18-menu_button.size.x,8)
	help_button.position = Vector2(menu_button.position.x-12-help_button.size.x,8)
	solar_panel.reset_size()
	solar_panel.position = Vector2(18,viewport_size.y-18-solar_panel.get_combined_minimum_size().y)
	ui_panel.reset_size()
	ui_panel.size = ui_panel.get_combined_minimum_size()
	ui_panel.position.y = catalogue_toggle.position.y+catalogue_toggle.size.y+8
	feedback_label.position.x = maxf(324,ui_panel.position.x+ui_panel.size.x+18)
	feedback_label.size.x = maxf(240,viewport_size.x-feedback_label.position.x-210)
	ring_status_hud.tooltip_text = "Click to focus. Dot: critical; X: broken; slashed arc: brownout; circle: active Relay."

func _capture_hits(events: Dictionary) -> void:
	if not interface_settings.effects: return
	for hit in events.get("hits",[]):
		if not hit.has("weapon_id") or not effect_positions.has(hit.target_id): continue
		var parts := str(hit.weapon_id).split(":")
		if parts.size() != 3: continue
		var ring := int(parts[0])
		var wedge := int(parts[1])
		var slot := int(parts[2])
		if not state.rings.has(ring): continue
		var plate: Dictionary = state.rings[ring].wedges[wedge]
		if not plate.occupants.has(slot) or plate.slot_count <= 0: continue
		var position := BuildingRules.slot_position(ring,wedge,slot,plate.slot_count)
		var source := grid.polar_to_world(position)
		if hit_effects.size() >= 256: hit_effects.pop_front()
		hit_effects.append({"from":source,"to":effect_positions[hit.target_id],"kind":plate.occupants[slot].kind,"remaining":0.12 if interface_settings.reduced_motion else 0.2})

func _draw_combat_feedback() -> void:
	var zoom := camera.zoom.x
	for effect in hit_effects:
		var color := Color(0.94,0.76,0.43,clampf(effect.remaining/0.2,0.0,1.0))
		if effect.kind == &"emp_node":
			draw_circle(effect.to,8.0/zoom,color,false,1.0/zoom)
		else:
			draw_line(effect.from,effect.to,color,(2.0 if effect.kind == &"lance_emitter" else 1.0)/zoom)
	for kind in elite_points:
		var labeled := false
		for point in elite_points[kind]:
			if not labeled:
				draw_set_transform(point+Vector2(10,-10)/zoom,0,Vector2.ONE/zoom)
				draw_string(ThemeDB.fallback_font,Vector2.ZERO,str(kind).capitalize(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
				draw_set_transform(Vector2.ZERO)
				labeled = true
			var radius := (9.0 if kind == &"assembler" else 5.0)/zoom
			var color := Color(1.0,0.51,0.45)
			match kind:
				&"foundry": draw_rect(Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2),color,false,1.5/zoom)
				&"transfer": draw_polyline(PackedVector2Array([point+Vector2(-radius,-radius),point+Vector2(radius,0),point+Vector2(-radius,radius)]),color,2.0/zoom)
				&"sapper":
					draw_line(point-Vector2.ONE*radius,point+Vector2.ONE*radius,color,2.0/zoom)
					draw_line(point+Vector2(-radius,radius),point+Vector2(radius,-radius),color,2.0/zoom)
				&"breacher": draw_colored_polygon(PackedVector2Array([point+Vector2(0,-radius),point+Vector2(radius,0),point+Vector2(0,radius),point+Vector2(-radius,0)]),color)
				_: draw_circle(point,radius,color,false,2.0/zoom)
