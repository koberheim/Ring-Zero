class_name ProfileStore
extends RefCounted
## Between-run persistence. Mutations return candidates; callers save before commit.
## A pending run lost before settlement is abandoned, never resumed or rewarded.
const MAX_EXACT := 9007199254740991
const HISTORY_LIMIT := 128
const DEFAULT_PATH := "user://profile.json"
const KEYS := ["version", "currency", "unlocks", "upgrades", "settings", "tutorial_completed", "next_run_id", "pending_run_id", "settled_run_ids", "settled_run_amounts", "revision"]

static func defaults() -> Dictionary:
	return {"version":1, "revision":0, "currency":0, "unlocks":[], "upgrades":{}, "settings":{"fullscreen":false, "ui_scale":1.0, "reduced_motion":false, "effects":true}, "tutorial_completed":false, "next_run_id":1, "pending_run_id":"", "settled_run_ids":[], "settled_run_amounts":{}}

static func _fail(message: String) -> Dictionary:
	return {"ok":false, "profile":{}, "errors":PackedStringArray([message]), "recovered":false}

static func _ok(profile: Dictionary, recovered: bool = false) -> Dictionary:
	return {"ok":true, "profile":profile.duplicate(true), "errors":PackedStringArray(), "recovered":recovered}

static func _integer(value: Variant, low: int, high: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]: return false
	return is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

