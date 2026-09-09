class_name SwarmLod
extends RefCounted
## Read-only presentation projection. Never changes paths, actor count or HP.
## Pass the FULL world-to-physical-window transform, including viewport stretch.

const ENTER_MASS_SCALE := 0.50 # physical pixels/world unit, provisional
const EXIT_MASS_SCALE := 0.62 # hysteresis avoids zoom-boundary shimmer
const BIN_PIXELS := 24.0
const BIN_WORLD := BIN_PIXELS / ENTER_MASS_SCALE
const BATCH_SIZE := 256
const STANDARD_CANVAS_WORLD := 15.0
const STANDARD_FLOOR_PIXELS := 4.0

var mass_mode := false

static func minimum_scale(transform: Transform2D) -> float:
	# Smallest singular value: rotation, anisotropic stretch and shear all count.
	var a := transform.x.length_squared()
	var b := transform.x.dot(transform.y)
	var d := transform.y.length_squared()
	return sqrt(maxf(0.0, (a + d - sqrt(maxf(0.0, (a - d) * (a - d) + 4.0 * b * b))) * 0.5))

func update_mode(world_to_physical: Transform2D) -> bool:
	var scale := minimum_scale(world_to_physical)
	if mass_mode:
		if scale >= EXIT_MASS_SCALE: mass_mode = false
	elif scale <= ENTER_MASS_SCALE:
		mass_mode = true
	return mass_mode

static func bearing_for(point: Vector2) -> int:
	var turns := fposmod(atan2(point.x, -point.y) / TAU, 1.0)
	var sector := int(floor(fposmod(turns + 1.0 / 24.0, 1.0) * 12.0))
	return 12 if sector == 0 else sector

static func canonical_kind(target: Dictionary) -> String:
	var kind := String(target.get("kind", "normal"))
	return "normal" if kind in ["", "standard", "normal"] else kind

static func canvas_world_size(metadata: Dictionary, world_to_physical: Transform2D) -> float:
	var base := float(metadata.get("world_canvas_size", STANDARD_CANVAS_WORLD))
	var floor_pixels := float(metadata.get("physical_floor_px", STANDARD_FLOOR_PIXELS))
	var fraction := float(metadata.get("min_occupied_extent_fraction", 1.0))
	var scale := minimum_scale(world_to_physical)
	if scale <= 0.0 or fraction <= 0.0: return base
	# F measures the longest occupied axis at all twelve bearings. sqrt(2)
	# conservatively protects that extent under arbitrary additional rotation /
	# shear, rather than pretending the transparent atlas canvas is the shape.
	return maxf(base, floor_pixels * sqrt(2.0) / (scale * fraction))

static func frame_for(metadata: Dictionary, seconds: float, reduced_motion: bool) -> int:
	if reduced_motion: return 0
	var count := maxi(1, int(metadata.get("frame_count", 1)))
	var period := maxf(0.001, float(metadata.get("period_seconds", 1.0)))
	return posmod(int(floor(seconds / period * count)), count)

static func frame_rect(metadata: Dictionary, frame: int) -> Rect2:
	var rectangles: Array = metadata.get("frame_rects", [])
	if not rectangles.is_empty():
		var rect: Array = rectangles[posmod(frame, rectangles.size())]
		return Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
	return Rect2(0, 0, 1, 1)

func project(targets: Array[Dictionary], world_points: PackedVector2Array, world_to_physical: Transform2D, visible_rect: Rect2, classes: Dictionary) -> Dictionary:
	assert(targets.size() == world_points.size(), "Every target requires its authoritative world position")
	update_mode(world_to_physical)
	var standards := PackedInt32Array()
	var elites := PackedInt32Array()
	var bearing_counts := PackedInt32Array()
	var standard_bearings := PackedInt32Array()
	bearing_counts.resize(12)
	standard_bearings.resize(12)
	var bins := {}
	var scale := minimum_scale(world_to_physical)
	if scale <= 0.0:
		return {"valid_transform": false, "mass_mode": mass_mode, "standards": standards, "elites": elites, "bearing_counts": bearing_counts, "standard_bearings": standard_bearings, "bins": [], "batches": []}
	for index in targets.size():
		var target: Dictionary = targets[index]
		if float(target.get("hp", 0.0)) <= 0.0 or String(target.get("phase", "")) == "burrowing": continue
		var point := world_points[index]
		if not point.is_finite(): continue
		var kind := canonical_kind(target)
		var metadata: Dictionary = classes.get(kind, {})
		var width := canvas_world_size(metadata, world_to_physical)
		# Conservative transformed canvas bounds keeps partially visible actors.
		var extent := (world_to_physical.x.abs() + world_to_physical.y.abs()) * width * 0.5
		var screen := world_to_physical * point
		if not visible_rect.intersects(Rect2(screen - extent, extent * 2.0), true): continue
		var bearing := bearing_for(point)
		bearing_counts[bearing - 1] += 1
		if kind != "normal":
			elites.append(index)
			continue
		standards.append(index)
		standard_bearings[bearing - 1] += 1
		# World-anchored bins remain fixed while panning. Camera changes do not
		# move a machine to another bearing or alter its authoritative position.
		var key := Vector2i(floori(point.x / BIN_WORLD), floori(point.y / BIN_WORLD))
		if not bins.has(key): bins[key] = {"count": 0, "sum": Vector2.ZERO, "bearing_counts": PackedInt32Array([0,0,0,0,0,0,0,0,0,0,0,0])}
		bins[key].count += 1
		bins[key].sum += point
		bins[key].bearing_counts[bearing - 1] += 1
	var density: Array[Dictionary] = []
	for key in bins:
		var entry: Dictionary = bins[key]
		density.append({"cell": key, "position": entry.sum / float(entry.count), "count": entry.count, "bearing_counts": entry.bearing_counts})
	# Batch descriptors cover EVERY visible standard; BATCH_SIZE is allocation
	# granularity, never a shipping cap or a discard limit. Reuse GPU buffers.
	var batches: Array[Vector2i] = []
	for start in range(0, standards.size(), BATCH_SIZE):
		batches.append(Vector2i(start, mini(BATCH_SIZE, standards.size() - start)))
	return {"valid_transform": true, "mass_mode": mass_mode, "standards": standards, "elites": elites, "bearing_counts": bearing_counts, "standard_bearings": standard_bearings, "bins": density, "batches": batches}

static func dominant_bearings(counts: PackedInt32Array) -> PackedInt32Array:
	var result := PackedInt32Array()
	var maximum := 0
	for value in counts: maximum = maxi(maximum, value)
	if maximum == 0: return result
	for index in counts.size():
		if counts[index] == maximum: result.append(index + 1)
	return result
