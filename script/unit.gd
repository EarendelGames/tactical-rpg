# unit.gd
@tool
extends Node3D

enum Force { PLAYER, ENEMY, NEUTRAL }

@export var unit_name: String = "Unit"
@export var initiative_modifier: float = 0.0
@export var movement_range: int = 3
@export var force: Force = Force.ENEMY

# Set at runtime
var initiative: float = 0.0
var current_cell: Node3D = null

func roll_initiative() -> void:
	initiative = randf_range(0.0, 10.0) + initiative_modifier
	
func place_on_cell(cell: Node3D) -> void:
	if current_cell:
		current_cell.occupant = null
	current_cell = cell
	cell.occupant = self
	# Snap world position to cell
	global_position = cell.global_position

func get_int_pos() -> Vector3i:
	if current_cell:
		return current_cell.int_pos
	return Vector3i.ZERO
