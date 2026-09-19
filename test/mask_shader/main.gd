extends Node3D

# Node paths assume the scene tree described alongside this script:
#   Main
#   ├── MainCamera (Camera3D)
#   ├── DirectionalLight3D
#   ├── Objects (Node3D)
#   │   ├── Sphere (MeshInstance3D)
#   │   ├── BoxA   (MeshInstance3D)
#   │   └── BoxB   (MeshInstance3D)
#   ├── MaskViewport (SubViewport)
#   │   └── MaskCamera3D (Camera3D)
#   └── CanvasLayer
#       └── MaskPreview (TextureRect)

@onready var main_camera: Camera3D = $MainCamera
@onready var mask_viewport: SubViewport = $MaskViewport
@onready var mask_camera: Camera3D = $MaskViewport/MaskCamera3D
@onready var mask_preview: TextureRect = $CanvasLayer/MaskPreview

# One flat, distinguishable color per test object -- stand-in for a real
# id-to-color encoding (e.g. packing an integer object ID into RGB).
var mask_colors := [Color(1, 0, 0), Color(0, 1, 0), Color(0, 0.4, 1)]


func _ready() -> void:
	var objects := $Objects.get_children()
	for i in objects.size():
		objects[i].set_instance_shader_parameter("mask_id", mask_colors[i % mask_colors.size()])

	mask_viewport.size = get_viewport().size
	#mask_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	mask_preview.texture = mask_viewport.get_texture()


func _process(_delta: float) -> void:
	# Keep the mask camera pinned to the main camera every frame so the
	# mask buffer always matches what's on screen when you capture it.
	mask_camera.global_transform = main_camera.global_transform
	mask_camera.fov = main_camera.fov

	if mask_viewport.size != get_viewport().size:
		mask_viewport.size = get_viewport().size


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Space / Enter, no Input Map setup needed
		capture_mask()


func capture_mask() -> void:
	RenderingServer.global_shader_parameter_set("mask_pass_active", true)
	mask_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	#mask_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	#await RenderingServer.frame_post_draw
	#RenderingServer.global_shader_parameter_set("mask_pass_active", false)
	#mask_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	#print("Mask captured -- check the preview panel.")
