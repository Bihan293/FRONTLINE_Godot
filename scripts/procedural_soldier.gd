extends Node3D
class_name FRONTLINEProceduralSoldier

## Attach this script to the imported character root. Set skeleton_path to the
## Skeleton3D node created by Godot's GLB importer.
@export var skeleton_path: NodePath = NodePath("Skeleton3D")
@export_range(2.0, 18.0, 0.1) var smoothing: float = 10.0
@export_range(0.5, 3.0, 0.05) var walk_cycle_rate: float = 1.0

var _skeleton: Skeleton3D
var _bone_ids: Dictionary = {}
var _hips_id: int = -1
var _hips_rest := Vector3.ZERO
var _hip_drop := 0.0
var _phase: float = 0.0
var _idle_time: float = 0.0
var _speed: float = 0.0
var _move_amount: float = 0.0
var _run_amount: float = 0.0
var _aim_amount: float = 0.0
var _crouch_amount: float = 0.0
var _sit_amount: float = 0.0
var _fire_amount: float = 0.0
var _reload_amount: float = 0.0
var _flinch_amount: float = 0.0
var _flinch_side: float = 1.0
var _aim_forward_sign: float = -1.0
var _look_yaw: float = 0.0
var _look_pitch: float = 0.0
var _t_pose_arms := false
var _prone := false
var _hide_head := false
var _pose: Dictionary = {}

# Рэгдолл-система
var _is_ragdoll := false
var _ragdoll_timer := 0.0
var _ragdoll_fall := 0.0
var _ragdoll_dir := Vector3.ZERO
var _ragdoll_headshot := false
var _ragdoll_side := 1.0
var _ragdoll_settled := false
var _ragdoll_physics: PhysicalBoneSimulator3D
var _ragdoll_physics_bones: Dictionary = {}
var _ragdoll_physics_pending := false
var _ragdoll_physics_active := false
var _ragdoll_physics_time := 0.0
var _ragdoll_started_msec := 0

const RAGDOLL_PHYSICS_TIME := 2.6
const RAGDOLL_WORLD_LAYER := 1
const MAX_ACTIVE_RAGDOLLS := 8

func _ready() -> void:
	_skeleton = _find_skeleton()
	if _skeleton == null:
		push_error("FRONTLINE: Skeleton3D not found. Check skeleton_path on the character root.")
		set_process(false)
		return
	var names := [
		"Hips", "Spine", "Chest", "Neck", "Head",
		"LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand",
		"RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
		"RightUpperLeg", "RightLowerLeg", "RightFoot"
	]
	for bone_name in names:
		var id := _skeleton.find_bone(bone_name)
		if id >= 0:
			_bone_ids[bone_name] = id
			_pose[bone_name] = Quaternion.IDENTITY
		else:
			push_warning("FRONTLINE: missing rig bone: " + bone_name)
	for i in range(_skeleton.get_bone_count()):
		_skeleton.set_bone_pose_position(i, _skeleton.get_bone_rest(i).origin)
		_skeleton.set_bone_pose_rotation(i, Quaternion.IDENTITY)
		_skeleton.set_bone_pose_scale(i, Vector3.ONE)
	if _bone_ids.has("Hips"):
		_hips_id = _bone_ids["Hips"]
		_hips_rest = _skeleton.get_bone_rest(_hips_id).origin
	_apply_hidden_bones()

func _apply_hidden_bones() -> void:
	if _skeleton == null:
		return
	var tiny := Vector3.ONE * 0.001
	if _hide_head:
		for bone_name in ["Head", "Neck"]:
			if _bone_ids.has(bone_name):
				_skeleton.set_bone_pose_scale(_bone_ids[bone_name], tiny)

func _find_skeleton() -> Skeleton3D:
	var direct := get_node_or_null(skeleton_path)
	if direct is Skeleton3D:
		return direct
	for node in find_children("*", "Skeleton3D", true, false):
		if node is Skeleton3D:
			return node
	return null

func set_motion(speed: float, running: bool = false) -> void:
	_speed = maxf(speed, 0.0)
	_move_amount = clampf(_speed / 2.8, 0.0, 1.0)
	_run_amount = 1.0 if running else 0.0

