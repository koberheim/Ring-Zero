class_name PolarGrid
extends RefCounted

const WEDGE_COUNT: int = 12
const CORE_RADIUS: float = 96.0
const RING_WIDTH: float = 96.0
# Vector2 components use single precision. Snap only within one millionth
# of a band/wedge boundary (0.000096 world units / 0.00003 degrees).
const BOUNDARY_TOLERANCE: float = 0.000001

var ring_count: int = 3


func _init(p_ring_count: int = 3) -> void:
	if p_ring_count < 0:
		push_error("PolarGrid: ring count must be nonnegative; using 0.")
		ring_count = 0
	else:
		ring_count = p_ring_count


func is_valid_cell(cell: Vector2i) -> bool:
	return cell == Vector2i.ZERO or (cell.x >= 1 and cell.x <= ring_count and cell.y >= 1 and cell.y <= WEDGE_COUNT)


func all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	for ring in range(1, ring_count + 1):
		for wedge in range(1, WEDGE_COUNT + 1):
			cells.append(Vector2i(ring, wedge))
	return cells


func ring_bounds(ring: int) -> Vector2:
	if ring < 0 or ring > ring_count:
		return Vector2(-1, -1)
	if ring == 0:
		return Vector2(0, CORE_RADIUS)
	return Vector2(CORE_RADIUS + (ring - 1) * RING_WIDTH, CORE_RADIUS + ring * RING_WIDTH)


func cell_center(cell: Vector2i) -> PolarPosition:
	if not is_valid_cell(cell):
		return null
	if cell.x == 0:
		return PolarPosition.new()
	return PolarPosition.new(cell.x, cell.y, 0.5, 0.5)


func cell_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	if not is_valid_cell(cell):
		return neighbors
	if cell.x == 0:
		if ring_count > 0:
			for wedge in range(1, WEDGE_COUNT + 1):
				neighbors.append(Vector2i(1, wedge))
		return neighbors
	neighbors.append(Vector2i(cell.x, wrapi(cell.y - 1, 1, WEDGE_COUNT + 1)))
	neighbors.append(Vector2i(cell.x, wrapi(cell.y + 1, 1, WEDGE_COUNT + 1)))
	neighbors.append(Vector2i.ZERO if cell.x == 1 else Vector2i(cell.x - 1, cell.y))
	if cell.x < ring_count:
		neighbors.append(Vector2i(cell.x + 1, cell.y))
	return neighbors


func is_valid_position(position: PolarPosition) -> bool:
	if position == null or not is_valid_cell(Vector2i(position.ring, position.wedge)):
		return false
	if not is_finite(position.radial_fraction) or not is_finite(position.angular_fraction):
		return false
	if position.radial_fraction < 0.0 or position.radial_fraction >= 1.0 or position.angular_fraction < 0.0 or position.angular_fraction >= 1.0:
		return false
	return not (position.ring == 0 and position.radial_fraction == 0.0 and position.angular_fraction != 0.0)


func polar_to_world(position: PolarPosition) -> Vector2:
	if not is_valid_position(position):
		push_error("PolarGrid: polar_to_world requires a valid PolarPosition.")
		return Vector2(INF, INF)
	var radius: float
	var turns: float
	if position.ring == 0:
		radius = position.radial_fraction * CORE_RADIUS
		turns = position.angular_fraction
	else:
		radius = CORE_RADIUS + (position.ring - 1 + position.radial_fraction) * RING_WIDTH
		turns = float(position.wedge % WEDGE_COUNT) / WEDGE_COUNT - 1.0 / 24.0 + position.angular_fraction / WEDGE_COUNT
	return Vector2(radius * sin(turns * TAU), -radius * cos(turns * TAU))


func _snap_boundary(value: float) -> float:
	var nearest := roundf(value)
	return nearest if absf(value - nearest) <= BOUNDARY_TOLERANCE else value


func world_to_polar(point: Vector2) -> PolarPosition:
	if not is_finite(point.x) or not is_finite(point.y):
		return null
	# Compute length in scalar precision, avoiding a single-precision intermediate.
	var radius := sqrt(float(point.x) * point.x + float(point.y) * point.y)
	var radial_coordinate := _snap_boundary(radius / RING_WIDTH)
	if radial_coordinate >= ring_count + 1:
		return null
	if radius == 0.0:
		return PolarPosition.new()
	var turns := fposmod(atan2(point.x, -point.y) / TAU, 1.0)
	if radial_coordinate < 1.0:
		# Do not snap small nonzero core radii to a noncanonical origin.
		return PolarPosition.new(0, 0, radius / CORE_RADIUS, turns)
	var ring := int(floor(radial_coordinate))
	var wedge_coordinate := _snap_boundary(turns * WEDGE_COUNT + 0.5)
	var wedge_index := int(floor(wedge_coordinate))
	var wedge := wedge_index % WEDGE_COUNT
	if wedge == 0:
		wedge = WEDGE_COUNT
	return PolarPosition.new(ring, wedge, radial_coordinate - ring, wedge_coordinate - wedge_index)


func world_to_cell(point: Vector2) -> Vector2i:
	var position := world_to_polar(point)
	return Vector2i(-1, -1) if position == null else Vector2i(position.ring, position.wedge)
