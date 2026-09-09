extends RefCounted
## Read-only committed-event projection. Values are provisional D-134 tuning.
const MAX_EVENTS := 8
const MAX_PIECES := 96
const DURATION := 2.8 # seconds: fracture .12, separation .8, dust/settle remainder.
const IMPULSE_PIXELS := 9.0
var events: Array[Dictionary] = []
var last_tick := -1
var admitted := {"ring":0,"wedge":0,"core":0}

func clear() -> void:
	events.clear()
	last_tick = -1
	admitted = {"ring":0,"wedge":0,"core":0}

func admit(before: Dictionary, committed: Dictionary, tick: int) -> Array[Dictionary]:
	var cues: Array[Dictionary] = []
	if tick <= last_tick: return cues
	last_tick = tick
	for ring in committed.collapsed_rings:
		if not before.rings.has(ring): continue
		var saved: Dictionary = before.rings[ring]
		if saved.get("collapsed",false): continue
		var pieces := []
		for wedge in range(1,13):
			var plate: Dictionary = saved.wedges[wedge]
			if float(plate.hp) > 0:
				pieces.append(_sector(ring,wedge,plate))
		_push({"kind":"ring","ring":ring,"tick":tick,"age":0.0,"pieces":pieces})
		cues.append({"id":&"ring.collapse","point":Vector2.ZERO})
	for cell in committed.broken_wedges:
		# A sector that belongs to this tick's collapse is already in its mass.
		if cell.x in committed.collapsed_rings: continue
		if not before.rings.has(cell.x): continue
		var plate: Dictionary = before.rings[cell.x].wedges[cell.y]
		var piece := _sector(cell.x,cell.y,plate)
		_push({"kind":"wedge","ring":cell.x,"tick":tick,"age":0.0,"pieces":[piece]})
		cues.append({"id":&"wedge.fracture","point":piece.center})
	if committed.core_lost:
		_push({"kind":"core","ring":0,"tick":tick,"age":0.0,"pieces":[]})
	return cues

func _push(effect: Dictionary) -> void:
	while events.size() >= MAX_EVENTS or piece_count()+effect.pieces.size() > MAX_PIECES:
		events.pop_front()
	events.append(effect)
	admitted[effect.kind] += 1

func _sector(ring: int, wedge: int, plate: Dictionary) -> Dictionary:
	var inner := 96.0*ring
	var outer := inner+96.0
	var grid := PolarGrid.new(ring)
	var center := grid.polar_to_world(grid.cell_center(Vector2i(ring,wedge)))
	var angle := center.angle()
	var polygon := PackedVector2Array()
	var uv := PackedVector2Array()
	var thickness := 14.0 if ring <= 3 else 12.5
	# Match the thin outer band and its open radial support, not a solid annulus.
	for step in range(7):
		polygon.append(Vector2.from_angle(angle-PI/12.0+float(step)*PI/36.0)*(outer+thickness)-center)
		uv.append(Vector2(float(step)/6.0*outer*TAU/12.0/(thickness*2.0*8.9),1))
	for step in range(6,-1,-1):
		polygon.append(Vector2.from_angle(angle-PI/12.0+float(step)*PI/36.0)*(outer-thickness)-center)
		uv.append(Vector2(float(step)/6.0*outer*TAU/12.0/(thickness*2.0*8.9),0))
	var rails := []
	for edge in [-1,1]:
		var radial := Vector2.from_angle(angle+float(edge)*PI/12.0)
		var tangent := radial.orthogonal()
		for side in [-1,1]: rails.append([radial*(inner+9)+tangent*float(side)*5.0-center,radial*(outer-10)+tangent*float(side)*5.0-center])
		for step in 5:
			rails.append([radial*lerpf(inner+9,outer-10,float(step)/5)+tangent*5.0*(1 if step%2==0 else -1)-center,radial*lerpf(inner+9,outer-10,float(step+1)/5)-tangent*5.0*(1 if step%2==0 else -1)-center])
	var hardware := []
	for slot in plate.occupants:
		var count := int(plate.slot_count)
		var p := BuildingRules.slot_position(ring,wedge,int(slot),count)
		var world := grid.polar_to_world(p)
		hardware.append({"kind":String(plate.occupants[slot].kind),"point":world-center,"angle":world.angle()-PI/2.0,"slot":slot})
	var walls := []
	if plate.has("wall"):
		var segments := ceili((outer+5)*TAU/12.0/24.0)
		for index in segments:
			var bearing := angle-PI/12.0+(float(index)+0.5)/float(segments)*TAU/12.0
			walls.append({"point":Vector2.from_angle(bearing)*(outer+5)-center,"angle":bearing+PI/2.0,"size":Vector2((outer+5)*TAU/12.0/float(segments)+1,25)})
	return {"center":center,"polygon":polygon,"uv":uv,"rails":rails,"wedge":wedge,"angle":angle,"hardware":hardware,"walls":walls,"hp":plate.hp}

func piece_count() -> int:
	var count := 0
	for event in events: count += event.pieces.size()
	return count

func advance(delta: float, paused: bool, enabled: bool) -> void:
	if not enabled:
		events.clear()
		return
	if paused: return
	for event in events: event.age += maxf(0,delta)
	events = events.filter(func(event): return event.age < DURATION)

