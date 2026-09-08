extends SceneTree

const Profile = preload("res://src/gameplay/balance_profile.gd")
const FIXTURES := "res://.godot/balance_test_fixtures"
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	_run()
	print("Balance profile: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)


func _reject(result: Dictionary, expected: String) -> void:
	_check(result.keys().size() == 3 and result.has("ok") and result.has("profile") and result.has("errors"), "Result contract")
	_check(result.ok == false and result.profile == null and result.errors is PackedStringArray, "Invalid data must return errors and no profile")
	_check(expected in "\n".join(result.errors), "Expected error containing: " + expected)


func _write(name: String, contents: String) -> String:
	var path := FIXTURES.path_join(name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "Can write fixture: " + path)
	if file != null:
		file.store_string(contents)
		file.close()
	return path


func _run() -> void:
	var loaded: Dictionary = Profile.load_json("res://data/balance/testing.json")
	_check(loaded.ok and loaded.profile is Profile and loaded.errors is PackedStringArray and loaded.errors.is_empty(), "Shipped JSON loads successfully")
	if not loaded.ok:
		return
	var profile = loaded.profile
	_pressure_checks(profile)
	_capacity_checks(profile)
	_wall_multiplier_checks(profile)
	_tunneler_data_checks(profile)
	_assimilation_data_checks(profile)
	_ability_data_checks(profile)
	_terrain_data_checks(profile)
	var baseline: Dictionary = profile.snapshot()
	_check(profile.value("mass_driver.arc_degrees") == 360, "Mass Driver shipped full circle arc")
	var missing_arc := baseline.duplicate(true)
	missing_arc.mass_driver.erase("arc_degrees")
	_reject(Profile.from_dict(missing_arc), "mass_driver.arc_degrees: required")
	_reject(profile.with_overrides({"mass_driver": {"arc_degrees": 0}}), "mass_driver.arc_degrees: must be > 0 and <= 360")
	_reject(profile.with_overrides({"mass_driver": {"arc_degrees": 361}}), "mass_driver.arc_degrees: must be > 0 and <= 360")
	_check(typeof(profile.value("economy.flak_cost")) == TYPE_INT, "JSON integer-valued floats normalize to integers")
	_check(profile.value("missing") == null and profile.value("economy.missing") == null and profile.value("economy.flak_cost.child") == null and profile.value("") == null, "Unknown paths return null")
	var raw: Dictionary = baseline.duplicate(true)
	var copied: Dictionary = Profile.from_dict(raw)
	raw.economy.flak_cost += 7
	_check(copied.profile.value("economy.flak_cost") == baseline.economy.flak_cost, "Factory deep copies input")
	var snapshot: Dictionary = profile.snapshot()
	snapshot.health.core_hp += 17
	var section: Dictionary = profile.value("health")
	section.core_hp += 31
	_check(profile.value("health.core_hp") == baseline.health.core_hp, "Snapshots and object lookups cannot mutate profile")
	var overrides := {"economy": {"flak_cost": 37}, "health": {"core_hp": 321.5}}
	var changed: Dictionary = profile.with_overrides(overrides)
	_check(changed.ok and changed.profile != profile, "Overrides create a new profile")
	_check(changed.profile.value("economy.flak_cost") == 37 and changed.profile.value("health.core_hp") == 321.5, "Economy and HP can be tuned without code changes")
	_check(changed.profile.value("economy.wall_cost") == baseline.economy.wall_cost, "Partial nested overrides preserve siblings")
	overrides.economy.flak_cost = 99
	_check(changed.profile.value("economy.flak_cost") == 37 and profile.snapshot() == baseline, "Overrides isolate input and original")
	_check(changed.profile.value("starting_test_setup.energy_in_flak_purchases") == baseline.starting_test_setup.energy_in_flak_purchases, "Starting grant remains a purchase count when Flak cost changes")
	_check(not changed.profile.snapshot().starting_test_setup.has("starting_energy"), "No duplicate starting-energy literal")
	var flexible: Dictionary = profile.with_overrides({
		"economy": {"mass_driver_cost": 0, "flak_cost": 1000},
		"flak": {"damage": 0, "arc_degrees": 360},
		"scaling": {"claim_cost_ring_exponent": -3.5, "wedge_hp_ring_exponent": 9.25, "power_ring_exponent": 0},
		"starting_test_setup": {"owned_ring_count": 0},
	})
	_check(flexible.ok, "Tuning permits zero costs/damage/counts, changed price relationships, and arbitrary finite exponents")
	var normalized: Dictionary = profile.with_overrides({"schema_version": 1.0, "flak": {"max_targets": 3.0}})
	_check(normalized.ok and typeof(normalized.profile.value("schema_version")) == TYPE_INT and typeof(normalized.profile.value("flak.max_targets")) == TYPE_INT, "Whole floats normalize for all integer rules")
	for missing in ["health", "economy.flak_cost"]:
		var incomplete: Dictionary = baseline.duplicate(true)
		if missing == "health":
			incomplete.erase("health")
		else:
			incomplete.economy.erase("flak_cost")
		_reject(Profile.from_dict(incomplete), missing + ": required")
	for invalid in [
		[{"starting_test_setup": {"flak_wedge": 0}}, "starting_test_setup.flak_wedge: must be an integer from 1 to 12"],
		[{"structure": {"collapse_broken_wedges": 13}}, "structure.collapse_broken_wedges: must be an integer from 1 to 12"],
		[{"extra": 1}, "extra: unknown"],
		[{"flak": {"extra": 1}}, "flak.extra: unknown"],
		[{"health": []}, "health: must be an object"],
		[{"health": null}, "health: must be an object"],
		[{"schema_version": 2}, "schema_version: unsupported"],
		[{"schema_version": 1.5}, "schema_version: must be an integer"],
		[{"economy": {"kill_energy": true}}, "economy.kill_energy: must be a number"],
		[{"flak": {"damage": "2"}}, "flak.damage: must be a number"],
		[{"economy": {"wall_cost": -1}}, "economy.wall_cost: must be >= 0"],
		[{"economy": {"wall_cost": 1.5}}, "economy.wall_cost: must be an integer"],
		[{"economy": {"wall_cost": 1e30}}, "economy.wall_cost: integer is outside"],
		[{"scaling": {"slots_per_wedge_per_ring": 0}}, "scaling.slots_per_wedge_per_ring: must be an integer >= 1"],
		[{"flak": {"max_targets": 0}}, "flak.max_targets: must be an integer >= 1"],
		[{"flak": {"damage": -0.1}}, "flak.damage: must be >= 0"],
		[{"mass_driver": {"cycle_seconds": 0}}, "mass_driver.cycle_seconds: must be > 0"],
		[{"flak": {"range_ring_widths": -1}}, "flak.range_ring_widths: must be > 0"],
		[{"health": {"wall_hp": 0}}, "health.wall_hp: must be > 0"],
		[{"flak": {"arc_degrees": 0}}, "flak.arc_degrees: must be > 0 and <= 360"],
		[{"flak": {"arc_degrees": 361}}, "flak.arc_degrees: must be > 0 and <= 360"],
		[{"starting_test_setup": {"flak_count": -1}}, "starting_test_setup.flak_count: must be >= 0"],
		[{"scaling": {"power_ring_exponent": INF}}, "scaling.power_ring_exponent: must be finite"],
		[{"health": {"core_hp": -INF}}, "health.core_hp: must be finite"],
		[{"standard_machine": {"damage_per_second": NAN}}, "standard_machine.damage_per_second: must be finite"],
	]:
		_reject(profile.with_overrides(invalid[0]), invalid[1])
	_reject(profile.with_overrides({"economy": {"flak_cost": 88}, "health": {"core_hp": 0}}), "health.core_hp")
	_check(profile.snapshot() == baseline, "All failed overrides leave original untouched, including mixed valid/invalid updates")
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FIXTURES)) == OK, "Create workspace fixture directory")
	var alternate: Dictionary = baseline.duplicate(true)
	alternate.economy.flak_cost = 43
	alternate.health.core_hp = 432.5
	var alternate_path := _write("alternate.json", JSON.stringify(alternate))
	var alternate_result: Dictionary = Profile.load_json(ProjectSettings.globalize_path(alternate_path))
	_check(alternate_result.ok and alternate_result.profile.value("economy.flak_cost") == 43 and alternate_result.profile.value("health.core_hp") == 432.5, "Alternate filesystem JSON tunes economy and HP")
	_reject(Profile.load_json(_write("malformed.json", "{broken")), "malformed JSON")
	_reject(Profile.load_json(_write("array.json", "[]")), "root must be an object")
	_reject(Profile.load_json(_write("null.json", "null")), "root must be an object")
	_reject(Profile.load_json(FIXTURES.path_join("absent-profile.json")), "cannot read file")
	_reject(Profile.load_json(_write("invalid.json", "{}")), "schema_version: required")
	for fixture in ["alternate.json", "malformed.json", "array.json", "null.json", "invalid.json"]:
		_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURES.path_join(fixture))) == OK, "Remove fixture: " + fixture)


