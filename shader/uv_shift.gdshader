shader_type spatial;
render_mode diffuse_toon; 

uniform sampler2D albedo_texture : repeat_enable;
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 1.0);
uniform vec2 uv_scale = vec2(1.0, 1.0);

void fragment() {
	METALLIC = 0.0;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
	ALBEDO = (texture(albedo_texture, (UV - vec2(0.5, 0.5)) * uv_scale + uv_offset).rgb * 1.2 + vec3(-0.2)) * tint;
}