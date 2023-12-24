extern vec3 palette[ 4 ];
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
    vec4 pixel = Texel(texture, texture_coords);
    float avg = min(0.9999,max(0.0001,(pixel.r + pixel.g + pixel.b)/3.0));
    int index = int(avg*4.0);
    return vec4(palette[index], pixel.a);
}