extern vec4 c;//vec4(242.0/255.0, 133.0/255.0, 197.0/255.0, 1.0);

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
    return mix(pix, vec4(overlay(pix.r, c.r), overlay(pix.g, c.g), overlay(pix.b, c.b), pix.a), c.a);
}
