extends RefCounted

## Общие меши оружия. AK-47 из GLB склеивается в один меш с vertex colors:
## 1 draw call на автомат и одинаковый вид у игрока и ботов.

const AK_PATH := "res://assets/models/ak47/ak47_lowpoly.glb"
const MUZZLE_LOCAL := Vector3(0.0, 0.09, 0.501)

static var _ak_mesh: ArrayMesh
static var _ak_material: StandardMaterial3D
static var _weapon_materials: Dictionary = {}

## Builds a first-person model with its muzzle marker. AK-47 uses the imported GLB;
## the remaining weapons use compact low-poly parts so they need no extra assets.
static func make_weapon(weapon_id: String) -> Node3D:
	var root := Node3D.new()
	root.name = weapon_id.to_upper()
	if weapon_id == "ak47":
		root.rotation.y = PI
		var imported := ak_mesh()
		if imported != null:
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.name = "AK47Mesh"
			mesh_instance.mesh = imported
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mesh_instance)
			var imported_muzzle := Node3D.new()
			imported_muzzle.name = "Muzzle"
			imported_muzzle.position = MUZZLE_LOCAL
			root.add_child(imported_muzzle)
			return root
		root.free()
		return null

	var dark := _weapon_material("dark", Color(0.105, 0.12, 0.125), 0.58, 0.32)
	var steel := _weapon_material("steel", Color(0.28, 0.31, 0.32), 0.48, 0.62)
	var wood := _weapon_material("wood", Color(0.32, 0.20, 0.105), 0.78, 0.0)
	var muzzle_z := -0.58
	match weapon_id:
		"mp40":
			_add_box(root, "Receiver", Vector3(0.0, 0.015, -0.08), Vector3(0.17, 0.17, 0.34), dark)
			_add_cylinder(root, "Barrel", Vector3(0.0, 0.045, -0.38), 0.032, 0.48, steel)
			_add_box(root, "Stock", Vector3(0.0, -0.015, 0.26), Vector3(0.10, 0.09, 0.28), steel)
			_add_box(root, "Magazine", Vector3(0.0, -0.17, -0.015), Vector3(0.085, 0.25, 0.09), steel)
			_add_box(root, "Grip", Vector3(0.0, -0.14, 0.10), Vector3(0.075, 0.18, 0.10), dark)
			muzzle_z = -0.64
		"mosin":
			_add_box(root, "WoodStock", Vector3(0.0, -0.015, 0.055), Vector3(0.14, 0.16, 0.73), wood)
			_add_box(root, "Receiver", Vector3(0.0, 0.055, -0.17), Vector3(0.105, 0.10, 0.24), steel)
			_add_cylinder(root, "Barrel", Vector3(0.0, 0.07, -0.48), 0.022, 0.62, steel)
			_add_box(root, "Bolt", Vector3(0.075, 0.12, -0.15), Vector3(0.10, 0.035, 0.12), dark)
			_add_box(root, "Sight", Vector3(0.0, 0.13, -0.30), Vector3(0.035, 0.09, 0.04), dark)
			muzzle_z = -0.80
		"m1911":
			_add_box(root, "Slide", Vector3(0.0, 0.04, -0.10), Vector3(0.105, 0.105, 0.31), steel)
			_add_cylinder(root, "Barrel", Vector3(0.0, 0.05, -0.30), 0.021, 0.20, dark)
			_add_box(root, "Grip", Vector3(0.0, -0.105, 0.065), Vector3(0.09, 0.20, 0.12), wood)
			_add_box(root, "TriggerGuard", Vector3(0.0, -0.055, -0.005), Vector3(0.11, 0.055, 0.10), dark)
			muzzle_z = -0.43
		"shotgun":
			_add_box(root, "WoodStock", Vector3(0.0, -0.02, 0.17), Vector3(0.14, 0.16, 0.42), wood)
			_add_box(root, "Receiver", Vector3(0.0, 0.02, -0.12), Vector3(0.16, 0.15, 0.29), steel)
			_add_cylinder(root, "Barrel", Vector3(0.0, 0.065, -0.42), 0.035, 0.48, steel)
			_add_cylinder(root, "MagazineTube", Vector3(0.0, -0.055, -0.40), 0.027, 0.43, dark)
			_add_box(root, "Foregrip", Vector3(0.0, -0.06, -0.31), Vector3(0.12, 0.10, 0.20), wood)
			muzzle_z = -0.69
		"ppsh41":
			_add_box(root, "WoodStock", Vector3(0.0, -0.02, 0.16), Vector3(0.12, 0.15, 0.44), wood)
			_add_box(root, "Receiver", Vector3(0.0, 0.04, -0.10), Vector3(0.13, 0.13, 0.28), dark)
			_add_cylinder(root, "ShroudBarrel", Vector3(0.0, 0.05, -0.40), 0.038, 0.44, steel)
			_add_cylinder_ex(root, "DrumMag", Vector3(0.0, -0.12, -0.07), 0.11, 0.11, 0.075, dark, Vector3(0.0, 0.0, PI * 0.5))
			_add_box(root, "MuzzleBrake", Vector3(0.0, 0.05, -0.63), Vector3(0.045, 0.05, 0.06), steel)
			muzzle_z = -0.66
		"kar98k":
			_add_box(root, "WoodStock", Vector3(0.0, -0.015, 0.06), Vector3(0.13, 0.15, 0.76), wood)
			_add_box(root, "Receiver", Vector3(0.0, 0.055, -0.17), Vector3(0.105, 0.10, 0.24), steel)
			_add_cylinder(root, "Barrel", Vector3(0.0, 0.07, -0.50), 0.022, 0.65, steel)
			_add_box(root, "Bolt", Vector3(0.07, 0.08, -0.13), Vector3(0.09, 0.035, 0.08), dark)
			_add_cylinder(root, "Scope", Vector3(0.0, 0.135, -0.18), 0.026, 0.28, dark)
			_add_box(root, "ScopeRingFront", Vector3(0.0, 0.095, -0.26), Vector3(0.045, 0.06, 0.03), steel)
			_add_box(root, "ScopeRingRear", Vector3(0.0, 0.095, -0.10), Vector3(0.045, 0.06, 0.03), steel)
			muzzle_z = -0.84
		"panzerfaust":
			var olive := _weapon_material("olive", Color(0.30, 0.35, 0.22), 0.68, 0.18)
			_add_cylinder(root, "Tube", Vector3(0.0, 0.0, -0.12), 0.042, 0.82, olive)
			_add_cylinder(root, "WarheadStem", Vector3(0.0, 0.0, -0.56), 0.032, 0.12, dark)
			_add_cylinder_ex(root, "WarheadHead", Vector3(0.0, 0.0, -0.68), 0.02, 0.095, 0.18, olive)
			_add_box(root, "SightLeaf", Vector3(0.0, 0.075, -0.36), Vector3(0.02, 0.09, 0.02), dark)
			_add_box(root, "TriggerBox", Vector3(0.0, 0.06, -0.16), Vector3(0.035, 0.05, 0.12), dark)
			muzzle_z = -0.78
		"drone_controller":
			# Handheld FPV terminal with screen and dual joysticks
			_add_box(root, "ConsoleBody", Vector3(0.0, -0.05, -0.22), Vector3(0.28, 0.05, 0.18), dark)
			_add_box(root, "Screen", Vector3(0.0, -0.02, -0.23), Vector3(0.18, 0.015, 0.11), _weapon_material("screen", Color(0.15, 0.65, 0.25), 0.2, 0.0))
			_add_cylinder(root, "AntennaL", Vector3(-0.11, 0.04, -0.29), 0.008, 0.14, steel)
			_add_cylinder(root, "AntennaR", Vector3(0.11, 0.04, -0.29), 0.008, 0.14, steel)
			_add_cylinder(root, "StickL", Vector3(-0.09, -0.01, -0.16), 0.012, 0.035, dark)
			_add_cylinder(root, "StickR", Vector3(0.09, -0.01, -0.16), 0.012, 0.035, dark)
			muzzle_z = -0.32
		_:
			root.free()
			return null
	var muzzle := Node3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0.0, 0.05, muzzle_z)
	root.add_child(muzzle)
	return root

static func _weapon_material(key: String, color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	if _weapon_materials.has(key):
		return _weapon_materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	_weapon_materials[key] = mat
	return mat

static func _add_box(parent: Node3D, node_name: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)

static func _add_cylinder(parent: Node3D, node_name: String, pos: Vector3, radius: float, length: float, material: Material) -> void:
	_add_cylinder_ex(parent, node_name, pos, radius, radius, length, material, Vector3(PI * 0.5, 0.0, 0.0))

static func _add_cylinder_ex(parent: Node3D, node_name: String, pos: Vector3, radius_top: float, radius_bottom: float, length: float, material: Material, rot: Vector3 = Vector3(PI * 0.5, 0.0, 0.0)) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_top
	mesh.bottom_radius = radius_bottom
	mesh.height = length
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	mesh_instance.rotation = rot
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)

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
