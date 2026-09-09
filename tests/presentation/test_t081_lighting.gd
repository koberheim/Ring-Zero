extends "res://tests/presentation/test_application.gd"
## Logical resource/cache invariants also run headless. Native pixel/normal/glow
## proof remains capture_t081_lighting.gd and is never inferred from this suite.
func _run() -> void:
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/t081-test-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	app.begin_run(false)
	app.live.set_process(false)
	app.live._refresh_board_cache()
	var original_stamp: Array = app.live.board_stamp.duplicate(true)
	for palette in 3:
		app.live.update_core_lighting(palette,0.35)
		app.live._refresh_board_cache()
		check(app.live.board_stamp == original_stamp,"Dynamic palette does not dirty fortress geometry")
		check(is_equal_approx(app.live.core_response.get_shader_parameter("core_energy"),0.35),"Core health reaches response shader")
	check(app.live.material_viewport.world_2d != app.live.board_viewport.world_2d,"Material/albedo worlds are isolated")
	check(app.live.material_viewport.canvas_transform == app.live.board_viewport.canvas_transform,"Both caches share world projection")
	check(app.live.material_viewport.size == app.live.board_viewport.size,"Both caches share raster size")
	app.live.interface_settings.effects = false
	app.live.update_core_lighting(1,1.0)
	check(not app.live.world_environment.environment.glow_enabled,"Effects-off disables final glow")
	app.live.interface_settings.effects = true
	app.live.interface_settings.reduced_motion = true
	var phase: float = app.live.sun_phase
	app.live._process(0)
	check(app.live.sun_phase == phase,"Reduced motion preserves solar phase")
	check(app.live.world_environment.environment.glow_enabled,"Reduced motion preserves steady illumination")
	app.live.state.rings[1].wedges[1].hp *= 0.5
	app.live._refresh_board_cache()
	check(app.live.board_stamp != original_stamp,"Wedge damage invalidates material and albedo together")
	original_stamp = app.live.board_stamp.duplicate(true)
	app.live.state.rings[1].relay_hp = 0
	app.live._refresh_board_cache()
	check(app.live.board_stamp != original_stamp,"Dead relay changes cached lamp state")
	original_stamp = app.live.board_stamp.duplicate(true)
	app.live.state.rings[1].collapsed = true
	app.live._refresh_board_cache()
	check(app.live.board_stamp != original_stamp,"Collapse invalidates both caches")
	for family in [app.live.mount,app.live.wall_texture,app.live.heads.flak,app.live.band_textures[0],app.live.terrain_textures.debris_field]:
		check(family is CanvasTexture and family.normal_texture != null and family.specular_texture != null,"Shipping hardware family has independent albedo/normal/emission channels")
	check(app.live.world_environment.environment.background_canvas_max_layer == 0,"Post-processing excludes HUD CanvasLayers")
	await app.audio.shutdown()
	app.queue_free()
	paused = false
	await process_frame
	print("T081 logical lighting checks: ",checks," failures: ",failures)
	quit(1 if failures else 0)
