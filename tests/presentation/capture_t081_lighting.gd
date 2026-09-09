extends "res://tests/presentation/test_application.gd"
var output := "res://docs/reviews/presentation-v3/T-081/"
var fixture_metadata := {}
func settle() -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw

func capture(label: String) -> void:
	await settle()
	check(root.get_texture().get_image().save_png(output+label+".png") == OK,"Native capture "+label)

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="): output = argument.trim_prefix("--evidence-dir=").trim_suffix("/")+"/"
	seed(81081)
	root.size = Vector2i(2560,1440)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/t081-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.add_child(app)
	await process_frame
	app.begin_run(false)
	app.live.set_process(false)
	var helper = load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base := BalanceProfile.load_json("res://data/balance/testing.json")
	var sim: LiveSimulation = helper._fixture(base.profile,6,120)
	helper = null
	for bearing in range(1,13): check(sim.place_weapon(3,bearing,0,&"flak").ok,"Representative head bearing %d" % bearing)
	app.live.simulation = sim
	app.live.profile = sim.profile
	app.live.sync_simulation()
	app.live.sun_phase = 0.0
	app.live.sun.material.set_shader_parameter("phase",0.0)
	app.live.camera.position = Vector2.ZERO
	app.live._set_zoom(0.85)
	app.live.camera.force_update_scroll()
	var backend := RenderingServer.get_current_rendering_method()
	var has_light: bool = app.live.has_method("update_core_lighting")
	var prefix := ("lit-" if has_light else "rc2-unlit-")+backend
	fixture_metadata = {"seed":81081,"simulation_seconds":sim.elapsed_seconds,"actors":sim.pool.active_count(),"rings":6,"zoom":0.85,"camera":"(0, 0)","root":"2560x1440","phase":0,"ui_scale":1.0,"backend":backend,"light_adapter":has_light}
	for palette in 3:
		app.live.sun.material.set_shader_parameter("palette",palette)
		if has_light: app.live.update_core_lighting(palette,1.0)
		await capture(prefix+"-palette-"+str(palette))
	if has_light:
		app.live.sun.material.set_shader_parameter("palette",1)
		app.live.update_core_lighting(1,1.0)
		await settle()
		var redraws: int = app.live.board_redraw_count
		app.live.update_core_lighting(0,0.3)
		await capture(prefix+"-low-core")
		check(app.live.board_redraw_count == redraws,"Palette/HP change does not repaint static albedo")
		app.live.update_core_lighting(1,1.0)
		app.live.camera.position += Vector2(60,30)
		app.live.camera.force_update_scroll()
		app.live._refresh_board_cache()
		await capture(prefix+"-pan")
		check(app.live.board_redraw_count == redraws,"Strategic pan reuses anchored fortress raster")
		app.live.tactical = true
		app.live._refresh_board_cache()
		await capture(prefix+"-alt")
		check(app.live.board_redraw_count > redraws,"Alt invalidates retained commands")
		app.live.tactical = false
		app.live.camera.position = Vector2.ZERO
		app.live._set_zoom(1.65)
		app.live._refresh_board_cache()
		await capture(prefix+"-detail")
		check(app.live.material_redraw_count == app.live.board_redraw_count,"Material and albedo invalidations agree")
		await settle()
		app.live.board_viewport.get_texture().get_image().save_png(output+prefix+"-albedo.png")
		app.live.material_viewport.get_texture().get_image().save_png(output+prefix+"-normal-emission.png")
		var normal_image: Image = app.live.material_viewport.get_texture().get_image()
		var normal_trials := []
		for bearing in range(1,13):
			var point: Vector2 = app.live.grid.polar_to_world(BuildingRules.slot_position(3,bearing,0,app.live._slot_count(3,bearing)))
			var probe_point := point+Vector2(0,-18).rotated(point.angle()-PI/2)
			var pixel: Vector2i = Vector2i(app.live.material_viewport.canvas_transform*probe_point)
			var packed := normal_image.get_pixelv(pixel)
			var n := Vector2(packed.r,packed.g)/maxf(packed.a,0.001)*2.0-Vector2.ONE
			var inward_dot := n.normalized().dot(-point.normalized())
			normal_trials.append({"bearing":bearing,"inward_dot":inward_dot,"normal":str(n),"alpha":packed.a})
			check(packed.a>0.9 and inward_dot>0.75,"Inward head bevel agrees with core at bearing %d" % bearing)
		fixture_metadata["normal_trials"] = normal_trials
		app.live.hit_effects.append({"kind":&"lance_emitter","from":Vector2(120,-260),"to":Vector2(330,-320),"remaining":0.2})
		app.live.queue_redraw()
		await capture(prefix+"-weapon")
		app.live.world_environment.environment.glow_enabled = false
		await capture(prefix+"-weapon-no-glow")
		# Identical white emitters on opaque black, one world and one UI layer.
		# Native readback proves bloom composition without relying on node names.
		var world_probe := Node2D.new()
		world_probe.transform = app.stage.get_canvas_transform().affine_inverse()
		app.live.add_child(world_probe)
		var ui_layer := CanvasLayer.new()
		ui_layer.layer = 5
		app.stage.add_child(ui_layer)
		for entry in [[world_probe,Vector2(2200,800)],[ui_layer,Vector2(2200,1050)]]:
			var black := ColorRect.new()
			black.color = Color.BLACK
			black.position = entry[1]
			black.size = Vector2(160,160)
			black.mouse_filter = Control.MOUSE_FILTER_IGNORE
			entry[0].add_child(black)
			var white := ColorRect.new()
			white.color = Color.WHITE
			white.position = Vector2(60,60)
			white.size = Vector2(40,40)
			white.mouse_filter = Control.MOUSE_FILTER_IGNORE
			black.add_child(white)
		app.live.world_environment.environment.glow_enabled = true
		print("ENV ",app.live.world_environment.get_viewport()==app.stage," OWN ",app.stage.world_3d.environment==app.live.world_environment.environment," DISABLE3D ",app.stage.disable_3d)
		await capture(prefix+"-glow-proof-on")
		var glow_on := root.get_texture().get_image()
		app.live.world_environment.environment.glow_enabled = false
		await capture(prefix+"-glow-proof-off")
		var glow_off := root.get_texture().get_image()
		var world_halo := 0.0
		var ui_difference := 0.0
		for y in range(45,115):
			for x in range(45,115):
				if x>=60 and x<100 and y>=60 and y<100: continue
				world_halo += glow_on.get_pixel(x+2200,y+800).r-glow_off.get_pixel(x+2200,y+800).r
				ui_difference += absf(glow_on.get_pixel(x+2200,y+1050).r-glow_off.get_pixel(x+2200,y+1050).r)
		check(world_halo>1.0,"World bright sample produces native glow outside its silhouette")
		check(ui_difference<0.01,"UI bright sample produces no glow outside its silhouette")
		fixture_metadata["glow_world_halo_sum"] = world_halo
		fixture_metadata["glow_ui_halo_difference"] = ui_difference
		fixture_metadata["lighting"] = app.live.lighting_state()
	var file := FileAccess.open(output+prefix+"-fixture.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture_metadata,"\t"))
	file.close()
	await app.audio.shutdown()
	app.queue_free()
	paused = false
	await process_frame
	print("T081 native capture checks: ",checks," / failures: ",failures)
	quit(1 if failures else 0)
