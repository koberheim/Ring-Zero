extends SceneTree
## External packaged-input verifier. Never included in the PCK, no gameplay grants.
var app: Control
var checks := 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func(): push_error("Packaged driver deadline"); quit(1))
	call_deferred("_run")

func check(value: bool, label: String) -> bool:
	checks += 1
	if not value:
		push_error("Packaged verification: " + label)
		quit(1)
	return value

func find_button(label: String, node: Node) -> Button:
	if node is Button and node.text == label and node.is_visible_in_tree(): return node
	for child in node.get_children():
		var found := find_button(label,child)
		if found != null: return found
	return null

func mouse(point: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = app.frame.position + point * app.frame.scale
	root.push_input(motion)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.pressed = pressed
		event.position = motion.position
		event.global_position = event.position
		root.push_input(event)

func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event)

func click(button: Button) -> void:
	if not check(button != null,"Visible requested button exists"): return
	await process_frame
	mouse(button.get_global_rect().get_center())
	await process_frame

func write_result(name: String, data: Dictionary) -> bool:
	var file := FileAccess.open("user://packaged-" + name + ".json",FileAccess.WRITE)
	if not check(file != null,"Write isolated package evidence"): return false
	file.store_string(JSON.stringify(data,"",true,true))
	file.flush()
	var error := file.get_error()
	file.close()
	return check(error == OK,"Package evidence persisted")

func _run() -> void:
	app = load("res://scenes/application.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	if not check(app.state == "start","Packaged application starts normally"): return
	if "--verify-reload" in OS.get_cmdline_user_args():
		var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://packaged-first.json"))
		if not check(previous is Dictionary,"Prior process evidence exists"): return
		if not check(FileAccess.get_file_as_string("user://profile.json").sha256_text() == previous.profile_sha256,"Independent application reload preserves exact profile bytes"): return
		if not check(app.progress.currency == 0 and app.progress.pending_run_id == "" and app.progress.next_run_id == 2,"Reloaded actual zero-reward settlement"): return
		if not write_result("reload",{"ok":true,"checks":checks,"profile_sha256":previous.profile_sha256,"build":previous.build}): return
		print("Packaged reload: %d checks passed; requesting real Quit button" % checks)
		await click(find_button("Quit",app))
		return
	if not check(app.progress.currency == 0 and app.progress.next_run_id == 1,"Fresh isolated profile, no grants"): return
	await click(find_button("Start run",app))
	if not check(app.state == "playing" and app.live != null,"Actual Start input begins normal run"): return
	var sim: Variant = app.live.simulation
	var initial_energy: float = sim.state.energy
	await create_timer(0.75).timeout
	if not check(sim._ticks >= 5 and not sim.ended,"Unmodified real-time simulation advances"): return
	key(KEY_1)
	await process_frame
	app.live.camera.force_update_scroll()
	var slots: int = sim.state.rings[1].wedges[3].slot_count
	var polar: Variant = load("res://src/gameplay/building_rules.gd").slot_position(1,3,0,slots)
	var point: Vector2 = app.stage.get_canvas_transform() * app.live.grid.polar_to_world(polar)
	mouse(point)
	await process_frame
	if not check(sim.state.rings[1].wedges[3].occupants.has(0) and sim.state.rings[1].wedges[3].occupants[0].kind == &"flak" and sim.state.energy < initial_energy,"Real key/world click buys Flak once"): return
	mouse(point,MOUSE_BUTTON_RIGHT)
	key(KEY_ESCAPE)
	await process_frame
	if not check(app.live.menu_open and paused,"Actual Escape pauses"): return
	var paused_tick: int = sim._ticks
	await create_timer(0.1).timeout
	if not check(sim._ticks == paused_tick,"Pause retains exact tick"): return
	key(KEY_ESCAPE)
	await create_timer(0.15).timeout
	if not check(not paused and sim._ticks > paused_tick,"Actual Escape resumes real simulation"): return
	key(KEY_ESCAPE)
	await process_frame
	var trace_path: String = app.trace_path
	await click(find_button("Abandon run and return",app))
	if not check(app.state == "start" and app.progress.currency == 0 and app.progress.pending_run_id == "","Actual abandon persists zero reward and returns to start"): return
	var parsed: Dictionary = load("res://src/core/run_recorder.gd").load_trace(trace_path)
	if not check(parsed.ok and parsed.complete,"Packaged input trace complete"): return
	var trace: Dictionary = parsed.trace
	var commands := 0
	var pauses := 0
	var resumes := 0
	for row in trace.records:
		if row.type == "command" and row.ok: commands += 1
		if row.type == "marker" and row.event == "pause": pauses += 1
		if row.type == "marker" and row.event == "resume": resumes += 1
	if not check(commands == 1 and pauses == 2 and resumes == 1,"Exactly recorded real command and pause/resume markers"): return
	if not check(trace.records[-1].outcome == "abandoned" and trace.records[-1].tick >= 5 and trace.header.metadata.build.get("frozen",false),"Abandoned end identifies frozen packaged source"): return
	var evidence := {"ok":true,"checks":checks,"commands":commands,"pauses":pauses,"resumes":resumes,"ticks":trace.records[-1].tick,"build":trace.header.metadata.build,"engine":trace.header.metadata.engine,"profile_sha256":FileAccess.get_file_as_string("user://profile.json").sha256_text(),"trace":trace_path}
	if not write_result("first",evidence): return
	print("Packaged lifecycle: %d checks passed; requesting real Quit button" % checks)
	await click(find_button("Quit",app))
