extern number exposure;
extern number decay;
extern number density;
extern number weight;
extern vec2 light_position;
extern number samples;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
    color = Texel(tex, uv);

    vec2 offset = (uv - light_position) * density / samples;
    number illumination = decay;
    vec4 c = vec4(.0, .0, .0, 1.0);

    for (int i = 0; i < int(samples); ++i) {
    uv -= offset;
    c += Texel(tex, uv) * illumination * weight;
    illumination *= decay;
    }

    return vec4(c.rgb * exposure + color.rgb, color.a);
}