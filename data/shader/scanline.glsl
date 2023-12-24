extern number width;
extern number phase;
extern number thickness;
extern number opacity;
extern vec3 color;
extern number screen_h;

vec4 effect(vec4 c, Image tex, vec2 tc, vec2 _) {
    number v = .5*(sin(tc.y * 3.14159 / width * screen_h + phase) + 1.);
    c = Texel(tex,tc);
    c.rgb -= (color - c.rgb) * (pow(v,thickness) - 1.0) * opacity;
    return c;
}