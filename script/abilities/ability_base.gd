# ability_base.gd
class_name AbilityBase
extends RefCounted

# --- Registry ---

static var _registry: Dictionary = {}

static func get_ability(ability_id: String) -> AbilityBase:
	return _registry.get(ability_id, null)

static func all() -> Array:
	return _registry.values()

# --- Fields ---

var id: String
var name: String
var description: String
var tags: Array[BattleEnums.Tag]
var inputs: Array[BattleEnums.AbilityInput]

var cost_mana: float = 0.0
var cost_movement: float = 0.0
var cost_health: float = 0.0
var max_uses_per_turn: int = 1
var has_max_uses_per_turn: bool = true

var _execute_fn: Callable
var _trigger_fn: Callable

# --- Init and registration ---

func _init(
	p_id: String,
	p_name: String,
	p_description: String,
	p_tags: Array[BattleEnums.Tag]
) -> void:
	id = p_id
	name = p_name
	description = p_description
	tags = p_tags
	inputs = []
	if AbilityBase._registry.has(id):
		push_error("AbilityBase: duplicate id '%s'" % id)
	AbilityBase._registry[id] = self

# --- Builder methods ---

func input_cell(input_range: float, p_min: int = 1, p_max: int = 1) -> AbilityBase:
	inputs.append(BattleEnums.AbilityInput.cell(input_range, p_min, p_max))
	return self

func input_unit(input_range: float, p_min: int = 1, p_max: int = 1) -> AbilityBase:
	inputs.append(BattleEnums.AbilityInput.unit(input_range, p_min, p_max))
	return self

func input_cell_corner(input_range: float, p_min: int = 1, p_max: int = 1) -> AbilityBase:
	inputs.append(BattleEnums.AbilityInput.cell_corner(input_range, p_min, p_max))
	return self

func input_direction(input_range: float) -> AbilityBase:
	inputs.append(BattleEnums.AbilityInput.direction(input_range))
	return self

func mana(amount: float) -> AbilityBase:
	cost_mana = amount
	return self

func movement(amount: float) -> AbilityBase:
	cost_movement = amount
	return self

func health(amount: float) -> AbilityBase:
	cost_health = amount
	return self

func uses_per_turn(value: Variant) -> AbilityBase:
	if value == false:
		has_max_uses_per_turn = false
		max_uses_per_turn = 0
	else:
		has_max_uses_per_turn = true
		max_uses_per_turn = value
	return self

func with_execute(fn: Callable) -> AbilityBase:
	_execute_fn = fn
	return self

func with_trigger(fn: Callable) -> AbilityBase:
	_trigger_fn = fn
	return self

# --- Runtime ---
func as_unit_ability(unit:Unit) -> UnitAbility:
	return UnitAbility.new(self, unit)
	

func is_movement() -> bool:
	return BattleEnums.Tag.MOVEMENT in tags

func is_basic() -> bool:
	return BattleEnums.Tag.BASIC in tags

func execute(unit_ability:UnitAbility, input:Dictionary) -> void:
	if _execute_fn.is_valid():
		_execute_fn.call(unit_ability, input)

func register_trigger(unit: Unit, battle: Battle) -> void:
	if _trigger_fn.is_valid():
		_trigger_fn.call(unit, battle)
