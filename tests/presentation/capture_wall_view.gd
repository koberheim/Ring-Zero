extends "res://tests/presentation/test_wall_view.gd"
## Bounded rendering/measurement fixtures; never attached to the normal scene.
var measured_hits := 0
var measured_wall_breaks := 0
var measured_wedge_breaks := 0

func fixture(overrides: Dictionary = {}) -> void:
	super.fixture(overrides)
	# Comparable normal-load fixtures now exercise the enabled live feature flag.
	var created := LiveSimulation.create(view.profile, 3, true)
	check(created.ok, "Feature-enabled load fixture valid")
	view.simulation = created.simulation
	view.sync_simulation()

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered != null and not rendered.is_empty(), "Rendered image exists")
	check(rendered.get_size() == Vector2i(1280, 900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-022-" + name + ".png") == OK, "PNG saved")

func percentile(values: Array[float], fraction: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	if fraction == 0.5:
		return (sorted[(sorted.size() - 1) / 2] + sorted[sorted.size() / 2]) * 0.5
	return sorted[maxi(0, ceili(fraction * sorted.size()) - 1)]

func measured_tick(delta: float) -> void:
	view._simulation_tick(delta)
	measured_hits += view.simulation.last_events.hits.size()
	measured_wall_breaks += view.simulation.last_events.walls_broken.size()
	measured_wedge_breaks += view.simulation.last_events.broken_wedges.size()

func structure_hp() -> Dictionary:
	var total := {"wedge": 0.0, "wall": 0.0}
	for ring in view.state.rings.values():
		for wedge in ring.wedges.values():
			total.wedge += wedge.hp
			if wedge.has("wall"):
				total.wall += wedge.wall.hp
	return total

func measure_load(angular: bool) -> void:
	fixture({"health": {"standard_machine_hp": 1.0e8, "wedge_base_hp": 1.0e8, "wall_hp": 1.0e8}, "standard_machine": {"damage_per_second": 1.0}})
	view.simulation.state.energy = 100000
	for wedge in range(1, 12):
		if wedge != 6:
			check(view.simulation.place_weapon(1, wedge, 0, &"flak").ok, "Load fixture Flak placement")
	var outer := 1
	if angular:
		check(view.simulation.purchase_ring().ok, "Angular fixture buys ring two")
		check(view.simulation.purchase_ring().ok, "Angular fixture buys ring three")
		outer = 3
	for wedge in range(1, 13):
		if not angular or wedge != 12:
			check(view.simulation.place_wall(outer, wedge).ok, "Load fixture wall placement")
	for index in 1000:
		var wedge := index % 3 + 5 if angular else index % 12 + 1
		check(spawn_at(outer + 1, wedge, 0, 1.0e8, 1.0, 1.0) >= 0, "Load machine allocated")
	view.sync_simulation()
	view.clock = FixedStepClock.new(60.0, measured_tick)
	view.set_process(true)
	var started := Time.get_ticks_usec()
	while Time.get_ticks_usec() - started < 3000000:
		await process_frame
	var before_targets := target_values()
	var before_hp := structure_hp()
	var before_routes: int = view.simulation.route_rebuild_count
	var before_elapsed: float = view.simulation.elapsed_seconds
	measured_hits = 0
	measured_wall_breaks = 0
	measured_wedge_breaks = 0
	var frame_ms: Array[float] = []
	var sim_ms: Array[float] = []
	var sync_ms: Array[float] = []
	var draw_ms: Array[float] = []
	var ticks_per_frame: Array[float] = []
	var active_counts: Array[int] = []
	var angular_frames := 0
	var previous_probes := [before_targets[0], before_targets[1], before_targets[2]]
	var previous := Time.get_ticks_usec()
	for frame in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		if now - started > 25000000:
			check(false, "Benchmark exceeded 25-second wall-clock deadline before 120 frames")
			break
		frame_ms.append(float(now - previous) / 1000.0)
		previous = now
		sim_ms.append(float(view.simulation_cpu_usec) / 1000.0)
		sync_ms.append(float(view.sync_cpu_usec) / 1000.0)
		draw_ms.append(float(view.draw_cpu_usec) / 1000.0)
		ticks_per_frame.append(float(view.simulation_ticks_per_frame))
		active_counts.append(view.simulation.pool.active_count())
		var probes_moved := true
		for index in 3:
			var position: PolarPosition = view.rendered_targets[index].position
			probes_moved = probes_moved and (position.wedge != previous_probes[index][2] or not is_equal_approx(position.angular_fraction, previous_probes[index][4]))
			previous_probes[index] = [0, position.ring, position.wedge, position.radial_fraction, position.angular_fraction]
		if probes_moved:
			angular_frames += 1
	view.set_process(false)
	var after_targets := target_values()
	var changed_angles := 0
	for index in mini(before_targets.size(), after_targets.size()):
		if before_targets[index][2] != after_targets[index][2] or not is_equal_approx(before_targets[index][4], after_targets[index][4]):
			changed_angles += 1
	var after_hp := structure_hp()
	check(frame_ms.size() == 120, "All 120 full-scene frames measured")
	check(active_counts.min() == 1000 and active_counts.max() == 1000 and view.marker_instances.instance_count == 1000, "All 1000 active machines and markers retained")
	check(view.last_error.is_empty() and not view.simulation.ended, "Load has no runtime error or core loss")
	check(view.tunneler_warnings.is_empty() and view.triangle_instances.instance_count == 0, "No Tunneler due before default first arrival")
	if angular:
		check(angular_frames == 120 and changed_angles == 1000, "Angular fixture remains moving throughout measured window")
	print("Wall rendered fixture=%s outer_ring=%d machines=1000 Flak=11 warmup=3s frames=%d" % ["angular" if angular else "sealed", outer, frame_ms.size()])
	for entry in [["Frame", frame_ms], ["Simulation", sim_ms], ["Sync", sync_ms], ["Draw", draw_ms], ["Ticks/frame", ticks_per_frame]]:
		print("%s median=%.3f p90=%.3f" % [entry[0], percentile(entry[1], 0.5), percentile(entry[1], 0.9)])
	print("Tick total=%d route rebuilds=%d active min=%d max=%d simulation interval=%.3f" % [ticks_per_frame.reduce(func(total, item): return total + item, 0), view.simulation.route_rebuild_count - before_routes, active_counts.min(), active_counts.max(), view.simulation.elapsed_seconds - before_elapsed])
	print("Angular probe frames=%d/120 changed machine angles=%d weapon hits=%d walls broken=%d wedges broken=%d" % [angular_frames, changed_angles, measured_hits, measured_wall_breaks, measured_wedge_breaks])
	print("Structure HP delta: wedge=%s wall=%s" % [str(after_hp.wedge - before_hp.wedge), str(after_hp.wall - before_hp.wall)])
	print("Phase counts: normal circles=%d underground warnings=%d surfaced triangles=%d" % [view.marker_instances.instance_count, view.tunneler_warnings.size(), view.triangle_instances.instance_count])
	print("Renderer=%s adapter=%s VSync=%d max_fps=%d" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(), DisplayServer.window_get_vsync_mode(), Engine.max_fps])

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	view.tabs.current_tab = 1
	await process_frame
	var args := OS.get_cmdline_user_args()
	if "--sealed" in args or "--angular" in args:
		await measure_load("--angular" in args)
	else:
		wall_fixture(12)
		for wedge in [1, 2, 3, 4, 8, 9, 10, 11]:
			spawn_at(2, wedge, 0, 100000, 8)
		ticks(35)
		slot_click(1, 3, 0)
		await process_frame
		await RenderingServer.frame_post_draw
		check(view.marker_instances.get_instance_transform_2d(0).origin.is_equal_approx(view.target_points[0]), "Actual batched marker transform follows angular snapshot")
		check(not is_equal_approx(view.rendered_targets[0].position.angular_fraction, 0.5), "Captured open-gap marker is angularly displaced")
		await screenshot("open-gap-funnel")
		wall_fixture(0)
		spawn_at(2, 3, 0, 100000, 8)
		ticks(60)
		slot_click(1, 3, 0)
		await screenshot("sealed-wall-damage")
		view.simulation.state.rings[1].wedges[3].wall.hp = 0.01
		ticks(1)
		spawn_at(2, 4, 0, 100000, 8)
		ticks(10)
		await screenshot("wall-breach")
		wall_collapse_fixture()
		slot_click(2, 3, 1)
		await screenshot("wall-ring-collapse")
	print("Wall render checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
