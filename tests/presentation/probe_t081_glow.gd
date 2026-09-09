extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,720)
	var world := WorldEnvironment.new()
	world.environment = load("res://src/presentation/lighting/fortress_lighting.gd").environment()
	world.environment.glow_hdr_threshold = 0.1
	world.environment.glow_intensity = 2.0
	world.environment.glow_bloom = 0.5
	root.add_child(world)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(1280,720)
	root.add_child(bg)
	var box := ColorRect.new()
	box.color = Color.WHITE
	box.position = Vector2(500,200)
	box.size = Vector2(200,200)
	root.add_child(box)
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://docs/reviews/presentation-v3/T-081/glow-isolated.png")
	print("glow=",world.environment.glow_enabled," background=",world.environment.background_mode," halo=",image.get_pixel(480,300)," center=",image.get_pixel(550,300))
	quit()
