// id_encoder.gdshader
shader_type spatial;
render_mode unshaded;

// Instance uniform allows each object to have a unique ID color
// without creating a unique material resource for each one.
instance uniform vec3 object_id_color;

varying vec3 world_pos;

void vertex() {
    // 2. Assign the built-in INSTANCE_ID to your varying variable here
    world_pos = NODE_POSITION_WORLD;
}

void fragment() {
    // CAMERA_VISIBLE_LAYERS is a bitmask. 
    // Layer 2 is represented by the bitwise value 2 (1u << 1u).
    if ((CAMERA_VISIBLE_LAYERS & 1u) != 0u) {
        discard; 
    } else {
        // Render flat encoded ID inside the SubViewport pass
        //ALBEDO = object_id_color;
		ALBEDO = vec3(0.5 + 0.5*sin(world_pos.x * PI * 1000.0), 0.5 + 0.5*sin(world_pos.y * PI * 1000.0), 0.5 + 0.5*sin(world_pos.z * PI * 1000.0));
    }
}