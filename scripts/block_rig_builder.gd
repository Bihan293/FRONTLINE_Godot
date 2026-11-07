extends RefCounted

static var _normal_mesh_cache: Dictionary = {}
static var _merged_material: StandardMaterial3D
static var _detail_texture: Texture2D

const BONE_SPECS := [
	["Root", "", Vector3.ZERO],
	["Hips", "Root", Vector3(0.0, 0.875, 0.0)],
	["Spine", "Hips", Vector3(0.0, 0.245, 0.0)],
	["Chest", "Spine", Vector3(0.0, 0.20, 0.0)],
	["Neck", "Chest", Vector3(0.0, 0.245, 0.0)],
	["Head", "Neck", Vector3(0.0, 0.12, 0.0)],
	["LeftShoulder", "Chest", Vector3(-0.305, 0.15, 0.0)],
	["LeftUpperArm", "LeftShoulder", Vector3(0.0, 0.0, 0.0)],
	["LeftLowerArm", "LeftUpperArm", Vector3(0.0, -0.33, 0.0)],
	["LeftHand", "LeftLowerArm", Vector3(0.0, -0.26, 0.0)],
	["RightShoulder", "Chest", Vector3(0.305, 0.15, 0.0)],
	["RightUpperArm", "RightShoulder", Vector3(0.0, 0.0, 0.0)],
	["RightLowerArm", "RightUpperArm", Vector3(0.0, -0.33, 0.0)],
	["RightHand", "RightLowerArm", Vector3(0.0, -0.26, 0.0)],
	["LeftUpperLeg", "Hips", Vector3(-0.115, 0.0, 0.0)],
	["LeftLowerLeg", "LeftUpperLeg", Vector3(0.0, -0.355, 0.0)],
	["LeftFoot", "LeftLowerLeg", Vector3(0.0, -0.39, 0.0)],
	["RightUpperLeg", "Hips", Vector3(0.115, 0.0, 0.0)],
	["RightLowerLeg", "RightUpperLeg", Vector3(0.0, -0.355, 0.0)],
	["RightFoot", "RightLowerLeg", Vector3(0.0, -0.39, 0.0)],
]

static func rig_model(model_root: Node, arms_only: bool = false) -> Skeleton3D:
	var parts: Array[MeshInstance3D] = []
	for child in model_root.find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			parts.append(child)
	_ensure_normals(parts)

	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	model_root.add_child(skeleton)
	var bone_indices: Dictionary = {}
	var rest_global: Dictionary = {}
	for spec in BONE_SPECS:
		var bone_name: String = spec[0]
		var parent_name: String = spec[1]
		var rest_position: Vector3 = spec[2]
		if arms_only and bone_name == "LeftShoulder":
			# Сводим левую кисть к цевью, не меняя исходные солдатские модели.
			rest_position.x += 0.42
		var index := skeleton.get_bone_count()
		skeleton.add_bone(bone_name)
		bone_indices[bone_name] = index
		if not parent_name.is_empty():
			skeleton.set_bone_parent(index, bone_indices[parent_name])
		var rest := Transform3D(Basis.IDENTITY, rest_position)
		skeleton.set_bone_rest(index, rest)
		# Newly created bones start with an identity pose unless initialized.
		# Match the pose to rest so BoneAttachment3D parts assemble as a soldier.
		skeleton.set_bone_pose_position(index, rest_position)
		skeleton.set_bone_pose_rotation(index, Quaternion.IDENTITY)
		skeleton.set_bone_pose_scale(index, Vector3.ONE)
		rest_global[bone_name] = rest if parent_name.is_empty() else rest_global[parent_name] * rest

	var attachments: Dictionary = {}
	for spec in BONE_SPECS:
		var bone_name: String = spec[0]
		var attachment := BoneAttachment3D.new()
		attachment.name = "Attach_" + bone_name
		skeleton.add_child(attachment)
		attachment.bone_name = bone_name
		attachments[bone_name] = attachment

	for part in parts:
		var bone_name := _part_bone(part.name)
		var is_arm := bone_name in [
			"LeftUpperArm", "LeftLowerArm", "LeftHand",
			"RightUpperArm", "RightLowerArm", "RightHand"
		]
		if bone_name.is_empty() or (arms_only and not is_arm):
			part.get_parent().remove_child(part)
			part.queue_free()
			continue

		var model_transform := _transform_to_root(part, model_root)
		if arms_only and bone_name.begins_with("Left"):
			model_transform.origin.x += 0.42
		part.get_parent().remove_child(part)
		var bone_rest: Transform3D = rest_global[bone_name]
		part.transform = bone_rest.affine_inverse() * model_transform
		var attachment: BoneAttachment3D = attachments[bone_name]
		attachment.add_child(part)
	return skeleton

