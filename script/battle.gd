# battle/battle.gd
class_name Battle
extends Node

@export var grid: GridHandler
@export var _button: Button
var units: Array[Unit] = []
var current_unit_index: int = 0
var current_tree: EventTree = null

var _highlighted_cells: Array[HexCell] = []
var _reachable_cells: Array[HexCell] = []
var _move_mode: bool = false

func _ready() -> void:
	_button.pressed.connect(_on_end_turn)
	get_viewport().physics_object_picking = true
	for unit in $Units.get_children():
		units.append(unit)
	start_combat(units)

func start_combat(unit_list: Array[Unit]) -> void:
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
	print("_begin_turn")
	var unit := units[current_unit_index]
	if unit.is_dead:
		_advance_turn()
		return
	print("Turn: %s (initiative %.2f)" % [unit.unit_name, unit.initiative])
	unit.turn_start(self)
	_show_movement_options(unit)

# --- Movement ---

func _show_movement_options(unit: Unit) -> void:
	_clear_highlights()
	_move_mode = true
	_reachable_cells = grid.get_reachable_cells(unit.current_cell, unit.movement_range)
	for cell in _reachable_cells:
		cell.set_highlighted(true)
		cell.cell_clicked.connect(_on_move_cell_clicked.bind(cell), CONNECT_ONE_SHOT)
	_highlighted_cells = _reachable_cells.duplicate()

func _on_move_cell_clicked(cell: HexCell) -> void:
	if not _move_mode:
		return
	var unit := units[current_unit_index]
	_clear_highlights()
	_move_mode = false
	_execute_move(unit, cell)

func _execute_move(unit: Unit, target_cell: HexCell) -> void:
	var start_cell := unit.current_cell
	var path := grid.find_path(start_cell, target_cell)
	if path.size() <= 1:
		return
	path.remove_at(0)
	current_tree = EventTree.new(unit, null, [])
	current_tree.battle = self
	MovementExecutor.execute(unit, path, current_tree, start_cell)
	current_tree = null

# --- Ability activation ---

func activate_ability(instance: AbilityInstance, resolved_inputs: Array) -> void:
	var unit := units[current_unit_index]
	if not instance.can_use(unit):
		push_warning("Unit cannot use ability: %s" % instance.ability.name)
		return
	instance.consume(unit)
	current_tree = EventTree.new(unit, instance.ability, resolved_inputs)
	current_tree.battle = self
	instance.ability.execute(current_tree)
	current_tree.resolve()
	current_tree = null

# --- Trigger notification ---

func notify_damage_taken(
	damaged_unit: Unit,
	tree: EventTree,
	parent_node: EventNode
) -> void:
	for unit in units:
		if unit.is_dead or unit == damaged_unit:
			continue
		for trigger in unit.get_triggers_for_timing(BattleEnums.EventTiming.RESPONSE):
			if trigger["cancel_if"].is_valid() and trigger["cancel_if"].call():
				continue
			trigger["callable"].call(tree, parent_node)

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
			unit.place_on_cell(best_cell)
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
