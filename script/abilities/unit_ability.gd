# ability_instance.gd
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
	
	unit.battle.clear_highlights()
	valid_cells = get_reachable_cells()
	var input_phase:AbilityInput = ability.inputs[0] #only consider the first phase for now
	
	unit.battle.clear_highlights()
	for cell:HexCell in valid_cells:
		if input_phase.selection_type == Selection.Type.CELL:
			cell.set_highlighted(true)
		if input_phase.selection_type == Selection.Type.UNIT:
			cell.set_highlighted(true, Color(1, 0, 0, 0.5))

func range_highlight() -> void:
	unit.battle.clear_hover_highlights()
	var reachable_cells = get_reachable_cells()
	var input_phase:AbilityInput = ability.inputs[0] #only consider the first phase for now
	for cell:HexCell in reachable_cells:
		if input_phase.selection_type == Selection.Type.CELL:
			cell.set_hover_highlighted(true)
		if input_phase.selection_type == Selection.Type.UNIT:
			cell.set_hover_highlighted(true, Color(1, 0, 0, 0.25))

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
		unit.battle.clear_highlights()
		unit.battle.set_input_consumer(null)
		activate_ability({"target_cell" = cell})
	else:
		print("invalid cell")
	
func unit_clicked(cell: HexCell) -> void:
	if not cell.occupant:
		return
	print("UnitAbility _on_unit_clicked")
	unit.battle.clear_highlights()
	unit.battle.set_input_consumer(null)
	activate_ability({"target_unit" = cell.occupant, "target_cell" = cell})

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