func set_look(yaw: float, pitch: float) -> void:
	_look_yaw = clampf(yaw, deg_to_rad(-75.0), deg_to_rad(75.0))
	_look_pitch = clampf(pitch, deg_to_rad(-45.0), deg_to_rad(45.0))

func set_aiming(enabled: bool) -> void:
	_aim_amount = 1.0 if enabled else 0.0

func set_aim_forward_sign(value: float) -> void:
	_aim_forward_sign = -1.0 if value < 0.0 else 1.0

func set_crouching(enabled: bool) -> void:
	_crouch_amount = 1.0 if enabled else 0.0

func set_sitting(enabled: bool) -> void:
	_sit_amount = 1.0 if enabled else 0.0

func set_firing(enabled: bool) -> void:
	_fire_amount = 1.0 if enabled else 0.0

func set_reloading(enabled: bool) -> void:
	_reload_amount = 1.0 if enabled else 0.0

func add_flinch(strength: float = 0.7) -> void:
	_flinch_amount = clampf(maxf(_flinch_amount, strength), 0.0, 1.0)
	_flinch_side = -1.0 if randf() < 0.5 else 1.0

func set_t_pose_arms(enabled: bool) -> void:
	_t_pose_arms = enabled

func set_prone(enabled: bool) -> void:
	_prone = enabled

func set_hide_head(enabled: bool) -> void:
	_hide_head = enabled
	_apply_hidden_bones()

## Включает физический рэгдолл при смерти.
func set_ragdoll(enabled: bool, hit_dir: Vector3 = Vector3.ZERO, is_headshot: bool = false) -> void:
	if not enabled:
		_reset_ragdoll()
		return
	_is_ragdoll = enabled
	_ragdoll_timer = 0.0
	_ragdoll_fall = 0.0
	_ragdoll_dir = hit_dir.normalized() if hit_dir.length_squared() > 0.01 else Vector3.FORWARD
	_ragdoll_headshot = is_headshot
	_ragdoll_side = -1.0 if (get_instance_id() % 2 == 0) else 1.0
	_ragdoll_settled = false
	_ragdoll_physics_time = 0.0
	_ragdoll_physics_active = false
	_ragdoll_physics_pending = _build_physics_ragdoll()
	if _ragdoll_physics_pending:
		call_deferred("_start_physics_ragdoll")
	set_process(true)

func is_physics_ragdoll_active() -> bool:
	return _ragdoll_physics_active

func get_physics_ragdoll_bone_count() -> int:
	return _ragdoll_physics_bones.size()

