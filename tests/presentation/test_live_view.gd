extends SceneTree
var checks := 0
var failures := 0
var view: Node2D

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

func control_click(control: Control) -> void:
	click(control.get_global_rect().get_center())

func slot_click(ring: int, wedge: int, slot: int) -> void:
	view.camera.force_update_scroll()
	var position := BuildingRules.slot_position(ring, wedge, slot, maxi(1, view._slot_count(ring, wedge)))
	click(root.get_canvas_transform() * view.grid.polar_to_world(position))

func fixture(overrides: Dictionary = {}) -> void:
	view.unbounded_expansion = false
	var loaded := BalanceProfile.load_json("res://data/balance/testing.json")
	var changes := {"pressure": {"spawn_per_second": 0}}
	for key in overrides:
		changes[key] = overrides[key]
	var tuned: Dictionary = loaded.profile.with_overrides(changes)
	check(tuned.ok, "Fixture profile valid")
	var created := LiveSimulation.create(tuned.profile, 3)
	check(created.ok, "Fixture simulation valid")
	view.profile = tuned.profile
	view.simulation = created.simulation
	view.clock = FixedStepClock.new(60.0, view._simulation_tick)
	view.last_error = ""
	view.build_mode = &""
	view.sync_simulation()

func spawn_at(ring: int, wedge: int, radial: float, hp: float = 1000.0, dps: float = 0.0, speed: float = 1.0) -> int:
	return view.simulation.pool.spawn({"position": PolarPosition.new(ring, wedge, radial, 0.5), "hp": hp, "damage_per_second": dps, "speed_ring_widths_per_second": speed})

func ticks(count: int) -> void:
	for tick in count:
		view._process(1.0 / 60.0)

func target_values() -> Array:
	var values := []
	for target in view.simulation.targets_snapshot():
		values.append([target.id, target.position.ring, target.position.wedge, target.position.radial_fraction, target.position.angular_fraction, target.hp])
	return values

func collapse_fixture() -> void:
	fixture()
	view.simulation.state.energy = 1000
	check(view.simulation.purchase_ring().ok, "Fixture buys surviving ring two")
	for wedge in range(1, 7):
		view.simulation.state.rings[1].wedges[wedge].hp = 0
	view.simulation.state.rings[1].wedges[7].hp = 0.01
	# Routing rejects embedded machines: this outer approach wedge is already open.
	view.simulation.state.rings[2].wedges[7].hp = 0
	spawn_at(2, 7, 0.0, 1000, 6)
	ticks(1)

