extern vec2 direction;
extern float radius;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 _) {
    vec4 c = vec4(0.0, 0.0, 0.0, 0.0);
    for (float i = -1.0; i <= 1.0; i += 1.0){
        c += Texel(tex, tc + i * direction);
    }
    return c / (2.0 * radius + 1.0) * color;
}