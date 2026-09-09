extends SceneTree
var app: Control
var checks := 0
var failures := 0

func _initialize() -> void:
	create_timer(35.0).timeout.connect(func(): push_error("Application test deadline"); quit(1))
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func mouse(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = app.frame.position + point*app.frame.scale
	root.push_input(motion)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = app.frame.position + point*app.frame.scale
		event.global_position = event.position
		root.push_input(event)

func click_control(control: Control) -> void:
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(control)
		ancestor = ancestor.get_parent()
	await process_frame
	mouse(control.get_global_rect().get_center())
	await process_frame

func find_button(text_value: String, node: Node = null) -> Button:
	if node == null: node = app.shell
	if node is Button and node.text == text_value and node.is_visible_in_tree(): return node
	for child in node.get_children():
		var found := find_button(text_value,child)
		if found != null: return found
	return null

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)

func world_slot(ring: int, wedge: int, slot: int = 0) -> void:
	app.live.camera.force_update_scroll()
	var count: int = maxi(1,int(ring*app.live.profile.value("scaling.slots_per_wedge_per_ring")))
	var position := BuildingRules.slot_position(ring,wedge,slot,count)
	mouse(app.stage.get_canvas_transform()*app.live.grid.polar_to_world(position))

func tutorial_checks() -> void:
	await click_control(find_button("Tutorial"))
	check(app.state == "tutorial" and app.current_run.practice,"Actual tutorial starts isolated practice")
	app.live.set_process(false)
	var starting_currency: int = app.progress.currency
	for step in range(11):
		check(app.tutorial_step == step,"Tutorial reaches step %d" % step)
		match step:
			0:
				key(KEY_1)
				world_slot(1,3)
			1:
				for tick in 180:
					app.live._process(1.0/60.0)
					app._update_tutorial()
					if not app.tutorial_next.disabled: break
			2: key(KEY_Q)
			3:
				key(PCSettings.bindings["Wall"])
				world_slot(2,3)
			4:
				for tick in 180:
					app.live._process(1.0/60.0)
					app._update_tutorial()
					if not app.tutorial_next.disabled: break
			5:
				key(KEY_Y)
				world_slot(1,3)
			6:
				key(KEY_T)
				world_slot(1,3)
			7:
				key(KEY_G)
				world_slot(1,3)
			8:
				key(KEY_X)
				world_slot(3,3)
			9:
				var hud: RingStatusHud = app.live.ring_status_hud
				var radius: float = hud.CORE_RADIUS+1.5*hud.BAND_WIDTH
				mouse(hud.global_position+hud._point(radius,3.0/12.0))
		app._update_tutorial()
		check(app.live.last_error.is_empty(),"Tutorial simulation stays valid at step %d" % step)
		check(not app.tutorial_next.disabled,"Actual action unlocks Next for step %d" % step)
		if app.tutorial_next.disabled:
			print("Tutorial blocked: ",app.live.feedback_label.text," / ",app.live.last_error)
			break
		await click_control(app.tutorial_next)
	check(app.state == "start" and app.progress.tutorial_completed,"Actual tutorial completion saved")
	check(app.progress.currency == starting_currency,"Practice grants no campaign reward")

