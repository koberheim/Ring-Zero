extends Node2D
## T-079 diagnostic overlay. No gameplay rendering or simulation integration.
const STANDARD = preload("res://assets/art/machines/machine_standard.png")
const MOUNT = preload("res://assets/art/buildings/mount_01.png")
const MASS_DRIVER = preload("res://assets/art/buildings/head_mass_driver.png")
const WORKING = preload("res://assets/art/bands/band_working_01.png")
const ZOOM = 810.0 * 0.42 / 1248.0
const MODES = ["Close / export pixels", "Strategic minification", "Canonical yellow star", "Mixed swarm", "Twelve bearings"]
var records: Array = []
var textures: Array[Texture2D] = []
var mode := 0
var page := 0
var star: ColorRect

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	records = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/art/t079_normalization_manifest.json"))
	for record in records:
		textures.append(load("res://" + record.output))
	var background := ColorRect.new()
	background.size = Vector2(1440, 810)
	background.color = Color("080b10")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -2
	add_child(background)
	star = ColorRect.new()
	star.position = Vector2(416, 145)
	star.size = Vector2(608, 608)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.z_index = -1
	var material := ShaderMaterial.new()
	material.shader = preload("res://src/presentation/art_preview/sun.gdshader")
	material.set_shader_parameter("palette", 1)
	material.set_shader_parameter("phase", 0.0)
	star.material = material
	add_child(star)
	set_review(0, 0)
	get_parent().hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F4:
			get_parent().visible = not get_parent().visible
			get_viewport().set_input_as_handled()
		elif get_parent().visible:
			if event.keycode >= KEY_1 and event.keycode <= KEY_5:
				set_review(event.keycode - KEY_1, 0)
			elif event.keycode == KEY_RIGHT:
				set_review(mode, page + 1)
			elif event.keycode == KEY_LEFT:
				set_review(mode, page - 1)
			get_viewport().set_input_as_handled()

func page_count(value: int) -> int:
	return [5, 2, 5, 3, 17][value]

func set_review(value: int, index: int) -> void:
	mode = clampi(value, 0, 4)
	page = posmod(index, page_count(mode))
	star.visible = mode == 2
	queue_redraw()

func label(at: Vector2, text: String, size: int = 18) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("dce1e6"))

func sprite(tex: Texture2D, at: Vector2, width: float, angle: float = 0.0) -> void:
	draw_set_transform(at, angle)
	var extent := Vector2(width, width * tex.get_height() / float(tex.get_width()))
	draw_texture_rect(tex, Rect2(-extent / 2, extent), false)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if textures.is_empty():
		return
	label(Vector2(30, 35), "T-079 | %s | page %d / %d" % [MODES[mode], page + 1, page_count(mode)], 26)
	label(Vector2(30, 65), "F4: return | 1 close, 2 strategic, 3 yellow, 4 crowd, 5 bearings | Left/Right: pages", 17)
	label(Vector2(30, 790), "DIAGNOSTIC CANDIDATES: provisional sizes/pivots. Live tilted placement, sprite integration and relighting remain absent.", 16)
	match mode:
		0: close_page()
		1: strategic_page()
		2: star_page()
		3: crowd_page()
		4: rotation_page()

func close_page() -> void:
	if page == 0:
		for i in 2:
			label(Vector2(30, 110 + i * 180), records[i].name + " | 1024 x 128, exact export pixels")
			sprite(textures[i], Vector2(542, 185 + i * 180), 1024)
		label(Vector2(30, 500), "Existing working band for comparison (unchanged)")
		sprite(WORKING, Vector2(542, 580), 1024)
		label(Vector2(30, 710), "No seam repair. Left/right RGBA boundary error is recorded in the normalization manifest.")
	elif page == 1:
		label(Vector2(30, 110), "Damage atlas at 0.55x; right: six atlas regions at 0.5x export pixels")
		sprite(textures[2], Vector2(310, 420), 560)
		for i in 6:
			var regions := [Rect2(45,20,445,352), Rect2(540,20,445,360), Rect2(50,383,440,287), Rect2(530,380,460,313), Rect2(35,682,455,286), Rect2(540,747,455,185)]
			var region: Rect2 = regions[i]
			# Each region is displayed at 0.5x, with scale explicitly labelled.
			draw_texture_rect_region(textures[2], Rect2(Vector2(650 + (i % 2) * 350, 145 + (i / 2) * 195), region.size * 0.5), region)
		label(Vector2(650, 750), "Regions shown at 0.5x; source substrate remains visible.", 16)
	elif page == 2:
		for j in 8:
			var at := Vector2(190 + (j % 4) * 350, 275 + (j / 4) * 310)
			var i := j + 3
			label(at + Vector2(-135, -143), records[i].name if j < 7 else "Existing Mass Driver")
			sprite(textures[i] if j < 7 else MASS_DRIVER, at, 256)
	elif page == 3:
		for j in 4:
			var at := Vector2(190 + j * 350, 300)
			label(at + Vector2(-135, -155), records[10 + j].name)
			sprite(textures[10 + j], at, 256)
		label(Vector2(30, 500), "Standalone wall / terrain: no shared mount is drawn beneath any of these four.")
		label(Vector2(30, 540), "Armor + mount overlay study | nominal source interface offset, not verified live seating")
		sprite(MOUNT, Vector2(250, 655), 170)
		sprite(textures[9], Vector2(250, 641), 170)
	else:
		label(Vector2(30, 110), "Elites at 128 px, standard at 64 px, Assembler at 256 px. No colour tint or added glow.")
		for j in 5:
			var at := Vector2(150 + j * 270, 265)
			label(at + Vector2(-75, -90), records[14 + j].name)
			sprite(textures[14 + j], at, 128)
		label(Vector2(200, 455), "Standard (zero emissive)")
		sprite(STANDARD, Vector2(300, 570), 64)
		label(Vector2(620, 435), "Assembler")
		sprite(textures[19], Vector2(720, 590), 256)
		label(Vector2(980, 475), "One cold accent required on each.")
		label(Vector2(980, 510), "Boss accent must be larger.")

