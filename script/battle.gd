# battle/battle.gd
class_name Battle
extends Node

@export var grid: GridHandler
@export var _button: Button
var units: Array[Unit] = []
var current_unit_index: int = 0
var sequence_tree: SequenceTree = null

var _highlighted_cells: Array[HexCell] = []
var _reachable_cells: Array[HexCell] = []
var _move_mode: bool = false
var sequence_timer: float = 0

func _ready() -> void:
	print("Battle ready")
	_button.pressed.connect(_on_end_turn)
	get_viewport().physics_object_picking = true
	for unit:Unit in $Units.get_children():
		units.append(unit)
		unit.battle = self
	start_combat(units)

func start_combat(unit_list: Array[Unit]) -> void:
	print("Battle start_combat with units")
	units = unit_list
	for unit in units:
		unit.initialise(self)
		unit.roll_initiative()
	units.sort_custom(func(a: Unit, b: Unit): return a.initiative > b.initiative)
	grid.rebuild_pos_lookup()
	_assign_units_to_cells()
	for unit in units:
		unit.register_ability_triggers(self)
	current_unit_index = 0
	_begin_turn()

func _begin_turn() -> void:
	print("Battle _begin_turn")
	var unit := units[current_unit_index]
	if unit.is_dead:
		_advance_turn()
		return
	print("Turn: %s (initiative %.2f)" % [unit.unit_name, unit.initiative])
	unit.turn_start(self)
	_show_movement_options(unit)

func _process(delta: float) -> void:
	if not sequence_tree: return
	sequence_timer += delta
	if sequence_timer > 0.5:
		sequence_timer = 0.0
		print("Battle _process")
		if not sequence_tree.process_next_action():
			sequence_tree = null
			_advance_turn()
			

# --- Movement ---

func _show_movement_options(unit: Unit) -> void:
	print("Battle _show_movement_options")
	_clear_highlights()
	_move_mode = true
	print("Show options from ", unit.current_cell.int_pos)
	_reachable_cells = grid.get_reachable_cells(unit.current_cell, unit.movement_range)
	for cell in _reachable_cells:
		cell.set_highlighted(true)
		cell.cell_clicked.connect(_on_move_cell_clicked.bind(cell), CONNECT_ONE_SHOT)
	_highlighted_cells = _reachable_cells.duplicate()

func _on_move_cell_clicked(cell: HexCell) -> void:
	print("Battle _on_move_cell_clicked")
	if not _move_mode:
		return
	var unit := units[current_unit_index]
	_clear_highlights()
	_move_mode = false
	_execute_move(unit, cell)

func _execute_move(unit: Unit, target_cell: HexCell) -> void:
	print("Battle _execute_move")
	activate_ability(unit.move_ability, {"target_cell" = target_cell})
	
func place_on_cell(unit:Unit, cell: HexCell) -> void:
	var occupant = cell.occupant
	var start_cell = unit.current_cell
	unit.current_cell = cell
	unit.global_position = cell.global_position
	cell.occupant = unit
	if start_cell:
		start_cell.occupant = null
	if occupant: # swap if occupied
		print("Swap positions")
		occupant.current_cell = start_cell
		occupant.global_position = start_cell.global_position
		start_cell.occupant = occupant

# --- Ability activation ---

func activate_ability(unit_ability: UnitAbility, resolved_inputs: Dictionary) -> void:
	print("Battle activate_ability")
	if sequence_tree != null:
		push_warning("The current sequence tree must finish first")
		return
	if not unit_ability.can_use():
		push_warning("Unit cannot use ability: %s" % unit_ability.ability.name)
		return
	unit_ability.consume()
	sequence_tree = SequenceTree.new(self, unit_ability, resolved_inputs)
	sequence_tree.battle = self
	unit_ability.ability.execute(unit_ability, resolved_inputs)

# --- Turn management ---

func _on_end_turn() -> void:
	_clear_highlights()
	_advance_turn()

func _advance_turn() -> void:
	current_unit_index = (current_unit_index + 1) % units.size()
	_begin_turn()

func _clear_highlights() -> void:
	for cell in _highlighted_cells:
		cell.set_highlighted(false)
		if cell.cell_clicked.is_connected(_on_move_cell_clicked):
			cell.cell_clicked.disconnect(_on_move_cell_clicked)
	_highlighted_cells.clear()
	_reachable_cells.clear()

# --- Setup ---

func _assign_units_to_cells() -> void:
	for unit in units:
		var best_cell := _find_closest_open_cell(unit.global_position)
		if best_cell:
			place_on_cell(unit, best_cell)
		else:
			push_error("No open cell found for unit: " + unit.unit_name)

func _find_closest_open_cell(world_pos: Vector3) -> HexCell:
	var best_cell: HexCell = null
	var best_dist: float = INF
	for child in grid.get_children():
		var cell := child as HexCell
		if not cell:
			continue
		if cell.occupant != null:
			continue
		var dist := world_pos.distance_squared_to(cell.global_position)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
	return best_cell
