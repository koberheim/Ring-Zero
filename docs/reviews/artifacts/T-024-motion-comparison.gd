extends SceneTree

var _failures := 0
var _comparisons := 0
var _benchmark_checksum := 0

func _initialize() -> void:
	_radial()
	_angular()
	_invalid()
	_equivalence()
	if _failures == 0:
		_benchmark()
	print("motion equivalence comparisons=%d" % _comparisons)
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

func _compare(source: PolarPosition, target: PolarPosition, speed: float, delta: float) -> void:
	_comparisons += 1
	var prior := FrozenMotion.advance(source, target, speed, delta)
	var actual := PolarMotion.advance(source, target, speed, delta)
	_check(prior.ok == actual.ok and prior.reached == actual.reached and prior.time_used == actual.time_used and prior.errors == actual.errors, "frozen outcome/time/diagnostic equivalence")
	if prior.ok and actual.ok:
		_check(prior.position.ring == actual.position.ring and prior.position.wedge == actual.position.wedge, "frozen exact cell ownership")
		_check(absf(_radius(prior.position) - _radius(actual.position)) <= 1.0e-8, "frozen radius tolerance")
		var difference := absf(_bearing(prior.position) - _bearing(actual.position))
		_check(minf(difference, 1.0 - difference) <= 1.0e-12, "frozen bearing tolerance")
		_check(not is_same(actual.position, source) and not is_same(actual.position, target), "frozen independent output")

func _equivalence() -> void:
	for ring in [1, 2, 17, 1000001]:
		for wedge in range(1, 13):
			for fraction in [0.0, 1.0e-14, 0.123456789, 0.5, 0.99999999999999]:
				var source := PolarPosition.new(ring, wedge, fraction, fraction)
				var radial := PolarPosition.new(ring + 2, wedge, 0.5, fraction)
				var angular := PolarPosition.new(ring, wedge % 12 + 1, fraction, fraction)
				for delta in [0.0, 1.0 / 60.0, 10.0]:
					_compare(source, radial, 96.0, delta)
					_compare(source, angular, 96.0, delta)
				_compare(radial, source, 96.0, 0.25)
				_compare(angular, source, 96.0, 0.25)
	var source := PolarPosition.new(2, 12, 0.4, 0.3)
	var radial := PolarPosition.new(4, 12, 0.4, 0.3)
	var angular := PolarPosition.new(2, 1, 0.4, 0.3)
	for target in [radial, angular]:
		var old := FrozenMotion.advance(source, target, 96.0, 0.13)
		var actual := PolarMotion.advance(source, target, 96.0, 0.13)
		for index in range(10):
			old = FrozenMotion.advance(old.position, target, 96.0, 0.13)
			actual = PolarMotion.advance(actual.position, target, 96.0, 0.13)
			_check(old.ok == actual.ok and old.reached == actual.reached and absf(old.time_used - actual.time_used) <= 1.0e-10, "frozen split travel time")
			_check(old.position.ring == actual.position.ring and old.position.wedge == actual.position.wedge and absf(_radius(old.position) - _radius(actual.position)) <= 1.0e-8, "frozen split travel position")
	_compare(source, PolarPosition.new(2, 12, 0.4 + 1.0e-11, 0.3 + 1.0e-12), 96, 1)
	_compare(source, PolarPosition.new(2, 12, 0.4 + 1.0e-8, 0.3 + 1.0e-8), 96, 1)
	for speed in [0.0, -1.0, INF, NAN, 1.0e-320, 1.0e-200, 1.0e308]:
		for delta in [-1.0, INF, NAN, 0.0, 1.0e-200, 1.0e-20, 1.0]:
			_compare(source, radial, speed, delta)
	_compare(source, angular, 1, 1.0e-20)
	_compare(null, angular, 1, 1)
	_compare(source, PolarPosition.new(9223372036854775807, 12, 0.4, 0.3), 1, 1)
	_compare(source, PolarPosition.new(9007199254740990, 12, 0.25, 0.3), 1, 1)

