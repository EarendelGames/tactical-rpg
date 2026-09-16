# status_base.gd
class_name StatusBase extends RefCounted

var id: String
var name: String
var description: String
var opposes: Array[String] = []

func _init(p_id: String, p_name: String, p_description: String) -> void:
	id = p_id
	name = p_name
	description = p_description
	print("adding status ", p_id)
	Statuses._registry[id] = self

func on_turn_start(_unit: Unit, _instance: StatusInstance) -> void:
	pass

func on_expired(_unit: Unit, _instance: StatusInstance) -> void:
	pass
