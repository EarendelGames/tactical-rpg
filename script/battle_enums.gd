# battle_enums.gd
class_name BattleEnums

enum Tag {
	BASIC, # Units usually have at least 1, and it usually has no cost other than max_uses
	ULTIMATE, # Max 1 per unit, powerful but costly, maybe 1 use per battle?
	MELEE,
	RANGED,
	MAGIC,
	MARTIAL,
	ARCANE,
	DEVOTION, # from a deity or something
	
	MOVEMENT, # Contains movemenet
	
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

enum DamageType {
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
	ASTRAL, # Arcane force
	SPIRIT
}

enum SelectionType {
	CELL,
	CELL_EDGE,
	CELL_CORNER,
	UNIT,
	DIRECTION,
	VECTOR,
}

enum EventTiming {
	IMMEDIATE,
	POST_EFFECT,
	RESPONSE,
	END_OF_STACK,
}

enum SetupEvent {
	PRE_ATTACK,
	PRE_SPELLCAST,
	PRE_MOVE,
	PRE_ABILITY,
}

class AbilityInput:
	var selection_type: SelectionType
	var min_selections: int
	var max_selections: int
	var selection_range: float

	func _init(
		p_type: SelectionType,
		p_range: float,
		p_min: int = 1,
		p_max: int = 1
	) -> void:
		selection_type = p_type
		selection_range = p_range
		min_selections = p_min
		max_selections = p_max

	static func cell(p_range: float, p_min: int = 1, p_max: int = 1) -> AbilityInput:
		return AbilityInput.new(SelectionType.CELL, p_range, p_min, p_max)

	static func unit(p_range: float, p_min: int = 1, p_max: int = 1) -> AbilityInput:
		return AbilityInput.new(SelectionType.UNIT, p_range, p_min, p_max)

	static func cell_corner(p_range: float, p_min: int = 1, p_max: int = 1) -> AbilityInput:
		return AbilityInput.new(SelectionType.CELL_CORNER, p_range, p_min, p_max)

	static func direction(p_range: float) -> AbilityInput:
		return AbilityInput.new(SelectionType.DIRECTION, p_range)
