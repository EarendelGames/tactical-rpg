# battle/event_tree.gd
class_name EventTree

const MAX_DEPTH := 8

var caster: Unit
var ability: AbilityBase
var resolved_inputs: Array
var root_nodes: Array[EventNode] = []
var end_of_stack_queue: Array[EventNode] = []
var battle: Battle
var _interrupted_units: Array[Unit] = []
var _movement_cancelled: bool = false

func _init(p_caster: Unit, p_ability: AbilityBase, p_inputs: Array) -> void:
	caster = p_caster
	ability = p_ability
	resolved_inputs = p_inputs

func add_root_node(node: EventNode) -> void:
	node.depth = 0
	root_nodes.append(node)

func add_end_of_stack(node: EventNode) -> void:
	end_of_stack_queue.append(node)

func cancel_movement() -> void:
	_movement_cancelled = true

func is_movement_cancelled() -> bool:
	return _movement_cancelled

func interrupt_unit(unit: Unit) -> void:
	_interrupted_units.append(unit)
	_remove_interruptible_from(root_nodes, unit)
	_remove_interruptible_from(end_of_stack_queue, unit)

func _remove_interruptible_from(nodes: Array, unit: Unit) -> void:
	var i := nodes.size() - 1
	while i >= 0:
		var node: EventNode = nodes[i]
		if node.interruptible and node.owner == unit:
			nodes.remove_at(i)
		else:
			_remove_interruptible_from(node.children, unit)
		i -= 1

func fire_setup_event(
	event: BattleEnums.SetupEvent,
	source: Unit,
	parent_node: EventNode
) -> void:
	if not battle:
		return
	for unit in battle.units:
		if unit.is_dead:
			continue
		for trigger in unit.get_triggers_for_setup_event(event):
			if trigger["cancel_if"].is_valid() and trigger["cancel_if"].call():
				continue
			trigger["callable"].call(self, parent_node, source)
	if parent_node:
		var setup_children := parent_node.children.duplicate()
		parent_node.children.clear()
		for child in setup_children:
			_resolve_node(child)

func resolve() -> void:
	for node in root_nodes:
		_resolve_node(node)
	root_nodes.clear()
	for node in end_of_stack_queue:
		_resolve_node(node)
	end_of_stack_queue.clear()

func _resolve_node(node: EventNode) -> void:
	if node.depth >= MAX_DEPTH:
		push_warning("EventTree: max depth reached, discarding node")
		return
	if node.cancel_if.is_valid() and node.cancel_if.call(node, self):
		return
	if node.effect.is_valid():
		node.effect.call()
	var sorted_children := node.children.duplicate()
	sorted_children.sort_custom(func(a: EventNode, b: EventNode): return a.timing < b.timing)
	var i := sorted_children.size() - 1
	while i >= 0:
		if sorted_children[i].timing == BattleEnums.EventTiming.END_OF_STACK:
			end_of_stack_queue.append(sorted_children[i])
			sorted_children.remove_at(i)
		i -= 1
	for child in sorted_children:
		_resolve_node(child)
