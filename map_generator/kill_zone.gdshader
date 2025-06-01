shader_type fog;

uniform vec3 fog_color_start : source_color = vec3(1.0, 1.0, 1.0); // np. niebieski
uniform vec3 fog_color_end : source_color = vec3(0.0, 0.0, 0.0);   // np. biały
uniform float length_x = 0.0;
uniform float density = 10.0;

void fog() {
	float length_x_half = length_x / 2.0;
    // Pozycja lokalna w objętości (współrzędne UVW mieszczą się w zakresie 0-1)
    float local_x = UVW.x; // UVW.z == 0.0 (przód) → 1.0 (tył)

    // Zmieniamy to na wartość od -5.0 do +5.0 (zgodnie z rozmiarem volume'u)
    float world_x =  mix(-length_x_half, length_x_half, local_x);

    // Oblicz gradient – im większe Z, tym większa gęstość
    float t = clamp((world_x + length_x_half) / (2.0 * length_x_half), 0.0, 1.0);

    DENSITY = t * density;         // Gęstość od 0 do 1
    ALBEDO = mix(fog_color_start, fog_color_end, t);
}
