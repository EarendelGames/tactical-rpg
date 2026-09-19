#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer Params {
	vec2 raster_size;
	vec2 reserved;
	mat4 inv_proj_mat;
} params;

layout(rgba16f, set = 0, binding = 1) uniform image2D color_image;
layout(set = 0, binding = 2) uniform sampler2D depth_texture;
layout(set = 0, binding = 3) uniform sampler2D base_depth_texture;
layout(set = 0, binding = 4) uniform sampler2D highlight_depth_texture;

const vec2 offset = vec2(0.0001);
const float sample_size = 5.0;

float to_linear_depth(float raw_depth, vec2 uv) {
	vec3 ndc = vec3(uv * 2.0 - 1.0, raw_depth);
	vec4 view = params.inv_proj_mat * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

void main() {
	vec2 size = params.raster_size;
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	vec2 uv_normalized = uv / size;
	
	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}
	
	int checkSize = 10;
	int cx = uv.x / checkSize;
	int cy = uv.y / checkSize;

	float checker = float((cx + cy) % 2);
	
	vec4 color = imageLoad(color_image, uv);
	float raw_depth = texture(depth_texture, uv_normalized + offset).r;
	float depth = to_linear_depth(raw_depth, uv_normalized + offset);

	vec4 highlight_depth_color = texture(highlight_depth_texture, uv_normalized + offset);
	float highlight_depth = highlight_depth_color.r;
	vec4 base_depth_color = texture(base_depth_texture, uv_normalized + offset);
	float base_depth = base_depth_color.r;

	depth = -texture(base_depth_texture, uv_normalized + offset).r; //working base_depth
	//depth = to_linear_depth(texture(base_depth_texture, uv_normalized + offset).r, uv_normalized + offset); // works, but is worse in some ways
	depth = -texture(highlight_depth_texture, uv_normalized + offset).r; //working highlight_depth

	float is_highlighted = highlight_depth_color.a;
	float is_highlighted_front = clamp(1.0 + (highlight_depth - base_depth) * 100000.0, 0.0, 1.0);
	float is_highlighted_hidden = is_highlighted * (1.0 - is_highlighted_front);

	float depth_border = 1.0;
	//float depth_multiplier = 1.0;
	float depth_multiplier = 100.0; //working base_depth

	for (float x = -sample_size; x <= sample_size; x++) {
		for (float y = -sample_size; y <= sample_size; y++) {
			float sample_length = length(vec2(x, y));
			if (sample_length > sample_size)
				continue;
			vec2 offset_uv = uv_normalized + vec2(x, y) / size + offset;

			float raw_offset_depth = texture(depth_texture, offset_uv).r;
			float offset_depth = to_linear_depth(raw_offset_depth, offset_uv);
			offset_depth = -texture(base_depth_texture, offset_uv).r; //working base_depth
			//offset_depth = to_linear_depth(texture(base_depth_texture, offset_uv).r, offset_uv); // works, but is worse in some ways
			offset_depth = -texture(highlight_depth_texture, offset_uv).r; //working highlight_depth

			if (depth >= offset_depth){
				depth_border = min(depth_border, clamp(1.0 + 10.0 * (sample_length * 0.1 - (depth - offset_depth) * depth_multiplier), 0.0, 1.0));
			}
		}
		if (depth_border == 0.0)
			break;
	}
	
	imageStore(color_image, uv, vec4(color.rgb * depth_border, 1.0));

	//imageStore(color_image, uv, mix(vec4(vec3(raw_depth), color.a), vec4(vec3(highlight_depth), color.a), checker));
	//imageStore(color_image, uv, mix(vec4(vec3(base_depth), color.a), vec4(vec3(highlight_depth), color.a), checker));
	//imageStore(color_image, uv, mix(vec4(vec3(depth), color.a), vec4(vec3(highlight_depth), color.a), checker));

	//imageStore(color_image, uv, vec4(is_highlighted, is_highlighted_front, 0.0, 1.0));
	//imageStore(color_image, uv, vec4(mix(color.rgb, vec3(0.5, 1.0, 1.0), is_highlighted_hidden * 0.5), 1.0));
}