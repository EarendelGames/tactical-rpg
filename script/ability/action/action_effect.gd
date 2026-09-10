# action_effect.gd — generic, one class for all effect types
class_name ActionEffect
extends ActionNode

var _effect: AbilityEffect
var _cell: HexCell

func _init(owning_ability, effect: AbilityEffect, cell: HexCell) -> void:
	_owning_ability = owning_ability
	_effect = effect
	_cell = cell

func execute(tree: SequenceTree) -> bool:
	return _effect.apply_to_cell(_owning_ability, _cell, tree, self)
