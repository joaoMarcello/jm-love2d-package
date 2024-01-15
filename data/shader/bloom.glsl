extern number threshold = 1.0;

float luminance(vec3 color)
{
    // numbers make 'true grey' on most monitors, apparently
    return (0.212671 * color.r) + (0.715160 * color.g) + (0.072169 * color.b);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 _)
{
    vec4 texcolor = Texel(tex, uv);
    
    vec3 extract = smoothstep(threshold * 0.7, threshold, luminance(texcolor.rgb)) * texcolor.rgb;
    return vec4(extract, 1.0);
}