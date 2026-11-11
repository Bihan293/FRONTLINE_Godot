extends Node3D
class_name FRONTLINEPlayerViewArms

## Первое лицо: руки от плеч к кистям на оружии.
## Компонент владеет кистевыми маркерами, IK-цепочкой плечо/локоть/кисть
## и анимацией перезарядки. Не знает про стрельбу и патроны.

const UPPER_ARM_LENGTH := 0.34
const LOWER_ARM_LENGTH := 0.31

var left_arm: Node3D
var right_arm: Node3D
var wrist_left: Node3D
var wrist_right: Node3D
var left_pivot: Node3D
var left_base := Vector3.ZERO

var _manual_pose := false
var _manual_left := Transform3D.IDENTITY
var _manual_right := Transform3D.IDENTITY
var _manual_left_visible := true
var _manual_right_visible := true

var _camera: Camera3D
var _weapon_root: Node3D

func setup(camera: Camera3D, weapon_root: Node3D) -> void:
	_camera = camera
	_weapon_root = weapon_root
	wrist_right = Node3D.new()
	wrist_right.name = "WristR"
	wrist_right.position = Vector3(0.0, -0.055, 0.02)
	_weapon_root.add_child(wrist_right)

	left_pivot = Node3D.new()
	left_pivot.name = "LeftArm"
	left_pivot.position = Vector3(0.0, 0.0, -0.14)
	left_base = left_pivot.position
	_weapon_root.add_child(left_pivot)

	wrist_left = Node3D.new()
	wrist_left.name = "WristL"
	wrist_left.position = Vector3(0.0, -0.055, 0.02)
	left_pivot.add_child(wrist_left)

	left_arm = _make_arm("ViewArmL", true)
	right_arm = _make_arm("ViewArmR", false)

## Ручная поза в пространстве камеры: граната, бинт, добивание.
func set_manual_pose(left_xf: Transform3D, right_xf: Transform3D, show_left := true, show_right := true) -> void:
	_manual_pose = true
	_manual_left = left_xf
	_manual_right = right_xf
	_manual_left_visible = show_left
	_manual_right_visible = show_right

func clear_manual_pose() -> void:
	_manual_pose = false
	_manual_left_visible = true
	_manual_right_visible = true

func has_manual_pose() -> bool:
	return _manual_pose

func set_hand_offsets(left_offset: Vector3, right_offset: Vector3) -> void:
	left_base = left_offset
	left_pivot.position = left_offset
	wrist_right.position = right_offset
	set_reload_progress(0.0)

func set_reload_progress(progress: float) -> void:
	if left_pivot == null:
		return
	var offset := Vector3(0.0, -0.10 * sin(progress * PI), 0.06 * sin(progress * PI))
	left_pivot.position = left_base + offset

func update(visible: bool) -> void:
	if _camera == null or left_arm == null or right_arm == null:
		return
	if not visible:
		left_arm.visible = false
		right_arm.visible = false
		return
	var cam_xf := _camera.global_transform
	var l_shoulder: Vector3 = cam_xf * Vector3(-0.34, -0.38, -0.10)
	var l_pole: Vector3 = cam_xf.basis * Vector3(-0.75, -0.85, 0.08)
	var r_shoulder: Vector3 = cam_xf * Vector3(0.34, -0.38, -0.10)
	var r_pole: Vector3 = cam_xf.basis * Vector3(0.75, -0.85, 0.08)
	if _manual_pose:
		if _manual_left_visible:
			_place_hand(left_arm, cam_xf * _manual_left, true, l_shoulder, l_pole)
		else:
			left_arm.visible = false
		if _manual_right_visible:
			_place_hand(right_arm, cam_xf * _manual_right, false, r_shoulder, r_pole)
		else:
			right_arm.visible = false
		return
	if wrist_left != null:
		_place_hand(left_arm, wrist_left.global_transform, true, l_shoulder, l_pole)
	if wrist_right != null:
		_place_hand(right_arm, wrist_right.global_transform, false, r_shoulder, r_pole)

