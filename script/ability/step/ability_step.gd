# ability_step.gd
class_name AbilityStep
extends RefCounted

func build_actions(unit_ability: UnitAbility, results: AbilitySelectionResults, tree: SequenceTree) -> void:
	print(unit_ability, results, tree)
	push_error("not implemented")
