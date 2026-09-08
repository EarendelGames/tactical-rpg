shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_opaque, cull_back;

// --- Global styling (shared across every hex; tune here) ---
uniform float outline_thickness : hint_range(0.0, 0.3) = 0.05;
uniform float outline_pulse_speed : hint_range(0.0, 10.0) = 2.0;
uniform float outline_pulse_amount : hint_range(0.0, 1.0) = 0.35;
uniform float cursor_line_thickness : hint_range(0.0, 0.3) = 0.035;
uniform float cursor_wedge_alpha : hint_range(0.0, 1.0) = 0.35;

// --- Per-cell state, pushed from HexCell.gd via set_instance_shader_parameter() ---
// Edge/corner index convention (derived from the mesh generator, NOT necessarily
// GridHandler's NEIGHBOUR_OFFSETS order -- see note below):
//   edge k's outward normal points at angle k * 60deg from +X (local UV +u).
//   corner i sits between edge i and edge (i+1)%6, at angle (i + 0.5) * 60deg.
instance uniform vec4 overlay_color : source_color = vec4(0.0);
instance uniform vec4 outline_color_0 : source_color = vec4(0.0);
instance uniform vec4 outline_color_1 : source_color = vec4(0.0);
instance uniform vec4 outline_color_2 : source_color = vec4(0.0);
instance uniform vec4 outline_color_3 : source_color = vec4(0.0);
instance uniform vec4 outline_color_4 : source_color = vec4(0.0);
instance uniform vec4 outline_color_5 : source_color = vec4(0.0);
instance uniform bool cursor_cell_highlight = false;
instance uniform int cursor_edge_highlight = -1;
instance uniform int cursor_corner_highlight = -1;

const float APOTHEM = 0.86602540378; // cos(30 deg): inradius of a unit-circumradius hex

// Signed distance, in local hex space, from p to edge k's infinite line.
// Positive = outside that edge. Local hex space: circumradius = 1.0, center = origin,
// reconstructed from UV as (UV - 0.5) * 2.0 -- matches the mesh generator's
// UV projection (u = x / (2*corner_radius) + 0.5, v = z / (2*corner_radius) + 0.5).
float edge_dist(vec2 p, int k) {
	float ang = float(k) * (PI / 3.0);
	vec2 n = vec2(cos(ang), sin(ang));
	return dot(p, n) - APOTHEM;
}

// Standard alpha-over compositing.
vec4 blend_over(vec4 base, vec4 top) {
	float a = top.a + base.a * (1.0 - top.a);
	if (a <= 0.0) {
		return vec4(0.0);
	}
	vec3 rgb = (top.rgb * top.a + base.rgb * base.a * (1.0 - top.a)) / a;
	return vec4(rgb, a);
}

// Shortest angular distance between two angles (radians), result in [0, PI].
float angle_diff(float a, float b) {
	return abs(mod(a - b + PI, TAU) - PI);
}

void fragment() {
	vec2 local = (UV - vec2(0.5)) * 2.0;
	float local_angle = atan(local.y, local.x);
	if (local_angle < 0.0) {
		local_angle += TAU;
	}

	vec4 result = vec4(0.0);

	// 1) Fill overlay -- the mesh already exactly matches the hex footprint,
	// so this applies everywhere with no extra masking needed.
	result = blend_over(result, overlay_color);

	// 2) Range/effect outline. Find the nearest edge (the binding constraint
	// of the hex's convex boundary) and, if within the outline band, draw
	// that edge's resolved color there, with a time-based thickness/alpha pulse.
	float best_dist = -1000.0;
	int best_k = 0;
	for (int k = 0; k < 6; k++) {
		float d = edge_dist(local, k);
		if (d > best_dist) {
			best_dist = d;
			best_k = k;
		}
	}
	float pulse = 1.0 + outline_pulse_amount * sin(TIME * outline_pulse_speed);
	float band = outline_thickness * pulse;
	if (best_dist > -band && best_dist <= 0.001) {
		vec4 oc;
		if (best_k == 0) { oc = outline_color_0; }
		else if (best_k == 1) { oc = outline_color_1; }
		else if (best_k == 2) { oc = outline_color_2; }
		else if (best_k == 3) { oc = outline_color_3; }
		else if (best_k == 4) { oc = outline_color_4; }
		else { oc = outline_color_5; }
		float edge_t = clamp(1.0 - (-best_dist) / band, 0.0, 1.0);
		oc.a *= edge_t * clamp(pulse, 0.0, 1.5);
		result = blend_over(result, oc);
	}

	// 3) Cursor highlight -- always white, drawn on top of everything else.
	if (cursor_cell_highlight && best_dist > -cursor_line_thickness && best_dist <= 0.001) {
		result = blend_over(result, vec4(1.0, 1.0, 1.0, 1.0));
	}
	if (cursor_edge_highlight >= 0) {
		float edge_ang = float(cursor_edge_highlight) * (PI / 3.0);
		if (angle_diff(local_angle, edge_ang) < (PI / 6.0)) {
			result = blend_over(result, vec4(1.0, 1.0, 1.0, cursor_wedge_alpha));
		}
	}
	if (cursor_corner_highlight >= 0) {
		float corner_ang = (float(cursor_corner_highlight) + 0.5) * (PI / 3.0);
		if (angle_diff(local_angle, corner_ang) < (PI / 6.0)) {
			result = blend_over(result, vec4(1.0, 1.0, 1.0, cursor_wedge_alpha));
		}
	}

	ALBEDO = result.rgb;
	ALPHA = result.a;
}
