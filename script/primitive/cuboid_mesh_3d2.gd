@tool
class_name CuboidMesh3D2 extends ArrayMesh

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

@export var uv_scale: float = 1.0:
	set(value):
		uv_scale = value
		_request_rebuild()

@export var flip_faces: bool = false:
	set(value):
		flip_faces = value
		_request_rebuild()

@export var material: Material:
	set(value):
		material = value
		if get_surface_count() > 0:
			surface_set_material(0, material)

const AXES := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
# Side directions walked in order around the Y (pole) axis, used for the UV perimeter.
const DIRS := [Vector3.RIGHT, Vector3.BACK, Vector3.LEFT, Vector3.FORWARD]

var _vertices := PackedVector3Array()
var _normals := PackedVector3Array()
var _uvs := PackedVector2Array()
var _indices := PackedInt32Array()

var _inner := Vector3.ZERO
var _radius := 0.0
var _qlen := 0.0
var _face_u0 := PackedFloat64Array()
var _face_u1 := PackedFloat64Array()
var _corner_u := PackedFloat64Array()
var _total_u := 0.0

func _init() -> void:
	_rebuild_mesh()

func _request_rebuild() -> void:
	_rebuild_mesh.call_deferred()

func _rebuild_mesh() -> void:
	clear_surfaces()
	_vertices.clear()
	_normals.clear()
	_uvs.clear()
	_indices.clear()

	_radius = minf(corner_radius, minf(size.x, minf(size.y, size.z)) * 0.5)
	_inner = size * 0.5 - Vector3.ONE * _radius
	_qlen = _radius * PI * 0.5
	var steps := corner_steps
	var quarter := PI * 0.5 / (steps - 1)
	_build_uv_layout()

	_build_faces()
	_build_edges(steps, quarter)
	_build_corners(steps, quarter)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _vertices
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_INDEX] = _indices
	add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material:
		surface_set_material(0, material)

# Walks the 4 side faces around Y, assigning each a U range, and each of the
# 4 vertical corner-columns between them a U start (u range = corner_u..corner_u+_qlen).
func _build_uv_layout() -> void:
	_face_u0.clear()
	_face_u1.clear()
	_corner_u.clear()
	var u := 0.0
	for i in 4:
		var wdir: Vector3 = DIRS[(i + 1) % 4]
		var wext := _inner.x if absf(wdir.x) > 0.5 else _inner.z
		_face_u0.append(u)
		u += 2.0 * wext
		_face_u1.append(u)
		_corner_u.append(u)
		u += _qlen
	_total_u = u

# Finds i such that (DIRS[i], DIRS[i+1]) == (first, second) in either order.
# Returns [corner_index, reversed]; reversed means (first, second) is (DIRS[i+1], DIRS[i]).
func _find_corner(first: Vector3, second: Vector3) -> Array:
	for k in 4:
		if DIRS[k] == first and DIRS[(k + 1) % 4] == second:
			return [k, false]
		if DIRS[k] == second and DIRS[(k + 1) % 4] == first:
			return [k, true]
	return [0, false] # unreachable for valid axis-aligned inputs

func _build_faces() -> void:
	for n: Vector3 in AXES:
		var u_vec := Vector3(n.y, n.z, n.x)
		var v_vec := u_vec.cross(n)
		var is_cap := n == Vector3.UP or n == Vector3.DOWN
		var face_i := -1
		var wdir := Vector3.ZERO
		var wext := 0.0
		if not is_cap:
			face_i = DIRS.find(n)
			wdir = DIRS[(face_i + 1) % 4]
			wext = _inner.x if absf(wdir.x) > 0.5 else _inner.z

		var centers := PackedVector3Array()
		var normals := PackedVector3Array()
		var uvs := PackedVector2Array()
		for i in 2:
			for j in 2:
				var c := (n + u_vec * (i * 2 - 1) + v_vec * (j * 2 - 1)) * _inner
				centers.append(c)
				normals.append(n)
				var pos := c + n * _radius
				if is_cap:
					var lx := pos.x + _inner.x
					var lz := pos.z + _inner.z
					var vv := lz + (2.0 * _inner.z if n.y > 0.0 else 0.0)
					uvs.append(Vector2(_total_u + lx, vv))
				else:
					var t := (pos.dot(wdir) + wext) / (2.0 * wext)
					uvs.append(Vector2(lerp(_face_u0[face_i], _face_u1[face_i], t), pos.y + _inner.y + _qlen))
		_add_patch(2, 2, centers, normals, uvs, false)