func _pressure_checks(profile: BalanceProfile) -> void:
	var baseline := profile.snapshot()
	_check(profile.value("pressure") == {"max_active_machines": 1000, "spawn_per_second": 2.0, "spawn_delay_seconds": 10.0, "speed_ring_widths_per_second": 1.0, "spawn_offset_ring_widths": 2.0, "stat_increase_per_minute": 0.1}, "Approved D-017 testing pressure values")
	_check(profile.value("schema_version") == 1, "Internal pressure schema expansion retains version 1")
	var missing := baseline.duplicate(true)
	missing.erase("pressure")
	_reject(Profile.from_dict(missing), "pressure: required")
	_reject(profile.with_overrides({"pressure": []}), "pressure: must be an object")
	_reject(profile.with_overrides({"pressure": {"cap": 100}}), "pressure.cap: unknown")
	for field in ["spawn_per_second", "spawn_delay_seconds", "speed_ring_widths_per_second", "spawn_offset_ring_widths", "stat_increase_per_minute"]:
		missing = baseline.duplicate(true)
		missing.pressure.erase(field)
		_reject(Profile.from_dict(missing), "pressure.%s: required" % field)
		var positive: bool = field in ["speed_ring_widths_per_second", "spawn_offset_ring_widths"]
		_reject(profile.with_overrides({"pressure": {field: -0.1}}), "pressure.%s: must be %s" % [field, "> 0" if positive else ">= 0"])
		for invalid in [INF, -INF, NAN]:
			_reject(profile.with_overrides({"pressure": {field: invalid}}), "pressure.%s: must be finite" % field)
		for invalid in [true, "2", null, []]:
			_reject(profile.with_overrides({"pressure": {field: invalid}}), "pressure.%s: must be a number" % field)
		if positive:
			_reject(profile.with_overrides({"pressure": {field: 0}}), "pressure.%s: must be > 0" % field)
	var overrides := {"pressure": {"max_active_machines": 1000, "spawn_per_second": 0, "spawn_delay_seconds": 0, "stat_increase_per_minute": 0, "speed_ring_widths_per_second": 0.25, "spawn_offset_ring_widths": 3.5}}
	var changed := profile.with_overrides(overrides)
	_check(changed.ok and changed.profile.value("pressure") == overrides.pressure, "Zero spawn and escalation valid; fractional speed and offset tunable")
	overrides.pressure.speed_ring_widths_per_second = 9
	_check(changed.profile.value("pressure.speed_ring_widths_per_second") == 0.25, "Pressure override source isolated")
	var partial := profile.with_overrides({"pressure": {"spawn_per_second": 12.5}})
	_check(partial.ok and partial.profile.value("pressure.spawn_per_second") == 12.5 and partial.profile.value("pressure.stat_increase_per_minute") == 0.1, "Partial pressure override preserves siblings")
	var section: Dictionary = profile.value("pressure")
	section.spawn_per_second = 999
	var snapshot := profile.snapshot()
	snapshot.pressure.stat_increase_per_minute = 999
	_check(profile.snapshot() == baseline, "Pressure snapshots and sections isolated; failed overrides preserve source")
	var parsed := Profile.from_dict(JSON.parse_string(JSON.stringify(changed.profile.snapshot())))
	_check(parsed.ok and parsed.profile.value("pressure.spawn_per_second") == 0 and parsed.profile.value("pressure.stat_increase_per_minute") == 0 and parsed.profile.value("pressure.speed_ring_widths_per_second") == 0.25 and parsed.profile.value("pressure.spawn_offset_ring_widths") == 3.5 and typeof(parsed.profile.value("economy.kill_energy")) == TYPE_INT, "Pressure JSON roundtrip preserves zero/fractional values and existing integer normalization")


