# effect_damage.gd
class_name EffectDamage
extends AbilityEffect

var amount: Variant
var damage_type: Type.Damage

func _init(p_amount, p_damage_type: Type.Damage) -> void:
	amount = p_amount
	damage_type = p_damage_type

func apply_to_cell(unit_ability: UnitAbility, cell: HexCell, tree: SequenceTree, node: ActionNode) -> bool:
	if not cell.occupant:
		return false
	var value: float = amount.evaluate(unit_ability) if amount is Evaluator else amount
	cell.occupant.apply_damage(value, damage_type, tree, node)
	return true
