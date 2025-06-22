extern number time;
extern vec2 resolution;

extern number CURVATURE;
extern number BLUR;
extern number CA_AMT;

number rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    // Coordenadas lógicas no canvas
    vec2 scLogical = uv * resolution;
    
    // Cálculo da curvatura sem clamp para obter a máscara de área válida
    vec2 crtUV_unclamped = uv * 2.0 - 1.0;
    vec2 offset = crtUV_unclamped.yx / CURVATURE;
    crtUV_unclamped += crtUV_unclamped * offset * offset;
    vec2 curveUV = crtUV_unclamped * 0.5 + 0.5;
    // validMask = 1 para pixels dentro [0,1]; 0 caso contrário
    float validMask = step(0.0, curveUV.x) * step(0.0, curveUV.y) *
                      step(curveUV.x, 1.0) * step(curveUV.y, 1.0);
    // Para amostragem segura, usa-se o clamp
    vec2 crtUV = clamp(curveUV, 0.0, 1.0);
    
    // Vinheta (fade suave nas bordas)
    vec2 edge = smoothstep(0.0, BLUR, crtUV) * (1.0 - smoothstep(1.0 - BLUR, 1.0, crtUV));
    
    // Aberração cromática
    vec2 uvR = clamp((crtUV - 0.5) * CA_AMT + 0.5, 0.0, 1.0);
    vec2 uvG = crtUV;
    vec2 uvB = clamp((crtUV - 0.5) / CA_AMT + 0.5, 0.0, 1.0);
    
    vec3 col;
    col.r = Texel(tex, uvR).r;
    col.g = Texel(tex, uvG).g;
    col.b = Texel(tex, uvB).b;
    col = clamp(col, 0.0, 1.0);
    
    // Brilho oscilante e flicker
    float brightness = 0.95 + 0.05 * (sin(time * 3.0) + 0.5 * sin(time * 7.0)) / 1.5;
    float noise = rand(vec2(uv.x * 128.0, uv.y * 128.0) + time);
    float flicker = clamp(mix(0.925, 1.05, noise), 0.9, 1.05);
    col *= edge.x * edge.y * brightness * flicker;
    
    // Scanline senoidal baseada em scLogical.y
    float scanline = 1.0 - 0.2 * 0.5 * (sin(scLogical.y * 3.14) * 0.5 + 0.5);
    col *= scanline;
    
    // Ghosting/Burn-in com canal alpha
    vec4 baseColor = vec4(col, edge.x * edge.y * color.a);
    vec2 ghostOffset = vec2(0.005 * sin(time * 3.), 0.005 * cos(time * 3.));
    vec2 ghostUV_raw = curveUV + ghostOffset;
    float ghostMask = step(0.0, ghostUV_raw.x) * step(0.0, ghostUV_raw.y) *
                      step(ghostUV_raw.x, 1.0) * step(ghostUV_raw.y, 1.0);
    vec4 ghostColor = Texel(tex, clamp(ghostUV_raw, 0.0, 1.0)) * ghostMask;
    vec4 effectColor = mix(baseColor, ghostColor, 0.05);
    
    // Phosphor Glow – Blur de quatro amostragens
    float blurOffset = 1.0 / resolution.x;
    vec4 glowSum = Texel(tex, crtUV + vec2(-blurOffset, -blurOffset)) +
                   Texel(tex, crtUV + vec2( blurOffset, -blurOffset)) +
                   Texel(tex, crtUV + vec2(-blurOffset,  blurOffset)) +
                   Texel(tex, crtUV + vec2( blurOffset,  blurOffset));
    vec4 glow = glowSum * 0.25;
    effectColor = mix(effectColor, glow, 0.05);
    
    // Interlacing – variação de brilho em linhas alternadas
    float interlace = step(0.5, mod(scLogical.y, 2.0));
    effectColor.rgb *= mix(vec3(1.0), vec3(0.9), interlace);
    
    // Ajuste de Saturação e Contraste (desbota as cores)
    float luminance = dot(effectColor.rgb, vec3(0.299, 0.587, 0.114));
    vec3 gray = vec3(luminance);
    effectColor.rgb = mix(gray, effectColor.rgb, 0.9);
    
    // Preserva o fundo do canvas:
    // Onde validMask for 0 (fora da área válida), forçamos o fundo (preto)
    effectColor = mix(vec4(0.0), effectColor, validMask);
    
    // Retorna o resultado; a multiplicação por "color" pode ser omitida se "color"
    // já representar o fundo desejado.
    return effectColor * color;
}