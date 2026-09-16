# statuses.gd
class_name Statuses

static var _registry: Dictionary
static var status_sets = Statuses

static func get_status(status_id: String) -> StatusBase:
	var registry = Statuses._registry
	return registry.get(status_id, null)

static func all() -> Array:
	return _registry.values()

static var oil := Oil.new()
class Oil extends StatusBase:
	func _init() -> void:
		super("oil", "Oil", "Flammable. Converts to fire stacks when hit by fire damage.")
	func on_turn_start(unit: Unit, instance: StatusInstance) -> void:
		var fire_instance := unit.get_status("fire")
		if fire_instance:
			fire_instance.stacks += instance.stacks
			unit.remove_status("oil")

static var fire := Fire.new()
class Fire extends StatusBase:
	func _init() -> void:
		super("fire", "Fire", "Burns the unit each turn. Ignites oil on contact.")
	func on_turn_start(unit: Unit, instance: StatusInstance) -> void:
		var oil_instance := unit.get_status("oil")
		if oil_instance:
			instance.stacks += oil_instance.stacks
			unit.remove_status("oil")
		unit.apply_damage(float(instance.get_total_magnitude()), Type.Damage.FIRE, null, null)

static var slow := Slow.new()
class Slow extends StatusBase:
	func _init() -> void:
		super("slow", "Slow", "Reduces movement points this turn.")
	func on_turn_start(unit: Unit, instance: StatusInstance) -> void:
		unit.movement_points = maxf(0.0, unit.movement_points - instance.get_total_magnitude())
