extern number opacity;
extern number size;
extern vec2 noise;
extern Image noisetex;
extern vec2 tex_ratio;

float rand(vec2 co) {
    return Texel(noisetex, mod(co * tex_ratio / vec2(size), vec2(1.0))).r;
}

vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
    return color * Texel(texture, tc) * mix(1.0, rand(tc+vec2(noise)), opacity);
}