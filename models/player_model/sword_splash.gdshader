shader_type canvas_item;

uniform sampler2D screen_texture : hint_default_black; // pobieramy obraz z ekranu
uniform float time_speed = 1.0;
uniform float noise_strength = 0.01;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a)* u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = SCREEN_UV;

    // Odległość od linii pionowej w środku
    float dist = abs(UV.x - 0.5);
    
    // Tylko w pobliżu linii – wpływ maleje wraz z oddaleniem
    float influence = smoothstep(0.1, 0.0, dist);
    
    // Animowany noise przesuwający UV
    float n = noise(vec2(UV.y * 1.0, TIME * time_speed));
    
    // Przemieszczamy UV ekranu na podstawie noise i influence
    vec2 offset = vec2((n - 0.9), 0.5) * noise_strength * influence;
    vec4 distorted = texture(screen_texture, uv + offset);

    COLOR = distorted;
}