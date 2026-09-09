# effect_apply_status.gd
class_name EffectApplyStatus
extends AbilityEffect

var status_id: String
var stacks: int

func _init(p_status_id: String, p_stacks: int) -> void:
	status_id = p_status_id
	stacks = p_stacks

func apply(unit_ability: UnitAbility, target: Unit, tree: SequenceTree, node: ActionNode) -> void:
	target.apply_status(status_id, stacks)
