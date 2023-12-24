extern vec2 size;
extern number feedback;
extern vec2 screen_size;
vec4 effect(vec4 color, Image tex, vec2 tc, vec2 _)
{
    vec4 c = Texel(tex, tc);

    // average pixel color over 5 samples
    vec2 scale = screen_size.xy / size;
    tc = floor(tc * scale + vec2(.5));
    vec4 meanc = Texel(tex, tc/scale);
    meanc += Texel(tex, (tc+vec2( 1.0,  .0))/scale);
    meanc += Texel(tex, (tc+vec2(-1.0,  .0))/scale);
    meanc += Texel(tex, (tc+vec2(  .0, 1.0))/scale);
    meanc += Texel(tex, (tc+vec2(  .0,-1.0))/scale);

    return color * mix(.2*meanc, c, feedback);
}