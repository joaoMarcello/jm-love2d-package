extern number time;
extern vec2 resolution;

extern number CURVATURE;
extern number BLUR;
extern number CA_AMT;

number rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

// float hash(vec2 p) {
//     return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
// }

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    // Corrige coordenadas para considerar o tamanho lógico do canvas
    vec2 scLogical = uv * resolution;

    // curvatura
    vec2 crtUV = uv * 2.0 - 1.0;
    vec2 offset = crtUV.yx / CURVATURE;
    crtUV += crtUV * offset * offset;
    crtUV = crtUV * 0.5 + 0.5;
    crtUV = clamp(crtUV, 0.0, 1.0);

    // vinheta
    vec2 edge = smoothstep(0.0, BLUR, crtUV) * (1.0 - smoothstep(1.0 - BLUR, 1.0, crtUV));

    // Aberração cromática (com clamp para evitar vazamento)
    vec2 uvR = clamp((crtUV - 0.5) * CA_AMT + 0.5, 0.0, 1.0);
    vec2 uvG = crtUV;
    vec2 uvB = clamp((crtUV - 0.5) / CA_AMT + 0.5, 0.0, 1.0);

    vec3 col;
    col.r = Texel(tex, uvR).r;
    col.g = Texel(tex, uvG).g;
    col.b = Texel(tex, uvB).b;
    col = clamp(col, 0.0, 1.0);

    // brilho oscilante
    float brightness = 0.95 + 0.05 * sin(time * 3.0);

    // // Geração de ruído para brilho aleatório
    // float noise1 = rand(vec2(floor(scLogical.x * 10.0), floor(scLogical.y * 10.0)) + fract(time * 30.0));
    // float brightness = mix(0.95, 1.05, noise1); //0.95, 1.05



    // flicker com ruído
    // float noise = rand(sc + time);
    float noise = rand(vec2(uv.x * 128.0, uv.y * 128.0) + time);
    // float noise = hash(uv * 100.0 + time);

    // number flicker = mix(0.95, 1.05, noise);
    float flicker = clamp(mix(0.925, 1.05, noise), 0.9, 1.05);

    // aplicação final dos efeitos
    col *= edge.x * edge.y * brightness * flicker;

    // // linhas de varredura
    // // float lineY = fract(scLogical.y * 0.5); // simula mod(sc.y, 2.0)
    // // float lineX = fract(scLogical.x / 3.0); // simula mod(sc.x, 3.0)

    // float lineY = fract(scLogical.y / 1.5); // simula mod(sc.y, 2.0)
    // float lineX = fract(scLogical.x / 1.5); // simula mod(sc.x, 3.0)

    // float opacity = 0.85;

    // if (lineY < 0.3) // 0.5
    //     col *= opacity;
    // else if (lineX < 0.3) // 0.333
    //     col *= opacity;
    // else
    //     col *= 1. ;//+ (1. - opacity) * 0.2;

    float SCANLINE_INTENSITY = 0.2;
    float SCANLINE_FREQ = 3.14;

     // Scanline tipo senoidal (baseado em Y lógico do canvas)
    float scanline = 1.0 - SCANLINE_INTENSITY * 0.5 * (sin(scLogical.y * SCANLINE_FREQ) * 0.5 + 0.5);
    col *= scanline;

    // return vec4(col, 1.0) * color;
    return vec4(col * color.rgb, edge.x * edge.y * color.a);
}