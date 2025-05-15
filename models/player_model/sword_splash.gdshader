shader_type spatial;
render_mode unshaded, blend_mix, cull_back;

uniform sampler2D trail_texture : hint_default_black;
uniform float fade = 1.0;

void fragment() {
	vec4 tex = texture(trail_texture, UV);
	ALBEDO = tex.rgb;
	ALPHA = tex.a * (1.0 - UV.x) * fade;
}