# status.gd
class_name Status extends RefCounted

# --- Registry ---
# The registry and the status file includes cannot go in the same file
# so the status includes are in status_manager, and the registry is on Status

static var _registry: Dictionary

static func get_status(status_id: String) -> Status:
	var registry = Status._registry
	return registry.get(status_id, null)

static func all() -> Array:
	return _registry.values()

var id: String
var name: String
var description: String
var opposes: Array[String] = []

func _init(p_id: String, p_name: String, p_description: String) -> void:
	id = p_id
	name = p_name
	description = p_description
	print("adding status ", p_id)
	Status._registry[id] = self

func on_turn_start(_unit: Unit, _instance: StatusInstance) -> void:
	pass

func on_expired(_unit: Unit, _instance: StatusInstance) -> void:
	pass
