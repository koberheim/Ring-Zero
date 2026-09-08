extends SceneTree
## GPU evidence of T-079 in the existing art preview scene.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1440,810)
	var view = load("res://scenes/art_preview.tscn").instantiate()
	root.add_child(view)
	view.set_process(false)
	await process_frame
	var fixture = view.get_node("ProductionArtReview/Fixture")
	fixture.get_parent().show()
	for mode in 5:
		for page in fixture.page_count(mode):
			fixture.set_review(mode,page)
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://docs/reviews/artifacts/T-079-%s-%02d.png" % [["close","strategic","yellow","crowd","rotations"][mode],page+1]
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Capture failed: " + path)
				quit(1)
				return
			print("Saved " + path)
	quit(0)
