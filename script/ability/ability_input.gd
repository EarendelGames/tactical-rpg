class_name AbilityInput

var selection_type: Selection.Type
var selection_range: Variant # float or Callable
var min_range: Variant # float or Callable
var min_selections: Variant # int or Callable
var max_selections: Variant # int or Callable
var require_path: bool = false
var require_los: bool = false

func _init(
	p_type: Selection.Type,
	p_selection_range: Variant = 0,
	p_min_range: Variant = 0,
	p_min_selections: Variant = 1,
	p_max_selections: Variant = 1,
	p_require_path: bool = false,
	p_require_los: bool = false
) -> void:
	selection_type = p_type
	selection_range = p_selection_range
	min_range = p_min_range
	min_selections = p_min_selections
	max_selections = p_max_selections
	require_path = p_require_path
	require_los = p_require_los

static func cell(p_selection_range: Variant, p_min_range: Variant, p_min_selections: Variant = 1, p_max_selections: Variant = 1, p_require_path: bool = false, p_require_los: bool = false) -> AbilityInput:
	return AbilityInput.new(Selection.Type.CELL, p_selection_range, p_min_range, p_min_selections, p_max_selections, p_require_path, p_require_los)

static func unit(p_selection_range: Variant, p_min_range: Variant, p_min_selections: Variant = 1, p_max_selections: Variant = 1, p_require_path: bool = false, p_require_los: bool = false) -> AbilityInput:
	return AbilityInput.new(Selection.Type.UNIT, p_selection_range, p_min_range, p_min_selections, p_max_selections, p_require_path, p_require_los)

static func cell_corner(p_selection_range: Variant, p_min_range: Variant, p_min_selections: Variant = 1, p_max_selections: Variant = 1, p_require_path: bool = false, p_require_los: bool = false) -> AbilityInput:
	return AbilityInput.new(Selection.Type.CELL_CORNER, p_selection_range, p_min_range, p_min_selections, p_max_selections, p_require_path, p_require_los)

static func direction() -> AbilityInput:
	return AbilityInput.new(Selection.Type.DIRECTION)


func get_selection_range(unit_ability: UnitAbility) -> float:
	if selection_range is Callable:
		return selection_range.call(unit_ability)
	return selection_range

func get_min_range(unit_ability: UnitAbility) -> float:
	if min_range is Callable:
		return min_range.call(unit_ability)
	return min_range

func get_min_selections(unit_ability: UnitAbility) -> float:
	if min_selections is Callable:
		return min_selections.call(unit_ability)
	return min_selections

func get_max_selections(unit_ability: UnitAbility) -> float:
	if max_selections is Callable:
		return max_selections.call(unit_ability)
	return max_selections