func _capacity_checks(profile: BalanceProfile) -> void:
	_check(profile.value("pressure.max_active_machines") == 1000 and typeof(profile.value("pressure.max_active_machines")) == TYPE_INT, "Approved prototype capacity normalized integer")
	var missing := profile.snapshot()
	missing.pressure.erase("max_active_machines")
	_reject(Profile.from_dict(missing), "pressure.max_active_machines: required")
	for value in [0, -1]:
		_reject(profile.with_overrides({"pressure": {"max_active_machines": value}}), "pressure.max_active_machines: must be an integer >= 1")
	for value in [true, "1000", null]:
		_reject(profile.with_overrides({"pressure": {"max_active_machines": value}}), "pressure.max_active_machines: must be a number")
	_reject(profile.with_overrides({"pressure": {"max_active_machines": 2.5}}), "pressure.max_active_machines: must be an integer")
	_reject(profile.with_overrides({"pressure": {"max_active_machines": INF}}), "pressure.max_active_machines: must be finite")
	var tuned := profile.with_overrides({"pressure": {"max_active_machines": 2.0}})
	_check(tuned.ok and tuned.profile.value("pressure.max_active_machines") == 2 and typeof(tuned.profile.value("pressure.max_active_machines")) == TYPE_INT and profile.value("pressure.max_active_machines") == 1000, "Capacity override normalization and isolation")

