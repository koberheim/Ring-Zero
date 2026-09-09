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
const CollapseFeedback = preload("res://src/presentation/effects/collapse_feedback.gd")
var collapse_feedback := CollapseFeedback.new()
var collapse_simulation: LiveSimulation
var objective: Label
var direction_cache := {}
var arc_cache := {}
var board_canvas: Node2D
var board_viewport: SubViewport
var board_sprite: Sprite2D
var board_redraw_count := 0
var board_cache_full := false
var board_stamp: Array = []
var band_meshes := {}
var band_textures: Array[Texture2D] = []
var mount: Texture2D
var terrain_textures := {}
var space: ColorRect
var wall_texture: Texture2D
var world_font: Font
const FortressLighting = preload("res://src/presentation/lighting/fortress_lighting.gd")
var material_viewport: SubViewport
var material_canvas: Node2D
var core_response: ShaderMaterial
var world_environment: WorldEnvironment
var lighting_enabled := true
var material_redraw_count := 0

func _ready() -> void:
	super._ready()
	# Retaining CanvasItem commands still resubmits thousands of industrial
	# detail draws every frame. Cache their raster at the native viewport size;
	# camera, damage, selection and build changes invalidate it immediately.
	board_viewport = SubViewport.new()
	board_viewport.disable_3d = true
	board_viewport.use_hdr_2d = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	board_viewport.transparent_bg = true
	board_viewport.world_2d = World2D.new()
	board_viewport.size = Vector2i(get_viewport_rect().size)
	board_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(board_viewport)
	board_canvas = Node2D.new()
	board_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	board_canvas.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	board_canvas.draw.connect(_render_board)
	board_viewport.add_child(board_canvas)
	board_sprite = Sprite2D.new()
	board_sprite.texture = board_viewport.get_texture()
	board_sprite.centered = false
	board_sprite.z_index = -1
	board_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(board_sprite)
	material_viewport = SubViewport.new()
	material_viewport.disable_3d = true
	material_viewport.use_hdr_2d = board_viewport.use_hdr_2d
	material_viewport.transparent_bg = true
	material_viewport.world_2d = World2D.new()
	material_viewport.size = board_viewport.size
	material_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(material_viewport)
	material_canvas = Node2D.new()
	material_canvas.texture_filter = board_canvas.texture_filter
	material_canvas.texture_repeat = board_canvas.texture_repeat
	var attributes := ShaderMaterial.new()
	attributes.shader = preload("res://src/presentation/lighting/material_cache.gdshader")
	material_canvas.material = attributes
	material_canvas.draw.connect(_render_material_cache)
	material_viewport.add_child(material_canvas)
	core_response = ShaderMaterial.new()
	core_response.shader = preload("res://src/presentation/lighting/core_response.gdshader")
	core_response.set_shader_parameter("attributes",material_viewport.get_texture())
	core_response.set_shader_parameter("albedo_is_linear",board_viewport.use_hdr_2d)
	core_response.set_shader_parameter("light_radius",FortressLighting.LIGHT_RADIUS)
	core_response.set_shader_parameter("light_height",FortressLighting.LIGHT_HEIGHT)
	board_sprite.material = core_response
	world_environment = WorldEnvironment.new()
	world_environment.environment = FortressLighting.environment()
	add_child(world_environment)
	for tier in ["hot", "working", "cold"]:
		band_textures.append(FortressLighting.material_texture(load("res://assets/art/bands/band_%s_01.png" % tier),"band"))
	mount = FortressLighting.material_texture(load("res://assets/art/buildings/mount_01.png"),"mount")
	wall_texture = FortressLighting.material_texture(load("res://assets/art/walls/wall_deflector_01.png"),"wall")
	world_font = load("res://assets/ui/fonts/barlow/Barlow-SemiBold.ttf")
	for kind in ["debris_field", "tractor_lane", "occlusion_screen"]:
		terrain_textures[kind] = FortressLighting.material_texture(load("res://assets/art/terrain/terrain_%s_01.png" % kind),"terrain")
	for kind in ["flak","mass_driver","emp_node","lance_emitter","point_defense","relay","repair_node","armor_plating"]:
		heads[kind] = FortressLighting.material_texture(load("res://assets/art/buildings/head_%s.png" % kind),"head")
	for kind in ["normal","tunneler","transfer","foundry","sapper","breacher","assembler"]:
		var file: String = "machine_standard" if kind == "normal" else ("assembler" if kind == "assembler" else "elite_"+kind)
		machines[kind] = load("res://assets/art/machines/%s.png" % file)
	machine_markers.hide()
	triangle_markers.hide()
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	space = ColorRect.new()
	space.size = get_viewport_rect().size
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://src/presentation/industrial_space.gdshader")
	space.material = material
	layer.add_child(space)
	sun = Sprite2D.new()
	var white := Image.create(1,1,false,Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	sun.texture = ImageTexture.create_from_image(white)
	sun.scale = Vector2.ONE * PolarGrid.CORE_RADIUS * 4.8
	sun.scale.y /= TILT
	var solar := ShaderMaterial.new()
	solar.shader = load("res://src/presentation/solar_body.gdshader")
	solar.set_shader_parameter("palette",randi()%3)
	sun.material = solar
	sun.z_index = -2
	add_child(sun)
	objective = Label.new()
	objective.text = "Containment  15:00  /  Ignition"
	objective.position = Vector2(get_viewport_rect().size.x*0.5-220,get_viewport_rect().size.y-56)
	objective.add_theme_color_override("font_color",WARM)
	objective.add_theme_font_size_override("font_size",24)
	objective.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label.get_parent().add_child(objective)
	# Frame the actual owned fortress once. The inspection scene's spare grid
	# rings must not make the first playable structure a distant thumbnail.
	var owned_radius := grid.ring_bounds(maxi(1,state.rings.size())).y
	var opening_size := get_viewport_rect().size
	_set_zoom(minf(opening_size.y*0.67,maxf(480,opening_size.x-660)*0.78)/(owned_radius*2.0))
	camera.force_update_scroll()
	queue_redraw()

func _set_zoom(value: float) -> void:
	super._set_zoom(clampf(value,0.05,4.0))
	camera.zoom.y = camera.zoom.x*TILT
	queue_redraw()
	if board_canvas != null: board_canvas.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and PCSettings.logical_key(event.physical_keycode) == KEY_ALT:
		tactical = event.pressed
		queue_redraw()
	super._input(event)

func _process(delta: float) -> void:
	if collapse_simulation != simulation:
		collapse_feedback.clear()
		collapse_simulation = simulation
	super._process(delta)
	_refresh_board_cache()
	if not get_tree().paused:
		if not interface_settings.reduced_motion: sun_phase += minf(delta,0.05)
	collapse_feedback.advance(delta,get_tree().paused,interface_settings.effects)
	camera.offset = collapse_feedback.camera_impulse(camera.zoom,interface_settings.reduced_motion,interface_settings.effects)
	if sun != null:
		sun.material.set_shader_parameter("phase",sun_phase)
		sun.material.set_shader_parameter("activity",clampf(float(simulation.elapsed_seconds)/900.0,0.2,1.0))
		var health := clampf(simulation.core_hp/float(profile.value("health.core_hp")),0.2,1.0) if profile != null else 1.0
		var brownout: bool = PowerRules.chain_boundary(state) < state.rings.size()
		var brightness: float = (0.67+0.08*sin(sun_phase*4.0)) if brownout and not interface_settings.reduced_motion else (0.7 if brownout else 1.0)
		sun.modulate = Color(brightness,health*brightness,health*brightness,1.0)
		update_core_lighting(int(sun.material.get_shader_parameter("palette")),health*brightness)
	if objective != null and simulation != null:
		objective.position = Vector2(get_viewport_rect().size.x*0.5-220,get_viewport_rect().size.y-56)
		var left := maxi(0,ceili(RunRules.OPERATION_SECONDS-simulation.elapsed_seconds))
		objective.text = "PRACTICE / No rewards" if simulation.run_is_practice else "CONTAINMENT  %02d:%02d  /  %s" % [left/60,left%60,"IGNITION" if left>600 else ("FORTRESS" if left>300 else "LAST WATCH")]
	if space != null:
		space.size = get_viewport_rect().size
		space.material.set_shader_parameter("star_center",get_viewport().get_canvas_transform()*Vector2.ZERO/get_viewport_rect().size)
		space.material.set_shader_parameter("drift",camera.position)
	queue_redraw()

func _simulation_tick(delta: float) -> void:
	super._simulation_tick(delta)
	if simulation != null and not simulation.run_is_practice and simulation.elapsed_seconds >= RunRules.OPERATION_SECONDS:
		clock.paused = true

func _presentation_committed_tick(before: Dictionary, events: Dictionary, tick: int) -> void:
	if collapse_simulation != simulation:
		collapse_feedback.clear()
		collapse_simulation = simulation
	var cues := collapse_feedback.admit(before,events,tick)
	if not interface_settings.effects: collapse_feedback.events.clear()
	if application_host == null: return
	if not events.hits.is_empty(): application_host.audio.play("shot") # T-082 replaces weapon compatibility.
	for cue in cues:
		var screen_point: Vector2 = get_viewport().get_canvas_transform()*cue.point
		var pan := clampf(screen_point.x/get_viewport_rect().size.x*2.0-1.0,-1,1)
		application_host.audio.emit_cue(cue.id,pan,1.0)

func apply_interface_settings(settings: Dictionary) -> void:
	super.apply_interface_settings(settings)
	if collapse_feedback != null:
		if not settings.effects: collapse_feedback.events.clear()
		if camera != null and (settings.reduced_motion or not settings.effects): camera.offset = Vector2.ZERO

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

func _draw() -> void:
	if camera == null: return
	var started := Time.get_ticks_usec()
	_draw_board()
	_draw_combat_feedback()
	var target_outline := ability_outline()
	if not target_outline.is_empty():
		draw_colored_polygon(target_outline,Color(WARM,0.055))
		draw_polyline(target_outline,Color(WARM,0.8),1.5/camera.zoom.x,true)
	for warning in tunneler_warnings:
		var point: Vector2 = warning.point
		var remaining: float = warning.remaining
		var warning_color := COLD if remaining>0.6 else Color("ffb77b")
		draw_set_transform(point,0,Vector2(1,1/TILT)/camera.zoom.x)
		draw_circle(Vector2.ZERO,12,Color("101e2a"))
		draw_arc(Vector2.ZERO,12,-PI/2,-PI/2+TAU*clampf(remaining/2.0,0.01,1),24,Color(warning_color,0.7),1.5,true)
		draw_polyline(PackedVector2Array([Vector2(-5,-4),Vector2(0,5),Vector2(5,-4)]),warning_color,1.7,true)
		if world_font != null:
			draw_string(world_font,Vector2(18,5),("TUNNELER  " if tactical else "")+"%.1fs" % remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,17,warning_color)
		draw_set_transform(Vector2.ZERO)
	if not is_equal_approx(marker_zoom,camera.zoom.x): _update_machine_markers()
	draw_cpu_usec = Time.get_ticks_usec()-started

func _refresh_board_cache() -> void:
	if board_canvas == null or camera == null: return
	camera.force_update_scroll()
	var canvas := get_viewport().get_canvas_transform()
	var viewport_size := Vector2i(get_viewport_rect().size)
	var stamp: Array = [canvas.x,canvas.y,viewport_size,selected_cell,selected_slot,detail_hover_cell,detail_hover_slot,build_mode,tactical,ring_count]
	for ring in state.get("rings",{}):
		var record: Dictionary = state.rings[ring]
		stamp.append(record.get("collapsed",false))
		stamp.append(record.get("relay_hp",0)>0)
		for plate in record.wedges.values():
			stamp.append(ceili(plate.hp/plate.max_hp*(100.0 if tactical else 12.0)))
			stamp.append(plate.occupants.hash())
			stamp.append(plate.has("wall"))
	var coverage := canvas*board_sprite.transform
	var cached_size := Vector2(board_viewport.size)
	var uncovered := not board_cache_full and (coverage.origin.x>0.01 or coverage.origin.y>0.01 or coverage.origin.x+cached_size.x<viewport_size.x-0.01 or coverage.origin.y+cached_size.y<viewport_size.y-0.01)
	if stamp != board_stamp or uncovered:
		board_stamp = stamp
		var extent := _board_extent()
		board_cache_full = extent*2*absf(canvas.x.x)<=viewport_size.x and extent*2*absf(canvas.y.y)<=viewport_size.y
		var raster := canvas
		if board_cache_full:
			# At strategic zoom the entire fortress fits. Anchor its native raster
			# in world space so WASD and shake move one texture, without redrawing.
			board_viewport.size = viewport_size
			raster.origin = Vector2(viewport_size)*0.5
		else:
			# Close inspections retain a bounded 256 native-pixel margin per edge.
			# Repaint only when panning exposes geometry outside that coverage.
			board_viewport.size = viewport_size+Vector2i(512,512)
			raster.origin += Vector2(256,256)
		board_viewport.canvas_transform = raster
		board_sprite.transform = raster.affine_inverse()
		board_canvas.queue_redraw()
		board_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		if material_viewport != null:
			material_viewport.size = board_viewport.size
			material_viewport.canvas_transform = raster
			material_canvas.material.set_shader_parameter("raster_scale",Vector2(raster.x.x,raster.y.y))
			material_canvas.queue_redraw()
			material_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			core_response.set_shader_parameter("raster_origin",raster.origin)
			core_response.set_shader_parameter("raster_scale",Vector2(raster.x.x,raster.y.y))
			core_response.set_shader_parameter("raster_size",Vector2(board_viewport.size))

## Frozen T-081 adapter: dynamic palette/health updates never invalidate geometry.
func update_core_lighting(palette: int, energy: float) -> void:
	if core_response == null: return
	core_response.set_shader_parameter("core_color",FortressLighting.CORE_COLORS[clampi(palette,0,2)])
	core_response.set_shader_parameter("core_energy",clampf(energy,0.0,1.0))
	core_response.set_shader_parameter("lighting_enabled",lighting_enabled)
	world_environment.environment.glow_enabled = lighting_enabled and interface_settings.effects

func lighting_state() -> Dictionary:
	return {"palette":int(sun.material.get_shader_parameter("palette")),"color":core_response.get_shader_parameter("core_color"),"radius":FortressLighting.LIGHT_RADIUS,"height":FortressLighting.LIGHT_HEIGHT,"enabled":lighting_enabled,"world_layer_max":0,"albedo_redraws":board_redraw_count,"material_redraws":material_redraw_count}

func _render_material_cache() -> void:
	var albedo_canvas := board_canvas
	var albedo_count := board_redraw_count
	board_canvas = material_canvas
	_render_board()
	board_canvas = albedo_canvas
	board_redraw_count = albedo_count
	material_redraw_count += 1

func _board_extent() -> float:
	var outer_ring := maxi(state.rings.size(),maxi(selected_cell.x,detail_hover_cell.x))
	if build_mode != &"": outer_ring=maxi(outer_ring,state.rings.size()+1)
	var extent := grid.ring_bounds(maxi(1,outer_ring)).y+64.0
	if tactical:
		for ring in state.rings:
			for wedge in state.rings[ring].wedges:
				var plate: Dictionary=state.rings[ring].wedges[wedge]
				for slot in plate.occupants:
					var kind: StringName=plate.occupants[slot].kind
					if kind==&"occlusion_screen": extent=maxf(extent,grid.ring_bounds(ring).y+float(profile.value("occlusion_screen.shadow_rings"))*PolarGrid.RING_WIDTH+8)
					if Vector2i(ring,wedge)==selected_cell and slot==selected_slot and kind in [&"flak",&"mass_driver",&"lance_emitter"]:
						extent=maxf(extent,grid.ring_bounds(ring).y+float(profile.value(String(kind)+".range_ring_widths"))*PolarGrid.RING_WIDTH+8)
	return extent

func _band_mesh(cell: Vector2i) -> ArrayMesh:
	if band_meshes.has(cell): return band_meshes[cell]
	var radius := grid.ring_bounds(cell.x).y
	var width := 28.0 if cell.x <= 3 else 25.0
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for step in range(ARC_STEPS+1):
		var direction := _boundary_direction(cell,step)
		var u := radius*TAU/12.0*float(step)/ARC_STEPS/(width*8.9)
		for side in 2:
			var point := direction*(radius+(float(side)-0.5)*width)
			vertices.append(Vector3(point.x,point.y,0))
			uvs.append(Vector2(u,float(side)))
		if step < ARC_STEPS:
			var index := step*2
			indices.append_array(PackedInt32Array([index,index+1,index+2,index+1,index+3,index+2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	band_meshes[cell] = mesh
	return mesh

func _draw_truss(cell: Vector2i, bounds: Vector2, zoom: float) -> void:
	var direction := _boundary_direction(cell,0)
	var tangent := Vector2(-direction.y,direction.x)
	var inner := bounds.x+9
	var outer := bounds.y-10
	var light := clampf(0.50+0.32*direction.y+0.16*absf(direction.x),0.24,0.95)
	var rail := Color("47535d").lerp(Color("c1a272"),light)
	# The open zigzag web is visibly traversable; the doubled rails carry depth.
	for side in [-1,1]:
		var a: Vector2 = direction*inner+tangent*side*5
		var b: Vector2 = direction*outer+tangent*side*5
		board_canvas.draw_line(a+Vector2(0,5),b+Vector2(0,5),Color("080c12"),5,true)
		board_canvas.draw_line(a,b,rail.darkened(0.20),3.4,true)
		board_canvas.draw_line(a-tangent*0.8,b-tangent*0.8,rail,0.7,true)
	if zoom > 0.38:
		for step in 5:
			var a := direction*lerpf(inner,outer,float(step)/5)+tangent*5*(1 if step%2==0 else -1)
			var b := direction*lerpf(inner,outer,float(step+1)/5)-tangent*5*(1 if step%2==0 else -1)
			board_canvas.draw_line(a+Vector2(0,2),b+Vector2(0,2),Color("151b22"),3,true)
			board_canvas.draw_line(a,b,rail.darkened(0.28+float(step%2)*0.15),1.7,true)
			var bolt := direction*lerpf(inner,outer,float(step)/5)
			board_canvas.draw_line(bolt-tangent*5,bolt+tangent*5,Color("1b242c"),2,true)
	var point := direction*bounds.y
	board_canvas.draw_set_transform(point,point.angle()+PI/2)
	board_canvas.draw_rect(Rect2(-7,-15,14,31),Color("1b242c"))
	board_canvas.draw_rect(Rect2(-6,-15,12,25),Color("696b66"))
	board_canvas.draw_line(Vector2(-5,-14),Vector2(5,-14),Color("d1ad70"),1.2)
	for side in [-1,1]:
		board_canvas.draw_circle(Vector2(side*4,-9),1.5,Color("161e25"))
		board_canvas.draw_rect(Rect2(side*5-1,6,2,4),Color("f5cf87"))
	board_canvas.draw_set_transform(Vector2.ZERO)

func _draw_band(cell: Vector2i, bounds: Vector2, health: float, zoom: float) -> void:
	var tier := 0 if cell.x<=2 else (1 if cell.x<=5 else 2)
	var mesh := _band_mesh(cell)
	var texture: Texture2D = band_textures[tier]
	var thickness := 14.0 if cell.x<=3 else 12.5
	# Real side faces extend down-screen under the mapped, authored top surface.
	board_canvas.draw_mesh(mesh,texture,Transform2D(0,Vector2(0,7)),Color("242732"))
	board_canvas.draw_polyline(_arc(cell,bounds.y+thickness),Color("0e141b"),8,true)
	board_canvas.draw_mesh(mesh,texture,Transform2D.IDENTITY,Color(0.72+health*0.28,0.69+health*0.31,0.66+health*0.34))
	board_canvas.draw_polyline(_arc(cell,bounds.y-thickness+0.7),Color("a7804d"),1.7,true)
	board_canvas.draw_polyline(_arc(cell,bounds.y+thickness-0.5),Color("151e28"),1.3,true)
	# Paired pipework and independent lamps read as inhabited industrial plant.
	if zoom > 0.30:
		board_canvas.draw_polyline(_arc(cell,bounds.y+thickness+1.0),Color("626969"),1.3,true)
		for step in range(1,ARC_STEPS,2):
			var direction := _boundary_direction(cell,step)
			var tangent := Vector2(-direction.y,direction.x)
			var point := direction*(bounds.y-thickness+1)
			var lit := health > float((step+cell.y*3)%12)/12.0
			if lit:
				board_canvas.draw_line(point-tangent*3,point+tangent*3,Color(1,0.50,0.10,0.10),7,true)
				board_canvas.draw_line(point-tangent*2.7,point+tangent*2.7,Color("ffcb78"),1.4,true)
			else:
				board_canvas.draw_line(point-tangent*2.7,point+tangent*2.7,Color("322d26"),1.4,true)
		# Pressure vessels, cable trunks and antennae break the perfect circle.
		if cell.y%3 == cell.x%3:
			var direction := _boundary_direction(cell,5)
			var point := direction*(bounds.y+thickness+4)
			board_canvas.draw_set_transform(point,point.angle()+PI/2)
			board_canvas.draw_rect(Rect2(-10,-5,20,11),Color("18212b"))
			board_canvas.draw_rect(Rect2(-9,-7,18,10),Color("606963"))
			board_canvas.draw_line(Vector2(-8,-6),Vector2(8,-6),Color("aea17d"),1)
			for rib in 4: board_canvas.draw_line(Vector2(-6+rib*4,-5),Vector2(-6+rib*4,2),Color("2e3940"),1.5)
			if cell.y%2 == 0:
				board_canvas.draw_line(Vector2(7,-3),Vector2(7,-24),Color("677984"),1.5,true)
				board_canvas.draw_circle(Vector2(7,-24),1.3,COLD)
			board_canvas.draw_set_transform(Vector2.ZERO)

func _draw_wall(cell: Vector2i, bounds: Vector2) -> void:
	var radius := bounds.y+5
	var segments := ceili(radius*TAU/12.0/24.0)
	var first := _boundary_direction(cell,0).angle()
	var size := Vector2(radius*TAU/12.0/segments+1,25)
	for index in segments:
		var bearing := first+(float(index)+0.5)/segments*TAU/12.0
		var point := Vector2.from_angle(bearing)*radius
		board_canvas.draw_set_transform(point+Vector2(0,5),bearing+PI/2)
		board_canvas.draw_texture_rect(wall_texture,Rect2(-size/2,size),false,Color("19202a"))
		board_canvas.draw_set_transform(point,bearing+PI/2)
		board_canvas.draw_texture_rect(wall_texture,Rect2(-size/2,size),false,Color("c8c2af"))
	board_canvas.draw_set_transform(Vector2.ZERO)

func _render_board() -> void:
	if camera == null: return
	board_redraw_count += 1
	var zoom := camera.zoom.x
	var draws: Array[Dictionary] = []
	for cell in cells:
		if cell.x==0 or not _cell_owned(cell): continue
		var previous := Vector2i(cell.x,((cell.y+10)%12)+1)
		if _cell_description(cell) not in ["broken","collapsed"] or _cell_description(previous) not in ["broken","collapsed"]:
			_draw_truss(cell,grid.ring_bounds(cell.x),zoom)
	for ring in state.get("rings",{}):
		var record: Dictionary = state.rings[ring]
		if record.get("collapsed",false): continue
		var relay_point := _boundary_direction(Vector2i(ring,1),0)*(grid.ring_bounds(ring).y-18)
		board_canvas.draw_set_transform(relay_point,relay_point.angle()+PI/2)
		if heads.has("relay"): board_canvas.draw_texture_rect(heads.relay,Rect2(-22,-26,44,44),false,Color.WHITE if record.get("relay_hp",0)>0 else Color("32363b"))
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
			_draw_band(cell,bounds,health,zoom)
			if _active_wall(cell): _draw_wall(cell,bounds)
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
				board_canvas.draw_line(point+Vector2(0,5),point.normalized()*bounds.y+Vector2(0,5),Color("101720"),11,true)
				board_canvas.draw_line(point,point.normalized()*bounds.y,Color("545d60"),8,true)
				board_canvas.draw_line(point-Vector2(1,0),point.normalized()*bounds.y-Vector2(1,0),Color("a69b7f"),1.5,true)
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
		board_canvas.draw_set_transform(point+Vector2(0,5),point.angle()-PI/2)
		if mount != null and heads.has(kind): board_canvas.draw_texture_rect(mount,Rect2(-23,-23,46,46),false,Color("151d28"))
		board_canvas.draw_set_transform(point,point.angle()-PI/2)
		if mount != null and heads.has(kind): board_canvas.draw_texture_rect(mount,Rect2(-23,-25,46,46),false)
		if heads.has(kind): board_canvas.draw_texture_rect(heads[kind],Rect2(-31,-34,62,62),false)
		else: _terrain_hardware(kind,int(item.direction))
		board_canvas.draw_set_transform(Vector2.ZERO)
		if tactical:
			board_canvas.draw_set_transform(point+Vector2(0,24)/zoom,0,Vector2(1,1/TILT)/zoom)
			board_canvas.draw_string(ThemeDB.fallback_font,Vector2.ZERO,BUILDING_NAMES.get(StringName(kind),kind),HORIZONTAL_ALIGNMENT_LEFT,-1,12,WARM)
			board_canvas.draw_set_transform(Vector2.ZERO)

func _terrain_hardware(kind: String, direction: int) -> void:
	if terrain_textures.has(kind):
		board_canvas.draw_texture_rect(terrain_textures[kind],Rect2(-29,-29,58,58),false)
		if kind == "tractor_lane":
			for index in 3:
				var x := float(index*9-9)*direction
				board_canvas.draw_polyline(PackedVector2Array([Vector2(x-3*direction,-5),Vector2(x,0),Vector2(x-3*direction,5)]),Color("b6d8da"),1.5,true)
	elif kind == "debris_field":
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
	if interface_settings.effects: collapse_feedback.draw(self,zoom,interface_settings.reduced_motion,{"heads":heads,"mount":mount,"bands":band_textures,"wall":wall_texture,"terrain":terrain_textures})
