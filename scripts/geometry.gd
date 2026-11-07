@tool
class_name RoomGeo
extends RefCounted
## Cached primitives with physical metre UVs and independent conservative colliders.
## Architecture stays square; bevel_box is an opt-in rounded furniture surface.

static var _mesh_cache: Dictionary = {}

static func box(parent: Node, label: String, pos: Vector3, size: Vector3, mat: Material, collision := false) -> MeshInstance3D:
	return _box_instance(parent, label, pos, size, mat, 0.0, collision)

static func bevel_box(parent: Node, label: String, pos: Vector3, size: Vector3, mat: Material, bevel := .01, collision := false) -> MeshInstance3D:
	var radius := clampf(bevel, 0.0, minf(size.x, minf(size.y, size.z)) * .48)
	return _box_instance(parent, label, pos, size, mat, radius, collision)

static func _box_instance(parent: Node, label: String, pos: Vector3, size: Vector3, mat: Material, bevel: float, collision: bool) -> MeshInstance3D:
	var phase := _uv_phase(mat, pos, label)
	var fit: bool = mat != null and mat.get_meta("uv_mode", "") == "fit"
	var key := "box|" + str(size) + "|" + str(bevel) + "|" + str(phase) + "|" + str(fit)
	if not _mesh_cache.has(key):
		_mesh_cache[key] = _box_geometry(size, bevel, phase, fit)
	var item := _mesh(parent, label, pos, _mesh_cache[key], mat)
	if collision:
		var shape := BoxShape3D.new()
		shape.size = size
		_collider(item, shape)
	return item

static func _uv_phase(mat: Material, pos: Vector3, label: String) -> Vector2:
	if mat == null or not mat.get_meta("uv_variation", false):
		return Vector2.ZERO
	# Eight deterministic cutting offsets prevent every cabinet panel/tile looking
	# identical, while retaining a small reusable mesh cache.
	var variant := posmod(int(label.hash()) + int(round(pos.x * 47 + pos.y * 17 + pos.z * 31)), 8)
	return Vector2(float(variant) * .137, float(variant) * .213)

static func _axis_grid(extent: float, bevel: float) -> PackedFloat32Array:
	if bevel < .00001:
		return PackedFloat32Array([-extent, extent])
	var inner := extent - bevel
	return PackedFloat32Array([-extent, -inner - bevel * .5, -inner, inner, inner + bevel * .5, extent])

