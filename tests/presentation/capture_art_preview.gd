extends "res://tests/presentation/test_art_preview.gd"

func rendered_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func screenshot(name: String) -> Image:
	var rendered := await rendered_image()
	check(rendered.get_size() == Vector2i(1280,900), "Capture dimensions")
	check(rendered.save_png("res://docs/reviews/artifacts/T-049-" + name + ".png") == OK, "Saved " + name)
	return rendered

func median(samples: Array[float]) -> float:
	var ordered := samples.duplicate()
	ordered.sort()
	return (ordered[59] + ordered[60]) * 0.5

func measure(treatment: int) -> void:
	view.set_treatment(treatment)
	view.strategic_view()
	view.set_process(true)
	for frame in 30:
		await process_frame
	var positions_before := target_values()
	var frames: Array[float] = []
	var sim: Array[float] = []
	var sync: Array[float] = []
	var draw: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		frames.append(float(now-previous)/1000.0)
		previous = now
		sim.append(float(view.simulation_cpu_usec)/1000.0)
		sync.append(float(view.sync_cpu_usec)/1000.0)
		draw.append(float(view.draw_cpu_usec)/1000.0)
	view.set_process(false)
	check(target_values() == positions_before and view.simulation.pool.active_count() == 100, "All100 contact actors stay stationary and durable during measured window")
	var ordered := frames.duplicate()
	ordered.sort()
	print("ART rendered treatment=%d rings=12 actors=%d frames=120 vsync=%d frame_median_ms=%.3f p90_ms=%.3f sim_median_ms=%.3f sync_median_ms=%.3f draw_median_ms=%.3f" % [treatment,view.simulation.pool.active_count(),DisplayServer.window_get_vsync_mode(),median(frames),ordered[107],median(sim),median(sync),median(draw)])

func _run() -> void:
	root.size = Vector2i(1280,900)
	view = load("res://scenes/art_preview.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	await process_frame
	quiet_main()
	await grow_to_twelve()
	view.close_core()
	view.tabs.current_tab = 0
	await process_frame
	control_click(view.emp_node_button)
	slot_click(1,3,0)
	control_click(view.lance_emitter_button)
	slot_click(2,4,0)
	control_click(view.flak_button)
	slot_click(2,5,0)
	view.tabs.current_tab = 1
	await process_frame
	control_click(view.wall_button)
	slot_click(2,4,0)
	view.simulation.state.rings[2].wedges[5].hp = 0
	check(view.simulation.state.rings[2].wedges[5].occupants.has(0), "Broken capture preserves its real retained occupant")
	view.sync_simulation()
	view.choose_build(&"")
	for treatment in range(2):
		view.set_treatment(treatment)
		view.close_core()
		await screenshot("%s-close" % ["industrial","painterly"][treatment])
		view.strategic_view()
		await screenshot("%s-strategic" % ["industrial","painterly"][treatment])
	view.close_core()
	for palette in range(3):
		view.set_sun_palette(palette)
		await screenshot("sun-%s" % ["red","yellow","white"][palette])
	view.set_sun_palette(1)
	view.set_sun_motion(false)
	var frozen_a := await rendered_image()
	view._process(0.1)
	var frozen_b := await rendered_image()
	check(frozen_a.get_data() == frozen_b.get_data(), "Motion off produces identical actual rendered pixels")
	view.set_sun_motion(true)
	var animation_start := await rendered_image()
	view._process(1.0)
	var animation_end := await rendered_image()
	check(animation_start.get_data() != animation_end.get_data(), "Advancing sun clock changes actual rendered pixels")
	if "--animation" in OS.get_cmdline_user_args():
		for frame in 60:
			view._process(0.1)
			var rendered := await rendered_image()
			rendered.save_png("res://.godot/t049-animation-%03d.png" % frame)
	# Durable stationary approaches: no resets, no pressure tuning in production.
	for index in 100:
		spawn_at(13,index%12+1,0.0,1000000,0,1)
	view.sync_simulation()
	await measure(0)
	await measure(1)
	check(view.last_error.is_empty(), "Rendered comparison simulation remains valid")
	print("Art capture checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
