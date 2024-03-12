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

// noise
uniform vec2 uNoise = vec2(0.2, 1.0);
uniform float uSeed = 0.0;

vec4 scanln(vec4 c, vec2 tc){
    number v = 0.5 * (sin(tc.y * 3.14159 / width * screen_h + phase) + 1.0);
    c.rgb -= (scan_color - c.rgb) * (pow(v, thickness) -1.0) * opacity;
    return c;
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 coord, vec2 uInputSize)
{
    vec2 pixelCoord = coord * uInputSize.xy;
    pixelCoord.x = floor(pixelCoord.x / uNoise[1]);
    pixelCoord.y = floor(pixelCoord.y / uNoise[1]);
    return (rand(pixelCoord * uNoise[1] * uSeed) - 0.5) * uNoise[0];
}

vec4 crt(vec4 c, vec2 uv){
    uv = (uv * 2.0) - vec2(1.0);

    uv *= scaleFactor;
    uv += (uv.yx * uv.yx) * uv *(distortionFactor - 1.0);

    float mask = (1.0 - smoothstep(1.0 - feather, 1.0, abs(uv.x)))
                * (1.0 - smoothstep(1.0 - feather, 1.0, abs(uv.y)));

    uv = (uv + vec2(1.0)) / 2.0;

    return c * mask;
}

vec4 effect(vec4 c, Image tex, vec2 uv, vec2 sc){
    vec4 final = Texel(tex, uv);

    if(uNoise[0] > 0.0 && uNoise[1] > 0.0)
    {
        float n = noise(uv, love_ScreenSize.xy);
        final += vec4(n, n, n, final.a);
    }

    final = scanln(final, uv);
    final = crt(final, uv);
    return final;
}