func settings_failure_checks() -> void:
	await click_control(find_button("Settings"))
	await click_control(find_button("Reduced motion"))
	check(app.progress.settings.reduced_motion,"Actual settings toggle saved")
	await click_control(find_button("Weapon feedback"))
	check(not app.progress.settings.effects,"Weapon feedback setting saved")
	var chooser: OptionButton = options_in(app.page)[0]
	await click_control(chooser)
	await create_timer(0.4).timeout
	var popup := chooser.get_popup()
	var bottom_margin := popup.get_theme_stylebox("panel").get_content_margin(SIDE_BOTTOM)
	var row_half_height := popup.get_theme_font("font").get_height(popup.get_theme_font_size("font_size"))*0.5
	mouse(Vector2(popup.position)+Vector2(popup.size.x*0.5,popup.size.y-bottom_margin-row_half_height-9))
	await process_frame
	print("Scale selected: ",app.progress.settings.ui_scale," popup ",popup.size if is_instance_valid(popup) else Vector2.ZERO)
	check(is_equal_approx(app.progress.settings.ui_scale,1.3),"Actual scale popup selects 130 percent")
	key(KEY_ESCAPE)
	await process_frame
	check(app.state == "start","Escape closes settings")
	await click_control(find_button("Start run"))
	app.live.set_process(false)
	check(app.live.flak_button.get_theme_font_size("font_size") >= 30,"Essential HUD labels remain readable at native 1440p and 130 percent")
	app.live.set_menu_open(true)
	await click_control(find_button("Settings",app.live))
	var before: Dictionary = app.live.state.duplicate(true)
	key(KEY_Q)
	key(KEY_1)
	check(app.live.state == before and app.live.build_mode == &"","Settings block underlying world shortcuts")
	key(KEY_ESCAPE)
	await process_frame
	check(app.state == "playing" and app.live.menu_open,"Settings Escape returns to existing pause menu")
	await click_control(find_button("Abandon run and return",app.live))
	# A real competing commit makes the in-memory revision stale.
	var changed: Dictionary = app.store.save_profile(app.progress,app.profile_path)
	check(changed.ok,"External writer fixture commits")
	await click_control(find_button("Start run"))
	check(app.state == "start" and app.live == null and app.feedback.text.contains("Save failed"),"Failed begin save never enters play")
	app._load_profile()
	await process_frame
	await click_control(find_button("Start run"))
	app.live.set_process(false)
	changed = app.store.save_profile(app.progress,app.profile_path)
	app.live.simulation.ended = true
	await process_frame
	check(app.state == "results" and app.result_back.disabled and app.result_retry.disabled,"Failed result save blocks exit and retry")
	key(KEY_ESCAPE)
	key(KEY_Q)
	check(app.state == "results" and not app.live.menu_open,"Unsaved results consume Escape without hidden menu")
	app.progress = changed.profile
	await click_control(app.result_save)
	check(not app.result_back.disabled and app.result_save.disabled and app.result_reward.text.contains("saved"),"Retry saves result and removes redundant save action")
	await click_control(app.result_back)
	# Corrupt primary after a successful backup exists; recovery must be explicit.
	var file := FileAccess.open(app.profile_path,FileAccess.WRITE)
	file.store_string("damaged test profile")
	file.close()
	app._load_profile()
	await process_frame
	check(find_button("Restore backup") != null,"Backup availability offers explicit recovery")
	check(FileAccess.get_file_as_string(app.profile_path) == "damaged test profile","Read-only load preserves corrupt primary")
	await click_control(find_button("Restore backup"))
	check(app.state == "start" and app.store.load_profile(app.profile_path).ok,"Explicit restore repairs disk and resumes Start")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path+".lock"))
	await click_control(find_button("Start run"))
	check(app.lock_notice != null and app.live == null,"Unknown lock offers explicit warned release")
	var notice: PanelContainer = app.lock_notice
	await click_control(find_button("Start run"))
	check(app.lock_notice == notice,"Lock modal shield prevents underlying Start click")
	key(KEY_ESCAPE)
	check(app.lock_notice == null and app.state == "start","Escape dismisses lock notice only")
	await click_control(find_button("Start run"))
	await click_control(find_button("Other instances closed: release unknown lock"))
	check(app.lock_notice == null and not DirAccess.dir_exists_absolute(app.profile_path+".lock"),"Explicit unknown-lock action releases only lock")
	await click_control(find_button("Start run"))
	app.live.set_process(false)
	check(app.state == "playing","Retry original action succeeds after lock release")
	app.live.set_menu_open(true)
	await click_control(find_button("Abandon run and return",app.live))


func options_in(node: Node) -> Array[OptionButton]:
	var result: Array[OptionButton] = []
	if node is OptionButton: result.append(node)
	for child in node.get_children(): result.append_array(options_in(child))
	return result

