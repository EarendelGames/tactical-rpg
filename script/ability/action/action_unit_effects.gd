class_name ActionUnitEffects
extends ActionNode

var _effects: Array[AbilityEffect]   # shared, stateless config objects
var _units:Array[Unit]

func _init(owning_ability:UnitAbility, units: Array[Unit], effects: Array[AbilityEffect]) -> void:
	_owning_ability = owning_ability
	_units = units
	_effects = effects

func execute(tree: SequenceTree) -> bool:
	for unit in _units:
		for effect in _effects:
			effect.apply(_owning_ability, unit, tree, self)
	return true
