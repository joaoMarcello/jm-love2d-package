// https://www.shadertoy.com/view/llj3Dz
uniform float iTime = 0.0;
uniform float ratio = 288.0/512.0;
uniform vec2 center = vec2(0.0, 0.5);
const vec3 WaveParams = vec3(10.0, 0.1, 0.1 ); 

vec4 effect( vec4 color, Image tex, vec2 tc, vec2 sc )
{
    //Sawtooth function to pulse from centre.
    float time = 0.0;
    if(iTime <= 1.0){ time = iTime; }
    float offset = (time - floor(time)) / time;
	float CurrentTime = time * offset;    
    
	// vec3 WaveParams = vec3(10.0, 0.8, 0.1 ); 
   
	vec2 uv = tc;      

	float Dist = distance(vec2(uv.x, uv.y * ratio),
        vec2(center.x, center.y * ratio));
    
	vec4 Color = Texel(tex, uv);
    
    //Only distort the pixels within the parameter distance from the centre
    if ((Dist <= ((CurrentTime) + (WaveParams.z))) && 
        (Dist >= ((CurrentTime) - (WaveParams.z)))) 
    {
        //The pixel offset distance based on the input parameters
        float Diff = (Dist - CurrentTime); 
        float ScaleDiff = (1.0 - pow(abs(Diff * WaveParams.x), WaveParams.y)); 
        float DiffTime = (Diff  * ScaleDiff);
        
        //The direction of the distortion
        vec2 DiffTexCoord = normalize(uv - center);         
        
        //Perform the distortion and reduce the effect over time
        uv += ((DiffTexCoord * DiffTime) 
            / (CurrentTime * Dist * 40.0));

        Color = Texel(tex, uv);
        
        //Blow out the color and reduce the effect over time
        // Color += (Color * ScaleDiff) / (CurrentTime * Dist * 40.0);
    } 
    
    return Color;
}