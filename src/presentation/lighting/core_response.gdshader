shader_type canvas_item;
render_mode unshaded;
uniform sampler2D attributes : filter_linear;
uniform vec2 raster_origin;
uniform vec2 raster_scale = vec2(1.0);
uniform vec2 raster_size = vec2(2560.0,1440.0);
uniform vec3 core_color : source_color = vec3(1.0,0.69,0.34);
uniform float core_energy = 1.0;
uniform float light_radius = 420.0;
uniform float light_height = 170.0;
uniform bool lighting_enabled = true;
uniform bool albedo_is_linear = false;
void fragment() {
	vec4 albedo = COLOR;
	if(albedo_is_linear) albedo.rgb = mix(albedo.rgb*12.92,1.055*pow(max(albedo.rgb,vec3(0.0)),vec3(1.0/2.4))-0.055,step(vec3(0.0031308),albedo.rgb));
	vec4 packed = texture(attributes,UV);
	vec2 normal_xy = (packed.rg/max(packed.a,0.001))*2.0-1.0;
	normal_xy = clamp(normal_xy,vec2(-0.98),vec2(0.98));
	vec3 n = normalize(vec3(normal_xy,sqrt(max(0.02,1.0-dot(normal_xy,normal_xy)))));
	vec2 world = (UV*raster_size-raster_origin)/raster_scale;
	vec3 light_direction = normalize(vec3(-world,light_height));
	float diffuse = max(0.0,dot(n,light_direction));
	float falloff = exp(-length(world)/light_radius);
	float emission = packed.b/max(packed.a,0.001);
	vec3 cold_ambient = vec3(0.40,0.54,0.68);
	vec3 response = cold_ambient + core_color*core_energy*falloff*(0.56+1.65*diffuse);
	vec3 lit = albedo.rgb*response;
	// Soft shoulder avoids clipping metal highlights; emissive strips may bloom.
	lit = lit/(vec3(1.0)+max(lit-vec3(0.82),vec3(0.0))*0.55);
	lit += core_color*core_energy*emission*0.70;
	COLOR = vec4(lighting_enabled ? lit : albedo.rgb,albedo.a);
}
