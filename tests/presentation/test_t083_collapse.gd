extends "res://tests/presentation/test_application.gd"
const Feedback = preload("res://src/presentation/effects/collapse_feedback.gd")

func _run() -> void:
	root.size = Vector2i(2560,1440)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/t083-test-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	app.set_process(false)
	app.begin_run(false)
	await process_frame
	var view = app.live
	view.set_process(false)
	view.apply_interface_settings({"effects":true,"reduced_motion":false,"ui_scale":1.0})
	var base: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile
	var profile: BalanceProfile = base.with_overrides({"pressure":{"spawn_per_second":0},"flak":{"damage":0}}).profile
	var sim: LiveSimulation = LiveSimulation.create(profile,5).simulation
	sim.state.energy = 1000
	check(sim.purchase_ring().ok,"Real public expansion fixture")
	check(sim.place_weapon(1,10,int(sim.state.rings[1].wedges[10].slot_count)-1,&"flak").ok,"Real highest-slot hardware fixture")
	check(sim.place_wall(1,11).ok,"Real wall fixture")
	for wedge in range(1,7): sim.state.rings[1].wedges[wedge].hp = 0.0
	sim.state.rings[2].wedges[7].hp = 0.0
	sim.state.rings[1].wedges[7].hp = 0.05
	sim.pool.spawn({"position":PolarPosition.new(2,7,0,0.5),"hp":100.0,"damage_per_second":6.0,"speed_ring_widths_per_second":1.0})
	view.simulation = sim
	view.profile = profile
	view.sync_simulation()
	var before: Dictionary = sim.state
	var original := before.duplicate(true)
	var energy: float = before.energy
	view._simulation_tick(1.0/60.0)
	check(view.last_error.is_empty() and sim._ticks == 1,"Successful original fixed tick")
	check(sim.last_events.collapsed_rings == [1],"Actual inner collapse event")
	check(sim.state.rings[1].collapsed and sim.state.rings[1].wedges[12].occupants.is_empty(),"Original tick clears lost occupants")
	check(not sim.state.rings[2].get("collapsed",false) and sim.state.energy == energy,"Surviving outer ring and no fabricated refund")
	check(before == original and not before.rings[1].get("collapsed",false),"Old state reference retained without mutation")
	check(view.collapse_feedback.admitted.ring == 1 and view.collapse_feedback.admitted.wedge == 0,"One ring admission; not seven wedge explosions")
	check(view.collapse_feedback.events[0].pieces.size() == 6,"Only standing pre-step sectors retained")
	var hardware := 0
	for piece in view.collapse_feedback.events[0].pieces: hardware += piece.hardware.size()
	check(hardware > 0,"Lost occupied hardware retained in presentation geometry")
	var saved_piece: Dictionary = view.collapse_feedback.events[0].pieces[3]
	var high_slot: Dictionary = saved_piece.hardware[0]
	var expected := PolarGrid.new(1).polar_to_world(BuildingRules.slot_position(1,10,int(original.rings[1].wedges[10].slot_count)-1,int(original.rings[1].wedges[10].slot_count)))
	check((saved_piece.center+high_slot.point).distance_to(expected)<0.001,"Highest valid slot uses actual slot_count and position")
	check(view.collapse_feedback.events[0].pieces[4].walls.size()>0,"Standing wall modules retained")
	check(saved_piece.rails.size()==14,"Open boundary rails retained separately from thin band")
	var snapshot: Array = view.collapse_feedback.events.duplicate(true)
	view._presentation_committed_tick(before,sim.last_events,sim._ticks)
	check(view.collapse_feedback.events == snapshot and view.collapse_feedback.admitted.ring == 1,"Same committed tick cannot duplicate effects")
	view._simulation_tick(1.0/60.0)
	view._simulation_tick(1.0/60.0)
	check(view.collapse_feedback.admitted.ring == 1,"Multiple ticks per draw retain first event once")
	var last_tick: int = view.collapse_feedback.last_tick
	view._simulation_tick(0.0)
	check(not view.last_error.is_empty() and view.collapse_feedback.last_tick == last_tick,"Failed tick never enters adapter")
	view.last_error = ""
	view.collapse_feedback.advance(0.4,true,true)
	check(view.collapse_feedback.events == snapshot,"Pause freezes cosmetic age")
	check(view.collapse_feedback.camera_impulse(Vector2.ONE,true,true) == Vector2.ZERO,"Reduced motion has zero camera offset")
	check(view.collapse_feedback.camera_impulse(Vector2.ONE,false,false) == Vector2.ZERO,"Effects off has zero camera offset")
	check(view.collapse_feedback.camera_impulse(Vector2.ONE,false,true).length() <= Feedback.IMPULSE_PIXELS,"Camera impulse bounded in physical stage pixels")
	view.camera.offset = Vector2(5,5)
	view.apply_interface_settings({"effects":true,"reduced_motion":true,"ui_scale":1.0})
	check(view.camera.offset == Vector2.ZERO,"Reduced motion toggle stops offset immediately")
	view.collapse_feedback.advance(3.0,false,true)
	check(view.collapse_feedback.events.is_empty(),"Debris expires after settling")
	check(sim.state.rings[1].collapsed,"Persistent loss remains after transient cleanup")
	var feedback := Feedback.new()
	for bearing in range(1,13):
		var sector := feedback._sector(1,bearing,original.rings[1].wedges[bearing])
		var grid := PolarGrid.new(1)
		check(sector.center.distance_to(grid.polar_to_world(grid.cell_center(Vector2i(1,bearing))))<0.001,"Saved sector matches clock-face bearing %d" % bearing)
	var fake := sim.last_events.duplicate(true)
	fake.collapsed_rings = [1]
	for tick in range(1,41): feedback.admit(original,fake,tick)
	check(feedback.events.size() <= Feedback.MAX_EVENTS and feedback.piece_count() <= Feedback.MAX_PIECES,"Bounded admission stress (explicit adapter diagnostic)")
	feedback.advance(0,false,false)
	check(feedback.events.is_empty(),"Effects-off releases retained geometry")
	feedback.clear()
	check(feedback.last_tick == -1 and feedback.admitted.ring == 0,"Retry reset permits new run tick identifiers")
	view.apply_interface_settings({"effects":false,"reduced_motion":false,"ui_scale":1.0})
	check(view.collapse_feedback.events.is_empty() and sim.state.rings[1].collapsed,"Effects-off preserves actual missing structure")
	await app.audio.shutdown()
	app.queue_free()
	paused = false
	await process_frame
	print("T083 collapse: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
