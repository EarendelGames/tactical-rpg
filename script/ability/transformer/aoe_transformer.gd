# aoe_transformer.gd
class_name AOETransformer
extends TargetTransformer

var shape: AOEShape

func _init(p_shape: AOEShape) -> void:
	shape = p_shape

func get_cells(unit_ability: UnitAbility, selection: AbilitySelectionResult) -> Array[HexCell]:
	return shape.get_cells(unit_ability.unit.battle.grid, selection, unit_ability)
