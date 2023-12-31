vec3 palette[16] = vec3[16](
vec3(0.0, 0.0, 0.0),
vec3(29.0/255.0, 43.0/255.0, 83.0/255.0),
vec3(126.0/255.0, 37.0/255.0, 83.0/255.0),
vec3(0.0, 135.0/255.0, 81.0/255.0),
vec3(171.0/255.0, 82.0/255.0, 54.0/255.0),
vec3(95.0/255.0, 87.0/255.0, 79.0/255.0),
vec3(194.0/255.0, 195.0/255.0, 199.0/255.0),
vec3(1.0, 241.0/255.0, 232.0/255.0),
vec3(1.0, 0.0, 77.0/255.0),
vec3(1.0, 163.0/255.0, 0.0),
vec3(1.0, 236.0/255.0, 39.0/255.0),
vec3(0.0, 228.0/255.0, 54.0/255.0),
vec3(41.0/255.0, 173.0/255.0, 1.0),
vec3(131.0/255.0, 118.0/255.0, 156.0/255.0),
vec3(1.0, 119.0/255.0, 168.0/255.0),
vec3(1.0, 204.0/255.0, 170.0/255.0));

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 coord)
{
    vec4 pix = Texel(tex, tc);
    int index = 0;
    float min_dist = 100000.0;

    for(int i=0; i < 16; i++){
        // float dist = distance(pix, vec4(palette[i],1.0));

        vec3 distVec = (pix.rgb) - palette[i];
        float R = 0.5 * (pix.r + palette[i].r);

        float dist;
        if(R < 0.5019607843){ // (128 / 255)
            dist = sqrt(2.0 * pow(distVec.r, 2.0)
                + 4.0 * pow(distVec.g, 2.0)
                + 3.0 * pow(distVec.b, 2.0)
            );
        }
        else{
            dist = sqrt(3.0 * pow(distVec.r, 2.0)
                + 4.0 * pow(distVec.g, 2.0)
                + 2.0 * pow(distVec.b, 2.0)
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