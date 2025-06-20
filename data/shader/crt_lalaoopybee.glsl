extern number time;
// extern vec2 resolution;

extern number CURVATURE;
extern number BLUR;
extern number CA_AMT;

number rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    // curvatura
    vec2 crtUV = uv * 2.0 - 1.0;
    vec2 offset = crtUV.yx / CURVATURE;
    crtUV += crtUV * offset * offset;
    crtUV = crtUV * 0.5 + 0.5;

    // vinheta
    vec2 edge = smoothstep(0.0, BLUR, crtUV) * (1.0 - smoothstep(1.0 - BLUR, 1.0, crtUV));

    // aberração cromática usando tex
    vec3 col;
    col.r = Texel(tex, (crtUV - 0.5) * CA_AMT + 0.5).r;
    col.g = Texel(tex, crtUV).g;
    col.b = Texel(tex, (crtUV - 0.5) / CA_AMT + 0.5).b;

    // brilho oscilante
    number brightness = 0.95 + 0.05 * sin(time * 3.0);
    // number brightness = 0.75 + 0.35 * sin(time * 6.0);

    // flicker com ruído
    number noise = rand(sc + time);
    // number flicker = mix(0.95, 1.05, noise);
    number flicker = mix(0.925, 1.05, noise);

    // aplicação final dos efeitos
    col *= edge.x * edge.y * brightness * flicker;

    // linhas de varredura
    if (mod(sc.y, 2.0) < 1.0)
        col *= 0.7;
    else if (mod(sc.x, 3.0) < 1.0)
        col *= 0.7;
    else
        col *= 1.2;

    // return vec4(col, 1.0) * color;
    return vec4(col * color.rgb, edge.x * edge.y * color.a);
}