func _build_physics_ragdoll() -> bool:
	if _skeleton == null or not is_instance_valid(_skeleton):
		return false
	if _ragdoll_physics != null and is_instance_valid(_ragdoll_physics):
		return not _ragdoll_physics_bones.is_empty()

	_ragdoll_physics = PhysicalBoneSimulator3D.new()
	_ragdoll_physics.name = "RagdollPhysics"
	_ragdoll_physics.active = false
	_skeleton.add_child(_ragdoll_physics)
	_ragdoll_physics_bones.clear()

	for child_id in range(_skeleton.get_bone_count()):
		var parent_id := _skeleton.get_bone_parent(child_id)
		if parent_id < 0:
			continue
		var bone_name := _skeleton.get_bone_name(parent_id)
		# The synthetic root has no volume and would add a useless body to each corpse.
		if bone_name == "Root" or _ragdoll_physics_bones.has(bone_name):
			continue

		var child_rest := _skeleton.get_bone_rest(child_id)
		var segment_length := child_rest.origin.length()
		var half_height := maxf(segment_length * 0.5, 0.055)
		var radius := _ragdoll_radius(bone_name, segment_length)
		var physical_bone := PhysicalBone3D.new()
		physical_bone.name = "Physical Bone " + bone_name
		physical_bone.mass = _ragdoll_mass(bone_name)
		physical_bone.friction = 0.85
		physical_bone.bounce = 0.0
		physical_bone.linear_damp = 0.5
		physical_bone.angular_damp = 2.0
		physical_bone.can_sleep = true
		physical_bone.collision_layer = 1 << 5
		physical_bone.collision_mask = RAGDOLL_WORLD_LAYER

		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		if segment_length <= 0.03:
			var joint_sphere := SphereShape3D.new()
			joint_sphere.radius = radius
			collision.shape = joint_sphere
		else:
			var capsule := CapsuleShape3D.new()
			capsule.radius = radius
			capsule.height = maxf(segment_length, radius * 2.2)
			collision.shape = capsule
			collision.transform.basis = Basis(Vector3.RIGHT, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 1.0, 0.0))
		physical_bone.add_child(collision)

		var up := Vector3.UP
		if absf(up.dot(child_rest.origin.normalized())) > 0.98:
			up = Vector3.FORWARD
		var body_basis := Basis.IDENTITY
		var joint_offset := Vector3.ZERO
		if segment_length > 0.03:
			body_basis = Basis.looking_at(child_rest.origin, up)
			physical_bone.body_offset = Transform3D(body_basis, body_basis * Vector3(0.0, 0.0, -half_height))
			joint_offset = Vector3(0.0, 0.0, half_height)
		physical_bone.joint_offset = Transform3D(Basis.IDENTITY, joint_offset)

		_ragdoll_physics.add_child(physical_bone)
		physical_bone.bone_name = bone_name
		var grandparent_id := _skeleton.get_bone_parent(parent_id)
		if grandparent_id >= 0 and _skeleton.get_bone_name(grandparent_id) != "Root":
			physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_PIN
		_ragdoll_physics_bones[bone_name] = physical_bone

	if _ragdoll_physics_bones.size() >= 8:
		return true
	_ragdoll_physics.queue_free()
	_ragdoll_physics = null
	_ragdoll_physics_bones.clear()
	return false

func _ragdoll_radius(bone_name: String, segment_length: float) -> float:
	if bone_name in ["Hips", "Spine", "Chest"]:
		return 0.13 if bone_name != "Hips" else 0.16
	if bone_name.contains("UpperLeg"):
		return 0.085
	if bone_name.contains("LowerLeg"):
		return 0.065
	if bone_name.contains("UpperArm"):
		return 0.06
	if bone_name.contains("LowerArm"):
		return 0.05
	if bone_name.contains("Shoulder"):
		return 0.075
	return clampf(segment_length * 0.20, 0.045, 0.075)

func _ragdoll_mass(bone_name: String) -> float:
	if bone_name == "Hips":
		return 4.0
	if bone_name in ["Spine", "Chest"]:
		return 2.4
	if bone_name.contains("UpperLeg"):
		return 1.5
	if bone_name.contains("LowerLeg"):
		return 0.9
	return 0.65

func _start_physics_ragdoll() -> void:
	_ragdoll_physics_pending = false
	if not _is_ragdoll or _skeleton == null or not is_instance_valid(_ragdoll_physics):
		return
	_skeleton.force_update_all_bone_transforms()
	_ragdoll_physics.physical_bones_start_simulation()
	await get_tree().physics_frame
	if not _is_ragdoll or not is_instance_valid(_ragdoll_physics):
		return
	_ragdoll_physics_active = false
	for value in _ragdoll_physics_bones.values():
		var physical_bone := value as PhysicalBone3D
		if physical_bone != null and physical_bone.is_simulating_physics():
			_ragdoll_physics_active = true
			break
	if not _ragdoll_physics_active:
		_ragdoll_physics.queue_free()
		_ragdoll_physics = null
		_ragdoll_physics_bones.clear()
		_ragdoll_settled = false
		return
	_ragdoll_physics_time = 0.0
	_register_physics_ragdoll()
	var impulse := _ragdoll_dir * (2.0 if _ragdoll_headshot else 1.35) + Vector3.UP * 0.45
	var chest := _ragdoll_physics_bones.get("Chest") as PhysicalBone3D
	if chest != null:
		chest.apply_central_impulse(impulse)
	var hips := _ragdoll_physics_bones.get("Hips") as PhysicalBone3D
	if hips != null:
		hips.apply_central_impulse(impulse * 0.35)

