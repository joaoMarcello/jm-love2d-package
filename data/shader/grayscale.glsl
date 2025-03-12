vec4 effect(vec4 c, Image tex, vec2 uv, vec2 sc) {
    vec4 pix = Texel(tex, uv);
    float gray = (pix.r * 0.299) + (pix.g * 0.587) + (pix.b * 0.114);
    return vec4(vec3(gray), pix.a) * c;
}