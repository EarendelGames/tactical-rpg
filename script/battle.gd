# battle/battle.gd
class_name Battle
extends Node3D

@onready var grid: GridHandler = $GridHandler

var units: Array[Unit] = []
var current_unit_index: int = 0
var sequence_tree: SequenceTree = null

var sequence_timer: float = 0
@onready var battle_ui : BattleUI = $"BattleUI"

func _ready() -> void:
	print("Battle ready")
	battle_ui.battle = self
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
		unit.register_ability_triggers()
	current_unit_index = 0
	_begin_turn()

func _begin_turn() -> void:
	print("Battle _begin_turn")
	var unit := units[current_unit_index]
	if unit.is_dead:
		advance_turn()
		return
	print("Turn: %s (initiative %.2f)" % [unit.unit_name, unit.initiative])
	unit.turn_start()
	unit.move_ability.prep_for_input()

func _process(delta: float) -> void:
	if not sequence_tree: return
	sequence_timer += delta
	if sequence_timer > 0.0:
		sequence_timer = 0.0
		print("Battle _process")
		if not sequence_tree.process_next_action():
			sequence_tree = null
			var unit := get_current_unit()
			if unit and unit.movement_points > 0:
				unit.move_ability.prep_for_input()
			#_advance_turn()
			

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
	
	var delay := 0.3
	var from = unit.global_position
	var to = cell.global_position
	var tween:Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(unit, "global_position",to, delay).set_custom_interpolator(Easing.in_out_faint)
	tween.tween_property(unit, "rotation:y", wrapf(atan2(to.x - from.x, to.z - from.z), unit.rotation.y - PI, unit.rotation.y + PI), 0.5 * delay)
	
	if occupant: # swap if occupied
		print("Swap positions")
		occupant.current_cell = start_cell
		start_cell.occupant = occupant
		#occupant.global_position = start_cell.global_position
		from = occupant.global_position
		to = start_cell.global_position
		tween.tween_property(occupant, "global_position", to, delay).set_custom_interpolator(Easing.in_out_faint)
		tween.tween_property(occupant, "rotation:y", wrapf(atan2(to.x - from.x, to.z - from.z), occupant.rotation.y - PI, occupant.rotation.y + PI), 0.5 * delay)
	
	sequence_timer -= delay
	tween.play()


# --- Turn management ---

func advance_turn() -> void:
	clear_highlights()
	current_unit_index = (current_unit_index + 1) % units.size()
	_begin_turn()

func clear_highlights() -> void:
	for cell:HexCell in grid.cells_array:
		cell.set_highlighted(false)
		
func clear_hover_highlights() -> void:
	for cell:HexCell in grid.cells_array:
		cell.set_hover_highlighted(false)

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

func new_sequence_tree(unit_ability:UnitAbility, inputs:Dictionary) -> SequenceTree:
	sequence_tree = SequenceTree.new(self, unit_ability, inputs)
	return sequence_tree
	
func get_current_unit() -> Unit:
	return units[current_unit_index]
