extends SceneTree
const Policy = preload("res://src/audio/cue_policy.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var policy = Policy.new()
	var ordinary := {"priority":30,"bus":"SFX","cooldown_seconds":0.0}
	var critical := {"priority":100,"bus":"SFX","cooldown_seconds":0.0}
	for index in 20:
		check(policy.reserve("shot%d" % index,ordinary,0.0,3.0,false) >= 0,"Ordinary voice admitted within limit")
	check(policy.reserve("overflow",ordinary,0.0,3.0,false) == -1,"Ordinary fire cannot occupy critical reserve")
	for index in 4:
		check(policy.reserve("critical%d" % index,critical,0.0,3.0,false) >= 20,"Critical warning uses reserved voice")
	check(policy.reserve("overflow",ordinary,0.0,3.0,false) == -1,"Ordinary fire never steals critical warning")
	check(policy.reserve("collapse",critical,0.0,3.0,false) >= 0,"Critical event preempts ordinary fire after reserve fills")
	policy.reset()
	var cooldown := {"priority":40,"bus":"SFX","cooldown_seconds":0.2}
	check(policy.reserve("flak",cooldown,0.0,0.1,false) >= 0,"First family shot accepted")
	check(policy.reserve("flak",cooldown,0.1,0.1,false) == -1,"Same-family cooldown enforced")
	check(policy.reserve("lance",cooldown,0.1,0.1,false) >= 0,"Another weapon is not suppressed by Flak cooldown")
	check(policy.reserve("flak",cooldown,0.21,0.1,false) >= 0,"Cooldown ends on presentation time")
	check(policy.reserve("paused_shot",ordinary,1.0,1.0,true) == -1,"Pause rejects gameplay cues")
	check(policy.reserve("ui",{"priority":50,"bus":"UI"},1.0,1.0,true) >= 0,"Pause retains UI sounds")
	check(Policy.screen_pan(-3.0) == -0.85 and Policy.screen_pan(3.0) == 0.85,"Pan clamps both offscreen bearings")
	check(Policy.screen_pan(NAN) == 0.0,"Invalid bearing remains centered")
	var previous := -1
	for index in 40:
		var selected: int = policy.select_variant("repeated",4)
		check(selected != previous,"Repeated source selection avoids immediate repetition")
		previous = selected
	var audio = load("res://src/presentation/game_audio.gd").new()
	root.add_child(audio)
	await process_frame
	var diagnostic: Dictionary = audio.diagnostics()
	check(diagnostic.required_cues == 52,"Complete event vocabulary is registered")
	check(not diagnostic.source_admission_complete,"Empty bank cannot claim source acceptance")
	check(diagnostic.missing_cues.size() == 52,"All unavailable families remain visible")
	check(not audio.emit_cue(&"ring.collapse",1.0),"Missing collapse is never silently replaced")
	check(not audio.set_music_state("assembler"),"Missing boss bed cannot claim playback")
	check(audio.set_music_state("silent"),"Silent state is supported")
	audio.set_levels({"Master":0.0,"Music":0.25,"SFX":0.5,"UI":0.6,"Ambience":0.15})
	check(audio.diagnostics().levels.Master == 0.0,"Master mute level retained exactly")
	check(audio.diagnostics().levels.UI == 0.6,"UI bus independently controllable")
	if DisplayServer.get_name() == "headless":
		check(audio.voices.is_empty() and audio.sounds.is_empty(),"Headless mode allocates no synthesized bank")
	audio.set_paused(true)
	audio.set_paused(false)
	await audio.shutdown()
	audio.queue_free()
	await process_frame
	print("Audio director: %d passed, %d failed" % [checks-failures,failures])
	quit(1 if failures else 0)
