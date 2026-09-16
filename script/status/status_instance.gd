# status_instance.gd
class_name StatusInstance

var status_id: String
var stacks: Array[StatusStack]

func _init(p_id: String) -> void:
	status_id = p_id

func get_status() -> StatusBase:
	return Statuses.get_status(status_id)

func get_total_magnitude() -> int:
	var sum: int = 0
	for stack in stacks:
		sum += stack.magnitude
	return sum

func get_max_duration() -> int:
	var longest := -1
	for stack in stacks:
		longest = max(longest, stack.duration)
	return longest

func is_empty() -> bool:
	return stacks.is_empty()

func remove_stack(stack: StatusStack) -> void:
	stacks.erase(stack)

func add_stack(stack: StatusStack) -> void:
	stacks.append(stack)
