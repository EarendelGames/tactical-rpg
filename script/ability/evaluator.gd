# evaluator.gd
class_name Evaluator

var target: Target = Target.none 

enum Target {
	none,
	health,
	mana,
	movement_points,
	strength,
	dexterity,
	mysticism
}

func _init(p_target: Target) -> void:
	target = p_target

func evaluate(ua: UnitAbility):
	var unit = ua.unit
	match target:
		Target.health: 
			return unit.health
		Target.mana: 
			return unit.mana
		Target.movement_points: 
			return unit.movement_points
		Target.strength: 
			return unit.strength
		Target.dexterity: 
			return unit.dexterity
		Target.mysticism: 
			return unit.mysticism
		_: 
			return 0
