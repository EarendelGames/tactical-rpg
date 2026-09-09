# aoe_shape.gd
class_name AOEShape
extends RefCounted

enum Kind { SINGLE, OFFSETS, RADIAL, FLOOD, LINE, CONE }

var kind: Kind
var offsets: Array[Vector3i] = []   # for OFFSETS
var param: Variant = 0              # radius / length, float or Evaluator
var width: Variant = 0              # for LINE/CONE
var vertical_buffer: int = 0        # passed straight to get_cells_in_radius

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
	
func get_cells(grid: GridHandler, caster_cell: HexCell, anchor: HexCell, unit_ability: UnitAbility = null) -> Array[HexCell]:
	match kind:
		Kind.SINGLE:
			return [anchor]
		Kind.OFFSETS:
			return _offset_cells(grid, anchor)
		Kind.RADIAL:
			return grid.get_cells_in_radius(anchor, _eval(param, unit_ability), vertical_buffer)
		Kind.FLOOD:
			return grid.get_cells_in_flood_radius(anchor, _eval(param, unit_ability))
		Kind.LINE:
			return _line_cells(grid, caster_cell, anchor, _eval(param, unit_ability))
		Kind.CONE:
			return _cone_cells(grid, caster_cell, anchor, _eval(param, unit_ability), _eval(width, unit_ability))
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
	
func _line_cells(grid: GridHandler, caster_cell: HexCell, anchor: HexCell, length: float) -> Array[HexCell]:
	var direction := _nearest_direction(grid, caster_cell, anchor.global_position)
	var result: Array[HexCell] = []
	var current := caster_cell
	for i in range(int(length)):
		var next := grid.get_neighbour_in_direction(current, direction)
		if not next:
			break
		result.append(next)
		current = next
	return result

func _cone_cells(grid: GridHandler, caster_cell: HexCell, anchor: HexCell, length: float, width_cells: float) -> Array[HexCell]:
	var direction := _nearest_direction(grid, caster_cell, anchor.global_position)
	var result: Array[HexCell] = []
	var frontier: Array[HexCell] = [caster_cell]
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
