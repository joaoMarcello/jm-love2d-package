uniform float time;
uniform Image simplex;
extern float canvas_width;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // the width of the simplex noise tile. You could also pass this in
    // as a uniform.
    float noise_width = 64.0;
    // the width of the sprite being drawn.
    float sprite_width = 64.0;

    // how fast should the textures scroll. Here we use one speed for all
    // directions, but we could use a different speed for each
    float speed = 0.1; //* (sprite_width / noise_width);

    // the amp (amplitude) controles the degree of the effect
    float amp = 0.25 * (sprite_width/canvas_width);   //0.00634765625;
    //float amp = 0.00634765625;

    // shift the noise index by time. Fract returns the fractional portion
    // of the float to ensure its between 0 and 1
    vec2 noise_time_index = fract(texture_coords * (sprite_width / noise_width) + vec2(speed * time, speed * time));

    // The noise colour channels r and g will form the base offset in x and y
    vec4 noisecolor = Texel(simplex, noise_time_index);

    // We use the b colour channel for for some counterflow
    float xy = noisecolor.b * 0.7071;
    noisecolor.r-=xy;
    noisecolor.g-=xy;

    // The displacement is the texture_coords offset by the noisecolor
    // In this example the offset is bound between + amp and - amp
    vec2 displacement = texture_coords + (((amp * 2.0) * vec2(noisecolor)) - amp);
    // Index the texture_coords for the sprite being drawn. This is the default
    // pixel colour
    vec4 texturecolor = Texel(tex, displacement);
    return texturecolor * color;
}