extends SceneTree
## Native 1440p renderer study, independent of the application shell.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(2560,1440)
	var view = load("res://scenes/release_view.tscn").instantiate()
	root.add_child(view)
	await process_frame
	view.set_process(false)
	view.sun.material.set_shader_parameter("palette",1)
	view.sun.material.set_shader_parameter("phase",35.0)
	for child in view.get_children():
		if child is CanvasLayer and child.layer>=0: child.hide()
	view._set_zoom(2.6)
	view.camera.force_update_scroll()
	await _capture("world-opening")
	var helper = load("res://tests/presentation/application_crowd_fixture.gd").new()
	var base := BalanceProfile.load_json("res://data/balance/testing.json")
	view.simulation = helper._fixture(base.profile,6,120)
	view.profile = view.simulation.profile
	view.sync_simulation()
	view._set_zoom(0.85)
	view.camera.force_update_scroll()
	await _capture("world-fortress")
	view._set_zoom(2.8)
	view.camera.position=Vector2(350,240)
	view.camera.force_update_scroll()
	await _capture("world-detail")
	view.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var directory := "res://.godot/release-qa/world-art"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	root.get_texture().get_image().save_png(directory+"/"+label+".png")
