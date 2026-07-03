class_name ActionMove
extends ActionNode

var _unit:Unit
var _to_cell:HexCell

func _init(owning_ability:UnitAbility, unit:Unit = null, to_cell:HexCell = null) -> void:
	_owning_ability = owning_ability
	_unit = unit
	_to_cell = to_cell

func execute(_sequence_tree:SequenceTree) -> bool:
	print("ActionMove execute_function")
	_sequence_tree.battle.place_on_cell(_unit, _to_cell)
	return true
