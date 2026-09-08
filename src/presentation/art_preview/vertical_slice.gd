extends Node2D
## T-078 diagnostic fixture only; it does not replace live simulation rendering.
## F3 opens this overlay in art_preview.tscn, keys 1-5 select review gates.
const BAND = preload("res://assets/art/bands/band_working_01.png")
const DECALS = preload("res://assets/art/decals/decal_sheet_01.png")
const MOUNT = preload("res://assets/art/buildings/mount_01.png")
const HEAD = preload("res://assets/art/buildings/head_mass_driver.png")
const MACHINE = preload("res://assets/art/machines/machine_standard.png")
const INK = Color("e4e6e8")
const MUTED = Color("9aa4ae")
const MODES = ["Close / export pixels", "Strategic minification", "Canonical yellow star", "1,000-machine crowd", "Twelve outward bearings"]
var mode := 0
var star: ColorRect
var swarm: MultiMeshInstance2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var background := ColorRect.new()
	background.size = Vector2(1440, 900)
	background.color = Color("080b10")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -2
	add_child(background)
	star = ColorRect.new()
	star.position = Vector2(416, 145)
	star.size = Vector2(608, 608)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.z_index = -1
	var shader := ShaderMaterial.new()
	shader.shader = preload("res://src/presentation/art_preview/sun.gdshader")
	shader.set_shader_parameter("palette", 1)
	shader.set_shader_parameter("phase", 0.0)
	star.material = shader
	add_child(star)
	swarm = MultiMeshInstance2D.new()
	swarm.texture = MACHINE
	swarm.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var mesh := QuadMesh.new()
	mesh.size = Vector2(25.6, 25.6)
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_2D
	instances.mesh = mesh
	instances.instance_count = 1000
	for i in 1000:
		var local_index := i % 500
		var spacing := Vector2(26, 22) if i < 500 else Vector2(17, 15)
		var origin := Vector2(55, 195) if i < 500 else Vector2(55, 500)
		instances.set_instance_transform_2d(i, Transform2D(float(i % 12) * TAU / 12.0,
			origin + Vector2(local_index % 50, local_index / 50) * spacing))
	swarm.multimesh = instances
	add_child(swarm)
	set_mode(0)
	get_parent().hide()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			get_parent().visible = not get_parent().visible
			get_viewport().set_input_as_handled()
		elif get_parent().visible and event.keycode >= KEY_1 and event.keycode <= KEY_5:
			set_mode(event.keycode - KEY_1)
			get_viewport().set_input_as_handled()

func set_mode(value: int) -> void:
	mode = clampi(value, 0, 4)
	if star != null:
		star.visible = mode == 2
	if swarm != null:
		swarm.visible = mode == 3
	queue_redraw()

