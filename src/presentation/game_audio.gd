extends Node
## Authored offline adapter. Legacy synthesis is an explicit development fallback
## while source admission is pending; diagnostics never count it as shipped audio.
const Director = preload("res://src/audio/audio_director.gd")
const LEGACY_IDS := {"ui":"ui.confirm", "build":"action.build", "shot":"weapon.flak.fire", "breach":"wedge.fracture", "solar":"solar.flare", "victory":"outcome.victory", "defeat":"outcome.defeat"}
var director: Node
var legacy_development_fallback := false
var operation_paused := false
var voices: Array[AudioStreamPlayer] = []
var ambience: AudioStreamPlayer
var sounds := {}
var next_voice := 0
var cooldowns := {}
var playback_enabled := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	playback_enabled = DisplayServer.get_name() != "headless"
	director = Director.new()
	add_child(director)
	apply_levels()
	legacy_development_fallback = not director.diagnostics().source_admission_complete
	if not playback_enabled: return
	if not legacy_development_fallback:
		director.set_music_state("menu")
		return
	push_warning("T-085 source admission pending: development audio placeholders are active.")
	for index in 8:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		voices.append(voice)
	for item in [["ui",520.0,0.07],["build",180.0,0.24],["shot",95.0,0.1],["breach",48.0,0.8],["solar",330.0,0.65],["victory",440.0,1.6],["defeat",65.0,1.8]]:
		sounds[item[0]] = synth(item[1],item[2],item[0])
	ambience = AudioStreamPlayer.new()
	ambience.bus = "Music"
	add_child(ambience)
	ambience.stream = synth(55.0,8.0,"ambient")
	apply_levels()
	if playback_enabled: ambience.play()

func synth(frequency: float, duration: float, kind: String) -> AudioStreamWAV:
	const RATE := 22050
	var count := int(duration * RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8417
	for index in count:
		var t := float(index) / RATE
		var phase := t / duration
		var envelope := minf(t / 0.012, 1.0) * pow(1.0 - phase, 2)
		var value := sin(TAU * frequency * t) * 0.6 + sin(TAU * frequency * 1.5 * t) * 0.15
		if kind in ["shot","breach","build"]: value = value * 0.4 + rng.randf_range(-0.5,0.5) * (1.0-phase)
		if kind == "victory": value = (sin(TAU*440*t)+sin(TAU*550*t)+sin(TAU*660*t))*0.22
		if kind == "ambient":
			# All frequencies are integer cycles in the eight-second loop.
			value = (sin(TAU*55*t)*0.25+sin(TAU*82.5*t)*0.12+sin(TAU*110*t)*0.05) * (0.65+0.15*cos(TAU*t/8.0))
			envelope = 1.0
		bytes.encode_s16(index*2,int(clampf(value*envelope,-1,1)*24000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	if kind == "ambient":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func apply_levels() -> void:
	if director != null:
		director.set_levels({"Master":PCSettings.master,"Music":PCSettings.music,"SFX":PCSettings.effects,"UI":PCSettings.ui,"Ambience":PCSettings.ambience})
	if ambience != null: ambience.volume_db = linear_to_db(0.25)
	for voice in voices: voice.volume_db = 0.0

func set_levels(values: Dictionary) -> void:
	if director != null: director.set_levels(values)

func emit_cue(event_id: StringName, screen_pan: float = 0.0, strength: float = 1.0) -> bool:
	return director.emit_cue(event_id, screen_pan, strength) if director != null else false

func set_music_state(state_id: String) -> bool:
	return director.set_music_state(state_id) if director != null else false

func set_paused(value: bool) -> void:
	operation_paused = value
	if director != null: director.set_paused(value)
	if ambience != null: ambience.stream_paused = value
	if value:
		for voice in voices: voice.stop()

func diagnostics() -> Dictionary:
	var result: Dictionary = director.diagnostics() if director != null else {}
	result["legacy_development_fallback"] = legacy_development_fallback
	return result

func _exit_tree() -> void:
	_stop_all()

func shutdown() -> void:
	# AudioServer retires stopped playback on its mixing thread. Begin teardown
	# while the tree is still running, then allow those queued removals to drain.
	# This is asynchronous and continues even if the operation is paused.
	_stop_all()
	if DisplayServer.get_name() != "headless" and is_inside_tree():
		await get_tree().create_timer(0.12, true, false, true).timeout

func _stop_all() -> void:
	playback_enabled = false
	if director != null: director.stop_all()
	for voice in voices:
		voice.stop()
		voice.stream = null
	if ambience != null:
		ambience.stop()
		ambience.stream = null
	sounds.clear()

func play(kind: String) -> void:
	# Historical callers do not identify a weapon. B replaces these aliases with
	# true event IDs; this adapter does not infer the identity from arbitrary hits.
	if LEGACY_IDS.has(kind) and director != null and director.has_cue(LEGACY_IDS[kind]):
		director.emit_cue(LEGACY_IDS[kind])
		return
	if operation_paused and kind != "ui": return
	if not playback_enabled or not sounds.has(kind) or voices.is_empty(): return
	var now := Time.get_ticks_msec()
	if now < cooldowns.get(kind,0): return
	cooldowns[kind] = now + (130 if kind == "shot" else 60)
	var voice := voices[next_voice]
	next_voice = (next_voice+1)%voices.size()
	voice.stream = sounds[kind]
	voice.bus = "UI" if kind == "ui" else "SFX"
	voice.play()
