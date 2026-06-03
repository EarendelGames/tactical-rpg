# battle/movement_executor.gd
class_name MovementExecutor

static func execute(
	unit: Unit,
	path: Array[HexCell],
	tree: EventTree,
	start_cell: HexCell
) -> void:
	for i in range(path.size()):
		var target_cell: HexCell = path[i]

		if unit.movement_points <= 0:
			break

		var cost: float = target_cell.movement_cost
		var is_adjacent_to_start := _is_adjacent(start_cell, target_cell, tree)

		if cost > unit.movement_points:
			if is_adjacent_to_start and unit.movement_points >= 1:
				cost = unit.movement_points
			else:
				break

		var captured_cell := target_cell
		var captured_cost := cost
		var step_node := EventNode.new(
			BattleEnums.EventTiming.IMMEDIATE,
			func():
				unit.movement_points -= captured_cost
				unit.place_on_cell(captured_cell),
			unit
		)
		tree.add_root_node(step_node)
		tree.resolve()

		if tree.is_movement_cancelled():
			break

		if target_cell._movement_triggers.size() > 0:
			var trigger_node := EventNode.new(
				BattleEnums.EventTiming.RESPONSE,
				func(): pass,
				null
			)
			tree.add_root_node(trigger_node)
			target_cell.fire_movement_triggers(tree, trigger_node, unit)
			tree.resolve()

		if tree.is_movement_cancelled():
			break

static func _is_adjacent(start_cell: HexCell, target_cell: HexCell, tree: EventTree) -> bool:
	var neighbours := tree.battle.grid.get_neighbours(start_cell)
	return neighbours.has(target_cell)
