extends Control
## Between-run controller: rules prepare choices; ProfileStore owns persistence.
const ThemeKit = preload("res://src/presentation/industrial_theme.gd")
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	stage.size = Vector2i(1440,810)
	stage.transparent_bg = true
	stage.handle_input_locally = true
	stage.gui_embed_subwindows = true
	stage.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	frame.add_child(stage)
	shell = Control.new()
	shell.size = Vector2(1440,810)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = 100
	stage.add_child(layer)
	layer.add_child(shell)
	menu_backdrop = ColorRect.new()
	menu_backdrop.color = Color("10161b")
	menu_backdrop.size = Vector2(1440,810)
	menu_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(menu_backdrop)
	get_viewport().size_changed.connect(_resize)
	_resize()
	_load_profile()

func _resize() -> void:
	if frame == null:
		return
	var viewport_size := get_viewport_rect().size
	var factor := minf(viewport_size.x/1440.0,viewport_size.y/810.0)
	# A fixed design viewport plus container scale preserves world and UI aspect.
	frame.stretch = false
	stage.size = Vector2i(1440,810)
	frame.size = Vector2(1440,810)
	frame.scale = Vector2.ONE*factor
	frame.position = (viewport_size-Vector2(1440,810)*factor)*0.5
	content_backdrop.position = frame.position
	content_backdrop.size = Vector2(1440,810)*factor

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
	page = PanelContainer.new()
	page.position = Vector2(252,54)
	page.size = Vector2(936,610 if title == "Ring Zero" else 702)
	if title == "Ring Zero": page.position.y = 100
	page.theme = ThemeKit.make(float(progress.get("settings",{}).get("ui_scale",1.0)))
	shell.add_child(page)
	var layout := VBoxContainer.new()
	page.add_child(layout)
	var heading := Label.new()
	heading.text = title
	ThemeKit.heading(heading,36)
	layout.add_child(heading)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(feedback)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	footer = HBoxContainer.new()
	layout.add_child(footer)

func _text(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)
	return label

func _action(title: String, callback: Callable, parent: Node = null) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 36
	(parent if parent != null else content).add_child(button)
	button.pressed.connect(callback)
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
	_text("Orbital defense / Run configuration")
	_text("Credits: %d" % int(progress.currency))
	var body := content
	var columns := HBoxContainer.new()
	body.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 410
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	content = left
	for category in ["doctrines","loadouts"]:
		var field := "doctrine" if category == "doctrines" else "loadout"
		_text("Doctrine" if category == "doctrines" else "Starting loadout")
		var select := OptionButton.new()
		content.add_child(select)
		var details := _text("")
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
	content = right
	_text("Optional challenges")
	for id in catalogue.get("mutators",{}):
		var entry: Dictionary = catalogue.mutators[id]
		var toggle := CheckButton.new()
		toggle.text = str(entry.get("label",id))
		toggle.tooltip_text = str(entry.get("description",""))
		toggle.button_pressed = id in choices.mutators
		content.add_child(toggle)
		toggle.toggled.connect(func(enabled: bool):
			if enabled and id not in choices.mutators: choices.mutators.append(id)
			elif not enabled: choices.mutators.erase(id)
		)
		_text(str(entry.get("description","")))
	content = body
	var start_button := _action("Start run",begin_run.bind(false),footer)
	start_button.add_theme_stylebox_override("normal",ThemeKit.box(ThemeKit.AMBER,ThemeKit.AMBER,8))
	start_button.add_theme_color_override("font_color",ThemeKit.HOUSING)
	_action("Shop",show_shop,footer)
	_action("Tutorial",begin_run.bind(true),footer)
	_action("Settings",show_settings.bind("start"),footer)
	_action("Reference",show_reference.bind("start"),footer)
	_action("Quit",func(): get_tree().quit(),footer)

func begin_run(practice: bool = false) -> void:
	var base: Dictionary = BalanceProfile.load_json("res://data/balance/testing.json")
	if not base.ok:
		feedback.text = _errors(base)
		return
	var prepared: Dictionary = rules.create_run(base.profile,choices,progress,practice)
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
	menu_backdrop.hide()
	live = load("res://scenes/live_view.tscn").instantiate()
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
	lock_shield.size = Vector2(1440,810)
	lock_shield.color = Color(0,0,0,0.45)
	shell.add_child(lock_shield)
	lock_notice = PanelContainer.new()
	lock_notice.position = Vector2(380,260)
	lock_notice.size = Vector2(680,220)
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
	if tutorial_card != null:
		tutorial_card.visible = state == "tutorial" and live != null and not live.menu_open and lock_notice == null
	if live == null:
		return
	if not recorder_error.is_empty(): live.feedback_label.text = recorder_error
	if state in ["playing","tutorial"] and (live.simulation.ended or not live.last_error.is_empty()):
		finish_run("practice" if current_run.get("practice",false) else ("error" if not live.last_error.is_empty() else "defeat"))
	elif state == "tutorial":
		_update_tutorial()

