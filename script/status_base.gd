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

func on_turn_start(_unit: Unit, _instance: Instance) -> void:
	pass

func on_expired(_unit: Unit, _instance: Instance) -> void:
	pass
