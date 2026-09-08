# grid_handler.gd
@tool
class_name GridHandler
extends Node3D

@export var cell_spacing: float = 1.0:
	set(value):
		cell_spacing = value
		_update_all_cells()

@export var height_step: float = 0.5:
	set(value):
		height_step = value
		_update_all_cells()

const NEIGHBOUR_OFFSETS_EVEN: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(-1, 1), Vector2i(-1, -1),
]
const NEIGHBOUR_OFFSETS_ODD: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0),
	Vector2i(1, 1), Vector2i(1, -1),
	Vector2i(0, 1), Vector2i(0, -1),
]

# Keyed by "ix,iy,iz", value is array of HexCells at that int position, iy is height
var _cells: Dictionary = {}
# Flat lookup from Vector3i int_pos to HexCell, built at runtime
var _pos_to_cell: Dictionary = {}
var cells_2d: Dictionary[Vector2i, Array] = {}
var cells_array: Array[HexCell]
var battle: Battle

enum CursorMode { CELL, EDGE, CORNER }
var cursor_mode: CursorMode = CursorMode.CELL
var _hovered_cell: HexCell
var _hovered_segment: int
#TODO: also add hovered segment, which 1/12 of the cell is hovered,
# so that the information can be used for edge and corner modes.

# --- Registration ---

func register_cell(cell: HexCell, int_pos: Vector3i) -> void:
	var key := _pos_key(int_pos)
	if not _cells.has(key):
		_cells[key] = []
	if not _cells[key].has(cell):
		_cells[key].append(cell)
	_validate_key(key)

func unregister_cell(cell: HexCell, int_pos: Vector3i) -> void:
	var key := _pos_key(int_pos)
	if _cells.has(key):
		_cells[key].erase(cell)
		if _cells[key].is_empty():
			_cells.erase(key)
		else:
			_validate_key(key)

func _validate_key(key: String) -> void:
	var cells: Array = _cells.get(key, [])
	var conflict := cells.size() > 1
	for cell: HexCell in cells:
		if conflict:
			cell.set_effect_layer(Color(1,0,0,0.5), 0)

func _pos_key(int_pos: Vector3i) -> String:
	return "%d,%d,%d" % [int_pos.x, int_pos.y, int_pos.z]

func pos_2d(int_pos: Vector3i) -> Vector2i:
	return Vector2i(int_pos.x, int_pos.z)
# --- Coordinate conversion ---

func int_to_world(int_pos: Vector3i) -> Vector3:
	var row_spacing := cell_spacing * sqrt(3.0) / 2.0
	var x_offset := 0.5 * (int_pos.z & 1) * cell_spacing
	return Vector3(
		int_pos.x * cell_spacing + x_offset,
		int_pos.y * height_step,
		int_pos.z * row_spacing
	)

func world_to_int(world_pos: Vector3) -> Vector3i:
	var row_spacing := cell_spacing * sqrt(3.0) / 2.0
	var iz := roundi(world_pos.z / row_spacing)
	var x_offset := 0.5 * (iz & 1) * cell_spacing
	var ix := roundi((world_pos.x - x_offset) / cell_spacing)
	var iy := roundi(world_pos.y / height_step)
	return Vector3i(ix, iy, iz)

# --- Cell updates ---

func _update_all_cells() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		var cell := child as HexCell
		if cell:
			cell.update_from_int_pos()

# --- Runtime lookup ---

func rebuild_pos_lookup() -> void:
	print("rebuild_pos_lookup")
	_pos_to_cell.clear()
	cells_array.clear()
	cells_2d.clear()
	
	for child in get_children():
		var cell := child as HexCell
		if cell:
			_pos_to_cell[cell.int_pos] = cell
			cells_array.append(cell)
			var pos2d := pos_2d(cell.int_pos)
			if not cells_2d.has(pos2d):
				cells_2d[pos2d] = []
			cells_2d[pos2d].append(cell)

	for cell in cells_array:
		var pos2d := pos_2d(cell.int_pos)
		var depth = -1
		if cells_2d[pos2d].size() > 1:
			for stack:HexCell in cells_2d[pos2d]:
				if stack.int_pos.y < cell.int_pos.y:
					depth = 1
		if depth < 0:
			depth = 1
			var neighbours = get_neighbours_2d(cell)
			for neighbour:HexCell in neighbours:
				if neighbour.int_pos.y < cell.int_pos.y:
					var diff = cell.int_pos.y - neighbour.int_pos.y
					depth = max(depth, diff)
		cell.set_depth(depth)
	

