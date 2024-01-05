uniform Image NOISE;
uniform float strength = 1.0;
uniform vec2 direction = vec2(1.0, -1.0);
uniform float speed = 0.1;
uniform float iTime = 0.0;
uniform float scaling = 0.0078125;  // -- 1/128

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    float amp = strength * scaling;

    float time = iTime;
    vec2 factor = direction * speed * time;

    vec2 noise_time_index = fract(uv + factor);

    vec4 noisecolor = Texel(NOISE, noise_time_index);

    float xy = noisecolor.b * 0.7071;
    noisecolor.r -= xy;
    noisecolor.g -= xy;

    uv += ((amp * 2.0) * noisecolor.xy) - amp;

    return Texel(tex, uv) * color;
}