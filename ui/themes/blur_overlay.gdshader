shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;

void fragment() {
    vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount);
    // Mix the blurred background with the ColorRect's color (tint) based on its alpha
    COLOR = mix(blurred, COLOR, COLOR.a);
    COLOR.a = 1.0; 
}
