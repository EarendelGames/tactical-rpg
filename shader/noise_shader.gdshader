shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled;

uniform sampler3D Noise : repeat_enable;

varying vec3 world_position;
uniform float grow = 0.1; // Controls how far the vertices are pushed
uniform vec3 albedo : source_color = vec3(1.0, 1.0, 1.0);

void vertex() {
    //world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_position = VERTEX; // Just use model position
    VERTEX += NORMAL * grow;
}

void fragment() {
	if (!FRONT_FACING) {
        NORMAL = -NORMAL;
    }
	METALLIC = 0.0;
	SPECULAR = 0.1;
	ROUGHNESS = 1.0;
	vec4 t = texture(Noise, world_position * 0.2);
	//ALBEDO = texture(Noise, world_position * 0.2).rgb;
	ALPHA = t.r > 0.5 ? 1.0 : 0.0;
	ALBEDO = albedo;
	
}