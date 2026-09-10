# step_auto_select.gd
class_name StepAutoselect
extends AbilityStep

var autoselect: Autoselect   # e.g. AutoselectSelf, AutoselectUnits, AutoselectCells

func build_actions(unit_ability: UnitAbility, results: AbilitySelectionResults, tree: SequenceTree) -> void:
	results.add_phase(autoselect.select(unit_ability, results))

func with_autoselect(p_autoselect: Autoselect) -> StepAutoselect:
	autoselect = p_autoselect
	return self
