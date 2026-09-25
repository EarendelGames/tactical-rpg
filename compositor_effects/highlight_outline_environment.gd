class_name HighlightOutlineEnvironment
extends WorldEnvironment

var subviewport_base:SubViewport
var subviewport_highlight:SubViewport
var subviews := []

static var highlight_layer := 11
@export var outline_color := Color(1.0, 1.0, 1.0, 1.0)
@export var highlight_color := Color(0.0, 0.404, 0.741, 0.757)

func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	var main_camera : Camera3D = get_tree().get_root().get_camera_3d()
	
	subviewport_base = SubViewport.new()
	subviewport_highlight = SubViewport.new()
	subviews = [subviewport_base, subviewport_highlight]
	for subview:SubViewport in subviews:
		subview.transparent_bg = true
		subview.use_hdr_2d = true
		subview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(subview)
		var sub_camera := Camera3D.new()
		if subview == subviewport_highlight:
			for i in range(1, 21):
				sub_camera.set_cull_mask_value(i, false)
			sub_camera.set_cull_mask_value(HighlightOutlineEnvironment.highlight_layer, true)
		sub_camera.fov = main_camera.fov
		
		subview.add_child(sub_camera)
		var remote := RemoteTransform3D.new()
		remote.use_global_coordinates = true
		remote.remote_path = sub_camera.get_path()
		main_camera.add_child(remote)
		var sub_compositor = Compositor.new()
		var depth_effect = DepthAlphaEffect.new()
		sub_compositor.compositor_effects = [depth_effect]
		sub_camera.set_compositor(sub_compositor)
	
	var highlight_outline_effect := HighlightOutlineEffect.new()
	highlight_outline_effect.outline_color = outline_color
	highlight_outline_effect.highlight_color = highlight_color
	
	compositor = Compositor.new()
	compositor.compositor_effects = [highlight_outline_effect]
	
	get_tree().get_root().size_changed.connect(_match_root_viewport)
	_match_root_viewport()
	
	
func _match_root_viewport() -> void:
	var size = get_tree().get_root().size
	
	subviewport_base.size = size
	subviewport_highlight.size = size
	for compositor_effect in compositor.compositor_effects:
		if "base_texture_rd" in compositor_effect:
			compositor_effect.base_texture_rd = RenderingServer.texture_get_rd_texture(subviewport_base.get_texture())
		if "highlighted_texture_rd" in compositor_effect:
			compositor_effect.highlighted_texture_rd = RenderingServer.texture_get_rd_texture(subviewport_highlight.get_texture())