func _benchmark() -> void:
	for angular in [false, true]:
		var sources: Array[PolarPosition] = []
		var targets: Array[PolarPosition] = []
		for index in range(1000):
			var ring := 2 + index % 7
			var wedge := index % 12 + 1
			var radial_fraction := 0.2 + float(index % 7) / 10.0
			var angular_fraction := 0.123 + float(index % 5) * 0.13
			sources.append(PolarPosition.new(ring, wedge, radial_fraction, angular_fraction))
			targets.append(PolarPosition.new(ring if angular else ring + 2, wedge % 12 + 1 if angular else wedge, radial_fraction, angular_fraction))
		var before: Array[int] = []
		var after: Array[int] = []
		for sample in range(25):
			# Alternate order to limit consistent first/second-run bias.
			for pass_index in range(2):
				var baseline := (sample + pass_index) % 2 == 0
				var started := Time.get_ticks_usec()
				for index in range(1000):
					var result: Dictionary = FrozenMotion.advance(sources[index], targets[index], 96.0, 1.0 / 60.0) if baseline else PolarMotion.advance(sources[index], targets[index], 96.0, 1.0 / 60.0)
					_benchmark_checksum += result.position.ring
				var duration := Time.get_ticks_usec() - started
				if sample >= 5:
					if baseline: before.append(duration)
					else: after.append(duration)
		before.sort()
		after.sort()
		print("motion 1000 %s calls warmups=5 samples=20 before_median_us=%.1f before_p90_us=%d after_median_us=%.1f after_p90_us=%d checksum=%d" % ["angular" if angular else "radial", (before[9] + before[10]) / 2.0, before[17], (after[9] + after[10]) / 2.0, after[17], _benchmark_checksum])