func loss_fixture() -> void:
	fixture()
	var ring: Dictionary = view.simulation.state.rings[1]
	ring.collapsed = true
	ring.relay = {}
	ring.erase("relay_hp")
	ring.erase("relay_max_hp")
	for wedge in ring.wedges.values():
		wedge.hp = 0
		wedge.occupants = {}
	view.simulation.core_hp = 0.01
	spawn_at(1, 1, 0.0, 1000, 6)
	view._process(0.25)

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	await process_frame
	check(view.setup_ok and view.simulation != null and view.last_error.is_empty(), "Default live startup")
	check(view.state.energy == 200 and view.state.rings.keys() == [1], "Default state matches build startup")
	check(view.combat_label.text.contains("Core HP") and view.combat_label.text.contains("Active machines: 0"), "Live status visible")
	# D-033 testing tuning added a 10-second pressure.spawn_delay_seconds
	# preliminary-build window (2026-09-07); the default live profile's first
	# arrival isn't due until 10.5s in, so this needs to run well past that.
	ticks(660)
	check(view.simulation.pool.active_count() > 0 and view.rendered_targets.size() > 0, "Scheduled arrivals synchronized to rendering")
	check(view.simulation.elapsed_seconds > 10.9, "Fixed-step elapsed advances")
	fixture()
	var moving_id := spawn_at(3, 3, 0.5)
	ticks(1)
	var before_position: PolarPosition = view.rendered_targets[0].position
	ticks(30)
	var after_position: PolarPosition = view.rendered_targets[0].position
	check(after_position.ring < before_position.ring or after_position.radial_fraction < before_position.radial_fraction, "Machine moves inward")
	check(view.rendered_targets[0].id == moving_id, "Lifetime identity rendered")
	check(view.marker_instances.instance_count == view.rendered_targets.size(), "One marker instance per target")
	check(view.target_points[0].is_equal_approx(view.target_grid.polar_to_world(after_position)), "Cached marker point derives from current polar snapshot")
	button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(950, 700))
	ticks(1)
	check(is_equal_approx(view.marker_zoom, view.camera.zoom.x), "Marker transforms refreshed after zoom")
	button(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(950, 700))
	fixture()
	spawn_at(2, 12, 0.0, float(view.profile.value("flak.damage")) * 0.5)
	var initial_energy: float = view.state.energy
	ticks(1)
	check(view.simulation.pool.active_count() == 0, "Automatic Flak kill without player firing")
	check(view.state.energy == initial_energy + view.profile.value("economy.kill_energy"), "Kill energy banked once")
	var earned: float = view.state.energy
	ticks(10)
	check(view.state.energy == earned, "No duplicate reward")
	fixture()
	control_click(view.flak_button)
	check(view.build_mode == &"flak" and view.state.energy == 200, "Normal UI arms without clickthrough")
	slot_click(1, 3, 0)
	check(view.simulation.state.energy == 180 and view.simulation.state.rings[1].wedges[3].occupants[0].kind == &"flak", "Placement persists through simulation API")
	check(view.state == view.simulation.state and view.build_mode == &"flak", "View follows persisted purchase")
	view.flak_button.pressed.emit()
	var before_select: Vector2i = view.selected_cell
	var before_state: Dictionary = view.state.duplicate(true)
	click(view.ui_panel.get_global_rect().position + Vector2(1,1))
	check(view.state == before_state and view.selected_cell == before_select, "Live panel no placement through")
	button(MOUSE_BUTTON_RIGHT, true, view.ui_panel.get_global_rect().get_center())
	button(MOUSE_BUTTON_RIGHT, false, view.ui_panel.get_global_rect().get_center())
	check(view.build_mode == &"" and view.state == before_state and view.selected_cell == before_select, "Panel right cancellation retained")
	button(MOUSE_BUTTON_MIDDLE, true, Vector2(950, 700))
	button(MOUSE_BUTTON_MIDDLE, false, view.ui_panel.get_global_rect().get_center())
	check(not view.dragging, "Panel middle release retained")
	fixture()
	view.simulation.state.energy = 1000
	view.sync_simulation()
	view.tabs.current_tab = 1
	await process_frame
	var quoted_cost: float = view.simulation.quote_expansion().quote.cost
	control_click(view.expand_button)
	slot_click(2, 3, 1)
	check(view.simulation.state.rings.size() == 2 and view.state.energy == 1000 - quoted_cost, "Live ring purchase persists with quoted deduction")
	check(view.simulation.state.rings[2].relay == {"active": true}, "Live ring purchase includes automatic relay")
	fixture()
	view.simulation.state.energy = 1000
	view.sync_simulation()
	spawn_at(2, 3, 0.5)
	before_state = view.state.duplicate(true)
	control_click(view.expand_button)
	check(view.state == before_state and view.simulation.state == before_state, "Occupied ring purchase has no mutation")
	check(view.feedback_label.text.contains("machines occupy"), "Occupied ring failure plain")
	check(view.expand_button.disabled and view.expand_button.text.contains("occupied"), "Occupied ring quote disables control")
	# Pause via GUI; root stays ALWAYS but neither clock nor simulation advances.
	spawn_at(2, 12, 0.0, 1000, 6)
	ticks(10)
	check(not view.simulation.cooldowns.is_empty(), "Pause fixture exercises active weapon cooldown")
	control_click(view.menu_button)
	check(paused and view.menu_open, "Live menu pauses")
	var frozen_values := target_values()
	var frozen_state: Dictionary = view.state.duplicate(true)
	var frozen_cooldowns: Dictionary = view.simulation.cooldowns.duplicate(true)
	var frozen_hp: float = view.simulation.core_hp
	var frozen_elapsed: float = view.simulation.elapsed_seconds
	var frozen_ticks: int = view.clock.tick_count
	view._process(8.0)
	await process_frame
	slot_click(1, 4, 0)
	check(target_values() == frozen_values and view.state == frozen_state and view.simulation.cooldowns == frozen_cooldowns and view.simulation.core_hp == frozen_hp, "Pause freezes targets HP cooldowns energy and building")
	check(view.simulation.elapsed_seconds == frozen_elapsed and view.clock.tick_count == frozen_ticks, "Pause freezes elapsed and ticks")
	control_click(view.resume_button)
	ticks(1)
	check(not paused and view.clock.tick_count == frozen_ticks + 1, "Resume has no paused catchup")
	fixture()
	view.simulation.state.rings[1].wedges[3].hp = 0.01
	spawn_at(2, 3, 0.0, 1000, 6)
	ticks(1)
	check(view._cell_description(Vector2i(1, 3)) == "broken" and view._slot_count(1, 3) == 0, "Broken wedge loses active slots")
	check(view._cell_shade(Vector2i(1, 3)) < view._cell_shade(Vector2i(1, 4)), "Broken wedge darker")
	check(view.feedback_label.text.contains("broken"), "Wedge break feedback")
	check(view.ring_status_hud.ring_records.size() == 1 and view.ring_status_hud.ring_records[0].wedges[2] == "broken", "Ring status HUD reflects a broken wedge (D-024)")
	var hud_center: Vector2 = view.ring_status_hud.get_global_rect().get_center()
	var hud_focus: Array = []
	view.ring_status_hud.wedge_focus_requested.connect(func(ring: int, wedge: int): hud_focus.append([ring, wedge]))
	var broken_point := hud_center + Vector2(0, -(view.ring_status_hud.CORE_RADIUS + 0.5 * view.ring_status_hud.BAND_WIDTH))
	click(broken_point)
	check(hud_focus == [[1, 12]], "Clicking the HUD's north sector on ring 1 focuses wedge 12 (D-024 click-to-focus)")
	check(view.selected_cell == Vector2i(1, 12) and view.camera.position.is_equal_approx(Vector2(0, -PolarGrid.CORE_RADIUS - 0.5 * PolarGrid.RING_WIDTH)), "HUD focus click pans the camera to the chosen cell without changing world selection rules")
	click(hud_center)
	check(hud_focus[-1] == [0, 0] and view.selected_cell == Vector2i.ZERO and view.camera.position == Vector2.ZERO, "Clicking the HUD core focuses the core")
	collapse_fixture()
	check(view.state.rings[1].collapsed and not view._cell_owned(Vector2i(1, 12)), "Collapsed ring not presented as owned intact")
	check(view._slot_count(1, 12) == 0 and view.state.rings[1].wedges[12].occupants.is_empty(), "Collapsed occupants and slots gone")
	check(view._cell_owned(Vector2i(2, 3)) and view.state.rings[2].relay == {"active": true}, "Outer structure survives inner collapse")
	check(view.feedback_label.text.contains("collapsed"), "Collapse feedback")
	check(view.ring_status_hud.ring_records.size() == 2 and view.ring_status_hud.ring_records[0].collapsed and not view.ring_status_hud.ring_records[1].collapsed and view.ring_status_hud.ring_records[1].relay_active, "Ring status HUD reflects collapse and surviving relay (D-024 relay status)")
	# A1/A4 regressions: a flat/recomputed HP reference misjudges every ring but 1
	# and any wedge with a nonstandard max_hp (e.g. future Armor Plating).
	view.simulation.state.rings[2].wedges[5].hp = 40.0
	view.refresh_view()
	check(view.simulation.state.rings[2].wedges[5].max_hp == 200.0 and view.ring_status_hud.ring_records[1].wedges[4] == "critical", "Ring 2 wedge at 40/200 HP (20%) reads critical; a flat ring-1 reference (40/100=40%) would have missed it")
	view.simulation.state.rings[2].wedges[9].max_hp = 500.0
	view.simulation.state.rings[2].wedges[9].hp = 100.0
	view.refresh_view()
	check(view.ring_status_hud.ring_records[1].wedges[8] == "critical", "Wedge with a nonstandard max_hp (100/500=20%) reads critical from its own authoritative maximum, not a recomputed profile value (100/200=50% would have read ok)")
	view.simulation.state.rings[2].wedges[11].hp = 50.0
	view.refresh_view()
	check(view.ring_status_hud.ring_records[1].wedges[10] == "ok", "Exactly 25% HP (50/200) is the ok/critical boundary, not yet critical")
	view.simulation.state.rings[2].wedges[11].hp = 49.99
	view.refresh_view()
	check(view.ring_status_hud.ring_records[1].wedges[10] == "critical", "Just under the 25% boundary reads critical")
	fixture()
	spawn_at(8, 3, 0.5)
	ticks(1)
	check(view.target_grid.ring_count == 8 and view.grid.ring_count == 3, "Target rendering covers bands outside selection grid")
	check(view.target_grid.is_valid_position(view.rendered_targets[0].position), "Beyond-slice target render position valid")
	loss_fixture()
	check(view.simulation.ended and view.feedback_label.text.begins_with("Core lost. Survived"), "Core loss visible with a basic result summary (Phase 6 session lifecycle)")
	check(view.clock.tick_count == 1, "Core loss stops catchup at terminal tick")
	check(view.flak_button.disabled and view.mass_driver_button.disabled and view.expand_button.disabled, "Loss disables all purchases")
	frozen_ticks = view.clock.tick_count
	before_state = view.state.duplicate(true)
	view.flak_button.pressed.emit()
	slot_click(1, 3, 0)
	ticks(20)
	check(view.state == before_state and view.clock.tick_count == frozen_ticks and view.build_mode == &"", "Loss stops ticks and placement")
	control_click(view.menu_button)
	control_click(view.resume_button)
	check(not paused and not view.menu_open, "Menu still works after loss")
	# Phase 6 session lifecycle: Retry starts a fresh, playable run from a loss.
	var lost_simulation: LiveSimulation = view.simulation
	control_click(view.menu_button)
	control_click(view.retry_button)
	check(not view.menu_open and not paused, "Retry closes the menu and resumes play")
	check(view.simulation != lost_simulation and not view.simulation.ended and view.simulation.elapsed_seconds == 0.0, "Retry replaces the ended simulation with a fresh one")
	check(view.run_kill_count == 0 and view.clock.tick_count == 0 and view.build_mode == &"" and view.selected_cell == Vector2i(-1, -1), "Retry resets run-scoped counters, controls and selection")
	check(not view.flak_button.disabled, "Retry re-enables purchases")
	ticks(1)
	check(view.simulation.elapsed_seconds > 0.0, "Retried run actually advances")
	# Phase 6 exit check: retry works repeatedly, including mid-run (not just after loss),
	# without leaking state (walls, markers, warnings, wedge damage) into the next run.
	check(view.simulation.place_wall(1, 3).ok, "Mid-run fixture places a wall before retrying again")
	spawn_at(1, 5, 0.5)
	ticks(1)
	view.simulation.state.rings[1].wedges[7].hp = 0.01
	view.refresh_view()
	check(not view.wall_edges.is_empty() and view.rendered_targets.size() > 0 and view.ring_status_hud.ring_records[0].wedges[6] == "critical", "Mid-run state is genuinely present before the next retry")
	var mid_run_simulation: LiveSimulation = view.simulation
	control_click(view.menu_button)
	control_click(view.retry_button)
	check(view.simulation != mid_run_simulation and not view.simulation.ended, "Retry works mid-run, not only after loss")
	check(view.wall_edges.is_empty() and view.rendered_targets.is_empty() and view.ring_status_hud.ring_records[0].wedges[6] == "ok", "Second retry leaves no wall, machine or wedge-damage residue from the previous run")
	control_click(view.menu_button)
	control_click(view.retry_button)
	check(not view.simulation.ended and view.run_kill_count == 0 and view.clock.tick_count == 0, "A third consecutive retry still works cleanly")
	fixture()
	view.simulation.state.energy = -1
	ticks(1)
	check(not view.last_error.is_empty() and view.clock.paused and view.flak_button.disabled, "Unexpected simulation error visibly stops gameplay")
	frozen_ticks = view.clock.tick_count
	ticks(10)
	check(view.clock.tick_count == frozen_ticks, "Error prevents subsequent ticks")
	print("Live view checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
