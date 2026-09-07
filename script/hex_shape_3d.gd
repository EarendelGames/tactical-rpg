@tool
class_name HexShape3D
extends CollisionShape3D

# Globally shared cache across all HexBody instances
static var shape_cache: Dictionary[StringName, ConvexPolygonShape3D] = {}

@export var diameter: int = 1:
	set(value):
		diameter = max(1, value) # Prevent 0 or negative diameter
		_update_shape()

@export var depth: int = 1:
	set(value):
		depth = max(1, value) # Prevent 0 or negative depth
		_update_shape()

func _ready() -> void:
	_update_shape()

func _update_shape() -> void:
	if not is_inside_tree():
		return

	# Unique key utilizing only the two integers
	var cache_key := StringName("%d_%d" % [diameter, depth])
	
	# Handle collision shape caching
	if false and shape_cache.has(cache_key):
		self.shape = shape_cache[cache_key]
	else:
		var new_shape := _generate_convex_shape(diameter, depth)
		shape_cache[cache_key] = new_shape
		self.shape = new_shape

# Helper function to compute raw outer vertices for the convex shape
func _generate_convex_shape(diameter: int, d: int) -> ConvexPolygonShape3D:
	var corner_radius: float = diameter * 0.5 / cos(PI / 6.0)
	var vertices := PackedVector3Array()
	
	# Top layer sits at y = 0, bottom layer extends down to y = -depth
	for side in range(2):
		var y: float = 0.0 if side == 0 else -float(d) * 0.5
		for i in range(6):
			var angle := (i + 0.5) * (PI / 3.0)
			var x := corner_radius * cos(angle)
			var z := corner_radius * sin(angle)
			vertices.append(Vector3(x, y, z))
			
	var new_shape := ConvexPolygonShape3D.new()
	new_shape.points = vertices
	return new_shape
