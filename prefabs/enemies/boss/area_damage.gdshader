shader_type spatial;
render_mode unshaded;

uniform sampler2D base_texture : source_color;
uniform float fade_radius : hint_range(0.0, 0.5) = 0.5;
uniform int sector_count : hint_range(1, 4, 1) = 4;
uniform float sector_angle : hint_range(1, 60, 1) = 60.0;

void fragment() {
    vec2 uv_centered = UV - vec2(0.5);
    float dist = length(uv_centered);
    if (dist > fade_radius) discard;

    float point_angle = atan(uv_centered.y, uv_centered.x); // -pi..pi
    if (point_angle < 0.0) {
        point_angle += 6.28318530718; // 0..2pi
    }

    float sector_angle_rad = radians(sector_angle);
    float half_angle = sector_angle_rad * 0.5;
    float sector_step = 6.28318530718 / float(sector_count);

    bool is_in_zone = false;
    for (int i = 0; i < sector_count; i++) {
        // Środek sektora = start + połowa kroku
        float sector_center = float(i) * sector_step;

        float diff = abs(point_angle - sector_center);
        if (diff > 3.14159265359) { // PI
            diff = 6.28318530718 - diff; // 2pi - diff
        }

        if (diff < half_angle) {
            is_in_zone = true;
            break;
        }
    }

    if (!is_in_zone) discard;

    vec4 tex = texture(base_texture, UV);
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
}