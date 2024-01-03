// https://www.shadertoy.com/view/wsGSR1
// Created by trisslotten and edited by JM for use with LÖVE2D
uniform float iTime = 0.0;
uniform float duration = 0.4;
uniform vec2 iResolution = vec2(512.0, 288.0);
uniform vec2 center = vec2(0.5, 0.5);

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc ){
    float time = iTime;//mod(iTime, duration);
    
    if(time > duration){ 
        return Texel(tex, uv);
    }

    float scaling = love_ScreenSize.x / iResolution.x;
    vec2 pos = center * iResolution * scaling;
    
    float radius = 5000.0 * time * time * scaling;
    float thickness_ratio = 0.1;
    
    float time_ratio = time/duration;
   	float shockwave = smoothstep(radius, radius - 2.0, length(pos - sc));

    shockwave *= smoothstep((radius - 2.0) * thickness_ratio,
        radius - 2.0, length(pos - sc));

    shockwave *= 1.0 - time_ratio;
    
    vec2 disp_dir = normalize(sc - pos);
    
    uv += 0.03 * disp_dir * shockwave;
    vec3 pix = Texel(tex, uv).rgb;
    
    return vec4(pix, 1.0);
}