func _make_arm(arm_name: String, is_left: bool) -> Node3D:
	var arm := Node3D.new()
	arm.name = arm_name
	var player_team := MatchState.player_team
	var is_red := player_team.to_upper().contains("RED") or player_team.to_upper().contains("SOVIET")
	var sleeve := StandardMaterial3D.new()
	sleeve.albedo_color = Color(0.24, 0.20, 0.14) if is_red else Color(0.16, 0.18, 0.13)
	sleeve.roughness = 0.95
	var glove := StandardMaterial3D.new()
	glove.albedo_color = Color(0.32, 0.25, 0.18)
	glove.roughness = 0.90

	var upper := MeshInstance3D.new()
	upper.name = "Upper"
	var upper_mesh := CylinderMesh.new()
	upper_mesh.top_radius = 0.045
	upper_mesh.bottom_radius = 0.038
	upper_mesh.height = 1.0
	upper_mesh.radial_segments = 10
	upper.mesh = upper_mesh
	upper.material_override = sleeve
	upper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	upper.visible = true
	arm.add_child(upper)

	var forearm := MeshInstance3D.new()
	forearm.name = "Forearm"
	var forearm_mesh := CylinderMesh.new()
	forearm_mesh.top_radius = 0.036
	forearm_mesh.bottom_radius = 0.028
	forearm_mesh.height = 1.0
	forearm_mesh.radial_segments = 10
	forearm.mesh = forearm_mesh
	forearm.material_override = sleeve
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	forearm.visible = true
	arm.add_child(forearm)

	var palm := MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh := BoxMesh.new()
	palm_mesh.size = Vector3(0.070, 0.040, 0.110)
	palm.mesh = palm_mesh
	palm.material_override = glove
	palm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm.add_child(palm)

	var thumb := MeshInstance3D.new()
	thumb.name = "Thumb"
	var thumb_mesh := BoxMesh.new()
	thumb_mesh.size = Vector3(0.026, 0.028, 0.055)
	thumb.mesh = thumb_mesh
	thumb.material_override = glove
	thumb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm.add_child(thumb)

	var cuff := MeshInstance3D.new()
	cuff.name = "Cuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.026
	cuff_mesh.bottom_radius = 0.030
	cuff_mesh.height = 0.10
	cuff_mesh.radial_segments = 8
	cuff.mesh = cuff_mesh
	cuff.material_override = sleeve
	cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm.add_child(cuff)

	for finger_index in range(4):
		var finger := MeshInstance3D.new()
		finger.name = "Finger%d" % finger_index
		var finger_mesh := BoxMesh.new()
		finger_mesh.size = Vector3(0.018, 0.020, 0.042)
		finger.mesh = finger_mesh
		finger.material_override = glove
		finger.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		finger.set_meta("finger_index", finger_index)
		arm.add_child(finger)
		var tip := MeshInstance3D.new()
		tip.name = "Finger%dTip" % finger_index
		var tip_mesh := BoxMesh.new()
		tip_mesh.size = Vector3(0.017, 0.018, 0.034)
		tip.mesh = tip_mesh
		tip.material_override = glove
		tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tip.set_meta("finger_index", finger_index)
		arm.add_child(tip)

	arm.set_meta("is_left", is_left)
	if _camera != null:
		_camera.add_child(arm)
	return arm

func _place_hand(arm: Node3D, marker_xf: Transform3D, is_left: bool, shoulder: Vector3, pole: Vector3) -> void:
	arm.visible = true
	arm.global_transform = Transform3D(marker_xf.basis.orthonormalized(), marker_xf.origin)

	var wrist := marker_xf.origin
	var elbow := _solve_elbow(shoulder, wrist, pole)
	var upper := arm.get_node_or_null("Upper") as MeshInstance3D
	var forearm := arm.get_node_or_null("Forearm") as MeshInstance3D
	if upper != null:
		_place_segment(upper, shoulder, elbow)
	if forearm != null:
		_place_segment(forearm, elbow, wrist)

	var cuff := arm.get_node_or_null("Cuff") as MeshInstance3D
	if cuff != null:
		cuff.visible = true
		cuff.position = Vector3(0.0, -0.016, 0.085)
		cuff.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	var palm := arm.get_node_or_null("Palm") as MeshInstance3D
	if palm != null:
		palm.visible = true
		palm.position = Vector3(0.0, -0.010, -0.052)
		palm.rotation = Vector3(deg_to_rad(-6.0), deg_to_rad(6.0 if is_left else -6.0), 0.0)
	var thumb := arm.get_node_or_null("Thumb") as MeshInstance3D
	if thumb != null:
		thumb.visible = true
		thumb.position = Vector3(0.052 if is_left else -0.052, 0.008, -0.052)
		thumb.rotation = Vector3(deg_to_rad(20.0), 0.0, deg_to_rad(48.0 if is_left else -48.0))
	var finger_x := -0.030
	for finger_index in range(4):
		var x := finger_x + float(finger_index) * 0.020
		var finger := arm.get_node_or_null("Finger%d" % finger_index) as MeshInstance3D
		if finger != null:
			finger.visible = true
			finger.position = Vector3(x, -0.018, -0.060)
			finger.rotation = Vector3(deg_to_rad(48.0), 0.0, deg_to_rad(4.0 if is_left else -4.0))
		var tip := arm.get_node_or_null("Finger%dTip" % finger_index) as MeshInstance3D
		if tip != null:
			tip.visible = true
			tip.position = Vector3(x, -0.044, -0.090)
			tip.rotation = Vector3(deg_to_rad(108.0), 0.0, deg_to_rad(4.0 if is_left else -4.0))

func _solve_elbow(shoulder: Vector3, wrist: Vector3, pole: Vector3) -> Vector3:
	var delta := wrist - shoulder
	var distance := delta.length()
	if distance < 0.05:
		return shoulder + Vector3.DOWN * 0.1
	var direction := delta / distance
	var max_reach := UPPER_ARM_LENGTH + LOWER_ARM_LENGTH - 0.01
	var reach := clampf(distance, 0.05, max_reach)
	var along := (UPPER_ARM_LENGTH * UPPER_ARM_LENGTH - LOWER_ARM_LENGTH * LOWER_ARM_LENGTH + reach * reach) / (2.0 * reach)
	var height := sqrt(maxf(UPPER_ARM_LENGTH * UPPER_ARM_LENGTH - along * along, 0.0001))
	var bend := pole - direction * pole.dot(direction)
	if bend.length_squared() < 0.001:
		bend = Vector3.DOWN
	return shoulder + direction * along + bend.normalized() * height

func _place_segment(mesh_inst: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var delta := b - a
	var length := delta.length()
	if length < 0.01:
		mesh_inst.visible = false
		return
	mesh_inst.visible = true
	var up := delta / length
	var right := up.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = up.cross(Vector3.RIGHT)
	right = right.normalized()
	var forward := up.cross(right).normalized()
	mesh_inst.global_transform = Transform3D(Basis(right, up * length, forward), (a + b) * 0.5)
