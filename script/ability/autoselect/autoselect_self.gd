# selector_self.gd
class_name AutoselectSelf
extends Autoselect

func select(unit_ability: UnitAbility, _results: AbilitySelectionResults) -> Array[AbilitySelectionResult]:
	var r := AbilitySelectionResult.new()
	r.cell = unit_ability.unit.current_cell
	return [r]
