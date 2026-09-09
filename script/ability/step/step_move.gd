# step_move.gd
class_name StepMove
extends AbilityStep

var input_index: int = 0

func build_actions(unit_ability: UnitAbility, results: Array[AbilitySelectionResult], tree: SequenceTree) -> void:
	for cell in results[input_index].path:
		tree.append_sequential_action(ActionMove.new(unit_ability, unit_ability.unit, cell))
