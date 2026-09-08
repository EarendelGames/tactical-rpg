@tool
class_name HexMesh
extends MeshInstance3D

@export var diameter: int = 1:
	set(value):
		diameter = max(1, value)
		_update_mesh()

func _ready() -> void:
	_update_mesh()

func _update_mesh() -> void:
	if not is_inside_tree():
		return
		
	var am := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	
	# Geometric math matching the HexBody collision dimensions
	var corner_radius: float = diameter * 0.5 / cos(PI / 6.0)
	
	# =========================================================================
	# 1. TOP CAP (Sits at y = 0)
	# =========================================================================
	# Center vertex for the fan
	vertices.append(Vector3(0, 0, 0))
	uvs.append(Vector2(0.5, 0.5)) # Center of the texture
	
	# Outer perimeter vertices
	for i in range(6):
		var angle := (i + 0.5) * (PI / 3.0)
		var x := corner_radius * cos(angle)
		var z := corner_radius * sin(angle)
		vertices.append(Vector3(x, 0, z))
		
		# UV projection based on the max horizontal span (2 * corner_radius)
		# Maps perfectly to a 0.0 - 1.0 UV space without distortion
		var u := (x / (2.0 * corner_radius)) + 0.5
		var v := (z / (2.0 * corner_radius)) + 0.5
		uvs.append(Vector2(u, v))
		
	# Top Cap Triangles (Clockwise winding order)
	for i in range(6):
		indices.append(0)
		indices.append(i + 1)
		indices.append((i + 1) % 6 + 1)

	# =========================================================================
	# 4. COMMIT MESH
	# =========================================================================
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = am
