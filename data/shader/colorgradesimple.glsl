extern vec3 factors;
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
    return vec4(factors, 1.0) * Texel(texture, tc) * color;
}