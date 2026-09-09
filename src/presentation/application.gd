extends Control
## Between-run controller: rules prepare choices; ProfileStore owns persistence.
const ThemeKit = preload("res://src/presentation/industrial_theme.gd")
const DESIGN_SIZE := Vector2(2560,1440)
var page_decoration: Control
var menu_sun: ColorRect
var menu_phase := 0.0
@export var profile_path := "user://profile.json"
var recorder: RefCounted
var recorder_error := ""
var trace_path := ""
var trace_finished := true
var rules: Script
var store: RefCounted
var progress: Dictionary = {}
var catalogue: Dictionary = {}
var choices: Dictionary = {}
var current_run: Dictionary = {}
var run_id := ""
var live: Node2D
var stage: SubViewport
var frame: SubViewportContainer
var content_backdrop: ColorRect
var shell: Control
var menu_backdrop: ColorRect
var page: PanelContainer
var footer: HBoxContainer
var content: VBoxContainer
var feedback: Label
var state := "loading"
var settlement: Dictionary = {}
var result_save: Button
var result_reward: Label
var result_retry: Button
var result_back: Button
var tutorial_step := 0
var tutorial_card: PanelContainer
var tutorial_text: Label
var tutorial_next: Button
var tutorial_baseline: Dictionary = {}
var settings_return := "start"
var lock_notice: PanelContainer
var lock_shield: ColorRect
var audio: Node
var rebinding := ""
var rebinding_group := "keyboard"
var controller: Node
var achievement_hooks := AchievementHooks.new()
var quitting := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	PCSettings.load_settings(profile_path.get_base_dir().path_join("pc_settings.cfg"))
	audio = load("res://src/presentation/game_audio.gd").new()
	add_child(audio)
	rules = load("res://src/gameplay/run_rules.gd")
	store = load("res://src/core/profile_store.gd").new()
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	content_backdrop = ColorRect.new()
	content_backdrop.color = Color("10161b")
	content_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_backdrop)
	frame = SubViewportContainer.new()
	frame.stretch = true
	add_child(frame)
	stage = SubViewport.new()
	stage.size = Vector2i(2560,1440)
	# The stage owns its post-process environment; sharing the root World3D
	# would also process the already-composited UI a second time.
	stage.world_3d = World3D.new()
	stage.transparent_bg = false
	stage.handle_input_locally = true
	stage.gui_embed_subwindows = true
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	frame.add_child(stage)
	shell = Control.new()
	shell.size = DESIGN_SIZE
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 100
	stage.add_child(layer)
	layer.add_child(shell)
	menu_backdrop = ColorRect.new()
	menu_backdrop.color = Color("10161b")
	var menu_material := ShaderMaterial.new()
	menu_material.shader = load("res://src/presentation/menu_background.gdshader")
	menu_material.set_shader_parameter("band_texture",load("res://assets/art/bands/band_working_01.png"))
	menu_backdrop.material = menu_material
	menu_backdrop.size = DESIGN_SIZE
	menu_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(menu_backdrop)
	get_viewport().size_changed.connect(_resize)
	_resize()
	_load_profile()
	controller = load("res://src/presentation/controller_pointer.gd").new()
	controller.host = self
	add_child(controller)
	var navigation = load("res://src/presentation/camera_navigation.gd").new()
	navigation.name = "CameraNavigation"
	navigation.host = self
	add_child(navigation)
	get_window().focus_exited.connect(_pause_on_focus_loss)
	Input.joy_connection_changed.connect(func(_device: int, connected: bool):
		if not connected: _pause_on_focus_loss()
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()

func request_quit() -> void:
	if quitting: return
	quitting = true
	_pause_on_focus_loss()
	if audio != null: await audio.shutdown()
	get_tree().quit()

func _pause_on_focus_loss() -> void:
	if live != null and state in ["playing","tutorial"] and not live.menu_open:
		live.set_menu_open(true)

func _resize() -> void:
	if frame == null:
		return
	var viewport_size := get_viewport_rect().size
	var factor := minf(viewport_size.x/DESIGN_SIZE.x,viewport_size.y/DESIGN_SIZE.y)
	# The world and text render at 2560 x 1440 before fitting the window.
	frame.stretch = false
	stage.size = Vector2i(2560,1440)
	frame.size = DESIGN_SIZE
	frame.scale = Vector2.ONE*factor
	frame.position = (viewport_size-DESIGN_SIZE*factor)*0.5
	content_backdrop.position = frame.position
	content_backdrop.size = DESIGN_SIZE*factor

func _load_profile() -> void:
	var loaded: Dictionary = store.load_profile(profile_path)
	if not loaded.ok:
		_new_page("Profile unavailable")
		_text("Your existing profile has not been overwritten. " + _errors(loaded))
		_action("Retry loading",_load_profile)
		return
	if loaded.get("recovered",false):
		_new_page("Backup available")
		_text("The primary profile is unreadable. Restore the last valid backup before continuing; this is an explicit recovery action.")
		_action("Restore backup",recover_profile)
		_action("Retry loading",_load_profile)
		return
	progress = loaded.profile
	catalogue = rules.catalogue()
	choices = rules.default_choices()
	_apply_settings()
	show_start()

func recover_profile() -> void:
	var recovered: Dictionary = store.recover_profile(profile_path)
	if not recovered.ok:
		feedback.text = _errors(recovered)
		return
	_load_profile()

func _errors(result: Dictionary) -> String:
	return " ".join(result.get("errors",PackedStringArray(["Unknown error"])))

func _new_page(title: String) -> void:
	menu_backdrop.show()
	if page != null:
		page.queue_free()
	if page_decoration != null:
		page_decoration.queue_free()
	menu_sun = null
	page_decoration = load("res://src/presentation/command_frame.gd").new()
	page_decoration.home = title == "Ring Zero"
	page_decoration.size = DESIGN_SIZE
	page_decoration.theme = ThemeKit.make()
	shell.add_child(page_decoration)
	if title != "Ring Zero":
		var shade := ColorRect.new()
		shade.color = Color(0.015,0.028,0.045,0.84)
		shade.size = DESIGN_SIZE
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page_decoration.add_child(shade)
		_page_label("RING ZERO",Vector2(142,32),30,ThemeKit.AMBER)
		_page_label("Stellar containment division",Vector2(1830,32),26,ThemeKit.STEEL)
	page = PanelContainer.new()
	page.position = Vector2(1500,174) if title == "Ring Zero" else Vector2(170,162)
	page.size = Vector2(910,1160) if title == "Ring Zero" else Vector2(2220,1120)
	page.theme = ThemeKit.make(float(progress.get("settings",{}).get("ui_scale",1.0)))
	if title != "Ring Zero":
		page.add_theme_stylebox_override("panel",ThemeKit.box(Color("101b25ed"),Color("3e5664"),44))
	shell.add_child(page)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",24)
	page.add_child(layout)
	var heading := Label.new()
	heading.text = "Prepare an operation" if title == "Ring Zero" else title
	ThemeKit.heading(heading,48 if title == "Ring Zero" else 72)
	layout.add_child(heading)
	var line := HSeparator.new()
	line.add_theme_stylebox_override("separator",ThemeKit.box(ThemeKit.AMBER,ThemeKit.AMBER,0))
	line.custom_minimum_size.y = 2
	layout.add_child(line)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.hide()
	feedback.add_theme_color_override("font_color",ThemeKit.CYAN)
	layout.add_child(feedback)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation",20)
	layout.add_child(footer)

func _page_label(value: String, at: Vector2, font_size: int, color: Color = ThemeKit.INK) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeKit.heading(label,font_size)
	label.add_theme_color_override("font_color",color)
	page_decoration.add_child(label)
	return label

func _section(value: String) -> Label:
	var label := _text(value)
	ThemeKit.heading(label,40)
	label.add_theme_color_override("font_color",ThemeKit.AMBER)
	return label

func _text(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)
	return label

func _action(title: String, callback: Callable, parent: Node = null) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 66
	(parent if parent != null else content).add_child(button)
	button.pressed.connect(callback)
	button.pressed.connect(func(): audio.play("ui"))
	return button

func _clear_game() -> void:
	get_tree().paused = false
	if live != null:
		live.queue_free()
		live = null
	if tutorial_card != null:
		tutorial_card.queue_free()
		tutorial_card = null
	current_run = {}

func show_start() -> void:
	_clear_game()
	state = "start"
	_new_page("Ring Zero")
	content.add_theme_constant_override("separation",10)
	_page_label("RING ZERO",Vector2(134,176),184)
	_page_label("Hold the star.",Vector2(144,392),58,ThemeKit.AMBER)
	_page_label("Build its cage. Survive the machine tide.",Vector2(148,470),32,ThemeKit.STEEL)
	_page_label("15 minutes. One star. Everything you can build.",Vector2(144,1180),30)
	_page_label("Stellar containment",Vector2(142,32),28,ThemeKit.STEEL)
	_page_label("Service credits  /  %d" % int(progress.currency),Vector2(1920,32),28,ThemeKit.AMBER)
	if ResourceLoader.exists("res://src/presentation/solar_body.gdshader"):
		menu_sun = ColorRect.new()
		menu_sun.position = Vector2(240,300)
		menu_sun.size = Vector2(1040,1040)
		menu_sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material := ShaderMaterial.new()
		material.shader = load("res://src/presentation/solar_body.gdshader")
		material.set_shader_parameter("palette",1)
		material.set_shader_parameter("activity",0.7)
		menu_sun.material = material
		page_decoration.add_child(menu_sun)
		page_decoration.move_child(menu_sun,0)
	_text("Hold containment for 15 minutes.")
	for category in ["doctrines","loadouts"]:
		var field := "doctrine" if category == "doctrines" else "loadout"
		_section("Doctrine" if category == "doctrines" else "Starting loadout")
		var select := OptionButton.new()
		select.custom_minimum_size.y = 70
		content.add_child(select)
		var details := _text("")
		details.add_theme_color_override("font_color",ThemeKit.STEEL)
		var entries: Dictionary = catalogue.get(category,{})
		for id in entries:
			var locked: bool = field == "loadout" and id in catalogue.unlocks and id not in progress.unlocks
			select.add_item(str(entries[id].get("label",id)) + (" [locked: %d credits in Shop]" % catalogue.unlocks[id].cost if locked else ""))
			select.set_item_disabled(select.item_count-1,locked)
			select.set_item_metadata(select.item_count-1,id)
			if id == choices[field]:
				select.select(select.item_count-1)
				details.text = str(entries[id].get("description",""))
		select.item_selected.connect(func(index: int):
			var id: String = select.get_item_metadata(index)
			choices[field] = id
			details.text = str(entries[id].get("description",""))
		)
	_section("Optional challenges")
	for id in catalogue.get("mutators",{}):
		var entry: Dictionary = catalogue.mutators[id]
		var toggle := CheckButton.new()
		toggle.text = str(entry.get("label",id))
		toggle.tooltip_text = str(entry.get("description",""))
		toggle.button_pressed = id in choices.mutators
		toggle.custom_minimum_size.y = 48
		content.add_child(toggle)
		toggle.toggled.connect(func(enabled: bool):
			if enabled and id not in choices.mutators: choices.mutators.append(id)
			elif not enabled: choices.mutators.erase(id)
		)
		var description := _text(str(entry.get("description","")))
		description.add_theme_font_size_override("font_size",24)
		description.add_theme_color_override("font_color",ThemeKit.STEEL)
	var start_button := _action("Start run",begin_run.bind(false),footer)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ThemeKit.primary(start_button)
	_action("Tutorial",begin_run.bind(true),footer)
	var navigation := HBoxContainer.new()
	navigation.position = Vector2(144,1352)
	navigation.add_theme_constant_override("separation",24)
	page_decoration.add_child(navigation)
	for item in [["Shop",show_shop],["Settings",show_settings.bind("start")],["Reference",show_reference.bind("start")],["Records",show_records],["Credits",show_credits],["Quit",request_quit]]:
		var button := _action(item[0],item[1],navigation)
		button.flat = true
		button.custom_minimum_size = Vector2(164,54)
		button.add_theme_font_size_override("font_size",28)

func show_records() -> void:
	_new_page("Service records")
	state = "records"
	var names := ["First Watch — Survive five minutes","Machine Breaker — Destroy 250 machines in one run","Outer Frontier — Reach ring six","Power Restored — Rebuild a relay","Containment — Complete a 15-minute operation","Trial by Fire — Win with all three mutators"]
	for index in AchievementHooks.IDS.size():
		var id: String = AchievementHooks.IDS[index]
		var earned: bool = id in progress.get("achievements",[])
		var row := HBoxContainer.new()
		content.add_child(row)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/achievements/"+id.to_lower()+".svg")
		icon.custom_minimum_size = Vector2(96,96)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color.WHITE if earned else Color(0.4,0.4,0.4)
		row.add_child(icon)
		var label := Label.new()
		label.text = ("Earned: " if earned else "Locked: ")+names[index]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
	_action("Back",show_start,footer)

func show_credits() -> void:
	_new_page("Credits")
	state = "credits"
	_text("RING ZERO\nCreated by Kevin with AI-assisted design and development.\nRelease candidate " + str(ProjectSettings.get_setting("application/config/version","")))
	_text("Built with Godot Engine, distributed under the MIT license. Godot copyright and third-party notices accompany the build in licenses/godot.")
	_text("Typography: Barlow and Barlow Semi Condensed. Copyright The Barlow Project Authors. SIL Open Font License 1.1; full license in licenses/barlow.")
	_text("World hardware: generated source art from the RING ZERO asset pipeline. Fortress geometry, lighting shaders, interface symbols, service-record emblems and sound synthesis are authored for this project. No third-party music recordings are used.")
	_action("Back",show_start,footer)

func begin_run(practice: bool = false) -> void:
	var base: Dictionary = BalanceProfile.load_json("res://data/balance/release.json")
	if not base.ok:
		feedback.text = _errors(base)
		return
	var prepared: Dictionary = rules.create_run(base.profile,choices,progress,practice,12)
	if not prepared.ok:
		feedback.text = _errors(prepared)
		return
	var begun: Dictionary = store.begin_run(progress)
	if not begun.ok:
		feedback.text = _errors(begun)
		return
	if not _save_candidate(begun.profile):
		return
	_finish_trace("abandoned")
	run_id = begun.run_id
	_clear_game()
	current_run = prepared
	current_run["practice"] = practice
	var recorder_script = load("res://src/core/run_recorder.gd")
	recorder = recorder_script.new()
	trace_path = recorder_script.default_path(run_id)
	trace_finished = false
	recorder_error = ""
	_trace_result(recorder.start(trace_path,recorder_script.make_metadata(run_id,base.profile.snapshot(),prepared.profile.snapshot(),choices,progress,practice)))
	state = "tutorial" if practice else "playing"
	page.hide()
	page_decoration.hide()
	menu_backdrop.hide()
	live = load("res://scenes/release_view.tscn").instantiate()
	live.prepared_run = prepared
	live.application_host = self
	live.industrial_ui = true
	stage.add_child(live)
	stage.move_child(live,0)
	_apply_live_settings()
	if practice:
		tutorial_step = 0
		_start_tutorial()

func _save_candidate(candidate: Dictionary) -> bool:
	var saved: Dictionary = store.save_profile(candidate,profile_path)
	if not saved.ok:
		if feedback != null: feedback.text = "Save failed. " + _errors(saved)
		if live != null: live.feedback_label.text = "Save failed. " + _errors(saved)
		if saved.get("lock_recovery","") in ["stale","unknown"]: _offer_lock_recovery(saved.lock_recovery)
		return false
	progress = saved.profile
	return true

func _trace_result(result: Dictionary) -> void:
	if not result.ok:
		recorder_error = "Diagnostic recording unavailable: " + _errors(result)
		if feedback != null: feedback.text = recorder_error
		if live != null: live.feedback_label.text = recorder_error

func record_command(action: String, args: Dictionary, result: Dictionary) -> void:
	if recorder == null or trace_finished or not recorder_error.is_empty(): return
	_trace_result(recorder.append_command(live.simulation._ticks,action,args,bool(result.ok),result.get("errors",[])))

func record_marker(event: String, data: Dictionary = {}) -> void:
	if recorder == null or trace_finished or not recorder_error.is_empty() or live == null: return
	_trace_result(recorder.marker(live.simulation._ticks,event,data))

func _finish_trace(outcome: String) -> void:
	if recorder == null or trace_finished or live == null: return
	if recorder_error.is_empty(): _trace_result(recorder.finish(live.simulation._ticks,outcome,live.simulation.run_summary(outcome)))
	trace_finished = true

func _offer_lock_recovery(kind: String) -> void:
	if lock_notice != null: lock_notice.queue_free()
	if lock_shield != null: lock_shield.queue_free()
	lock_shield = ColorRect.new()
	lock_shield.size = DESIGN_SIZE
	lock_shield.color = Color(0,0,0,0.45)
	shell.add_child(lock_shield)
	lock_notice = PanelContainer.new()
	lock_notice.position = Vector2(680,440)
	lock_notice.size = Vector2(1200,480)
	lock_notice.theme = shell.theme
	shell.add_child(lock_notice)
	var column := VBoxContainer.new()
	lock_notice.add_child(column)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "The previous save owner has exited. Release its stale lock, then retry the action." if kind == "stale" else "Lock ownership is unknown. Close all other Ring Zero instances before confirming release. Profile contents are preserved."
	column.add_child(label)
	_action("Release stale lock" if kind == "stale" else "Other instances closed: release unknown lock",func():
		var released: Dictionary = store.release_stale_lock(profile_path) if kind == "stale" else store.force_release_unknown_lock(profile_path)
		if released.ok:
			lock_notice.queue_free()
			lock_notice = null
			lock_shield.queue_free()
			lock_shield = null
			feedback.text = "Lock released. Retry the original action."
		else: label.text = _errors(released)
	,column)
	_action("Cancel",_close_lock_notice,column)

func _close_lock_notice() -> void:
	if lock_notice != null: lock_notice.queue_free()
	if lock_shield != null: lock_shield.queue_free()
	lock_notice = null
	lock_shield = null

func _process(_delta: float) -> void:
	if feedback != null and is_instance_valid(feedback): feedback.visible = not feedback.text.is_empty()
	if menu_sun != null and is_instance_valid(menu_sun) and menu_backdrop.visible:
		if not progress.get("settings",{}).get("reduced_motion",false): menu_phase += _delta
		menu_sun.material.set_shader_parameter("phase",menu_phase)
	if tutorial_card != null:
		tutorial_card.visible = state == "tutorial" and live != null and not live.menu_open and lock_notice == null
	if live == null:
		return
	if not recorder_error.is_empty(): live.feedback_label.text = recorder_error
	if state in ["playing","tutorial"] and (live.simulation.ended or not live.last_error.is_empty()):
		finish_run("practice" if current_run.get("practice",false) else ("error" if not live.last_error.is_empty() else "defeat"))
	elif state == "playing" and live.simulation.elapsed_seconds >= RunRules.OPERATION_SECONDS:
		finish_run("victory")
	elif state == "tutorial":
		_update_tutorial()

func finish_run(outcome: String) -> void:
	if outcome == "error": record_marker("error",{"message":live.last_error})
	_finish_trace(outcome)
	state = "results"
	get_tree().paused = true
	var summary: Dictionary = live.simulation.run_summary(outcome)
	var reward: Dictionary = rules.reward(summary,float(current_run.reward_multiplier))
	_new_page("Containment complete" if outcome == "victory" else ("Run ended" if outcome != "practice" else "Practice ended"))
	audio.play("victory" if outcome == "victory" else "defeat")
	if outcome == "victory": _text("The star is secure. Your fortress held against the machine tide.")
	if not recorder_error.is_empty(): _text(recorder_error)
	if not live.last_error.is_empty(): _text(live.last_error)
	var statistics := HBoxContainer.new()
	statistics.add_theme_constant_override("separation",64)
	content.add_child(statistics)
	for item in [["Time held","%02d:%02d" % [int(summary.elapsed_seconds)/60,int(summary.elapsed_seconds)%60]],["Machines destroyed",str(summary.kills)],["Highest ring",str(summary.highest_ring)],["Relays restored",str(summary.relay_rebuilds)]]:
		var stat := VBoxContainer.new()
		stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		statistics.add_child(stat)
		var number := Label.new()
		number.text = item[1]
		ThemeKit.heading(number,92)
		number.add_theme_color_override("font_color",ThemeKit.AMBER)
		stat.add_child(number)
		var caption := Label.new()
		caption.text = item[0]
		caption.add_theme_color_override("font_color",ThemeKit.STEEL)
		stat.add_child(caption)
	if not reward.ok:
		feedback.text = _errors(reward)
		return
	settlement = {"summary":summary,"reward":reward}
	result_reward = _text("Pending reward: %d credits" % reward.amount)
	ThemeKit.heading(result_reward,44)
	var reward_labels := {"survival":"Survival credits","kills":"Kill credits","rings":"Expansion credits","survive_300":"Challenge: survive five minutes","kills_250":"Challenge: destroy 250 machines","rebuild_relay":"Challenge: rebuild a Relay","subtotal":"Base reward","multiplier":"Run reward multiplier"}
	var reward_grid := GridContainer.new()
	reward_grid.columns = 4
	reward_grid.add_theme_constant_override("h_separation",56)
	content.add_child(reward_grid)
	for item in reward.breakdown:
		if reward_labels.has(item):
			var caption := Label.new()
			caption.text = reward_labels[item]
			caption.add_theme_color_override("font_color",ThemeKit.STEEL)
			reward_grid.add_child(caption)
			var amount := Label.new()
			amount.text = "%.2fx" % float(reward.breakdown[item]) if item == "multiplier" else str(int(reward.breakdown[item]))
			amount.add_theme_color_override("font_color",ThemeKit.AMBER)
			reward_grid.add_child(amount)
	if not reward.breakdown.get("eligible",false): _text("No campaign rewards for practice, abandonment or interrupted runs.")
	result_save = _action("Save result",save_result,footer)
	result_retry = _action("Retry run",begin_run.bind(false),footer)
	result_back = _action("Return to start",show_start,footer)
	ThemeKit.primary(result_retry)
	result_retry.disabled = true
	result_back.disabled = true
	save_result()

func save_result() -> void:
	var settled: Dictionary = store.settle_run(progress,run_id,int(settlement.reward.amount))
	if not settled.ok:
		feedback.text = _errors(settled)
		return
	for id in AchievementHooks.earned(settlement.summary,choices.mutators):
		if id not in settled.profile.achievements: settled.profile.achievements.append(id)
	if _save_candidate(settled.profile):
		achievement_hooks.replay_saved(progress.achievements)
		feedback.text = "Result saved. Credits: %d" % progress.currency
		result_reward.text = "Earned reward: %d credits (saved)" % settlement.reward.amount
		result_save.disabled = true
		result_save.hide()
		result_retry.disabled = false
		result_back.disabled = false

func request_restart() -> void:
	begin_run(current_run.get("practice",false))

func abandon_run() -> void:
	var settled: Dictionary = store.settle_run(progress,run_id,0)
	if not settled.ok:
		live.feedback_label.text = _errors(settled)
		return
	if _save_candidate(settled.profile):
		_finish_trace("abandoned")
		show_start()
	else: live.feedback_label.text = feedback.text

func show_shop() -> void:
	state = "shop"
	_new_page("Progression shop")
	_text("Credits: %d" % progress.currency)
	for category in ["unlocks","upgrades"]:
		for id in catalogue.get(category,{}):
			var entry: Dictionary = catalogue[category][id]
			var level: int = int(progress.upgrades.get(id,0)) if category == "upgrades" else -1
			var owned: bool = id in progress.unlocks if category == "unlocks" else level >= int(entry.get("max_level",3))
			var cost: int = int(entry.get("cost",0)) if category == "unlocks" else int(entry.get("costs",[25,50,75])[mini(level,2)])
			var button := _action("%s  %s" % [entry.get("label",id),"Owned" if owned else str(cost)+" credits"],purchase.bind(id,cost,level+1 if category == "upgrades" else -1))
			button.disabled = owned
			button.tooltip_text = str(entry.get("description",""))
			if category == "upgrades":
				_text("Level %d / %d. %s" % [level,int(entry.max_level),str(entry.description)])
	_action("Back",show_start,footer)

func purchase(id: String, cost: int, level: int) -> void:
	var bought: Dictionary = store.purchase(progress,id,cost,level)
	if not bought.ok:
		feedback.text = _errors(bought)
		return
	if _save_candidate(bought.profile): show_shop()

func reference_text() -> String:
	var text := "Buildings and defenses\n"
	for kind in ["flak","mass_driver","emp_node","lance_emitter","point_defense"]:
		text += kind.replace("_"," ").capitalize() + ": choose its numbered key, then an empty owned slot. Uses ring power.\n"
	text += "Marker legend: circle Standard; square Foundry; chevron Transfer; X Sapper; diamond Breacher; large ring Assembler; triangle surfaced Tunneler.\nRing Plate: Q purchases the next complete ring, including its automatic Relay.\nWall: blocks an outer edge and funnels surface machines.\nArmor Plating: increases the supporting wedge HP ceiling.\nRepair Node: repairs its supporting wedge over time.\nRepair Wedge: restores a damaged owned wedge at its quoted cost.\nReclaim Ring: rebuilds a collapsed ring without erasing surviving outer rings.\nRebuild Relay: restores the selected ring's Relay HP; kill a camping Sapper first.\nDebris Field: blocks the outer boundary without wall HP.\nTractor Lane: directs surface movement clockwise/counterclockwise, selected with F.\nOcclusion Screen: slows machines in the outward wedge column; inspect its range and speed.\nFocused Flare: core-centered sector cast. EMP Burst: pointer-centered circle cast. Both use cooldowns, not energy; kills grant no energy.\n\nEnemy counters\n"
	for id in catalogue.get("reference",{}):
		text += str(catalogue.reference[id].label) + ": " + str(catalogue.reference[id].description) + "\n\n"
	return text

func show_reference(return_to: String = "start") -> void:
	settings_return = return_to
	_new_page("Field reference")
	_text(reference_text())
	_text("Controls: 1-5 weapons; Q whole ring purchase; H Wall; E Armor; R Repair Node; T Repair Wedge; Y Reclaim; G Rebuild Relay. C/V/B terrain, F direction, Z/X solar. Build tools repeat on distinct clicks; solar casts once. Right/Esc cancel. Tab catalogue. WASD or middle drag pan, wheel zoom, minimap focus.")
	_action("Back",close_settings,footer)
	state = "reference"

func show_settings(return_to: String = "start") -> void:
	settings_return = return_to
	_new_page("Settings")
	var body := content
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",90)
	content.add_child(columns)
	var video := VBoxContainer.new()
	video.custom_minimum_size.x = 910
	video.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(video)
	content = video
	_section("Display & comfort")
	_text("Rendered at 2560 x 1440. The image fits your display while preserving the fortress proportions.")
	for key in ["fullscreen","reduced_motion","effects"]:
		var toggle := CheckButton.new()
		toggle.text = {"fullscreen":"Fullscreen","reduced_motion":"Reduced motion","effects":"Weapon feedback"}[key]
		toggle.button_pressed = progress.settings[key]
		toggle.custom_minimum_size.y = 66
		content.add_child(toggle)
		toggle.toggled.connect(func(value: bool): _change_setting(key,value))
	_text("Interface scale")
	var scale_choice := OptionButton.new()
	scale_choice.custom_minimum_size.y = 70
	content.add_child(scale_choice)
	for value in [1.0,1.15,1.3]:
		scale_choice.add_item("%d%%" % roundi(value*100))
		if is_equal_approx(progress.settings.ui_scale,value): scale_choice.select(scale_choice.item_count-1)
	scale_choice.item_selected.connect(func(index: int): _change_setting("ui_scale",[1.0,1.15,1.3][index]))
	var comfort := _text("Reduced motion disables camera shake and slows the presentation. Weapon feedback controls visual combat effects.")
	comfort.add_theme_color_override("font_color",ThemeKit.STEEL)
	var sound := VBoxContainer.new()
	sound.custom_minimum_size.x = 910
	sound.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(sound)
	content = sound
	_section("Sound")
	_text("Set the balance of machinery, weapons and the ambient stellar drone.")
	for bus in ["master","music","effects"]:
		var label := _text(bus.capitalize() + " volume")
		label.add_theme_color_override("font_color",ThemeKit.AMBER)
		var slider := HSlider.new()
		slider.custom_minimum_size.y = 54
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = PCSettings.master if bus == "master" else (PCSettings.music if bus == "music" else PCSettings.effects)
		content.add_child(slider)
		slider.value_changed.connect(func(value: float):
			match bus:
				"master": PCSettings.master = value
				"music": PCSettings.music = value
				"effects": PCSettings.effects = value
			audio.apply_levels()
			if PCSettings.save_settings() != OK: feedback.text = "Could not save audio settings."
		)
	content = body
	_action("Controls",show_controls,footer)
	_action("Back",close_settings,footer)
	state = "settings"

func show_controls() -> void:
	_new_page("Controls")
	state = "controls"
	_text("Select a binding, then press its new key or button. Assignments already in use swap automatically.")
	var controls_tabs := TabContainer.new()
	controls_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(controls_tabs)
	for group in ["keyboard","mouse","pad"]:
		var column := VBoxContainer.new()
		column.name = {"keyboard":"Keyboard","mouse":"Mouse","pad":"Controller"}[group]
		controls_tabs.add_child(column)
		var guide := Label.new()
		guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		guide.text = {"keyboard":"Default controls: WASD moves the map. Number keys choose weapons; H builds walls; C, V and B choose terrain. Hold Alt for the tactical view.","mouse":"Battlefield buttons can be remapped. Menus always use the primary button. Drag with Pan to move the map.","pad":"Left stick moves the pointer. Right stick moves the map. Triggers zoom. D-pad scrolls menus. Standard button positions: south 0, east 1, west 2, north 3."}[group]
		column.add_child(guide)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("v_separation",8)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(grid)
		var entries: Dictionary = PCSettings.DEFAULT_KEYS if group == "keyboard" else (PCSettings.DEFAULT_MOUSE if group == "mouse" else PCSettings.DEFAULT_PAD)
		for action in entries:
			var caption: String = PCSettings.label(action) if group == "keyboard" else ("Mouse %d" % PCSettings.mouse[action] if group == "mouse" else "Pad %d" % PCSettings.pad[action])
			var button := _action("%s: %s" % [action,caption],func():
				rebinding = action
				rebinding_group = group
				feedback.text = "Press the new " + ("key" if group == "keyboard" else "button") + " for " + action
			,grid)
			button.custom_minimum_size = Vector2(650,56)
			button.add_theme_stylebox_override("normal",ThemeKit.box(ThemeKit.RECESS,Color("405766"),10))
			button.add_theme_stylebox_override("hover",ThemeKit.box(Color("263947"),ThemeKit.AMBER,10))
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_font_size_override("font_size",roundi(26*float(progress.settings.ui_scale)))
	_action("Reset",func():
		var previous := PCSettings.bindings.duplicate()
		var previous_pad := PCSettings.pad.duplicate()
		var previous_mouse := PCSettings.mouse.duplicate()
		PCSettings.bindings = PCSettings.DEFAULT_KEYS.duplicate()
		PCSettings.pad = PCSettings.DEFAULT_PAD.duplicate()
		PCSettings.mouse = PCSettings.DEFAULT_MOUSE.duplicate()
		if PCSettings.save_settings() != OK:
			PCSettings.bindings = previous
			PCSettings.pad = previous_pad
			PCSettings.mouse = previous_mouse
			feedback.text = "Could not save bindings."
		else: show_controls()
	,footer)
	_action("Back",show_settings.bind(settings_return),footer)

func _change_setting(key: String, value: Variant) -> void:
	var candidate := progress.duplicate(true)
	candidate.settings[key] = value
	if _save_candidate(candidate):
		_apply_settings()
		show_settings(settings_return)
	else:
		var message := feedback.text
		show_settings(settings_return)
		feedback.text = message

func _apply_settings() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if progress.settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	shell.theme = ThemeKit.make(float(progress.settings.ui_scale))
	_apply_live_settings()

func _apply_live_settings() -> void:
	if live != null:
		live.apply_interface_settings(progress.settings)

func close_settings() -> void:
	if settings_return == "game" and live != null:
		page.hide()
		page_decoration.hide()
		menu_backdrop.hide()
		state = "tutorial" if current_run.get("practice",false) else "playing"
	else: show_start()

func _input(event: InputEvent) -> void:
	if not rebinding.is_empty():
		var error := ERR_BUSY
		if rebinding_group == "keyboard" and event is InputEventKey and event.pressed and not event.echo:
			error = PCSettings.rebind(rebinding,event.physical_keycode)
		elif rebinding_group == "mouse" and event is InputEventMouseButton and event.pressed:
			error = PCSettings.rebind_button("mouse",rebinding,event.button_index)
		elif rebinding_group == "pad" and event is InputEventJoypadButton and event.pressed:
			error = PCSettings.rebind_button("pad",rebinding,event.button_index)
		else: return
		rebinding = ""
		show_controls()
		if error != OK: feedback.text = "Could not save that binding."
		get_viewport().set_input_as_handled()
		return
	if lock_notice != null:
		if event is InputEventKey:
			if event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE: _close_lock_notice()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and PCSettings.logical_key(event.physical_keycode) == KEY_ESCAPE:
		if state == "controls": show_settings(settings_return)
		elif state in ["settings","reference"]: close_settings()
		elif state in ["shop","records","credits"]: show_start()
		elif state == "results":
			if result_back != null and not result_back.disabled: show_start()
			else: feedback.text = "Save the result successfully before leaving."
		else: return
		get_viewport().set_input_as_handled()

const TUTORIAL_STEPS := [
	"Build a Flak with [1], then click an empty owned slot. This practice uses 10000 training energy and quiet pressure; campaign funds are unchanged.",
	"Destroy the approaching practice machine. Weapon kills grant energy; solar ability kills do not.",
	"Purchase the next whole ring with [Q]. The Relay is automatic and uses no building slot.",
	"Build one Wall with [H] on ring 2. Walls redirect ordinary machines toward an opening; do not seal the full perimeter.",
	"Observe seven broken wedges collapsing ring 1. This step opens a training breach in ring 2, damages six inner wedges and sends an attacker to the seventh.",
	"Reclaim collapsed ring 1: [Y], then click that ring. The outer ring survives.",
	"Repair the damaged ring 1 wedge 3: [T], then click it. The training fixture sets its HP to 40.",
	"Relay brownout: select ring 1, then [G] and click it to rebuild. This fixture explicitly destroys its Relay. An inward interruption reduces outer power too.",
	"Use EMP Burst [X], aim at the practice machine and click. Casting is one-shot and starts a cooldown without awarding energy.",
	"Click ring 2 in the minimap to focus it. WASD or middle drag pans and the wheel zooms; hidden UI leaves the world clickable.",
	"Enemy reference: Standard follows openings; Foundry is durable; Transfer hops one ring; Sapper camps the Relay; Breacher seeks walls; Assembler ignores walls and grows; Tunneler warns at its destination. Kill Sappers before rebuilding. Use terrain, focused fire and solar tools together."
]

func _tutorial_occupants() -> int:
	var count := 0
	for ring in live.state.rings.values():
		for plate in ring.wedges.values(): count += plate.occupants.size()
	return count

func _start_tutorial() -> void:
	var quiet: Dictionary = live.profile.with_overrides({"pressure":{"spawn_per_second":0}})
	live.profile = quiet.profile
	live.simulation.profile = quiet.profile
	for flag in ["tunnelers_enabled","foundry_enabled","transfer_enabled","sapper_enabled","breacher_enabled","assembler_enabled"]:
		live.simulation.set(flag,false)
	live.simulation.state.energy = 10000
	live.sync_simulation()
	tutorial_card = PanelContainer.new()
	tutorial_card.position = Vector2(700,1070)
	tutorial_card.size = Vector2(1160,320)
	tutorial_card.theme = shell.theme
	shell.add_child(tutorial_card)
	var column := VBoxContainer.new()
	tutorial_card.add_child(column)
	tutorial_text = Label.new()
	tutorial_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(tutorial_text)
	var row := HBoxContainer.new()
	column.add_child(row)
	tutorial_next = _action("Next",advance_tutorial,row)
	_action("Replay tutorial",request_restart,row)
	_action("Exit practice",abandon_run,row)
	_prepare_tutorial_step()

func _practice_actor(ring: int, wedge: int, hp: float = 1, damage: float = 0) -> void:
	live.simulation.pool.spawn({"position":PolarPosition.new(ring,wedge,0,0.5),"hp":hp,"damage_per_second":damage,"speed_ring_widths_per_second":1.0})

func _prepare_tutorial_step() -> void:
	record_marker("diagnostic",{"tutorial_step":tutorial_step,"fixture_instruction":TUTORIAL_STEPS[tutorial_step]})
	live.choose_build(&"")
	tutorial_text.text = "Tutorial %d / %d\n%s" % [tutorial_step+1,TUTORIAL_STEPS.size(),TUTORIAL_STEPS[tutorial_step]]
	tutorial_next.disabled = tutorial_step != 10
	tutorial_baseline = {"occupants":_tutorial_occupants(),"kills":live.simulation.run_summary().kills,"rebuilds":live.simulation.run_summary().relay_rebuilds}
	match tutorial_step:
		1: _practice_actor(2,12)
		4:
			live.state.rings[2].wedges[7].hp = 0
			live.state.rings[2].wedges[7].erase("wall")
			for wedge in range(1,7):
				live.state.rings[1].wedges[wedge].hp = 0
				live.state.rings[1].wedges[wedge].erase("wall")
			live.state.rings[1].wedges[7].hp = 0.01
			live.state.rings[1].wedges[7].erase("wall")
			_practice_actor(2,7,1000,6)
		6: live.state.rings[1].wedges[3].hp = 40
		7: live.state.rings[1].relay_hp = 0
		8: _practice_actor(3,3,1000,0)
	live.sync_simulation()

func _update_tutorial() -> void:
	if tutorial_next == null: return
	var done := false
	match tutorial_step:
		0: done = _tutorial_occupants() > int(tutorial_baseline.occupants)
		1: done = live.simulation.run_summary().kills > int(tutorial_baseline.kills)
		2: done = live.state.rings.size() >= 2
		3:
			for plate in live.state.rings[2].wedges.values():
				if plate.has("wall"): done = true
		4: done = live.state.rings[1].get("collapsed",false)
		5: done = not live.state.rings[1].get("collapsed",false)
		6: done = live.state.rings[1].wedges[3].hp >= live.state.rings[1].wedges[3].max_hp
		7: done = live.simulation.run_summary().relay_rebuilds > int(tutorial_baseline.rebuilds)
		8: done = live.simulation.abilities_snapshot().get(&"emp_burst",0) > 0
		9: done = live.selected_cell.x == 2 and live.grid.world_to_cell(live.camera.position).x == 2
		10: done = true
	tutorial_next.disabled = not done
	if done and tutorial_step == 4:
		for id in live.simulation.pool.active_ids(): live.simulation.pool.release(id)

func advance_tutorial() -> void:
	if tutorial_next.disabled: return
	if tutorial_step == 10:
		var candidate := progress.duplicate(true)
		candidate.tutorial_completed = true
		if not _save_candidate(candidate):
			tutorial_text.text = feedback.text
			return
		abandon_run()
		return
	tutorial_step += 1
	_prepare_tutorial_step()
