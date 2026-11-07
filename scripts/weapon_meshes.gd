extends RefCounted

## Общие меши оружия. AK-47 из GLB склеивается в один меш с vertex colors:
## 1 draw call на автомат и одинаковый вид у игрока и ботов.

const AK_PATH := "res://assets/models/ak47/ak47_lowpoly.glb"
const MUZZLE_LOCAL := Vector3(0.0, 0.09, 0.501)

static var _ak_mesh: ArrayMesh
static var _ak_material: StandardMaterial3D

static func ak_mesh() -> ArrayMesh:
	if _ak_mesh != null:
		return _ak_mesh
	var packed = load(AK_PATH)
	if packed == null:
		return null
	var root: Node3D = packed.instantiate()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surf in range(mesh.get_surface_count()):
			var arrays := mesh.surface_get_arrays(surf)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var bi = arrays[Mesh.ARRAY_INDEX]
			if v == null:
				continue
			var base := verts.size()
			var color := Color(0.18, 0.18, 0.19)
			var mat = mesh.surface_get_material(surf)
			if mat is StandardMaterial3D:
				color = (mat as StandardMaterial3D).albedo_color
			for i in range(v.size()):
				verts.append(v[i])
				normals.append(n[i] if n != null and n.size() == v.size() else Vector3.UP)
				colors.append(color)
			if bi == null or bi.is_empty():
				for i in range(v.size()):
					indices.append(base + i)
			else:
				for idx in bi:
					indices.append(base + idx)
	root.free()
	if verts.is_empty():
		return null
	# Приводим палитру к более реалистичному оружию: тёмное дерево и сталь.
	for i in range(colors.size()):
		var c := colors[i]
		if c.r > c.b + 0.08 and c.get_luminance() > 0.35:
			colors[i] = Color(0.38, 0.22, 0.10)
		elif c.get_luminance() < 0.35:
			colors[i] = Color(0.13, 0.14, 0.15)
		else:
			colors[i] = Color(0.55, 0.56, 0.58)
	var mesh := ArrayMesh.new()
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_COLOR] = colors
	out[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	mesh.surface_set_material(0, ak_material())
	_ak_mesh = mesh
	return mesh

static func ak_material() -> StandardMaterial3D:
	if _ak_material != null:
		return _ak_material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.58
	mat.metallic = 0.22
	_ak_material = mat
	return mat
