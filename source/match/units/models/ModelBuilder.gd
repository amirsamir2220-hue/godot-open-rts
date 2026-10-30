# Builds low-poly meshes out of simple solids (boxes, tapered boxes, cylinders, domes).
# Every part added to one builder is merged into a single ArrayMesh with at most two surfaces:
#   0 - all regular parts, colored with vertex colors (one shared material)
#   1 - team-color parts (material is replaced per player, see FactionModels.apply_team_color)
# Keeping it to one mesh per moving part keeps draw calls low on integrated GPUs.
extends RefCounted

const TEAM = Color(1.0, 0.0, 1.0, 0.0)  # sentinel color: part is painted with player color

var _regular = []  # [position, normal, color] triples
var _team = []
var _stack = [Transform3D.IDENTITY]


static func xf(pos = Vector3.ZERO, rot_deg = Vector3.ZERO, scl = Vector3.ONE):
	var rot = Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z))
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(scl), pos)


func push(t):
	_stack.append(_stack.back() * t)


func pop():
	assert(_stack.size() > 1, "unbalanced pop()")
	_stack.pop_back()


func is_empty():
	return _regular.is_empty() and _team.is_empty()


## Hexahedron with a rectangular bottom (size_bottom.x by size_bottom.y on XZ) at y=0 and
## a rectangular top (size_top) at y=height, shifted by top_shift on XZ. Origin at bottom center.
func tapered_box(t, size_bottom, size_top, height, color, top_shift = Vector2.ZERO):
	var bx = size_bottom.x * 0.5
	var bz = size_bottom.y * 0.5
	var tx = size_top.x * 0.5
	var tz = size_top.y * 0.5
	var b = [Vector3(-bx, 0, -bz), Vector3(bx, 0, -bz), Vector3(bx, 0, bz), Vector3(-bx, 0, bz)]
	var s = Vector3(top_shift.x, height, top_shift.y)
	var u = [
		Vector3(-tx, 0, -tz) + s,
		Vector3(tx, 0, -tz) + s,
		Vector3(tx, 0, tz) + s,
		Vector3(-tx, 0, tz) + s
	]
	var faces = [
		[b[0], b[1], b[2], b[3]],
		[u[0], u[1], u[2], u[3]],
		[b[0], b[1], u[1], u[0]],
		[b[1], b[2], u[2], u[1]],
		[b[2], b[3], u[3], u[2]],
		[b[3], b[0], u[0], u[3]],
	]
	_add_convex_faces(t, faces, color)


## Axis-aligned box centered at the origin of t.
func box(t, size, color):
	tapered_box(
		t * Transform3D(Basis(), Vector3(0, -size.y * 0.5, 0)),
		Vector2(size.x, size.z),
		Vector2(size.x, size.z),
		size.y,
		color
	)


## Cylinder (or cone/frustum) along local Y, centered at the origin of t.
func cylinder(t, radius_bottom, radius_top, height, color, sides = 8, smooth = true, caps = true):
	var m = _stack.back() * t
	var h = height * 0.5
	var center = m * Vector3.ZERO
	var slope = (radius_bottom - radius_top) / max(height, 0.0001)
	for i in range(sides):
		var a0 = TAU * float(i) / sides
		var a1 = TAU * float(i + 1) / sides
		var d0 = Vector3(cos(a0), 0, sin(a0))
		var d1 = Vector3(cos(a1), 0, sin(a1))
		var p0 = d0 * radius_bottom + Vector3(0, -h, 0)
		var p1 = d1 * radius_bottom + Vector3(0, -h, 0)
		var p2 = d1 * radius_top + Vector3(0, h, 0)
		var p3 = d0 * radius_top + Vector3(0, h, 0)
		var n0 = (d0 + Vector3(0, slope, 0)).normalized()
		var n1 = (d1 + Vector3(0, slope, 0)).normalized()
		if not smooth:
			var mid = (d0 + d1).normalized()
			n0 = (mid + Vector3(0, slope, 0)).normalized()
			n1 = n0
		_emit_tri(m, [p0, p1, p2], [n0, n1, n1], color, center)
		_emit_tri(m, [p0, p2, p3], [n0, n1, n0], color, center)
		if caps:
			_emit_tri(
				m, [Vector3(0, h, 0), p3, p2], [Vector3.UP, Vector3.UP, Vector3.UP], color, center
			)
			_emit_tri(
				m,
				[Vector3(0, -h, 0), p0, p1],
				[Vector3.DOWN, Vector3.DOWN, Vector3.DOWN],
				color,
				center
			)


