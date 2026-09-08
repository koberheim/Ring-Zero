extends "res://tests/presentation/test_weapon_catalogue_view.gd"

func quiet_main() -> void:
	var loaded := BalanceProfile.load_json("res://data/balance/testing.json")
	var tuned: Dictionary = loaded.profile.with_overrides({"pressure": {"spawn_per_second": 0}})
	check(tuned.ok, "Quiet growing-world profile valid")
	view.profile = tuned.profile
	view._start_new_run()
	check(view.state.energy == 200 and view.ring_count == 3 and view.cells.size() == 37, "Unbounded main startup keeps normal funds and three-band preview")
	view.simulation.state.energy = 1000000
	view.sync_simulation()

func aim_at_slot(ring: int, wedge: int, slot: int) -> void:
	view.camera.position = view.grid.polar_to_world(BuildingRules.slot_position(ring, wedge, slot, maxi(1, view._slot_count(ring, wedge))))
	view.camera.force_update_scroll()

func grow_to_twelve() -> void:
	view.tabs.current_tab = 1
	await process_frame
	for ring in range(2, 13):
		aim_at_slot(ring, 3, 0)
		var position: Vector2 = view.camera.position
		var zoom: Vector2 = view.camera.zoom
		control_click(view.expand_button)
		slot_click(ring, 3, 0)
		check(view.state.rings.size() == ring and view.state.rings[ring].relay == {"active": true}, "Actual Ring Plate input purchases ring %d" % ring)
		check(view.grid.ring_count == maxi(3, ring + 1) and view.cells.size() == 1 + 12 * maxi(3, ring + 1), "Only owned rings plus preview allocated at ring %d" % ring)
		check(view.camera.position == position and view.camera.zoom == zoom and view.camera.rotation == 0 and view.selected_cell == Vector2i(ring, 3) and view.selected_slot == 0, "Growth preserves camera and purchase selection at ring %d" % ring)
		var same_grid: PolarGrid = view.grid
		view.sync_simulation()
		check(view.grid == same_grid and view.target_grid.ring_count == view.ring_count, "Unchanged extent avoids geometry rebuild and marker support follows ring %d" % ring)

func hud_focus(ring: int, wedge: int) -> void:
	var hud: RingStatusHud = view.ring_status_hud
	var radius := hud.CORE_RADIUS + (ring - 0.5) * hud.BAND_WIDTH
	click(hud.global_position + hud._point(radius, float(wedge % 12) / 12))

func large_controls() -> void:
	view.tabs.current_tab = 0
	await process_frame
	hud_focus(12, 4)
	check(view.selected_cell == Vector2i(12, 4) and view.grid.world_to_cell(view.camera.position) == Vector2i(12, 4), "Actual HUD focus ring 12 maps to selectable world geometry")
	control_click(view.flak_button)
	slot_click(12, 4, 2)
	check(view.state.rings[12].wedges[4].occupants[2].kind == &"flak" and view.selected_slot == 2, "Actual ring 12 weapon slot placement")
	view.tabs.current_tab = 1
	await process_frame
	control_click(view.wall_button)
	slot_click(12, 4, 2)
	check(view.wall_edges.has(Vector2i(12, 4)), "Ring 12 wall has displayed edge geometry")
	view.simulation.state.rings[12].wedges[4].hp -= 20
	view.sync_simulation()
	control_click(view.repair_button)
	hover_slot(12, 4, 2)
	check(view.status_label.text.begins_with("Repair ring 12 / wedge 4"), "Ring 12 repair quote available")
	slot_click(12, 4, 2)
	check(view.state.rings[12].wedges[4].hp == view.state.rings[12].wedges[4].max_hp, "Actual ring 12 repair succeeds")
	var ring: Dictionary = view.simulation.state.rings[11]
	ring.collapsed = true
	ring.relay = {}
	ring.erase("relay_hp")
	ring.erase("relay_max_hp")
	for plate in ring.wedges.values():
		plate.hp = 0
		plate.occupants = {}
		plate.erase("wall")
	view.sync_simulation()
	hud_focus(11, 4)
	control_click(view.reclaim_button)
	# Collapsed rings have no slots; any position within the band confirms reclaim now.
	var point: Vector2 = view.grid.polar_to_world(BuildingRules.slot_position(11, 4, 0, maxi(1, view._slot_count(11, 4))))
	click(root.get_canvas_transform() * point)
	check(not view.state.rings[11].get("collapsed", false) and view.state.rings[11].relay == {"active": true} and view.state.rings.has(12), "Actual ring 11 reclaim preserves outer ring 12")
	var machine := spawn_at(13, 4, 0.8)
	ticks(1)
	check(view.last_error.is_empty() and view.rendered_targets.size() == 1 and view.target_points[0].is_equal_approx(view.target_grid.polar_to_world(view.simulation.pool.payload_for(machine).position)), "Large-world machine marker uses synchronized support")
	view.simulation.pool.release(machine)
	view.sync_simulation()
	var position: Vector2 = view.camera.position
	button(MOUSE_BUTTON_MIDDLE, true, Vector2(900, 700))
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(920, 710)
	motion.relative = Vector2(20, 10)
	root.push_input(motion)
	button(MOUSE_BUTTON_MIDDLE, false, view.feedback_label.get_global_rect().get_center())
	var zoom: Vector2 = view.camera.zoom
	button(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(900, 700))
	check(view.camera.position != position and not view.dragging and view.camera.zoom.x < zoom.x and view.camera.rotation == 0, "Large world pan zoom and cross-panel drag release")
	view.simulation.state.energy = 0
	view.sync_simulation()
	aim_at_slot(13, 3, 0)
	control_click(view.expand_button)
	check(view.state.rings.size() == 12 and view.ring_count == 13 and view.feedback_label.text.contains("Not enough energy"), "Rejected ring 13 purchase cannot grow state or displayed extent")
	view.choose_build(&"")

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	await process_frame
	check(view.unbounded_expansion, "Main scene enables unbounded expansion")
	quiet_main()
	await grow_to_twelve()
	await large_controls()
	control_click(view.menu_button)
	await process_frame
	control_click(view.retry_button)
	check(not paused and not view.menu_open and view.state.rings.size() == 1 and view.state.energy == 200 and view.ring_count == 3 and view.cells.size() == 37 and view.wall_edges.is_empty(), "Retry resets funds world extent walls and owned history")
	check(view.camera.position == Vector2.ZERO and view.selected_cell == Vector2i(-1, -1) and view.selected_slot == -1 and view.target_grid.ring_count == 3 and view.rendered_targets.is_empty(), "Retry resets camera selection and marker support without stale large geometry")
	print("Growing world view checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
