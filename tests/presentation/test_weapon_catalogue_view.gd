extends "res://tests/presentation/test_tunneler_view.gd"

func catalogue_button(kind: StringName) -> Button:
	return view.get(str(kind) + "_button")

func funded_fixture(overrides: Dictionary = {}) -> void:
	fixture(overrides)
	view.simulation.state.energy = 10000
	view.sync_simulation()

func hover_slot(ring: int, wedge: int, slot: int = 0) -> void:
	view.camera.force_update_scroll()
	var event := InputEventMouseMotion.new()
	event.position = root.get_canvas_transform() * view.grid.polar_to_world(BuildingRules.slot_position(ring, wedge, slot, maxi(1, view._slot_count(ring, wedge))))
	root.push_input(event)

func weapon_input_checks(kind: StringName) -> void:
	funded_fixture()
	var cost: float = view.profile.value("economy.%s_cost" % kind)
	check(catalogue_button(kind).text == "[%s] %s %s %s" % [view.TOOL_LABELS[kind],view.BUILDING_NAMES[kind],String.chr(8212),str(view.profile.value("economy.%s_cost" % kind))], "%s displays profile cost" % kind)
	control_click(catalogue_button(kind))
	check(view.build_mode == kind, "%s actual button selects mode" % kind)
	slot_click(1, 3, 0)
	check(view.state.rings[1].wedges[3].occupants[0].kind == kind and view.state.energy == 10000 - cost and view.build_mode == kind, "%s places and charges once" % kind)
	var placed: Dictionary = view.state.duplicate(true)
	control_click(catalogue_button(kind))
	slot_click(1, 3, 0)
	check(view.state == placed and view.build_mode == kind, "%s occupied rejection has no charge or ghost" % kind)
	view.simulation.state.rings[1].wedges[4].hp = 0
	view.sync_simulation()
	var broken: Dictionary = view.state.duplicate(true)
	slot_click(1, 4, 0)
	check(view.state == broken and view.build_mode == kind, "%s broken rejection has no charge or ghost" % kind)
	view.simulation.state.energy = 0
	view.sync_simulation()
	var poor: Dictionary = view.state.duplicate(true)
	slot_click(1, 5, 0)
	check(view.state == poor and view.feedback_label.text.contains("Not enough energy"), "%s insufficient energy feedback and no mutation" % kind)
	button(MOUSE_BUTTON_RIGHT, true, view.feedback_label.get_global_rect().get_center())
	button(MOUSE_BUTTON_RIGHT, false, view.feedback_label.get_global_rect().get_center())
	check(view.build_mode == &"" and view.state == poor, "%s right cancel over panel" % kind)
	funded_fixture({"power": {"base_output": 10.0}})
	control_click(catalogue_button(kind))
	var powerless: Dictionary = view.state.duplicate(true)
	slot_click(1, 3, 0)
	check(view.state == powerless and view.feedback_label.text.contains("power capacity"), "%s power rejection is accurate and atomic" % kind)

func combat_checks() -> void:
	funded_fixture({"flak": {"damage": 0}})
	control_click(view.emp_node_button)
	slot_click(1, 3, 0)
	view.simulation.state.rings[1].wedges[4].hp = 0
	var own := spawn_at(1, 4, 0.8)
	var outer := spawn_at(2, 4, 0.8)
	ticks(1)
	check(view.simulation.pool.payload_for(own).hp < 1000 and view.simulation.pool.payload_for(own).get("stun_remaining", 0) > 0, "Purchased EMP damages and stuns own-ring adjacent-wedge target")
	check(view.simulation.pool.payload_for(outer).hp == 1000, "EMP excludes another ring")
	check(view.last_error.is_empty(), "EMP fixture is a valid live simulation")
	funded_fixture({"flak": {"damage": 0}})
	check(view.simulation.purchase_ring().ok, "Lance fixture buys ring two")
	view.sync_simulation()
	control_click(view.lance_emitter_button)
	slot_click(2, 3, 0)
	view.simulation.state.rings[1].wedges[3].hp = 0
	var outward := spawn_at(3, 3, 0.8)
	var inward := spawn_at(1, 3, 0.8)
	var adjacent := spawn_at(3, 4, 0.8)
	ticks(1)
	check(view.simulation.pool.payload_for(outward).hp < 1000, "Purchased Lance fires outward in its wedge column")
	check(view.simulation.pool.payload_for(inward).hp == 1000 and view.simulation.pool.payload_for(adjacent).hp == 1000, "Lance excludes inner-ring and adjacent-wedge decoys")
	check(view.last_error.is_empty(), "Lance fixture is a valid live simulation")
	tunneler_fixture()
	view.simulation.state.rings[1].wedges[12].occupants.clear()
	view.sync_simulation()
	control_click(view.point_defense_button)
	slot_click(1, 12, 0)
	check(view.state.rings[1].wedges[12].occupants[0].kind == &"point_defense", "Point Defense purchased at scheduled destination")
	check(await_phase(&"burrowing"), "Point Defense fixture gets real underground Tunneler")
	var target := first_tunneler()
	var hp: float = target.hp
	ticks(20)
	check(first_tunneler().hp == hp, "Purchased Point Defense cannot hit underground Tunneler")
	check(await_phase(&"surface_attack"), "Point Defense fixture reaches real surface")
	ticks(8)
	check(first_tunneler().hp < hp and view.last_error.is_empty(), "Purchased Point Defense hits surfaced own-cell Tunneler")

