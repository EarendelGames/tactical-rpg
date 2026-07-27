# battle/battle.gd
class_name Battle
extends Node3D

@export var grid: GridHandler
@export var _button: Button
var units: Array[Unit] = []
var current_unit_index: int = 0
var sequence_tree: SequenceTree = null

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
	# TODO: find primary movement ability and auto-select if for movement selection. 
	unit.move_ability.prep_for_input()

func _process(delta: float) -> void:
	if not sequence_tree: return
	sequence_timer += delta
	if sequence_timer > 0.1:
		sequence_timer = 0.0
		print("Battle _process")
		if not sequence_tree.process_next_action():
			sequence_tree = null
			_advance_turn()
			

# --- Movement ---
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
		
func move_to_cell(unit:Unit, cell: HexCell) -> void:
	var occupant = cell.occupant
	var start_cell = unit.current_cell
	unit.current_cell = cell
	cell.occupant = unit
	if start_cell:
		start_cell.occupant = null
		
	#unit.global_position = cell.global_position
	
	var from = unit.global_position
	var to = cell.global_position
	var tween:Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(unit, "global_position",to, 0.3).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(unit, "rotation:y", wrapf(atan2(to.x - from.x, to.z - from.z), unit.rotation.y - PI, unit.rotation.y + PI), 0.2)
	
	if occupant: # swap if occupied
		print("Swap positions")
		occupant.current_cell = start_cell
		start_cell.occupant = occupant
		#occupant.global_position = start_cell.global_position
		from = occupant.global_position
		to = start_cell.global_position
		tween.tween_property(occupant, "global_position", to, 0.3).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(occupant, "rotation:y", wrapf(atan2(to.x - from.x, to.z - from.z), occupant.rotation.y - PI, occupant.rotation.y + PI), 0.2)
	
	sequence_timer -= 0.3
	tween.play()


# --- Turn management ---

func _on_end_turn() -> void:
	clear_highlights()
	_advance_turn()

func _advance_turn() -> void:
	current_unit_index = (current_unit_index + 1) % units.size()
	_begin_turn()

func clear_highlights() -> void:
	for cell:HexCell in grid.cells_array:
		cell.set_highlighted(false)

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