func _freeze_physics_ragdoll() -> void:
	if not _ragdoll_physics_active or _skeleton == null:
		return
	remove_from_group("active_physics_ragdolls")
	_skeleton.force_update_all_bone_transforms()
	var positions: Array[Vector3] = []
	var rotations: Array[Quaternion] = []
	var scales: Array[Vector3] = []
	for bone_id in range(_skeleton.get_bone_count()):
		positions.append(_skeleton.get_bone_pose_position(bone_id))
		rotations.append(_skeleton.get_bone_pose_rotation(bone_id))
		scales.append(_skeleton.get_bone_pose_scale(bone_id))
	if is_instance_valid(_ragdoll_physics):
		_ragdoll_physics.physical_bones_stop_simulation()
		_ragdoll_physics.active = false
		_ragdoll_physics.queue_free()
	_ragdoll_physics = null
	_ragdoll_physics_bones.clear()
	_ragdoll_physics_active = false
	for bone_id in range(positions.size()):
		_skeleton.set_bone_pose_position(bone_id, positions[bone_id])
		_skeleton.set_bone_pose_rotation(bone_id, rotations[bone_id])
		_skeleton.set_bone_pose_scale(bone_id, scales[bone_id])
	_skeleton.force_update_all_bone_transforms()
	_ragdoll_settled = true
	set_process(false)

func _reset_ragdoll() -> void:
	_is_ragdoll = false
	_ragdoll_physics_pending = false
	remove_from_group("active_physics_ragdolls")
	if _ragdoll_physics != null and is_instance_valid(_ragdoll_physics):
		_ragdoll_physics.physical_bones_stop_simulation()
		_ragdoll_physics.queue_free()
	_ragdoll_physics = null
	_ragdoll_physics_bones.clear()
	_ragdoll_physics_active = false
	_ragdoll_settled = false
	_ragdoll_timer = 0.0
	_hip_drop = 0.0
	if _skeleton != null and is_instance_valid(_skeleton):
		for bone_id in range(_skeleton.get_bone_count()):
			_skeleton.set_bone_pose_position(bone_id, _skeleton.get_bone_rest(bone_id).origin)
			_skeleton.set_bone_pose_rotation(bone_id, Quaternion.IDENTITY)
			_skeleton.set_bone_pose_scale(bone_id, Vector3.ONE)
		_pose.clear()
		for bone_name in _bone_ids:
			_pose[bone_name] = Quaternion.IDENTITY
		_apply_hidden_bones()
	set_process(true)

func _register_physics_ragdoll() -> void:
	_ragdoll_started_msec = Time.get_ticks_msec()
	add_to_group("active_physics_ragdolls")
	var active := get_tree().get_nodes_in_group("active_physics_ragdolls")
	if active.size() <= MAX_ACTIVE_RAGDOLLS:
		return
	var oldest: FRONTLINEProceduralSoldier
	for candidate in active:
		var procedural := candidate as FRONTLINEProceduralSoldier
		if procedural == null or procedural == self or not procedural._ragdoll_physics_active:
			continue
		if oldest == null or procedural._ragdoll_started_msec < oldest._ragdoll_started_msec:
			oldest = procedural
	if oldest != null:
		oldest._freeze_physics_ragdoll()

