extends "res://tests/presentation/test_live_view.gd"
## Phase 7 UI: Armor Plating, Repair Node, Repair (D-022 Tier 1) and Reclaim (D-022 Tier 2).

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	view.tabs.current_tab = 1
	await process_frame

	fixture()
	view.simulation.state.energy = 10000
	view.sync_simulation()

	# Armor Plating: click, select an empty owned wedge, raises its HP ceiling.
	control_click(view.armor_button)
	check(view.build_mode == &"armor", "Armor Plating mode selected")
	slot_click(1, 7, 0)
	check(view.build_mode == &"armor" and view.state.rings[1].wedges[7].max_hp == 150.0 and view.state.rings[1].wedges[7].hp == 150.0, "Armor Plating click raises the wedge's HP ceiling and retains build mode")

	# Repair Node: click, select an empty owned wedge, occupies the slot with no immediate HP change.
	control_click(view.repair_node_button)
	slot_click(1, 8, 0)
	check(view.build_mode == &"repair_node" and view.state.rings[1].wedges[8].occupants[0].kind == &"repair_node", "Repair Node click places the node")

	# Repair (D-022 Tier 1): damage an owned wedge, then click it in Repair mode to restore it.
	view.simulation.state.rings[1].wedges[9].hp = 40.0
	view.sync_simulation()
	control_click(view.repair_button)
	check(view.build_mode == &"repair", "Repair mode selected")
	slot_click(1, 9, 0)
	check(view.build_mode == &"repair" and view.state.rings[1].wedges[9].hp == 100.0, "Repair click restores the damaged wedge to full HP")
	control_click(view.repair_button)
	slot_click(1, 9, 0)
	check(view.build_mode == &"repair" and view.feedback_label.text.contains("full HP"), "Repairing an already-full wedge fails with a clear reason and keeps the mode active")
	view.choose_build(&"")

	# Reclaim (D-022 Tier 2): collapse ring 1 while ring 2 survives, then rebuild it in place.
	check(view.simulation.purchase_ring().ok, "Reclaim fixture buys ring 2")
	var ring: Dictionary = view.simulation.state.rings[1]
	ring.collapsed = true
	ring.relay = {}
	ring.erase("relay_hp")
	ring.erase("relay_max_hp")
	for plate in ring.wedges.values():
		plate.hp = 0
		plate.occupants = {}
	view.sync_simulation()
	check(view._cell_description(Vector2i(1, 6)) == "collapsed", "Fixture ring 1 is now collapsed")
	control_click(view.reclaim_button)
	check(view.build_mode == &"reclaim", "Reclaim mode selected")
	slot_click(1, 6, 0)
	check(view.build_mode == &"reclaim" and not view.state.rings[1].get("collapsed", false) and view.state.rings[1].relay == {"active": true} and view.state.rings[1].wedges[1].hp == 100.0, "Reclaim click rebuilds the collapsed ring with a fresh relay")
	control_click(view.reclaim_button)
	slot_click(2, 3, 0)
	check(view.build_mode == &"reclaim" and view.feedback_label.text.contains("collapsed ring"), "Clicking a non-collapsed ring in Reclaim mode is rejected and keeps the mode active")

	print("Structure view checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