# Frozen accepted T-020 implementation, test instrumentation only.
class FrozenMotion:
	extends RefCounted
	## Double-precision scalar interpolation; no route or barrier decisions.
	## Equality allows 1e-8 world units / 1e-12 turns of representation roundoff.
	## Boundary reconstruction snaps only within 1e-10 units / 1e-14 turns.

	const RADIAL_TOLERANCE := 1.0e-8
	const ANGULAR_TOLERANCE := 1.0e-12
	const MAX_EXACT_INTEGER := 9007199254740991

	static func advance(current: PolarPosition, target: PolarPosition, speed_world: float, delta_seconds: float) -> Dictionary:
		if not _valid_position(current) or not _valid_position(target):
			return _failure("Positions require ring >= 1, wedge 1..12, and finite fractions in [0,1).")
		if not is_finite(speed_world) or speed_world <= 0.0 or not is_finite(delta_seconds) or delta_seconds < 0.0:
			return _failure("Speed must be finite positive; delta must be finite nonnegative.")
		var radius := _radius(current)
		var target_radius := _radius(target)
		if not is_finite(radius) or not is_finite(target_radius) or current.ring > MAX_EXACT_INTEGER or target.ring > MAX_EXACT_INTEGER:
			return _failure("Radius or band ID is not representable.")
		var bearing := _bearing(current)
		# Difference before absolute-bearing conversion preserves exact half-turn
		# ties when both fractional bearings are equal.
		var clockwise := fposmod((float(target.wedge - current.wedge) + (target.angular_fraction - current.angular_fraction)) / 12.0, 1.0)
		var angular_delta := clockwise if clockwise <= 0.5 else clockwise - 1.0
		var radial_delta := target_radius - radius
		var same_radius := absf(radial_delta) <= RADIAL_TOLERANCE
		var same_bearing := absf(angular_delta) <= ANGULAR_TOLERANCE
		if not same_radius and not same_bearing:
			return _failure("A segment must be radial or angular, not both.")
		if same_radius and same_bearing:
			return _success(_clone(target), 0.0, true)
		var distance := absf(radial_delta) if same_bearing else absf(angular_delta) * TAU * radius
		var duration := distance / speed_world
		if not is_finite(distance) or distance <= 0.0 or not is_finite(duration) or duration <= 0.0:
			return _failure("Segment distance or travel time is nonfinite or unrepresentable.")
		if delta_seconds >= duration:
			return _success(_clone(target), duration, true)
		if delta_seconds == 0.0:
			return _success(_clone(current), 0.0, false)
		var travel := speed_world * delta_seconds
		if not is_finite(travel) or travel <= 0.0:
			return _failure("Travel distance is nonfinite or unrepresentable.")
		var moved_radius := radius
		var moved_bearing := bearing
		if same_bearing:
			moved_radius += travel if radial_delta > 0.0 else -travel
			if moved_radius == radius:
				return _failure("Radial progress is too small to represent.")
		else:
			moved_bearing = fposmod(bearing + (travel / radius / TAU) * (1.0 if angular_delta > 0.0 else -1.0), 1.0)
			if moved_bearing == bearing:
				return _failure("Angular progress is too small to represent.")
		var position := _from_scalars(moved_radius, moved_bearing)
		if position == null:
			return _failure("Interpolated polar position is not representable.")
		return _success(position, delta_seconds, false)

	static func _valid_position(position: PolarPosition) -> bool:
		return position != null and position.ring >= 1 and position.wedge >= 1 and position.wedge <= 12 and is_finite(position.radial_fraction) and is_finite(position.angular_fraction) and position.radial_fraction >= 0.0 and position.radial_fraction < 1.0 and position.angular_fraction >= 0.0 and position.angular_fraction < 1.0

	static func _radius(position: PolarPosition) -> float:
		if position.ring > MAX_EXACT_INTEGER:
			return NAN
		var radius := float(PolarGrid.CORE_RADIUS) + (float(position.ring - 1) + position.radial_fraction) * float(PolarGrid.RING_WIDTH)
		var recovered_bands := (radius - float(PolarGrid.CORE_RADIUS)) / float(PolarGrid.RING_WIDTH)
		if floorf(recovered_bands) != float(position.ring - 1) or absf((recovered_bands - floorf(recovered_bands)) - position.radial_fraction) * float(PolarGrid.RING_WIDTH) > RADIAL_TOLERANCE:
			return NAN
		return radius

	static func _bearing(position: PolarPosition) -> float:
		return fposmod(float(position.wedge % 12) / 12.0 - 1.0 / 24.0 + position.angular_fraction / 12.0, 1.0)

	static func _from_scalars(radius: float, bearing: float) -> PolarPosition:
		if not is_finite(radius) or radius < float(PolarGrid.CORE_RADIUS):
			return null
		var bands := (radius - float(PolarGrid.CORE_RADIUS)) / float(PolarGrid.RING_WIDTH)
		var nearest_band := roundf(bands)
		if absf(bands - nearest_band) * float(PolarGrid.RING_WIDTH) <= 1.0e-10:
			bands = nearest_band
		if bands < 0.0 or bands >= float(MAX_EXACT_INTEGER):
			return null
		var ring := int(floorf(bands)) + 1
		var radial_fraction := bands - floorf(bands)
		var sectors := fposmod(bearing + 1.0 / 24.0, 1.0) * 12.0
		if absf(sectors - roundf(sectors)) / 12.0 <= 1.0e-14:
			sectors = roundf(sectors)
		if sectors >= 12.0:
			sectors = 0.0
		var sector := int(floorf(sectors))
		var wedge := 12 if sector == 0 else sector
		return PolarPosition.new(ring, wedge, radial_fraction, sectors - floorf(sectors))

	static func _clone(position: PolarPosition) -> PolarPosition:
		return PolarPosition.new(position.ring, position.wedge, position.radial_fraction, position.angular_fraction)

	static func _success(position: PolarPosition, time_used: float, reached: bool) -> Dictionary:
		return {"ok": true, "position": position, "time_used": time_used, "reached": reached, "errors": PackedStringArray()}

	static func _failure(message: String) -> Dictionary:
		return {"ok": false, "position": null, "time_used": 0.0, "reached": false, "errors": PackedStringArray([message])}

