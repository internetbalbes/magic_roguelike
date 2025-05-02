shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float blur_radius : hint_range(0.0, 10.0) = 3.0;
uniform float grain_intensity = 0.05;
uniform float sharpness = 1.0;  // Siła wyostrzenia
uniform float aberration_strength : hint_range(0.0, 1.0) = 0.02;
uniform float aberration_offset_x : hint_range(-1.0, 1.0) = 0.01;
uniform float aberration_offset_y : hint_range(-1.0, 1.0) = 0.01;

float rand(vec2 co) {
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {

	// Ustawienie przesunięć dla każdego kanału
	vec2 offset_r = vec2(aberration_offset_x, aberration_offset_y);
	vec2 offset_g = vec2(-aberration_offset_x, aberration_offset_y);
	vec2 offset_b = vec2(aberration_offset_x, -aberration_offset_y);

	// Pobieranie kolorów z tekstury z przesunięciem dla każdego kanału
	vec4 color_r = texture(screen_texture, UV + offset_r * aberration_strength);
	vec4 color_g = texture(screen_texture, UV + offset_g * aberration_strength);
	vec4 color_b = texture(screen_texture, UV + offset_b * aberration_strength);

	// Chromatyczne aberracje: Łączenie przesuniętych kanałów
	vec4 aberrated_color = vec4(color_r.r, color_g.g, color_b.b, 1.0);

	// Gaussian Blur
	vec4 blur_color = vec4(0.0);
	float blur_kernel[9] = float[](0.0625, 0.125, 0.0625,
									0.125, 0.25, 0.125,
									0.0625, 0.125, 0.0625);

	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			blur_color += texture(screen_texture, UV + vec2(float(i), float(j)) * blur_radius) * blur_kernel[(i+1)*3 + (j+1)];
		}
	}
	vec4 sharpened_color = aberrated_color * (1.0 + sharpness) - blur_color * sharpness;
	// Final color: blend sharpened and blurred result
	///vec4 color = mix(blur_color, sharpened_color, 1);
	vec4 color = blur_color;
	// Maska wyostrzająca (konwolucja)
	float noise = rand(UV * TIME);
	color.rgb += (noise - 0.5) * grain_intensity;
	COLOR = color;
}
//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
