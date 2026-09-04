class_name BattleSide

enum Side {	PLAYER, ENEMY, NEUTRAL, ALLY, ENEMY2 }

var side_enum: BattleSide.Side = BattleSide.Side.NEUTRAL
var units: Array[Unit] = []
var loop_pos: float = 0.0

func _init(p_side_enum:BattleSide.Side) -> void:
	side_enum = p_side_enum