func caption(at: Vector2, text: String, size: int = 18, color: Color = INK) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func sprite(tex: Texture2D, at: Vector2, width: float, angle: float = 0.0) -> void:
	draw_set_transform(at, angle)
	var extent := Vector2(width, width * tex.get_height() / float(tex.get_width()))
	draw_texture_rect(tex, Rect2(-extent / 2, extent), false)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	caption(Vector2(35, 38), "T-078  |  " + MODES[mode], 26)
	caption(Vector2(35, 67), "F3: return to live preview    1: close    2: strategic    3: yellow star    4: crowd    5: rotations", 17, MUTED)
	caption(Vector2(35, 785), "REVIEW FIXTURE: provisional sizes/pivots. Live band UVs, decals, building sprites, machine sprites and relighting remain unwired.", 17, MUTED)
	match mode:
		0:
			caption(Vector2(35, 105), "Working band | 1024 x 128 | three source repeats; no seam correction")
			draw_texture_rect(BAND, Rect2(35, 115, 1024, 128), false)
			caption(Vector2(35, 282), "Decal sheet | 0.375x")
			draw_texture_rect(DECALS, Rect2(35, 290, 384, 384), false)
			caption(Vector2(455, 282), "Mount | 256 px")
			sprite(MOUNT, Vector2(583, 435), 256)
			caption(Vector2(755, 282), "Head | 256 px")
			sprite(HEAD, Vector2(883, 435), 256)
			caption(Vector2(1070, 282), "Machine | 64 px / 3x")
			sprite(MACHINE, Vector2(1105, 350), 64)
			sprite(MACHINE, Vector2(1190, 500), 192)
			caption(Vector2(455, 625), "Composite study | same source-space scale, head on mount socket")
			sprite(MOUNT, Vector2(615, 694), 120)
			sprite(HEAD, Vector2(615, 684), 160)
		1:
			caption(Vector2(35, 118), "World-size trial: band 256x32, sheet 128, mount 32, head 43, machine 8 units.")
			caption(Vector2(35, 146), "Strategic zoom = 810 x 0.42 / (96 + 12 x 96) = 0.273. Live marker is a fixed 6 px circle.")
			for row in 2:
				var factor := 1.55 if row == 0 else 810.0 * 0.42 / 1248.0
				var y := 290.0 + row * 245
				caption(Vector2(35, y - 65), "Close zoom 1.55" if row == 0 else "Strategic zoom 0.273")
				for i in 5:
					var tex: Texture2D = [BAND, DECALS, MOUNT, HEAD, MACHINE][i]
					var width: float = [256.0, 128.0, 32.0, 43.0, 8.0][i] * factor
					sprite(tex, Vector2(240 + i * 240, y), width)
					caption(Vector2(180 + i * 240, y + 115), ["Band", "Sheet", "Mount", "Head", "Machine"][i])
		2:
			caption(Vector2(35, 118), "Actual sun.gdshader | palette=1, phase=0 | neutral texture modulation; no simulated relighting")
			# Texture around a real polar arc; this is a local UV diagnostic, not live board integration.
			for j in 64:
				var points := PackedVector2Array()
				var uv := PackedVector2Array()
				for corner in [Vector2(j, 0), Vector2(j + 1, 0), Vector2(j + 1, 1), Vector2(j, 1)]:
					var a: float = PI + corner.x / 64.0 * PI
					points.append(Vector2(720, 449) + Vector2.from_angle(a) * (224 + corner.y * 38))
					uv.append(Vector2(corner.x / 64.0, corner.y))
				draw_polygon(points, PackedColorArray([Color.WHITE]), uv, BAND)
			caption(Vector2(80, 360), "Mount / head / standard")
			sprite(MOUNT, Vector2(435, 435), 140, PI / 2)
			sprite(HEAD, Vector2(1005, 435), 155, -PI / 2)
			sprite(MACHINE, Vector2(720, 655), 64)
			draw_texture_rect(DECALS, Rect2(40, 410, 256, 256), false)
			var regions := [Rect2(25,154,247,290), Rect2(314,153,175,286), Rect2(510,155,272,285), Rect2(805,154,200,295), Rect2(58,512,140,349), Rect2(270,513,140,349), Rect2(483,555,263,279), Rect2(770,579,235,237)]
			for i in regions.size():
				var at := Vector2(720, 449) + Vector2.from_angle(0.2 + float(i) / 7 * 2.74) * 230
				draw_texture_rect_region(DECALS, Rect2(at - Vector2(17,17), Vector2(34,34)), regions[i])
			caption(Vector2(1030, 680), "Black hull against bright limb")
		3:
			caption(Vector2(35, 118), "1,000 quads | one MultiMesh / shared texture | 25.6 px extent | 12 rotations")
			caption(Vector2(35, 150), "Top: 500 at 26 x 22 px spacing. Bottom: 500 overlapping at 17 x 15 px on a grey deck.")
			draw_rect(Rect2(35, 475, 880, 182), Color("39414b"))
			caption(Vector2(35, 455), "Dense overlap on working-tier metal")
			caption(Vector2(35, 720), "Compare: isolated 25.6 px")
			sprite(MACHINE, Vector2(310, 710), 25.6)
		4:
			caption(Vector2(35, 118), "Front is source +Y. angle = bearing - PI/2. Cross marks projected pivot. Top bearing is 270 degrees.")
			for column in 3:
				var center := Vector2(245 + column * 475, 430)
				caption(center + Vector2(-95, -215), ["Mount", "Mass Driver head", "Standard machine"][column])
				draw_arc(center, 152, 0, TAU, 96, Color("27303b"), 1, true)
				for bearing in 12:
					var a := bearing * TAU / 12.0
					var at := center + Vector2.from_angle(a) * 152
					sprite([MOUNT, HEAD, MACHINE][column], at, 68 if column < 2 else 40, a - PI / 2)
					draw_line(at - Vector2(3, 0), at + Vector2(3, 0), Color("d6a75c"))
					draw_line(at - Vector2(0, 3), at + Vector2(0, 3), Color("d6a75c"))
					caption(center + Vector2.from_angle(a) * 204 - Vector2(10, -4), str(bearing * 30), 13, MUTED)
			caption(Vector2(35, 726), "This fixture rotates the baked view. Tilted-plane placement / depth sorting are absent from the live renderer.")
