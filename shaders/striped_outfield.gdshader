shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Two-tone striped lawn grass shader (WCC2 & Real Cricket broadcast style)
uniform vec3 grass_light : source_color = vec3(0.24, 0.58, 0.18);
uniform vec3 grass_dark : source_color = vec3(0.18, 0.44, 0.13);
uniform float stripe_width : hint_range(2.0, 15.0) = 6.0;
uniform float rough : hint_range(0.0, 1.0) = 0.85;

void fragment() {
    // Generate alternating lawn mower stripes along Z direction (pitch axis)
    float stripe = step(0.5, fract(NODE_POSITION_WORLD.z / (stripe_width * 2.0) + (NODE_POSITION_WORLD.x * 0.01)));
    vec3 col = mix(grass_dark, grass_light, stripe);
    
    // Add subtle radial gradient darkening towards the boundary
    float dist = length(NODE_POSITION_WORLD.xz);
    col *= clamp(1.0 - (dist * 0.0018), 0.75, 1.0);
    
    ALBEDO = col;
    ROUGHNESS = rough;
    SPECULAR = 0.15;
}
