extends "res://src/presentation/live_view.gd"
## Production presentation: authoritative polar positions, thin lit hardware.
const TILT := 0.9396926
const WARM := Color("efb66b")
const COLD := Color("9dd9ed")
var heads := {}
var machines := {}
var sun: Sprite2D
var sun_phase := 0.0
var tactical := false
var destruction: Array[Dictionary] = []
var objective: Label
var direction_cache := {}
var arc_cache := {}
var board_canvas: Node2D
var board_stamp: Array = []

func _ready() -> void:
	super._ready()
	board_canvas = Node2D.new()
	board_canvas.z_index = -1
	board_canvas.draw.connect(_render_board)
	add_child(board_canvas)
	for kind in ["flak","mass_driver","emp_node","lance_emitter","point_defense","relay","repair_node","armor_plating"]:
		heads[kind] = load("res://assets/art/buildings/head_%s.png" % kind)
	for kind in ["normal","tunneler","transfer","foundry","sapper","breacher","assembler"]:
		var file: String = "machine_standard" if kind == "normal" else ("assembler" if kind == "assembler" else "elite_"+kind)
		machines[kind] = load("res://assets/art/machines/%s.png" % file)
	machine_markers.hide()
	triangle_markers.hide()
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var space := ColorRect.new()
	space.size = Vector2(1440,810)
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://src/presentation/art_preview/space.gdshader")
	space.material = material
	layer.add_child(space)
	sun = Sprite2D.new()
	var white := Image.create(1,1,false,Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	sun.texture = ImageTexture.create_from_image(white)
	sun.scale = Vector2.ONE * PolarGrid.CORE_RADIUS * 3.3
	sun.scale.y /= TILT
	var solar := ShaderMaterial.new()
	solar.shader = load("res://src/presentation/art_preview/sun.gdshader")
	solar.set_shader_parameter("palette",randi()%3)
	sun.material = solar
	sun.z_index = -2
	add_child(sun)
	objective = Label.new()
	objective.text = "Containment  15:00  /  Ignition"
	objective.position = Vector2(960,770)
	objective.add_theme_color_override("font_color",WARM)
	objective.add_theme_font_size_override("font_size",18)
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label.get_parent().add_child(objective)
	queue_redraw()

func _set_zoom(value: float) -> void:
	super._set_zoom(clampf(value,0.05,4.0))
	camera.zoom.y = camera.zoom.x*TILT

func _input(event: InputEvent) -> void:
	if event is InputEventKey and PCSettings.logical_key(event.physical_keycode) == KEY_ALT:
		tactical = event.pressed
		queue_redraw()
	super._input(event)

func _process(delta: float) -> void:
	super._process(delta)
	_refresh_board_cache()
	if not get_tree().paused:
		if not interface_settings.reduced_motion: sun_phase += minf(delta,0.05)
		for effect in destruction: effect.life -= delta
		destruction = destruction.filter(func(effect): return effect.life > 0)
		camera.offset = Vector2.ZERO
		if not destruction.is_empty() and not interface_settings.reduced_motion:
			var strength: float = minf(1.0,destruction[-1].life)*2.0/camera.zoom.x
			camera.offset = Vector2(sin(sun_phase*71),cos(sun_phase*53))*strength
	if sun != null:
		sun.material.set_shader_parameter("phase",sun_phase)
		var health := clampf(simulation.core_hp/float(profile.value("health.core_hp")),0.2,1.0) if profile != null else 1.0
		var brownout: bool = PowerRules.chain_boundary(state) < state.rings.size()
		var brightness: float = (0.67+0.08*sin(sun_phase*4.0)) if brownout and not interface_settings.reduced_motion else (0.7 if brownout else 1.0)
		sun.modulate = Color(brightness,health*brightness,health*brightness,1.0)
	if objective != null and simulation != null:
		var left := maxi(0,ceili(RunRules.OPERATION_SECONDS-simulation.elapsed_seconds))
		objective.text = "PRACTICE / No rewards" if simulation.run_is_practice else "CONTAINMENT  %02d:%02d  /  %s" % [left/60,left%60,"IGNITION" if left>600 else ("FORTRESS" if left>300 else "LAST WATCH")]
	queue_redraw()

func _simulation_tick(delta: float) -> void:
	super._simulation_tick(delta)
	if simulation != null and not simulation.run_is_practice and simulation.elapsed_seconds >= RunRules.OPERATION_SECONDS:
		clock.paused = true
	if application_host == null or not last_error.is_empty(): return
	var events: Dictionary = simulation.last_events
	if not events.hits.is_empty(): application_host.audio.play("shot")
	if not events.broken_wedges.is_empty() or not events.collapsed_rings.is_empty():
		application_host.audio.play("breach")
		for cell in events.broken_wedges:
			if destruction.size() < 32: destruction.append({"point":grid.polar_to_world(PolarPosition.new(cell.x,cell.y,0.95,0.5)),"life":1.2})

func _record_command(action: String, args: Dictionary, result: Dictionary) -> Dictionary:
	if application_host != null and result.ok: application_host.audio.play("solar" if action == "cast_ability" else "build")
	return super._record_command(action,args,result)

func _arc(cell: Vector2i, radius: float) -> PackedVector2Array:
	var key := Vector3i(cell.x,cell.y,roundi(radius*1000))
	if arc_cache.has(key): return arc_cache[key]
	var points := PackedVector2Array()
	for step in range(ARC_STEPS+1): points.append(_boundary_direction(cell,step)*radius)
	arc_cache[key] = points
	return points

func _boundary_direction(cell: Vector2i, step: int) -> Vector2:
	var key := Vector2i(cell.y,step)
	if not direction_cache.has(key): direction_cache[key] = super._boundary_direction(cell,step)
	return direction_cache[key]

func refresh_view() -> void:
	super.refresh_view()
	for entry in [[flak_button,"Flak"],[mass_driver_button,"Mass Driver"],[emp_node_button,"EMP Node"],[lance_emitter_button,"Lance Emitter"],[point_defense_button,"Point Defense"],[expand_button,"Expand"],[wall_button,"Wall"],[armor_button,"Armor"],[repair_node_button,"Repair Node"],[repair_button,"Repair"],[reclaim_button,"Reclaim"],[relay_button,"Relay"],[debris_field_button,"Debris"],[tractor_lane_button,"Tractor"],[occlusion_screen_button,"Occlusion"],[focused_flare_button,"Flare"],[emp_burst_button,"EMP Burst"]]:
		var button: Button = entry[0]
		if button == null: continue
		if button.text.begins_with("["):
			button.text = "["+PCSettings.label(entry[1])+"]"+button.text.substr(button.text.find("]")+1)
	if menu_button != null: menu_button.text = "Menu ["+PCSettings.label("Pause / cancel")+"]"
	if help_button != null: help_button.text = "Help ["+PCSettings.label("Reference")+"]"

func _draw_board() -> void:
	# Static fortress commands are retained separately from moving combat.
	_refresh_board_cache()

func _refresh_board_cache() -> void:
	if board_canvas == null or camera == null: return
	var stamp: Array = [camera.zoom.x,selected_cell,selected_slot,detail_hover_cell,detail_hover_slot,build_mode,tactical,ring_count]
	for ring in state.get("rings",{}):
		var record: Dictionary = state.rings[ring]
		stamp.append(record.get("collapsed",false))
		stamp.append(record.get("relay_hp",0)>0)
		for plate in record.wedges.values():
			stamp.append(ceili(plate.hp/plate.max_hp*12.0))
			stamp.append(plate.occupants.hash())
	if tactical or stamp != board_stamp:
		board_stamp = stamp
		board_canvas.queue_redraw()

func _render_board() -> void:
	if camera == null: return
	var zoom := camera.zoom.x
	var draws: Array[Dictionary] = []
	for ring in state.get("rings",{}):
		var record: Dictionary = state.rings[ring]
		if record.get("collapsed",false): continue
		var relay_point := _boundary_direction(Vector2i(ring,1),0)*(grid.ring_bounds(ring).y-18)
		board_canvas.draw_set_transform(relay_point,relay_point.angle()+PI/2)
		if heads.has("relay"): board_canvas.draw_texture_rect(heads.relay,Rect2(-14,-14,28,28),false,Color.WHITE if record.get("relay_hp",0)>0 else Color("32363b"))
		board_canvas.draw_set_transform(Vector2.ZERO)
	for cell in cells:
		if cell.x == 0: continue
		var bounds := grid.ring_bounds(cell.x)
		var owned := _cell_owned(cell)
		var intact := owned and _cell_description(cell) not in ["broken","collapsed"]
		var outer := _arc(cell,bounds.y)
		if intact:
			var plate: Dictionary = state.rings[cell.x].wedges[cell.y]
			var health := clampf(float(plate.hp)/float(plate.max_hp),0,1)
			var shadow := outer.duplicate()
			for index in shadow.size(): shadow[index] += Vector2(0,5)
			board_canvas.draw_polyline(shadow,Color("0d1117"),15.0,true)
			board_canvas.draw_polyline(outer,Color("343d47"),12.0,true)
			board_canvas.draw_polyline(_arc(cell,bounds.y-5),Color("8c8171"),2.0,true)
			if zoom >= 0.5: board_canvas.draw_polyline(_arc(cell,bounds.y+4),Color("101820"),2.0,true)
			for step in range(1,ARC_STEPS,2) if zoom >= 0.5 else []:
				var direction := _boundary_direction(cell,step)
				board_canvas.draw_line(direction*(bounds.y-5),direction*(bounds.y+5),Color("17212b"),2)
				if health > float(step)/ARC_STEPS: board_canvas.draw_circle(direction*(bounds.y-1),1.8,WARM)
			for boundary in [0,ARC_STEPS]:
				var start := _boundary_direction(cell,boundary)
				var tangent := Vector2(-start.y,start.x)*2.0
				for side in [-1,1]: board_canvas.draw_line(start*bounds.x+tangent*side,start*bounds.y+tangent*side,Color("53606b"),1.5)
				for step in 6 if zoom >= 0.5 else 0:
					var radius := lerpf(bounds.x,bounds.y,float(step)/6)
					board_canvas.draw_line(start*radius-tangent,start*(radius+16)+tangent,Color("343f48"),1)
			if tactical:
				var point := _boundary_direction(cell,6)*(bounds.y-14)
				board_canvas.draw_line(point-Vector2(12,0)/zoom,point+Vector2(12,0)/zoom,Color("202833"),4/zoom)
				board_canvas.draw_line(point-Vector2(12,0)/zoom,point+Vector2(24*health-12,0)/zoom,WARM if health>0.3 else Color("ff6555"),3/zoom)
		elif cell == selected_cell or (build_mode != &"" and cell.x == state.rings.size()+1):
			board_canvas.draw_polyline(outer,Color("43505d"),1/zoom,true)
		if cell == selected_cell or cell == detail_hover_cell:
			board_canvas.draw_polyline(outer,WARM if cell == selected_cell else Color("70828c"),2/zoom,true)
		if not intact: continue
		var count := _slot_count(cell.x,cell.y)
		for slot in _visible_board_slots(cell,count):
			var point := grid.polar_to_world(BuildingRules.slot_position(cell.x,cell.y,slot,count))
			var occupant: Dictionary = state.rings[cell.x].wedges[cell.y].occupants.get(slot,{})
			if occupant.is_empty():
				if build_mode != &"" or tactical: board_canvas.draw_circle(point,4/zoom,Color("65717a"),false,1/zoom)
			else:
				board_canvas.draw_line(point,point.normalized()*bounds.y,Color("46515a"),5)
				draws.append({"point":point,"kind":String(occupant.kind),"direction":occupant.get("direction",1),"cell":cell})
				if tactical and occupant.kind == &"occlusion_screen":
					var far := bounds.y+PolarGrid.RING_WIDTH*float(profile.value("occlusion_screen.shadow_rings"))
					var zone := _arc(cell,bounds.y).duplicate()
					var edge := _arc(cell,far).duplicate()
					edge.reverse()
					zone.append_array(edge)
					board_canvas.draw_colored_polygon(zone,Color(0.35,0.5,0.55,0.08))
					zone.append(zone[0])
					board_canvas.draw_polyline(zone,Color(0.5,0.65,0.7,0.5),1/zoom)
				if tactical and occupant.kind in [&"flak",&"mass_driver",&"lance_emitter"] and cell == selected_cell and slot == selected_slot:
					var radius := float(profile.value(String(occupant.kind)+".range_ring_widths"))*PolarGrid.RING_WIDTH
					var arc := deg_to_rad(float(profile.value(String(occupant.kind)+".arc_degrees")))
					board_canvas.draw_arc(point,radius,point.angle()-arc/2,point.angle()+arc/2,48,Color(WARM,0.45),1/zoom,true)
			if _detail_slot(cell,slot): board_canvas.draw_circle(point,11/zoom,WARM,false,1.5/zoom)
	# Painter's order preserves the visible height of the authored hardware.
	draws.sort_custom(func(a,b): return a.point.y < b.point.y)
	for item in draws:
		var point: Vector2 = item.point
		var kind: String = item.kind
		board_canvas.draw_set_transform(point,point.angle()+PI/2)
		board_canvas.draw_rect(Rect2(-12,-12,24,24),Color("11191f"))
		board_canvas.draw_rect(Rect2(-10,-10,20,20),Color("626365"),false,1.5)
		if heads.has(kind): board_canvas.draw_texture_rect(heads[kind],Rect2(-22,-25,44,44),false)
		else: _terrain_hardware(kind,int(item.direction))
		board_canvas.draw_set_transform(Vector2.ZERO)
		if tactical or zoom > 1.4:
			board_canvas.draw_set_transform(point+Vector2(0,24)/zoom,0,Vector2(1,1/TILT)/zoom)
			board_canvas.draw_string(ThemeDB.fallback_font,Vector2.ZERO,BUILDING_NAMES.get(StringName(kind),kind),HORIZONTAL_ALIGNMENT_LEFT,-1,12,WARM)
			board_canvas.draw_set_transform(Vector2.ZERO)

func _terrain_hardware(kind: String, direction: int) -> void:
	if kind == "debris_field":
		for index in 5: board_canvas.draw_rect(Rect2(Vector2(-16+index*6,-8+(index%2)*9),Vector2(5,7)),Color("64666a"))
	elif kind == "tractor_lane":
		for index in 3:
			var x := float(index*9-9)*direction
			board_canvas.draw_polyline(PackedVector2Array([Vector2(x-4*direction,-7),Vector2(x,0),Vector2(x-4*direction,7)]),Color("88a4ac"),2,true)
	else:
		board_canvas.draw_rect(Rect2(-15,-5,30,10),Color("747e82"))
		board_canvas.draw_line(Vector2(-13,-6),Vector2(13,-6),WARM,2)

func _draw_combat_feedback() -> void:
	var zoom := camera.zoom.x
	for effect in hit_effects:
		var color := Color(WARM,clampf(effect.remaining/0.2,0,1))
		match effect.kind:
			&"emp_node": draw_circle(effect.to,(1-effect.remaining/0.2)*20/zoom,color,false,1.5/zoom)
			&"lance_emitter":
				draw_line(effect.from,effect.to,Color(color,0.15),7/zoom)
				draw_line(effect.from,effect.to,color,2/zoom)
			&"flak":
				draw_line(effect.from,effect.to,color,1/zoom)
				draw_circle(effect.to,4/zoom,color,false,1/zoom)
			_: draw_line(effect.from,effect.to,color,1/zoom)
	for index in rendered_targets.size():
		var target: Dictionary = rendered_targets[index]
		if target.get("phase") == &"burrowing": continue
		var kind := String(target.get("kind","normal"))
		if kind in ["","standard"]: kind = "normal"
		var point: Vector2 = target_points[index]
		var width := (34.0 if kind == "assembler" else (21.0 if kind == "foundry" else 15.0))
		width = maxf(width,(4.0 if kind == "normal" else 9.0)/zoom)
		draw_set_transform(point,point.angle()-PI/2)
		if machines.has(kind): draw_texture_rect(machines[kind],Rect2(-width/2,-width/2,width,width),false)
		# Distinct non-color glyphs retain family identification at strategic scale.
		if kind != "normal":
			var radius := maxf(width*0.55,6/zoom)
			var sides: int = {"tunneler":3,"transfer":4,"foundry":6,"sapper":5,"breacher":3,"assembler":8}.get(kind,4)
			var outline := PackedVector2Array()
			for side in range(sides+1): outline.append(Vector2.from_angle(TAU*side/sides)*radius)
			draw_polyline(outline,Color(COLD,0.75),1/zoom,true)
			if kind == "breacher": draw_line(Vector2(-radius,0),Vector2(radius,0),COLD,1/zoom)
		draw_set_transform(Vector2.ZERO)
	if not interface_settings.reduced_motion:
		for effect in destruction:
			var age: float = 1.2-effect.life
			for index in 8:
				var point: Vector2 = effect.point+Vector2.from_angle(index*TAU/8)*age*35
				draw_line(point,point+Vector2(3,4),Color(WARM,effect.life/1.2),2)
