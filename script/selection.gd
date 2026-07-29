class_name Selection

enum Type {
	CELL,
	CELL_EDGE,
	CELL_CORNER,
	UNIT,
	DIRECTION,
	VECTOR,
}

var cells: Array[HexCell]
var unit: Array[Unit]
