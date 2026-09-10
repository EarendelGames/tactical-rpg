# aoe_shape.gd
class_name AOEShape
extends RefCounted

enum Kind { SINGLE, OFFSETS, RADIAL, FLOOD, LINE, CONE, PATH }

var kind: Kind
var offsets: Array[Vector3i] = []   # for OFFSETS
var param: Variant = 0              # radius / length, float or Evaluator
var width: Variant = 0              # for LINE/CONE
var vertical_buffer: int = 0        # passed straight to get_cells_in_radius
var include_start: bool = false

static func single() -> AOEShape:
	var s := AOEShape.new(); s.kind = Kind.SINGLE; return s

static func offsets_shape(list: Array[Vector3i]) -> AOEShape:
	var s := AOEShape.new(); s.kind = Kind.OFFSETS; s.offsets = list; return s

static func radial(radius: Variant, p_vertical_buffer: int = 0) -> AOEShape:
	var s := AOEShape.new(); s.kind = Kind.RADIAL; s.param = radius; s.vertical_buffer = p_vertical_buffer; return s

static func flood(radius: Variant) -> AOEShape:
	var s := AOEShape.new(); s.kind = Kind.FLOOD; s.param = radius; return s

static func line(length: Variant, p_width: Variant = 0) -> AOEShape:
	var s := AOEShape.new(); s.kind = Kind.LINE; s.param = length; s.width = p_width; return s
	
static func cone(length: Variant, p_width: Variant = 0) -> AOEShape:
	var s := AOEShape.new(); s.kind = Kind.CONE; s.param = length; s.width = p_width; return s
	
static func path(p_width: Variant = 0, p_include_start: bool = false) -> AOEShape:
	var s := AOEShape.new(); s.kind = Kind.PATH; s.width = p_width; s.include_start = p_include_start; return s

func get_cells(grid: GridHandler, selection: AbilitySelectionResult, unit_ability: UnitAbility = null) -> Array[HexCell]:
	match kind:
		Kind.SINGLE:  return [selection.cell]
		Kind.OFFSETS: return _offset_cells(grid, selection.cell)
		Kind.RADIAL:  return grid.get_cells_in_radius(selection.cell, _eval(param, unit_ability), vertical_buffer)
		Kind.FLOOD:   return grid.get_cells_in_flood_radius(selection.cell, _eval(param, unit_ability))
		Kind.LINE:    return _line_cells(grid, selection.cell, selection.direction, _eval(param, unit_ability))
		Kind.CONE:    return _cone_cells(grid, selection.cell, selection.direction, _eval(param, unit_ability), _eval(width, unit_ability))
		Kind.PATH:    return _path_cells(grid, selection.path, _eval(width, unit_ability), include_start)
	return []

func _eval(v: Variant, unit_ability: UnitAbility) -> float:
	return v.evaluate(unit_ability) if v is Evaluator else v

func _offset_cells(grid: GridHandler, anchor: HexCell) -> Array[HexCell]:
	var result: Array[HexCell] = []
	for offset in offsets:
		var cell := grid.get_cell_at(anchor.int_pos + offset)
		if cell:
			result.append(cell)
	return result
	
func _nearest_direction(grid: GridHandler, from_cell: HexCell, target_world_pos: Vector3) -> int:
	var segment := grid.get_hexagon_segment(from_cell, target_world_pos)
	return grid.get_edge_index_from_segment(segment)
	
func _line_cells(grid: GridHandler, anchor: HexCell, direction, length: float) -> Array[HexCell]:
	var result: Array[HexCell] = []
	var current := anchor
	for i in range(int(length)):
		var next := grid.get_neighbour_in_direction(current, direction)
		if not next:
			break
		result.append(next)
		current = next
	return result

func _cone_cells(grid: GridHandler, anchor: HexCell, direction, length: float, width_cells: float) -> Array[HexCell]:
	var result: Array[HexCell] = []
	var frontier: Array[HexCell] = [anchor]
	for depth in range(1, int(length) + 1):
		var next_frontier: Array[HexCell] = []
		for cell in frontier:
			for d_offset in range(-int(width_cells), int(width_cells) + 1):
				var dir := wrapi(direction + d_offset, 0, 6)
				var next := grid.get_neighbour_in_direction(cell, dir)
				if next and not result.has(next):
					result.append(next)
					next_frontier.append(next)
		frontier = next_frontier
	return result

func _path_cells(grid: GridHandler, selected_path: Array[HexCell], _width: float, include_start: bool) -> Array[HexCell]:
	var steps: Array[HexCell] = path if include_start else selected_path.slice(1)
	if selected_path.size() == 0:
		push_error("aoe_shape path was give a path of size 0")
	if width <= 0.0:
		return steps
	var result: Array[HexCell] = []
	for cell in steps:
		for c in grid.get_cells_in_radius(cell, width, 0):
			if not result.has(c):
				result.append(c)
	return result
