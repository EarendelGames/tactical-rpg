# battle/sequence_tree.gd
class_name SequenceTree

const MAX_DEPTH := 8

var instigating_ability: UnitAbility
var inputs: Dictionary = {} # Input can be a unit, tile, tile corner, tile edge, or vector.
var triggered_events: Array[EventNode] = []
var immediate_actions: Array[ActionNode] = []
var sequential_actions: Array[ActionNode] = []
var processed_actions: Array[ActionNode] = []
var battle: Battle

func _init(p_battle: Battle, p_instigator: UnitAbility, p_inputs) -> void:
	battle = p_battle
	instigating_ability = p_instigator
	inputs = p_inputs

func append_sequential_action(new_action = ActionNode) -> void:
	sequential_actions.append(new_action)

func prepend_sequential_action(new_action = ActionNode) -> void:
	sequential_actions.push_front(new_action)

func append_immediate_actions(new_action = ActionNode) -> void:
	immediate_actions.append(new_action)

func process_next_action()-> bool:
	if immediate_actions.size() > 0:
		var action : ActionNode = immediate_actions.pop_front()
		print("SequenceTree execute immediate action")
		action.execute(self)
		processed_actions.append(action)
		return true
	if sequential_actions.size() > 0:
		var action : ActionNode = sequential_actions.pop_front()
		print("SequenceTree execute sequential action")
		action.execute(self)
		processed_actions.append(action)
		return true
	return false
