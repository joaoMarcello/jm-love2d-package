uniform vec4 c;

float less_than(float x, float y) {
    return max(sign(y - x), 0.0);
}

float is_equal(float x, float y) {
    return 1.0 - abs(sign(x - y));
}

float or(float x, float y){
    return min(x + y, 1.0);
}

float overlay(float a, float b){
    float r = less_than(a, 0.5);
    float r2 = or(less_than(0.5, a), is_equal(a, 0.5));

    return (2.0 * a * b) * r 
        + (1.0 - 2.0 * (1.0 - a) * (1.0 - b)) * r2;
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc){
    vec4 pix = Texel(tex, uv);
    return mix(vec4(overlay(c.r, pix.r), overlay(c.g, pix.g), overlay(c.b, pix.b), pix.a), pix, c.a);
}
