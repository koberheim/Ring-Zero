extends "res://tests/presentation/test_application.gd"
## Native before/after evidence plus input/persistence checks for the narrow toggle slice.
var phase := "before"
var evidence_dir := ""
var manifest: Array = []
var traversal_frames: Array = []

func traversal_hold(label: String) -> void:
	for sample in range(5):
		await create_timer(0.1).timeout
		await RenderingServer.frame_post_draw
		var filename := "focus-traversal-%03d.png" % traversal_frames.size()
		check(root.get_texture().get_image().save_png(evidence_dir.path_join(filename)) == OK,"Focus traversal frame")
		traversal_frames.append({"file":filename,"time_usec":Time.get_ticks_usec(),"state":label})

func focus_traversal() -> void:
	app.show_settings("start")
	await process_frame
	find_button("Reduced motion").grab_focus()
	await traversal_hold("Reduced motion: keyboard focus")
	for index in range(2):
		var previous: Control = app.stage.gui_get_focus_owner()
		for pressed in [true,false]:
			var event := InputEventKey.new()
			event.keycode = KEY_TAB
			event.physical_keycode = KEY_TAB
			event.pressed = pressed
			root.push_input(event)
		await process_frame
		check(app.stage.gui_get_focus_owner() != previous,"Actual Tab advances GUI focus")
		await traversal_hold("Tab traversal %d" % (index+1))
	app.controller.point = find_button("Weapon feedback").get_global_rect().get_center()
	var pad_motion := InputEventJoypadMotion.new()
	pad_motion.axis = JOY_AXIS_LEFT_X
	pad_motion.axis_value = 0.0
	root.push_input(pad_motion)
	await process_frame
	await traversal_hold("Controller virtual pointer over Weapon feedback")
	await accept_pad()
	check(app.progress.settings.effects,"Controller A enables feedback during recorded sequence")
	await traversal_hold("Controller A: feedback enabled")

func _initialize() -> void:
	create_timer(90.0).timeout.connect(func(): push_error("T086 capture deadline"); quit(1))
	call_deferred("_run")

func capture_t086(label: String, scale_value: float) -> void:
	await create_timer(0.12).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var filename := "%s-%dx%d-%d.png" % [label,root.size.x,root.size.y,roundi(scale_value*100)]
	check(root.get_texture().get_image().save_png(evidence_dir.path_join(filename)) == OK,"Native capture "+filename)
	manifest.append({"file":filename,"viewport":[root.size.x,root.size.y],"stage":[app.stage.size.x,app.stage.size.y],"ui_scale":scale_value,"palette":1,"menu_phase":0,"seed":"not applicable: menu","tick":0,"actors":0})

func move_pointer(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = app.frame.position + point*app.frame.scale
	root.push_input(event)

func accept_key() -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = KEY_SPACE
		event.physical_keycode = KEY_SPACE
		event.pressed = pressed
		root.push_input(event)
		await process_frame
	await process_frame

func accept_pad() -> void:
	for pressed in [true,false]:
		var event := InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_A
		event.pressed = pressed
		root.push_input(event)
	await process_frame

func state_gallery(scale_value: float) -> void:
	app.page.hide()
	app.page_decoration.hide()
	var panel := PanelContainer.new()
	panel.position = Vector2(410,190)
	panel.size = Vector2(1740,1030)
	panel.theme = app.ThemeKit.make(scale_value)
	app.shell.add_child(panel)
	var rows := VBoxContainer.new()
	panel.add_child(rows)
	var title := Label.new()
	title.text = "T-086 control states · native diagnostic"
	rows.add_child(title)
	var focused: CheckButton
	var hovered: CheckButton
	for state_name in ["Off", "On", "Disabled off", "Disabled on", "Keyboard / controller focus", "Hover off", "Hover on"]:
		var toggle := CheckButton.new()
		toggle.text = state_name
		toggle.custom_minimum_size.y = 78
		toggle.button_pressed = state_name in ["On","Disabled on","Hover on"]
		toggle.disabled = state_name.begins_with("Disabled")
		rows.add_child(toggle)
		if state_name == "Keyboard / controller focus": focused = toggle
		if state_name == "Hover off": hovered = toggle
	var choice := OptionButton.new()
	choice.add_item("Dropdown choice")
	rows.add_child(choice)
	focused.grab_focus()
	await process_frame
	move_pointer(hovered.get_global_rect().get_center())
	await capture_t086("states-off-hover",scale_value)
	var hover_on := rows.get_child(7) as CheckButton
	move_pointer(hover_on.get_global_rect().get_center())
	await capture_t086("states-on-hover",scale_value)
	panel.queue_free()
	await process_frame

func _run() -> void:
	root.size = Vector2i(2560,1440)
	if "--after" in OS.get_cmdline_user_args(): phase = "after"
	evidence_dir = "res://docs/reviews/presentation-v3/T-086/"+phase
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="):
			evidence_dir = argument.trim_prefix("--evidence-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_dir))
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/t086-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	app.set_process(false)
	for resolution in [Vector2i(2560,1440),Vector2i(1920,1080)]:
		root.size = resolution
		await create_timer(0.2).timeout
		for scale_value in [1.0,1.3]:
			app.progress.settings.ui_scale = scale_value
			app.progress.settings.reduced_motion = false
			app.progress.settings.effects = true
			app._apply_settings()
			app.show_start()
			move_pointer(Vector2(40,40))
			await capture_t086("start",scale_value)
			app.show_settings("start")
			await capture_t086("settings",scale_value)
			await state_gallery(scale_value)
	# Actual native interactions: settings rebuild after each successful persisted change.
	app.progress.settings.ui_scale = 1.0
	app._apply_settings()
	app.show_settings("start")
	await click_control(find_button("Reduced motion"))
	check(app.progress.settings.reduced_motion,"Mouse toggles and saves actual Reduced motion setting")
	find_button("Reduced motion").grab_focus()
	await capture_t086("focus-01-keyboard",1.0)
	await accept_key()
	check(not app.progress.settings.reduced_motion,"Space activates the focused switch")
	find_button("Weapon feedback").grab_focus()
	# Shipping controller A clicks its virtual pointer, not the keyboard focus owner.
	# Position setup is a fixture; the following button events use the real input route.
	app.controller.point = find_button("Weapon feedback").get_global_rect().get_center()
	await capture_t086("focus-02-controller",1.0)
	await accept_pad()
	check(not app.progress.settings.effects,"Controller A clicks the actual switch through its virtual pointer")
	var loaded: Dictionary = app.store.load_profile(app.profile_path)
	check(loaded.ok and not loaded.profile.settings.effects and not loaded.profile.settings.reduced_motion,"Native input changes survive profile reload")
	var disabled_toggle := find_button("Reduced motion")
	disabled_toggle.disabled = true
	await click_control(disabled_toggle)
	check(not app.progress.settings.reduced_motion,"Disabled switch ignores pointer activation")
	if phase == "after": await focus_traversal()
	var file := FileAccess.open(evidence_dir.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"phase":phase,"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"checks":checks,"failures":failures,"captures":manifest,"focus_traversal_frames":traversal_frames},"\t"))
	file.close()
	print("T086 ",phase,": ",checks," checks, ",failures," failures")
	await app.audio.shutdown()
	app.queue_free()
	await process_frame
	quit(1 if failures else 0)
