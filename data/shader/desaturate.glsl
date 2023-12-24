extern vec4 tint;
extern number strength;
vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _) {
    color = Texel(texture, tc);
    number luma = dot(vec3(0.299, 0.587, 0.114), color.rgb);
    return mix(color, tint * luma, strength);
}