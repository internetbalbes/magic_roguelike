shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;  // Tekstura ekranu
uniform float sharpen_strength : hint_range(0.0, 10.0) = 1.0;  // Siła wyostrzenia
uniform float blur_strength : hint_range(0.0, 10.0) = 5.0;  // Siła rozmycia
uniform float aberration_strength : hint_range(0.0, 1.0) = 0.02;  // Siła aberracji chromatycznej
uniform float grain_strength : hint_range(0.0, 1.0) = 0.05;  // Siła ziarnistości

// Funkcja do generowania ziarnistości (noise)
float random(vec2 st) {
	return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 size = vec2(textureSize(screen_texture, 0));
	vec2 texel_size = 1.0 / size;	
	// Pobieranie oryginalnego koloru
	vec4 color = texture(screen_texture, UV);
	// 1. Wyostrzenie (Sharpening)
	vec4 left = texture(screen_texture, UV + vec2(-texel_size.x, 0.0));
	vec4 right = texture(screen_texture, UV + vec2(texel_size.x, 0.0));
	vec4 up = texture(screen_texture, UV + vec2(0.0, -texel_size.y));
	vec4 down = texture(screen_texture, UV + vec2(0.0, texel_size.y));
	// Zastosowanie wyostrzenia
	//color = color * (1.0 + sharpen_strength) - (left + right + up + down) * (sharpen_strength / 4.0);

	// 2. Rozmycie (Blur)
	vec4 blurred_color = vec4(0.0);
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			blurred_color += texture(screen_texture, UV + vec2(float(x), float(y)) * texel_size) * 0.04;
		}
	}
	// Zastosowanie rozmycia
	color = mix(color, blurred_color, blur_strength);

	// 3. Aberracja Chromatyczna (Chromatic Aberration)
	vec2 offset = aberration_strength * texel_size;

	// Przemieszczanie tekstury dla różnych kanałów (RGB)
	vec4 chromatic_color_r = texture(screen_texture, UV + vec2(offset.x, 0.0));  // Czerwony
	vec4 chromatic_color_g = texture(screen_texture,UV);  // Zielony (bez przesunięcia)
	vec4 chromatic_color_b = texture(screen_texture, UV + vec2(-offset.x, 0.0));  // Niebieski

	// Łączenie kanałów z aberracją chromatyczną
	vec4 aberrated_color = vec4(chromatic_color_r.r, chromatic_color_g.g, chromatic_color_b.b, color.a);

	// 4. Ziarnistość (Noise)
	// Generowanie ziarnistości
	float noise = random(UV);
	// Dodanie ziarnistości do koloru
	aberrated_color.rgb += noise * grain_strength;
	// Ustawienie końcowego koloru
	COLOR = aberrated_color;
}