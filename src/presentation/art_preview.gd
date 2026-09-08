extends "res://src/presentation/live_view.gd"
## Experimental presentation only. All input and simulation come from LiveView.
var treatment := 0
var sun_palette := 1
var sun_motion := true
var sun_phase := 0.0
var treatment_selector: Button
var sun_selector: Button
var motion_toggle: CheckButton
var art_toggle: Button
var preview_panel: PanelContainer
var sun_material: ShaderMaterial
var space_material: ShaderMaterial
var sun_surface: Polygon2D
var atmosphere_surface: Polygon2D
var atmosphere_material: ShaderMaterial
var art_grid: PolarGrid
var art_geometry: Array[Dictionary] = []
const SPACE := Color("05070b")
const METAL := Color("39414b")
const RIM := Color("9ca7af")
const WARM := Color("d68d42")
const DANGER := Color("e7654b")
const TEXT := Color("e6e8ec")

func _create_ui() -> void:
	super._create_ui()
	art_toggle = _button("Art settings [F2]", status_label.get_parent(), toggle_art_settings)
	preview_panel = PanelContainer.new()
	preview_panel.position = Vector2(1010, 330)
	preview_panel.custom_minimum_size = Vector2(220, 0)
	status_label.get_parent().add_child(preview_panel)
	var column := VBoxContainer.new()
	preview_panel.add_child(column)
	var title := Label.new()
	title.text = "Art comparison"
	column.add_child(title)
	treatment_selector = _button("Art: Industrial",column,func(): set_treatment((treatment+1)%2))
	treatment_selector.tooltip_text = "Click to switch Industrial / Painterly."
	sun_selector = _button("Sun: Yellow",column,func(): set_sun_palette((sun_palette+1)%3))
	sun_selector.tooltip_text = "Click to cycle Red giant / Yellow / White."
	motion_toggle = CheckButton.new()
	motion_toggle.text = "Sun motion"
	motion_toggle.button_pressed = true
	column.add_child(motion_toggle)
	motion_toggle.toggled.connect(set_sun_motion)
	_button("Close core", column, close_core)
	_button("Strategic view", column, strategic_view)
	preview_panel.hide()
	_layout_ui()

func toggle_art_settings() -> void:
	preview_panel.visible = not preview_panel.visible

func _extra_key(key: Key) -> bool:
	if key == KEY_F2:
		toggle_art_settings()
		return true
	return super._extra_key(key)

func _layout_ui() -> void:
	super._layout_ui()
	var viewport_size := get_viewport_rect().size
	if art_toggle != null:
		art_toggle.position = Vector2(viewport_size.x-172,244)
		art_toggle.size = Vector2(160,28)
	if preview_panel != null:
		preview_panel.position = Vector2(viewport_size.x-232,280)

func _ready() -> void:
	super._ready()
	var backdrop := CanvasLayer.new()
	backdrop.layer = -10
	add_child(backdrop)
	var space := ColorRect.new()
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(space)
	space.size = get_viewport_rect().size
	get_viewport().size_changed.connect(func(): space.size = get_viewport_rect().size)
	space_material = ShaderMaterial.new()
	space_material.shader = load("res://src/presentation/art_preview/space.gdshader")
	space.material = space_material
	sun_surface = Polygon2D.new()
	var extent := PolarGrid.CORE_RADIUS * 1.65
	sun_surface.polygon = PackedVector2Array([Vector2(-extent,-extent),Vector2(extent,-extent),Vector2(extent,extent),Vector2(-extent,extent)])
	sun_surface.uv = PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)])
	var white := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	sun_surface.texture = ImageTexture.create_from_image(white)
	sun_surface.z_index = 1
	sun_material = ShaderMaterial.new()
	sun_material.shader = load("res://src/presentation/art_preview/sun.gdshader")
	sun_surface.material = sun_material
	add_child(sun_surface)
	atmosphere_surface = Polygon2D.new()
	atmosphere_surface.texture = sun_surface.texture
	atmosphere_surface.uv = sun_surface.uv
	atmosphere_material = ShaderMaterial.new()
	atmosphere_material.shader = load("res://src/presentation/art_preview/atmosphere.gdshader")
	atmosphere_surface.material = atmosphere_material
	add_child(atmosphere_surface)
	machine_markers.z_index = 2
	triangle_markers.z_index = 2
	machine_markers.modulate = DANGER
	triangle_markers.modulate = Color("ffca8a")
	set_treatment(treatment)
	set_sun_palette(sun_palette)

