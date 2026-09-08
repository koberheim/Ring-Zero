class_name PolarMotion
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
