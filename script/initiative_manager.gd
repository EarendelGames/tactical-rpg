# initiative_manager.gd
extends Node

@export var grid_handler: NodePath
@export var end_turn_button: NodePath

var _grid: Node3D
var _button: Button
var units: Array = []
var current_unit_index: int = 0
var _highlighted_cells: Array[Node3D] = []
var _reachable_cells: Array[Node3D] = []

func _ready() -> void:
	_grid = get_node(grid_handler)
	_button = get_node(end_turn_button)
	_button.pressed.connect(_on_end_turn)
	start_combat($Units.get_children())
	get_viewport().physics_object_picking = true

func start_combat(unit_list: Array) -> void:
	units = unit_list
	for unit in units:
		unit.roll_initiative()
	units.sort_custom(func(a, b): return a.initiative > b.initiative)
	_grid.rebuild_pos_lookup()
	_assign_units_to_cells()
	current_unit_index = 0
	_begin_turn()

func _assign_units_to_cells() -> void:
	for unit in units:
		var best_cell = _find_closest_open_cell(unit.global_position)
		if best_cell:
			unit.place_on_cell(best_cell)
		else:
			push_error("No open cell found for unit: " + unit.unit_name)

func _find_closest_open_cell(world_pos: Vector3) -> Node3D:
	var best_cell: Node3D = null
	var best_dist: float = INF
	for cell in _grid.get_children():
		if not cell.has_method("update_from_int_pos"):
			continue
		if cell.occupant != null:
			continue
		var dist = world_pos.distance_squared_to(cell.global_position)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
	return best_cell
	
func _begin_turn() -> void:
	var unit = units[current_unit_index]
	print("Turn: ", unit.unit_name)
	_show_movement_options(unit)

func _show_movement_options(unit: Node3D) -> void:
	_clear_highlights()
	_reachable_cells = _grid.get_reachable_cells(unit.current_cell, unit.movement_range)
	for cell in _reachable_cells:
		cell.set_highlighted(true)
		cell.cell_clicked.connect(_on_cell_clicked, CONNECT_ONE_SHOT)
	_highlighted_cells = _reachable_cells.duplicate()

func _on_cell_clicked(cell: Node3D) -> void:
	print("on_cell_clicked")
	var unit = units[current_unit_index]
	_clear_highlights()
	unit.place_on_cell(cell)

func _on_end_turn() -> void:
	_clear_highlights()
	current_unit_index = (current_unit_index + 1) % units.size()
	_begin_turn()

func _clear_highlights() -> void:
	for cell in _highlighted_cells:
		cell.set_highlighted(false)
		# Disconnect click signal if still connected
		if cell.cell_clicked.is_connected(_on_cell_clicked):
			cell.cell_clicked.disconnect(_on_cell_clicked)
	_highlighted_cells.clear()
	_reachable_cells.clear()
	