func quote_checks() -> void:
	funded_fixture()
	view.tabs.current_tab = 1
	await process_frame
	view.simulation.state.rings[1].wedges[3].hp = 40
	view.sync_simulation()
	control_click(view.repair_button)
	hover_slot(1, 3)
	var quote: Dictionary = view.simulation.quote_repair(1, 3)
	check(quote.ok and view.status_label.text.contains("%s energy" % str(quote.quote.cost)) and view.state.energy == 10000, "Hover shows authoritative repair cost before spend")
	slot_click(1, 3, 0)
	check(view.state.energy == 10000 - quote.quote.cost, "Repair purchase uses previewed cost")
	view.simulation.state.rings[1].wedges[3].hp = 0
	spawn_at(1, 3, 0.8)
	view.sync_simulation()
	control_click(view.repair_button)
	var before: Dictionary = view.state.duplicate(true)
	slot_click(1, 3, 0)
	check(view.state == before and view.feedback_label.text.contains("occupy the broken wedge"), "D-094 occupied broken repair rejection is clear and atomic")
	funded_fixture()
	var ring: Dictionary = view.simulation.state.rings[1]
	ring.collapsed = true
	ring.relay = {}
	ring.erase("relay_hp")
	ring.erase("relay_max_hp")
	for plate in ring.wedges.values():
		plate.hp = 0
		plate.occupants = {}
	view.sync_simulation()
	control_click(view.reclaim_button)
	hover_slot(1, 3)
	quote = view.simulation.quote_reclaim(1)
	check(quote.ok and view.status_label.text.contains("%s energy" % str(quote.quote.cost)) and view.state.energy == 10000, "Hover shows authoritative reclaim cost before spend")
	slot_click(1, 3, 0)
	check(view.state.energy == 10000 - quote.quote.cost and not view.state.rings[1].get("collapsed", false), "Reclaim retains single-click purchase and quoted charge")
	check(view.BUILDING_NAMES[&"armor_plating"] == "Armor Plating" and view.BUILDING_NAMES[&"repair_node"] == "Repair Node", "Existing structures have approved world labels")
	view.tabs.current_tab = 0
	await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	await process_frame
	for kind in [&"emp_node", &"lance_emitter", &"point_defense"]:
		weapon_input_checks(kind)
	for kind in [&"flak", &"mass_driver"]:
		funded_fixture({"power": {"base_output": 10.0}})
		control_click(catalogue_button(kind))
		slot_click(1, 3, 0)
		check(view.feedback_label.text.contains("power capacity"), "%s gets corrected power feedback" % kind)
	combat_checks()
	await quote_checks()
	control_click(view.lance_emitter_button)
	control_click(view.menu_button)
	await process_frame
	check(paused and view.build_mode == &"" and view.point_defense_button.disabled, "Menu pauses and disables new catalogue")
	control_click(view.retry_button)
	check(not paused and not view.menu_open and view.simulation.pool.active_count() == 0 and view.state.rings[1].wedges[3].occupants.is_empty() and not view.emp_node_button.disabled, "Retry clears catalogue fixture and restores controls")
	print("Weapon catalogue view checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
