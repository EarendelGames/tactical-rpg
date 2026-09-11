# effect_apply_status.gd
class_name EffectApplyStatus
extends AbilityEffect

var status_id: String
var stacks: int

func _init(p_status_id: String, p_stacks: int) -> void:
	status_id = p_status_id
	stacks = p_stacks

func apply_to_cell(unit_ability: UnitAbility, cell: HexCell, tree: SequenceTree, node: ActionNode) -> bool:
	if not cell.occupant:
		return false
	cell.occupant.apply_status(status_id, stacks)
	return true
