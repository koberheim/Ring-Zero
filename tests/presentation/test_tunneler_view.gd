extends "res://tests/presentation/test_live_view.gd"

func tunneler_fixture(overrides: Dictionary = {}) -> void:
	view.unbounded_expansion = false
	var loaded := BalanceProfile.load_json("res://data/balance/testing.json")
	var tuned: Dictionary = loaded.profile.with_overrides({"pressure": {"spawn_per_second": 0}, "tunneler": {"first_arrival_seconds": 0.05}, "flak": {"damage": 0}, "health": {"wedge_base_hp": 100000}})
	tuned = tuned.profile.with_overrides(overrides)
	check(tuned.ok, "Tunneler fixture profile valid")
	var created := LiveSimulation.create(tuned.profile, 3, true)
	check(created.ok, "Scheduled Tunneler fixture valid")
	view.profile = tuned.profile
	view.simulation = created.simulation
	view.clock = FixedStepClock.new(60.0, view._simulation_tick)
	view.last_error = ""
	view.build_mode = &""
	view.simulation.state.energy = 1000
	check(view.simulation.purchase_ring().ok, "Fixture purchases outer ring with Relay")
	view.sync_simulation()

func first_tunneler() -> Dictionary:
	for target in view.rendered_targets:
		if target.get("kind", &"") == &"tunneler":
			return target
	return {}

func await_phase(phase: StringName, max_ticks: int = 150) -> bool:
	for tick in max_ticks:
		var target := first_tunneler()
		if not target.is_empty() and target.phase == phase:
			return true
		ticks(1)
	return false

func tunneler_collapse_fixture() -> void:
	tunneler_fixture()
	for wedge in range(1, 7):
		view.simulation.state.rings[1].wedges[wedge].hp = 0
	view.simulation.state.rings[1].wedges[12].hp = 0.01
	check(await_phase(&"surface_attack"), "Collapse fixture reaches real emergence")
	ticks(1)