func get_cell_at(int_pos: Vector3i) -> HexCell:
	return _pos_to_cell.get(int_pos, null)
	
func set_hovered_cell(cell:HexCell) -> void:
	if _hovered_cell != cell:
		_hovered_cell = cell
		_on_hovered_state_changed()

func unset_hovered_cell(cell:HexCell) -> void:
	if _hovered_cell == cell:
		_hovered_cell = null
		_on_hovered_state_changed()

func _on_hovered_state_changed() -> void:
	for cell in cells_array:
		cell.set_cursor_cell(false)
	if _hovered_cell:
		_hovered_cell.set_cursor_cell(true)

func set_hovered_segment(segment:int) -> void:
	if _hovered_segment != segment:
		_hovered_segment = segment
		_on_hovered_state_changed()
	
func cell_mouse_motion(cell:HexCell, pos: Vector3) -> void:
	#Calculate which 1/12 of the cell this is.
	set_hovered_segment(get_hexagon_segment(cell, pos))

func get_hexagon_segment(cell: HexCell, world_pos: Vector3) -> int:
	var local_pos: Vector3 = cell.to_local(world_pos)
	var angle: float = atan2(local_pos.z, local_pos.x)
	if angle < 0:
		angle += 2 * PI
	return clampi(floor(12 * angle / TAU), 0, 11)

func cell_clicked(cell: HexCell, pos: Vector3, normal: Vector3) -> void:
	battle.cell_clicked(cell, pos, normal)

# --- Neighbours ---

func get_neighbours(cell: HexCell, down: int = 1, up: int = 1) -> Array[HexCell]:
	var neighbours: Array[HexCell] = []
	var pos := cell.int_pos
	var offsets := NEIGHBOUR_OFFSETS_ODD if (pos.z & 1) else NEIGHBOUR_OFFSETS_EVEN
	for offset in offsets:
		for dy in range(-down, 1 + up):
			var candidate := Vector3i(pos.x + offset.x, pos.y + dy, pos.z + offset.y)
			var neighbour := get_cell_at(candidate)
			if neighbour:
				neighbours.append(neighbour)
	return neighbours

func get_flat_neighbours(cell: HexCell) -> Array[HexCell]:
	var neighbours: Array[HexCell] = []
	var pos := cell.int_pos
	var offsets := NEIGHBOUR_OFFSETS_ODD if (pos.z & 1) else NEIGHBOUR_OFFSETS_EVEN
	for offset in offsets:
		var candidate := Vector3i(pos.x + offset.x, pos.y, pos.z + offset.y)
		var neighbour := get_cell_at(candidate)
		if neighbour:
			neighbours.append(neighbour)
	return neighbours
	
func get_neighbours_2d(cell: HexCell) -> Array[HexCell]:
	var neighbours: Array[HexCell] = []
	var pos := cell.int_pos
	var pos2d := pos_2d(pos)
	var offsets := NEIGHBOUR_OFFSETS_ODD if (pos.z & 1) else NEIGHBOUR_OFFSETS_EVEN
	for offset in offsets:
		var candidate := pos2d + offset
		if cells_2d.has(candidate):
			for neighbour in cells_2d[candidate]:
				neighbours.append(neighbour)
	return neighbours

# --- Reachability (BFS for movement) ---

func get_reachable_cells(from_cell: HexCell, range_steps: float, allow_occupied = false) -> Array[HexCell]:
	var reachable: Array[HexCell] = []
	var visited: Dictionary = {}
	var queue: Array = []
	visited[from_cell.int_pos] = true
	queue.append([from_cell, range_steps])

	while queue.size() > 0:
		var entry = queue.pop_front()
		var cell: HexCell = entry[0]
		var points: float = entry[1]

		for neighbour in get_neighbours(cell):
			if neighbour.occupant and not allow_occupied:
				continue
			if visited.has(neighbour.int_pos):
				continue
			if abs(neighbour.int_pos.y - cell.int_pos.y) > 1:
				continue
			var cost: float = neighbour.movement_cost
			var is_adjacent_to_start := cell == from_cell
			var effective_cost := cost
			if cost > points:
				if is_adjacent_to_start and points >= 1:
					effective_cost = points
				else:
					continue
			visited[neighbour.int_pos] = true
			reachable.append(neighbour)
			var remaining := points - effective_cost
			if remaining > 0:
				queue.append([neighbour, remaining])

	return reachable

