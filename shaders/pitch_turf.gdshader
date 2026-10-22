shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Realistic Clay/Dirt cricket pitch with bowler's landing footmarks and crease scuffs
uniform vec3 pitch_clay_color : source_color = vec3(0.74, 0.65, 0.48);
uniform vec3 footmark_color : source_color = vec3(0.55, 0.46, 0.32);
uniform vec3 edge_grass_color : source_color = vec3(0.25, 0.50, 0.18);

void fragment() {
    vec2 uv = UV;
    vec3 col = pitch_clay_color;
    
    // Add subtle dry dirt variation
    float noise_val = sin(uv.x * 40.0) * cos(uv.y * 60.0) * 0.04;
    col += vec3(noise_val);
    
    // Bowler landing footmarks near both popping creases (Z: ~0.15 and ~0.85)
    float footmark_end1 = smoothstep(0.18, 0.10, uv.y) * smoothstep(0.04, 0.10, uv.y);
    float footmark_end2 = smoothstep(0.82, 0.90, uv.y) * smoothstep(0.96, 0.90, uv.y);
    float footmarks = (footmark_end1 + footmark_end2) * smoothstep(0.2, 0.5, abs(uv.x - 0.5));
    col = mix(col, footmark_color, footmarks * 0.65);
    
    // Edge grass blending on the sides of the pitch
    float edge_blend = smoothstep(0.42, 0.50, abs(uv.x - 0.5));
    col = mix(col, edge_grass_color, edge_blend * 0.7);
    
    ALBEDO = col;
    ROUGHNESS = 0.92;
    SPECULAR = 0.1;
}