func camera_impulse(zoom: Vector2, reduced: bool, enabled: bool) -> Vector2:
	if reduced or not enabled: return Vector2.ZERO
	var impulse := Vector2.ZERO
	for event in events:
		var t: float = event.age
		var envelope := pow(maxf(0,1.0-t/0.85),2.0)
		var power := IMPULSE_PIXELS if event.kind != "wedge" else 2.2
		var phase := float(event.tick%97)
		impulse += Vector2(sin(t*113.0+phase)+0.35*sin(t*197.0),cos(t*137.0+phase)*0.8)*envelope*power
	return impulse.limit_length(IMPULSE_PIXELS)/zoom

func draw(canvas: CanvasItem, zoom: float, reduced: bool, art: Dictionary = {}) -> void:
	for event in events:
		var age: float = event.age
		var radius := 96.0*float(event.ring)+48.0 if event.ring > 0 else 96.0
		var fade := clampf(1.0-age/DURATION,0,1)
		if reduced:
			if age < 0.35:
				if event.kind != "wedge": canvas.draw_arc(Vector2.ZERO,radius,0,TAU,96,Color(0.78,0.47,0.25,(1-age/0.35)*0.3),2.0/zoom,true)
			continue
		if event.kind != "wedge" and age < 0.6:
			var flash_radius := radius+maxf(0,age-0.08)*180.0
			canvas.draw_arc(Vector2.ZERO,flash_radius,0,TAU,128,Color(1.0,0.69,0.32,0.5*pow(1.0-age/0.6,2.0)),maxf(1.0,8.0*(1-age/0.6))/zoom,true)
		for piece in event.pieces:
			var direction := Vector2.from_angle(piece.angle)
			var move := maxf(0,age-0.12)
			var side := -1.0 if piece.wedge%2 == 0 else 1.0
			var drift: Vector2 = direction*(move*32.0)+direction.orthogonal()*side*move*9.0
			var depth := sin(minf(move/1.7,1.0)*PI)*18.0
			var center: Vector2 = piece.center+drift+Vector2(0,-depth)
			var rotation := side*move*0.13
			var scale := Vector2(1.0,maxf(0.18,cos(move*0.9)))
			canvas.draw_set_transform(center+Vector2(0,8.0+depth),rotation,scale)
			canvas.draw_colored_polygon(piece.polygon,Color(0.015,0.025,0.032,fade*0.55))
			# Structural side face stays attached to the band during its tumble.
			canvas.draw_set_transform(center+Vector2(0,5.0),rotation,scale)
			canvas.draw_colored_polygon(piece.polygon,Color(0.11,0.15,0.18,fade))
			var pose := Transform2D(rotation,scale,0,center)
			canvas.draw_set_transform_matrix(pose)
			if art.has("bands"):
				var tier := 0 if event.ring <= 2 else (1 if event.ring <= 5 else 2)
				canvas.draw_polygon(piece.polygon,PackedColorArray([Color(0.60,0.57,0.52,fade)]),piece.uv,art.bands[tier])
			else: canvas.draw_colored_polygon(piece.polygon,Color(0.21,0.27,0.29,fade))
			for rail in piece.rails:
				canvas.draw_line(rail[0]+Vector2(0,4),rail[1]+Vector2(0,4),Color(0.04,0.06,0.08,fade),3.4,true)
				canvas.draw_line(rail[0],rail[1],Color(0.48,0.49,0.43,fade),2.0,true)
			var rim: PackedVector2Array = piece.polygon.duplicate()
			rim.append(rim[0])
			canvas.draw_polyline(rim,Color(0.65,0.74,0.74,fade*0.75),1.5/zoom,true)
			# Sheared hot seams go dark quickly; the detached slab has no living lamps.
			for edge in [0,6]:
				canvas.draw_line(piece.polygon[edge],piece.polygon[13-edge],Color(1.0,0.60,0.24,fade*maxf(0,1.0-age/0.7)),3.0/zoom,true)
			for hardware in piece.hardware:
				canvas.draw_set_transform_matrix(pose*Transform2D(hardware.angle,hardware.point))
				if art.has("heads") and art.heads.has(hardware.kind):
					canvas.draw_texture_rect(art.mount,Rect2(-23,-25,46,46),false,Color(0.6,0.6,0.6,fade))
					canvas.draw_texture_rect(art.heads[hardware.kind],Rect2(-31,-34,62,62),false,Color(0.6,0.6,0.6,fade))
				elif art.has("terrain") and art.terrain.has(hardware.kind):
					canvas.draw_texture_rect(art.terrain[hardware.kind],Rect2(-29,-29,58,58),false,Color(0.6,0.6,0.6,fade))
			for wall in piece.walls:
				canvas.draw_set_transform_matrix(pose*Transform2D(wall.angle,wall.point))
				if art.has("wall"): canvas.draw_texture_rect(art.wall,Rect2(-wall.size/2,wall.size),false,Color(0.5,0.5,0.5,fade))
			canvas.draw_set_transform(Vector2.ZERO)
			# Dust follows each retained sector, never fills surviving ring bands.
			for mote in range(3):
				var p: Vector2 = center+direction.orthogonal()*float(mote-1)*11.0+direction*move*float(8+mote*3)
				canvas.draw_circle(p,3.0+move*5.0,Color(0.49,0.43,0.32,fade*0.10))
	canvas.draw_set_transform(Vector2.ZERO)
