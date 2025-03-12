uniform vec3[16] palette;
uniform int size;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 coord)
{
    vec4 pix = Texel(tex, tc);
    int index = 0;
    float min_dist = 100000.0;

    for(int i=0; i < min(size, palette.length()); i++){
        vec3 distVec = (pix.rgb) - palette[i];
        float R = 0.5 * (pix.r + palette[i].r);

        float dist;
        if(R < 0.5019607843){ // (128 / 255)
            // dist = sqrt(2.0 * pow(distVec.r, 2.0)
            //     + 4.0 * pow(distVec.g, 2.0)
            //     + 3.0 * pow(distVec.b, 2.0)
            // );
            dist = (2.0 * (distVec.r * distVec.r)
                + 4.0 * (distVec.g * distVec.g)
                + 3.0 * (distVec.b * distVec.b)
            );
        }
        else{
            // dist = sqrt(3.0 * pow(distVec.r, 2.0)
            //     + 4.0 * pow(distVec.g, 2.0)
            //     + 2.0 * pow(distVec.b, 2.0)
            // );
            dist = (3.0 * (distVec.r * distVec.r)
                + 4.0 * (distVec.g * distVec.g)
                + 2.0 * (distVec.b * distVec.b)
            );
        }

        // dist = sqrt(dot(distVec, distVec));

        if (dist < min_dist){
            min_dist = dist;
            index = i;
        }
    }
    
    return vec4(palette[index], pix.a);
}