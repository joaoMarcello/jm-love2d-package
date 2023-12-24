// crt
extern vec2 distortionFactor;
extern vec2 scaleFactor;
extern number feather;

// scanline
extern number width;
extern number phase;
extern number thickness;
extern number opacity;
extern vec3 color_ex;
extern number screen_h;

vec4 scanln(vec4 c,Image tex,vec2 tc){
    number v=0.5 * (sin(tc.y*3.14159/width*screen_h+phase)+1.0);
    c.rgb-=(color_ex-c.rgb)*(pow(v,thickness)-1.0)*opacity;
    return c;
}

vec4 crt(vec4 c,Image tex,vec2 uv,vec2 px){
    uv=uv*2.0-vec2(1.0);
    uv*=scaleFactor;uv+=(uv.yx*uv.yx)*uv*(distortionFactor-1.0);
    number mask=(1.0-smoothstep(1.0-feather,1.0,abs(uv.x)))
        * (1.0-smoothstep(1.0-feather,1.0,abs(uv.y)));
    uv=(uv+vec2(1.0))/2.0;
    return c*Texel(tex,uv)*mask;
}

vec4 effect(vec4 c,Image tex,vec2 uv,vec2 px){
    return crt(scanln(c,tex,uv), tex,uv,px);
}