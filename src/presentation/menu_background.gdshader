shader_type canvas_item;
render_mode unshaded;
uniform sampler2D band_texture : source_color, repeat_enable, filter_linear_mipmap;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void fragment() {
 vec2 p=(UV-vec2(0.296875,0.569444))*vec2(1.777778,1.0);
 p.y/=0.9396926;
 float r=length(p), angle=atan(p.y,p.x);
 vec3 color=vec3(0.014,0.023,0.036);
 vec2 cell=floor(UV*vec2(540.0,310.0)),local=fract(UV*vec2(540.0,310.0))-0.5;
 color+=vec3(0.23,0.29,0.37)*step(0.996,hash(cell))*exp(-dot(local,local)*110.0);
 color+=vec3(0.08,0.030,0.004)*exp(-r*8.0);
 for(int i=0;i<3;i++) {
  float radius=0.30+float(i)*0.135;
  float width=0.031;
  float relative=r-radius;
  float body=1.0-smoothstep(width*0.5,width*0.5+0.0015,abs(relative));
  float undersurface=1.0-smoothstep(width*0.5,width*0.5+0.0015,abs(length(p-vec2(0,0.006))-radius));
  color=mix(color,vec3(0.040,0.047,0.062),undersurface);
  vec3 metal=texture(band_texture,vec2(angle*radius/(width*8.9),(relative/width+0.5))).rgb;
  metal*=vec3(0.58,0.53,0.46)*(0.55+0.45*smoothstep(-1.0,1.0,-p.y/r));
  color=mix(color,metal,body*0.82);
  float rim=exp(-abs(relative+width*0.45)*2400.0);
  float lamps=step(0.63,sin(angle*95.0+float(i)))*exp(-abs(relative+width*0.4)*2200.0);
  color+=vec3(0.66,0.39,0.13)*rim*0.5+vec3(0.8,0.39,0.08)*lamps*0.5;
 }
 float spoke=1.0-smoothstep(0.002,0.004,abs(sin(angle*6.0))*r);
 float spoke_domain=step(0.303,r)*step(r,0.568);
 color=mix(color,vec3(0.12,0.13,0.14),spoke*spoke_domain*0.6);
 // The command console sits over an intentionally quieter right hand field.
 color*=1.0-smoothstep(0.46,0.79,UV.x)*0.63;
 COLOR=vec4(color,1.0);
}