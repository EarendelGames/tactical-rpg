# effect_apply_status.gd
class_name EffectApplyStatus
extends AbilityEffect

var status_id: String
var magnitude: int
var duration: int

func _init(p_status_id: String, p_magnitude: int, p_duration: int = 1) -> void:
	status_id = p_status_id
	magnitude = p_magnitude
	duration = p_duration

func apply_to_cell(unit_ability: UnitAbility, cell: HexCell, tree: SequenceTree, node: ActionNode) -> bool:
	if not cell.occupant:
		return false
	cell.occupant.apply_status(status_id, magnitude, duration, unit_ability)
	return true