func set_treatment(value: int) -> void:
	treatment = clampi(value, 0, 1)
	if treatment_selector != null:
		treatment_selector.text = "Art: " + ["Industrial","Painterly"][treatment]
	if sun_material != null:
		sun_material.set_shader_parameter("painterly", float(treatment))
		space_material.set_shader_parameter("painterly", float(treatment))
		atmosphere_material.set_shader_parameter("enabled", float(treatment))
	queue_redraw()

func set_sun_palette(value: int) -> void:
	sun_palette = clampi(value, 0, 2)
	if sun_selector != null:
		sun_selector.text = "Sun: " + ["Red giant","Yellow","White"][sun_palette]
	if sun_material != null:
		sun_material.set_shader_parameter("palette", sun_palette)

func set_sun_motion(value: bool) -> void:
	sun_motion = value
	if motion_toggle != null:
		motion_toggle.set_pressed_no_signal(value)

func _process(delta: float) -> void:
	super._process(delta)
	if sun_motion and not get_tree().paused:
		sun_phase += delta
	if sun_material != null:
		sun_material.set_shader_parameter("phase", sun_phase)
		space_material.set_shader_parameter("drift", camera.position)

func close_core() -> void:
	camera.position = Vector2.ZERO
	_set_zoom(1.55)
	camera.force_update_scroll()
	queue_redraw()

func strategic_view() -> void:
	camera.position = Vector2.ZERO
	_set_zoom(minf(get_viewport_rect().size.x, get_viewport_rect().size.y) * 0.42 / grid.ring_bounds(ring_count).y)
	camera.force_update_scroll()
	queue_redraw()

