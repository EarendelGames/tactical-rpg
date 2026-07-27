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
