#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer Params {
	vec2 raster_size;
	float outline_size;
	float depth_difference_multiplier;
	vec4 outline_color;
	vec4 highlight_color;
	mat4 inv_proj_mat;
} params;

layout(rgba16f, set = 0, binding = 1) uniform image2D color_image;
layout(set = 0, binding = 2) uniform sampler2D depth_texture;
layout(set = 0, binding = 3) uniform sampler2D base_depth_texture;
layout(set = 0, binding = 4) uniform sampler2D highlight_depth_texture;

const vec2 offset = vec2(0.0001);
const float nan = -(1.0/0.0);

float to_linear_depth(float raw_depth, vec2 uv) {
	if(raw_depth == nan){
		return nan;
	}
	vec3 ndc = vec3(uv * 2.0 - 1.0, raw_depth);
	vec4 view = params.inv_proj_mat * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return view.z;
}

void main() {
	vec2 size = params.raster_size;
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	vec2 uv_normalized = uv / size;

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	int checkSize = 1;
	int cx = uv.x / checkSize;
	int cy = uv.y / checkSize;
	float checker = float((cx + cy) % 2);

	vec4 color = imageLoad(color_image, uv);
	//float raw_depth = texture(depth_texture, uv_normalized + offset).r; // for some reason is on a different scale

	vec4 highlight_depth_color = texture(highlight_depth_texture, uv_normalized + offset);
	float highlight_depth = highlight_depth_color.a;
	vec4 base_depth_color = texture(base_depth_texture, uv_normalized + offset);
	float base_depth = base_depth_color.a;

	highlight_depth = to_linear_depth(highlight_depth, uv_normalized + offset);
	base_depth = to_linear_depth(base_depth, uv_normalized + offset);

	float is_highlighted = highlight_depth > nan ? 1.0 : 0.0; // fails
	float is_highlighted_front = clamp(1.0 + (highlight_depth - base_depth) * 100000.0, 0.0, 1.0); // works
	float is_highlighted_hidden = is_highlighted * (1.0 - is_highlighted_front);

	float depth_border = 0.0;
	float sample_size = params.outline_size;
	for (float x = -sample_size; x <= sample_size; x++) {
		for (float y = -sample_size; y <= sample_size; y++) {
			float sample_length = length(vec2(x, y));
			if (sample_length > sample_size)
				continue;
			vec2 offset_uv = uv_normalized + vec2(x, y) / size + offset;
			float offset_highlight_depth = texture(highlight_depth_texture, offset_uv).a;
			offset_highlight_depth = to_linear_depth(offset_highlight_depth, offset_uv);
			float depth_difference = params.depth_difference_multiplier * (offset_highlight_depth - highlight_depth);

			if (highlight_depth < offset_highlight_depth){
				depth_border = max(depth_border, clamp(-10.0 * (sample_length * 0.1 - depth_difference), 0.0, 1.0));
			}
			if (depth_border == 1.0)
				break;
		}
		if (depth_border == 1.0)
			break;
	}

	vec3 highlighted_region = mix(highlight_depth_color.rgb, params.highlight_color.rgb, 0.5);
	vec3 pre_outline = mix(color.rgb, params.highlight_color.rgb, is_highlighted_front * params.highlight_color.a * checker);
	vec3 post_outline = mix(pre_outline, params.outline_color.rgb, depth_border * params.outline_color.a);

	imageStore(color_image, uv, vec4(post_outline, 1.0));
	//imageStore(color_image, uv, vec4(vec3(highlight_depth), 1.0));
	//imageStore(color_image, uv, vec4(vec3(highlight_depth_color.a), 1.0));
	//imageStore(color_image, uv, vec4(vec3(base_depth_color.a), 1.0));
	//imageStore(color_image, uv, vec4(vec3(highlight_depth_color.rgb), 1.0));
}