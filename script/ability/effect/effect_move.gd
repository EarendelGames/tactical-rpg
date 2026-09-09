# effect_move.gd
class_name EffectMove
extends AbilityEffect

func apply_path(unit_ability: UnitAbility, path: Array[HexCell], tree: SequenceTree) -> void:
	for cell in path:
		tree.append_sequential_action(ActionMove.new(unit_ability, unit_ability.unit, cell))
