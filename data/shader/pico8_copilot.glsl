uniform vec3 palette[16];
uniform int size;
uniform float threshold; // (128 / 255)
uniform vec3 weights_dark; // Precomputed weights for dark pixels
uniform vec3 weights_light; // Precomputed weights for light pixels

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 coord)
{
    vec4 pix = Texel(tex, tc);
    int index = 0;
    float min_dist = 100000.0;

    for (int i = 0; i < min(size, palette.length()); i++) {
        vec3 distVec = pix.rgb - palette[i];
        float dist;

        // Choose weights based on the precomputed threshold
        if (pix.r < threshold) {
            dist = dot(weights_dark, distVec * distVec);
        } else {
            dist = dot(weights_light, distVec * distVec);
        }

        if (dist < min_dist) {
            min_dist = dist;
            index = i;
        }
    }

    return vec4(palette[index], pix.a);
}
