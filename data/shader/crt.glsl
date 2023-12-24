extern vec2 distortionFactor;
extern vec2 scaleFactor;
extern number feather;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
    // to barrel coordinates
    uv = uv * 2.0 - vec2(1.0);

    // distort
    uv *= scaleFactor;
    uv += (uv.yx*uv.yx) * uv * (distortionFactor - 1.0);
    number mask = (1.0 - smoothstep(1.0-feather,1.0,abs(uv.x)))
                * (1.0 - smoothstep(1.0-feather,1.0,abs(uv.y)));

    // to cartesian coordinates
    uv = (uv + vec2(1.0)) / 2.0;

    return color * Texel(tex, uv) * mask;
}