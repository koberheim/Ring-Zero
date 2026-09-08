shader_type canvas_item;
render_mode unshaded;
uniform float phase = 0.0;
uniform int palette = 1;
uniform float painterly = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) {
	float v=0.0; float a=0.55;
	for(int i=0;i<4;i++){v+=a*noise(p);p=mat2(vec2(1.6,1.2),vec2(-1.2,1.6))*p+3.7;a*=0.48;}
	return v;
}
void fragment() {
	vec2 p=(UV-0.5)*3.3; float r=length(p); float t=phase*0.045;
	float angle=atan(p.y,p.x);
	float rotation=t*(0.3+0.5*r);
	vec2 spun=mat2(vec2(cos(rotation),sin(rotation)),vec2(-sin(rotation),cos(rotation)))*p;
	vec2 flow=spun*3.6+vec2(t,-t*0.63);
	float warp=fbm(flow+vec2(fbm(flow+2.0),fbm(flow-3.0))*1.4);
	float granules=fbm(spun*29.0+vec2(warp*4.0-t,t*0.7));
	float texture_value=clamp(warp*0.6+granules*0.65,0.0,1.0);
	float cells=pow(max(0.0,1.0-abs(granules-0.52)*5.0),3.0);
	vec3 dark=vec3(0.57,0.10,0.018); vec3 mid=vec3(1.0,0.48,0.055); vec3 hot=vec3(1.0,0.94,0.60);
	if(palette==0){dark=vec3(0.27,0.018,0.026);mid=vec3(0.92,0.16,0.025);hot=vec3(1.0,0.72,0.28);}
	if(palette==2){dark=vec3(0.34,0.42,0.55);mid=vec3(0.82,0.87,0.90);hot=vec3(1.0,0.98,0.89);}
	vec3 surface=mix(dark,mid,smoothstep(0.22,0.68,texture_value));
	surface=mix(surface,hot,cells*0.44+pow(texture_value,4.0)*0.35);
	float limb=pow(clamp(1.0-r*r,0.0,1.0),0.18);
	surface*=0.52+limb*0.55;
	float edge=exp(-abs(r-0.995)*115.0);
	surface+=hot*edge*0.42;
	float corona=exp(-max(0.0,r-1.0)*13.0)*(0.11+0.05*painterly);
	float wisp=pow(0.5+0.5*sin(angle*11.0+fbm(p*4.0+vec2(t))*9.0),10.0);
	corona+=wisp*exp(-max(0.0,r-1.0)*9.0)*0.18;
	float disk=1.0-smoothstep(0.993,1.006,r);
	vec3 glow=mix(mid,hot,0.2);
	COLOR=vec4(mix(glow,surface,disk),max(disk,corona)*(1.0-smoothstep(1.35,1.64,r)));
}
