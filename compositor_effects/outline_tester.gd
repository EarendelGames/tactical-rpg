extends Node3D

var time: float = 0.0
@onready var boxes : Node3D = find_child("Boxes", true, false)
var rot_v: Vector3 = Vector3(1.0, 0.0, 0.0)


func _physics_process(delta: float) -> void:
	time += delta
	$Camera3D.global_position.x = sin(time)
	$Camera3D.global_position.z = 3.195 + (1 + cos(time / 3)) * 2

	if randf() < 0.01:
		var children = boxes.get_children(true)
		for box:MeshInstance3D in children:
			box.set_layer_mask_value(11, false)
		children.pick_random().set_layer_mask_value(11, true)
	rot_v.x += randf_range(-0.1, 0.1)
	rot_v.y += randf_range(-0.1, 0.1)
	rot_v.z += randf_range(-0.1, 0.1)
	rot_v *= 0.99
	boxes.rotation += rot_v * delta * 0.01
	
