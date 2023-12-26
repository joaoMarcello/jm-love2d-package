extern vec2 inputSize;
extern vec2 textureSize;

#define distortion 0.2

vec2 radialDistortion(vec2 coord, const vec2 ratio)
{
	float offsety = 1.0 - ratio.y;
	coord.y -= offsety;
	coord /= ratio;
	
	vec2 cc = coord - 0.5;
	float dist = dot(cc, cc) * distortion;
	vec2 result = coord + cc * (1.0 + dist) * dist;
	
	result *= ratio;
	result.y += offsety;
	
	return result;
}

vec4 checkTexelBounds(Image texture, vec2 coords, vec2 bounds)
{
	vec2 ss = step(coords, vec2(bounds.x, 1.0)) * step(vec2(0.0, bounds.y), coords);
	return Texel(texture, coords) * ss.x * ss.y;
}


vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
	vec2 coords = radialDistortion(texture_coords, inputSize / textureSize);
	
	vec4 texcolor = checkTexelBounds(texture, coords, vec2(inputSize.x / textureSize.x, 1.0 - inputSize.y / textureSize.y));
	texcolor.a = 1.0;
	
	return texcolor;
}

