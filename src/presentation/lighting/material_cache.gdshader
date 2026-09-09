shader_type canvas_item;
render_mode unshaded;
// Cached material attributes: normal XY in RG, authored emission in B.
// Derivative tangent basis rotates texture-local normals with each draw command
// and follows the curved band mesh UVs. Undo camera tilt before encoding world XY.
uniform vec2 raster_scale = vec2(1.0);
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	// Maps declare green=image-down. Sample explicitly so the engine's 2D
	// NORMAL green inversion is not accidentally applied a second time.
	vec3 local_n = normalize(texture(NORMAL_TEXTURE,UV).rgb*2.0-1.0);
	vec2 dx = dFdx(UV), dy = dFdy(UV);
	float determinant = dx.x*dy.y-dx.y*dy.x;
	vec2 tangent = normalize(vec2(dy.y,-dx.y)/raster_scale*sign(determinant)+vec2(0.000001));
	vec2 bitangent = normalize(vec2(-dy.x,dx.x)/raster_scale*sign(determinant)+vec2(0.000001));
	vec3 n = normalize(vec3(tangent*local_n.x+bitangent*local_n.y,local_n.z));
	// Default untextured primitives have a white specular texture; they are not
	// lamps. Authored strip locations all have a non-flat proxy normal.
	float powered = smoothstep(0.4,0.8,max(vertex_tint.r,max(vertex_tint.g,vertex_tint.b)));
	float emission = texture(SPECULAR_SHININESS_TEXTURE, UV).r*step(0.02,length(local_n.xy))*powered;
	// Existing immediate-mode lamps retain their explicit warm luminous pigment.
	float warm_lamp = smoothstep(0.84,0.98,COLOR.r)*smoothstep(0.40,0.65,COLOR.g)*(1.0-smoothstep(0.60,0.85,COLOR.b));
	COLOR = vec4(n.xy*0.5+0.5,max(emission,warm_lamp),COLOR.a);
}
