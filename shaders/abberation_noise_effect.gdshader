shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;  // Tekstura ekranu
uniform float aberration_strength : hint_range(0.0, 5.0) = 0.0;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.00;  // Siła ziarnistości

// Funkcja do generowania ziarnistości (noise)
float random(vec2 st) {
	return fract(sin(dot(st + TIME, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	
	// Chromatic aberration offsets
	vec2 offset = vec2(0.001 * aberration_strength);
	float r = texture(screen_texture, UV + offset).r;
	float g = texture(screen_texture, UV).g; // From processed image
	float b = texture(screen_texture, UV - offset).b;
	vec4 color = vec4(r, g, b, texture(screen_texture, UV).a);

	color += grain_strength * (random(UV) - 0.5);  // Losowy szum z zakresu [-0.5, 0.5]
	COLOR = color;
}