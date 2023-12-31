// https://love2d.org/forums/viewtopic.php?t=85284&sid=dbbc45ad7847be2605acfb59e6f24698

//https://blogs.love2d.org/content/let-it-glow-dynamically-adding-outlines-characters
extern vec2 stepSize = vec2(0.025, 0.025);
extern vec3 iColor = vec3(0.4, 1.0, 0.1);

vec4 effect( vec4 col, Image tex, vec2 uv, vec2 sc)
{
	// get color of pixels:
	float alpha = -4.0*Texel( tex, uv ).a;
	alpha += Texel( tex, uv + vec2( stepSize.x, 0.0 ) ).a;
	alpha += Texel( tex, uv + vec2( -stepSize.x, 0.0 ) ).a;
	alpha += Texel( tex, uv + vec2( 0.0, stepSize.y ) ).a;
	alpha += Texel( tex, uv + vec2( 0.0, -stepSize.y ) ).a;

	// calculate resulting color
	return vec4( iColor.rgb, alpha );
}