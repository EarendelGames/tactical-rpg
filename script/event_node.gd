# battle/event_node.gd
class_name EventNode

var timing: BattleEnums.EventTiming
var effect: Callable
var interruptible: bool = false
var cancel_if: Callable
var owner: Unit
var children: Array[EventNode] = []
var parent: EventNode = null
var depth: int = 0

func _init(
	p_timing: BattleEnums.EventTiming,
	p_effect: Callable,
	p_owner: Unit = null,
	p_interruptible: bool = false,
	p_cancel_if: Callable = Callable()
) -> void:
	timing = p_timing
	effect = p_effect
	owner = p_owner
	interruptible = p_interruptible
	cancel_if = p_cancel_if

func add_child_node(child: EventNode) -> void:
	child.parent = self
	child.depth = depth + 1
	children.append(child)
