shader_type canvas_item;
render_mode unshaded;
uniform vec2 drift = vec2(0.0);
uniform vec2 star_center = vec2(0.5);
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) { vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void fragment() {
	vec2 aspect=vec2(SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x,1.0);
	vec2 q=UV*aspect+drift*0.000045;
	float dust=noise(q*5.0)*0.55+noise(q*13.0)*0.3+noise(q*33.0)*0.15;
	float veil=exp(-pow((q.y-q.x*0.47+0.21)*4.0,2.0));
	vec3 color=vec3(0.008,0.014,0.023)+vec3(0.018,0.025,0.036)*dust*veil;
	float distance_to_star=length((UV-star_center)*aspect);
	color+=vec3(0.035,0.013,0.002)*exp(-distance_to_star*8.0)*dust;
	for(int layer=0;layer<2;layer++) {
		float density=layer==0?210.0:370.0;
		vec2 p=q*density,cell=floor(p),local=fract(p)-0.5;
		float seed=hash(cell+float(layer)*71.0);
		float stars=step(0.994,seed)*exp(-dot(local,local)*(layer==0?110.0:180.0));
		color+=mix(vec3(0.32,0.43,0.55),vec3(0.64,0.56,0.40),hash(cell+7.0))*stars;
	}
	COLOR=vec4(color,1.0);
}
