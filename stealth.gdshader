shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    float dist = distance(UV, vec2(0.5));
    // Calculate vignette alpha based on distance from center
    float alpha = smoothstep(0.3, 0.8, dist) * intensity;
    COLOR = vec4(color.rgb, alpha);
}