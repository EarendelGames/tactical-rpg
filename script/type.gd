# type.gd
class_name Type 

enum Damage {
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

enum EventTiming {
	IMMEDIATE,
	POST_EFFECT,
	RESPONSE,
	END_OF_STACK,
}