func _wall_multiplier_checks(profile: BalanceProfile) -> void:
	_check(profile.value("standard_machine.wall_damage_multiplier") == 0.25, "Approved quarter-DPS wall testing multiplier")
	var missing := profile.snapshot()
	missing.standard_machine.erase("wall_damage_multiplier")
	_reject(Profile.from_dict(missing), "standard_machine.wall_damage_multiplier: required")
	for value in [-0.01, 1.01]:
		_reject(profile.with_overrides({"standard_machine": {"wall_damage_multiplier": value}}), "standard_machine.wall_damage_multiplier: must be between 0 and 1 inclusive")
	for value in [true, "0.25", null]:
		_reject(profile.with_overrides({"standard_machine": {"wall_damage_multiplier": value}}), "standard_machine.wall_damage_multiplier: must be a number")
	for value in [INF, NAN]:
		_reject(profile.with_overrides({"standard_machine": {"wall_damage_multiplier": value}}), "standard_machine.wall_damage_multiplier: must be finite")
	for value in [0, 1, 0.125]:
		var result := profile.with_overrides({"standard_machine": {"wall_damage_multiplier": value}})
		_check(result.ok and result.profile.value("standard_machine.wall_damage_multiplier") == value and profile.value("standard_machine.wall_damage_multiplier") == 0.25, "Multiplier inclusive tuning bounds and input isolation")


func _tunneler_data_checks(profile: BalanceProfile) -> void:
	_check(profile.value("health.tunneler_hp") == 20 and profile.value("tunneler") == {"first_arrival_seconds": 60.0, "arrival_interval_seconds": 30.0, "burrow_seconds": 2.0}, "Approved testing Tunneler data")
	var missing := profile.snapshot()
	missing.erase("tunneler")
	_reject(Profile.from_dict(missing), "tunneler: required")
	for path in ["health.tunneler_hp", "tunneler.first_arrival_seconds", "tunneler.arrival_interval_seconds", "tunneler.burrow_seconds"]:
		var parts: PackedStringArray = path.split(".")
		missing = profile.snapshot()
		missing[parts[0]].erase(parts[1])
		_reject(Profile.from_dict(missing), path + ": required")
		for number in [0, -1]:
			_reject(profile.with_overrides({parts[0]: {parts[1]: number}}), path + ": must be > 0")
		for number in [INF, NAN]:
			_reject(profile.with_overrides({parts[0]: {parts[1]: number}}), path + ": must be finite")
		for number in [true, "2", null]:
			_reject(profile.with_overrides({parts[0]: {parts[1]: number}}), path + ": must be a number")
	_reject(profile.with_overrides({"tunneler": {"cap": 20}}), "tunneler.cap: unknown")
	_reject(profile.with_overrides({"tunneler": []}), "tunneler: must be an object")
	var tuned := profile.with_overrides({"health": {"tunneler_hp": 12.5}, "tunneler": {"first_arrival_seconds": 0.5, "arrival_interval_seconds": 0.75, "burrow_seconds": 1.25}})
	_check(tuned.ok and tuned.profile.value("health.tunneler_hp") == 12.5 and tuned.profile.value("tunneler.burrow_seconds") == 1.25 and profile.value("tunneler.burrow_seconds") == 2, "Tunneler fractional overrides isolate source")


