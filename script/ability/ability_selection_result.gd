class_name AbilitySelectionResult
extends RefCounted

# It is a selection result, not an input result, becuase passive abilties and trigers may auto-select.

# one phase's worth of selections
# results: Array[Array[AbilitySelectionResult]]
# results[phase_index] = Array[AbilitySelectionResult]   (multiple only if that phase allows multi-select)

var cell: HexCell           # the clicked/targeted cell (or the unit's cell, if unit-type selection)
var unit: Unit               # null unless selection_type == UNIT
var path: Array[HexCell] = []       # empty unless this selection used pathfinding
var direction: int = 0              # edge index 0-5; caster->cell by default, overridable via rotation

func with_cell(_cell: HexCell) -> AbilitySelectionResult:
	cell = _cell
	return self

func with_unit(_unit: Unit) -> AbilitySelectionResult:
	unit = _unit
	return self

func with_path(_path: Array[HexCell]) -> AbilitySelectionResult:
	path = _path
	return self