static func _id(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING or value.is_empty() or value.length() > 64: return false
	for character in value:
		if not character in "abcdefghijklmnopqrstuvwxyz0123456789_": return false
	return value[0] in "abcdefghijklmnopqrstuvwxyz"

static func _run_number(value: Variant) -> int:
	if typeof(value) != TYPE_STRING or value.is_empty() or value.length() > 16: return -1
	if not value.is_valid_int(): return -1
	var number: int = value.to_int()
	return number if number > 0 and number <= MAX_EXACT and str(number) == value else -1

static func validate(profile: Dictionary) -> Dictionary:
	# Version must precede field validation: future schemas naturally add fields.
	if profile.has("version") and not _integer(profile.version, 1, 1): return _fail("Unsupported profile version; preserve the file and use a compatible application")
	for key in profile:
		if key not in KEYS: return _fail("Unknown profile field: %s" % key)
	for key in KEYS:
		if key not in ["settled_run_amounts", "revision"] and not profile.has(key): return _fail("Missing profile field: %s" % key)
	if not _integer(profile.version, 1, 1): return _fail("Unsupported profile version; preserve the file and use a compatible application")
	if not _integer(profile.currency, 0, MAX_EXACT) or not _integer(profile.next_run_id, 1, MAX_EXACT): return _fail("Invalid currency or run counter")
	if typeof(profile.tutorial_completed) != TYPE_BOOL: return _fail("Invalid tutorial flag")
	if typeof(profile.unlocks) != TYPE_ARRAY or typeof(profile.upgrades) != TYPE_DICTIONARY or typeof(profile.settings) != TYPE_DICTIONARY or typeof(profile.settled_run_ids) != TYPE_ARRAY: return _fail("Invalid profile collection types")
	var result := profile.duplicate(true)
	if not _integer(result.get("revision", 0), 0, MAX_EXACT): return _fail("Invalid profile revision")
	result.revision = int(result.get("revision", 0))
	result.currency = int(result.currency)
	result.next_run_id = int(result.next_run_id)
	result.version = 1
	var seen := {}
	for item in result.unlocks:
		if not _id(item) or seen.has(item): return _fail("Invalid or duplicate unlock ID")
		seen[item] = true
	for key in result.upgrades:
		if not _id(key) or not _integer(result.upgrades[key], 1, 3): return _fail("Invalid upgrade ID or level")
		result.upgrades[key] = int(result.upgrades[key])
	var settings: Dictionary = result.settings
	if settings.size() != 4: return _fail("Invalid settings fields")
	for key in ["fullscreen", "reduced_motion", "effects"]:
		if not settings.has(key) or typeof(settings[key]) != TYPE_BOOL: return _fail("Invalid setting: %s" % key)
	if not settings.has("ui_scale") or typeof(settings.ui_scale) not in [TYPE_INT, TYPE_FLOAT] or settings.ui_scale not in [1.0, 1.15, 1.3]: return _fail("UI scale must be 1.0, 1.15 or 1.3")
	if typeof(result.pending_run_id) != TYPE_STRING: return _fail("Invalid pending run ID")
	var pending := _run_number(result.pending_run_id)
	if result.pending_run_id != "" and (pending < 1 or pending != result.next_run_id - 1): return _fail("Pending run must be the latest allocated ID")
	if result.settled_run_ids.size() > HISTORY_LIMIT: return _fail("Too many retained run receipts")
	seen.clear()
	var previous := 0
	for run_id in result.settled_run_ids:
		var number := _run_number(run_id)
		if number <= previous or number >= result.next_run_id or run_id == result.pending_run_id: return _fail("Invalid settled run receipt order or ID")
		previous = number
		seen[run_id] = true
	var amounts: Variant = result.get("settled_run_amounts", {})
	if typeof(amounts) != TYPE_DICTIONARY: return _fail("Invalid receipt amounts")
	for run_id in amounts:
		if not seen.has(run_id) or not _integer(amounts[run_id], 0, MAX_EXACT): return _fail("Invalid receipt amount or orphan receipt")
		amounts[run_id] = int(amounts[run_id])
	result.settled_run_amounts = amounts
	return _ok(result)

func begin_run(profile: Dictionary) -> Dictionary:
	var checked := validate(profile)
	if not checked.ok: return checked
	var next: Dictionary = checked.profile
	if next.next_run_id >= MAX_EXACT: return _fail("Run ID space exhausted")
	next.pending_run_id = str(next.next_run_id)
	next.next_run_id += 1
	var result := _ok(next)
	result.run_id = next.pending_run_id
	return result

func settle_run(profile: Dictionary, run_id: String, amount: int) -> Dictionary:
	var checked := validate(profile)
	if not checked.ok: return checked
	var next: Dictionary = checked.profile
	var number := _run_number(run_id)
	if number < 1 or number >= next.next_run_id or amount < 0 or amount > MAX_EXACT: return _fail("Invalid settlement ID or amount")
	if run_id != next.pending_run_id:
		if next.settled_run_amounts.has(run_id) and next.settled_run_amounts[run_id] != amount: return _fail("Settlement conflicts with retained receipt amount")
		# Old allocated IDs, including abandoned/pruned runs, can never earn again.
		return _ok(next)
	if amount > MAX_EXACT - next.currency: return _fail("Currency overflow")
	next.currency += amount
	next.pending_run_id = ""
	next.settled_run_ids.append(run_id)
	next.settled_run_amounts[run_id] = amount
	while next.settled_run_ids.size() > HISTORY_LIMIT:
		var removed: String = next.settled_run_ids.pop_front()
		next.settled_run_amounts.erase(removed)
	return _ok(next)

func purchase(profile: Dictionary, id: String, cost: int, upgrade_level: int = -1) -> Dictionary:
	var checked := validate(profile)
	if not checked.ok: return checked
	var next: Dictionary = checked.profile
	if not _id(id) or cost < 0 or cost > MAX_EXACT or upgrade_level < -1 or upgrade_level == 0 or upgrade_level > 3: return _fail("Invalid purchase ID, cost or level")
	if cost > next.currency: return _fail("Insufficient currency")
	if upgrade_level == -1:
		if id in next.unlocks: return _fail("Already unlocked")
		next.unlocks.append(id)
	else:
		if upgrade_level != next.upgrades.get(id, 0) + 1: return _fail("Upgrade must purchase exactly the next level")
		next.upgrades[id] = upgrade_level
	next.currency -= cost
	return _ok(next)

func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return _fail("Cannot read %s: %s" % [path, error_string(FileAccess.get_open_error())])
	if file.get_length() > 1048576:
		file.close()
		return _fail("Profile exceeds 1 MiB limit: %s" % path)
	var content := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error not in [OK, ERR_FILE_EOF]: return _fail("Cannot read profile bytes: %s" % path)
	var parser := JSON.new()
	if parser.parse(content) != OK or typeof(parser.data) != TYPE_DICTIONARY: return _fail("Invalid profile JSON: %s" % path)
	return validate(parser.data)

func load_profile(path: String = DEFAULT_PATH) -> Dictionary:
	if path.is_empty(): return _fail("Profile path is empty")
	if FileAccess.file_exists(path):
		var primary := _read(path)
		if primary.ok: return primary
		# Future versions are never replaced by an older backup.
		if "Unsupported profile version" in " ".join(primary.errors): return primary
		if FileAccess.file_exists(path + ".bak"):
			var backup := _read(path + ".bak")
			if backup.ok:
				backup.recovered = true
				return backup
		return primary
	if DirAccess.dir_exists_absolute(path): return _fail("Profile path is a directory: %s" % path)
	if FileAccess.file_exists(path + ".bak"):
		var backup := _read(path + ".bak")
		backup.recovered = backup.ok
		return backup
	# Orphan temporary files are uncommitted; do not guess that they earned rewards.
	if FileAccess.file_exists(path + ".tmp"): return _fail("Uncommitted temporary profile exists; recover explicitly: %s" % path)
	return _ok(defaults())

# Narrow I/O seam permits deterministic failure tests without real-user files.
func _write(path: String, content: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(content)
	file.flush()
	var error := file.get_error()
	file.close()
	return error

func _rename(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(from, to)

func _lock_owner(path: String) -> int:
	var metadata := path + ".lock/owner.json"
	if not FileAccess.file_exists(metadata): return -1
	var file := FileAccess.open(metadata, FileAccess.READ)
	if file == null: return -1
	if file.get_length() > 256:
		file.close()
		return -1
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) != TYPE_DICTIONARY or not _integer(data.get("pid"), 1, 2147483647): return -1
	return int(data.pid)

func _lock_failure(path: String) -> Dictionary:
	var owner := _lock_owner(path)
	var mode := "unknown" if owner < 1 else ("busy" if OS.is_process_running(owner) else "stale")
	var result := _fail("Profile lock %s: close other game instances before recovery; no process will be stopped" % mode)
	result.lock_recovery = mode
	result.lock_owner_pid = owner
	return result

func _acquire_lock(path: String) -> Dictionary:
	var lock_path := path + ".lock"
	if DirAccess.make_dir_absolute(lock_path) != OK:
		return _lock_failure(path) if DirAccess.dir_exists_absolute(lock_path) else _fail("Profile parent directory is unavailable: %s" % path)
	var file := FileAccess.open(lock_path.path_join("owner.json"), FileAccess.WRITE)
	if file == null:
		DirAccess.remove_absolute(lock_path)
		return _fail("Cannot record profile lock owner")
	file.store_string(JSON.stringify({"pid":OS.get_process_id()}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		_drop_lock(path)
		return _fail("Cannot persist profile lock owner")
	return _ok({})

func _drop_lock(path: String) -> Error:
	var metadata := path + ".lock/owner.json"
	if FileAccess.file_exists(metadata):
		var error := DirAccess.remove_absolute(metadata)
		if error != OK: return error
	return DirAccess.remove_absolute(path + ".lock")

func release_stale_lock(path: String = DEFAULT_PATH) -> Dictionary:
	if not DirAccess.dir_exists_absolute(path + ".lock"): return _ok({})
	var owner := _lock_owner(path)
	if owner < 1 or OS.is_process_running(owner): return _lock_failure(path)
	var error := _drop_lock(path)
	return _ok({}) if error == OK else _fail("Cannot release stale profile lock: %s" % error_string(error))

func force_release_unknown_lock(path: String = DEFAULT_PATH) -> Dictionary:
	# Separate explicit UI action after warning to close all game instances.
	if not DirAccess.dir_exists_absolute(path + ".lock"): return _ok({})
	if _lock_owner(path) > 0: return _lock_failure(path)
	var error := _drop_lock(path)
	return _ok({}) if error == OK else _fail("Cannot release unknown lock; unexpected directory contents are preserved")

func save_profile(profile: Dictionary, path: String = DEFAULT_PATH) -> Dictionary:
	var checked := validate(profile)
	if not checked.ok: return checked
	if path.is_empty() or DirAccess.dir_exists_absolute(path): return _fail("Invalid profile file path")
	var lock := _acquire_lock(path)
	if not lock.ok: return lock
	var result := _save_locked(checked.profile, path)
	_drop_lock(path)
	return result

func _save_locked(profile: Dictionary, path: String) -> Dictionary:
	var checked := _ok(profile)
	var primary_exists := FileAccess.file_exists(path)
	var current_revision := 0
	if primary_exists:
		var primary := _read(path)
		if not primary.ok: return _fail("Existing profile is unreadable or incompatible; preserve it and use recover_profile explicitly: %s" % path)
		current_revision = primary.profile.revision
	elif FileAccess.file_exists(path + ".bak"):
		var backup := _read(path + ".bak")
		if not backup.ok: return _fail("Existing backup is unreadable or incompatible; preserve it before choosing an explicit reset path")
		current_revision = backup.profile.revision
	if checked.profile.revision != current_revision: return _fail("Profile changed in another session; reload before retrying")
	if current_revision >= MAX_EXACT: return _fail("Profile revision exhausted")
	checked.profile.revision = current_revision + 1
	var temporary := path + ".tmp"
	var backup_path := path + ".bak"
	var error := _write(temporary, JSON.stringify(checked.profile))
	if error != OK: return _fail("Cannot write temporary profile: %s" % error_string(error))
	var verified := _read(temporary)
	if not verified.ok: return _fail("Temporary profile verification failed")
	if primary_exists:
		# Preserve a valid backup before replacing primary; failure leaves primary intact.
		if FileAccess.file_exists(backup_path):
			error = DirAccess.remove_absolute(backup_path)
			if error != OK: return _fail("Cannot replace backup: %s" % error_string(error))
		error = _rename(path, backup_path)
		if error != OK: return _fail("Cannot preserve previous profile: %s" % error_string(error))
	error = _rename(temporary, path)
	if error != OK:
		if primary_exists:
			var rollback := _rename(backup_path, path)
			if rollback != OK: return _fail("Profile commit and rollback failed; valid backup remains at %s" % backup_path)
		return _fail("Profile commit failed; prior profile preserved: %s" % error_string(error))
	return _ok(checked.profile)

func recover_profile(path: String = DEFAULT_PATH) -> Dictionary:
	if path.is_empty(): return _fail("Profile path is empty")
	var lock := _acquire_lock(path)
	if not lock.ok: return lock
	var result := _recover_locked(path)
	_drop_lock(path)
	return result

func _recover_locked(path: String) -> Dictionary:
	# Explicit recovery retains the unreadable primary for inspection.
	var loaded := load_profile(path)
	if not loaded.ok or not loaded.recovered: return _fail("No valid backup recovery is available")
	if FileAccess.file_exists(path):
		var quarantine := path + ".corrupt-" + str(Time.get_unix_time_from_system()).replace(".", "-")
		if FileAccess.file_exists(quarantine): return _fail("Recovery quarantine already exists")
		var error := _rename(path, quarantine)
		if error != OK: return _fail("Cannot preserve damaged primary for recovery")
	var saved := _save_locked(loaded.profile, path)
	if saved.ok: saved.recovered = true
	return saved
