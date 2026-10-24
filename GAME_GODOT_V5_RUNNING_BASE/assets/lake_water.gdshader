shader_type spatial;
render_mode cull_disabled;
uniform vec3 deep_color : source_color = vec3(0.06,0.19,0.22);
uniform vec3 sky_color : source_color = vec3(0.41,0.59,0.65);
void vertex() {
 VERTEX.y += sin(VERTEX.x*1.9+TIME*.9)*.025 + cos(VERTEX.z*2.7+TIME)*.018;
}
void fragment() {
 vec2 p = UV*30.0;
 float wave = sin(p.x*1.7+TIME*.8+sin(p.y*2.0))*cos(p.y*2.6-TIME*.6);
 NORMAL_MAP = vec3(.5+wave*.025,.5+cos(p.x+p.y+TIME)*.025,1.0);
 NORMAL_MAP_DEPTH = .35;
 float fresnel = pow(1.0-clamp(dot(normalize(VIEW),NORMAL),0.0,1.0),3.0);
 float ripple = wave*.012;
 ALBEDO = mix(deep_color,sky_color,.27+fresnel*.5)+ripple;
 ROUGHNESS = .34;
 METALLIC = .15;
}