# --- Radius expansion ---
func get_cells_in_radius(origin: HexCell, radius: float, vertical_buffer:int = 0) -> Array[HexCell]:
	var result: Array[HexCell] = []
	for cell:HexCell in cells_array:
		var dist = get_cell_distance(origin.int_pos, cell.int_pos, vertical_buffer) 
		if dist <= radius:
			result.append(cell)
	return result

func get_cells_in_flood_radius(origin: HexCell, radius: float) -> Array[HexCell]:
	var max_steps := int(radius)
	var result: Array[HexCell] = []
	var visited: Dictionary = {}
	var queue: Array = [[origin, 0]]
	visited[origin.int_pos] = true

	while queue.size() > 0:
		var entry = queue.pop_front()
		var cell: HexCell = entry[0]
		var dist: int = entry[1]
		result.append(cell)
		if dist >= max_steps:
			continue
		for neighbour in get_neighbours(cell):
			if not visited.has(neighbour.int_pos):
				visited[neighbour.int_pos] = true
				queue.append([neighbour, dist + 1])

	return result

# --- Pathfinding (A*) ---

func find_path(from_cell: HexCell, to_cell: HexCell, allow_occupied:bool = false) -> Array[HexCell]:
	if from_cell == to_cell:
		return [from_cell]

	var open_set: Array[HexCell] = []
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	var f_score: Dictionary = {}

	g_score[from_cell.int_pos] = 0
	f_score[from_cell.int_pos] = _heuristic(from_cell, to_cell)
	open_set.append(from_cell)

	while open_set.size() > 0:
		var current: HexCell = open_set[0]
		for cell in open_set:
			if f_score.get(cell.int_pos, INF) < f_score.get(current.int_pos, INF):
				current = cell

		if current == to_cell:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbour in get_neighbours(current):
			if abs(neighbour.int_pos.y - current.int_pos.y) > 1:
				continue
			if neighbour.occupant and not allow_occupied:
				continue
			var tentative_g: float = g_score.get(current.int_pos, INF) + 1.0
			if tentative_g < g_score.get(neighbour.int_pos, INF):
				came_from[neighbour.int_pos] = current
				g_score[neighbour.int_pos] = tentative_g
				f_score[neighbour.int_pos] = tentative_g + _heuristic(neighbour, to_cell)
				if not open_set.has(neighbour):
					open_set.append(neighbour)

	return []

func _heuristic(a: HexCell, b: HexCell) -> float:
	var ap := a.int_pos
	var bp := b.int_pos
	var dq := bp.x - ap.x
	var dr := bp.z - ap.z
	return float(maxi(abs(dq), maxi(abs(dr), abs(dq + dr))))

func _reconstruct_path(came_from: Dictionary, current: HexCell) -> Array[HexCell]:
	var path: Array[HexCell] = [current]
	while came_from.has(current.int_pos):
		current = came_from[current.int_pos]
		path.push_front(current)
	return path


# --- Distance ---

static func get_horizontal_distance(from: Vector2i, to: Vector2i) -> int:
	@warning_ignore("integer_division")
	var ax = from.x - ((from.y - (from.y & 1)) / 2)
	var az = from.y
	var ay = -ax - az

	@warning_ignore("integer_division")
	var bx = to.x - ((to.y - (to.y & 1)) / 2)
	var bz = to.y
	var by = -bx - bz

	return max(
		abs(ax - bx),
		max(
			abs(ay - by),
			abs(az - bz)
		)
	)

static func get_cell_distance(from:Vector3i, to:Vector3i, vertical_buffer:int = 0) -> int:
	var h:int = get_horizontal_distance(
		Vector2i(from.x, from.z),
		Vector2i(to.x, to.z)
	)
	var v : int = abs(from.y - to.y)
	return h + max(0, v - vertical_buffer)

static func get_cell_distance_vs(from:Vector3i, to:Vector3i) -> int: #vs = vertical square
	return max(get_horizontal_distance(
		Vector2i(from.x, from.z),
		Vector2i(to.x, to.z)
	), abs(from.y - to.y))
