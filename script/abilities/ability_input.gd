class_name AbilityInput

var selection_type: BattleEnums.SelectionType
var min_selections: int
var max_selections: int
var selection_range: float
var require_path: bool = false
var require_los: bool = false

func _init(
	p_type: BattleEnums.SelectionType,
	p_range: float,
	p_min: int = 1,
	p_max: int = 1,
	p_require_path: bool = false,
	p_require_los: bool = false
) -> void:
	selection_type = p_type
	selection_range = p_range
	min_selections = p_min
	max_selections = p_max
	require_path = p_require_path
	require_los = p_require_los

static func cell(p_range: float, p_min: int = 1, p_max: int = 1, p_require_path: bool = false, p_require_los: bool = false) -> AbilityInput:
	return AbilityInput.new(BattleEnums.SelectionType.CELL, p_range, p_min, p_max, p_require_path, p_require_los)

static func unit(p_range: float, p_min: int = 1, p_max: int = 1, p_require_path: bool = false, p_require_los: bool = false) -> AbilityInput:
	return AbilityInput.new(BattleEnums.SelectionType.UNIT, p_range, p_min, p_max, p_require_path, p_require_los)

static func cell_corner(p_range: float, p_min: int = 1, p_max: int = 1, p_require_path: bool = false, p_require_los: bool = false) -> AbilityInput:
	return AbilityInput.new(BattleEnums.SelectionType.CELL_CORNER, p_range, p_min, p_max, p_require_path, p_require_los)

static func direction(p_range: float) -> AbilityInput:
	return AbilityInput.new(BattleEnums.SelectionType.DIRECTION, p_range)
