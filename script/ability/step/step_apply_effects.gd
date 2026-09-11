# step_apply_effects.gd
class_name StepApplyEffects
extends AbilityStep

# step_auto_select.gd
var phase_index: int = 0
var transformer: TargetTransformer   # null = identity
var effects: Array[AbilityEffect]

func build_actions(unit_ability: UnitAbility, results: AbilitySelectionResults, tree: SequenceTree) -> void:
	var phase_selections: Array[AbilitySelectionResult] = results.get_phase(phase_index)
	for selection: AbilitySelectionResult in phase_selections:
		var cells: Array[HexCell] = [selection.cell]
		if transformer:
			cells = transformer.get_cells(unit_ability, selection)
		for cell in cells:
			var actions: Array[ActionNode] = []
			for effect in effects:
				actions.append(ActionEffect.new(unit_ability, effect, cell))
			tree.append_sequential_action(actions[0] if actions.size() == 1 else ActionSequence.new(unit_ability, actions))
			

func with_transformer(p_transformer: TargetTransformer) -> StepApplyEffects:
	transformer = p_transformer
	return self
	
func with_effects(p_effects: Array[AbilityEffect]) -> StepApplyEffects:
	effects = p_effects
	return self

func use_phase(_phase_index:int) -> StepApplyEffects:
	phase_index = _phase_index
	return self
