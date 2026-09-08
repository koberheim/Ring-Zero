extends "res://tests/presentation/test_weapon_catalogue_view.gd"

func aim_world(point: Vector2) -> void:
	view.camera.force_update_scroll()
	var event := InputEventMouseMotion.new()
	event.position = root.get_canvas_transform()*point
	root.push_input(event)

func world_click(point: Vector2) -> void:
	view.camera.force_update_scroll()
	click(root.get_canvas_transform()*point)

func solar_checks() -> void:
	funded_fixture({"flak":{"damage":0}})
	view.choose_build(&"")
	await process_frame
	var position: Vector2 = view.grid.polar_to_world(PolarPosition.new(2,3,0.0,0.5))
	for index in 3:
		spawn_at(2,3,0.0,10)
	var decoy := spawn_at(2,7,0.0,1000)
	view.sync_simulation()
	control_click(view.focused_flare_button)
	check(view.ability_mode == &"focused_flare" and view.build_mode == &"", "Actual Flare button enters distinct ability mode")
	aim_world(position)
	var outline: PackedVector2Array = view.ability_outline()
	var radius: float = view.profile.value("focused_flare.range_ring_widths")*PolarGrid.RING_WIDTH
	var half_arc := deg_to_rad(float(view.profile.value("focused_flare.arc_degrees")))*0.5
	check(outline.size() == 67 and outline[0] == Vector2.ZERO and absf(outline[1].length()-radius) < 0.001 and absf(outline[65].angle()-position.angle()-half_arc) < 0.00001, "Flare outline uses exact profile range and boundary bearing")
	var energy: float = view.state.energy
	var selected: Vector2i = view.selected_cell
	click(view.ui_panel.get_global_rect().position+Vector2(1,1))
	check(view.simulation.abilities_snapshot().is_empty() and view.selected_cell == selected and view.simulation.pool.active_count() == 4, "UI click does not cast or select through panel")
	world_click(Vector2.ZERO)
	check(view.ability_mode == &"focused_flare" and view.simulation.abilities_snapshot().is_empty() and view.feedback_label.text.contains("finite world point"), "Zero-bearing Flare is rejected without cooldown")
	world_click(position)
	check(view.ability_mode == &"" and view.simulation.pool.active_count() == 1 and view.simulation.pool.payload_for(decoy).hp == 1000 and view.run_kill_count == 3 and view.state.energy == energy, "Flare multi-kill counts once, excludes angular decoy, grants no energy")
	ticks(1)
	check(view.run_kill_count == 3 and view.state.energy == energy, "Following tick does not double-count cast kills or reward")
	control_click(view.focused_flare_button)
	check(view.ability_mode == &"" and view.feedback_label.text.contains("cooling down"), "Cooling-down ability gives readable feedback")
	control_click(view.emp_burst_button)
	aim_world(position)
	outline = view.ability_outline()
	radius = view.profile.value("emp_burst.radius_ring_widths")*PolarGrid.RING_WIDTH
	check(outline.size() == 65 and absf(outline[0].distance_to(position)-radius) < 0.001, "EMP outline is centered at authoritative pointer with profile radius")
	button(MOUSE_BUTTON_RIGHT,true,view.feedback_label.get_global_rect().get_center())
	button(MOUSE_BUTTON_RIGHT,false,view.feedback_label.get_global_rect().get_center())
	check(view.ability_mode == &"" and not view.simulation.abilities_snapshot().has(&"emp_burst"), "Right cancellation over panel makes no ability command")
	control_click(view.emp_burst_button)
	var hit := spawn_at(8,3,0.5,1000)
	var distant := Vector2(816,0)
	view.camera.position = distant
	view.camera.force_update_scroll()
	aim_world(distant)
	button(MOUSE_BUTTON_MIDDLE,true,Vector2(640,450))
	var pan := InputEventMouseMotion.new()
	pan.position = Vector2(650,455)
	pan.relative = Vector2(10,5)
	root.push_input(pan)
	button(MOUSE_BUTTON_MIDDLE,false,Vector2(650,455))
	check(view.ability_aim_world.is_equal_approx(root.get_canvas_transform().affine_inverse()*pan.position), "Pan recomputes target outline after camera movement")
	button(MOUSE_BUTTON_WHEEL_DOWN,true,Vector2(650,455))
	check(view.ability_aim_world.is_equal_approx(root.get_canvas_transform().affine_inverse()*pan.position), "Wheel recomputes outline without a new pointer motion")
	world_click(distant)
	check(view.simulation.pool.payload_for(hit).hp < 1000 and view.simulation.pool.payload_for(hit).stun_remaining > 0 and view.state.energy == energy and view.ring_count == 3, "EMP casts beyond displayed extent without expanding build geometry or granting energy")
	control_click(view.menu_button)
	await process_frame
	world_click(position)
	check(paused and view.ability_mode == &"", "Menu cancels ability input and blocks casts")
	control_click(view.retry_button)
	check(not paused and view.simulation.abilities_snapshot().is_empty() and view.ability_mode == &"" and view.focused_flare_button.text.contains("Ready"), "Retry clears targeting and resets ready cooldowns")
	control_click(view.focused_flare_button)
	view.tabs.current_tab = 0
	await process_frame
	control_click(view.flak_button)
	check(view.ability_mode == &"" and view.build_mode == &"flak", "Build mode cancels ability targeting")
	await process_frame
	control_click(view.emp_burst_button)
	check(view.build_mode == &"" and view.ability_mode == &"emp_burst", "Ability mode cancels build mode")
	funded_fixture({"emp_burst":{"radius_ring_widths":1.0e308}})
	view.choose_build(&"")
	control_click(view.emp_burst_button)
	aim_world(position)
	check(view.ability_outline().is_empty(), "Overflowed edited radius produces no invalid draw points")
	world_click(position)
	check(view.simulation.abilities_snapshot().is_empty() and view.feedback_label.text.contains("Nonfinite ability range"), "Unusable edited radius rejects cast without cooldown")

