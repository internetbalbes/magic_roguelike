shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D noise_texture;
uniform float freeze_amount : hint_range(0.0, 1.0) = 0.5;
uniform float noise_scale = 10.0;
uniform vec4 freeze_tint : source_color = vec4(0.5, 0.8, 1.0, 1.0);

void fragment() {
    vec4 tex = texture(albedo_texture, UV);
    float noise = texture(noise_texture, UV * noise_scale).r;

    float height_factor = clamp((VERTEX.y + 1.0) * 0.5, 0.0, 1.0);
    float gradient = smoothstep(0.0, 1.0, 1.0 - height_factor);
    float blend = clamp(freeze_amount * gradient + noise * 0.2, 0.0, 1.0);

    vec3 frozen = mix(tex.rgb, freeze_tint.rgb, blend);
    ALBEDO = frozen;
    ALPHA = tex.a;

    METALLIC = freeze_amount;
    ROUGHNESS = mix(1.0, 0.05, freeze_amount);
}