# unit_ability.gd
class_name UnitAbility
#This is an ability that exists on a character. It is not the "usage instace" of the ability - that's the sequence tree. 

var unit:Unit # the owning unit
var ability: Ability
var uses_remaining: int = 1
var valid_cells: Array[HexCell] = []
var _path_predecessors: Dictionary = {}   # HexCell -> Array[HexCell], empty when not path-based

func _init(_ability: Ability, _unit:Unit) -> void:
	ability = _ability
	unit = _unit
	reset_uses()

func reset_uses() -> void:
	if ability.has_max_uses_per_turn:
		uses_remaining = ability.max_uses_per_turn
	else:
		uses_remaining = -1  # sentinel for unlimited

func can_use() -> bool:
	if ability.has_max_uses_per_turn and uses_remaining <= 0:
		return false
	if unit.mana < ability.cost_mana:
		return false
	if unit.movement_points < ability.cost_movement:
		return false
	if unit.health <= ability.cost_health:
		return false
	return true

func consume() -> void:
	if ability.has_max_uses_per_turn:
		uses_remaining -= 1
	unit.mana -= ability.cost_mana
	unit.movement_points -= ability.cost_movement
	unit.health -= ability.cost_health

func prep_for_input() -> void:
	unit.battle.set_input_consumer(self)
	valid_cells = get_reachable_cells()
	range_highlight(valid_cells)

func range_highlight(cells = null) -> void:
	unit.battle.clear_highlights()
	if not cells: 
		cells =  get_reachable_cells()
	#var input_phase:AbilityInput = ability.inputs[0] #only consider the first phase for now
	for cell:HexCell in cells:
		#if input_phase.selection_type == Selection.Type.CELL:
		#if input_phase.selection_type == Selection.Type.UNIT:
		cell.set_range_layer(Color(1.0, 0.9, 0.0, 0.5), HexCell.Edge.ALL)

func get_reachable_cells() -> Array[HexCell]:
	var input_phase: AbilityInput = ability.inputs[0]
	var selection_range = input_phase.get_selection_range(self)
	var min_range = input_phase.get_min_range(self)
	var collect_cells: Array[HexCell]

	_path_predecessors = {}
	if input_phase.selection_type == Selection.Type.CELL:
		if input_phase.require_path:
			_path_predecessors = unit.battle.grid.get_reachable_cells(unit.current_cell, selection_range, false)
			collect_cells.assign(_path_predecessors.keys())
		else:
			collect_cells = unit.battle.grid.get_cells_in_radius(unit.current_cell, selection_range, 1)
	if input_phase.selection_type == Selection.Type.UNIT:
		collect_cells = unit.battle.grid.get_cells_in_radius(unit.current_cell, selection_range, 1)

	var reachable_cells: Array[HexCell] = []
	for cell: HexCell in collect_cells:
		if GridHandler.get_cell_distance(unit.current_cell.int_pos, cell.int_pos) >= min_range:
			reachable_cells.append(cell)
	return reachable_cells
	
func get_path_to(cell: HexCell) -> Array[HexCell]:
	var path: Array[HexCell] = [cell]
	var current := cell
	while _path_predecessors.has(current):
		var candidates: Array = _path_predecessors[current]
		var best: HexCell = candidates[0]
		for c in candidates:
			if c.last_hover > best.last_hover:
				best = c
		path.push_front(best)
		current = best
	return path

func cell_clicked(cell: HexCell, _pos, _normal) -> void:
	if not valid_cells.has(cell):
		print("invalid cell")
		return
	var input_phase: AbilityInput = ability.inputs[0]
	if input_phase.selection_type == Selection.Type.UNIT:
		if cell.occupant:
			unit.battle.clear_highlights()
			unit.battle.set_input_consumer(null)
			# Important: Unit should be converted to HexCell at the last possible moment so that it can track if the unit was moved mid ability.
			# So only set the unit selection, NOT the initial hex cell
			activate_ability(AbilitySelectionResults.new().add_phase([AbilitySelectionResult.new().with_unit(cell.occupant)]))
		return
	var result := AbilitySelectionResult.new().with_cell(cell)
	if not _path_predecessors.is_empty():
		result.with_path(get_path_to(cell))
	unit.battle.clear_highlights()
	unit.battle.set_input_consumer(null)
	activate_ability(AbilitySelectionResults.new().add_phase([result]))

func activate_ability(resolved_inputs: AbilitySelectionResults) -> void:
	print("Battle activate_ability")
	if unit.battle.sequence_tree != null:
		push_warning("The current sequence tree must finish first")
		return
	if not can_use():
		push_warning("Unit cannot use ability: %s" % ability.name)
		return
	unit.battle.sequence_tree = SequenceTree.new(unit.battle, self, resolved_inputs)
	consume()
	ability.execute(self, resolved_inputs, unit.battle.sequence_tree)
