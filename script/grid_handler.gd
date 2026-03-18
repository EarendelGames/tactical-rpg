# grid_handler.gd
@tool
extends Node3D

@export var cell_spacing: float = 1.0:
	set(value):
		cell_spacing = value
		_update_all_cells()

@export var height_step: float = 0.5:
	set(value):
		height_step = value
		_update_all_cells()

# Neighbour directions for pointy-top hex, in axial coords
# Even-row and odd-row offsets for offset coordinates
const NEIGHBOUR_OFFSETS_EVEN: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),   # right, left
	Vector2i(0, 1), Vector2i(0, -1),   # down-right, up-right  
	Vector2i(-1, 1), Vector2i(-1, -1), # down-left, up-left
]
const NEIGHBOUR_OFFSETS_ODD: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),   # right, left
	Vector2i(1, 1), Vector2i(1, -1),   # down-right, up-right
	Vector2i(0, 1), Vector2i(0, -1),   # down-left, up-left
]

# Keyed by "ix,iy,iz", value is array of cells at that int position
var _cells: Dictionary = {}
# Flat lookup from Vector3i int_pos to cell node, built at runtime
var _pos_to_cell: Dictionary = {}

func register_cell(cell: Node3D, int_pos: Vector3i) -> void:
	var key = _pos_key(int_pos)
	if not _cells.has(key):
		_cells[key] = []
	if not _cells[key].has(cell):
		_cells[key].append(cell)
	_validate_key(key)

func unregister_cell(cell: Node3D, int_pos: Vector3i) -> void:
	var key = _pos_key(int_pos)
	if _cells.has(key):
		_cells[key].erase(cell)
		if _cells[key].is_empty():
			_cells.erase(key)
		else:
			_validate_key(key)

func int_to_world(int_pos: Vector3i) -> Vector3:
	var row_spacing = cell_spacing * sqrt(3.0) / 2.0
	var x_offset = 0.5 * (int_pos.z & 1) * cell_spacing
	return Vector3(
		int_pos.x * cell_spacing + x_offset,
		int_pos.y * height_step,
		int_pos.z * row_spacing
	)

func world_to_int(world_pos: Vector3) -> Vector3i:
	var row_spacing = cell_spacing * sqrt(3.0) / 2.0
	var iz = roundi(world_pos.z / row_spacing)
	var x_offset = 0.5 * (iz & 1) * cell_spacing
	var ix = roundi((world_pos.x - x_offset) / cell_spacing)
	var iy = roundi(world_pos.y / height_step)
	return Vector3i(ix, iy, iz)

func _update_all_cells() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		if child.has_method("update_from_int_pos"):
			child.update_from_int_pos()

func _validate_key(key: String) -> void:
	var cells = _cells.get(key, [])
	var conflict = cells.size() > 1
	for cell in cells:
		cell.set_invalid(conflict)

func _pos_key(int_pos: Vector3i) -> String:
	return "%d,%d,%d" % [int_pos.x, int_pos.y, int_pos.z]


func rebuild_pos_lookup() -> void:
	_pos_to_cell.clear()
	for child in get_children():
		if child.has_method("update_from_int_pos"):
			_pos_to_cell[child.int_pos] = child

func get_cell_at(int_pos: Vector3i) -> Node3D:
	return _pos_to_cell.get(int_pos, null)

func get_reachable_cells(from_cell: Node3D, range_steps: int) -> Array[Node3D]:
	var reachable: Array[Node3D] = []
	# BFS
	var visited: Dictionary = {}
	var queue: Array = []  # [cell, steps_remaining]
	visited[from_cell.int_pos] = true
	queue.append([from_cell, range_steps])

	while queue.size() > 0:
		var entry = queue.pop_front()
		var cell: Node3D = entry[0]
		var steps: int = entry[1]

		for neighbour in get_neighbours(cell):
			if visited.has(neighbour.int_pos):
				continue
			# Height difference must be at most 1
			if abs(neighbour.int_pos.y - cell.int_pos.y) > 1:
				continue
			# Can't move through or onto occupied cells (except start)
			if neighbour.occupant != null:
				continue
			visited[neighbour.int_pos] = true
			reachable.append(neighbour)
			if steps > 1:
				queue.append([neighbour, steps - 1])

	return reachable

func get_neighbours(cell: Node3D) -> Array[Node3D]:
	var neighbours: Array[Node3D] = []
	var pos = cell.int_pos
	var offsets = NEIGHBOUR_OFFSETS_ODD if (pos.z & 1) else NEIGHBOUR_OFFSETS_EVEN
	for offset in offsets:
		# Neighbours can be at any height — we find whichever y levels exist
		# Search a reasonable height range (e.g. ±4 steps)
		for dy in range(-4, 5):
			var candidate = Vector3i(pos.x + offset.x, pos.y + dy, pos.z + offset.y)
			var neighbour = get_cell_at(candidate)
			if neighbour:
				neighbours.append(neighbour)
	return neighbours