func _process(delta: float) -> void:
	if _skeleton == null:
		return

	if _is_ragdoll:
		_process_ragdoll(delta)
		return

	var blend := 1.0 - exp(-smoothing * delta)
	_idle_time += delta
	# Темп шага привязан к реальной скорости, чтобы ступни меньше скользили.
	var gait_rate := clampf(_speed * 1.7, 2.4, 7.5) * walk_cycle_rate
	if _move_amount > 0.02:
		_phase = fposmod(_phase + delta * gait_rate, TAU)
	_flinch_amount = maxf(0.0, _flinch_amount - delta * 3.5)

	var stride := sin(_phase) * _move_amount
	var opposite_stride := sin(_phase + PI) * _move_amount
	var bounce := absf(cos(_phase * 2.0)) * _move_amount
	var breath := sin(_idle_time * 1.55) * (1.0 - _move_amount) * (1.0 - _fire_amount)
	var run_scale := 1.0 + 0.35 * _run_amount
	var aim := _aim_amount
	var crouch := _crouch_amount
	var sit := _sit_amount
	var fire := _fire_amount
	var reload := _reload_amount
	var flinch := _flinch_amount

	# Опускаем таз, чтобы присед/сидение читались, а ступни оставались у пола.
	var target_hip_drop := crouch * 0.26 + sit * 0.48
	_hip_drop = lerpf(_hip_drop, target_hip_drop, blend)
	if _hips_id >= 0:
		var body_bob := bounce * 0.035 + breath * 0.008
		_skeleton.set_bone_pose_position(_hips_id, _hips_rest + Vector3(0, -_hip_drop + body_bob, 0))

	# Ноги
	_set_pose("LeftUpperLeg", _q(Vector3.RIGHT, stride * 0.48 * run_scale - crouch * 0.28 - sit * 1.50), blend)
	_set_pose("RightUpperLeg", _q(Vector3.RIGHT, opposite_stride * 0.48 * run_scale - crouch * 0.28 - sit * 1.50), blend)
	_set_pose("LeftLowerLeg", _q(Vector3.RIGHT, maxf(0.0, -stride) * 0.72 + crouch * 0.62 + sit * 1.50), blend)
	_set_pose("RightLowerLeg", _q(Vector3.RIGHT, maxf(0.0, -opposite_stride) * 0.72 + crouch * 0.62 + sit * 1.50), blend)
	_set_pose("LeftFoot", _q(Vector3.RIGHT, -maxf(0.0, stride) * 0.20 - sit * 0.20), blend)
	_set_pose("RightFoot", _q(Vector3.RIGHT, -maxf(0.0, opposite_stride) * 0.20 - sit * 0.20), blend)

	# Корпус и голова
	_set_pose("Hips", _q(Vector3.UP, sin(_phase) * 0.035 * _move_amount), blend)
	_set_pose("Spine", _q(Vector3.RIGHT, -0.06 * _run_amount - 0.16 * crouch + 0.16 * sit - 0.10 * reload + breath * 0.012), blend)
	_set_pose("Chest", _q(Vector3.UP, -sin(_phase) * 0.055 * _move_amount) * _q(Vector3.RIGHT, -0.10 * aim - 0.12 * reload - 0.14 * flinch + breath * 0.018) * _q(Vector3.FORWARD, 0.10 * flinch * _flinch_side), blend)
	_set_pose("Neck", _q(Vector3.RIGHT, _look_pitch * 0.30 + 0.10 * flinch), blend)
	_set_pose("Head", _q(Vector3.UP, _look_yaw * 0.72) * _q(Vector3.RIGHT, _look_pitch * 0.70 + 0.12 * flinch), blend)

	# Руки
	var arm_swing := 0.26 * run_scale
	var left_swing := opposite_stride * arm_swing * (1.0 - aim)
	var right_swing := stride * arm_swing * (1.0 - aim)
	if _t_pose_arms:
		var aim_amount := _aim_amount
		var l_up_idle := Vector3(-0.12, -1.0, 0.05 + 0.30 * left_swing).normalized()
		var l_low_idle := Vector3(-0.04, -1.0, 0.20 + 0.40 * left_swing).normalized()
		var r_up_idle := Vector3(0.12, -1.0, 0.05 + 0.30 * right_swing).normalized()
		var r_low_idle := Vector3(0.04, -1.0, 0.20 + 0.40 * right_swing).normalized()
		var l_up_aim: Vector3
		var l_low_aim: Vector3
		var r_up_aim: Vector3
		var r_low_aim: Vector3
		if _prone:
			l_up_aim = Vector3(0.46, 0.86, -0.10).normalized()
			l_low_aim = Vector3(0.55, 0.82, -0.12).normalized()
			r_up_aim = Vector3(-0.46, 0.86, -0.10).normalized()
			r_low_aim = Vector3(-0.55, 0.82, -0.12).normalized()
		else:
			l_up_aim = Vector3(0.30, -0.75, 0.59).normalized()
			l_low_aim = Vector3(0.55, 0.12, 0.83).normalized()
			r_up_aim = Vector3(-0.62, -0.62, 0.48).normalized()
			r_low_aim = Vector3(-0.50, 0.10, 0.86).normalized()
		var l_up := l_up_idle.lerp(l_up_aim, aim_amount).normalized()
		var l_low := l_low_idle.lerp(l_low_aim, aim_amount).normalized()
		var r_up := r_up_idle.lerp(r_up_aim, aim_amount).normalized()
		var r_low := r_low_idle.lerp(r_low_aim, aim_amount).normalized()
		var q_l_up := Quaternion(Vector3.LEFT, l_up)
		var q_r_up := Quaternion(Vector3.RIGHT, r_up)
		var q_l_low := q_l_up.inverse() * Quaternion(Vector3.LEFT, l_low)
		var q_r_low := q_r_up.inverse() * Quaternion(Vector3.RIGHT, r_low)
		_set_pose("LeftShoulder", Quaternion.IDENTITY, blend)
		_set_pose("RightShoulder", Quaternion.IDENTITY, blend)
		_set_pose("LeftUpperArm", q_l_up, blend)
		_set_pose("RightUpperArm", q_r_up, blend)
		_set_pose("LeftLowerArm", q_l_low, blend)
		_set_pose("RightLowerArm", q_r_low, blend)
		_set_pose("LeftHand", Quaternion.IDENTITY, blend)
		_set_pose("RightHand", Quaternion.IDENTITY, blend)
	else:
		_set_pose("LeftShoulder", _q(Vector3.FORWARD, left_swing * 0.16), blend)
		_set_pose("RightShoulder", _q(Vector3.FORWARD, right_swing * 0.16), blend)
		if _prone and aim > 0.01:
			_set_pose("LeftUpperArm", _q(Vector3.UP, 0.35 * aim) * _q(Vector3.RIGHT, PI - 0.18), blend)
			_set_pose("RightUpperArm", _q(Vector3.UP, -0.35 * aim) * _q(Vector3.RIGHT, PI - 0.18), blend)
			_set_pose("LeftLowerArm", _q(Vector3.RIGHT, -0.12), blend)
			_set_pose("RightLowerArm", _q(Vector3.RIGHT, -0.12), blend)
			_set_pose("LeftHand", Quaternion.IDENTITY, blend)
			_set_pose("RightHand", Quaternion.IDENTITY, blend)
			return
		var aim_raise := 1.25 * aim * _aim_forward_sign
		var inward := 0.55 * aim
		# Левая рука уходит к магазину на перезарядке.
		_set_pose("LeftUpperArm", _q(Vector3.UP, inward - 0.18 * reload) * _q(Vector3.RIGHT, aim_raise + left_swing - crouch * 0.10 - 0.48 * reload), blend)
		_set_pose("RightUpperArm", _q(Vector3.UP, -inward) * _q(Vector3.RIGHT, aim_raise + right_swing - crouch * 0.10), blend)
		_set_pose("LeftLowerArm", _q(Vector3.RIGHT, -0.20 * aim + fire * 0.12 + 0.90 * reload), blend)
		_set_pose("RightLowerArm", _q(Vector3.RIGHT, -0.24 * aim + fire * 0.12), blend)
		_set_pose("LeftHand", _q(Vector3.RIGHT, -0.08 * aim - 0.25 * reload), blend)
		_set_pose("RightHand", _q(Vector3.RIGHT, -0.06 * aim), blend)

