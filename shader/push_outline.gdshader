shader_type spatial;
render_mode cull_front, unshaded;

// Same idea as the inverted-hull StandardMaterial3D outline (cull_front + grow),
// but the grown vertex is also pulled toward the camera in view space by a
// fraction of the grow amount. This keeps the outline from being interrupted
// by nearby geometry, without changing the silhouette of the outline itself.

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float grow : hint_range(0.0, 0.1, 0.0001) = 0.01;
uniform float camera_push_ratio : hint_range(0.0, 10.0, 0.01) = 0.95;

void vertex() {
	vec3 view_normal = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);

	// Standard outline grow, done in view space along the (view-space) normal.
	view_pos.xyz += view_normal * grow;

	// Pull the grown vertex toward the camera. In view space the camera sits
	// at the origin looking down -Z, so the direction to the camera from any
	// point is simply normalize(-view_pos.xyz).
	vec3 to_camera = normalize(-view_pos.xyz);
	view_pos.xyz += to_camera * grow * camera_push_ratio;

	// Write clip-space position directly, bypassing the normal VERTEX
	// pipeline (which would otherwise reapply MODELVIEW_MATRIX for us).
	POSITION = PROJECTION_MATRIX * view_pos;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
