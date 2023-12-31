// https://love2d.org/forums/viewtopic.php?t=85284&sid=dbbc45ad7847be2605acfb59e6f24698
extern vec2 stepSize = vec2(1.0, 1.0);
vec4 resultCol;

vec4 effect( vec4 col, Image texture, vec2 texturePos, vec2 screenPos )
{
	// get color of pixels:
	number alpha = -4.0*texture2D( texture, texturePos ).a;
	alpha += texture2D( texture, texturePos + vec2( stepSize.x, 0.0 ) ).a;
	alpha += texture2D( texture, texturePos + vec2( -stepSize.x, 0.0 ) ).a;
	alpha += texture2D( texture, texturePos + vec2( 0.0, stepSize.y ) ).a;
	alpha += texture2D( texture, texturePos + vec2( 0.0, -stepSize.y ) ).a;

	// calculate resulting color
	resultCol = vec4( 0.4, 1.0, 0.1, alpha );
	// return color for current pixel
	return resultCol;
}