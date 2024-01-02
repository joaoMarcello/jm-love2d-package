// https://www.shadertoy.com/view/ldXGz7

uniform float iTime = 0.0;
uniform vec2 direction = vec2(1.0, 1.0);
uniform float speed = 3.0;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc)
{
	float time = iTime * speed;

	uv.y += ((cos((uv.y + (time * 0.04)) * 45.0) * 0.0019) +
		(cos((uv.y + (time * 0.1)) * 10.0) * 0.002)) * direction.y;

	uv.x += ((sin((uv.y + (time * 0.07)) * 15.0) * 0.0029) +
		(sin((uv.y + (time * 0.1)) * 15.0) * 0.002))*direction.x;

	return Texel(tex,uv);
}