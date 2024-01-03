#define PI 3.14159265359

uniform vec2 scaling = vec2(1.0/512.0, 1.0/288.0);
uniform float iTime = 0.0;
uniform float speed = 5.0;
uniform int N = 18; // quantidade de segmentos que divide a tela em y
uniform float delay = 0.1; // range [0-1]
uniform vec2 direction = vec2(1.0, 0.0);

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc){
    float stepHoriz = scaling.x * 1.0;
    float time = iTime * speed;

    float segment = floor((uv.y / (1.0/N)) + 0.5); // 0.02 = 1 / 50
    uv.x += (stepHoriz 
        * sin((time + (PI * delay) * segment)))
        * direction.x;

    segment = floor(uv.x / (1.0/8) + 0.5);
    uv.y += ((scaling.y*2.0) 
        * sin((time*0.35 + (PI * delay * 0.5) * segment)))
        * direction.y;

    // if(uv.x < 0.0 || uv.x > 1.0){
    //     return vec4(0.0);
    // }

    return Texel(tex, uv) * color;
}