static func _box_geometry(size: Vector3, bevel: float, phase: Vector2, fit: bool) -> ArrayMesh:
	var half := size * .5
	var inner := half - Vector3.ONE * bevel
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var tangents := PackedFloat32Array()
	var indices := PackedInt32Array()
	# n, horizontal, vertical: horizontal cross vertical equals outward normal.
	var faces: Array = [
		[Vector3.FORWARD, Vector3.LEFT, Vector3.UP],
		[Vector3.BACK, Vector3.RIGHT, Vector3.UP],
		[Vector3.LEFT, Vector3.BACK, Vector3.UP],
		[Vector3.RIGHT, Vector3.FORWARD, Vector3.UP],
		[Vector3.UP, Vector3.RIGHT, Vector3.FORWARD],
		[Vector3.DOWN, Vector3.RIGHT, Vector3.BACK]
	]
	for face in faces:
		var n: Vector3 = face[0]
		var horizontal: Vector3 = face[1]
		var vertical: Vector3 = face[2]
		var extent_u := half.dot(horizontal.abs())
		var extent_v := half.dot(vertical.abs())
		var extent_n := half.dot(n.abs())
		var grid_u := _axis_grid(extent_u, bevel)
		var grid_v := _axis_grid(extent_v, bevel)
		var start := vertices.size()
		for vv in grid_v:
			for uu in grid_u:
				var point: Vector3 = n * extent_n + horizontal * uu + vertical * vv
				var normal := n
				if bevel > .00001:
					var nearest := point.clamp(-inner, inner)
					normal = (point - nearest).normalized()
					point = nearest + normal * bevel
				vertices.append(point)
				normals.append(normal)
				var tangent := (horizontal - normal * horizontal.dot(normal)).normalized()
				tangents.append_array(PackedFloat32Array([tangent.x, tangent.y, tangent.z, -1.0]))
				var uv := Vector2(point.dot(horizontal), -point.dot(vertical))
				if fit:
					uv = Vector2(uv.x / size.dot(horizontal.abs()) + .5, uv.y / size.dot(vertical.abs()) + .5)
				else:
					uv += phase
				uvs.append(uv)
		for yy in range(grid_v.size() - 1):
			for xx in range(grid_u.size() - 1):
				var a := start + yy * grid_u.size() + xx
				var b := a + 1
				var c := b + grid_u.size()
				var d := a + grid_u.size()
				# Godot front faces use clockwise winding.
				indices.append_array(PackedInt32Array([a, c, b, a, d, c]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func cylinder(parent: Node, label: String, pos: Vector3, radius: float, height: float, mat: Material, collision := false) -> MeshInstance3D:
	var key := "cylinder|" + str(radius) + "|" + str(height)
	if not _mesh_cache.has(key):
		var primitive := CylinderMesh.new()
		primitive.top_radius = radius
		primitive.bottom_radius = radius
		primitive.height = height
		primitive.radial_segments = 32 if radius > .045 else 16
		var arrays := primitive.get_mesh_arrays()
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normal: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for i in points.size():
			if absf(normal[i].y) > .9:
				uv[i] = Vector2(points[i].x, points[i].z)
			else:
				uv[i] = Vector2(uv[i].x * TAU * radius, points[i].y)
		arrays[Mesh.ARRAY_TEX_UV] = uv
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_mesh_cache[key] = mesh
	var item := _mesh(parent, label, pos, _mesh_cache[key], mat)
	if collision:
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		_collider(item, shape)
	return item

static func sphere(parent: Node, label: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var key := "ellipsoid|" + str(size)
	if not _mesh_cache.has(key):
		var primitive := SphereMesh.new()
		primitive.radius = .5
		primitive.height = 1.0
		primitive.radial_segments = 32
		# Odd latitude count gives an equator ring, preserving exact outer bounds.
		primitive.rings = 15
		var arrays := primitive.get_mesh_arrays()
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var safe_size := size.max(Vector3.ONE * .0001)
		var circumference := PI * (size.x + size.z) * .5
		var meridian := PI * (size.y + (size.x + size.z) * .5) * .25
		for i in points.size():
			points[i] *= size
			normals[i] = (normals[i] / safe_size).normalized()
			uv[i] *= Vector2(circumference, meridian)
			if tangents.size() >= i * 4 + 4:
				var tangent := Vector3(tangents[i * 4], tangents[i * 4 + 1], tangents[i * 4 + 2]) * size
				tangent = (tangent - normals[i] * tangent.dot(normals[i])).normalized()
				tangents[i * 4] = tangent.x
				tangents[i * 4 + 1] = tangent.y
				tangents[i * 4 + 2] = tangent.z
		arrays[Mesh.ARRAY_VERTEX] = points
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TANGENT] = tangents
		arrays[Mesh.ARRAY_TEX_UV] = uv
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_mesh_cache[key] = mesh
	return _mesh(parent, label, pos, _mesh_cache[key], mat)

static func rod(parent: Node, label: String, start: Vector3, end: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var item := cylinder(parent, label, (start + end) * .5, radius, maxf(start.distance_to(end), .0001), mat)
	item.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	return item

static func torus(parent: Node, label: String, pos: Vector3, inner_radius: float, outer_radius: float, mat: Material) -> MeshInstance3D:
	var key := "torus|" + str(inner_radius) + "|" + str(outer_radius)
	if not _mesh_cache.has(key):
		var primitive := TorusMesh.new()
		primitive.inner_radius = inner_radius
		primitive.outer_radius = outer_radius
		primitive.rings = 32
		primitive.ring_segments = 10
		var arrays := primitive.get_mesh_arrays()
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var metric := Vector2(PI * (outer_radius + inner_radius), PI * (outer_radius - inner_radius))
		for i in uv.size():
			uv[i] *= metric
		arrays[Mesh.ARRAY_TEX_UV] = uv
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_mesh_cache[key] = mesh
	return _mesh(parent, label, pos, _mesh_cache[key], mat)

static func collider(parent: Node, label: String, pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var child := CollisionShape3D.new()
	child.shape = shape
	body.add_child(child)
	return body

static func _mesh(parent: Node, label: String, pos: Vector3, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = label
	item.position = pos
	item.mesh = mesh
	item.material_override = mat
	parent.add_child(item)
	return item

static func _collider(parent: Node3D, shape: Shape3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var child := CollisionShape3D.new()
	child.shape = shape
	body.add_child(child)
