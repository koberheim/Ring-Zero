class_name PCSettings
extends RefCounted
## Machine-local settings are deliberately separate from cloud-synced progress.
const DEFAULT_KEYS := {"Flak":KEY_1,"Mass Driver":KEY_2,"EMP Node":KEY_3,"Lance Emitter":KEY_4,"Point Defense":KEY_5,"Expand":KEY_Q,"Wall":KEY_W,"Armor":KEY_E,"Repair Node":KEY_R,"Repair":KEY_T,"Reclaim":KEY_Y,"Relay":KEY_G,"Debris":KEY_A,"Tractor":KEY_S,"Occlusion":KEY_D,"Flare":KEY_Z,"EMP Burst":KEY_X,"Reverse tractor":KEY_F,"Catalogue":KEY_TAB,"Reference":KEY_F1,"Pause / cancel":KEY_ESCAPE,"Tactical overlay":KEY_ALT}
static var bindings: Dictionary = DEFAULT_KEYS.duplicate()
const DEFAULT_PAD := {"Confirm":JOY_BUTTON_A,"Back":JOY_BUTTON_B,"EMP":JOY_BUTTON_X,"Flare":JOY_BUTTON_Y,"Pause":JOY_BUTTON_START,"Previous tool":JOY_BUTTON_LEFT_SHOULDER,"Next tool":JOY_BUTTON_RIGHT_SHOULDER,"Scroll up":JOY_BUTTON_DPAD_UP,"Scroll down":JOY_BUTTON_DPAD_DOWN,"Catalogue":JOY_BUTTON_BACK}
const DEFAULT_MOUSE := {"Place / select":MOUSE_BUTTON_LEFT,"Cancel tool":MOUSE_BUTTON_RIGHT,"Pan":MOUSE_BUTTON_MIDDLE,"Zoom in":MOUSE_BUTTON_WHEEL_UP,"Zoom out":MOUSE_BUTTON_WHEEL_DOWN}
static var pad: Dictionary = DEFAULT_PAD.duplicate()
static var mouse: Dictionary = DEFAULT_MOUSE.duplicate()
static var master := 0.8
static var music := 0.45
static var effects := 0.75
static var path := "user://pc_settings.cfg"

static func load_settings(location: String) -> void:
	path = location
	bindings = DEFAULT_KEYS.duplicate()
	pad = DEFAULT_PAD.duplicate()
	mouse = DEFAULT_MOUSE.duplicate()
	master = 0.8
	music = 0.45
	effects = 0.75
	var config := ConfigFile.new()
	if config.load(path) != OK: return
	pad = _validated_map(config.get_value("input","pad",pad),DEFAULT_PAD,0,127)
	mouse = _validated_map(config.get_value("input","mouse",mouse),DEFAULT_MOUSE,1,9)
	var candidate: Variant = config.get_value("input", "bindings", bindings)
	if candidate is Dictionary and candidate.size() == DEFAULT_KEYS.size():
		var used := {}
		var valid := true
		for action in DEFAULT_KEYS:
			var key: Variant = candidate.get(action)
			if not key is int or key <= 0 or key > 0x01ffffff or used.has(key):
				valid = false
				break
			used[key] = true
		if valid: bindings = candidate.duplicate()
	for bus in ["master", "music", "effects"]:
		var value: Variant = config.get_value("audio", bus, 0.5)
		if (value is float or value is int) and is_finite(value) and value >= 0 and value <= 1:
			match bus:
				"master": master = value
				"music": music = value
				"effects": effects = value

static func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("input", "bindings", bindings)
	config.set_value("input", "pad", pad)
	config.set_value("input", "mouse", mouse)
	config.set_value("audio", "master", master)
	config.set_value("audio", "music", music)
	config.set_value("audio", "effects", effects)
	return config.save(path)

static func rebind(action: String, key: int) -> Error:
	if not DEFAULT_KEYS.has(action) or key <= 0 or key > 0x01ffffff: return ERR_INVALID_PARAMETER
	if key in [KEY_CTRL,KEY_META,KEY_SHIFT] or (key == KEY_ALT and action != "Tactical overlay"): return ERR_INVALID_PARAMETER
	var previous := bindings.duplicate()
	for other in bindings:
		if other != action and bindings[other] == key: bindings[other] = bindings[action]
	bindings[action] = key
	var error := save_settings()
	if error != OK: bindings = previous
	return error

static func logical_key(physical: int) -> int:
	for action in bindings:
		if bindings[action] == physical: return DEFAULT_KEYS[action]
	# An unbound old default must not keep activating its former action.
	return 0 if physical in DEFAULT_KEYS.values() else physical

static func label(action: String) -> String:
	return OS.get_keycode_string(bindings.get(action, 0))

static func _validated_map(candidate: Variant, defaults: Dictionary, low: int, high: int) -> Dictionary:
	if not candidate is Dictionary or candidate.size() != defaults.size(): return defaults.duplicate()
	var seen := {}
	for action in defaults:
		var value: Variant = candidate.get(action)
		if not value is int or value < low or value > high or seen.has(value): return defaults.duplicate()
		seen[value] = true
	return candidate.duplicate()

static func rebind_button(group: String, action: String, button: int) -> Error:
	var map: Dictionary = pad if group == "pad" else mouse
	var defaults: Dictionary = DEFAULT_PAD if group == "pad" else DEFAULT_MOUSE
	if not map.has(action) or button < (0 if group == "pad" else 1) or button > (127 if group == "pad" else 9): return ERR_INVALID_PARAMETER
	if group == "mouse" and ((action in ["Zoom in","Zoom out"]) != (button in [4,5,6,7])): return ERR_INVALID_PARAMETER
	var previous := map.duplicate()
	for other in map:
		if other != action and map[other] == button: map[other] = map[action]
	map[action] = button
	if _validated_map(map,defaults,0 if group == "pad" else 1,127 if group == "pad" else 9) != map: return ERR_INVALID_PARAMETER
	var error := save_settings()
	if error != OK:
		if group == "pad": pad = previous
		else: mouse = previous
	return error

static func pad_button(physical: int) -> int:
	for action in pad:
		if pad[action] == physical: return DEFAULT_PAD[action]
	return -1

static func world_event(event: InputEvent) -> InputEvent:
	if not event is InputEventMouseButton or event.device == -8: return event
	var result := event.duplicate() as InputEventMouseButton
	for action in mouse:
		if mouse[action] == event.button_index:
			result.button_index = DEFAULT_MOUSE[action]
			return result
	result.button_index = MOUSE_BUTTON_NONE
	return result
