shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform float falloff : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(UV, center);
    float mask = 1.0 - smoothstep(0.5 - falloff, 0.5, dist);
    
    vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount);
    vec4 blended = mix(blurred, COLOR, COLOR.a);
    
    COLOR = vec4(blended.rgb, mask);
}
