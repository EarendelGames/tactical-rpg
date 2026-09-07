@tool
class_name HexBody
extends StaticBody3D

# Globally shared cache across all HexBody instances
static var shape_cache: Dictionary[StringName, ConvexPolygonShape3D] = {}

@export var edge_radius: int = 1:
	set(value):
		edge_radius = max(1, value) # Prevent 0 or negative radius
		_update_cell_geometry()

@export var depth: int = 1:
	set(value):
		depth = max(1, value) # Prevent 0 or negative depth
		_update_cell_geometry()

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	_update_cell_geometry()

func _update_cell_geometry() -> void:
	if not is_inside_tree() or not mesh_instance or not collision_shape:
		return

	# Clean key utilizing only the two integers
	var cache_key := StringName("%d_%d" % [edge_radius, depth])
	
	# 1. Handle collision shape caching
	if shape_cache.has(cache_key):
		collision_shape.shape = shape_cache[cache_key]
	else:
		var new_shape := _generate_convex_shape(edge_radius, depth)
		shape_cache[cache_key] = new_shape
		collision_shape.shape = new_shape

	# 2. Update visual mesh
	mesh_instance.mesh = _generate_visual_mesh(edge_radius, depth)

# Helper function to compute raw outer vertices for the convex shape
func _generate_convex_shape(radius: int, d: int) -> ConvexPolygonShape3D:
	var corner_radius: float = radius / cos(PI / 6.0)
	var vertices := PackedVector3Array()
	
	# Top layer sits at y = 0, bottom layer extends down to y = -depth
	for side in range(2):
		var y: float = 0.0 if side == 0 else -float(d)
		for i in range(6):
			var angle := i * (PI / 3.0)
			var x := corner_radius * cos(angle)
			var z := corner_radius * sin(angle)
			vertices.append(Vector3(x, y, z))
			
	var shape := ConvexPolygonShape3D.new()
	shape.points = vertices
	return shape

# Helper function to generate the visual representation
func _generate_visual_mesh(radius: int, d: int) -> ArrayMesh:
	var corner_radius: float = radius / cos(PI / 6.0)
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	
	# Top layer sits at y = 0, bottom layer extends down to y = -depth
	for side in range(2):
		var y: float = 0.0 if side == 0 else -float(d)
		for i in range(6):
			var angle := i * (PI / 3.0)
			var x := corner_radius * cos(angle)
			var z := corner_radius * sin(angle)
			vertices.append(Vector3(x, y, z))
			
	vertices.append(Vector3(0, 0, 0))        # Top Center (12)
	vertices.append(Vector3(0, -float(d), 0)) # Bottom Center (13)
	
	# Top Cap
	for i in range(6):
		indices.append(12)
		indices.append((i + 1) % 6)
		indices.append(i)
		
	# Bottom Cap
	for i in range(6):
		indices.append(13)
		indices.append(6 + i)
		indices.append(6 + ((i + 1) % 6))
		
	# Sides
	for i in range(6):
		var tl := i
		var tr := (i + 1) % 6
		var bl := i + 6
		var br := ((i + 1) % 6) + 6
		indices.append(tl)
		indices.append(tr)
		indices.append(br)
		indices.append(tl)
		indices.append(br)
		indices.append(bl)
		
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am
