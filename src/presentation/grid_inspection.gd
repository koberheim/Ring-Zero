extends Node2D
## Neutral, generated inspection of the authoritative polar grid.
@export var ring_count: int = 3
var grid: PolarGrid
var selected_cell: Vector2i = Vector2i(-1, -1)
var camera: Camera2D
var status_label: Label
var cell_polygons: Array[PackedVector2Array] = []
var cells: Array[Vector2i] = []
var dragging := false
const ARC_STEPS := 12

func _ready() -> void:
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	var overlay := CanvasLayer.new()
	add_child(overlay)
	status_label = Label.new()
	status_label.position = Vector2(16, 16)
	overlay.add_child(status_label)
	rebuild_grid(ring_count)

func rebuild_grid(new_ring_count: int, preserve_view: bool = false) -> void:
	grid = PolarGrid.new(new_ring_count)
	ring_count = grid.ring_count
	if not preserve_view:
		selected_cell = Vector2i(-1, -1)
		dragging = false
	cell_polygons.clear()
	cells = grid.all_cells()
	for cell in cells:
		cell_polygons.append(_polygon_for(cell))
	if not preserve_view:
		camera.position = Vector2.ZERO
		camera.rotation = 0.0
		var viewport_size := get_viewport_rect().size
		var radius := grid.ring_bounds(ring_count).y
		_set_zoom(minf(viewport_size.x, viewport_size.y) * 0.42 / radius)
	camera.force_update_scroll()
	_update_status()
	queue_redraw()

func _polygon_for(cell: Vector2i) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	var bounds := grid.ring_bounds(cell.x)
	if cell.x == 0:
		for step in range(ARC_STEPS * PolarGrid.WEDGE_COUNT):
			var bearing := float(step) / (ARC_STEPS * PolarGrid.WEDGE_COUNT)
			var direction := grid.polar_to_world(PolarPosition.new(0, 0, 0.5, bearing)).normalized()
			polygon.append(direction * bounds.y)
	else:
		for step in range(ARC_STEPS + 1):
			polygon.append(_boundary_direction(cell, step) * bounds.y)
		for step in range(ARC_STEPS, -1, -1):
			polygon.append(_boundary_direction(cell, step) * bounds.x)
	return polygon

func _boundary_direction(cell: Vector2i, step: int) -> Vector2:
	# The excluded clockwise endpoint is the adjacent wedge's included start.
	var wedge := cell.y
	var fraction := float(step) / ARC_STEPS
	if step == ARC_STEPS:
		wedge = wedge % PolarGrid.WEDGE_COUNT + 1
		fraction = 0.0
	return grid.polar_to_world(PolarPosition.new(cell.x, wedge, 0.5, fraction)).normalized()

func _draw() -> void:
	for index in cell_polygons.size():
		var polygon := cell_polygons[index]
		var shade := 0.19 if cells[index].x == 0 else 0.27
		draw_colored_polygon(polygon, Color(shade, shade, shade))
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		draw_polyline(outline, Color(0.57, 0.57, 0.57), 1.0 / camera.zoom.x, true)
	var selected_index := cells.find(selected_cell)
	if selected_index >= 0:
		var outline := cell_polygons[selected_index].duplicate()
		outline.append(outline[0])
		draw_polyline(outline, Color(0.95, 0.95, 0.95), 3.0 / camera.zoom.x, true)

func select_at_world(point: Vector2) -> void:
	selected_cell = grid.world_to_cell(point)
	_update_status()
	queue_redraw()

func _update_status() -> void:
	var selection := "No selection"
	if selected_cell == Vector2i.ZERO:
		selection = "Selected core"
	elif selected_cell.x > 0:
		selection = "Selected ring %d / wedge %d" % [selected_cell.x, selected_cell.y]
	status_label.text = "%s\nLeft: select   Middle drag: pan   Wheel: zoom\nNorth up | %d bands" % [selection, ring_count]

func _set_zoom(value: float) -> void:
	# Numerical limits only; independent of the number of rings.
	if not is_finite(value) or value <= 0.0:
		value = 1.0
	camera.zoom = Vector2.ONE * clampf(value, 1.0e-12, 1.0e12)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			camera.force_update_scroll()
			select_at_world(get_viewport().get_canvas_transform().affine_inverse() * event.position)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera.zoom.x * 1.1)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera.zoom.x / 1.1)
	elif event is InputEventMouseMotion and dragging:
		_set_zoom(camera.zoom.x)
		camera.position -= event.relative / camera.zoom
	camera.rotation = 0.0
	camera.force_update_scroll()
	queue_redraw()
