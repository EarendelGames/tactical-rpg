@tool
class_name CuboidMesh3D extends ArrayMesh

@export var size: Vector3 = Vector3(2.0, 2.0, 2.0):
	set(value):
		size = Vector3(max(0.1, value.x), max(0.1, value.y), max(0.1, value.z))
		_request_rebuild()

@export var corner_radius: float = 0.2:
	set(value):
		corner_radius = max(0.0, value)
		_request_rebuild()

@export var corner_steps: int = 2:
	set(value):
		corner_steps = max(2, value) # 2 = exactly 2 points = 0 intermediate vertices
		_request_rebuild()

@export var flip_faces: bool = false:
	set(value):
		flip_faces = value
		_request_rebuild()

@export var flip_normals: bool = false:
	set(value):
		flip_normals = value
		_request_rebuild()

@export var material: Material = null:
	set(value):
		material = value
		_request_rebuild()
	
const AXES := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]

var _vertices := PackedVector3Array()
var _normals := PackedVector3Array()
var _indices := PackedInt32Array()

func _init() -> void:
	_rebuild_mesh()

func _request_rebuild() -> void:
	_rebuild_mesh.call_deferred()

func _rebuild_mesh() -> void:
	clear_surfaces()
	_vertices.clear()
	_normals.clear()
	_indices.clear()

	var radius := minf(corner_radius, minf(size.x, minf(size.y, size.z)) * 0.5)
	var inner := size * 0.5 - Vector3.ONE * radius # half extents of the inset face rectangle
	var steps := corner_steps
	var quarter := PI * 0.5 / (steps - 1)

	# Faces: 2x2 grid, u x v = -normal.
	for n: Vector3 in AXES:
		var u := Vector3(n.y, n.z, n.x)
		var v := u.cross(n)
		var centers := PackedVector3Array()
		var normals := PackedVector3Array()
		for i in 2:
			for j in 2:
				centers.append((n + u * (i * 2 - 1) + v * (j * 2 - 1)) * inner)
				normals.append(n)
		_add_patch(2, 2, centers, normals, radius, false)

	# Edges: `steps` rows along the arc from p to q, 2 columns along w = q x p.
	for axis_p in 3:
		for axis_q in range(axis_p + 1, 3):
			for sign_p in [-1.0, 1.0]:
				for sign_q in [-1.0, 1.0]:
					var p := Vector3.ZERO
					var q := Vector3.ZERO
					p[axis_p] = sign_p
					q[axis_q] = sign_q
					var w := q.cross(p)
					var centers := PackedVector3Array()
					var normals := PackedVector3Array()
					for i in steps:
						var dir := p * cos(i * quarter) + q * sin(i * quarter)
						for j in 2:
							centers.append((p + q + w * (j * 2 - 1)) * inner)
							normals.append(dir)
					_add_patch(steps, 2, centers, normals, radius, false)

	# Corners: sphere octants with the pole on b. (a, b, c) is a right-handed axis triple.
	# Row 0 is the pole (all columns coincide), so it is stitched with triangles only.
	for b: Vector3 in [Vector3.UP, Vector3.DOWN]:
		for a: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
			var c := a.cross(b)
			var centers := PackedVector3Array()
			var normals := PackedVector3Array()
			for i in steps:
				for j in steps:
					var polar := i * quarter
					var azimuth := j * quarter
					centers.append((a + b + c) * inner)
					normals.append(a * (sin(polar) * cos(azimuth)) + b * cos(polar) + c * (sin(polar) * sin(azimuth)))
			_add_patch(steps, steps, centers, normals, radius, true)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _vertices
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_INDEX] = _indices
	add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	surface_set_material(0, material)

# Every vertex is center + normal * radius. The grid is laid out so that d(i) x d(j) = -normal.
func _add_patch(rows: int, cols: int, centers: PackedVector3Array, normals: PackedVector3Array, radius: float, has_pole: bool) -> void:
	var base := _vertices.size()
	for k in centers.size():
		_vertices.append(centers[k] + normals[k] * radius)
		_normals.append(-normals[k] if flip_normals else normals[k])

	for i in rows - 1:
		for j in cols - 1:
			var a := base + i * cols + j
			var b := a + cols
			var c := b + 1
			var d := a + 1
			_add_tri(a, b, c)
			if not (has_pole and i == 0):
				_add_tri(a, c, d)

func _add_tri(a: int, b: int, c: int) -> void:
	_indices.append_array([a, c, b] if flip_faces else [a, b, c])
