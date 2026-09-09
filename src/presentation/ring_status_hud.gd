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
		_: return Color(0.72, 0.55, 0.32)

func _draw() -> void:
	var radius := CORE_RADIUS + maxi(1, ring_records.size()) * BAND_WIDTH
	var amber := Color("d7aa64")
	var ivory := Color("e6d9bb")
	var housing := Color("0a141d")
	# Dark glass, an engraved bezel and bearing ticks establish an instrument
	# rather than painting the entire clickable annulus as solid status color.
	draw_circle(_center, radius + 3.0, Color(0.012, 0.023, 0.032, 0.94), true, -1.0, true)
	draw_arc(_center, radius + 3.0, 0, TAU, 96, Color("364954"), 1.0, true)
	draw_arc(_center, radius + 1.0, 0, TAU, 96, Color(amber, 0.26), 1.0, true)
	for tick in range(48):
		var turns := float(tick) / 48.0
		var major := tick % 4 == 0
		draw_line(_point(radius + (0.0 if major else 2.0), turns), _point(radius + 5.0, turns), Color(amber if major else ivory, 0.55 if major else 0.16), 1.0, true)
	for wedge in range(1, WEDGE_COUNT + 1):
		var bearing := _turn_bounds(wedge).x
		draw_line(_point(CORE_RADIUS, bearing), _point(radius, bearing), Color("263842"), 1.0, true)
	for index in ring_records.size():
		var record: Dictionary = ring_records[index]
		var inner := CORE_RADIUS + index * BAND_WIDTH
		var outer := inner + BAND_WIDTH - 1.0
		var middle := (inner + outer) * 0.5
		var collapsed: bool = record.get("collapsed", false)
		var wedges: Array = record.get("wedges", [])
		var relay_active: bool = record.get("relay_active", false)
		for wedge in range(1, WEDGE_COUNT + 1):
			var status: String = "collapsed" if collapsed else String(wedges[wedge - 1])
			var color := amber if status == "ok" else (Color("edb955") if status == "critical" else (Color("e3957c") if status == "broken" else Color("52616a")))
			var fill_alpha := 0.045 if status == "ok" else (0.14 if status in ["critical", "broken"] else 0.02)
			draw_colored_polygon(_wedge_polygon(inner, outer, wedge), Color(color, fill_alpha))
			var bounds := _turn_bounds(wedge)
			var inset := minf(0.006, 1.0 / maxf(outer, 1.0))
			var start := (bounds.x + inset) * TAU - PI * 0.5
			var end := (bounds.y - inset) * TAU - PI * 0.5
			var arc_radius := outer - minf(3.0, BAND_WIDTH * 0.18)
			var stroke := clampf(BAND_WIDTH * 0.16, 1.0, 2.2)
			if status in ["broken", "collapsed"]:
				# Interrupted arcs remain legible without relying on fault colors.
				for segment in range(3):
					draw_arc(_center, arc_radius, lerpf(start, end, segment / 3.0), lerpf(start, end, (segment + 0.5) / 3.0), 4, Color(color, 0.7), stroke, true)
			else:
				draw_arc(_center, arc_radius, start, end, 9, Color(color, 0.72 if status == "ok" else 1.0), stroke, true)
			var mark := _point(middle, (bounds.x + bounds.y) * 0.5)
			if status == "broken":
				draw_line(mark + Vector2(-2.0, -2.0), mark + Vector2(2.0, 2.0), ivory, 1.3, true)
				draw_line(mark + Vector2(-2.0, 2.0), mark + Vector2(2.0, -2.0), ivory, 1.3, true)
			elif status == "critical":
				draw_polyline(PackedVector2Array([mark + Vector2(0, -3), mark + Vector2(2.5, 0), mark + Vector2(0, 3), mark + Vector2(-2.5, 0), mark + Vector2(0, -3)]), ivory, 1.2, true)
		if record.get("brownout", false):
			var mark := _point(middle, 0.125)
			draw_circle(mark, 5.0, housing, true, -1.0, true)
			draw_polyline(PackedVector2Array([mark + Vector2(1, -4), mark + Vector2(-2, 0), mark + Vector2(2, 0), mark + Vector2(-1, 4)]), Color("f0bd72"), 1.4, true)
		# A single isolated lamp marks the ring-level relay at north.
		if relay_active and not collapsed:
			var relay := _point(middle, 0.0)
			draw_circle(relay, 3.0, housing, true, -1.0, true)
			draw_circle(relay, 2.1, ivory, false, 1.0, true)
			draw_circle(relay, 0.65, amber, true, -1.0, true)
	# The core is a small contained star glyph with separated reticle brackets.
	draw_circle(_center, CORE_RADIUS - 1.0, housing, true, -1.0, true)
	for quadrant in range(4):
		var angle := quadrant * PI * 0.5
		draw_arc(_center, CORE_RADIUS * 0.76, angle + 0.2, angle + PI * 0.5 - 0.2, 12, Color(amber, 0.58), 1.0, true)
	var glyph := minf(6.0, CORE_RADIUS * 0.25)
	draw_circle(_center, glyph + 3.0, Color(amber, 0.07), true, -1.0, true)
	draw_circle(_center, glyph, Color(amber, 0.2), true, -1.0, true)
	draw_circle(_center, glyph, amber, false, 1.2, true)
	for ray in range(4):
		var bearing := float(ray) * 0.25
		draw_line(_point(glyph + 2.0, bearing), _point(glyph + 4.0, bearing), Color(amber, 0.85), 1.0, true)

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
