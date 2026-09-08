class_name BalanceProfile
extends RefCounted
## Validated balance data. Factories return {ok, profile, errors}; no fallback data.

const SCHEMA: Dictionary = {
	"schema_version": "version",
	"tractor_lane": {"path_cost_multiplier": "positive_unit_interval"},
	"occlusion_screen": {"shadow_rings": "positive_integer", "speed_multiplier": "positive_unit_interval"},
	"focused_flare": {"damage": "nonnegative", "cooldown_seconds": "positive", "range_ring_widths": "positive", "arc_degrees": "arc"},
	"emp_burst": {"damage": "nonnegative", "cooldown_seconds": "positive", "radius_ring_widths": "positive", "stun_seconds": "positive"},
	"assimilation": {"bonus_per_stack": "nonnegative", "max_stacks": "positive_integer", "stack_seconds": "positive"},
	"tunneler": {
		"first_arrival_seconds": "positive",
		"arrival_interval_seconds": "positive",
		"burrow_seconds": "positive",
	},
	"foundry": {
		"first_arrival_seconds": "positive",
		"arrival_interval_seconds": "positive",
		"hp_multiplier": "positive",
		"damage_multiplier": "positive",
		"speed_multiplier": "positive_unit_interval",
	},
	"transfer": {
		"first_arrival_seconds": "positive",
		"arrival_interval_seconds": "positive",
	},
	"pressure": {
		"max_active_machines": "positive_integer",
		"spawn_per_second": "nonnegative",
		"spawn_delay_seconds": "nonnegative",
		"speed_ring_widths_per_second": "positive",
		"spawn_offset_ring_widths": "positive",
		"stat_increase_per_minute": "nonnegative",
	},
	"economy": {
		"kill_energy": "nonnegative_integer",
		"ring_plate_base_cost": "nonnegative_integer",
		"wall_cost": "nonnegative_integer",
		"debris_field_cost": "nonnegative_integer",
		"tractor_lane_cost": "nonnegative_integer",
		"occlusion_screen_cost": "nonnegative_integer",
		"flak_cost": "nonnegative_integer",
		"mass_driver_cost": "nonnegative_integer",
		"reclaim_discount": "unit_interval",
		"repair_discount": "positive_unit_interval",
		"armor_plating_cost": "nonnegative_integer",
		"repair_node_cost": "nonnegative_integer",
		"emp_node_cost": "nonnegative_integer",
		"lance_emitter_cost": "nonnegative_integer",
		"point_defense_cost": "nonnegative_integer",
		"rebuild_relay_cost": "nonnegative_integer",
	},
	"scaling": {
		"slots_per_wedge_per_ring": "positive_integer",
		"claim_cost_ring_exponent": "finite",
		"wedge_hp_ring_exponent": "finite",
		"power_ring_exponent": "finite",
	},
	"flak": {
		"damage": "nonnegative",
		"cycle_seconds": "positive",
		"range_ring_widths": "positive",
		"arc_degrees": "arc",
		"max_targets": "positive_integer",
		"power_demand": "nonnegative",
	},
	"mass_driver": {
		"damage": "nonnegative",
		"cycle_seconds": "positive",
		"range_ring_widths": "positive",
		"arc_degrees": "arc",
		"max_targets": "positive_integer",
		"power_demand": "nonnegative",
	},
	"emp_node": {
		"damage": "nonnegative",
		"cycle_seconds": "positive",
		"range_ring_widths": "positive",
		"arc_degrees": "arc",
		"max_targets": "positive_integer",
		"power_demand": "nonnegative",
		"stun_seconds": "positive",
	},
	"lance_emitter": {
		"damage": "nonnegative",
		"cycle_seconds": "positive",
		"range_ring_widths": "positive",
		"arc_degrees": "arc",
		"max_targets": "positive_integer",
		"power_demand": "nonnegative",
	},
	"point_defense": {
		"damage": "nonnegative",
		"cycle_seconds": "positive",
		"range_ring_widths": "positive",
		"arc_degrees": "arc",
		"max_targets": "positive_integer",
		"power_demand": "nonnegative",
	},
	"power": {
		"base_output": "positive",
		"brownout_fraction": "unit_interval",
	},
	"health": {
		"wedge_base_hp": "positive",
		"core_hp": "positive",
		"wall_hp": "positive",
		"standard_machine_hp": "positive",
		"tunneler_hp": "positive",
	},
	"standard_machine": {"damage_per_second": "nonnegative", "wall_damage_multiplier": "unit_interval"},
	"structure": {
		"collapse_broken_wedges": "wedge_integer",
		"armor_plating_hp_bonus": "positive",
		"armor_plating_max_stacks": "positive_integer",
		"repair_node_heal_fraction_per_second": "positive",
		"relay_max_hp": "positive",
	},
	"sapper": {
		"first_arrival_seconds": "positive",
		"arrival_interval_seconds": "positive",
	},
	"breacher": {
		"first_arrival_seconds": "positive",
		"arrival_interval_seconds": "positive",
	},
	"assembler": {
		"first_arrival_seconds": "positive",
		"interval_seconds": "positive",
		"hp_multiplier": "positive",
		"damage_multiplier": "positive",
		"speed_multiplier": "positive_unit_interval",
		"growth_damage_per_stack": "nonnegative",
		"growth_hp_per_stack": "nonnegative",
	},
	"starting_test_setup": {
		"owned_ring_count": "nonnegative_integer",
		"flak_count": "nonnegative_integer",
		"energy_in_flak_purchases": "nonnegative_integer",
		"flak_wedge": "wedge_integer",
	},
}

