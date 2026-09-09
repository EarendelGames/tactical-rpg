# statuses.gd

class Oil extends StatusBase:
	func _init() -> void:
		super("oil", "Oil", "Flammable. Converts to fire stacks when hit by fire damage.")
	func on_turn_start(unit: Unit, instance: Instance) -> void:
		var fire_instance := unit.get_status("fire")
		if fire_instance:
			fire_instance.stacks += instance.stacks
			unit.remove_status("oil")

class Fire extends StatusBase:
	func _init() -> void:
		super("fire", "Fire", "Burns the unit each turn. Ignites oil on contact.")
	func on_turn_start(unit: Unit, instance: Instance) -> void:
		var oil_instance := unit.get_status("oil")
		if oil_instance:
			instance.stacks += oil_instance.stacks
			unit.remove_status("oil")
		unit.apply_damage(float(instance.stacks), Type.Damage.FIRE, null, null)
		instance.stacks -= 1
		if instance.stacks <= 0:
			unit.remove_status("fire")

class Slow extends StatusBase:
	func _init() -> void:
		super("slow", "Slow", "Reduces movement points this turn.")
	func on_turn_start(unit: Unit, instance: Instance) -> void:
		unit.movement_points = maxf(0.0, unit.movement_points - instance.stacks)
		instance.stacks -= 1
		if instance.stacks <= 0:
			unit.remove_status("slow")

static var oil := Oil.new()
static var fire := Fire.new()
static var slow := Slow.new()
