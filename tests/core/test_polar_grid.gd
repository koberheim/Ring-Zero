extends SceneTree

const Grid = preload("res://src/core/polar_grid.gd")
const Position = preload("res://src/core/polar_position.gd")

var checks: int = 0
var failures: int = 0


func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)


func point_at(radius: float, degrees: float) -> Vector2:
	return Vector2(radius * sin(deg_to_rad(degrees)), -radius * cos(deg_to_rad(degrees)))


func _initialize() -> void:
	var grid := Grid.new()
	var core := Grid.new(0)
	var extended := Grid.new(12)
	check(grid.all_cells().size() == 37, "three bands")
	check(core.all_cells() == [Vector2i.ZERO], "core only")
	check(extended.all_cells().size() == 145, "12 bands")
	check(Grid.new(100).all_cells().size() == 1201, "100 bands, no slice cap")
	var cells := grid.all_cells()
	for i in range(1, cells.size()):
		check(cells[i] == Vector2i(1 + (i - 1) / 12, 1 + (i - 1) % 12), "enumeration order")
	check(grid.ring_bounds(0) == Vector2(0, 96), "core bounds")
	check(grid.ring_bounds(1) == Vector2(96, 192), "ring 1 bounds")
	check(grid.ring_bounds(3) == Vector2(288, 384), "ring 3 bounds")
	check(grid.ring_bounds(-1) == Vector2(-1, -1) and grid.ring_bounds(4) == Vector2(-1, -1), "invalid bounds")
	for pair in [[0, 12], [90, 3], [180, 6], [270, 9], [14.999, 12], [15, 1], [15.001, 1], [344.999, 11], [345, 12], [345.001, 12]]:
		check(grid.world_to_cell(point_at(144, pair[0])) == Vector2i(1, pair[1]), "bearing " + str(pair[0]))
	for boundary in [96.0, 192.0, 288.0, 384.0]:
		var outward := int(boundary / 96)
		for angle in [0.0, 15.0, 90.0, 217.0]:
			var before := grid.world_to_polar(point_at(boundary - 0.001, angle))
			check(before != null and before.ring == outward - 1, "before radial boundary")
			var exact := grid.world_to_polar(point_at(boundary, angle))
			var after := grid.world_to_polar(point_at(boundary + 0.001, angle))
			if outward == 4:
				check(exact == null and after == null, "outer exclusion")
			else:
				check(exact != null and exact.ring == outward and exact.radial_fraction == 0.0, "radial tie outward")
				check(after != null and after.ring == outward, "after radial boundary")
	var origin := grid.world_to_polar(Vector2.ZERO)
	check(origin != null and origin.ring == 0 and origin.wedge == 0 and origin.radial_fraction == 0.0 and origin.angular_fraction == 0.0, "canonical origin")
	check(core.world_to_cell(Vector2(96, 0)) == Vector2i(-1, -1), "core-only outer edge")
	for point in [Vector2(INF, 0), Vector2(0, -INF), Vector2(NAN, 0), Vector2(0, NAN), Vector2(10000, 10000)]:
		check(grid.world_to_polar(point) == null and grid.world_to_cell(point) == Vector2i(-1, -1), "outside/nonfinite")
	check(core.cell_neighbors(Vector2i.ZERO).is_empty(), "isolated core")
	var core_neighbors: Array[Vector2i] = []
	for wedge in range(1, 13):
		core_neighbors.append(Vector2i(1, wedge))
	check(grid.cell_neighbors(Vector2i.ZERO) == core_neighbors, "core neighbor order")
	check(grid.cell_neighbors(Vector2i(1, 1)) == [Vector2i(1, 12), Vector2i(1, 2), Vector2i.ZERO, Vector2i(2, 1)], "inner adjacency order and wrap")
	check(grid.cell_neighbors(Vector2i(2, 12)) == [Vector2i(2, 11), Vector2i(2, 1), Vector2i(1, 12), Vector2i(3, 12)], "middle adjacency order and wrap")
	check(grid.cell_neighbors(Vector2i(3, 6)) == [Vector2i(3, 5), Vector2i(3, 7), Vector2i(2, 6)], "outer adjacency")
	for cell in extended.all_cells():
		for neighbor in extended.cell_neighbors(cell):
			check(extended.cell_neighbors(neighbor).has(cell), "bidirectional adjacency")
		var center := extended.cell_center(cell)
		check(extended.world_to_cell(extended.polar_to_world(center)) == cell, "center round trip")
		if cell.x > 0:
			check(center.radial_fraction == 0.5 and center.angular_fraction == 0.5, "center fractions")
	for ring in [0, 1, 3, 12]:
		for wedge in range(1, 13):
			for fractions in [Vector2(0.17, 0.23), Vector2(0.81, 0.91)]:
				var position := Position.new(ring, 0 if ring == 0 else wedge, fractions.x, float(wedge - 1) / 12 if ring == 0 else fractions.y)
				var recovered := extended.world_to_polar(extended.polar_to_world(position))
				check(recovered != null and extended.is_valid_position(recovered), "valid round trip")
				if recovered != null:
					check(recovered.ring == position.ring and recovered.wedge == position.wedge and absf(recovered.radial_fraction - position.radial_fraction) < 0.000002 and absf(recovered.angular_fraction - position.angular_fraction) < 0.000002, "fraction round trip")
	for cell in [Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 13), Vector2i(4, 1)]:
		check(not grid.is_valid_cell(cell) and grid.cell_center(cell) == null and grid.cell_neighbors(cell).is_empty(), "invalid cell")
	var invalid: Array[PolarPosition] = [null, Position.new(0, 1), Position.new(-1, 0), Position.new(4, 1), Position.new(1, 13), Position.new(0, 0, 0, 0.5)]
	for fraction in [-0.1, 1.0, INF, -INF, NAN]:
		invalid.append(Position.new(1, 1, fraction, 0.5))
		invalid.append(Position.new(1, 1, 0.5, fraction))
	print("EXPECTED DIAGNOSTICS BEGIN: ", invalid.size(), " invalid positions and one negative ring count.")
	for position in invalid:
		check(not grid.is_valid_position(position), "reject malformed position")
		check(grid.polar_to_world(position) == Vector2(INF, INF), "invalid conversion sentinel")
	check(Grid.new(-1).ring_count == 0, "negative ring count fallback")
	print("EXPECTED DIAGNOSTICS END")
	var raw := Position.new(-2, 99, -0.4, 1.5)
	check(raw.ring == -2 and raw.wedge == 99 and raw.radial_fraction == -0.4 and raw.angular_fraction == 1.5, "constructor stores without clamping")
	print("Polar grid: ", checks, " checks, ", failures, " failures.")
	quit(0 if failures == 0 else 1)
