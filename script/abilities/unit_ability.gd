# ability_instance.gd
class_name UnitAbility
#This is an ability that exists on a character. It is not the "usage instace" of the ability - that's the sequence tree. 

var unit:Unit # the owning unit
var ability: AbilityBase
var uses_remaining: int = 1

func _init(_ability: AbilityBase, _unit:Unit) -> void:
	ability = _ability
	unit = _unit
	reset_uses()

func reset_uses() -> void:
	if ability.has_max_uses_per_turn:
		uses_remaining = ability.max_uses_per_turn
	else:
		uses_remaining = -1  # sentinel for unlimited

func can_use() -> bool:
	if ability.has_max_uses_per_turn and uses_remaining <= 0:
		return false
	if unit.mana < ability.cost_mana:
		return false
	if unit.movement_points < ability.cost_movement:
		return false
	if unit.health <= ability.cost_health:
		return false
	return true

func consume() -> void:
	if ability.has_max_uses_per_turn:
		uses_remaining -= 1
	unit.mana -= ability.cost_mana
	unit.movement_points -= ability.cost_movement
	unit.health -= ability.cost_health
