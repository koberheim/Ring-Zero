class_name RingStatusHud
extends Control
## Persistent, fixed-screen radial overview of wedge integrity across every
## owned ring (D-024 Option A). Independent of the world camera so an
## off-screen failing bearing stays identifiable. Presentation only; reads
## status records supplied by the owning view, never simulation state.

signal wedge_focus_requested(ring: int, wedge: int)

const WEDGE_COUNT := 12
const ARC_STEPS := 4
const MARGIN := 6.0
const CORE_FRACTION := 0.22

var ring_records: Array[Dictionary] = []
var CORE_RADIUS := 10.0
var BAND_WIDTH := 14.0
var _center := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_recompute_scale)
	_recompute_scale()

func _recompute_scale() -> void:
	_center = size * 0.5
	var max_radius: float = maxf(1.0, minf(size.x, size.y) * 0.5 - MARGIN)
	CORE_RADIUS = max_radius * CORE_FRACTION
	var bands: int = maxi(1, ring_records.size())
	BAND_WIDTH = (max_radius - CORE_RADIUS) / bands

func set_status(records: Array[Dictionary]) -> void:
	ring_records = records
	_recompute_scale()
	queue_redraw()

static func _turn_bounds(wedge: int) -> Vector2:
	var mid := float(wedge % WEDGE_COUNT) / WEDGE_COUNT
	return Vector2(mid - 1.0 / 24.0, mid + 1.0 / 24.0)

func _point(radius: float, turns: float) -> Vector2:
	return _center + Vector2(radius * sin(turns * TAU), -radius * cos(turns * TAU))

func _wedge_polygon(inner: float, outer: float, wedge: int) -> PackedVector2Array:
	var bounds := _turn_bounds(wedge)
	var points := PackedVector2Array()
	for step in range(ARC_STEPS + 1):
		points.append(_point(outer, lerpf(bounds.x, bounds.y, float(step) / ARC_STEPS)))
	for step in range(ARC_STEPS, -1, -1):
		points.append(_point(inner, lerpf(bounds.x, bounds.y, float(step) / ARC_STEPS)))
	return points

static func _color_for(status: String) -> Color:
	match status:
		"broken": return Color(0.82, 0.24, 0.2)
		"critical": return Color(0.88, 0.72, 0.2)
		"collapsed": return Color(0.1, 0.1, 0.1)
		_: return Color(0.55, 0.72, 0.85)

func _draw() -> void:
	draw_circle(_center, CORE_RADIUS * 0.6, Color(0.85, 0.85, 0.85))
	for index in ring_records.size():
		var record: Dictionary = ring_records[index]
		var inner := CORE_RADIUS + index * BAND_WIDTH
		var outer := inner + BAND_WIDTH - 1.0
		var collapsed: bool = record.get("collapsed", false)
		var wedges: Array = record.get("wedges", [])
		var relay_active: bool = record.get("relay_active", false)
		for wedge in range(1, WEDGE_COUNT + 1):
			var status: String = "collapsed" if collapsed else String(wedges[wedge - 1])
			var polygon := _wedge_polygon(inner, outer, wedge)
			draw_colored_polygon(polygon, _color_for(status))
			# Symbols carry the broken/critical distinction; color is not the only signal.
			var mark := _point((inner + outer) * 0.5, (_turn_bounds(wedge).x + _turn_bounds(wedge).y) * 0.5)
			if status == "broken":
				draw_line(mark + Vector2(-2, -2), mark + Vector2(2, 2), Color.BLACK, 1.0)
				draw_line(mark + Vector2(-2, 2), mark + Vector2(2, -2), Color.BLACK, 1.0)
			elif status == "critical":
				draw_circle(mark, 1.6, Color.BLACK)
		if record.get("brownout",false):
			var radius := (inner+outer)*0.5
			draw_arc(_center,radius,0.0,PI*0.25,12,Color(1.0,0.72,0.35),2.0)
			var mark := _center + Vector2.from_angle(PI*0.125)*radius
			draw_line(mark+Vector2(-3,-4),mark+Vector2(3,4),Color.BLACK,2.0)
		# D-104: the relay floats within the ring rather than sitting on a
		# wedge, so its marker is a single ring-level indicator, not tied to
		# any wedge's mark position.
		if relay_active and not collapsed:
			draw_circle(_point((inner + outer) * 0.5, 0.0), 2.2, Color.WHITE, false, 1.0)
	for index in range(ring_records.size() + 1):
		draw_arc(_center, CORE_RADIUS + index * BAND_WIDTH, 0, TAU, 48, Color(0.18, 0.18, 0.18), 1.0)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var local: Vector2 = event.position - _center
	var radius := local.length()
	accept_event()
	if radius < CORE_RADIUS:
		wedge_focus_requested.emit(0, 0)
		return
	var ring := int((radius - CORE_RADIUS) / BAND_WIDTH) + 1
	if ring < 1 or ring > ring_records.size():
		return
	var turns := fposmod(atan2(local.x, -local.y) / TAU, 1.0)
	var wedge := int(round(turns * WEDGE_COUNT))
	wedge_focus_requested.emit(ring, WEDGE_COUNT if wedge == 0 else wedge)