## Процедурная физика рэгдолла при гибели в стиле Dummy War.
func _process_ragdoll(delta: float) -> void:
	if _ragdoll_settled:
		return
	if _ragdoll_physics_pending:
		return
	if _ragdoll_physics_active:
		_ragdoll_physics_time += delta
		if _ragdoll_physics_time >= RAGDOLL_PHYSICS_TIME:
			_freeze_physics_ragdoll()
		return
	_ragdoll_timer += delta
	_ragdoll_fall = minf(1.0, _ragdoll_fall + delta * 3.2)
	var t := ease(_ragdoll_fall, 0.45)
	var blend := clampf(delta * 14.0, 0.0, 1.0)

	# Опускаем таз к полу: тело ложится на землю
	var target_drop := 0.74 * t
	if _hips_id >= 0:
		_skeleton.set_bone_pose_position(_hips_id, _hips_rest + Vector3(0, -target_drop, 0))

	# Проверяем вектор попадания относительно бойца
	var forward := -global_transform.basis.z
	var hit_front := _ragdoll_dir.dot(forward) < 0.2

	if hit_front:
		# Попадание спереди: корпус откидывается назад, колени подкашиваются вперёд
		var head_snap := 1.2 if _ragdoll_headshot else 0.55
		_set_pose("Head", _q(Vector3.RIGHT, head_snap * t) * _q(Vector3.UP, 0.3 * _ragdoll_side * t), blend)
		_set_pose("Neck", _q(Vector3.RIGHT, 0.4 * t), blend)
		_set_pose("Chest", _q(Vector3.RIGHT, 0.45 * t) * _q(Vector3.FORWARD, 0.2 * _ragdoll_side * t), blend)
		_set_pose("Spine", _q(Vector3.RIGHT, 0.35 * t), blend)
		_set_pose("LeftUpperLeg", _q(Vector3.RIGHT, -0.85 * t) * _q(Vector3.UP, 0.25 * t), blend)
		_set_pose("RightUpperLeg", _q(Vector3.RIGHT, -0.70 * t) * _q(Vector3.UP, -0.25 * t), blend)
		_set_pose("LeftLowerLeg", _q(Vector3.RIGHT, 1.40 * t), blend)
		_set_pose("RightLowerLeg", _q(Vector3.RIGHT, 1.25 * t), blend)
	else:
		# Попадание сзади: тело складывается вперёд и валится на живот/бок
		_set_pose("Head", _q(Vector3.RIGHT, -0.6 * t) * _q(Vector3.FORWARD, 0.4 * _ragdoll_side * t), blend)
		_set_pose("Neck", _q(Vector3.RIGHT, -0.35 * t), blend)
		_set_pose("Chest", _q(Vector3.RIGHT, -0.55 * t), blend)
		_set_pose("Spine", _q(Vector3.RIGHT, -0.45 * t), blend)
		_set_pose("LeftUpperLeg", _q(Vector3.RIGHT, 0.7 * t), blend)
		_set_pose("RightUpperLeg", _q(Vector3.RIGHT, 0.9 * t), blend)
		_set_pose("LeftLowerLeg", _q(Vector3.RIGHT, 0.8 * t), blend)
		_set_pose("RightLowerLeg", _q(Vector3.RIGHT, 1.1 * t), blend)

	# Руки обвисают и падают вдоль тела
	_set_pose("LeftUpperArm", _q(Vector3.FORWARD, -0.4 * t) * _q(Vector3.RIGHT, -0.3 * t), blend)
	_set_pose("RightUpperArm", _q(Vector3.FORWARD, 0.4 * t) * _q(Vector3.RIGHT, -0.3 * t), blend)
	_set_pose("LeftLowerArm", _q(Vector3.RIGHT, 0.2 * t), blend)
	_set_pose("RightLowerArm", _q(Vector3.RIGHT, 0.2 * t), blend)

	if _ragdoll_timer > 1.8:
		_ragdoll_settled = true
		set_process(false)

func _set_pose(bone_name: String, target: Quaternion, weight: float) -> void:
	if not _bone_ids.has(bone_name):
		return
	var current: Quaternion = _pose.get(bone_name, Quaternion.IDENTITY)
	var next := current.slerp(target, weight).normalized()
	_pose[bone_name] = next
	_skeleton.set_bone_pose_rotation(_bone_ids[bone_name], next)

func _q(axis: Vector3, angle: float) -> Quaternion:
	return Quaternion(axis.normalized(), angle)
