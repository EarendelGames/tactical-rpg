# step_apply_effects.gd
class_name StepApplyEffects
extends AbilityStep

enum Anchor { CASTER, INPUT }

var anchor: Anchor
var aoe_shape: AOEShape          # null = just use results[input_index].units directly
var effects: Array[AbilityEffect]
var input_index: int = 0

func _init(p_anchor: Anchor, p_aoe_shape: AOEShape, p_effects: Array[AbilityEffect], p_input_index := 0) -> void:
	anchor = p_anchor; aoe_shape = p_aoe_shape; effects = p_effects; input_index = p_input_index

func build_actions(unit_ability: UnitAbility, results: Array[AbilitySelectionResult], tree: SequenceTree) -> void:
	var targets: Array[Unit] = []
	if aoe_shape:
		var anchor_cell: HexCell = unit_ability.unit.current_cell if anchor == Anchor.CASTER else results[input_index].cells[0]
		for cell in aoe_shape.get_cells(unit_ability.unit.battle.grid, unit_ability.unit.current_cell, anchor_cell):
			if cell.occupant:
				targets.append(cell.occupant)
	else:
		targets = results[input_index].units
	tree.append_sequential_action(ActionUnitEffects.new(unit_ability, targets, effects))
