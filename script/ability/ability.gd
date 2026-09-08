# ability.gd
class_name Ability
extends RefCounted

# --- Registry ---
enum Tag {
	BASIC, # Units usually have at least 1, and it usually has no cost other than max_uses
	ULTIMATE, # Max 1 per unit, powerful but costly, maybe 1 use per battle?
	MELEE,
	RANGED,
	MAGIC,
	MARTIAL,
	ARCANE,
	DEVOTION, # from a deity or something
	
	ATTACK, # An attack type action
	MOVEMENT, # Contains movement
	
	# DamageType
	PHYSICAL,
	FIRE,
	ACID,
	COLD,
	LIGHTNING,
	PLANT,
	BLOOD,
	ROT,
	LIGHT,
	DARK,
	ASTRAL,
	SPIRIT,
	
	# ELEMTENT RESIDUE (de-energised)
	METAL, #FIRE
	WATER, #ACID
	EARTH, #COLD
	AIR, #LIGHTNING
	CRYSTAL, #LIGHT
	UMBRA, #DARK
}

static var _registry: Dictionary = {}

static func get_ability(ability_id: String) -> Ability:
	return _registry.get(ability_id, null)

static func all() -> Array:
	return _registry.values()

# --- Fields ---

var id: String
var name: String
var description: String
var tags: Array[Ability.Tag]
var inputs: Array[AbilityInput]

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
	p_tags: Array[Ability.Tag]
) -> void:
	id = p_id
	name = p_name
	description = p_description
	tags = p_tags
	inputs = []
	if Ability._registry.has(id):
		push_error("AbilityBase: duplicate id '%s'" % id)
	Ability._registry[id] = self

# --- Builder methods ---

func with_input(input:AbilityInput) -> Ability:
	inputs.append(input)
	return self

func mana(amount: float) -> Ability:
	cost_mana = amount
	return self

func movement(amount: float) -> Ability:
	cost_movement = amount
	return self

func health(amount: float) -> Ability:
	cost_health = amount
	return self

func uses_per_turn(value: Variant) -> Ability:
	if value == false:
		has_max_uses_per_turn = false
		max_uses_per_turn = 0
	else:
		has_max_uses_per_turn = true
		max_uses_per_turn = value
	return self

func with_execute(fn: Callable) -> Ability:
	_execute_fn = fn
	return self

func with_trigger(fn: Callable) -> Ability:
	_trigger_fn = fn
	return self

# --- Runtime ---
func as_unit_ability(unit:Unit) -> UnitAbility:
	return UnitAbility.new(self, unit)
	

func is_movement() -> bool:
	return Ability.Tag.MOVEMENT in tags

func is_basic() -> bool:
	return Ability.Tag.BASIC in tags

func execute(unit_ability:UnitAbility, input:Dictionary) -> void:
	if _execute_fn.is_valid():
		_execute_fn.call(unit_ability, input)

func register_trigger(unit: Unit) -> void:
	if _trigger_fn.is_valid():
		_trigger_fn.call(unit)
