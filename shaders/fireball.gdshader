shader_type spatial;

uniform float time : hint_range(0.0, 1.0);
uniform vec4 color_start : source_color;
uniform vec4 color_end : source_color;

void fragment() {
	float brightness = sin(time * 3.14159) * 0.5 + 0.5;  // Fluktuacja jasności
	vec4 color = mix(color_start, color_end, brightness);  // Mieszanie kolorów
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
