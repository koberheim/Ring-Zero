extends Node
## Original deterministic synthesis; bounded voices, no external audio licenses.
var voices: Array[AudioStreamPlayer] = []
var ambience: AudioStreamPlayer
var sounds := {}
var next_voice := 0
var cooldowns := {}
var playback_enabled := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	playback_enabled = DisplayServer.get_name() != "headless"
	for index in 8:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	for item in [["ui",520.0,0.07],["build",180.0,0.24],["shot",95.0,0.1],["breach",48.0,0.8],["solar",330.0,0.65],["victory",440.0,1.6],["defeat",65.0,1.8]]:
		sounds[item[0]] = synth(item[1],item[2],item[0])
	ambience = AudioStreamPlayer.new()
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
	if ambience != null: ambience.volume_db = linear_to_db(maxf(0.00001,PCSettings.master*PCSettings.music*0.25))
	for voice in voices: voice.volume_db = linear_to_db(maxf(0.00001,PCSettings.master*PCSettings.effects))

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
	for voice in voices:
		voice.stop()
		voice.stream = null
	if ambience != null:
		ambience.stop()
		ambience.stream = null
	sounds.clear()

func play(kind: String) -> void:
	if not playback_enabled or not sounds.has(kind) or voices.is_empty(): return
	var now := Time.get_ticks_msec()
	if now < cooldowns.get(kind,0): return
	cooldowns[kind] = now + (130 if kind == "shot" else 60)
	var voice := voices[next_voice]
	next_voice = (next_voice+1)%voices.size()
	voice.stream = sounds[kind]
	voice.play()
