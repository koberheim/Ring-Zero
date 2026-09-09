extends "res://tests/presentation/test_application.gd"

func _run() -> void:
	root.size = Vector2i(1920,1080)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/release-profiles/test-%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	check(PCSettings.rebind("Flak",KEY_6) == OK,"Binding persists")
	check(PCSettings.logical_key(KEY_6) == KEY_1 and PCSettings.logical_key(KEY_1) == 0,"Old key stops and new key translates")
	PCSettings.load_settings(PCSettings.path)
	check(PCSettings.logical_key(KEY_6) == KEY_1,"Reload preserves binding")
	check(PCSettings.rebind("Mass Driver",KEY_6) == OK,"Binding collision swaps")
	check(PCSettings.bindings["Flak"] == KEY_2,"Swap keeps both actions reachable")
	PCSettings.bindings = PCSettings.DEFAULT_KEYS.duplicate()
	PCSettings.save_settings()
	check(PCSettings.rebind_button("pad","Confirm",JOY_BUTTON_B) == OK,"Controller remap saved")
	check(PCSettings.pad_button(JOY_BUTTON_B) == JOY_BUTTON_A and PCSettings.pad_button(JOY_BUTTON_A) == JOY_BUTTON_B,"Controller conflict swaps")
	check(PCSettings.rebind_button("mouse","Place / select",MOUSE_BUTTON_RIGHT) == OK,"Mouse remap saved")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	check(PCSettings.world_event(click).button_index == MOUSE_BUTTON_LEFT,"Mouse remap translates world event")
	check(click.button_index == MOUSE_BUTTON_RIGHT,"Translation preserves original GUI event")
	PCSettings.pad = PCSettings.DEFAULT_PAD.duplicate()
	PCSettings.mouse = PCSettings.DEFAULT_MOUSE.duplicate()
	PCSettings.save_settings()
	# Controller primary click uses the same visible start button as the mouse.
	var start := find_button("Start run")
	app.controller.point = start.get_global_rect().get_center()
	for pressed in [true,false]:
		var event := InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_A
		event.pressed = pressed
		app.controller._input(event)
	await process_frame
	check(app.state == "playing" and app.live != null,"Controller starts operation")
	if app.live == null: quit(1); return
	app.live.set_process(false)
	key(KEY_1)
	check(app.live.build_mode == &"flak","Gameplay default binding")
	app._pause_on_focus_loss()
	check(app.live.menu_open and paused,"Focus loss pauses")
	app.live.set_menu_open(false)
	var practice := {"outcome":"practice","elapsed_seconds":900.0,"kills":500,"highest_ring":6,"relay_rebuilds":1}
	check(AchievementHooks.earned(practice).is_empty(),"Practice never awards achievements")
	var too_early := practice.duplicate()
	too_early.outcome = "victory"
	too_early.elapsed_seconds = 899.9
	check(not RunRules.reward(too_early).ok,"Early victory reward rejected")
	app.live.simulation.elapsed_seconds = RunRules.OPERATION_SECONDS
	app._process(0)
	check(app.state == "results","Operation deadline produces results")
	check(app.settlement.summary.outcome == "victory","Deadline outcome is victory")
	check("CONTAINMENT" in app.progress.achievements,"Victory record saved")
	var credits: int = app.progress.currency
	app.save_result()
	check(app.progress.currency == credits,"Victory settlement stays exactly once")
	var loaded := ProfileStore.new().load_profile(app.profile_path)
	check(loaded.ok and "CONTAINMENT" in loaded.profile.achievements,"Achievement survives independent reload")
	app.show_controls()
	check(find_button("Pause / cancel: Escape") != null,"Pause binding visible")
	app.show_records()
	check(app.state == "records" and find_button("Back") != null,"Service records can be viewed")
	key(KEY_ESCAPE)
	check(app.state == "start","Record screen closes through mapped back")
	app.show_credits()
	check(app.state == "credits" and find_button("Back") != null,"Credits can be viewed")
	app.queue_free()
	paused = false
	await process_frame
	print("Release candidate checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
