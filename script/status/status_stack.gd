# status_stack.gd
class_name StatusStack

var magnitude: int
var duration: int
var source: UnitAbility

func _init(p_magnitude: int, p_duration: int, p_source: UnitAbility = null) -> void:
	magnitude = p_magnitude
	duration = p_duration
	source = p_source
