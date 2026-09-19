shader_type spatial;

// Flipped by the mask-capture script right before it force-renders the
// mask SubViewport, then flipped back. Every material that wants to
// participate in ID-mask baking declares this same global uniform.
global uniform bool mask_pass_active;

// Set per-object via set_instance_shader_parameter("mask_id", color),
// even though every object here shares the SAME ShaderMaterial resource.
instance uniform vec3 mask_id : source_color;

uniform vec4 albedo_color : source_color = vec4(0.75, 0.75, 0.78, 1.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	if (mask_pass_active) {
		// Black albedo + exact-value emission = the mask viewport reads
		// back mask_id almost untouched by ambient/lighting.
		ALBEDO = vec3(0.0);
		EMISSION = mask_id;
	} else {
		ALBEDO = albedo_color.rgb;
		ROUGHNESS = roughness_value;
	}
}
