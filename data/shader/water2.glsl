// https://www.shadertoy.com/view/ldXGz7

uniform float iTime = 0.0;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc)
{
    vec2 scaling = vec2(512/256, 288/224);

	uv.y += (cos((uv.y + (iTime * 0.04)) * 45.0) * 0.0019) +
		(cos((uv.y + (iTime * 0.1)) * 10.0) * 0.002);

	uv.x += (sin((uv.y + (iTime * 0.07)) * 15.0) * 0.0029) +
		(sin((uv.y + (iTime * 0.1)) * 15.0) * 0.002);

	return Texel(tex,uv);
}