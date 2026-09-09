extends "res://tests/presentation/test_application.gd"

func send_key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	root.push_input(event)

func _run() -> void:
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/native-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	for window_size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440),Vector2i(1600,1000)]:
		root.size = window_size
		await process_frame
		await process_frame
		check(app.stage.size == window_size,"Native render resolution matches the window, not a fixed downsampled buffer")
		check(is_equal_approx(app.frame.scale.x,app.frame.scale.y),"Window resizing never distorts the game")
		check(app.frame.size == Vector2(window_size) and app.frame.position == Vector2.ZERO,"Game frame fills the window exactly at native resolution")
		check(Rect2(Vector2.ZERO,Vector2(window_size)).grow(1).has_point(find_button("Start run").get_global_rect().get_center()),"Launch control remains reachable after resize")
	await click_control(find_button("Start run"))
	check(app.live != null,"Transformed launch click starts the actual game")
	if app.live == null: quit(1); return
	app.live.set_process(false)
	var navigation: Node = app.get_node("CameraNavigation")
	navigation.set_process(false)
	var before: Dictionary = app.live.state.duplicate(true)
	var origin: Vector2 = app.live.camera.position
	send_key(KEY_W,true)
	navigation._process(1.0/60.0)
	check(app.live.camera.position.y < origin.y,"W pans the actual application map upward")
	check(app.live.state == before and app.live.build_mode == &"","W does not select or purchase a wall")
	send_key(KEY_W,false)
	var stopped: Vector2 = app.live.camera.position
	navigation._process(1.0/60.0)
	check(app.live.camera.position == stopped,"Releasing W stops map movement")
	send_key(KEY_D,true)
	navigation._process(1.0/60.0)
	check(app.live.camera.position.x > origin.x,"D pans right without selecting terrain")
	app.live.set_menu_open(true)
	stopped = app.live.camera.position
	navigation._process(1.0/60.0)
	check(app.live.camera.position == stopped and navigation.held.is_empty(),"Pause clears held movement and freezes camera")
	send_key(KEY_D,false)
	app.live.set_menu_open(false)
	send_key(PCSettings.bindings["Wall"],true)
	send_key(PCSettings.bindings["Wall"],false)
	check(app.live.build_mode == &"wall","Remapped wall key still reaches the build command")
	app.live.choose_build(&"")
	app.live.camera.position = Vector2.ZERO
	var energy: float = app.live.state.energy
	send_key(KEY_1,true)
	send_key(KEY_1,false)
	world_slot(1,3)
	check(app.live.state.energy < energy,"World purchase still targets the intended slot after WASD and letterboxing")
	app.queue_free()
	paused = false
	await process_frame
	print("Native presentation integration: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
