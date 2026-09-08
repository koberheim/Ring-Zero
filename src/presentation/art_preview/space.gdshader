shader_type canvas_item;
render_mode unshaded;
uniform float painterly = 0.0;
uniform vec2 drift = vec2(0.0);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
	vec2 uv=UV+drift*0.000025;
	float cloud=noise(uv*4.0)*0.6+noise(uv*9.0)*0.25+noise(uv*20.0)*0.15;
	float diagonal=exp(-pow((uv.y-uv.x*0.6-0.18)*3.0,2.0));
	vec3 space=vec3(0.020,0.027,0.043);
	space+=painterly*diagonal*cloud*vec3(0.075,0.034,0.080);
	space+=painterly*pow(cloud,4.0)*vec3(0.085,0.028,0.010);
	vec2 cell=floor(uv*vec2(340.0,230.0));
	vec2 local=fract(uv*vec2(340.0,230.0))-0.5;
	float star=step(0.994,hash(cell))*exp(-dot(local,local)*70.0);
	space+=vec3(0.45,0.50,0.59)*star;
	COLOR=vec4(space,1.0);
}