## Dome (upper half of a sphere, or full sphere) centered at the origin of t, smooth shaded.
func dome(t, radius, color, rings = 3, segments = 8, full_sphere = false):
	var m = _stack.back() * t
	var center = m * Vector3.ZERO
	var start_ring = -rings if full_sphere else 0
	for r in range(start_ring, rings):
		var phi0 = PI * 0.5 * float(r) / rings
		var phi1 = PI * 0.5 * float(r + 1) / rings
		for i in range(segments):
			var a0 = TAU * float(i) / segments
			var a1 = TAU * float(i + 1) / segments
			var v = [
				_sphere_point(a0, phi0),
				_sphere_point(a1, phi0),
				_sphere_point(a1, phi1),
				_sphere_point(a0, phi1),
			]
			var p = v.map(func(n): return n * radius)
			_emit_tri(m, [p[0], p[1], p[2]], [v[0], v[1], v[2]], color, center)
			_emit_tri(m, [p[0], p[2], p[3]], [v[0], v[2], v[3]], color, center)
	if not full_sphere:
		for i in range(segments):
			var a0 = TAU * float(i) / segments
			var a1 = TAU * float(i + 1) / segments
			_emit_tri(
				m,
				[Vector3.ZERO, _sphere_point(a0, 0) * radius, _sphere_point(a1, 0) * radius],
				[Vector3.DOWN, Vector3.DOWN, Vector3.DOWN],
				color,
				center + m.basis * Vector3.UP * radius
			)


## Wheel lying along the X axis (vehicle side), centered at pos.
func wheel(pos, radius, width, tire_color, hub_color, sides = 8):
	cylinder(xf(pos, Vector3(0, 0, 90)), radius, radius, width, tire_color, sides)
	var side = sign(pos.x) if pos.x != 0.0 else 1.0
	cylinder(
		xf(pos + Vector3(side * width * 0.5, 0, 0), Vector3(0, 0, 90)),
		radius * 0.55,
		radius * 0.55,
		0.02,
		hub_color,
		6,
		false
	)


func build(base_material, team_material):
	var mesh = ArrayMesh.new()
	if not _regular.is_empty():
		_commit(mesh, _regular, base_material)
	if not _team.is_empty():
		_commit(mesh, _team, team_material)
	return mesh


func _commit(mesh, verts, material):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in verts:
		st.set_color(v[2])
		st.set_normal(v[1])
		st.add_vertex(v[0])
	st.commit(mesh)
	mesh.surface_set_material(mesh.get_surface_count() - 1, material)


func _sphere_point(azimuth, elevation):
	return Vector3(cos(azimuth) * cos(elevation), sin(elevation), sin(azimuth) * cos(elevation))


func _add_convex_faces(t, faces, color):
	var m = _stack.back() * t
	var center = Vector3.ZERO
	var count = 0
	for face in faces:
		for p in face:
			center += p
			count += 1
	center = m * (center / count)
	for face in faces:
		var n = _face_normal(m, face)
		if n == Vector3.ZERO:
			continue  # degenerate (e.g. a top that collapsed to a line)
		var local_normal = n
		_emit_tri(m, [face[0], face[1], face[2]], [], color, center, local_normal)
		_emit_tri(m, [face[0], face[2], face[3]], [], color, center, local_normal)


func _face_normal(m, face):
	var a = m * face[0]
	var b = m * face[1]
	var c = m * face[2]
	var d = m * face[3]
	var n = (b - a).cross(c - a) + (c - a).cross(d - a)
	if n.length_squared() < 1e-12:
		return Vector3.ZERO
	return n.normalized()


## Emits one triangle in world (model) space. Winding and normals are fixed up so the face
## points away from `center` (all solids here are convex), whatever order the caller used.
func _emit_tri(m, pts, normals, color, center, flat_normal = null):
	var a = m * pts[0]
	var b = m * pts[1]
	var c = m * pts[2]
	var face_n = (b - a).cross(c - a)
	if face_n.length_squared() < 1e-14:
		return
	face_n = face_n.normalized()
	var outward = ((a + b + c) / 3.0 - center).dot(face_n) >= 0.0
	var ns = []
	if flat_normal != null or normals.is_empty():
		var fn = face_n if outward else -face_n
		ns = [fn, fn, fn]
	else:
		var nb = m.basis.inverse().transposed()
		ns = normals.map(func(n): return (nb * n).normalized())
	var target = _team if color == TEAM else _regular
	var col = Color.WHITE if color == TEAM else color
	# Godot treats clockwise triangles (seen from the front) as front faces.
	if outward:
		target.append_array([[a, ns[0], col], [c, ns[2], col], [b, ns[1], col]])
	else:
		target.append_array([[a, ns[0], col], [b, ns[1], col], [c, ns[2], col]])
