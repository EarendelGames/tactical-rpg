# statuses.gd
class_name StatusBase

# --- Instance inner class ---

class Instance:
	var status_id: String
	var stacks: int
	var data: Dictionary
	func _init(p_id: String, p_stacks: int, p_data: Dictionary = {}) -> void:
		status_id = p_id
		stacks = p_stacks
		data = p_data

# --- Registry ---

static var _registry: Dictionary = {}

static func register(status: StatusBase) -> StatusBase:
	if _registry.has(status.id):
		push_error("StatusBase: duplicate id '%s'" % status.id)
	_registry[status.id] = status
	return status

static func get_status(status_id: String) -> StatusBase:
	if not _registry.has(status_id):
		push_error("StatusBase: unknown id '%s'" % status_id)
	return _registry.get(status_id, null)

static func all() -> Array:
	return _registry.values()

# --- StatusBase fields ---

var id: String
var name: String
var description: String

func _init(p_id: String, p_name: String, p_description: String) -> void:
	id = p_id
	name = p_name
	description = p_description
	StatusBase.register(self)

func on_turn_start(unit: Unit, instance: Instance, battle: Battle) -> void:
	pass

func on_expired(unit: Unit, instance: Instance, battle: Battle) -> void:
	pass

# --- Definitions ---
#
#class Oil extends StatusBase:
	#func _init() -> void:
		#super("oil", "Oil", "Flammable. Converts to fire stacks when hit by fire damage.")
	#func on_turn_start(unit: Unit, instance: Instance, _battle: Battle) -> void:
		#var fire_instance := unit.get_status("fire")
		#if fire_instance:
			#fire_instance.stacks += instance.stacks
			#unit.remove_status("oil")
#
#class Fire extends StatusBase:
	#func _init() -> void:
		#super("fire", "Fire", "Burns the unit each turn. Ignites oil on contact.")
	#func on_turn_start(unit: Unit, instance: Instance, _battle: Battle) -> void:
		#var oil_instance := unit.get_status("oil")
		#if oil_instance:
			#instance.stacks += oil_instance.stacks
			#unit.remove_status("oil")
		#var tree := SequenceTree.new(null, null, [])
		#var node := EventNode.new(
			#BattleEnums.EventTiming.IMMEDIATE,
			#func(): unit.take_damage(float(instance.stacks), BattleEnums.DamageType.FIRE, tree, null)
		#)
		#tree.add_root_node(node)
		#tree.resolve()
		#instance.stacks -= 1
		#if instance.stacks <= 0:
			#unit.remove_status("fire")
#
## --- Static instances — forces registration at load time ---
#
#static var _oil := Oil.new()
#static var _fire := Fire.new()