func _run() -> void:
	root.size = Vector2i(1280, 900)
	# Exercise main-view creation with its own enabled flag, preserving default 60s.
	var loaded := BalanceProfile.load_json("res://data/balance/testing.json")
	var quiet: Dictionary = loaded.profile.with_overrides({"pressure": {"spawn_per_second": 0}, "flak": {"damage": 0}, "health": {"wedge_base_hp": 100000}})
	var temporary := FileAccess.open("res://.godot/t028-quiet-profile.json", FileAccess.WRITE)
	temporary.store_string(JSON.stringify(quiet.profile.snapshot()))
	temporary.close()
	view = load("res://scenes/live_view.tscn").instantiate()
	view.balance_path = "res://.godot/t028-quiet-profile.json"
	root.add_child(view)
	view.set_process(false)
	await process_frame
	check(view.profile.value("tunneler.first_arrival_seconds") == 60, "Default first arrival remains 60 seconds")
	view.simulation.state.energy = 1000
	check(view.simulation.purchase_ring().ok, "Default timing fixture buys second ring")
	ticks(3599)
	check(first_tunneler().is_empty(), "No scheduled Tunneler before 60 seconds")
	ticks(2)
	check(not first_tunneler().is_empty() and view.tunneler_warnings.size() == 1, "Main-view enabled flag admits real Tunneler at 60 seconds")
	tunneler_fixture()
	ticks(4)
	var target := first_tunneler()
	check(not target.is_empty() and target.phase == &"burrowing" and not target.targetable, "Real scheduled underground admission")
	check(view.marker_instances.instance_count == 0 and view.triangle_instances.instance_count == 0 and view.tunneler_warnings.size() == 1, "Underground actor only has destination warning")
	check(view.combat_label.text.contains("Machines  1"), "Underground actor included in active count")
	var warning_point: Vector2 = view.tunneler_warnings[0].point
	check(warning_point.is_equal_approx(view.target_grid.polar_to_world(target.destination)), "Warning is at locked destination")
	var initial_position: Vector2 = view.target_grid.polar_to_world(target.position)
	var initial_remaining: float = view.tunneler_warnings[0].remaining
	var initial_hp: float = view.state.rings[1].wedges[12].hp
	ticks(20)
	check(view.tunneler_warnings[0].point == warning_point and not view.target_grid.polar_to_world(first_tunneler().position).is_equal_approx(initial_position), "Underground actor moves while warning remains fixed")
	check(view.tunneler_warnings[0].remaining < initial_remaining and view.state.rings[1].wedges[12].hp == initial_hp, "Only ticks lower countdown; no underground wedge damage")
	view.flak_button.pressed.emit()
	button(MOUSE_BUTTON_RIGHT, true, view.feedback_label.get_global_rect().get_center())
	button(MOUSE_BUTTON_RIGHT, false, view.feedback_label.get_global_rect().get_center())
	check(view.build_mode == &"", "Right cancel remains available during warning")
	control_click(view.menu_button)
	# A real player always sees a rendered frame between opening the menu and
	# clicking within it; this first-ever open needs one for the pause panel's
	# now-multi-button layout (Resume/Retry) to finish sorting before we click it.
	await process_frame
	var frozen_targets := target_values()
	var frozen_remaining: float = view.tunneler_warnings[0].remaining
	var frozen_state: Dictionary = view.state.duplicate(true)
	view._process(3.0)
	check(view.tunneler_warnings[0].remaining == frozen_remaining and target_values() == frozen_targets and view.state == frozen_state, "Pause freezes warning position countdown and HP")
	control_click(view.resume_button)
	ticks(1)
	check(not paused and view.tunneler_warnings[0].remaining < frozen_remaining, "Resume advances countdown without catchup")
	button(MOUSE_BUTTON_MIDDLE, true, Vector2(950, 700))
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(970, 690)
	motion.relative = Vector2(20, -10)
	root.push_input(motion)
	button(MOUSE_BUTTON_MIDDLE, false, view.feedback_label.get_global_rect().get_center())
	button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(950, 700))
	check(not view.dragging and view.camera.position != Vector2.ZERO and view.tunneler_warnings[0].point == warning_point, "Pan zoom and panel release preserve locked warning")
	view.flak_button.pressed.emit()
	slot_click(1, 3, 0)
	check(view.state.rings[1].wedges[3].occupants[0].kind == &"flak", "Build controls operate during underground warning")
	check(await_phase(&"surface_attack"), "Scheduled real emergence occurs")
	check(view.tunneler_warnings.is_empty() and view.triangle_instances.instance_count == 1 and view.marker_instances.instance_count == 0, "Emergence replaces warning with triangle")
	check(view.surfaced_points[0].is_equal_approx(view.target_grid.polar_to_world(first_tunneler().position)), "Triangle follows current surface position")
	var energy_before: float = view.state.energy
	view.mass_driver_button.pressed.emit()
	slot_click(1, 11, 0)
	var purchase_energy: float = view.state.energy
	check(purchase_energy == energy_before - view.profile.value("economy.mass_driver_cost"), "Real weapon purchased for kill fixture")
	ticks(1)
	check(first_tunneler().is_empty() and view.triangle_instances.instance_count == 0, "Automatic weapon kill removes triangle")
	check(view.state.energy == purchase_energy + view.profile.value("economy.kill_energy"), "Tunneler kill banks reward once")
	var rewarded: float = view.state.energy
	ticks(5)
	check(view.state.energy == rewarded, "No duplicate Tunneler reward")
	tunneler_fixture()
	view.simulation.state.rings[1].wedges[12].hp = 0.01
	check(await_phase(&"roaming"), "Real inside attack breaks target then transitions to roaming")
	var roaming_point: Vector2 = view.surfaced_points[0]
	ticks(2)
	check(view.state.rings[1].wedges[12].hp == 0 and view.triangle_instances.instance_count == 1 and view.surfaced_points[0] != roaming_point, "Roaming triangle follows motion after target break")
	tunneler_collapse_fixture()
	check(view.state.rings[1].get("collapsed", false) and view._slot_count(1, 12) == 0 and view.state.rings[1].wedges[12].occupants.is_empty(), "Tunneler-triggered collapse clears inner buildings")
	check(view._cell_owned(Vector2i(2, 3)) and view.state.rings[2].relay == {"active": true}, "Outer Relay survives Tunneler collapse")
	tunneler_fixture()
	ticks(4)
	warning_point = view.tunneler_warnings[0].point
	for wedge in range(1, 7):
		view.simulation.state.rings[1].wedges[wedge].hp = 0
	view.simulation.state.rings[1].wedges[12].hp = 0.01
	view.simulation.state.rings[2].wedges[12].hp = 0
	spawn_at(2, 12, 0, 1000, 6)
	ticks(1)
	check(view.state.rings[1].get("collapsed", false) and view.tunneler_warnings[0].point == warning_point, "Destination warning remains locked when another actor collapses target")
	check(await_phase(&"roaming"), "Tunneler emerges in planned gap after target disappears")
	check(view.tunneler_warnings.is_empty() and view.triangle_instances.instance_count == 1, "Gap emergence clears warning and shows triangle")
	view.simulation.state.energy = -1
	ticks(1)
	check(not view.last_error.is_empty() and view.clock.paused, "Runtime failure stops lifecycle clock")
	var stopped_ticks: int = view.clock.tick_count
	ticks(5)
	check(view.clock.tick_count == stopped_ticks, "No lifecycle continuation after error")
	loss_fixture()
	stopped_ticks = view.clock.tick_count
	ticks(5)
	check(view.simulation.ended and view.clock.tick_count == stopped_ticks, "Core loss stops all further lifecycle ticks")
	print("Tunneler view checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