func _band_polygon(cell: Vector2i, inset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var bounds := grid.ring_bounds(cell.x)
	for step in range(ARC_STEPS + 1):
		points.append(_boundary_direction(cell, step) * (bounds.y - inset))
	for step in range(ARC_STEPS, -1, -1):
		points.append(_boundary_direction(cell, step) * (bounds.x + inset))
	return points

func _cache_art_geometry() -> void:
	if art_grid == grid:
		return
	art_grid = grid
	art_geometry.clear()
	for index in cells.size():
		var cell := cells[index]
		var item := {"slots": {}, "panels": [], "panel_colors": [], "fasteners": PackedVector2Array()}
		if cell.x > 0:
			item.bounds = grid.ring_bounds(cell.x)
			item.industrial = _band_polygon(cell,5.0)
			item.painterly = _band_polygon(cell,3.0)
			item.industrial_colors = PackedColorArray()
			item.painterly_colors = PackedColorArray()
			for vertex in item.industrial:
				item.industrial_colors.append(METAL)
			for vertex in item.painterly:
				item.painterly_colors.append(Color("25232e").lerp(Color("9e6546"),exp(-vertex.length()/430.0)*0.35))
			item.edge = PackedVector2Array()
			for step in range(ARC_STEPS+1):
				item.edge.append(_boundary_direction(cell,step)*(item.bounds.x+5.0))
			item.center = grid.polar_to_world(grid.cell_center(cell))
			item.seam = grid.polar_to_world(PolarPosition.new(cell.x,cell.y,0.5,0.0)).normalized()
			for section in range(4):
				var panel := PackedVector2Array()
				for step in range(5):
					panel.append(grid.polar_to_world(PolarPosition.new(cell.x,cell.y,0.84,(section+(step/4.0)*0.94+0.03)/4.0)))
				for step in range(4,-1,-1):
					panel.append(grid.polar_to_world(PolarPosition.new(cell.x,cell.y,0.16,(section+(step/4.0)*0.94+0.03)/4.0)))
				item.panels.append(panel)
				var shades := PackedColorArray()
				for vertex in panel:
					shades.append(METAL.lightened(0.08+0.06*float(section%2)).darkened(0.12*(vertex.length()-item.bounds.x)/96.0))
				item.panel_colors.append(shades)
			for fraction in [0.12,0.88]:
				var direction := grid.polar_to_world(PolarPosition.new(cell.x,cell.y,0.5,fraction)).normalized()
				for radius in [item.bounds.x+12,item.bounds.y-12]:
					item.fasteners.append(direction*radius)
		var rect := Rect2(cell_polygons[index][0],Vector2.ZERO)
		for vertex in cell_polygons[index]:
			rect = rect.expand(vertex)
		item.rect = rect
		art_geometry.append(item)
	if atmosphere_surface != null:
		var extent := grid.ring_bounds(ring_count).y
		atmosphere_surface.polygon = PackedVector2Array([Vector2(-extent,-extent),Vector2(extent,-extent),Vector2(extent,extent),Vector2(-extent,extent)])
		atmosphere_material.set_shader_parameter("extent",extent)

func _slot_point(item: Dictionary, cell: Vector2i, slot: int, count: int) -> Vector2:
	var key := Vector2i(slot,count)
	if not item.slots.has(key):
		item.slots[key] = grid.polar_to_world(BuildingRules.slot_position(cell.x,cell.y,slot,count))
	return item.slots[key]

func _draw_board() -> void:
	if camera == null:
		return
	var zoom := camera.zoom.x
	var detailed := zoom >= 0.6
	_cache_art_geometry()
	var world_rect := Rect2(camera.position-get_viewport_rect().size/(2.0*zoom),get_viewport_rect().size/zoom).grow(35.0/zoom)
	var labels: Array[Dictionary] = []
	for index in cells.size():
		var cell := cells[index]
		if cell.x == 0:
			continue
		var item: Dictionary = art_geometry[index]
		if detailed and not world_rect.intersects(item.rect):
			continue
		var polygon := cell_polygons[index]
		var owned := _cell_owned(cell)
		var description := _cell_description(cell)
		var broken := description in ["broken", "collapsed"]
		var fill := METAL if treatment == 0 else Color("25232e")
		if not owned:
			fill = Color(0.04, 0.055, 0.075, 0.45)
		if broken:
			fill = Color("100d13")
		draw_colored_polygon(polygon, fill.darkened(0.4))
		var outline := polygon.duplicate()
		outline.append(polygon[0])
		draw_polyline(outline, Color("59616c") if owned else Color("232b37"), 0.8 / zoom, true)
		if owned and not broken:
			var plate: PackedVector2Array = item.industrial if treatment == 0 else item.painterly
			draw_polygon(plate,item.industrial_colors if treatment == 0 else item.painterly_colors)
			draw_polyline(item.edge, WARM.darkened(0.25) if treatment == 0 else Color("865240"), 1.3 / zoom, true)
			if detailed and treatment == 0:
				for panel_index in item.panels.size():
					var panel: PackedVector2Array = item.panels[panel_index]
					draw_polygon(panel,item.panel_colors[panel_index])
					draw_polyline(panel,Color("555a60"),0.8,true)
				for point in item.fasteners:
					draw_circle(point,1.7,RIM.darkened(0.3))
				draw_line(item.seam*(item.bounds.x+6),item.seam*(item.bounds.y-6),Color("1b222b"),4.0,true)
		if broken:
			var center: Vector2 = item.center
			draw_line(center + Vector2(-5,-5)/zoom, center + Vector2(5,5)/zoom, DANGER, 1.3/zoom, true)
			draw_line(center + Vector2(-5,5)/zoom, center + Vector2(5,-5)/zoom, DANGER, 1.3/zoom, true)
		if cell == selected_cell:
			draw_polyline(outline, TEXT, 2.0 / zoom, true)
		var count := _slot_count(cell.x, cell.y)
		var visible_slots: Array = _visible_board_slots(cell,count)
		for slot in visible_slots:
			var point := _slot_point(item,cell,slot,count)
			var occupant: Dictionary = state.rings[cell.x].wedges[cell.y].occupants.get(slot, {}) if owned else {}
			if occupant.is_empty():
				draw_circle(point, 2.3/zoom, Color("6c747e"), false, 0.8/zoom, true)
			else:
				_draw_occupant(point, occupant.kind, detailed,occupant.get("direction",1))
				if _slot_label_visible(cell,slot,count,BUILDING_NAMES.get(occupant.kind,str(occupant.kind))):
					labels.append({"point":point,"text":BUILDING_NAMES.get(occupant.kind,str(occupant.kind))})
			if cell == selected_cell and slot == selected_slot:
				draw_circle(point, 13.0/zoom, TEXT, false, 1.5/zoom, true)
	for label in labels:
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		draw_set_transform(label.point + Vector2(-width*0.5,24)/zoom,0,Vector2.ONE/zoom)
		draw_string_outline(font,Vector2.ZERO,label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,SPACE)
		draw_string(font,Vector2.ZERO,label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,TEXT)
		draw_set_transform(Vector2.ZERO)

func _draw_occupant(point: Vector2, kind: StringName, detailed: bool, direction: int = 1) -> void:
	var zoom := camera.zoom.x
	if not detailed:
		draw_circle(point, 3.5/zoom, WARM if kind == &"relay" else TEXT)
		return
	# Close silhouettes grow with the world; only strategic markers use fixed pixels.
	draw_set_transform(point, point.angle() + PI * 0.5, Vector2.ONE * clampf(zoom,0.8,2.8) / zoom)
	var body := Color("59616a") if treatment == 0 else Color("38303d")
	draw_rect(Rect2(-8,-8,16,16), SPACE)
	draw_rect(Rect2(-6,-6,12,12), body)
	match kind:
		&"debris_field":
			for fragment in [Vector2(-4,-3),Vector2(4,2),Vector2(-2,5)]:
				draw_rect(Rect2(fragment-Vector2(2,2),Vector2(4,4)),RIM)
		&"tractor_lane":
			draw_line(Vector2(-6,0),Vector2(6,0),WARM,2.0,true)
			draw_line(Vector2(3*direction,-3),Vector2(6*direction,0),WARM,2.0,true)
			draw_line(Vector2(3*direction,3),Vector2(6*direction,0),WARM,2.0,true)
		&"occlusion_screen":
			for x in [-5,0,5]: draw_line(Vector2(x,-6),Vector2(x,6),RIM,2.0,true)
		&"relay":
			draw_circle(Vector2.ZERO,7.0,WARM,false,2.0,true)
			draw_line(Vector2(0,-11),Vector2(0,11),RIM,2.0,true)
		&"emp_node":
			draw_arc(Vector2.ZERO,8.0,0,TAU,24,Color("91b9c4"),2.0,true)
			draw_circle(Vector2.ZERO,3.0,Color("d1e4e9"))
		&"lance_emitter":
			draw_rect(Rect2(-3,-19,6,22),RIM)
			draw_line(Vector2(0,-19),Vector2(0,3),WARM,1.5,true)
		&"point_defense":
			for x in [-4,4]: draw_rect(Rect2(x-1,-13,2,13),RIM)
		&"armor_plating":
			for y in [-4,0,4]: draw_line(Vector2(-6,y),Vector2(6,y),RIM,2.0,true)
		&"repair_node":
			draw_line(Vector2(-5,0),Vector2(5,0),Color("b4d9ca"),3.0,true)
			draw_line(Vector2(0,-5),Vector2(0,5),Color("b4d9ca"),3.0,true)
		_:
			draw_circle(Vector2.ZERO,6.0,body.lightened(0.15))
			draw_rect(Rect2(-2,-16 if kind == &"mass_driver" else -12,4,16),RIM)
	draw_set_transform(Vector2.ZERO)
