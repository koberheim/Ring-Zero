extends SceneTree

var _failures := 0
var _checks := 0
var _checksum := 0.0

func _initialize() -> void:
	_examples()
	_invalid()
	_reference()
	_directed()
	_reference(true)
	if _failures == 0:
		_benchmark()
	print("polar_route_field: %s" % ("PASS" if _failures == 0 else "FAIL (%d)" % _failures))
	print("route field checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)

func _edge(a: Vector2i, b: Vector2i, cost: float) -> Dictionary:
	return {"a": a, "b": b, "cost": cost}

func _examples() -> void:
	var grid := PolarGrid.new(2)
	var core := Vector2i.ZERO
	var a := Vector2i(1, 1)
	var seam := Vector2i(1, 12)
	var outer := Vector2i(2, 1)
	var isolated := Vector2i(2, 6)
	var cells: Array[Vector2i] = [core, a, seam, outer, isolated]
	var edges: Array[Dictionary] = [_edge(core, a, 10), _edge(core, seam, 1), _edge(seam, a, 2), _edge(a, outer, 3)]
	var built := PolarRouteField.build(grid, cells, edges, [core])
	_check(built.ok, "weighted field builds")
	if not built.ok:
		return
	var field: PolarRouteField = built.field
	_check(field.distance_for(outer) == 6 and field.next_cell(outer) == a, "outer inward neighbor")
	_check(field.distance_for(a) == 3 and field.next_cell(a) == seam, "weighted angular seam detour")
	_check(field.next_cell(core) == core and field.goal_for(core) == core and field.distance_for(core) == 0, "core goal")
	_check(field.distance_for(isolated) == INF and field.next_cell(isolated) == Vector2i(-1, -1), "isolated")
	_check(field.distance_for(Vector2i(9, 9)) == INF and field.goal_for(Vector2i(9, 9)) == Vector2i(-1, -1), "unlisted")
	var outward := PolarRouteField.build(grid, cells, edges, [outer])
	_check(outward.ok and outward.field.next_cell(a) == outer, "outward route")
	edges[0].cost = 0.5
	var rebuilt := PolarRouteField.build(grid, cells, edges, [core])
	_check(rebuilt.ok and rebuilt.field.distance_for(a) == 0.5 and field.distance_for(a) == 3, "immutable old snapshot after rebuild")
	cells.clear()
	edges.clear()
	_check(field.distance_for(outer) == 6, "caller containers not retained")
	_check(PolarRouteField.build(grid, [], [], []).ok, "empty graph valid")
	var no_goals := PolarRouteField.build(grid, [core], [], [])
	_check(no_goals.ok and no_goals.field.distance_for(core) == INF, "empty goals no routes")
	var tie_cells: Array[Vector2i] = [core, Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]
	var tie_edges: Array[Dictionary] = [_edge(core, Vector2i(1, 1), 1), _edge(core, Vector2i(1, 3), 1), _edge(Vector2i(1, 1), Vector2i(1, 2), 1), _edge(Vector2i(1, 3), Vector2i(1, 2), 1)]
	var tie_goals: Array[Vector2i] = [Vector2i(1, 3), Vector2i(1, 1)]
	for permutation in range(8):
		# Seeded shuffles avoid reliance on global RNG state.
		_shuffle(tie_cells, permutation + 1)
		_shuffle(tie_edges, permutation + 10)
		_shuffle(tie_goals, permutation + 20)
		var multiple := PolarRouteField.build(grid, tie_cells, tie_edges, tie_goals)
		_check(multiple.ok and multiple.field.goal_for(core) == Vector2i(1, 1) and multiple.field.goal_for(Vector2i(1, 2)) == Vector2i(1, 1), "lowest exact-tie goal shuffled")
		var single := PolarRouteField.build(grid, tie_cells, tie_edges, [core])
		_check(single.ok and single.field.next_cell(Vector2i(1, 2)) == Vector2i(1, 1), "lowest exact-tie next cell shuffled")
		for goal in tie_goals:
			_check(multiple.field.next_cell(goal) == goal, "every goal self resolves")
	# A tiny real difference must not be treated as a tie.
	var precise_edges: Array[Dictionary] = [_edge(core, Vector2i(1, 1), 1.0 + 1.0e-10), _edge(core, Vector2i(1, 3), 1.0)]
	var precise := PolarRouteField.build(grid, tie_cells, precise_edges, tie_goals)
	_check(precise.ok and precise.field.goal_for(core) == Vector2i(1, 3), "no approximate tie")

func _invalid() -> void:
	var grid := PolarGrid.new(2)
	var core := Vector2i.ZERO
	var a := Vector2i(1, 1)
	var cells: Array[Vector2i] = [core, a, Vector2i(2, 1)]
	_rejected(PolarRouteField.build(null, [], [], []), "null grid")
	_rejected(PolarRouteField.build(grid, [core, core], [], []), "duplicate cells")
	_rejected(PolarRouteField.build(grid, [Vector2i(1, 0)], [], []), "invalid cell")
	_rejected(PolarRouteField.build(grid, cells, [], [core, core]), "duplicate goals")
	_rejected(PolarRouteField.build(grid, cells, [], [Vector2i(1, 2)]), "unlisted goal")
	_rejected(PolarRouteField.build(grid, cells, [], [Vector2i(-1, -1)]), "invalid goal")
	for cost in [0, -1, INF, NAN, true, "1", null]:
		_rejected(PolarRouteField.build(grid, cells, [{"a": core, "b": a, "cost": cost}], [core]), "invalid cost")
	for edge in [{}, {"a": core, "b": a}, {"a": core, "b": a, "cost": 1, "extra": 1}, {"a": "core", "b": a, "cost": 1}, {"a": core, "b": Vector2(1, 1), "cost": 1}, _edge(core, core, 1), _edge(core, Vector2i(1, 2), 1), _edge(core, Vector2i(2, 1), 1)]:
		_rejected(PolarRouteField.build(grid, cells, [edge], [core]), "malformed or illegal edge")
	_rejected(PolarRouteField.build(grid, cells, [_edge(core, a, 1), _edge(a, core, 2)], [core]), "reverse duplicate")
	_rejected(PolarRouteField.build(grid, cells, [_edge(core, a, 1.0e308), _edge(a, Vector2i(2, 1), 1.0e308)], [core]), "distance overflow")
	_rejected(PolarRouteField.build(grid, cells, [_edge(core, a, 1.0e20), _edge(a, Vector2i(2, 1), 1.0)], [core]), "cost rounds away")

func _rejected(result: Dictionary, label: String) -> void:
	_check(not result.ok and result.field == null and not result.errors.is_empty(), label)

func _shuffle(items: Array, seed_value: int) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for index in range(items.size() - 1, 0, -1):
		var other := random.randi_range(0, index)
		var swap = items[index]
		items[index] = items[other]
		items[other] = swap

func _graph(rings: int) -> Dictionary:
	var grid := PolarGrid.new(rings)
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	for ring in range(1, rings + 1):
		for wedge in range(1, 13):
			cells.append(Vector2i(ring, wedge))
	var edges: Array[Dictionary] = []
	for cell in cells:
		for neighbor in grid.cell_neighbors(cell):
			if cell.x < neighbor.x or (cell.x == neighbor.x and cell.y < neighbor.y):
				# Integer costs keep independent sum comparisons exact.
				var cost := 1 + (cell.x * 7 + cell.y * 3 + neighbor.x * 11 + neighbor.y) % 9
				edges.append(_edge(cell, neighbor, cost))
	return {"grid": grid, "cells": cells, "edges": edges}

func _directed() -> void:
	var grid := PolarGrid.new(2)
	var core := Vector2i.ZERO
	var a := Vector2i(1, 1)
	var b := Vector2i(1, 2)
	var c := Vector2i(1, 3)
	var cells: Array[Vector2i] = [core, a, b, c]
	var edges: Array[Dictionary] = [_edge(a, core, 2), _edge(b, a, 3)]
	var toward := PolarRouteField.build(grid, cells, edges, [core], true)
	_check(toward.ok and toward.field.distance_for(b) == 5 and toward.field.next_cell(b) == a and toward.field.next_cell(a) == core, "one-way incoming search reaches goal")
	var reverse := PolarRouteField.build(grid, cells, edges, [b], true)
	_check(reverse.ok and reverse.field.distance_for(a) == INF and reverse.field.distance_for(core) == INF and reverse.field.next_cell(core) == Vector2i(-1, -1), "missing reverse edge never traversed")
	var reciprocal: Array[Dictionary] = [_edge(a, core, 2), _edge(core, a, 7)]
	var inward := PolarRouteField.build(grid, cells, reciprocal, [core], true)
	var outward := PolarRouteField.build(grid, cells, reciprocal, [a], true)
	_check(inward.ok and outward.ok and inward.field.distance_for(a) == 2 and outward.field.distance_for(core) == 7, "reciprocal unequal ordered costs")
	edges.append(_edge(core, b, 4))
	var cycle := PolarRouteField.build(grid, cells, edges, [b], true)
	_check(cycle.ok and cycle.field.distance_for(a) == 6 and cycle.field.next_cell(a) == core and cycle.field.next_cell(core) == b and cycle.field.next_cell(b) == b, "directed cycle produces acyclic goal chain")
	var tie_edges: Array[Dictionary] = [_edge(b, a, 1), _edge(b, c, 1), _edge(a, core, 1), _edge(c, core, 1)]
	var goals: Array[Vector2i] = [c, a]
	for seed_value in range(8):
		_shuffle(cells, seed_value + 1)
		_shuffle(tie_edges, seed_value + 10)
		_shuffle(goals, seed_value + 20)
		var tied := PolarRouteField.build(grid, cells, tie_edges, goals, true)
		_check(tied.ok and tied.field.goal_for(b) == a and tied.field.next_cell(b) == a, "directed exact goal tie shuffled")
		var single := PolarRouteField.build(grid, cells, tie_edges, [core], true)
		_check(single.ok and single.field.distance_for(b) == 2 and single.field.next_cell(b) == a, "directed exact next tie shuffled")
	_rejected(PolarRouteField.build(grid, cells, [_edge(a, core, 1), _edge(a, core, 2)], [core], true), "duplicate ordered edge rejected")
	_rejected(PolarRouteField.build(grid, cells, reciprocal, [core]), "legacy reciprocal duplicate still rejected")
	for invalid_cost in [0.0, -1.0, INF, NAN]:
		_rejected(PolarRouteField.build(grid, cells, [_edge(a, core, invalid_cost)], [core], true), "directed invalid cost")
	_rejected(PolarRouteField.build(grid, cells, [_edge(a, core, 1.0e308), _edge(b, a, 1.0e308)], [core], true), "directed overflow")
	_rejected(PolarRouteField.build(grid, cells, [_edge(a, core, 1.0e20), _edge(b, a, 1.0)], [core], true), "directed precision loss")
	var explicit_false := PolarRouteField.build(grid, cells, tie_edges, [core], false)
	var implicit_false := PolarRouteField.build(grid, cells, tie_edges, [core])
	for cell in cells:
		_check(explicit_false.ok and implicit_false.ok and explicit_false.field.distance_for(cell) == implicit_false.field.distance_for(cell) and explicit_false.field.next_cell(cell) == implicit_false.field.next_cell(cell) and explicit_false.field.goal_for(cell) == implicit_false.field.goal_for(cell), "four-argument default unchanged")

func _reference(directed: bool = false) -> void:
	var graph := _graph(2)
	if directed:
		# Keep some arcs one-way; others get distinct reverse costs.
		var original_edges: Array = graph.edges.duplicate()
		for index in range(original_edges.size()):
			if index % 3 != 0:
				var edge: Dictionary = original_edges[index]
				graph.edges.append(_edge(edge.b, edge.a, edge.cost + 2))
	var cells: Array[Vector2i] = graph.cells
	var goals: Array[Vector2i] = [Vector2i(2, 7), Vector2i.ZERO, Vector2i(1, 3)]
	# Independent Floyd-Warshall all-pairs reference, no production heap/helpers.
	var distances: Array = []
	var edge_costs: Dictionary = {}
	for i in range(cells.size()):
		var row: Array[float] = []
		for j in range(cells.size()):
			row.append(0.0 if i == j else INF)
		distances.append(row)
	for edge in graph.edges:
		var a := cells.find(edge.a)
		var b := cells.find(edge.b)
		distances[a][b] = edge.cost
		edge_costs[Vector4i(edge.a.x, edge.a.y, edge.b.x, edge.b.y)] = edge.cost
		if not directed:
			distances[b][a] = edge.cost
			edge_costs[Vector4i(edge.b.x, edge.b.y, edge.a.x, edge.a.y)] = edge.cost
	for k in range(cells.size()):
		for i in range(cells.size()):
			for j in range(cells.size()):
				distances[i][j] = minf(distances[i][j], distances[i][k] + distances[k][j])
	var result := PolarRouteField.build(graph.grid, cells, graph.edges, goals, directed)
	_check(result.ok, "reference graph builds")
	if not result.ok:
		return
	for index in range(cells.size()):
		var expected := INF
		var expected_goal := Vector2i(-1, -1)
		for goal in goals:
			var candidate: float = distances[index][cells.find(goal)]
			if candidate < expected or (candidate == expected and (goal.x < expected_goal.x or (goal.x == expected_goal.x and goal.y < expected_goal.y))):
				expected = candidate
				expected_goal = goal
		_check(result.field.distance_for(cells[index]) == expected and result.field.goal_for(cells[index]) == expected_goal, "Floyd-Warshall distance and goal")
		if not is_finite(expected):
			_check(result.field.next_cell(cells[index]) == Vector2i(-1, -1), "reference unreachable sentinel")
			continue
		var cursor := cells[index]
		var visited: Dictionary = {}
		var sum := 0.0
		while cursor != expected_goal and not visited.has(cursor):
			visited[cursor] = true
			var next: Vector2i = result.field.next_cell(cursor)
			var key := Vector4i(cursor.x, cursor.y, next.x, next.y)
			_check(edge_costs.has(key), "next is supplied edge")
			sum += edge_costs.get(key, INF)
			cursor = next
		_check(cursor == expected_goal and sum == expected, "acyclic chain reaches goal with exact summed cost")

func _benchmark() -> void:
	var graph := _graph(100)
	var build_times: Array[int] = []
	var query_times: Array[int] = []
	for sample in range(13):
		var started := Time.get_ticks_usec()
		var result := PolarRouteField.build(graph.grid, graph.cells, graph.edges, [Vector2i.ZERO])
		var duration := Time.get_ticks_usec() - started
		_check(result.ok, "benchmark build")
		if not result.ok:
			return
		started = Time.get_ticks_usec()
		for cell in graph.cells:
			_checksum += result.field.distance_for(cell)
			_checksum += result.field.next_cell(cell).x
			_checksum += result.field.goal_for(cell).y
		var query_duration := Time.get_ticks_usec() - started
		if sample >= 3:
			build_times.append(duration)
			query_times.append(query_duration)
	build_times.sort()
	query_times.sort()
	print("route benchmark: headless rings=100 cells=%d edges=%d warmups=3 samples=10" % [graph.cells.size(), graph.edges.size()])
	print("build median_us=%.1f p90_us=%d max_us=%d" % [(build_times[4] + build_times[5]) / 2.0, build_times[8], build_times[9]])
	print("all-cell three-query sweep median_us=%.1f p90_us=%d max_us=%d checksum=%.1f" % [(query_times[4] + query_times[5]) / 2.0, query_times[8], query_times[9], _checksum])
