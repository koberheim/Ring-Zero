shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 p = (UV - vec2(0.5,0.5)) * vec2(1.77778,1.0);
	p.y /= 0.9396926;
	float r = length(p);
	float angle = atan(p.y,p.x);
	float rings = 0.0;
	for (int i=0; i<4; i++) {
		float radius = 0.48 + float(i)*0.065;
		rings += (1.0-smoothstep(0.001,0.0028,abs(r-radius)))*0.2;
	}
	float spokes = (1.0-smoothstep(0.002,0.006,abs(sin(angle*6.0))))*step(0.48,r)*step(r,0.675)*0.12;
	float corona = exp(-r*5.0)*0.04;
	vec3 color = vec3(0.018,0.025,0.032) + vec3(0.43,0.31,0.18)*(rings+spokes+corona);
	vec2 cell=floor(UV*vec2(450.0,260.0));
	float hash=fract(sin(dot(cell,vec2(127.1,311.7)))*43758.5453);
	vec2 local=fract(UV*vec2(450.0,260.0))-0.5;
	color += vec3(0.18,0.21,0.24)*step(0.998,hash)*exp(-dot(local,local)*80.0);
	COLOR=vec4(color,1.0);
}
