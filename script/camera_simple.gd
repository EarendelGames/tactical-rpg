class_name CameraSimple
extends Camera3D

@export var move_speed := 1.0
@export var zoom_speed := 0.1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	handle_input(delta)
	
func handle_input(delta):
	var input_vector = Vector2(
		int(Input.is_action_pressed("camera_move_right")) - int(Input.is_action_pressed("camera_move_left")),
		int(Input.is_action_pressed("camera_move_forward")) - int(Input.is_action_pressed("camera_move_backward"))
	)
		
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()

		var forward = -global_transform.basis.z
		var right = global_transform.basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()

		var movement = (right * input_vector.x + forward * input_vector.y) * move_speed * delta * (1.0 + global_position.y)
		global_position += movement

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP: zoom_with_factor(event.factor)
			MOUSE_BUTTON_WHEEL_DOWN: zoom_with_factor(-event.factor)

func zoom_with_factor(f: float) -> void:
	global_position -= global_transform.basis.z * f * zoom_speed * global_position.y
