extends SceneTree

class FailingStore extends ProfileStore:
	var fail_write := false
	var fail_commit := false
	func _write(path: String, content: String) -> Error:
		return ERR_CANT_CREATE if fail_write else super._write(path, content)
	func _rename(from: String, to: String) -> Error:
		return ERR_CANT_CREATE if fail_commit and from.ends_with(".tmp") else super._rename(from, to)

var checks := 0
var failures := 0
var fixture := ""

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	fixture = ProjectSettings.globalize_path("res://.godot/profile-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(fixture)
	_test_mutations()
	_test_disk()
	for file in DirAccess.get_files_at(fixture): DirAccess.remove_absolute(fixture.path_join(file))
	DirAccess.remove_absolute(fixture)
	print("Profile store: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_mutations() -> void:
	var store := ProfileStore.new()
	var initial := ProfileStore.defaults()
	var begun := store.begin_run(initial)
	check(begun.ok and begun.run_id == "1" and initial.pending_run_id == "", "begin immutable")
	var settled := store.settle_run(begun.profile, begun.run_id, 80)
	check(settled.ok and settled.profile.currency == 80 and begun.profile.currency == 0, "settle immutable credit")
	check(store.settle_run(settled.profile, "1", 80).profile == settled.profile, "duplicate same amount no-op")
	check(not store.settle_run(settled.profile, "1", 81).ok, "conflicting amount rejected")
	for id in ["0", "01", "+1", "-1", "2", "1.0", "9007199254740992"]:
		check(not store.settle_run(settled.profile, id, 0).ok, "invalid ID " + id)
	check(not store.settle_run(begun.profile, "1", -1).ok, "negative credit rejected")
	var overflow: Dictionary = begun.profile.duplicate(true)
	overflow.currency = ProfileStore.MAX_EXACT
	check(not store.settle_run(overflow, "1", 1).ok, "credit overflow rejected")
	var buy := store.purchase(settled.profile, "lance", 50)
	check(buy.ok and buy.profile.currency == 30 and settled.profile.unlocks.is_empty(), "purchase independent debit")
	check(not store.purchase(buy.profile, "lance", 0).ok, "duplicate unlock rejected")
	check(not store.purchase(buy.profile, "flare", 31).ok, "insufficient funds")
	check(not store.purchase(buy.profile, "bad/id", 1).ok, "ID validation")
	check(not store.purchase(buy.profile, "core_hp", 1, 2).ok, "cannot skip upgrade")
	var upgraded: Dictionary = buy.profile
	for level in range(1, 4):
		var result := store.purchase(upgraded, "core_hp", 1, level)
		check(result.ok, "next upgrade %d" % level)
		upgraded = result.profile
	check(not store.purchase(upgraded, "core_hp", 1, 4).ok, "level cap")
	var abandoned := store.begin_run(begun.profile)
	check(abandoned.run_id == "2" and store.settle_run(abandoned.profile, "1", 500).profile.currency == 0, "abandoned ID cannot earn")
	var history := ProfileStore.defaults()
	for number in range(132):
		var start := store.begin_run(history)
		history = store.settle_run(start.profile, start.run_id, 1).profile
	check(history.settled_run_ids.size() == 128 and history.settled_run_amounts.size() == 128, "bounded receipts")
	check(store.settle_run(history, "1", 999).profile.currency == 132, "pruned ID no new credit")
	var old_schema := history.duplicate(true)
	old_schema.erase("settled_run_amounts")
	check(ProfileStore.validate(old_schema).ok, "optional amount history compatible")
	for field in ["currency", "next_run_id"]:
		var invalid := initial.duplicate(true)
		invalid[field] = 0.5
		check(not ProfileStore.validate(invalid).ok, "fraction rejected " + field)
	var invalid := initial.duplicate(true)
	invalid.settings.ui_scale = INF
	check(not ProfileStore.validate(invalid).ok, "nonfinite settings rejected")
	invalid = initial.duplicate(true)
	invalid.settings.extra = true
	check(not ProfileStore.validate(invalid).ok, "unknown settings rejected")
	invalid = initial.duplicate(true)
	invalid.next_run_id = ProfileStore.MAX_EXACT
	check(not store.begin_run(invalid).ok, "counter exhausted")

func put(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _test_disk() -> void:
	var store := ProfileStore.new()
	var path := fixture.path_join("profile.json")
	var loaded := store.load_profile(path)
	check(loaded.ok and loaded.profile == ProfileStore.defaults() and not FileAccess.file_exists(path), "missing defaults without mutation")
	var saved := store.save_profile(loaded.profile, path)
	check(saved.ok and saved.profile.revision == 1, "initial save revision")
	check(not ProfileStore.new().save_profile(loaded.profile, path).ok, "independent stale writer rejected")
	var begun := store.begin_run(saved.profile)
	saved = store.save_profile(begun.profile, path)
	check(saved.ok and saved.profile.revision == 2, "durable begin")
	var disk := ProfileStore.new().load_profile(path)
	check(disk.ok and disk.profile.pending_run_id == "1", "independent reload")
	var settled := store.settle_run(disk.profile, "1", 25)
	saved = store.save_profile(settled.profile, path)
	check(saved.ok and saved.profile.revision == 3, "atomic settlement save")
	disk = ProfileStore.new().load_profile(path)
	check(store.settle_run(disk.profile, "1", 25).profile.currency == 25, "reload duplicate no credit")
	check(not store.settle_run(disk.profile, "1", 26).ok, "reload conflict rejected")
	var original := FileAccess.get_file_as_string(path)
	var failing := FailingStore.new()
	failing.fail_write = true
	check(not failing.save_profile(disk.profile, path).ok and FileAccess.get_file_as_string(path) == original, "write failure preserves primary/revision")
	failing.fail_write = false
	failing.fail_commit = true
	check(not failing.save_profile(disk.profile, path).ok and FileAccess.get_file_as_string(path) == original, "commit failure rollback revision unchanged")
	var invalid: Dictionary = disk.profile.duplicate(true)
	invalid.currency = -1
	var invalid_path := fixture.path_join("invalid.json")
	check(not store.save_profile(invalid, invalid_path).ok and not FileAccess.file_exists(invalid_path + ".tmp"), "validation before any write")
	check(store.save_profile(disk.profile, path).ok, "restore valid backup")
	DirAccess.make_dir_absolute(path + ".lock")
	check(not store.save_profile(store.load_profile(path).profile, path).ok, "existing writer lock blocks mutation")
	var locked_bytes := FileAccess.get_file_as_string(path)
	check(store.release_stale_lock(path).get("lock_recovery") == "unknown", "unknown owner not automatically released")
	check(store.force_release_unknown_lock(path).ok and FileAccess.get_file_as_string(path) == locked_bytes, "explicit unknown release preserves profile")
	DirAccess.make_dir_absolute(path + ".lock")
	put(path + ".lock/owner.json", JSON.stringify({"pid":OS.get_process_id()}))
	check(store.release_stale_lock(path).get("lock_recovery") == "busy", "live owner protected")
	check(not store.force_release_unknown_lock(path).ok, "force unknown cannot steal known live owner")
	put(path + ".lock/owner.json", JSON.stringify({"pid":2147483647}))
	check(store.release_stale_lock(path).ok and FileAccess.get_file_as_string(path) == locked_bytes, "dead owner safely released without profile changes")
	put(path, "{broken")
	var recovered := store.load_profile(path)
	check(recovered.ok and recovered.recovered and recovered.profile.currency == 25, "backup read reported")
	check(not store.save_profile(recovered.profile, path).ok and FileAccess.get_file_as_string(path) == "{broken", "no implicit corrupt overwrite")
	var repaired := store.recover_profile(path)
	check(repaired.ok and repaired.profile.revision == 4 and store.load_profile(path).profile.currency == 25, "explicit backup recovery revision increment")
	var future: Dictionary = disk.profile.duplicate(true)
	future.version = 2
	put(path, JSON.stringify(future))
	check(not store.load_profile(path).ok and not store.recover_profile(path).ok, "future version never downgraded from backup")
	check(not store.save_profile(disk.profile, path).ok, "future version never overwritten")
	future.extra_schema_field = {"new":true}
	put(path, JSON.stringify(future))
	var future_bytes := FileAccess.get_file_as_string(path)
	check(not store.load_profile(path).ok and not store.recover_profile(path).ok and not store.save_profile(disk.profile, path).ok and FileAccess.get_file_as_string(path) == future_bytes, "future added fields never permit backup downgrade")
	var no_backup := fixture.path_join("corrupt.json")
	put(no_backup, "no-json")
	check(not store.load_profile(no_backup).ok, "corrupt no backup rejected")
	var interrupted := fixture.path_join("interrupted.json")
	put(interrupted + ".bak", JSON.stringify(disk.profile))
	check(store.load_profile(interrupted).recovered, "missing primary valid backup recovery")
	var orphan := fixture.path_join("orphan.json")
	put(orphan + ".tmp", JSON.stringify(disk.profile))
	check(not store.load_profile(orphan).ok, "orphan uncommitted temp not rewarded")
	check(not store.save_profile(disk.profile, fixture.path_join("absent/sub/profile.json")).ok, "missing parent actionable failure")
