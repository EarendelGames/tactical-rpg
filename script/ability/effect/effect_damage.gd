# effect_damage.gd
class_name EffectDamage
extends AbilityEffect

var amount: Variant
var damage_type: Type.Damage

func _init(p_amount, p_damage_type: Type.Damage) -> void:
	amount = p_amount
	damage_type = p_damage_type

func apply(unit_ability: UnitAbility, target: Unit, tree: SequenceTree, node: ActionNode) -> void:
	var value: float = amount.evaluate(unit_ability) if amount is Evaluator else amount
	target.apply_damage(value, damage_type, tree, node)
