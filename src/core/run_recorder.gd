class_name RunRecorder
extends RefCounted
## Local reproduction diagnostics, never a save/resume mechanism.
const MAX_BYTES := 16 * 1024 * 1024
const MAX_RECORDS := 50000
const MAX_EXACT := 9007199254740991
var _trace := {"header":{}, "records":[]}
var _path := ""
var _bytes := 0
var _last_tick := 0
var _finished := false
var _failed := false

static func _failure(message: String) -> Dictionary:
	return {"ok":false, "errors":PackedStringArray([message])}

static func _success() -> Dictionary:
	return {"ok":true, "errors":PackedStringArray()}

static func _whole(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value >= 0 and value <= MAX_EXACT and float(value) == floor(float(value))

static func _safe(value: Variant, depth: int = 0) -> bool:
	if depth > 32: return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL: return true
		TYPE_INT: return value >= -MAX_EXACT and value <= MAX_EXACT
		TYPE_FLOAT: return is_finite(value)
		TYPE_STRING, TYPE_STRING_NAME: return value.length() <= 65536
		TYPE_ARRAY:
			if value.size() > MAX_RECORDS: return false
			for item in value:
				if not _safe(item, depth + 1): return false
			return true
		TYPE_DICTIONARY:
			if value.size() > 2048: return false
			for key in value:
				if typeof(key) not in [TYPE_STRING, TYPE_STRING_NAME] or not _safe(key, depth + 1) or not _safe(value[key], depth + 1): return false
			return true
	return false

static func fingerprint(value: Variant) -> String:
	return JSON.stringify(_canonical(value), "", true, true).sha256_text() if _safe(value) else ""

static func _canonical(value: Variant) -> Variant:
	# JSON parses integral numbers as doubles; content identity ignores that type change.
	if typeof(value) == TYPE_FLOAT and absf(value) <= MAX_EXACT and value == floor(value): return int(value)
	if typeof(value) == TYPE_STRING_NAME: return String(value)
	if typeof(value) == TYPE_DICTIONARY:
		var result := {}
		for key in value: result[String(key)] = _canonical(value[key])
		return result
	if typeof(value) == TYPE_ARRAY:
		var result: Array = []
		for item in value: result.append(_canonical(item))
		return result
	return value

static func build_info() -> Dictionary:
	var fallback := {"build_id":"development-unfrozen", "frozen":false}
	if not FileAccess.file_exists("res://data/build_info.json"): return fallback
	var file := FileAccess.open("res://data/build_info.json", FileAccess.READ)
	if file == null: return fallback
	if file.get_length() > 1048576:
		file.close()
		return fallback
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or not _safe(parsed) or typeof(parsed.get("build_id")) != TYPE_STRING: return fallback
	parsed.erase("source_inventory")
	# Editor runs remain development even if the last export left a manifest.
	if OS.has_feature("editor"):
		parsed["export_build_id"] = parsed.build_id
		parsed.build_id = "development-unfrozen"
		parsed["frozen"] = false
	return parsed

static func make_metadata(run_id: String, base_profile: Dictionary, effective_profile: Dictionary, choices: Dictionary, progress: Dictionary, practice: bool = false) -> Dictionary:
	var game_progress := {"unlocks":progress.get("unlocks", []), "upgrades":progress.get("upgrades", {}), "revision":progress.get("revision", 0)}.duplicate(true)
	return {"build":build_info(), "engine":Engine.get_version_info().string, "run_id":run_id, "profile_id":fingerprint(effective_profile), "base_profile":base_profile.duplicate(true), "effective_profile":effective_profile.duplicate(true), "choices":choices.duplicate(true), "progress":game_progress, "practice":practice, "seed":null, "randomness":"none"}

static func default_path(run_id: String) -> String:
	return "user://runs/run-%s-%d-%d.jsonl" % [run_id.validate_filename(), OS.get_process_id(), Time.get_ticks_usec()]

static func _allowed_path(path: String) -> bool:
	var absolute := ProjectSettings.globalize_path(path).simplify_path().replace("\\", "/")
	var user_root := ProjectSettings.globalize_path("user://runs/").simplify_path().replace("\\", "/").trim_suffix("/") + "/"
	var test_root := ProjectSettings.globalize_path("res://.godot/").simplify_path().replace("\\", "/").trim_suffix("/") + "/"
	return path.get_extension() == "jsonl" and (absolute.begins_with(user_root) or absolute.begins_with(test_root))

static func _header_valid(header: Dictionary) -> bool:
	if header.get("format") != 1 or header.get("type") != "header" or not header.get("metadata") is Dictionary: return false
	var meta: Dictionary = header.metadata
	return _safe(header) and typeof(meta.get("run_id")) == TYPE_STRING and not meta.run_id.is_empty() and meta.get("build") is Dictionary and typeof(meta.build.get("build_id")) == TYPE_STRING and typeof(meta.get("profile_id")) == TYPE_STRING and meta.get("effective_profile") is Dictionary and meta.profile_id == fingerprint(meta.effective_profile)

func start(path: String, metadata: Dictionary) -> Dictionary:
	if not _path.is_empty(): return _failure("Recorder already started")
	var header := {"type":"header", "format":1, "metadata":metadata.duplicate(true)}
	if not _allowed_path(path) or not _header_valid(header): return _failure("Invalid local trace path or metadata")
	if FileAccess.file_exists(path): return _failure("Trace already exists; choose a new path")
	var parent_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if parent_error != OK: return _failure("Cannot create trace directory: %s" % error_string(parent_error))
	var line := JSON.stringify(header, "", true, true) + "\n"
	if line.to_utf8_buffer().size() > MAX_BYTES: return _failure("Trace header exceeds byte limit")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return _failure("Cannot create trace: %s" % error_string(FileAccess.get_open_error()))
	file.store_string(line)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return _failure("Cannot persist trace header")
	_path = path
	_bytes = line.to_utf8_buffer().size()
	_trace.header = header
	return _success()

func append_command(tick: int, action: String, args: Dictionary, result_ok: bool, command_errors: Variant = []) -> Dictionary:
	if typeof(command_errors) not in [TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY]: return _recording_failure("Command errors must be strings")
	var copied_errors: Array = Array(command_errors)
	for item in copied_errors:
		if typeof(item) != TYPE_STRING: return _recording_failure("Command errors must be strings")
	if action.is_empty(): return _recording_failure("Command action is empty")
	return _append(tick, {"type":"command", "action":action, "args":args.duplicate(true), "ok":result_ok, "errors":copied_errors})

func marker(tick: int, event: String, data: Dictionary = {}) -> Dictionary:
	if event not in ["pause", "resume", "error", "abandon", "diagnostic"]: return _recording_failure("Unknown trace marker")
	return _append(tick, {"type":"marker", "event":event, "data":data.duplicate(true)})

func finish(tick: int, outcome: String, summary: Dictionary) -> Dictionary:
	if outcome not in ["victory", "defeat", "abandoned", "error", "practice"]: return _recording_failure("Invalid trace outcome")
	var result := _append(tick, {"type":"end", "outcome":outcome, "summary":summary.duplicate(true)})
	if result.ok: _finished = true
	return result

func _append(tick: int, row: Dictionary) -> Dictionary:
	if _path.is_empty() or _finished or _failed: return _failure("Trace is inactive, complete or failed; diagnostics are incomplete")
	if tick < _last_tick or tick < 0 or tick > MAX_EXACT or _trace.records.size() >= MAX_RECORDS: return _recording_failure("Trace tick/order or record limit exceeded")
	row.tick = tick
	row.sequence = _trace.records.size()
	if not _safe(row): return _recording_failure("Trace accepts only finite JSON game-state values")
	var line := JSON.stringify(row, "", true, true) + "\n"
	var added := line.to_utf8_buffer().size()
	if _bytes + added > MAX_BYTES:
		_failed = true
		return _failure("Trace byte limit reached; recording is incomplete")
	var result := _append_line(line)
	if not result.ok:
		_failed = true
		return result
	_trace.records.append(row)
	_bytes += added
	_last_tick = tick
	return _success()

func _recording_failure(message: String) -> Dictionary:
	if not _path.is_empty(): _failed = true
	return _failure(message)

func _append_line(line: String) -> Dictionary:
	var file := FileAccess.open(_path, FileAccess.READ_WRITE)
	if file == null: return _failure("Cannot append trace; recording is incomplete")
	if file.get_length() != _bytes:
		file.close()
		return _failure("Trace changed externally; recording is incomplete")
	file.seek_end()
	file.store_string(line)
	file.flush()
	var error := file.get_error()
	file.close()
	return _success() if error == OK else _failure("Trace write failed; recording is incomplete")

func snapshot() -> Dictionary:
	return _trace.duplicate(true)

static func load_trace(path: String) -> Dictionary:
	if not _allowed_path(path): return _failure("Invalid local trace path")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return _failure("Cannot read trace")
	if file.get_length() > MAX_BYTES:
		file.close()
		return _failure("Trace exceeds byte limit")
	var text := file.get_as_text()
	file.close()
	if not text.ends_with("\n"): return _failure("Truncated trace: last line was not committed")
	var lines := text.trim_suffix("\n").split("\n")
	if lines.size() < 1 or lines.size() > MAX_RECORDS + 1: return _failure("Invalid trace length")
	var header: Variant = JSON.parse_string(lines[0])
	if typeof(header) != TYPE_DICTIONARY or not _header_valid(header): return _failure("Invalid trace header")
	var records: Array[Dictionary] = []
	var last_tick := 0
	var complete := false
	for index in range(1, lines.size()):
		var row: Variant = JSON.parse_string(lines[index])
		if complete or typeof(row) != TYPE_DICTIONARY or not _safe(row) or not _whole(row.get("tick")) or not _whole(row.get("sequence")) or row.sequence != index - 1 or row.tick < last_tick: return _failure("Invalid trace order or record")
		if row.get("type") == "command":
			if typeof(row.get("action")) != TYPE_STRING or row.action.is_empty() or not row.get("args") is Dictionary or typeof(row.get("ok")) != TYPE_BOOL or not row.get("errors") is Array: return _failure("Invalid command record")
			for item in row.errors:
				if typeof(item) != TYPE_STRING: return _failure("Invalid command error element")
		elif row.get("type") == "marker":
			if row.get("event") not in ["pause", "resume", "error", "abandon", "diagnostic"] or not row.get("data") is Dictionary: return _failure("Invalid marker")
		elif row.get("type") == "end":
			if row.get("outcome") not in ["victory", "defeat", "abandoned", "error", "practice"] or not row.get("summary") is Dictionary: return _failure("Invalid end record")
			complete = true
		else: return _failure("Unknown record type")
		row.tick = int(row.tick)
		row.sequence = int(row.sequence)
		last_tick = row.tick
		records.append(row)
	return {"ok":true, "trace":{"header":header, "records":records}, "complete":complete, "errors":PackedStringArray()}
