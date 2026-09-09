extends RefCounted
## T-081 material adapter. These are authored proxy surfaces, not recovered
## physical normals from the generated albedo. Texture-local +Y is forward;
## normal texture +Y points down the image (Godot CanvasTexture convention).
const CORE_COLORS := [Color(1.0,0.32,0.13),Color(1.0,0.69,0.34),Color(0.78,0.88,1.0)]
const LIGHT_RADIUS := 420.0 # world units; preserves a cold frontier as rings grow.
const LIGHT_HEIGHT := 170.0 # world units above the fortress plane.
const GLOW_THRESHOLD := 0.45
const GLOW_INTENSITY := 1.0
static var maps := {}

static func moving_material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = preload("res://src/presentation/lighting/moving_hardware.gdshader")
	result.set_shader_parameter("light_radius",LIGHT_RADIUS)
	result.set_shader_parameter("light_height",LIGHT_HEIGHT)
	return result

static func set_core_state(material: ShaderMaterial, palette: int, energy: float) -> void:
	material.set_shader_parameter("core_color",CORE_COLORS[clampi(palette,0,2)])
	material.set_shader_parameter("core_energy",clampf(energy,0.0,1.0))

static func material_texture(albedo: Texture2D, family: String) -> CanvasTexture:
	if not maps.has(family):
		var normal := Image.create(64,64,false,Image.FORMAT_RGBA8)
		var emission := Image.create(64,64,false,Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var p := (Vector2(x,y)+Vector2(0.5,0.5))/32.0-Vector2.ONE
				var slope := Vector2.ZERO
				if family == "band":
					slope.y = signf(p.y)*smoothstep(0.55,1.0,absf(p.y))*0.85
				elif family == "wall":
					slope = Vector2(p.x*0.12,p.y*0.75)
				else:
					# Elliptical bevel/dome proxy preserves a consistent inward-facing
					# highlight at every bearing. No albedo luminance enters this normal.
					slope = p*Vector2(0.65,0.85)*smoothstep(0.15,1.0,p.length())
				var n := Vector3(slope.x,slope.y,1.0).normalized()
				normal.set_pixel(x,y,Color(n.x*0.5+0.5,n.y*0.5+0.5,n.z*0.5+0.5,1))
				# Deliberately authored running-light strips; masked by albedo alpha.
				var lamp := 0.0
				# Band lamps already have a per-wedge HP-dependent draw mask; do not
				# manufacture a second always-on strip over damaged hardware.
				if family not in ["band","terrain"]: lamp = 1.0 if absf(absf(p.x)-0.47)<0.045 and p.y>0.25 and p.y<0.48 else 0.0
				emission.set_pixel(x,y,Color(lamp,lamp,lamp,1))
		maps[family] = [ImageTexture.create_from_image(normal),ImageTexture.create_from_image(emission)]
	var result := CanvasTexture.new()
	result.diffuse_texture = albedo
	result.normal_texture = maps[family][0]
	result.specular_texture = maps[family][1] # explicitly repurposed emission mask
	return result

static func environment() -> Environment:
	var result := Environment.new()
	result.background_mode = Environment.BG_CANVAS
	result.background_canvas_max_layer = 0 # HUD/menu CanvasLayers remain sharp.
	result.glow_enabled = true
	result.glow_hdr_threshold = GLOW_THRESHOLD
	result.glow_intensity = GLOW_INTENSITY
	result.glow_bloom = 0.08
	result.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	return result