func resize_config_checks() -> void:
	root.size = Vector2i(1920,1080)
	await process_frame
	var options := options_in(app.page)
	check(options[1].is_item_disabled(1) and options[1].get_item_text(1).contains("locked"),"Locked loadouts visibly disabled before Start")
	await click_control(options[0])
	await create_timer(0.4).timeout
	var popup := options[0].get_popup()
	var bottom_margin := popup.get_theme_stylebox("panel").get_content_margin(SIDE_BOTTOM)
	var row_half_height := popup.get_theme_font("font").get_height(popup.get_theme_font_size("font_size"))*0.5
	mouse(Vector2(popup.position)+Vector2(popup.size.x*0.5,popup.size.y-bottom_margin-row_half_height-9))
	await process_frame
	await click_control(find_button("Dense Swarm"))
	var chosen: Dictionary = app.choices.duplicate(true)
	await click_control(find_button("Start run"))
	app.live.set_process(false)
	check(app.current_run.choices == chosen and "dense_swarm" in chosen.mutators,"Actual configuration forwarded to prepared run")
	var before: float = app.live.state.energy
	key(KEY_1)
	world_slot(1,4)
	check(app.live.state.energy < before,"1920 viewport-transformed world purchase")
	root.size = Vector2i(1600,1000)
	await process_frame
	check(app.frame.position.y > 0 and app.stage.size == Vector2i(2560,1440),"Non-16:9 resize letterboxes native 1440p game viewport")
	before = app.live.state.energy
	world_slot(1,5)
	check(app.live.state.energy < before,"Letterboxed viewport input still targets slot")
	app.live.set_menu_open(true)
	await click_control(find_button("Settings",app.live))
	await click_control(find_button("Fullscreen"))
	check(app.progress.settings.fullscreen,"Actual fullscreen setting persists")
	await click_control(find_button("Fullscreen"))
	check(not app.progress.settings.fullscreen,"Fullscreen toggle restores windowed preference")
	key(KEY_ESCAPE)
	await process_frame
	await click_control(find_button("Abandon run and return",app.live))

func _run() -> void:
	root.size = Vector2i(1280,720)
	app = load("res://scenes/application.tscn").instantiate()
	app.profile_path = "res://.godot/t067-profiles/%d/profile.json" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.profile_path.get_base_dir()))
	root.add_child(app)
	await process_frame
	await process_frame
	check(app.state == "start" and app.progress.currency == 0,"Fresh isolated profile opens Start")
	print("Driver Start=",find_button("Start run").get_global_rect().get_center()," Quit=",find_button("Quit").get_global_rect().get_center())
	check(app.frame.scale.is_equal_approx(Vector2.ONE*0.5),"1280 window downsamples native 1440p canvas")
	await click_control(find_button("Start run"))
	print("After Start: ",app.state," / ",app.feedback.text)
	check(app.state == "playing" and app.live != null,"Actual Start button creates run")
	if app.live != null:
		app.live.set_process(false)
		check(app.live.simulation.foundry_enabled and app.live.simulation.assembler_enabled,"Prepared main run enables complete roster")
		var before: Dictionary = app.live.state.duplicate(true)
		key(KEY_3)
		check(app.live.build_mode == &"" and app.live.state == before,"Locked weapon shortcut cannot select or spend")
		key(KEY_1)
		check(app.live.build_mode == &"flak" and app.live.state == before,"Unlocked shortcut selects without charge")
		var position := BuildingRules.slot_position(1,3,0,app.live._slot_count(1,3))
		mouse(app.stage.get_canvas_transform()*app.live.grid.polar_to_world(position))
		check(app.live.state.energy < before.energy and app.live.build_mode == &"flak","Viewport-transformed click purchases and remains active")
		# Accounting fixture only: actual controller defeat, reward, persistence and shop paths.
		app.live.simulation.elapsed_seconds = 300
		app.live.simulation.total_kills = 250
		app.live.simulation.highest_owned_ring = 2
		app.live.simulation.ended = true
		await process_frame
		await process_frame
		check(app.state == "results" and app.progress.currency > 0,"Defeat settles authoritative reward and saves")
		var balance: int = app.progress.currency
		app.save_result()
		check(app.progress.currency == balance,"Repeated save does not duplicate reward")
		await click_control(find_button("Return to start"))
		await click_control(find_button("Shop"))
		check(app.state == "shop","Actual shop navigation")
		await click_control(find_button("EMP Node  25 credits"))
		check("emp_node" in app.progress.unlocks and app.progress.currency == balance-25,"Actual shop purchase saves exact cost and unlock")
		var saved_path: String = app.profile_path
		app.queue_free()
		await process_frame
		app = load("res://scenes/application.tscn").instantiate()
		app.profile_path = saved_path
		root.add_child(app)
		await process_frame
		await process_frame
		check("emp_node" in app.progress.unlocks and app.progress.currency == balance-25,"Independent application reload retains purchase")
		await click_control(find_button("Start run"))
		app.live.set_process(false)
		key(KEY_3)
		check(app.live.build_mode == &"emp_node","Purchased unlock available in subsequent run")
		app.live.set_menu_open(true)
		await process_frame
		print("Driver Abandon=",find_button("Abandon run and return",app.live).get_global_rect().get_center())
		await click_control(find_button("Abandon run and return",app.live))
		check(app.state == "start" and app.progress.currency == balance-25,"Explicit abandon returns with no reward")
		await tutorial_checks()
		await settings_failure_checks()
		await resize_config_checks()
	print("Application checks: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
