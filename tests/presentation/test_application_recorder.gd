extends "res://tests/presentation/test_application.gd"
func _run() -> void:
	root.size = Vector2i(1280,720)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/t067-profiles/trace-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	await click_control(find_button("Start run"))
	app.live.set_process(false)
	app.live._process(1.0/60.0)
	var tick: int = app.live.simulation._ticks
	key(KEY_Q)
	key(KEY_1)
	world_slot(1,3)
	world_slot(1,3)
	var trace: Dictionary = app.recorder.snapshot()
	check(trace.records.size() == 3,"Exactly one record for each accepted/rejected command")
	check(not trace.records[0].ok and trace.records[1].ok and not trace.records[2].ok,"Command outcomes retained in input order")
	check(trace.records[0].tick == tick and trace.records[2].tick == tick,"Exact committed tick recorded without elapsed-time reconstruction")
	key(KEY_X)
	world_slot(2,3)
	trace = app.recorder.snapshot()
	check(trace.records.size() == 4 and trace.records[-1].action == "cast_ability" and trace.records[-1].ok and trace.records[-1].args.ring == 2,"Actual solar cast logs one complete polar command")
	key(KEY_1)

	key(KEY_ESCAPE)
	key(KEY_ESCAPE)
	key(KEY_ESCAPE)
	trace = app.recorder.snapshot()
	check(trace.records[-2].event == "pause" and trace.records[-1].event == "resume","Actual pause/resume produce ordered markers")
	var path: String = app.trace_path
	app.live.simulation.ended = true
	await process_frame
	var parsed: Dictionary = RunRecorder.load_trace(path)
	check(parsed.ok and parsed.complete and parsed.trace.records[-1].outcome == "defeat","Durable trace includes terminal summary")
	await click_control(app.result_back)
	await click_control(find_button("Start run"))
	app.live.set_process(false)
	app.recorder._path += "/unwritable.jsonl"
	var energy: float = app.live.state.energy
	key(KEY_1)
	world_slot(1,4)
	await process_frame
	check(app.live.state.energy < energy and not app.recorder_error.is_empty(),"Trace write failure does not rollback valid gameplay")
	check(app.live.feedback_label.text.contains("Diagnostic recording unavailable"),"Trace failure remains visibly diagnostic")
	check(not app.trace_finished and app.recorder.snapshot().records.is_empty(),"Failed trace cannot claim completed recording")
	print("Application recorder checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
