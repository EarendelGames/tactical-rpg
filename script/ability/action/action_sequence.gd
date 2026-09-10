class_name ActionSequence
extends ActionNode

var _sub_actions: Array[ActionNode] = []

func _init(owning_ability, sub_actions: Array[ActionNode]) -> void:
	_owning_ability = owning_ability
	_sub_actions = sub_actions

func execute(tree: SequenceTree) -> bool:
	for action in _sub_actions:
		action.execute(tree)
	return true
