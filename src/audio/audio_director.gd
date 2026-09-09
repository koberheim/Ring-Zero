extends Node
## Offline authored audio. Missing/unadmitted cues are explicit and never synthesized.

const Policy = preload("res://src/audio/cue_policy.gd")
const BANK_PATH := "res://data/audio/cues.json"
const MUSIC_STATES := ["menu", "run_low", "run_pressure", "run_climax", "assembler", "silent"]
const BUSES := ["Music", "SFX", "UI", "Ambience"]
const CROSSFADE_SECONDS := 1.25
const DUCK_DB := -7.0
const DUCK_ATTACK_SECONDS := 0.035
const DUCK_RELEASE_SECONDS := 0.65
const DUCK_HOLD_SECONDS := 0.4

var policy = Policy.new()
var bank := {}
var streams := {}
var invalid_assets: Array[String] = []
var voices: Array[AudioStreamPlayer] = []
var panners: Array[AudioEffectPanner] = []
var voice_buses: Array[String] = []
var owned_buses: Array[String] = []
var music_players: Array[AudioStreamPlayer] = []
var music_target := -1
var music_state := "silent"
var music_fades := [0.0, 0.0]
var music_gains := [0.0, 0.0]
var levels := {"Master": 0.8, "Music": 0.45, "SFX": 0.75, "UI": 0.75, "Ambience": 0.45}
var clock_seconds := 0.0
var duck_until := 0.0
var duck_db := 0.0
var operation_paused := false
var enabled := true
var emitted := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = DisplayServer.get_name() != "headless"
	_load_bank()
	if not enabled: return
	for bus in BUSES: _ensure_bus(bus, "Master")
	for index in Policy.VOICE_LIMIT:
		var bus := "RZVoice_%d_%d" % [get_instance_id(), index]
		_ensure_bus(bus, "SFX")
		var panner := AudioEffectPanner.new()
		AudioServer.add_bus_effect(AudioServer.get_bus_index(bus), panner)
		voice_buses.append(bus)
		panners.append(panner)
		var player := AudioStreamPlayer.new()
		player.bus = bus
		add_child(player)
		player.finished.connect(policy.release.bind(index))
		voices.append(player)
	for index in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		music_players.append(player)
	set_levels(levels)

func _ensure_bus(bus: String, send: String) -> void:
	if AudioServer.get_bus_index(bus) >= 0: return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_send(index, send)
	owned_buses.append(bus)

func _load_bank() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BANK_PATH))
	if not parsed is Dictionary:
		invalid_assets.append("Invalid audio bank")
		return
	bank = parsed
	for event_id in bank.get("cues", {}):
		var cue: Dictionary = bank.cues[event_id]
		var admitted: Array[AudioStream] = []
		for variant in cue.get("variants", []):
			if not variant is Dictionary or not variant.get("admitted", false): continue
			var path: String = variant.get("path", "")
			if not path.begins_with("res://assets/audio/") or ".." in path:
				invalid_assets.append(path)
				continue
			if variant.get("source_ids", []).is_empty() or not _sources_admitted(variant.source_ids):
				invalid_assets.append(path + " missing admitted source")
				continue
			if not ResourceLoader.exists(path):
				invalid_assets.append(path)
				continue
			var stream = load(path)
			if stream is AudioStream:
				admitted.append(stream)
			else:
				invalid_assets.append(path)
		streams[event_id] = admitted

func _sources_admitted(ids: Array) -> bool:
	for source_id in ids:
		var source: Dictionary = bank.get("sources", {}).get(source_id, {})
		if not source.get("commercial_use_verified", false) or not source.get("download_verified", false): return false
		if float(source.get("spend_usd", -1.0)) != 0.0 or str(source.get("sha256", "")).length() != 64: return false
	return true

func has_cue(event_id: String) -> bool:
	return streams.has(event_id) and not streams[event_id].is_empty()

