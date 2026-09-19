@tool
extends CompositorEffect
class_name HighlightOutlineEffect

var rd := RenderingServer.get_rendering_device()
var shader := RID()
var pipeline := RID()
var parameter_storage_buffer := RID()
var depth_sampler := RID()

var base_texture_sampler := RID()
var highlighted_texture_sampler := RID()
var normal_sampler := RID()

#$WorldEnvironment.compositor.compositor_effects[1].base_texture_rd = RenderingServer.texture_get_rd_texture($SubViewportBase.get_texture())
var base_texture_rd = null
#$WorldEnvironment.compositor.compositor_effects[1].highlighted_texture_rd = RenderingServer.texture_get_rd_texture($SubViewportHighlight.get_texture())
var highlighted_texture_rd = null

@export var outline_size := 2.0;
@export var depth_difference_multiplier := 1.0;
@export var outline_color := Color(1.0, 1.0, 1.0, 1.0)
@export var highlight_color := Color(0.0, 0.396, 0.769, 0.761)

func _init() -> void:
	var shader_file: RDShaderFile = load("res://compositor_effects/highlight_outline.glsl")
	var shader_spirv := shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	var data := PackedFloat32Array()
	data.resize(28)
	data.fill(0)
	var parameter_data := data.to_byte_array()
	parameter_storage_buffer = rd.storage_buffer_create(parameter_data.size(), parameter_data)
	
	var depth_sampler_state := RDSamplerState.new()
	depth_sampler = rd.sampler_create(depth_sampler_state)
	
	var base_sampler_state := RDSamplerState.new()
	base_texture_sampler = rd.sampler_create(base_sampler_state)
	
	var highlighted_sampler_state := RDSamplerState.new()
	highlighted_texture_sampler = rd.sampler_create(highlighted_sampler_state)
	
	var normal_sampler_state := RDSamplerState.new()
	normal_sampler = rd.sampler_create(normal_sampler_state)
	
	needs_normal_roughness = true
	#effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_OPAQUE

func _render_callback(_callback_type: int, render_data: RenderData) -> void:
	if base_texture_rd == null or highlighted_texture_rd == null: return
	if Engine.is_editor_hint(): return
	
	var render_scene_buffers: RenderSceneBuffersRD = render_data.get_render_scene_buffers()
	if !render_scene_buffers:
		return

	var size := render_scene_buffers.get_internal_size()
	if size.x == 0 or size.y == 0:
		return
	
	var groups: Vector3i = Vector3((size.x - 1.0) / 8.0 + 1.0, (size.y - 1.0) / 8.0 + 1.0, 1.0).floor()
	var inv_proj_mat := render_data.get_render_scene_data().get_cam_projection().inverse()
	var inv_proj_mat_array := PackedVector4Array([inv_proj_mat.x, inv_proj_mat.y, inv_proj_mat.z, inv_proj_mat.w])
	
	var parameters := PackedFloat32Array([size.x, size.y, outline_size, depth_difference_multiplier])
	
	var parameter_data := parameters.to_byte_array()
	parameter_data.append_array(_color_to_byte_array(outline_color))
	parameter_data.append_array(_color_to_byte_array(highlight_color))
	parameter_data.append_array(inv_proj_mat_array.to_byte_array())
	rd.buffer_update(parameter_storage_buffer, 0, parameter_data.size(), parameter_data)
	
	var parameter_uniform := RDUniform.new()
	parameter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameter_uniform.binding = 0
	parameter_uniform.add_id(parameter_storage_buffer)
	
	var color_layer_uniform := RDUniform.new()
	color_layer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	color_layer_uniform.binding = 1
	color_layer_uniform.add_id(render_scene_buffers.get_color_layer(0))
	
	var depth_layer_uniform := _texture_sampler_uniform(render_scene_buffers.get_depth_layer(0), depth_sampler, 2)
	var base_texture_uniform := _texture_sampler_uniform(base_texture_rd, base_texture_sampler, 3)
	var highlighted_texture_uniform := _texture_sampler_uniform(highlighted_texture_rd, highlighted_texture_sampler, 4)
	
	var normal_texture_uniform := _texture_sampler_uniform(render_scene_buffers.get_texture("forward_clustered", "normal_roughness"), normal_sampler, 5)
	
	var bindings: Array[RDUniform] = [
		parameter_uniform,
		color_layer_uniform,
		depth_layer_uniform,
		base_texture_uniform,
		highlighted_texture_uniform,
		normal_texture_uniform
	]
	
	var uniform_set := rd.uniform_set_create(bindings, shader, 0)
	var compute_list := rd.compute_list_begin()
	
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, groups.x, groups.y, groups.z)
	rd.compute_list_end()
	
	rd.free_rid(uniform_set)

func _color_to_byte_array(c:Color) -> PackedByteArray:
	return PackedFloat32Array([c.r,c.g,c.b,c.a]).to_byte_array()
	
func _texture_sampler_uniform(texture, sampler, binding) -> RDUniform:
	var uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.binding = binding 
	uniform.add_id(sampler)
	uniform.add_id(texture)
	return uniform
