extends "res://tests/presentation/test_application.gd"
## Deliberately separate actual-collapse stress; never replaces canonical RC2 fixture.
func _run() -> void:
	root.size = Vector2i(2560,1440)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/t083-load-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.begin_run(false)
	await process_frame
	app.live.set_process(false)
	var base: BalanceProfile = BalanceProfile.load_json("res://data/balance/release.json").profile
	var tuned: BalanceProfile = base.with_overrides({"pressure":{"spawn_per_second":0},"flak":{"damage":0},"power":{"base_output":1800.0}}).profile
	var sim: LiveSimulation = LiveSimulation.create(tuned,12).simulation
	sim.state.energy = 1e9
	for ring in range(2,13): check(sim.purchase_ring().ok,"Public ring purchase")
	for wedge in range(8,13):
		check(sim.place_wall(12,wedge).ok,"Standing outer wall")
		for slot in 5:
			# Actual ring power supports three Flak per sector and the real armor
			# cap supports two. This bounded fixture makes no maximum-load claim.
			var placed: Dictionary = sim.place_weapon(12,wedge,slot,&"flak") if slot < 3 else sim.place_armor(12,wedge,slot)
			check(placed.ok,"Occupied high ring slot: "+str(placed.get("errors",[])))
	for wedge in range(1,7): sim.state.rings[12].wedges[wedge].hp = 0.0
	sim.state.rings[12].wedges[7].hp = 6.7
	for index in 128:
		sim.pool.spawn({"position":PolarPosition.new(13,7 if index == 0 else index%12+1,0.0 if index == 0 else 0.4,0.5),"hp":1e9,"damage_per_second":6.0 if index == 0 else 0.0,"speed_ring_widths_per_second":1.0 if index == 0 else 0.00001})
	check(RingPurchaseRules.validate_state(sim.state,tuned).is_empty(),"Actual fixture state validates")
	if failures:
		print("Invalid setup; timing not started")
		await app.audio.shutdown()
		app.queue_free()
		await process_frame
		quit(1)
		return
	app.live.simulation = sim
	app.live.profile = tuned
	app.live.sync_simulation()
	app.live._set_zoom(0.41)
	app.live.camera.force_update_scroll()
	var admission := {}
	app.live.clock = FixedStepClock.new(60.0,func(dt):
		app.live._simulation_tick(dt)
		if not sim.last_events.collapsed_rings.is_empty():
			admission.tick = sim._ticks
			admission.rings = sim.last_events.collapsed_rings.duplicate()
			admission.pieces = app.live.collapse_feedback.piece_count()
			admission.hardware = 0
			admission.wall_modules = 0
			for event in app.live.collapse_feedback.events:
				for piece in event.pieces:
					admission.hardware += piece.hardware.size()
					admission.wall_modules += piece.walls.size())
	app.live.set_process(true)
	for frame in 60: await process_frame
	var frames: Array[float] = []
	var during: Array[float] = []
	var start := Time.get_ticks_usec()
	var last := start
	var sim_start := sim.elapsed_seconds
	var max_callback := 0.0
	for frame in 180:
		await process_frame
		var now := Time.get_ticks_usec()
		var ms := float(now-last)/1000.0
		frames.append(ms)
		if not app.live.collapse_feedback.events.is_empty(): during.append(ms)
		last = now
		max_callback = maxf(max_callback,float(app.live.simulation_cpu_usec)/1000.0)
		check(app.live.last_error.is_empty() and sim.pool.active_count()==128,"Actual transient stress state valid")
	var wall := float(Time.get_ticks_usec()-start)/1e6
	frames.sort()
	during.sort()
	check(not admission.is_empty() and admission.rings == [12],"Real high-ring committed collapse occurred")
	check(admission.get("hardware",0) == 25,"All actual loaded hardware retained")
	check(not during.is_empty(),"Measured actual debris frames")
	print(JSON.stringify({"diagnostic":"actual high-ring collapse with densely occupied standing hardware; different fixture from canonical","viewport":str(app.stage.size),"actors":128,"rings":12,"effects":true,"zoom":0.41,"frames":180,"median_frame_ms":frames[90],"p95_frame_ms":frames[171],"max_frame_ms":frames[-1],"during_frames":during.size(),"during_median_ms":during[during.size()/2] if not during.is_empty() else 0,"max_simulation_callback_ms":max_callback,"simulation_wall_ratio":(sim.elapsed_seconds-sim_start)/wall,"admission":admission,"adapter_cap_pieces":96,"adapter_cap_events":8}))
	await app.audio.shutdown()
	app.queue_free()
	paused = false
	await process_frame
	quit(1 if failures else 0)
