# hex_cell.gd
@tool
extends Node3D

# The canonical position — this is what gets saved
@export var int_pos: Vector3i = Vector3i.ZERO

var _invalid_material: StandardMaterial3D
var _grid_handler: Node3D = null

var occupant: Node3D = null  # unit currently on this cell

var _highlight_material: StandardMaterial3D
var _highlighted: bool = false

signal cell_clicked(cell: Node3D)

func _ready() -> void:
	_invalid_material = StandardMaterial3D.new()
	_invalid_material.albedo_color = Color(1.0, 0.0, 0.0, 0.5)
	_invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.albedo_color = Color(0.2, 0.6, 1.0, 0.5)
	_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_find_grid_handler()
	_register()
	var body = find_child("Area3D")
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
	var parent = get_parent()
	if parent and parent.has_method("register_cell"):
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

	var new_int_pos = _grid_handler.world_to_int(position)
	if new_int_pos == int_pos:
		# Position unchanged, just correct float pos in case of drift
		position = _grid_handler.int_to_world(int_pos)
		return

	_unregister()
	int_pos = new_int_pos
	position = _grid_handler.int_to_world(int_pos)
	_register()

func update_from_int_pos() -> void:
	# Called by grid handler when cell_spacing or height_step changes
	if _grid_handler:
		position = _grid_handler.int_to_world(int_pos)

func set_invalid(invalid: bool) -> void:
	_apply_material_overrides(invalid)
	
func set_highlighted(highlighted: bool) -> void:
	_highlighted = highlighted
	_apply_material_overrides()

func _apply_material_overrides(force_invalid: bool = false) -> void:
	var mat: StandardMaterial3D = null
	if force_invalid:
		mat = _invalid_material
	elif _highlighted:
		mat = _highlight_material
	for child in get_children():
		if child is MeshInstance3D:
			child.material_override = mat
			return

func _on_input_event(_camera, event, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			cell_clicked.emit(self)
