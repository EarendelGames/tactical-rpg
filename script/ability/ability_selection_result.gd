class_name AbilitySelectionResult
extends RefCounted

# It is a selection result, not an input result, becuase passive abilties and trigers may auto-select.

var input_phase: AbilityInput        # which phase this came from, if any
var cells: Array[HexCell] = []
var units: Array[Unit] = []
var path: Array[HexCell] = []        # populated only if input_phase.require_path

func with_cells(_cells: Array[HexCell]) -> AbilitySelectionResult:
	cells = _cells
	return self
	
func with_units(_units: Array[Unit]) -> AbilitySelectionResult:
	units = _units
	return self
	
func with_path(_path: Array[HexCell]) -> AbilitySelectionResult:
	path = _path
	return self
	
func for_input_phase(_input_phase: AbilityInput) -> AbilitySelectionResult:
	input_phase = _input_phase
	return self
