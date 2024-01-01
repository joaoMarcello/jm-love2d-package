// https://godotshaders.com/shader/noise-offset-wiggle/
// Created by nuzcraft and edited by JM for use in Löve2D

uniform Image NOISE_TEXTURE;
uniform float strength = 0.75;
uniform float scaling = 0.03;
uniform vec2 direction = vec2(1.0, -1.0);
uniform float speed = 0.01;
uniform float iTime = 0.0;
uniform float pixel_size = 0.0025;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
    float time = iTime;

	vec2 factor = direction * speed * time;
    // vec2 noise_time_index = fract(uv * scaling +  vec2(speed * iTime, speed * iTime));
    vec2 noise_time_index = fract(uv * scaling + factor);
    
	// vec4 noise_color = Texel(NOISE_TEXTURE, noise_time_index);
    // float noise_value = (noise_color.r - 0.5);

    float noise_value = Texel(NOISE_TEXTURE, noise_time_index).r - 0.5;

    // float pixel_size = 0.0025;

	uv += noise_value * pixel_size * strength;
    return Texel(tex, uv);
}
