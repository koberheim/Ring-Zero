extends SceneTree

var _failures := 0

func _initialize() -> void:
	_radial()
	_angular()
	_invalid()
	print("polar_motion: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	quit(0 if _failures == 0 else 1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)

func _radius(p: PolarPosition) -> float:
	return 96.0 * (float(p.ring) + p.radial_fraction)

func _bearing(p: PolarPosition) -> float:
	return fposmod((float(p.wedge % 12) + p.angular_fraction - 0.5) / 12.0, 1.0)

func _same(a: PolarPosition, b: PolarPosition) -> bool:
	return a.ring == b.ring and a.wedge == b.wedge and a.radial_fraction == b.radial_fraction and a.angular_fraction == b.angular_fraction

func _radial() -> void:
	var source := PolarPosition.new(2, 4, 0.25, 0.3)
	var target := PolarPosition.new(5, 4, 0.75, 0.3)
	var part := PolarMotion.advance(source, target, 48.0, 2.0)
	_check(part.ok and not part.reached and absf(_radius(part.position) - _radius(source) - 96.0) < 1.0e-8 and part.time_used == 2.0, "fractional outward constant speed")
	var inward := PolarMotion.advance(target, source, 48.0, 2.0)
	_check(inward.ok and absf(_radius(target) - _radius(inward.position) - 96.0) < 1.0e-8, "inward constant speed")
	var reached := PolarMotion.advance(source, target, 48.0, 10.0)
	_check(reached.ok and reached.reached and reached.time_used == 7.0 and _same(reached.position, target) and not is_same(reached.position, target), "exact target and three seconds residual")
	var boundary := PolarMotion.advance(source, target, 72.0, 1.0)
	_check(boundary.ok and boundary.position.ring == 3 and boundary.position.radial_fraction == 0.0, "outward band boundary ownership")
	var inward_boundary := PolarMotion.advance(target, source, 72.0, 1.0)
	_check(inward_boundary.ok and inward_boundary.position.ring == 5 and inward_boundary.position.radial_fraction == 0.0, "inward boundary outward ownership")
	var zero := PolarMotion.advance(source, target, 1.0, 0.0)
	_check(zero.ok and not zero.reached and zero.time_used == 0.0 and _same(zero.position, source) and not is_same(zero.position, source), "zero time clone")
	var equal := PolarMotion.advance(source, source, 1.0, 0.0)
	_check(equal.ok and equal.reached and equal.time_used == 0.0 and not is_same(equal.position, source), "identical clone")
	var split := PolarMotion.advance(source, target, 31.0, 0.7)
	split = PolarMotion.advance(split.position, target, 31.0, 0.9)
	var whole := PolarMotion.advance(source, target, 31.0, 1.6)
	_check(absf(_radius(split.position) - _radius(whole.position)) < 1.0e-8, "radial split equals whole")
	_check(source.ring == 2 and source.radial_fraction == 0.25 and target.ring == 5 and target.radial_fraction == 0.75, "input isolation")

func _angular() -> void:
	var source := PolarPosition.new(2, 12, 0.4, 0.75)
	var target := PolarPosition.new(2, 2, 0.4, 0.25)
	var radius := _radius(source)
	var speed := radius * TAU / 12.0
	var clockwise := PolarMotion.advance(source, target, speed, 0.5)
	_check(clockwise.ok and clockwise.position.wedge == 1 and absf(clockwise.position.angular_fraction - 0.25) < 1.0e-12, "clockwise crosses 12/1 seam at arc speed")
	var reverse := PolarMotion.advance(target, source, speed, 0.5)
	_check(reverse.ok and reverse.position.wedge == 1 and absf(reverse.position.angular_fraction - 0.75) < 1.0e-12, "counterclockwise arc speed")
	var seam := PolarMotion.advance(source, target, speed, 0.25)
	_check(seam.ok and seam.position.wedge == 1 and seam.position.angular_fraction == 0.0, "clockwise wedge boundary ownership")
	var back_seam := PolarMotion.advance(target, source, speed, 0.25)
	_check(back_seam.ok and back_seam.position.wedge == 2 and back_seam.position.angular_fraction == 0.0, "counterclockwise boundary clockwise ownership")
	var half_source := PolarPosition.new(1, 12, 0.5, 0.5)
	var half_target := PolarPosition.new(1, 6, 0.5, 0.5)
	var half := PolarMotion.advance(half_source, half_target, _radius(half_source) * TAU / 12.0, 1.0)
	_check(half.ok and half.position.wedge == 1 and absf(half.position.angular_fraction - 0.5) < 1.0e-12, "exact half turn clockwise")
	for wedge in range(1, 13):
		var half_a := PolarPosition.new(2, wedge, 0.125, 0.3)
		var half_b := PolarPosition.new(2, (wedge + 5) % 12 + 1, 0.125, 0.3)
		var fractional_half := PolarMotion.advance(half_a, half_b, _radius(half_a) * TAU / 12.0, 0.25)
		var clockwise_progress := fposmod(_bearing(fractional_half.position) - _bearing(half_a), 1.0)
		_check(fractional_half.ok and absf(clockwise_progress - 0.25 / 12.0) < 1.0e-12, "fractional half-turn clockwise in every wedge")
	var end := PolarMotion.advance(source, target, speed, 10.0)
	_check(end.ok and end.reached and absf(end.time_used - 1.5) < 1.0e-12 and _same(end.position, target), "arc residual time exact target")
	var split := PolarMotion.advance(source, target, speed, 0.3)
	split = PolarMotion.advance(split.position, target, speed, 0.4)
	var whole := PolarMotion.advance(source, target, speed, 0.7)
	_check(absf(_bearing(split.position) - _bearing(whole.position)) < 1.0e-12 and absf(_radius(split.position) - radius) < 1.0e-8, "angular split equals whole")

func _invalid() -> void:
	var valid := PolarPosition.new(1, 1, 0.25, 0.25)
	var target := PolarPosition.new(2, 1, 0.25, 0.25)
	_reject(PolarMotion.advance(null, valid, 1, 1), "null")
	for p in [PolarPosition.new(0, 1, 0.0, 0.0), PolarPosition.new(-1, 1, 0.0, 0.0), PolarPosition.new(1, 0, 0.0, 0.0), PolarPosition.new(1, 13, 0.0, 0.0), PolarPosition.new(1, 1, -0.1, 0.0), PolarPosition.new(1, 1, 1.0, 0.0), PolarPosition.new(1, 1, 0.0, 1.0), PolarPosition.new(1, 1, INF, 0.0), PolarPosition.new(1, 1, 0.0, NAN)]:
		_reject(PolarMotion.advance(p, valid, 1, 1), "invalid position")
		_reject(PolarMotion.advance(valid, p, 1, 1), "invalid target")
	for speed in [0.0, -1.0, INF, NAN]:
		_reject(PolarMotion.advance(valid, target, speed, 1), "invalid speed")
	for delta in [-1.0, INF, NAN]:
		_reject(PolarMotion.advance(valid, target, 1, delta), "invalid delta")
	_reject(PolarMotion.advance(valid, PolarPosition.new(2, 2, 0.25, 0.25), 1, 1), "diagonal")
	_reject(PolarMotion.advance(valid, target, 1.0e-320, 1), "time overflow")
	_reject(PolarMotion.advance(valid, PolarPosition.new(9223372036854775807, 1, 0.25, 0.25), 1, 1), "unrepresentable band")
	_reject(PolarMotion.advance(valid, PolarPosition.new(9007199254740990, 1, 0.25, 0.25), 1, 1), "fraction lost in large radius")
	_reject(PolarMotion.advance(valid, target, 1.0e-200, 1.0e-200), "travel underflow")
	_reject(PolarMotion.advance(valid, target, 1, 1.0e-20), "unrepresentable radial progress")

func _reject(result: Dictionary, label: String) -> void:
	_check(not result.ok and result.position == null and result.time_used == 0 and not result.reached and not result.errors.is_empty(), label)
