# ability_selection_results.gd
class_name AbilitySelectionResults
extends RefCounted

var phases: Array[Array] = []   # phases[phase_index] = Array[AbilitySelectionResult]

func get_phase(phase_index: int) -> Array[AbilitySelectionResult]:
	return phases[phase_index]

func add_phase(selections: Array[AbilitySelectionResult]) -> AbilitySelectionResults:
	phases.append(selections)
	return self
