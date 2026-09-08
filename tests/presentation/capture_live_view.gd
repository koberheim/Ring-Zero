extends "res://tests/presentation/test_live_view.gd"
## Isolated render/measurement fixtures; never attached to the playable scene.

func screenshot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	check(rendered != null and not rendered.is_empty(), "Rendered image exists")
	check(rendered.get_size() == Vector2i(1280, 900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-018-" + name + ".png") == OK, "PNG saved")

func percentile(values: Array[float], fraction: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	if fraction == 0.5:
		return (sorted[(sorted.size() - 1) / 2] + sorted[sorted.size() / 2]) * 0.5
	return sorted[maxi(0, ceili(fraction * sorted.size()) - 1)]

func measure_load() -> void:
	fixture({"health": {"standard_machine_hp": 1.0e12, "wedge_base_hp": 1.0e12}, "standard_machine": {"damage_per_second": 0.01}})
	view.simulation.state.energy = 10000
	for wedge in range(1, 12):
		if wedge != 6:
			check(view.simulation.place_weapon(1, wedge, 0, &"flak").ok, "Load fixture Flak placement")
	for index in 1000:
		check(spawn_at(2, index % 12 + 1, 0.0, 1.0e12, 0.01, 1.0) >= 0, "Load fixture machine allocated")
	view.sync_simulation()
	view.set_process(true)
	var warmed_at := Time.get_ticks_usec()
	while Time.get_ticks_usec() - warmed_at < 3000000:
		await process_frame
	var intervals: Array[float] = []
	var cpu: Array[float] = []
	var sync_cpu: Array[float] = []
	var draw_cpu: Array[float] = []
	var quote_cpu: Array[float] = []
	var tick_counts: Array[float] = []
	var residual: Array[float] = []
	var counts: Array[int] = []
	var previous := Time.get_ticks_usec()
	for frame in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append(float(now - previous) / 1000.0)
		previous = now
		cpu.append(float(view.simulation_cpu_usec) / 1000.0)
		sync_cpu.append(float(view.sync_cpu_usec) / 1000.0)
		draw_cpu.append(float(view.draw_cpu_usec) / 1000.0)
		quote_cpu.append(float(view.quote_cpu_usec) / 1000.0)
		tick_counts.append(float(view.simulation_ticks_per_frame))
		residual.append(intervals.back() - cpu.back() - sync_cpu.back() - draw_cpu.back())
		counts.append(view.simulation.pool.active_count())
	check(counts.min() == 1000 and counts.max() == 1000, "Full cap sustained")
	check(view.marker_instances.instance_count == 1000 and view.target_points.size() == 1000, "All 1000 machine markers retained in batch")
	check(view.last_error.is_empty() and not view.simulation.ended, "Load runs without runtime error or loss")
	print("Rendered load: 1000 durable machines, 11 Flak, 3-second warmup, 120 frames")
	print("Frame interval ms: median=%.3f p90=%.3f" % [percentile(intervals, 0.5), percentile(intervals, 0.9)])
	print("Simulation CPU ms per frame (step calls only): median=%.3f p90=%.3f" % [percentile(cpu, 0.5), percentile(cpu, 0.9)])
	print("Snapshot/refresh CPU ms: median=%.3f p90=%.3f" % [percentile(sync_cpu, 0.5), percentile(sync_cpu, 0.9)])
	print("Quote CPU ms (included in refresh): median=%.3f p90=%.3f" % [percentile(quote_cpu, 0.5), percentile(quote_cpu, 0.9)])
	print("Draw submission CPU ms: median=%.3f p90=%.3f" % [percentile(draw_cpu, 0.5), percentile(draw_cpu, 0.9)])
	print("Simulation ticks/frame: median=%.1f p90=%.1f total=%d" % [percentile(tick_counts, 0.5), percentile(tick_counts, 0.9), tick_counts.reduce(func(total, item): return total + item, 0)])
	print("Unattributed frame interval ms (engine/render/VSync/scheduling): median=%.3f p90=%.3f" % [percentile(residual, 0.5), percentile(residual, 0.9)])
	print("Renderer=%s adapter=%s VSync=%d max_fps=%d" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(), DisplayServer.window_get_vsync_mode(), Engine.max_fps])
	view.set_process(false)

func _run() -> void:
	root.size = Vector2i(1280, 900)
	view = load("res://scenes/live_view.tscn").instantiate()
	root.add_child(view)
	await process_frame
	if "--measure" in OS.get_cmdline_user_args():
		view.set_process(false)
		await measure_load()
	else:
		# Natural default pressure and frame loop, with no purchases or overrides.
		while view.simulation.elapsed_seconds < 6.0 and not view.simulation.ended:
			await process_frame
		view.set_process(false)
		check(view.rendered_targets.size() > 0 and not view.simulation.ended, "Natural early combat visible")
		button(MOUSE_BUTTON_WHEEL_UP, true, Vector2(950, 700))
		await process_frame
		await RenderingServer.frame_post_draw
		check(is_equal_approx(view.marker_instances.get_instance_transform_2d(0).x.length() * view.camera.zoom.x, 3.0), "Rendered marker radius stays three pixels after zoom")
		button(MOUSE_BUTTON_WHEEL_DOWN, true, Vector2(950, 700))
		print("Natural capture elapsed=%.3f active=%d energy=%s core_hp=%s" % [view.simulation.elapsed_seconds, view.rendered_targets.size(), str(view.state.energy), str(view.simulation.core_hp)])
		await screenshot("early-combat")
		collapse_fixture()
		check(view.state.rings[1].collapsed and view._cell_owned(Vector2i(2, 3)), "Authentic collapse fixture preserves outer ring")
		await screenshot("inner-collapse")
		loss_fixture()
		check(view.simulation.ended, "Authentic core loss fixture")
		await screenshot("core-loss")
	print("Live render checks: %d passed, %d failed" % [checks - failures, failures])
	quit(1 if failures else 0)
