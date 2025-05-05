shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;

uniform float time = 0.0;
uniform sampler2D noise_texture : source_color;
uniform float lightning_thickness : hint_range(0.01, 0.2) = 0.05;
uniform vec3 lightning_color : source_color = vec3(0.6, 0.8, 1.0);
uniform vec3 base_color : source_color = vec3(0.05, 0.05, 0.1);
uniform float transparency_strength : hint_range(0.0, 1.0) = 0.7;

float lightning_pattern(vec2 uv, float t) {
	vec2 animated_uv = uv + vec2(0.0, t * 0.1); // animacja pionowa
	float n = texture(noise_texture, animated_uv).r; // tylko kanał R
	float line = abs(n - 0.5);
	return smoothstep(lightning_thickness, 0.0, line);
}

void fragment() {
	vec3 normal = NORMAL;
	vec2 uv;
	uv.x = atan(normal.z, normal.x) / (2.0 * PI) + 0.5;
	uv.y = acos(normal.y) / PI;

	float pattern = lightning_pattern(uv, time);

	vec3 color = mix(base_color, lightning_color, pattern);
	ALBEDO = color;
	EMISSION = lightning_color * pattern * 2.0;
	
	float alpha = pattern * transparency_strength;
	ALPHA = alpha;

	// Ukryj bardzo słabe fragmenty
	if (alpha < 0.02) {
		discard;
	}
}