var _data: Dictionary = {}


static func from_dict(raw: Dictionary) -> Dictionary:
	var candidate: Dictionary = raw.duplicate(true)
	var errors := PackedStringArray()
	_validate_object(candidate, SCHEMA, "", errors)
	if not errors.is_empty():
		return _failure(errors)
	var profile := BalanceProfile.new()
	profile._data = candidate
	return {"ok": true, "profile": profile, "errors": errors}


static func load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure(PackedStringArray([
			"%s: cannot read file (%s)" % [path, error_string(FileAccess.get_open_error())]
		]))
	var source := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return _failure(PackedStringArray([
			"%s: cannot read file contents (%s)" % [path, error_string(read_error)]
		]))
	var json := JSON.new()
	if json.parse(source) != OK:
		return _failure(PackedStringArray([
			"%s: malformed JSON at line %d: %s" % [path, json.get_error_line(), json.get_error_message()]
		]))
	if not json.data is Dictionary:
		return _failure(PackedStringArray(["%s: root must be an object" % path]))
	return from_dict(json.data)


func with_overrides(overrides: Dictionary) -> Dictionary:
	var candidate: Dictionary = _data.duplicate(true)
	_merge(candidate, overrides)
	return from_dict(candidate)


func snapshot() -> Dictionary:
	return _data.duplicate(true)


func value(path: String) -> Variant:
	var current: Variant = _data
	for part in path.split("."):
		if not current is Dictionary or not current.has(part):
			return null
		current = current[part]
	if current is Dictionary or current is Array:
		return current.duplicate(true)
	return current


static func _failure(errors: PackedStringArray) -> Dictionary:
	return {"ok": false, "profile": null, "errors": errors}


static func _merge(target: Dictionary, overrides: Dictionary) -> void:
	for key in overrides:
		if overrides[key] is Dictionary and target.get(key) is Dictionary:
			_merge(target[key], overrides[key])
		else:
			target[key] = overrides[key]


static func _validate_object(data: Dictionary, schema: Dictionary, prefix: String, errors: PackedStringArray) -> void:
	for key in data:
		if not schema.has(key):
			errors.append("%s%s: unknown key" % [prefix, str(key)])
	for key in schema:
		var path: String = prefix + key
		if not data.has(key):
			errors.append("%s: required field is missing" % path)
			continue
		if schema[key] is Dictionary:
			if not data[key] is Dictionary:
				errors.append("%s: must be an object" % path)
			else:
				_validate_object(data[key], schema[key], path + ".", errors)
			continue
		var rule: String = schema[key]
		var number: Variant = data[key]
		if typeof(number) != TYPE_INT and typeof(number) != TYPE_FLOAT:
			errors.append("%s: must be a number (booleans are not numbers)" % path)
			continue
		if not is_finite(float(number)):
			errors.append("%s: must be finite" % path)
			continue
		if rule in ["version", "nonnegative_integer", "positive_integer", "wedge_integer"]:
			if typeof(number) == TYPE_FLOAT:
				if floor(number) != number:
					errors.append("%s: must be an integer" % path)
					continue
				# Conversion must remain exact and fit Godot's signed 64-bit integer.
				if number < -9223372036854775808.0 or number >= 9223372036854775808.0:
					errors.append("%s: integer is outside the supported 64-bit range" % path)
					continue
			data[key] = int(number)
		if rule == "positive_unit_interval" and (number <= 0 or number > 1):
			errors.append("%s: must be > 0 and <= 1" % path)
		elif rule == "unit_interval" and (number < 0 or number > 1):
			errors.append("%s: must be between 0 and 1 inclusive" % path)
		elif rule == "version" and number != 1:
			errors.append("%s: unsupported schema version; expected 1" % path)
		elif rule in ["nonnegative_integer", "nonnegative"] and number < 0:
			errors.append("%s: must be >= 0" % path)
		elif rule == "positive_integer" and number < 1:
			errors.append("%s: must be an integer >= 1" % path)
		elif rule == "wedge_integer" and (number < 1 or number > 12):
			errors.append("%s: must be an integer from 1 to 12" % path)
		elif rule == "positive" and number <= 0:
			errors.append("%s: must be > 0" % path)
		elif rule == "arc" and (number <= 0 or number > 360):
			errors.append("%s: must be > 0 and <= 360 degrees" % path)

