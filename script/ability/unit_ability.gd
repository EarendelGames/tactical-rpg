# unit_ability.gd
class_name UnitAbility
#This is an ability that exists on a character. It is not the "usage instace" of the ability - that's the sequence tree. 

var unit:Unit # the owning unit
var ability: Ability
var uses_remaining: int = 1
var valid_cells: Array[HexCell] = []

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
	var collect_cells: Array[HexCell]
	var reachable_cells: Array[HexCell]
	
	# consider moving to ability_input
	var input_phase:AbilityInput = ability.inputs[0] #only consider the first phase for now
	var selection_range = input_phase.get_selection_range(self)
	var min_range = input_phase.get_min_range(self)
	
	if input_phase.selection_type == Selection.Type.CELL:
		if input_phase.require_path:
			collect_cells = unit.battle.grid.get_reachable_cells(unit.current_cell, selection_range, false)
		else:
			collect_cells = unit.battle.grid.get_cells_in_radius(unit.current_cell, selection_range, 1)
	
	if input_phase.selection_type == Selection.Type.UNIT:
		collect_cells = unit.battle.grid.get_cells_in_radius(unit.current_cell, selection_range, 1)
	
	#Enforce minimum range
	for cell:HexCell in collect_cells:
		if GridHandler.get_cell_distance(unit.current_cell.int_pos, cell.int_pos) >= min_range:
			reachable_cells.append(cell)
	
	return reachable_cells
	

func cell_clicked(cell: HexCell, _pos, _normal) -> void:
	print("UnitAbility _on_cell_clicked")
	if valid_cells.has(cell):
		var input_phase:AbilityInput = ability.inputs[0] #only consider the first phase for now
		if input_phase.selection_type == Selection.Type.UNIT:
			if cell.occupant:
				if not cell.occupant:
					print("No occupant")
					return
				print("UnitAbility _on_unit_clicked")
				unit.battle.clear_highlights()
				unit.battle.set_input_consumer(null)
				activate_ability({"target_unit" = cell.occupant, "target_cell" = cell})
				return
		else:
			unit.battle.clear_highlights()
			unit.battle.set_input_consumer(null)
			activate_ability({"target_cell" = cell})
	else:
		print("invalid cell")

func activate_ability(resolved_inputs: Dictionary) -> void:
	print("Battle activate_ability")
	if unit.battle.sequence_tree != null:
		push_warning("The current sequence tree must finish first")
		return
	if not can_use():
		push_warning("Unit cannot use ability: %s" % ability.name)
		return
	unit.battle.sequence_tree = SequenceTree.new(unit.battle, self, resolved_inputs)
	consume()
	ability.execute(self, resolved_inputs)