func emit_cue(event_id: StringName, pan: float = 0.0, strength: float = 1.0) -> bool:
	var key := String(event_id)
	if not bank.get("cues", {}).has(key):
		policy.rejected.unknown += 1
		return false
	if not has_cue(key):
		policy.rejected.missing += 1
		return false
	if not enabled or not is_finite(strength) or strength <= 0.0: return false
	var cue: Dictionary = bank.cues[key]
	var variants: Array = streams[key]
	var stream: AudioStream = variants[policy.select_variant(key, variants.size())]
	var pitch: float = policy.rng.randf_range(float(cue.get("pitch_min", 1.0)), float(cue.get("pitch_max", 1.0)))
	var index: int = policy.reserve(key, cue, clock_seconds, stream.get_length() / pitch, operation_paused)
	if index < 0: return false
	var player := voices[index]
	player.stop()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = float(cue.get("gain_db", -8.0)) + linear_to_db(clampf(strength, 0.00001, 1.0))
	var bus: String = cue.get("bus", "SFX")
	AudioServer.set_bus_send(AudioServer.get_bus_index(voice_buses[index]), bus)
	panners[index].pan = 0.0 if bus == "UI" else Policy.screen_pan(pan)
	player.play()
	if int(cue.get("priority", 0)) >= Policy.CRITICAL_PRIORITY:
		duck_until = maxf(duck_until, clock_seconds + DUCK_HOLD_SECONDS)
	emitted += 1
	return true

func set_music_state(state_id: String) -> bool:
	if state_id not in MUSIC_STATES: return false
	if state_id == music_state: return true
	if state_id == "silent":
		music_state = state_id
		music_target = -1
		return true
	var event_id := "music." + state_id
	if not enabled or not has_cue(event_id): return false
	music_target = 0 if music_target != 0 else 1
	music_state = state_id
	var player := music_players[music_target]
	player.stop()
	player.stream = streams[event_id][0]
	music_gains[music_target] = float(bank.cues[event_id].get("gain_db", -10.0))
	player.volume_db = -80.0
	music_fades[music_target] = 0.0
	player.play()
	player.stream_paused = operation_paused
	return true

func _process(delta: float) -> void:
	if not enabled: return
	# The presentation clock advances on pause for UI cooldowns. Gameplay voices
	# are stopped on pause, while music preserves its stream position.
	clock_seconds += delta
	var duck_target := DUCK_DB if clock_seconds < duck_until else 0.0
	var duck_time := DUCK_ATTACK_SECONDS if duck_target < duck_db else DUCK_RELEASE_SECONDS
	duck_db = move_toward(duck_db, duck_target, absf(DUCK_DB) * delta / duck_time)
	for index in music_players.size():
		var player := music_players[index]
		var target := 1.0 if index == music_target else 0.0
		music_fades[index] = move_toward(music_fades[index], target, delta / CROSSFADE_SECONDS)
		player.volume_db = linear_to_db(maxf(0.0001, sin(music_fades[index] * PI * 0.5))) + music_gains[index] + duck_db
		if music_fades[index] == 0.0 and index != music_target: player.stop()

func set_levels(values: Dictionary) -> void:
	for bus in levels:
		if values.has(bus) and (values[bus] is float or values[bus] is int) and is_finite(values[bus]):
			levels[bus] = clampf(float(values[bus]), 0.0, 1.0)
		var index := AudioServer.get_bus_index(bus)
		if enabled and index >= 0:
			AudioServer.set_bus_mute(index, float(levels[bus]) <= 0.0)
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.00001, float(levels[bus]))))

func set_paused(value: bool) -> void:
	operation_paused = value
	for index in voices.size():
		if policy.active[index].bus != "UI":
			voices[index].stop()
			policy.release(index)
	for player in music_players: player.stream_paused = value
	if value: duck_until = 0.0

func diagnostics() -> Dictionary:
	var missing: Array[String] = []
	for event_id in bank.get("cues", {}):
		if not has_cue(event_id): missing.append(event_id)
	return {"required_cues": bank.get("cues", {}).size(), "missing_cues": missing,
		"source_admission_complete": missing.is_empty() and not bank.is_empty() and invalid_assets.is_empty(),
		"invalid_assets": invalid_assets.duplicate(), "emitted": emitted,
		"rejected": policy.rejected.duplicate(), "music_state": music_state,
		"headless": DisplayServer.get_name() == "headless", "levels": levels.duplicate()}

func stop_all() -> void:
	enabled = false
	for player in voices:
		player.stop()
		player.stream = null
	for player in music_players:
		player.stop()
		player.stream = null
	policy.reset()
	streams.clear()

func _exit_tree() -> void:
	stop_all()
	owned_buses.reverse()
	for bus in owned_buses:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0: AudioServer.remove_bus(index)
	owned_buses.clear()
