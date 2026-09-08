shader_type canvas_item;
render_mode unshaded;
uniform float extent = 1344.0;
uniform float enabled = 0.0;
void fragment(){
	vec2 world=(UV-0.5)*2.0*extent;
	float radius=length(world)/96.0;
	float warm=exp(-max(0.0,radius-1.0)*1.15)*0.24;
	float violet=exp(-pow((radius-4.0)*0.36,2.0))*0.095;
	float angle=atan(world.y,world.x);
	float ribbon=0.72+0.28*sin(angle*2.0+radius*0.35);
	vec3 color=mix(vec3(0.36,0.18,0.48),vec3(1.0,0.48,0.13),warm/(warm+violet+0.0001));
	float outside= smoothstep(0.95,1.03,radius);
	float soft_extent=1.0-smoothstep(0.72,1.0,length(world)/extent);
	COLOR=vec4(color,(warm+violet*ribbon)*outside*enabled*soft_extent);
}
