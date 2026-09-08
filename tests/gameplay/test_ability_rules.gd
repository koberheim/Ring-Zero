extends SceneTree
var checks := 0
var failures := 0
func _check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _target(id: int, ring: int = 2, wedge: int = 12, radial: float = 0.0) -> Dictionary:
	return {"id": id, "position": PolarPosition.new(ring, wedge, radial, 0.5), "hp": 10.0}
func _initialize() -> void:
	var profile: BalanceProfile = BalanceProfile.load_json("res://data/balance/testing.json").profile
	var aim := PolarPosition.new(1, 12, 0, 0.5)
	var targets: Array[Dictionary] = [_target(9), _target(2, 2, 1), _target(3, 2, 11), _target(4, 2, 6), _target(5, 2, 2), _target(6, 8), _target(7, 8, 12, 0.01)]
	var result := AbilityRules.cast(profile, targets, {}, &"focused_flare", aim)
	_check(result.ok and result.kill_ids == [9, 2, 3, 6] and result.energy_awarded == 0, "Flare sector edges/range edge included, opposite/outside excluded; input order preserved")
	_check(targets[0].hp == 10 and result.targets[0].hp == 0 and result.cooldowns[&"focused_flare"] == 30, "Pure cast consumes only returned cooldown and target HP")
	_check(result.hits[0] == {"ability_id": &"focused_flare", "target_id": 9, "damage": 10.0}, "Exact ability hit schema")
	result.targets[0].position.ring = 99
	_check(targets[0].position.ring == 2 and aim.ring == 1, "Returned position and aim independent")
	var tuned: BalanceProfile = profile.with_overrides({"emp_burst": {"radius_ring_widths": 1, "damage": 1, "stun_seconds": 3, "cooldown_seconds": 0.25}}).profile
	var center := PolarPosition.new(2, 12, 0, 0.5)
	targets = [_target(1, 3), _target(2, 3, 12, 0.01), _target(3, 1), _target(4, 2)]
	targets[3].targetable = false
	result = AbilityRules.cast(tuned, targets, {}, &"emp_burst", center)
	_check(result.ok and result.hits.size() == 2 and result.hits[0].target_id == 1 and result.hits[1].target_id == 3, "EMP radius boundary in both directions; hidden/outside excluded")
	_check(result.targets[0].hp == 9 and result.targets[0].stun_remaining == 3 and result.cooldowns[&"emp_burst"] == 0.25, "EMP numeric overrides honored")
	targets[0].stun_remaining = 5.0
	targets[0].assimilation_stacks = [15.0]
	targets[0].start_position = PolarPosition.new(4, 12, 0, 0.5)
	targets[0].destination = PolarPosition.new(1, 12, 0.5, 0.5)
	result = AbilityRules.cast(tuned, targets, {}, &"emp_burst", center)
	_check(result.targets[0].stun_remaining == 5.0, "EMP never shortens existing longer stun")
	result.targets[0].assimilation_stacks.clear()
	result.targets[0].start_position.ring = 99
	result.targets[0].destination.ring = 99
	_check(targets[0].assimilation_stacks == [15.0] and targets[0].start_position.ring == 4 and targets[0].destination.ring == 1, "All known nested lifecycle/status data isolated")
	var empty: Array[Dictionary] = []
	_check(AbilityRules.cast(profile, empty, {}, &"emp_burst", PolarPosition.new(100, 1, 0, 0.5)).ok, "Empty EMP cast consumes cooldown without aim-distance limit")
	_check(AbilityRules.cast(profile, empty, {}, &"emp_burst", PolarPosition.new()).ok, "EMP permits core-origin aim")
	_check(not AbilityRules.cast(profile, empty, {}, &"focused_flare", PolarPosition.new()).ok, "Zero-length Flare aim invalid")
	_check(not AbilityRules.cast(profile, empty, {}, &"unknown", aim).ok and not AbilityRules.cast(profile, empty, {}, &"emp_burst", null).ok, "Invalid kind/aim")
	_check(not AbilityRules.cast(profile, empty, {&"emp_burst": 0.1}, &"emp_burst", aim).ok, "Cooling ability rejected")
	_check(AbilityRules.cast(profile, empty, {&"focused_flare": 10.0}, &"emp_burst", aim).cooldowns[&"focused_flare"] == 10, "Other ability cooldown retained")
	for bad in [{&"emp_burst": -1.0}, {&"emp_burst": INF}, {&"emp_burst": NAN}, {&"emp_burst": true}, {"emp_burst": 1.0}, {&"other": 0.0}]:
		_check(not AbilityRules.cast(profile, empty, bad, &"emp_burst", aim).ok, "Strict ability cooldown validation")
	for field in ["hp", "position", "targetable", "stun_remaining", "assimilation_stacks"]:
		var bad := _target(1)
		bad[field] = {"hp": NAN, "position": null, "targetable": 1, "stun_remaining": INF, "assimilation_stacks": [false]}[field]
		var supplied: Array[Dictionary] = [_target(0), bad]
		result = AbilityRules.cast(profile, supplied, {}, &"focused_flare", aim)
		_check(not result.ok and result.hits.is_empty() and result.targets.is_empty() and supplied[0].hp == 10, "Malformed target failure is atomic: " + field)
	var huge: BalanceProfile = profile.with_overrides({"focused_flare": {"range_ring_widths": 1e308}}).profile
	_check(not AbilityRules.cast(huge, empty, {}, &"focused_flare", aim).ok, "Computed range overflow rejected")
	_check(not AbilityRules.cast(null, empty, {}, &"emp_burst", aim).ok, "Invalid profile")
	var precise: BalanceProfile = profile.with_overrides({"focused_flare": {"range_ring_widths": 50.1}, "emp_burst": {"radius_ring_widths": 0.1}}).profile
	var edge: Array[Dictionary] = [_target(1, 50, 3, 0.1), _target(2, 50, 3, 0.100001)]
	var east := PolarPosition.new(50, 3, 0, 0.5)
	var flare_edge := AbilityRules.cast(precise, edge, {}, &"focused_flare", east)
	_check(flare_edge.ok and flare_edge.kill_ids == [1], "Scalar Flare fractional radius boundary at ring50 excludes only outside target")
	var emp_edge := AbilityRules.cast(precise, edge, {}, &"emp_burst", east)
	_check(emp_edge.ok and emp_edge.hits.size() == 1 and emp_edge.hits[0].target_id == 1, "Scalar EMP local fractional distance remains precise at ring50")
	var core_targets: Array[Dictionary] = [{"id": 1, "hp": 10.0, "position": PolarPosition.new(0, 0, 0.5, 0.25)}, {"id": 2, "hp": 10.0, "position": PolarPosition.new(0, 0, 0.5, 0.75)}]
	_check(AbilityRules.cast(profile, core_targets, {}, &"focused_flare", PolarPosition.new(0, 0, 0.25, 0.25)).kill_ids == [1], "Scalar core-band radius/bearing mapping matches east versus west")
	print("Ability rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