func strategic_page() -> void:
	label(Vector2(30, 110), "World widths are provisional: standard 8, elites 16 (Foundry 24), boss 48. No minimum-screen-size boost.")
	label(Vector2(30, 140), "Each cell: close zoom 1.55 (left); strategic zoom 0.273 (right). Widths refer to complete canvas.")
	for j in 10:
		var i := page * 10 + j
		var at := Vector2(45 + (j % 2) * 705, 190 + (j / 2) * 112)
		label(at, records[i].name + (" | six motifs, 32 units each" if i == 2 else " | " + str(records[i].world_width) + " units"), 16)
		if i == 2:
			var regions := [Rect2(45,20,445,352), Rect2(540,20,445,360), Rect2(50,383,440,287), Rect2(530,380,460,313), Rect2(35,682,455,286), Rect2(540,747,455,185)]
			for k in 6:
				var region: Rect2 = regions[k]
				for trial in 2:
					var width := 32.0 * (1.55 if trial == 0 else ZOOM)
					var extent := Vector2(width, width * region.size.y / region.size.x)
					var pos := at + Vector2(45 + k * 57 if trial == 0 else 485 + k * 20, 50)
					draw_texture_rect_region(textures[i], Rect2(pos - extent/2, extent), region)
			continue
		sprite(textures[i], at + Vector2(205, 50), records[i].world_width * 1.55)
		sprite(textures[i], at + Vector2(565, 50), records[i].world_width * ZOOM)

func star_page() -> void:
	label(Vector2(30, 110), "Actual sun.gdshader, yellow palette 1, phase 0. Neutral modulation; no relighting or glow added.")
	for j in 4:
		var i := page * 4 + j
		var at := Vector2(720, 430) + Vector2.from_angle(-PI * 0.75 + j * PI / 2) * 285
		var width := 190.0 if i < 14 else 128.0
		if i == 19:
			width = 220
		sprite(textures[i], at, width)
		label(at + Vector2(-100, 112), records[i].name, 17)

func crowd_page() -> void:
	label(Vector2(30, 110), "1,000 standard quads + 30 elites + 1 boss. Seeded positions, 12 facings, mixed Y order; no outlines/tints.")
	var factor: float = [3.2, 1.55, ZOOM][page]
	label(Vector2(30, 140), "Zoom %.2f | standard %.1f px, elites %.1f px, Foundry %.1f px, boss %.1f px" % [factor, 8*factor, 16*factor, 24*factor, 48*factor])
	draw_rect(Rect2(25, 165, 1390, 565), Color("39414b"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 79
	var items: Array = []
	var origin := Vector2(720,455) - Vector2(150,60) * factor
	for i in 1000:
		var at := origin + Vector2((i % 50) * 6, (i / 50) * 6) * factor
		at += Vector2(rng.randf_range(-2,2), rng.randf_range(-2,2)) * factor
		items.append({"at":at, "kind":-1, "angle":float(rng.randi_range(0,11))*TAU/12})
	for i in 30:
		items.append({"at":origin+Vector2(20+(i%10)*28,25+(i/10)*36)*factor, "kind":14+i%5, "angle":float(i%12)*TAU/12})
	items.append({"at":origin+Vector2(150,60)*factor, "kind":19, "angle":0.0})
	items.sort_custom(func(a,b): return a.at.y < b.at.y)
	for item in items:
		var kind: int = item.kind
		sprite(STANDARD if kind < 0 else textures[kind], item.at, (8.0 if kind < 0 else float(records[kind].world_width))*factor, item.angle)
	label(Vector2(30, 755), "Diagnostic draw calls, not a throughput benchmark. Strategic isolated comparisons are on page 2 of mode 2.", 16)

func rotation_page() -> void:
	var i := page + 3
	label(Vector2(30, 110), records[i].name + " | all 12 bearings; cross = attachment/footprint pivot")
	label(Vector2(30, 140), "Source +Y faces outward, angle = bearing - PI/2. No per-asset corrective rotation; no tilted ground simulation.")
	var center := Vector2(540, 450)
	for bearing in 12:
		var angle := bearing * TAU / 12
		var at := center + Vector2.from_angle(angle) * 240
		var width := 92.0
		if i >= 14:
			width = 76 if i < 19 else 104
		if records[i].mount_mounted:
			sprite(MOUNT, at, 76, angle - PI/2)
		sprite(textures[i], at, width, angle - PI/2)
		draw_line(at-Vector2(3,0), at+Vector2(3,0), Color("ffc36a"))
		draw_line(at-Vector2(0,3), at+Vector2(0,3), Color("ffc36a"))
		label(center + Vector2.from_angle(angle) * 305 - Vector2(10,-5), str(bearing*30), 14)
	label(Vector2(980, 250), "Isolated export pixels")
	sprite(textures[i], Vector2(1100, 440), textures[i].get_width())
	label(Vector2(940, 660), "Flat dial cannot prove live seating.", 17)
	label(Vector2(940, 690), "Camera/facing failures stay visible.", 17)
