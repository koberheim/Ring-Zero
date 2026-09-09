extends "res://tests/presentation/test_application.gd"
## Run rendered: validates native cache lifetime and camera/picking coherence.
func _settle() -> void:
	app.live.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw

func _run() -> void:
	root.size=Vector2i(2560,1440)
	app=load("res://scenes/application.tscn").instantiate()
	app.profile_path="res://.godot/release-profiles/cache-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	app.begin_run(false)
	app.live.set_process(false)
	await _settle()
	check(app.live.board_viewport.size==Vector2i(2560,1440),"Fortress raster matches native viewport")
	var redraws: int=app.live.board_redraw_count
	for frame in 5: await _settle()
	check(app.live.board_redraw_count==redraws,"Stable fortress incurs no repeated draw submissions")
	app.live.camera.position+=Vector2(41,-29)
	app.live.camera.force_update_scroll()
	await _settle()
	check(app.live.board_redraw_count==redraws,"Pan reuses a world-anchored full-fortress raster")
	var native_transform: Transform2D=app.stage.get_canvas_transform()*app.live.board_sprite.transform
	check(native_transform.x.is_equal_approx(Vector2.RIGHT) and native_transform.y.is_equal_approx(Vector2.DOWN),"Composite retains one native pixel per screen pixel after pan")
	redraws=app.live.board_redraw_count
	app.live._set_zoom(1.73)
	await _settle()
	check(app.live.board_redraw_count>redraws,"Zoom invalidates cached raster")
	var point:=Vector2(135,44)
	var cached_pixel: Vector2=app.live.board_viewport.canvas_transform*point
	var composite_point: Vector2=app.stage.get_canvas_transform()*app.live.board_sprite.transform*cached_pixel
	check(composite_point.distance_to(app.stage.get_canvas_transform()*point)<0.001,"Composite and picking remain aligned after zoom")
	redraws=app.live.board_redraw_count
	app.live.state.rings[1].wedges[1].hp*=0.5
	await _settle()
	check(app.live.board_redraw_count>redraws,"Damage invalidates working lamps")
	redraws=app.live.board_redraw_count
	app.live.tactical=true
	await _settle()
	check(app.live.board_redraw_count>redraws,"Tactical overlay invalidates raster")
	redraws=app.live.board_redraw_count
	await _settle()
	check(app.live.board_redraw_count==redraws,"Holding unchanged tactical view stays cached")
	app.live.camera.offset=Vector2(2,3)
	await _settle()
	check(app.live.board_redraw_count==redraws,"Camera shake moves full raster without repainting")
	print("World cache assertions: ",checks," failures: ",failures)
	await app.audio.shutdown()
	app.queue_free()
	paused=false
	await process_frame
	quit(1 if failures else 0)
