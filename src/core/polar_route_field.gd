class_name PolarRouteField
extends RefCounted
## Immutable snapshot by convention; rebuild before movement after graph changes.

const MISSING := Vector2i(-1, -1)
var _distances: Dictionary = {}
var _next: Dictionary = {}
var _goals: Dictionary = {}

static func build(grid: PolarGrid, cells: Array[Vector2i], edges: Array[Dictionary], goals: Array[Vector2i], directed: bool = false) -> Dictionary:
	var errors := PackedStringArray()
	if grid == null:
		return _failure("Grid must not be null.")
	var graph: Dictionary = {}
	for cell in cells:
		if not grid.is_valid_cell(cell) or graph.has(cell):
			return _failure("Cells must be unique valid grid cells.")
		graph[cell] = []
	var goal_set: Dictionary = {}
	for goal in goals:
		if not graph.has(goal) or goal_set.has(goal):
			return _failure("Goals must be unique traversable cells.")
		goal_set[goal] = true
	var pairs: Dictionary = {}
	for edge in edges:
		if edge.size() != 3 or not edge.has("a") or not edge.has("b") or not edge.has("cost"):
			return _failure("Edges require exactly a, b, and cost.")
		if not edge.a is Vector2i or not edge.b is Vector2i:
			return _failure("Edge endpoints must be Vector2i cells.")
		if not (edge.cost is int or edge.cost is float) or not is_finite(float(edge.cost)) or float(edge.cost) <= 0.0:
			return _failure("Edge cost must be finite and positive.")
		var a: Vector2i = edge.a
		var b: Vector2i = edge.b
		if a == b or not graph.has(a) or not graph.has(b) or not grid.cell_neighbors(a).has(b):
			return _failure("Edge endpoints must be listed, distinct grid neighbors.")
		var low := a if _cell_less(a, b) else b
		var high := b if low == a else a
		var key := Vector4i(a.x, a.y, b.x, b.y) if directed else Vector4i(low.x, low.y, high.x, high.y)
		if pairs.has(key):
			return _failure("Duplicate directed edge." if directed else "Duplicate undirected edge.")
		pairs[key] = true
		# Search outward from goals along incoming edges: a -> b means that
		# knowing b's distance lets a route through b at this supplied cost.
		if not directed:
			graph[a].append({"cell": b, "cost": float(edge.cost)})
		graph[b].append({"cell": a, "cost": float(edge.cost)})
	var field := PolarRouteField.new()
	var heap: Array[Dictionary] = []
	for goal in goals:
		field._distances[goal] = 0.0
		field._next[goal] = goal
		field._goals[goal] = goal
		_heap_push(heap, {"distance": 0.0, "goal": goal, "cell": goal})
	while not heap.is_empty():
		var entry := _heap_pop(heap)
		var cell: Vector2i = entry.cell
		if entry.distance != field.distance_for(cell) or entry.goal != field.goal_for(cell):
			continue
		for neighbor in graph[cell]:
			var candidate: float = entry.distance + neighbor.cost
			if not is_finite(candidate):
				return _failure("Accumulated route distance is nonfinite.")
			if candidate <= float(entry.distance):
				return _failure("Route cost is too small to increase the accumulated distance at float precision.")
			var destination: Vector2i = neighbor.cell
			if goal_set.has(destination):
				continue
			var previous := field.distance_for(destination)
			var better := candidate < previous
			if candidate == previous:
				better = _cell_less(entry.goal, field.goal_for(destination)) or (entry.goal == field.goal_for(destination) and _cell_less(cell, field.next_cell(destination)))
			if better:
				field._distances[destination] = candidate
				field._next[destination] = cell
				field._goals[destination] = entry.goal
				_heap_push(heap, {"distance": candidate, "goal": entry.goal, "cell": destination})
	return {"ok": true, "field": field, "errors": errors}

func distance_for(cell: Vector2i) -> float:
	return _distances.get(cell, INF)

func next_cell(cell: Vector2i) -> Vector2i:
	return _next.get(cell, MISSING)

func goal_for(cell: Vector2i) -> Vector2i:
	return _goals.get(cell, MISSING)

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "field": null, "errors": PackedStringArray([message])}

static func _cell_less(a: Vector2i, b: Vector2i) -> bool:
	return a.x < b.x or (a.x == b.x and a.y < b.y)

static func _entry_less(a: Dictionary, b: Dictionary) -> bool:
	if a.distance != b.distance:
		return a.distance < b.distance
	if a.goal != b.goal:
		return _cell_less(a.goal, b.goal)
	return _cell_less(a.cell, b.cell)

static func _heap_push(heap: Array[Dictionary], entry: Dictionary) -> void:
	heap.append(entry)
	var index := heap.size() - 1
	while index > 0:
		var parent := (index - 1) / 2
		if not _entry_less(heap[index], heap[parent]):
			break
		var swap := heap[parent]
		heap[parent] = heap[index]
		heap[index] = swap
		index = parent

static func _heap_pop(heap: Array[Dictionary]) -> Dictionary:
	var result := heap[0]
	var last: Dictionary = heap.pop_back()
	if heap.is_empty():
		return result
	heap[0] = last
	var index := 0
	while index * 2 + 1 < heap.size():
		var child := index * 2 + 1
		if child + 1 < heap.size() and _entry_less(heap[child + 1], heap[child]):
			child += 1
		if not _entry_less(heap[child], heap[index]):
			break
		var swap := heap[index]
		heap[index] = heap[child]
		heap[child] = swap
		index = child
	return result
