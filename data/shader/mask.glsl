vec4 effect(vec4 color, Image text, vec2 tc, vec2 screen_coords){
    vec4 pixel = Texel(text, tc );
    if(pixel.r == 1.0 && pixel.b == 1.0)
    {
        return vec4(0.0,0.0,0.0,0.0);
    }
    return pixel;
}