extern number radius;
extern number softness;
extern number opacity;
extern vec4 color;

vec4 effect(vec4 c, Image tex, vec2 tc, vec2 _)
{
    number aspect = love_ScreenSize.x / love_ScreenSize.y;
    // use different aspect when in portrait mode
    aspect = max(aspect, 1.0 / aspect); 
    number v = 1.0 - smoothstep(radius, radius-softness,
        length((tc - vec2(0.5)) * aspect));
    return mix(Texel(tex, tc), color, v*opacity);
}