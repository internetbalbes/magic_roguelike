shader_type canvas_item;

uniform float glow_strength = 1.0;

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float hash11(float p)
{
    return length(hash22(vec2(p)));
}

float hash21(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

mat2 rmatrix(float a)    //Rotation matrix;
{
	float c = cos(a);
	float s = sin(a);
	return mat2(vec2(c, -s), vec2(s, c));
}

float S(float x)
{
	return (3.0 * x * x - 2.0 * x * x * x);
}

float noise(vec2 pos)
{
	float a = hash21(vec2(floor(pos.x), floor(pos.y)));
	float b = hash21(vec2(ceil(pos.x), floor(pos.y)));
	float c = hash21(vec2(floor(pos.x), ceil(pos.y)));
	float d = hash21(vec2(ceil(pos.x), ceil(pos.y)));

	float s1 = S(pos.x - floor(pos.x));
	float s2 = S(pos.y - floor(pos.y));

	float f = a +
			  (b - a) * s1 +
			  (c - a) * s2 +
			  (a - b - c + d) * s1 * s2;
	return (f);
}

float onoise(in vec2 pos)
{
	float n = 3.0;
	float delta = 3.1415 / 6.0;
	float sum = 0.0;
	float power = 0.5;

	for (float i = 0.0; i < n; i++)
	{
		sum += noise(rmatrix(delta * i) * pos) * power;
		power *= 0.40;
		pos *= 1.9;
	}
	return sum;
}

vec3 portalTexture(vec2 uv)
{
    vec2 uv2 = uv;
    uv2 = vec2(length(uv), (atan(uv.y, uv.x) + PI) / 2.0 / PI);
    uv2.y = fract(uv2.y + uv2.x * 0.3 - TIME * 0.01);
    uv2.x = uv2.x * 1.0 + TIME * 0.5;
    vec3 colors[4] = vec3[4]( vec3(0.086, 0.184, 0.529),
                              vec3(0.161, 0.557, 0.890),
                              vec3(0.110, 0.349, 0.835),
                              vec3(0.847, 0.921, 0.980));
    vec2 k = vec2(10.0);
    float br1 = onoise(uv2 * k);
    float br2 = onoise(vec2(uv2.x, uv2.y - 1.0) * k);
    float br = mix(br1, br2, uv2.y);
	br = min(0.99, pow(br * 1.5, 2.5));
	int bri = int(br / 0.25);
	vec3 col = vec3(br);
    col = colors[bri];
    return col;
}

float circle(in vec2 pt, in float radius){
	vec2 dist = pt-vec2(0.5);
	return 1.0-smoothstep(radius-(radius*0.01),
						radius+(radius*0.01),
						dot(dist,dist)*4.0);
}

void fragment()
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (UV - .5) / .4;
    // Time varying pixel color
    vec3 col = portalTexture(uv);
    COLOR = vec4(col, circle(UV, 1. )) * glow_strength;

}
