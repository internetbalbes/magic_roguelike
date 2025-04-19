shader_type particles;

uniform float tangent_velocity = 0.1;
uniform float upward_speed = 1.0;
uniform float base_radius = 0.3;
uniform sampler2D profile : repeat_disable;

const vec3 flatten = vec3(1.0, 0.0, 1.0);

uint hash(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

void start() {
	if (RESTART_POSITION) {
		uint seed = hash(NUMBER + uint(1) + RANDOM_SEED);

		float theta = mod(float(seed), PI*2.0);
		vec3 pos = vec3(cos(theta), 0, sin(theta)) * base_radius;

		TRANSFORM[3] = EMISSION_TRANSFORM[3] + vec4(pos, 0);
	}
	if (RESTART_CUSTOM) {
		CUSTOM = vec4(0.0);
		CUSTOM.xyz = EMISSION_TRANSFORM[3].xyz;
	}
}

void process() {
	CUSTOM.w += DELTA / LIFETIME;
	float t = CUSTOM.w;
	float s = texture(profile, vec2(t)).r;
	float v = tangent_velocity * DELTA / (s*2.0);
	vec3 pos = (TRANSFORM[3].xyz - CUSTOM.xyz);
	vec3 p = pos * flatten;
	float r = base_radius * s;
	float a = v / r;
	float b = atan(p.z, p.x);
	float ab = mod(a+b, 2.0*PI);
	vec3 dest = vec3(cos(ab), 0.0, sin(ab)) * r;
	dest.y = pos.y + upward_speed * DELTA;
	TRANSFORM[3].xyz = CUSTOM.xyz + dest;
}
