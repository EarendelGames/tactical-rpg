# hex_cell.gd
@tool
class_name HexCell
extends Node3D

# The canonical position — this is what gets saved
@export var int_pos: Vector3i = Vector3i.ZERO

# Movement cost to enter this cell. Default 1.
# Higher values require more movement points.
@export var movement_cost: int = 1

@onready var mesh_lower: MeshInstance3D = $MeshLower
@onready var mesh_higher: MeshInstance3D = $MeshHigher
@onready var area: Area3D = $Area3D

var _highlighted: bool = false
var _highlight_material: StandardMaterial3D

var _hover_highlighted: bool = false
var _hover_highlight_material: StandardMaterial3D

var _grid_handler: GridHandler = null

var occupant: Unit = null

# Callbacks registered by traps or terrain effects.
# Each entry is a Callable: (tree: EventTree, parent_node: EventNode, moving_unit: Unit) -> void
var _movement_triggers: Array = []

signal cell_clicked(cell: HexCell)
signal mouse_entered(cell: HexCell)
signal mouse_exited(cell: HexCell)

func _ready() -> void:
	
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.albedo_color = Color(0.2, 0.6, 1.0, 0.5)
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	_hover_highlight_material = StandardMaterial3D.new()
	_hover_highlight_material.albedo_color = Color(0.2, 0.6, 1.0, 0.5)
	_hover_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
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

# --- Materials ---

func set_invalid(invalid: bool) -> void:
	if invalid:
		set_highlighted(true, Color(1.0, 0.0, 0.0, 0.5))
	else:
		set_highlighted(false)

func set_highlighted(highlighted: bool, color: Color = Color(0.2, 0.6, 1.0, 0.5)) -> void:
	_highlighted = highlighted
	_apply_highlighted_material_overrides(color)

func _apply_highlighted_material_overrides(color: Color) -> void:
	if _highlighted:
		_highlight_material.albedo_color = color
		mesh_higher.material_override = _highlight_material
	else:
		mesh_higher.material_override = null
		
func set_hover_highlighted(highlighted: bool, color: Color = Color(0.6, 0.5, 0.1, 0.5)) -> void:
	_hover_highlighted = highlighted
	_apply_hover_highlighted_material_overrides(color)

func _apply_hover_highlighted_material_overrides(color: Color) -> void:
	if _hover_highlighted:
		_hover_highlight_material.albedo_color = color
		mesh_lower.material_override = _hover_highlight_material
	else:
		mesh_lower.material_override = null

# --- Input ---

func _on_input_event(_camera, event, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cell_clicked.emit()

func _on_mouse_entered() -> void:
	mouse_entered.emit()
	_grid_handler.set_hovered_cell(self)

func _on_mouse_exited() -> void:
	mouse_exited.emit()
	_grid_handler.unset_hovered_cell(self)

# --- Movement triggers ---

func add_movement_trigger(callable: Callable) -> void:
	_movement_triggers.append(callable)

func remove_movement_trigger(callable: Callable) -> void:
	_movement_triggers.erase(callable)

func fire_movement_triggers(tree: SequenceTree, parent_node: EventNode, moving_unit: Unit) -> void:
	for trigger in _movement_triggers:
		trigger.call(tree, parent_node, moving_unit)