## Собирает все части скелета (включая шлем и бронежилет) в один skinned-меш.
## Это даёт 1 draw call на солдата вместо ~20 и сильно снижает нагрузку на мобилках.
static func merge_rigged_model(skeleton: Skeleton3D, excluded_bones: Array = []) -> MeshInstance3D:
	var bone_count := skeleton.get_bone_count()
	var rest_global: Array[Transform3D] = []
	rest_global.resize(bone_count)
	for i in range(bone_count):
		var xf := skeleton.get_bone_rest(i)
		var parent := skeleton.get_bone_parent(i)
		if parent >= 0:
			xf = rest_global[parent] * xf
		rest_global[i] = xf

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var bone_ids := PackedInt32Array()
	var weights := PackedFloat32Array()

	for child in skeleton.get_children():
		if not (child is BoneAttachment3D):
			continue
		var attachment := child as BoneAttachment3D
		var bone_idx := skeleton.find_bone(attachment.bone_name)
		if bone_idx < 0 or attachment.bone_name in excluded_bones:
			continue
		for node in attachment.get_children():
			if not (node is MeshInstance3D):
				continue
			var part := node as MeshInstance3D
			var mesh := part.mesh
			if mesh == null:
				continue
			var part_xf: Transform3D = rest_global[bone_idx] * part.transform
			for surf in range(mesh.get_surface_count()):
				var arrays := mesh.surface_get_arrays(surf)
				var v = arrays[Mesh.ARRAY_VERTEX]
				if v == null or v.is_empty():
					continue
				var n = arrays[Mesh.ARRAY_NORMAL]
				var c = arrays[Mesh.ARRAY_COLOR]
				if n == null or n.size() != v.size():
					# Часть без нормалей — пересобираем через SurfaceTool.
					var st := SurfaceTool.new()
					st.create_from(mesh, surf)
					st.deindex()
					st.generate_normals()
					var tmp := st.commit()
					if tmp == null or tmp.get_surface_count() == 0:
						continue
					var fixed_arrays := tmp.surface_get_arrays(0)
					v = fixed_arrays[Mesh.ARRAY_VERTEX]
					n = fixed_arrays[Mesh.ARRAY_NORMAL]
					c = fixed_arrays[Mesh.ARRAY_COLOR]
				var base_color := Color(0.6, 0.6, 0.6)
				var mat = mesh.surface_get_material(surf)
				if mat is StandardMaterial3D:
					base_color = (mat as StandardMaterial3D).albedo_color
				for vi in range(v.size()):
					verts.append(part_xf * v[vi])
					var nv: Vector3 = n[vi]
					normals.append((part_xf.basis * nv).normalized())
					if c != null and c.size() == v.size():
						colors.append(c[vi])
					else:
						colors.append(base_color)
					bone_ids.append(bone_idx)
					bone_ids.append(0)
					bone_ids.append(0)
					bone_ids.append(0)
					weights.append(1.0)
					weights.append(0.0)
					weights.append(0.0)
					weights.append(0.0)

	if verts.is_empty():
		return null

	var merged := ArrayMesh.new()
	var mesh_arrays := []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = verts
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_COLOR] = colors
	mesh_arrays[Mesh.ARRAY_BONES] = bone_ids
	mesh_arrays[Mesh.ARRAY_WEIGHTS] = weights
	merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	merged.surface_set_material(0, _get_merged_material())

	var skin := Skin.new()
	skin.set_bind_count(bone_count)
	for i in range(bone_count):
		skin.set_bind_pose(i, rest_global[i].affine_inverse())
		skin.set_bind_name(i, skeleton.get_bone_name(i))

	var inst := MeshInstance3D.new()
	inst.name = "MergedSoldier"
	inst.mesh = merged
	inst.skin = skin
	inst.skeleton = NodePath("..")
	skeleton.add_child(inst)

	for child in skeleton.get_children():
		if child is BoneAttachment3D:
			skeleton.remove_child(child)
			child.queue_free()
	return inst

