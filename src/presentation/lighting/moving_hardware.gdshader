shader_type canvas_item;
render_mode unshaded;
// One material per moving-hardware canvas, CanvasTexture channels per draw.
// Standard/elite albedo+normal+emission can vary without per-actor uniforms.
uniform vec3 core_color : source_color = vec3(1.0,0.69,0.34);
uniform float core_energy = 1.0;
uniform float light_radius = 420.0;
uniform float light_height = 170.0;
uniform bool normal_green_up = true; // T-092 Blender map declaration.
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec3 local_n = normalize(texture(NORMAL_TEXTURE,UV).rgb*2.0-1.0);
	if(normal_green_up) local_n.y = -local_n.y;
	vec2 du = dFdx(UV), dv = dFdy(UV);
	vec2 dx = dFdx(world_position), dy = dFdy(world_position);
	float determinant = du.x*dv.y-du.y*dv.x;
	vec2 tangent = normalize((dx*dv.y-dy*du.y)*sign(determinant)+vec2(0.000001));
	vec2 bitangent = normalize((dy*du.x-dx*dv.x)*sign(determinant)+vec2(0.000001));
	vec3 n = normalize(vec3(tangent*local_n.x+bitangent*local_n.y,local_n.z));
	vec3 light_direction = normalize(vec3(-world_position,light_height));
	float falloff = exp(-length(world_position)/light_radius);
	vec3 response = vec3(0.40,0.54,0.68)+core_color*core_energy*falloff*(0.56+1.65*max(0.0,dot(n,light_direction)));
	vec3 lit = COLOR.rgb*response;
	lit = lit/(vec3(1.0)+max(lit-vec3(0.82),vec3(0.0))*0.55);
	vec3 emission = texture(SPECULAR_SHININESS_TEXTURE,UV).rgb;
	// Elite self-emission is its own power source; core HP only affects reflection.
	COLOR = vec4(lit+emission*0.70,COLOR.a);
}
