class_name IntegrityLayout
extends RefCounted
## Instrument geometry in local Control coordinates. The host supplies the
## true local-to-physical transform; UI scale is already included in that.
const MIN_BAND_PIXELS := 6.0
const SEPARATOR_PIXELS := 1.0
const MARGIN := 8.0
const CORE_FRACTION := 0.22
const Scale = preload("res://src/presentation/readability/swarm_lod.gd")

static func minimum_size(rings: int, local_to_physical: Transform2D = Transform2D.IDENTITY) -> Vector2:
	var scale := maxf(0.0001, Scale.minimum_scale(local_to_physical))
	var radius := (maxi(1, rings) * (MIN_BAND_PIXELS + SEPARATOR_PIXELS) / scale) / (1.0 - CORE_FRACTION)
	return Vector2.ONE * ceilf((radius + MARGIN) * 2.0)

static func geometry(size: Vector2, rings: int) -> Dictionary:
	var outer := maxf(0.0, minf(size.x, size.y) * 0.5 - MARGIN)
	var core := outer * CORE_FRACTION
	return {"center": size * 0.5, "outer": outer, "core": core, "band": (outer - core) / maxi(1, rings), "rings": rings}

static func hit(local: Vector2, shape: Dictionary, records: Array[Dictionary]) -> Vector2i:
	var point: Vector2 = local - shape.center
	var radius := point.length()
	if radius > float(shape.outer) or float(shape.band) <= 0: return Vector2i(-1, -1)
	if radius < float(shape.core): return Vector2i.ZERO
	var index := mini(records.size() - 1, floori((radius - float(shape.core)) / float(shape.band)))
	if index < 0 or index >= records.size(): return Vector2i(-1, -1)
	return Vector2i(int(records[index].get("ring", index + 1)), Scale.bearing_for(point))

static func focus_point(ring_index: int, wedge: int, shape: Dictionary) -> Vector2:
	var radius := float(shape.core) + (ring_index + 0.5) * float(shape.band)
	var turns := float(posmod(wedge, 12)) / 12.0
	return shape.center + Vector2(sin(turns * TAU), -cos(turns * TAU)) * radius
