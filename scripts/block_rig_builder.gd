extends RefCounted

static var _normal_mesh_cache: Dictionary = {}

const BONE_SPECS := [
	["Root", "", Vector3.ZERO],
	["Hips", "Root", Vector3(0.0, 0.76, 0.0)],
	["Spine", "Hips", Vector3(0.0, 0.16, 0.0)],
	["Chest", "Spine", Vector3(0.0, 0.36, 0.0)],
	["Neck", "Chest", Vector3(0.0, 0.29, 0.0)],
	["Head", "Neck", Vector3(0.0, 0.18, 0.0)],
	["LeftShoulder", "Chest", Vector3(-0.16, 0.06, 0.0)],
	["LeftUpperArm", "LeftShoulder", Vector3(-0.14, -0.03, 0.0)],
	["LeftLowerArm", "LeftUpperArm", Vector3(0.0, -0.32, 0.0)],
	["LeftHand", "LeftLowerArm", Vector3(0.0, -0.24, 0.0)],
	["RightShoulder", "Chest", Vector3(0.16, 0.06, 0.0)],
	["RightUpperArm", "RightShoulder", Vector3(0.14, -0.03, 0.0)],
	["RightLowerArm", "RightUpperArm", Vector3(0.0, -0.32, 0.0)],
	["RightHand", "RightLowerArm", Vector3(0.0, -0.24, 0.0)],
	["LeftUpperLeg", "Hips", Vector3(-0.10, -0.10, 0.0)],
	["LeftLowerLeg", "LeftUpperLeg", Vector3(0.0, -0.36, 0.0)],
	["LeftFoot", "LeftLowerLeg", Vector3(0.0, -0.25, 0.0)],
	["RightUpperLeg", "Hips", Vector3(0.10, -0.10, 0.0)],
	["RightLowerLeg", "RightUpperLeg", Vector3(0.0, -0.36, 0.0)],
	["RightFoot", "RightLowerLeg", Vector3(0.0, -0.25, 0.0)],
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
