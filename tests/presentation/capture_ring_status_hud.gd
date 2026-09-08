extends "res://tests/presentation/test_live_view.gd"
## Isolated capture for the D-024 ring-status HUD; never attached to the playable scene.

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered != null and not rendered.is_empty(), "Rendered image exists")
	check(rendered.get_size() == Vector2i(1280, 900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-029-" + name + ".png") == OK, "PNG saved")

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	await process_frame
	collapse_fixture()
	# Give ring 2 a mixed picture: one critical wedge alongside its surviving relay.
	view.simulation.state.rings[2].wedges[9].hp = view.simulation.state.rings[2].wedges[9].hp * 0.0 + (view.profile.value("health.wedge_base_hp") * 0.1)
	view.refresh_view()
	await screenshot("mixed-status")
	check(view.ring_status_hud.ring_records[0].collapsed, "Capture fixture ring 1 collapsed")
	check(view.ring_status_hud.ring_records[1].wedges[8] == "critical", "Capture fixture ring 2 wedge 9 critical")
	await twelve_ring_readability()
	print("Ring status HUD capture checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)

func twelve_ring_readability() -> void:
	var loaded := BalanceProfile.load_json("res://data/balance/testing.json")
	var tuned: Dictionary = loaded.profile.with_overrides({"pressure": {"spawn_per_second": 0}})
	check(tuned.ok, "Readability fixture profile valid")
	var created := LiveSimulation.create(tuned.profile, 12)
	check(created.ok, "Readability fixture simulation valid")
	view.profile = tuned.profile
	view.simulation = created.simulation
	view.clock = FixedStepClock.new(60.0, view._simulation_tick)
	view.last_error = ""
	view.build_mode = &""
	view.sync_simulation()
	view.simulation.state.energy = 1.0e6
	for _index in range(11):
		check(view.simulation.purchase_ring().ok, "Readability fixture buys ring")
	check(view.simulation.state.rings.size() == 12, "Readability fixture reaches ring 12")
	view.simulation.state.rings[3].wedges[5].hp = view.profile.value("health.wedge_base_hp") * 0.1
	view.simulation.state.rings[7].wedges[10].hp = 0
	var ring_ten: Dictionary = view.simulation.state.rings[10]
	ring_ten.collapsed = true
	ring_ten.relay = {}
	ring_ten.erase("relay_hp")
	ring_ten.erase("relay_max_hp")
	for wedge in ring_ten.wedges.values():
		wedge.hp = 0
		wedge.occupants = {}
	view.refresh_view()
	await screenshot("twelve-ring-readability")
	check(view.ring_status_hud.ring_records.size() == 12, "HUD renders all twelve rings")
