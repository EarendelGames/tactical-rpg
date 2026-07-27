# ability_instance.gd
class_name UnitAbility
#This is an ability that exists on a character. It is not the "usage instace" of the ability - that's the sequence tree. 

var unit:Unit # the owning unit
var ability: AbilityBase
var uses_remaining: int = 1

func _init(_ability: AbilityBase, _unit:Unit) -> void:
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
	var input_phase:AbilityInput = ability.inputs[0] #only consider the first phase for now
	if input_phase.selection_type == BattleEnums.SelectionType.CELL:
		var _reachable_cells: Array[HexCell]
		if input_phase.require_path:
			_reachable_cells = unit.battle.grid.get_reachable_cells(unit.current_cell, input_phase.selection_range, false)
		else:
			_reachable_cells = unit.battle.grid.get_cells_in_radius(unit.current_cell, input_phase.selection_range)
		unit.battle.clear_highlights()
		for cell:HexCell in _reachable_cells:
			cell.set_highlighted(true)
			cell.cell_clicked.connect(_on_cell_clicked.bind(cell), CONNECT_ONE_SHOT)


func _on_cell_clicked(cell: HexCell) -> void:
	print("UnitAbility _on_cell_clicked")
	unit.battle.clear_highlights()
	for clear_cell:HexCell in unit.battle.grid.cells_array:
		if clear_cell.cell_clicked.is_connected(_on_cell_clicked):
			clear_cell.cell_clicked.disconnect(_on_cell_clicked)
	activate_ability({"target_cell" = cell})

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