func _assimilation_data_checks(profile: BalanceProfile) -> void:
	_check(profile.value("assimilation") == {"bonus_per_stack": 0.05, "max_stacks": 10, "stack_seconds": 15.0}, "T043 default assimilation values unchanged")
	var missing := profile.snapshot()
	missing.erase("assimilation")
	_check(not Profile.from_dict(missing).ok, "T043 assimilation section required")
	for key in ["bonus_per_stack", "max_stacks", "stack_seconds"]:
		missing = profile.snapshot()
		missing.assimilation.erase(key)
		_check(not Profile.from_dict(missing).ok, "T043 required assimilation field " + key)
		for invalid in [true, "1", null, INF, NAN, -1]:
			_check(not profile.with_overrides({"assimilation": {key: invalid}}).ok, "T043 invalid assimilation field " + key)
	_check(not profile.with_overrides({"assimilation": {"max_stacks": 0}}).ok and not profile.with_overrides({"assimilation": {"max_stacks": 1.5}}).ok and not profile.with_overrides({"assimilation": {"stack_seconds": 0}}).ok, "T043 positive count/duration constraints")
	_check(not profile.with_overrides({"assimilation": {"extra": 1}}).ok and not profile.with_overrides({"assimilation": []}).ok, "T043 strict assimilation schema")
	var tuned := profile.with_overrides({"assimilation": {"bonus_per_stack": 0, "max_stacks": 2.0, "stack_seconds": 0.5}})
	_check(tuned.ok and typeof(tuned.profile.value("assimilation.max_stacks")) == TYPE_INT and profile.value("assimilation.max_stacks") == 10, "T043 zero bonus and normalized independent overrides")

func _ability_data_checks(profile: BalanceProfile) -> void:
	for kind in ["focused_flare", "emp_burst"]:
		var raw := profile.snapshot()
		raw.erase(kind)
		_check(not Profile.from_dict(raw).ok, "T048 required ability section")
		for field in profile.value(kind):
			raw = profile.snapshot()
			raw[kind].erase(field)
			_check(not Profile.from_dict(raw).ok, "T048 required ability field")
			for invalid in [INF, NAN, true, null, "1", -1]:
				_check(not profile.with_overrides({kind: {field: invalid}}).ok, "T048 strict numeric ability field")
			_check(profile.with_overrides({kind: {field: 0}}).ok == (field == "damage"), "T048 zero allowed only for damage")
		_check(not profile.with_overrides({kind: {"extra": 1}}).ok, "T048 unknown ability field rejected")
	_check(not profile.with_overrides({"focused_flare": {"arc_degrees": 361}}).ok, "T048 arc upper bound")

func _terrain_data_checks(profile: BalanceProfile) -> void:
	for kind in ["tractor_lane", "occlusion_screen"]:
		var raw := profile.snapshot()
		raw.erase(kind)
		_check(not Profile.from_dict(raw).ok, "T050 required terrain section")
		for field in profile.value(kind):
			raw = profile.snapshot()
			raw[kind].erase(field)
			_check(not Profile.from_dict(raw).ok, "T050 required terrain field")
			for invalid in [0, -1, INF, NAN, true, null, "1"]:
				_check(not profile.with_overrides({kind: {field: invalid}}).ok, "T050 strict positive terrain field")
	for path in ["path_cost_multiplier", "speed_multiplier"]:
		var kind := "tractor_lane" if path == "path_cost_multiplier" else "occlusion_screen"
		_check(not profile.with_overrides({kind: {path: 1.01}}).ok and profile.with_overrides({kind: {path: 1.0}}).ok, "T050 multipliers positive through one")
	_check(not profile.with_overrides({"occlusion_screen": {"shadow_rings": 1.5}}).ok, "T050 shadow span is whole")
	for kind in ["debris_field", "tractor_lane", "occlusion_screen"]:
		var raw := profile.snapshot()
		raw.economy.erase(kind + "_cost")
		_check(not Profile.from_dict(raw).ok and not profile.with_overrides({"economy": {kind + "_cost": -1}}).ok and profile.with_overrides({"economy": {kind + "_cost": 0}}).ok, "T050 required nonnegative whole terrain cost")
