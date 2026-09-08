extends SceneTree
## Actual GPU captures of the T-078 fixture inside the existing art preview.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1440, 810)
	var view = load("res://scenes/art_preview.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	var fixture = view.get_node("VerticalSliceReview/Fixture")
	fixture.get_parent().show()
	for mode in 5:
		fixture.set_mode(mode)
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered := root.get_texture().get_image()
		var path := "res://docs/reviews/artifacts/T-078-%s.png" % ["close", "strategic", "yellow", "crowd", "rotations"][mode]
		if rendered.save_png(path) != OK:
			push_error("Capture failed: " + path)
			quit(1)
			return
		print("Saved " + path)
	quit(0)