func _build_edges(steps: int, quarter: float) -> void:
	for axis_p in 3:
		for axis_q in range(axis_p + 1, 3):
			for sign_p in [-1.0, 1.0]:
				for sign_q in [-1.0, 1.0]:
					var p := Vector3.ZERO
					var q := Vector3.ZERO
					p[axis_p] = sign_p
					q[axis_q] = sign_q
					var w := q.cross(p)

					var vertical := axis_p == 0 and axis_q == 2
					var corner_i := 0
					var reversed_arc := false
					var face_i := -1
					var wdir := Vector3.ZERO
					var wext := 0.0
					var row_is_face_first := axis_p != 1 # true when p (row 0) is the horizontal axis, not Y
					var y_sign := p.y + q.y # whichever of p, q is Y contributes its sign, the other contributes 0
					if vertical:
						var res := _find_corner(p, q)
						corner_i = res[0]
						reversed_arc = res[1]
					else:
						var h := p if axis_p != 1 else q
						face_i = DIRS.find(h)
						wdir = DIRS[(face_i + 1) % 4]
						wext = _inner.x if absf(wdir.x) > 0.5 else _inner.z

					var face_v := _qlen if y_sign < 0.0 else _qlen + 2.0 * _inner.y
					var cap_v := 0.0 if y_sign < 0.0 else 2.0 * _qlen + 2.0 * _inner.y

					var centers := PackedVector3Array()
					var normals := PackedVector3Array()
					var uvs := PackedVector2Array()
					for i in steps:
						var dir := p * cos(i * quarter) + q * sin(i * quarter)
						var row_t := float(i) / float(steps - 1)
						for j in 2:
							var c := (p + q + w * (j * 2 - 1)) * _inner
							centers.append(c)
							normals.append(dir)
							var pos := c + dir * _radius
							var uu := 0.0
							var vv := 0.0
							if vertical:
								var t := row_t
								if reversed_arc:
									t = 1.0 - t
								uu = _corner_u[corner_i] + t * _qlen
								vv = pos.y + _inner.y + _qlen
							else:
								var col_dir := w * (j * 2 - 1)
								var t2 := 0.0 if col_dir.dot(wdir) < 0.0 else 1.0
								uu = lerp(_face_u0[face_i], _face_u1[face_i], t2)
								var t_to_cap := row_t if row_is_face_first else 1.0 - row_t
								vv = lerp(face_v, cap_v, t_to_cap)
							uvs.append(Vector2(uu, vv))
					_add_patch(steps, 2, centers, normals, uvs, false)

func _build_corners(steps: int, quarter: float) -> void:
	for b: Vector3 in [Vector3.UP, Vector3.DOWN]:
		for a: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
			var c := a.cross(b)
			var res := _find_corner(a, c)
			var corner_i: int = res[0]
			var reversed_az: bool = res[1]
			var total_v := 2.0 * _qlen + 2.0 * _inner.y

			var centers := PackedVector3Array()
			var normals := PackedVector3Array()
			var uvs := PackedVector2Array()
			for i in steps:
				var row_t := float(i) / float(steps - 1) # 0 at the pole (cap), 1 at the equator
				var vv := total_v - row_t * _qlen if b.y > 0.0 else row_t * _qlen
				for j in steps:
					var polar := i * quarter
					var azimuth := j * quarter
					var c3 := (a + b + c) * _inner
					var n3 := a * (sin(polar) * cos(azimuth)) + b * cos(polar) + c * (sin(polar) * sin(azimuth))
					centers.append(c3)
					normals.append(n3)
					var t := float(j) / float(steps - 1)
					if reversed_az:
						t = 1.0 - t
					var uu := _corner_u[corner_i] + t * _qlen
					uvs.append(Vector2(uu, vv))
			_add_patch(steps, steps, centers, normals, uvs, true)

# Every vertex is center + normal * radius. The grid is laid out so that d(i) x d(j) = -normal.
func _add_patch(rows: int, cols: int, centers: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, has_pole: bool) -> void:
	var base := _vertices.size()
	for k in centers.size():
		_vertices.append(centers[k] + normals[k] * _radius)
		_normals.append(-normals[k] if flip_faces else normals[k])
		_uvs.append(uvs[k] * uv_scale)

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
