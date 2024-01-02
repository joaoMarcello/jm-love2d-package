// crt
uniform vec2 distortionFactor;
uniform vec2 scaleFactor;
uniform float feather;

// scanline
uniform float width = 1.0;
uniform float phase = 1.0;
uniform float thickness = 1.0;
uniform float opacity = 0.15;
uniform vec3 scan_color = vec3(0.0, 0.0, 0.0);
uniform float screen_h;

vec4 scanln(vec4 c,Image tex,vec2 tc){
    number v = 0.5 * (sin(tc.y * 3.14159 / width * screen_h + phase) + 1.0);
    c.rgb -= (scan_color - c.rgb) * (pow(v, thickness) -1.0) * opacity;
    return c;
}

vec4 crt(vec4 c, Image tex, vec2 uv, vec2 sc){
    uv = (uv * 2.0) - vec2(1.0);

    uv *= scaleFactor;
    uv += (uv.yx * uv.yx) * uv *(distortionFactor - 1.0);

    float mask = (1.0 - smoothstep(1.0 - feather, 1.0, abs(uv.x)))
                * (1.0 - smoothstep(1.0 - feather, 1.0, abs(uv.y)));

    uv = (uv + vec2(1.0)) / 2.0;

    return c * Texel(tex, uv) * mask;
}

vec4 effect(vec4 c,Image tex,vec2 uv,vec2 sc){
    return crt(scanln(c, tex, uv), tex, uv, sc);
}