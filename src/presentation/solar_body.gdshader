shader_type canvas_item;
render_mode unshaded;

// Surface noise is sampled on a rotating sphere, not a flat UV disc. Limb
// compression and darkening make the photosphere retain depth at every zoom.
uniform float phase = 0.0;
uniform int palette = 1;
uniform float activity : hint_range(0.0, 1.0) = 0.5;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.13,0.27,0.41));
	p *= 17.0;
	return fract(p.x*p.y*p.z*(p.x+p.y+p.z));
}
float n3(vec3 p) {
	vec3 i = floor(p), f = fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(mix(hash3(i),hash3(i+vec3(1,0,0)),f.x),mix(hash3(i+vec3(0,1,0)),hash3(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash3(i+vec3(0,0,1)),hash3(i+vec3(1,0,1)),f.x),mix(hash3(i+vec3(0,1,1)),hash3(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float fbm(vec3 p) {
	float sum = 0.0, amplitude = 0.55;
	for(int i=0;i<4;i++) { sum += n3(p)*amplitude; p=p*2.03+vec3(7.3,2.7,1.9); amplitude*=0.48; }
	return sum;
}
void fragment() {
	vec2 p = (UV-0.5)*4.8;
	float r = length(p);
	float t = phase*0.026;
	float angle = atan(p.y,p.x);
	vec3 ember = vec3(0.64,0.055,0.006);
	vec3 fire = vec3(1.0,0.31,0.018);
	vec3 gold = vec3(1.0,0.72,0.21);
	vec3 white = vec3(1.0,0.96,0.77);
	if(palette==0) { ember=vec3(0.36,0.012,0.007); fire=vec3(1.0,0.15,0.01); gold=vec3(1.0,0.55,0.12); }
	if(palette==2) { ember=vec3(0.22,0.32,0.45); fire=vec3(0.67,0.78,0.89); gold=vec3(0.91,0.92,1.0); white=vec3(1.0); }
	float outside = max(0.0,r-1.0);
	float angular = n3(vec3(cos(angle)*7.0,sin(angle)*7.0,t));
	float stream = pow(0.5+0.5*sin(angle*27.0+angular*12.0+t),5.0);
	float halo = exp(-outside*3.8)*0.11 + exp(-outside*15.0)*0.4;
	float corona = exp(-outside*(12.0-5.0*angular))*stream*(0.18+activity*0.1);
	float loops = 0.0;
	for(int i=0;i<5;i++) {
		float bearing = float(i)*1.756637+0.32+sin(float(i)*2.0+t)*0.15;
		vec2 axis = vec2(cos(bearing),sin(bearing));
		vec2 q = vec2(dot(p,axis),dot(p,vec2(-axis.y,axis.x)));
		float length_scale=0.14+0.10*sin(float(i)*2.7+t*1.3);
		vec2 arch=vec2((q.x-1.015)/length_scale,q.y/(length_scale*0.72));
		float warp=n3(vec3(q*23.0,t+float(i)))*0.075;
		float tube = abs(length(arch)-1.0-warp);
		float filament = exp(-tube*65.0)*0.62+exp(-tube*13.0)*0.13;
		loops += filament*smoothstep(0.96,1.025,r)*(0.65+0.35*sin(float(i)*1.7+t));
	}
	vec3 color = mix(fire,gold,0.28);
	float alpha = (halo+corona+loops)*(1.0-smoothstep(1.8,2.38,r));
	color += gold*loops*0.6;
	if(r<1.008) {
		float z=sqrt(max(0.0,1.0-r*r));
		vec3 sphere=vec3(p,z);
		sphere.xz = mat2(vec2(cos(t),sin(t)),vec2(-sin(t),cos(t)))*sphere.xz;
		float flow=fbm(sphere*4.7+vec3(0,t*0.18,0));
		vec3 warped=sphere*24.0+vec3(flow*3.0,flow*2.0,t);
		float granules=fbm(warped);
		float fine=n3(sphere*99.0+flow*2.0);
		float ridges=pow(1.0-abs(granules*2.0-1.0),7.0);
		float hot=clamp((granules-0.29)*1.5+fine*0.19,0.0,1.0);
		vec3 surface=mix(ember,fire,smoothstep(0.06,0.52,hot));
		surface=mix(surface,gold,smoothstep(0.28,0.79,hot)*0.95);
		surface=mix(surface,white,ridges*0.20+pow(hot,4.0)*0.27);
		float active=pow(smoothstep(0.56,0.84,flow),2.0);
		surface=mix(surface,white,active*0.58);
		float spots=smoothstep(0.68,0.79,n3(sphere*7.5+vec3(8.0,3.0,2.0)))*smoothstep(0.45,0.7,flow);
		surface*=1.0-spots*0.73;
		surface*=0.38+0.68*pow(z,0.44);
		surface+=gold*exp(-abs(r-0.995)*170.0)*0.62;
		float disk=1.0-smoothstep(0.995,1.006,r);
		color=mix(color,surface,disk); alpha=max(alpha,disk);
	}
	COLOR=vec4(color,clamp(alpha,0.0,1.0));
}
