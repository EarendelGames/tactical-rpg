#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer Params {
	vec2 raster_size;
	float depth_multiplier;
	float reserved;
} params;

layout(rgba16f, set = 0, binding = 1) uniform image2D color_image;
layout(set = 0, binding = 2) uniform sampler2D depth_texture;

const vec2 offset = vec2(0.0001);

void main() {
	vec2 size = params.raster_size;
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	vec2 uv_normalized = uv / size;

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	vec4 color = imageLoad(color_image, uv);
	float raw_depth = texture(depth_texture, uv_normalized + offset).r * params.depth_multiplier;
	if(color.a == 0.0){
		raw_depth = -(1.0/0.0);
	}
	imageStore(color_image, uv, vec4(color.rgb, raw_depth));
}