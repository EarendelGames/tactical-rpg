class_name AbilitySelectionResult
extends RefCounted

# It is a selection result, not an input result, becuase passive abilties and trigers may auto-select.

# one phase's worth of selections
# results: Array[Array[AbilitySelectionResult]]
# results[phase_index] = Array[AbilitySelectionResult]   (multiple only if that phase allows multi-select)

var _cell: HexCell = null
var unit: Unit               # null unless selection_type == UNIT
var path: Array[HexCell] = []       # empty unless this selection used pathfinding
var direction: int = 0              # edge index 0-5; caster->cell by default, overridable via rotation

# Important: Unit should be converted to HexCell at the last possible moment so that it can track if the unit was moved mid ability.

var cell: HexCell:
	get: return unit.current_cell if unit else _cell
	set(value): _cell = value
	
func with_cell(p_cell: HexCell) -> AbilitySelectionResult:
	_cell = p_cell
	return self
	
func with_unit(p_unit: Unit) -> AbilitySelectionResult:
	unit = p_unit
	return self

func with_path(p_path: Array[HexCell]) -> AbilitySelectionResult:
	path = p_path
	return self
