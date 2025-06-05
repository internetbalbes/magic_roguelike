shader_type spatial;

render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque;

uniform vec4 albedo_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);
uniform float emission_energy = 5.0;

float circle(in vec2 pt, in float radius){
	vec2 dist = pt-vec2(0.5);
	return 1.0-smoothstep(radius-(radius*0.01),
						radius+(radius*0.01),
						dot(dist,dist)*4.0);
}

void fragment() {

    // Kolor bazowy obiektu
    ALBEDO = albedo_color.rgb * emission_energy;
	ALPHA = circle(UV,0.95) * (1.0 - circle(UV,0.8));
}
