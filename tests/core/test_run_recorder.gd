extends SceneTree
var checks := 0
var failures := 0
var fixture := ""

class FailedAppend extends RunRecorder:
	func _append_line(_line: String) -> Dictionary:
		return {"ok":false,"errors":PackedStringArray(["Injected disk failure"])}

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	fixture = "res://.godot/trace-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(fixture)
	_test_trace()
	_test_replay()
	for file in DirAccess.get_files_at(fixture): DirAccess.remove_absolute(fixture.path_join(file))
	DirAccess.remove_absolute(fixture)
	print("Run recorder: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func metadata() -> Dictionary:
	return RunRecorder.make_metadata("1", {"x":1.0}, {"x":1.0}, {}, {"unlocks":[],"upgrades":{},"currency":999}, false)

func put(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _test_trace() -> void:
	var path := fixture.path_join("trace.jsonl")
	var recorder := RunRecorder.new()
	var meta := metadata()
	check(not meta.progress.has("currency") and meta.randomness == "none", "metadata only reproduction game state")
	check(recorder.start(path, meta).ok, "start trace")
	meta.effective_profile.x = 2
	check(recorder.snapshot().header.metadata.effective_profile.x == 1, "header clone isolation")
	var args := {"radial_fraction":0.12345678901234566,"angular_fraction":0.9999999999999999}
	check(recorder.append_command(0,"cast_ability",args,true).ok, "finite scalar command")
	check(recorder.append_command(0,"purchase_ring",{},false,PackedStringArray(["Insufficient energy"])).ok, "rejected same-tick command retained")
	check(recorder.marker(1,"pause").ok and recorder.marker(1,"resume").ok, "pause resume same tick")
	check(recorder.finish(2,"defeat",{"kills":0}).ok, "end marker")
	check(not recorder.append_command(2,"after_end",{},true).ok, "cannot append after finish")
	var loaded := RunRecorder.load_trace(path)
	check(loaded.ok and loaded.complete and loaded.trace.records.size() == 5, "independent trace reload")
	check(loaded.trace.records[1].sequence == 1 and not loaded.trace.records[1].ok, "stable order and failure result")
	check(var_to_bytes(float(loaded.trace.records[0].args.radial_fraction)) == var_to_bytes(args.radial_fraction) and var_to_bytes(float(loaded.trace.records[0].args.angular_fraction)) == var_to_bytes(args.angular_fraction), "double scalar precision roundtrip")
	loaded.trace.records.clear()
	check(recorder.snapshot().records.size() == 5, "snapshot independent")
	check(not RunRecorder.new().start(path,metadata()).ok, "existing trace never overwritten")
	check(not RunRecorder.new().start("res://outside.jsonl",metadata()).ok, "unsafe path rejected")
	var truncated := fixture.path_join("truncated.jsonl")
	var content := FileAccess.get_file_as_string(path)
	put(truncated,content.trim_suffix("\n"))
	check(not RunRecorder.load_trace(truncated).ok, "truncated last line rejected")
	var reordered := fixture.path_join("reordered.jsonl")
	put(reordered,content.replace('"sequence":1','"sequence":9'))
	check(not RunRecorder.load_trace(reordered).ok, "sequence tampering rejected")
	var failing := FailedAppend.new()
	var failed_path := fixture.path_join("failed.jsonl")
	check(failing.start(failed_path,metadata()).ok and not failing.append_command(0,"purchase_ring",{},true).ok, "append failure reported")
	check(not failing.finish(0,"defeat",{}).ok and not RunRecorder.load_trace(failed_path).complete, "failed recorder cannot claim complete")
	var limit := RunRecorder.new()
	check(limit.start(fixture.path_join("limit.jsonl"),metadata()).ok, "limit fixture start")
	limit._bytes = RunRecorder.MAX_BYTES
	check(not limit.marker(0,"pause").ok, "byte bound before disk append")
	check(RunRecorder.fingerprint({"a":1,"b":2}) == RunRecorder.fingerprint({"b":2,"a":1}), "content ID ignores insertion order")
	for invalid_case in ["backward", "nonfinite", "errors", "record_limit"]:
		var rejected := RunRecorder.new()
		var rejected_path := fixture.path_join(invalid_case + ".jsonl")
		rejected.start(rejected_path,metadata())
		rejected.marker(1,"pause")
		var result: Dictionary
		match invalid_case:
			"backward": result = rejected.append_command(0,"late",{},true)
			"nonfinite": result = rejected.append_command(1,"invalid",{"value":INF},true)
			"errors": result = rejected.append_command(1,"invalid",{},false,[7])
			"record_limit":
				rejected._trace.records.resize(RunRecorder.MAX_RECORDS)
				result = rejected.append_command(1,"overflow",{},true)
		check(not result.ok and not rejected.finish(1,"defeat",{}).ok and not RunRecorder.load_trace(rejected_path).complete,"sticky failed recording " + invalid_case)

func _execute(sim: LiveSimulation, action: String, args: Dictionary) -> Dictionary:
	match action:
		"place_wall": return sim.place_wall(int(args.ring),int(args.wedge))
		"place_weapon": return sim.place_weapon(int(args.ring),int(args.wedge),int(args.slot),StringName(args.kind))
		"cast_ability": return sim.cast_ability(StringName(args.kind),PolarPosition.new(int(args.ring),int(args.wedge),float(args.radial_fraction),float(args.angular_fraction)))
	return {"ok":false,"errors":PackedStringArray(["Unknown replay command"])}

func _test_replay() -> void:
	var base := BalanceProfile.load_json("res://data/balance/testing.json")
	var tuned: Dictionary = base.profile.with_overrides({"pressure":{"spawn_delay_seconds":0,"spawn_per_second":60},"health":{"standard_machine_hp":100000}})
	var original: LiveSimulation = LiveSimulation.create(tuned.profile, 3).simulation
	var recorder := RunRecorder.new()
	var path := fixture.path_join("replay.jsonl")
	check(recorder.start(path,RunRecorder.make_metadata("2",base.profile.snapshot(),tuned.profile.snapshot(),{}, {},false)).ok, "replay metadata")
	var commands := [{"tick":0,"action":"place_wall","args":{"ring":1,"wedge":1}}, {"tick":0,"action":"place_wall","args":{"ring":1,"wedge":1}}, {"tick":5,"action":"place_weapon","args":{"ring":1,"wedge":2,"slot":0,"kind":"flak"}}, {"tick":8,"action":"cast_ability","args":{"kind":"emp_burst","ring":3,"wedge":1,"radial_fraction":0.12345678901234566,"angular_fraction":0.9999999999999999}}]
	var tick := 0
	for command in commands:
		while tick < command.tick:
			check(original.step(1.0/60.0).ok,"original tick")
			tick += 1
		var result := _execute(original,command.action,command.args)
		check(recorder.append_command(tick,command.action,command.args,result.ok,result.errors).ok,"record real command result")
	while tick < 10:
		check(original.step(1.0/60.0).ok,"original end tick")
		tick += 1
	check(recorder.finish(tick,"defeat",original.run_summary()).ok,"record final summary")
	var loaded := RunRecorder.load_trace(path)
	check(loaded.ok, "reload command replay: " + str(loaded.get("errors", [])))
	if not loaded.ok: return
	var replay_profile := BalanceProfile.from_dict(loaded.trace.header.metadata.effective_profile)
	var replay: LiveSimulation = LiveSimulation.create(replay_profile.profile,3).simulation
	tick = 0
	for row in loaded.trace.records:
		while tick < row.tick:
			check(replay.step(1.0/60.0).ok,"replay tick")
			tick += 1
		if row.type == "command":
			var result := _execute(replay,row.action,row.args)
			check(result.ok == row.ok and Array(result.errors) == row.errors,"replay accepted/rejected outcome")
	check(replay.state == original.state and replay.cooldowns == original.cooldowns and replay.abilities_snapshot() == original.abilities_snapshot() and replay.run_summary() == original.run_summary(),"replay final state, cooldowns, accounting match")
	var first := original.targets_snapshot()
	var second := replay.targets_snapshot()
	check(first.size() == second.size() and first.size() > 0,"replay real actors present")
	for index in first.size():
		var a: PolarPosition = first[index].position
		var b: PolarPosition = second[index].position
		first[index].position = [a.ring,a.wedge,a.radial_fraction,a.angular_fraction]
		second[index].position = [b.ring,b.wedge,b.radial_fraction,b.angular_fraction]
	check(first == second,"replay exact scalar actor state")
