// https://www.shadertoy.com/view/wsGSR1
uniform float iTime = 0.0;

vec4 effect( vec4 color, Image tex, vec2 tc, vec2 screen_coord )
{
    vec2 uv = tc;
    float ratio = 288.0/512.0;
    vec2 sc = vec2(tc.x , tc.y);
    vec2 pos = vec2(256.0, 135.0);
    
    float duration = 0.4;
    float time = mod(iTime, duration);
    float radius = 2000.0 * time * time;
    float thickness_ratio = 0.4;
    
    float time_ratio = time/duration;
   	float shockwave = smoothstep(radius, radius-2.0, length(pos - sc));

    shockwave *= smoothstep((radius - 2.0) * thickness_ratio,
        radius - 2.0, length(pos - sc));

    shockwave *= 1.0 - time_ratio;
    
    vec2 disp_dir = normalize(sc-pos);
    
    uv += 0.2 * disp_dir * shockwave;
    vec3 pix = Texel(tex, uv).rgb;
    
    return vec4(pix, 1.0);
}