func underground_check() -> void:
	tunneler_fixture()
	view.choose_build(&"")
	await process_frame
	check(await_phase(&"burrowing"), "Solar immunity fixture admits real underground Tunneler")
	var target := first_tunneler()
	var hp: float = target.hp
	control_click(view.emp_burst_button)
	world_click(view.target_grid.polar_to_world(target.destination))
	check(first_tunneler().hp == hp and view.simulation.abilities_snapshot().has(&"emp_burst"), "Actual cast cannot damage underground Tunneler")

func terrain_checks() -> void:
	funded_fixture()
	view.choose_build(&"")
	check(view.simulation.purchase_ring().ok, "Terrain fixture buys ring two")
	view.sync_simulation()
	view.tabs.current_tab = 2
	await process_frame
	check(view.tabs.get_tab_count() == 3 and not view.tabs.is_tab_disabled(2), "Three build tabs retained and Terrain enabled")
	for entry in [[view.debris_field_button,&"debris_field",3],[view.occlusion_screen_button,&"occlusion_screen",4]]:
		var before: float = view.state.energy
		control_click(entry[0])
		slot_click(2,entry[2],0)
		check(view.state.rings[2].wedges[entry[2]].occupants[0].kind == entry[1] and view.state.energy == before-view.profile.value("economy.%s_cost" % entry[1]), "Actual %s placement charges exact profile cost" % entry[1])
	check(view.status_label.text.contains("Rings 3–5") and view.status_label.text.contains("50.0% speed"), "Selected Screen explains outward effect span and speed")
	control_click(view.tractor_lane_button)
	slot_click(2,12,0)
	check(TerrainRules.tractor_direction(view.state,2,12) == 1 and view.status_label.text.contains("Clockwise"), "Clockwise lane at wrap wedge12 is inspectable")
	var before_state: Dictionary = view.state.duplicate(true)
	control_click(view.tractor_lane_button)
	slot_click(2,12,1)
	check(view.state == before_state and view.feedback_label.text.contains("already has a Tractor Lane"), "One-lane limit rejects atomically with clear reason")
	control_click(view.tractor_direction_button)
	check(view.feedback_label.text.to_lower().contains("counterclockwise"), "Chosen direction visible before placement")
	slot_click(2,1,0)
	check(TerrainRules.tractor_direction(view.state,2,1) == -1 and view.status_label.text.contains("Counterclockwise"), "Counterclockwise lane at wrap wedge1 is inspectable")
	control_click(view.debris_field_button)
	before_state = view.state.duplicate(true)
	slot_click(2,3,0)
	check(view.state == before_state and view.feedback_label.text.contains("occupied"), "Occupied terrain placement is atomic")
	view.simulation.state.energy = 0
	view.sync_simulation()
	before_state = view.state.duplicate(true)
	slot_click(2,5,0)
	check(view.state == before_state and view.feedback_label.text.contains("Not enough energy"), "Unaffordable terrain placement is atomic")
	view.simulation.state.energy = 10000
	view.simulation.state.rings[2].wedges[4].hp = 0
	view.sync_simulation()
	check(TerrainRules.surface_speed_multiplier(view.state,view.profile,PolarPosition.new(3,4,0.8,0.5)) == 1.0 and view._slot_count(2,4) == 0, "Broken support visibly disables retained Screen and its slow")
	view.tabs.current_tab = 1
	await process_frame
	control_click(view.repair_button)
	slot_click(2,4,0)
	check(TerrainRules.surface_speed_multiplier(view.state,view.profile,PolarPosition.new(3,4,0.8,0.5)) == view.profile.value("occlusion_screen.speed_multiplier"), "Actual Repair reactivates retained Screen")
	var slowed := spawn_at(3,4,0.8,1000,0,1)
	ticks(1)
	check(absf(view.simulation.pool.payload_for(slowed).position.radial_fraction-(0.8-float(view.profile.value("occlusion_screen.speed_multiplier"))/60.0)) < 0.00001, "Repaired Screen slows actual next-tick physical movement")
	funded_fixture()
	view.choose_build(&"")
	check(view.simulation.purchase_ring().ok, "Seal fixture buys ring two")
	for wedge in range(1,12):
		check(view.simulation.place_terrain(2,wedge,1 if wedge == 6 else 0,&"debris_field").ok, "Seal fixture places existing frontier debris")
	view.sync_simulation()
	view.tabs.current_tab = 2
	await process_frame
	control_click(view.debris_field_button)
	before_state = view.state.duplicate(true)
	slot_click(2,12,0)
	check(view.state == before_state and view.feedback_label.text.contains("seal the outer perimeter"), "Final sealing Debris placement rejects atomically through actual input")

func _run() -> void:
	root.size = Vector2i(1280,900)
	for scene in ["live_view","art_preview"]:
		view = load("res://scenes/%s.tscn" % scene).instantiate()
		root.add_child(view)
		view.set_process(false)
		await process_frame
		await process_frame
		await solar_checks()
		await terrain_checks()
		await underground_check()
		view.queue_free()
		await process_frame
	print("Terrain/ability view checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
