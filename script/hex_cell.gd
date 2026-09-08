# hex_cell.gd
@tool
class_name HexCell
extends Node3D

# The canonical position — this is what gets saved
@export var int_pos: Vector3i = Vector3i.ZERO

# Movement cost to enter this cell. Default 1.
# Higher values require more movement points.
@export var movement_cost: int = 1

@onready var mesh: MeshInstance3D = $Mesh
@onready var area: Area3D = $Area3D
@onready var shape: HexShape3D = $Area3D/HexShape3D

var _grid_handler: GridHandler = null

var occupant: Unit = null

# Callbacks registered by traps or terrain effects.
# Each entry is a Callable: (tree: EventTree, parent_node: EventNode, moving_unit: Unit) -> void
var _movement_triggers: Array = []

# --- Highlight state ---
# Two overlap-able layers: "range" (movement range / reach) and "effect" (AOE /
# affected cells). Each layer has a fill color and a 6-bit outline mask, where
# bit i means edge i is an outer edge of that layer's region on this cell.
# Edge/corner index order matches GridHandler's NEIGHBOUR_OFFSETS direction order.
var range_layer_color: Color = Color(0, 0, 0, 0)
var range_outline_mask: int = 0
var effect_layer_color: Color = Color(0, 0, 0, 0)
var effect_outline_mask: int = 0
enum Edge { NONE = 0, E0 = 1, E1 = 2, E2 = 4, E3 = 8, E4 = 16, E5 = 32, ALL = 63}

# Cursor targeting indicator. Only one of these is meaningful at a time,
# depending on the ability's selection mode (cell / edge / corner).
var cursor_cell_highlight: bool = false
var cursor_edge_highlight: int = -1   # 0-5, -1 = off
var cursor_corner_highlight: int = -1 # 0-5, -1 = off

# Shared across every HexCell instance so they all draw with one material and
# differ only via per-instance shader parameters.
static var _shared_material: ShaderMaterial = null

func _ready() -> void:

	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_area_3d_input_event)

	_assign_shader_material()
	_push_shader_params()

	_find_grid_handler()
	_register()
	var body := find_child("Area3D")
	if body:
		body.input_event.connect(_on_input_event)
	if Engine.is_editor_hint():
		set_notify_transform(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_snap_to_grid()
	elif what == NOTIFICATION_PREDELETE:
		_unregister()

func _find_grid_handler() -> void:
	var parent := get_parent()
	if parent is GridHandler:
		_grid_handler = parent

func _register() -> void:
	_find_grid_handler()
	if _grid_handler:
		_grid_handler.register_cell(self, int_pos)

func _unregister() -> void:
	if _grid_handler:
		_grid_handler.unregister_cell(self, int_pos)

func _snap_to_grid() -> void:
	if not _grid_handler:
		_find_grid_handler()
	if not _grid_handler:
		return
	rotation = Vector3.ZERO
	scale = Vector3.ONE * _grid_handler.cell_spacing
	var new_int_pos := _grid_handler.world_to_int(position)
	if new_int_pos == int_pos:
		position = _grid_handler.int_to_world(int_pos)
		return
	_unregister()
	int_pos = new_int_pos
	position = _grid_handler.int_to_world(int_pos)
	_register()

func update_from_int_pos() -> void:
	if _grid_handler:
		position = _grid_handler.int_to_world(int_pos)
		scale = Vector3.ONE * _grid_handler.cell_spacing

func set_depth(depth: int) -> void:
	shape.depth = depth

# --- Shader material ---

func _assign_shader_material() -> void:
	if _shared_material == null:
		var shader: Shader = preload("res://shader/hex_cell.gdshader")
		_shared_material = ShaderMaterial.new()
		_shared_material.shader = shader
	mesh.material_override = _shared_material

# --- Highlight layer API ---
# Abilities / grid state call these. The cell only recomputes and re-pushes
# to the shader when something actually changed, per the caller's diff.

func set_range_layer(color: Color, outline_mask: int = 0) -> void:
	if color == range_layer_color and outline_mask == range_outline_mask:
		return
	range_layer_color = color
	range_outline_mask = outline_mask
	_push_shader_params()

func clear_range_layer() -> void:
	set_range_layer(Color(0, 0, 0, 0), 0)

func set_effect_layer(color: Color, outline_mask: int = 0) -> void:
	if color == effect_layer_color and outline_mask == effect_outline_mask:
		return
	effect_layer_color = color
	effect_outline_mask = outline_mask
	_push_shader_params()

func clear_effect_layer() -> void:
	set_effect_layer(Color(0, 0, 0, 0), 0)

func set_cursor_cell(highlighted: bool) -> void:
	if highlighted == cursor_cell_highlight:
		return
	cursor_cell_highlight = highlighted
	_push_shader_params()

func set_cursor_edge(edge: int) -> void:
	if edge == cursor_edge_highlight:
		return
	cursor_edge_highlight = edge
	_push_shader_params()

func set_cursor_corner(corner: int) -> void:
	if corner == cursor_corner_highlight:
		return
	cursor_corner_highlight = corner
	_push_shader_params()

func clear_cursor() -> void:
	set_cursor_cell(false)
	set_cursor_edge(-1)
	set_cursor_corner(-1)

# --- Blend + push ---

# rgb = lerp weighted by relative alpha, alpha = sum of both (clamped to 1).
func _blend(a: Color, b: Color) -> Color:
	var total_alpha := a.a + b.a
	if total_alpha <= 0.0:
		return Color(0, 0, 0, 0)
	var t := b.a / total_alpha
	return Color(
		lerp(a.r, b.r, t),
		lerp(a.g, b.g, t),
		lerp(a.b, b.b, t),
		minf(total_alpha, 1.0)
	)

func _edge_outline_color(edge: int) -> Color:
	var bit := 1 << edge
	var range_active := (range_outline_mask & bit) != 0
	var effect_active := (effect_outline_mask & bit) != 0
	if range_active and effect_active:
		return _blend(range_layer_color, effect_layer_color)
	elif range_active:
		return range_layer_color
	elif effect_active:
		return effect_layer_color
	return Color(0, 0, 0, 0)

func _push_shader_params() -> void:
	if mesh == null:
		return
	mesh.set_instance_shader_parameter("overlay_color", _blend(range_layer_color, effect_layer_color))
	for i in 6:
		mesh.set_instance_shader_parameter("outline_color_%d" % i, _edge_outline_color(i))
	mesh.set_instance_shader_parameter("cursor_cell_highlight", cursor_cell_highlight)
	mesh.set_instance_shader_parameter("cursor_edge_highlight", cursor_edge_highlight)
	mesh.set_instance_shader_parameter("cursor_corner_highlight", cursor_corner_highlight)

# --- Input ---

func _on_input_event(_camera, event, pos, _normal, _shape_idx) -> void: # pos is world position
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_grid_handler.cell_clicked(self, pos, _normal)

func _on_mouse_entered() -> void:
	_grid_handler.set_hovered_cell(self)

func _on_mouse_exited() -> void:
	_grid_handler.unset_hovered_cell(self)
	
func _on_area_3d_input_event(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseMotion:
		_grid_handler.cell_mouse_motion(self, event_position)


# --- Movement triggers ---

func add_movement_trigger(callable: Callable) -> void:
	_movement_triggers.append(callable)

func remove_movement_trigger(callable: Callable) -> void:
	_movement_triggers.erase(callable)

func fire_movement_triggers(tree: SequenceTree, parent_node: EventNode, moving_unit: Unit) -> void:
	for trigger in _movement_triggers:
		trigger.call(tree, parent_node, moving_unit)
