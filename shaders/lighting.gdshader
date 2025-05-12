shader_type spatial;

render_mode unshaded, blend_mix, cull_disabled, depth_draw_opaque;

uniform vec3 effect_color : source_color = vec3(0.2, 0.3, 0.8);
uniform int octave_count : hint_range(0, 20, 1) = 10;
uniform float amp_start = 0.5;
uniform float amp_coeff = 0.5;
uniform float freq_coeff = 2.0;
uniform float speed = 0.5;

// hash + noise
float hash12(vec2 x) {
	return fract(cos(mod(dot(x, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}

vec2 hash22(vec2 uv) {
	uv = vec2(dot(uv, vec2(127.1, 311.7)),
			  dot(uv, vec2(269.5, 183.3)));
	return 2.0 * fract(sin(uv) * 43758.5453) - 1.0;
}

float noise(vec2 uv) {
	vec2 iuv = floor(uv);
	vec2 fuv = fract(uv);
	vec2 blur = smoothstep(0.0, 1.0, fuv);
	return mix(mix(dot(hash22(iuv + vec2(0.0, 0.0)), fuv - vec2(0.0, 0.0)),
  					dot(hash22(iuv + vec2(1.0, 0.0)), fuv - vec2(1.0, 0.0)), blur.x),
				mix(dot(hash22(iuv + vec2(0.0, 1.0)), fuv - vec2(0.0, 1.0)),
					dot(hash22(iuv + vec2(1.0, 1.0)), fuv - vec2(1.0, 1.0)), blur.x), blur.y) + 0.5;
}

float fbm(vec2 uv, int octaves){
	float value = 0.0;
	float amplitude = amp_start;
	for (int i=0; i < octaves; i++){
		value += amplitude * noise(uv);
		uv *= freq_coeff;
		amplitude *= amp_coeff;
	}
	return value;
}

void fragment() {
	vec2 uv = UV  - 0.5; // center UVs
	uv += fbm(uv + TIME * speed, octave_count) - 0.5;

	float dist = abs(uv.x);
	float intensity = mix(0.0, 0.5, hash12(vec2(TIME))) / dist;

	vec3 color = effect_color * intensity;

	ALBEDO = color;
	ALPHA = (1.0 - smoothstep(.0, 0.1, dist)) * clamp(intensity / 20.0, 0.0, 1.0); // transparency
}