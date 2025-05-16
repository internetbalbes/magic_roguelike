shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;

uniform vec3 color : source_color = vec3(0.2, 0.3, 0.8);
uniform float emission_energy = 5.0;

float circle(in vec2 pt, in float radius){
	vec2 dist = pt-vec2(0.5);
	return 1.0-smoothstep(radius-(radius*0.01),
						radius+(radius*0.01),
						dot(dist,dist)*4.0);
}

void fragment() {
	ALBEDO = color * emission_energy;
	ALPHA = circle(UV, 1.0) * 0.5;	
}