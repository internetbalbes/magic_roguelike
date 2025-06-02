shader_type spatial;

render_mode unshaded, cull_disabled;

uniform sampler2D noise_texture : hint_default_white;
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float power : hint_range(0.0, 1.0) = 1.0;
uniform vec2 speed = vec2(0.0, 1.0);
uniform float fill : hint_range(0.0, 1.0) = 1.0; // 0 = pusta, 1 = pełna

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fill_y = mix(-0.49, 0.49, fill);
	if (world_position.y > fill_y) {
		discard;
	}
	vec2 uv = vec2(world_position.x, world_position.y) + TIME * speed;
	float noise = texture(noise_texture, uv).r;
	vec4 color = mix(edge_color, base_color, noise);
	float draw = smoothstep(fill, fill- 0.1, world_position.y);
	ALBEDO = (1.0 - draw) * vec3(0.0) + draw * color.rgb * power;
}