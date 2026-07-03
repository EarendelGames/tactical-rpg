# battle/movement_executor.gd
class_name MovementExecutor

static func execute(
	unit: Unit,
	path: Array[HexCell],
	tree: SequenceTree
) -> void:
	# Put movement actions into the tree.
	# Movements is processed by the tree processing the contained actions.
	for i in range(path.size()):
		var target_cell: HexCell = path[i]
		tree.append_sequential_action(ActionMove(unit.ability_move, unit, target_cell))
