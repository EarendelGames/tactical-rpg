# ability_effect.gd
class_name AbilityEffect
extends RefCounted

func apply(unit_ability: UnitAbility, target: Unit, tree: SequenceTree, node: ActionNode) -> void:
	push_error("AbilityEffect.apply not implemented")