func finish_run(outcome: String) -> void:
	if outcome == "error": record_marker("error",{"message":live.last_error})
	_finish_trace(outcome)
	state = "results"
	get_tree().paused = true
	var summary: Dictionary = live.simulation.run_summary(outcome)
	var reward: Dictionary = rules.reward(summary,float(current_run.reward_multiplier))
	_new_page("Run ended" if outcome != "practice" else "Practice ended")
	if not recorder_error.is_empty(): _text(recorder_error)
	if not live.last_error.is_empty(): _text(live.last_error)
	_text("Survived %.1f seconds\nKills: %d\nHighest ring: %d\nRelays rebuilt: %d" % [summary.elapsed_seconds,summary.kills,summary.highest_ring,summary.relay_rebuilds])
	if not reward.ok:
		feedback.text = _errors(reward)
		return
	settlement = {"summary":summary,"reward":reward}
	result_reward = _text("Pending reward: %d credits" % reward.amount)
	var reward_labels := {"survival":"Survival credits","kills":"Kill credits","rings":"Expansion credits","survive_300":"Challenge: survive five minutes","kills_250":"Challenge: destroy 250 machines","rebuild_relay":"Challenge: rebuild a Relay","subtotal":"Base reward","multiplier":"Run reward multiplier"}
	for item in reward.breakdown:
		if reward_labels.has(item): _text("%s: %s" % [reward_labels[item],str(reward.breakdown[item])])
	if not reward.breakdown.get("eligible",false): _text("No campaign rewards for practice, abandonment or interrupted runs.")
	result_save = _action("Save result",save_result,footer)
	result_retry = _action("Retry run",begin_run.bind(false),footer)
	result_back = _action("Return to start",show_start,footer)
	result_retry.disabled = true
	result_back.disabled = true
	save_result()

func save_result() -> void:
	var settled: Dictionary = store.settle_run(progress,run_id,int(settlement.reward.amount))
	if not settled.ok:
		feedback.text = _errors(settled)
		return
	if _save_candidate(settled.profile):
		feedback.text = "Result saved. Credits: %d" % progress.currency
		result_reward.text = "Earned reward: %d credits (saved)" % settlement.reward.amount
		result_save.disabled = true
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
	_text("Controls: 1-5 weapons; Q whole ring purchase; W Wall; E Armor; R Repair Node; T Repair Wedge; Y Reclaim; G Rebuild Relay. A/S/D terrain, F direction, Z/X solar. Build tools repeat on distinct clicks; solar casts once. Right/Esc cancel. Tab catalogue. Middle drag pan, wheel zoom, minimap focus.")
	_action("Back",close_settings,footer)
	state = "reference"

func show_settings(return_to: String = "start") -> void:
	settings_return = return_to
	_new_page("Settings")
	for key in ["fullscreen","reduced_motion","effects"]:
		var toggle := CheckButton.new()
		toggle.text = {"fullscreen":"Fullscreen","reduced_motion":"Reduced motion","effects":"Weapon feedback"}[key]
		toggle.button_pressed = progress.settings[key]
		content.add_child(toggle)
		toggle.toggled.connect(func(value: bool): _change_setting(key,value))
	_text("Interface scale")
	var scale_choice := OptionButton.new()
	content.add_child(scale_choice)
	for value in [1.0,1.15,1.3]:
		scale_choice.add_item("%d%%" % roundi(value*100))
		if is_equal_approx(progress.settings.ui_scale,value): scale_choice.select(scale_choice.item_count-1)
	scale_choice.item_selected.connect(func(index: int): _change_setting("ui_scale",[1.0,1.15,1.3][index]))
	_text("Fonts: Barlow / Barlow Semi Condensed. Copyright The Barlow Project Authors. SIL Open Font License 1.1; bundled license in assets/ui/fonts/barlow/OFL.txt.")
	_action("Back",close_settings,footer)
	state = "settings"

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
		menu_backdrop.hide()
		state = "tutorial" if current_run.get("practice",false) else "playing"
	else: show_start()

func _input(event: InputEvent) -> void:
	if lock_notice != null:
		if event is InputEventKey:
			if event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE: _close_lock_notice()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		if state in ["settings","reference"]: close_settings()
		elif state == "shop": show_start()
		elif state == "results":
			if result_back != null and not result_back.disabled: show_start()
			else: feedback.text = "Save the result successfully before leaving."
		else: return
		get_viewport().set_input_as_handled()

const TUTORIAL_STEPS := [
	"Build a Flak with [1], then click an empty owned slot. This practice uses 10000 training energy and quiet pressure; campaign funds are unchanged.",
	"Destroy the approaching practice machine. Weapon kills grant energy; solar ability kills do not.",
	"Purchase the next whole ring with [Q]. The Relay is automatic and uses no building slot.",
	"Build one Wall with [W] on ring 2. Walls redirect ordinary machines toward an opening; do not seal the full perimeter.",
	"Observe seven broken wedges collapsing ring 1. This step opens a training breach in ring 2, damages six inner wedges and sends an attacker to the seventh.",
	"Reclaim collapsed ring 1: [Y], then click that ring. The outer ring survives.",
	"Repair the damaged ring 1 wedge 3: [T], then click it. The training fixture sets its HP to 40.",
	"Relay brownout: select ring 1, then [G] and click it to rebuild. This fixture explicitly destroys its Relay. An inward interruption reduces outer power too.",
	"Use EMP Burst [X], aim at the practice machine and click. Casting is one-shot and starts a cooldown without awarding energy.",
	"Click ring 2 in the minimap to focus it. Middle drag pans and the wheel zooms; hidden UI leaves the world clickable.",
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
	tutorial_card.position = Vector2(338,596)
	tutorial_card.size = Vector2(772,186)
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