static func _get_merged_material() -> StandardMaterial3D:
	if _merged_material != null:
		return _merged_material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.95
	if _detail_texture == null:
		_detail_texture = _make_detail_texture()
	mat.albedo_texture = _detail_texture
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(1.7, 1.7, 1.7)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_merged_material = mat
	return mat

static func _make_detail_texture() -> Texture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.06
	noise.fractal_octaves = 4
	noise.fractal_gain = 0.55
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.generate_mipmaps = true
	tex.noise = noise
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	ramp.colors = PackedColorArray([
		Color(0.84, 0.84, 0.84), Color(0.94, 0.94, 0.94), Color(1, 1, 1)])
	tex.color_ramp = ramp
	return tex

static func _ensure_normals(parts: Array[MeshInstance3D]) -> void:
	for part in parts:
		var source: Mesh = part.mesh
		if source == null or source.get_surface_count() == 0:
			continue
		var arrays: Array = source.surface_get_arrays(0)
		var has_colors: bool = arrays[Mesh.ARRAY_COLOR] != null
		var has_normals := (int(source.surface_get_format(0)) & Mesh.ARRAY_FORMAT_NORMAL) != 0
		if has_normals and not has_colors:
			continue
		var source_id := source.get_instance_id()
		if _normal_mesh_cache.has(source_id):
			part.mesh = _normal_mesh_cache[source_id]
			continue
		var fixed: ArrayMesh
		if has_normals:
			fixed = source.duplicate() as ArrayMesh
		else:
			var surface := SurfaceTool.new()
			surface.create_from(source, 0)
			surface.deindex()
			surface.generate_normals()
			fixed = surface.commit()
		if fixed == null or fixed.get_surface_count() == 0:
			continue
		var source_material = source.surface_get_material(0)
		if has_colors:
			var color_material := StandardMaterial3D.new()
			if source_material is StandardMaterial3D:
				color_material = source_material.duplicate() as StandardMaterial3D
			color_material.albedo_color = Color.WHITE
			color_material.vertex_color_use_as_albedo = true
			fixed.surface_set_material(0, color_material)
		else:
			fixed.surface_set_material(0, source_material)
		_normal_mesh_cache[source_id] = fixed
		part.mesh = fixed

static func _part_bone(part_name: String) -> String:
	if part_name.find("Helmet") >= 0:
		return "Head"
	if part_name.find("Body_Armor") >= 0:
		return "Chest"
	match part_name:
		"Pelvis_Torso_Block": return "Hips"
		"Chest_Torso_Block": return "Chest"
		"Neck_Block": return "Neck"
		"Square_Head": return "Head"
		"L_Thigh": return "LeftUpperLeg"
		"L_LowerLeg": return "LeftLowerLeg"
		"L_Boot": return "LeftFoot"
		"L_UpperArm": return "LeftUpperArm"
		"L_Forearm": return "LeftLowerArm"
		"L_Hand": return "LeftHand"
		"R_Thigh": return "RightUpperLeg"
		"R_LowerLeg": return "RightLowerLeg"
		"R_Boot": return "RightFoot"
		"R_UpperArm": return "RightUpperArm"
		"R_Forearm": return "RightLowerArm"
		"R_Hand": return "RightHand"
	return ""

static func _transform_to_root(node: Node3D, root: Node) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent != null and parent != root:
		if parent is Node3D:
			result = (parent as Node3D).transform * result
		parent = parent.get_parent()
	return result
