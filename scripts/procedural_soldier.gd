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
var _aim_forward_sign: float = -1.0
var _look_yaw: float = 0.0
var _look_pitch: float = 0.0
var _t_pose_arms := false
var _prone := false
var _hide_head := false
var _hide_arms := false
var _pose: Dictionary = {}

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
    # Godot stores bone poses as local transforms. Newly built skeletons start
    # with identity poses, so without this every bone collapses to its parent's
    # origin and all body parts pile up at the hips.
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
    if _hide_arms:
        for bone_name in ["LeftUpperArm", "RightUpperArm"]:
            if _bone_ids.has(bone_name):
                _skeleton.set_bone_pose_scale(_bone_ids[bone_name], tiny)

func _find_skeleton() -> Skeleton3D:
    var direct := get_node_or_null(skeleton_path)
    if direct is Skeleton3D:
        return direct
    # Godot может назвать Skeleton3D по имени скина, поэтому ищем по типу.
    for node in find_children("*", "Skeleton3D", true, false):
        if node is Skeleton3D:
            return node
    return null

## Call from the character movement controller. speed is in m/s (or a consistent
## project-specific unit); it is normalized internally for the gait cycle.
func set_motion(speed: float, running: bool = false) -> void:
    _speed = maxf(speed, 0.0)
    _move_amount = clampf(_speed / 2.8, 0.0, 1.0)
    _run_amount = 1.0 if running else 0.0

## yaw and pitch are radians. Feed these from the look controller, not raw pixels.
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

func set_t_pose_arms(enabled: bool) -> void:
    _t_pose_arms = enabled

func set_prone(enabled: bool) -> void:
    _prone = enabled

func set_hide_head(enabled: bool) -> void:
    _hide_head = enabled
    _apply_hidden_bones()

func set_hide_arms(enabled: bool) -> void:
    _hide_arms = enabled
    _apply_hidden_bones()

func set_chest_scale(value: float) -> void:
    if _skeleton == null or not _bone_ids.has("Chest"):
        return
    var scale_value := maxf(clampf(value, 0.0, 1.0), 0.001)
    _skeleton.set_bone_pose_scale(_bone_ids["Chest"], Vector3.ONE * scale_value)

func _process(delta: float) -> void:
    if _skeleton == null:
        return
    var blend := 1.0 - exp(-smoothing * delta)
    _idle_time += delta
    var gait_rate := lerpf(2.0, 5.2, _run_amount) * walk_cycle_rate
    if _move_amount > 0.02:
        _phase = fposmod(_phase + delta * gait_rate, TAU)

    var stride := sin(_phase) * _move_amount
    var opposite_stride := sin(_phase + PI) * _move_amount
    var bounce := absf(cos(_phase * 2.0)) * _move_amount
    var breath := sin(_idle_time * 1.55) * (1.0 - _move_amount) * (1.0 - _fire_amount)
    var run_scale := 1.0 + 0.35 * _run_amount
    var aim := _aim_amount
    var crouch := _crouch_amount
    var sit := _sit_amount
    var fire := _fire_amount

    # Опускаем таз, чтобы присед/сидение читались, а ступни оставались у пола.
    var target_hip_drop := crouch * 0.26 + sit * 0.48
    _hip_drop = lerpf(_hip_drop, target_hip_drop, blend)
    if _hips_id >= 0:
        var body_bob := bounce * 0.035 + breath * 0.008
        _skeleton.set_bone_pose_position(_hips_id, _hips_rest + Vector3(0, -_hip_drop + body_bob, 0))

    # Lower body: alternating hip/knee/foot motion with a softer planted-foot phase.
    _set_pose("LeftUpperLeg", _q(Vector3.RIGHT, stride * 0.48 * run_scale - crouch * 0.28 - sit * 1.50), blend)
    _set_pose("RightUpperLeg", _q(Vector3.RIGHT, opposite_stride * 0.48 * run_scale - crouch * 0.28 - sit * 1.50), blend)
    _set_pose("LeftLowerLeg", _q(Vector3.RIGHT, maxf(0.0, -stride) * 0.72 + crouch * 0.62 + sit * 1.50), blend)
    _set_pose("RightLowerLeg", _q(Vector3.RIGHT, maxf(0.0, -opposite_stride) * 0.72 + crouch * 0.62 + sit * 1.50), blend)
    _set_pose("LeftFoot", _q(Vector3.RIGHT, -maxf(0.0, stride) * 0.20 - sit * 0.20), blend)
    _set_pose("RightFoot", _q(Vector3.RIGHT, -maxf(0.0, opposite_stride) * 0.20 - sit * 0.20), blend)

    # Torso follows the gait with damped counter-rotation and a subtle vertical rhythm.
    _set_pose("Hips", _q(Vector3.UP, sin(_phase) * 0.035 * _move_amount), blend)
    _set_pose("Spine", _q(Vector3.RIGHT, -0.06 * _run_amount - 0.16 * crouch + 0.16 * sit + breath * 0.012), blend)
    _set_pose("Chest", _q(Vector3.UP, -sin(_phase) * 0.055 * _move_amount) * _q(Vector3.RIGHT, -0.10 * aim + breath * 0.018), blend)
    _set_pose("Neck", _q(Vector3.RIGHT, _look_pitch * 0.30), blend)
    _set_pose("Head", _q(Vector3.UP, _look_yaw * 0.72) * _q(Vector3.RIGHT, _look_pitch * 0.70), blend)

    # Arms counter-swing while moving; aiming smoothly blends both arms into a ready pose.
    var arm_swing := 0.26 * run_scale
    var left_swing := opposite_stride * arm_swing * (1.0 - aim)
    var right_swing := stride * arm_swing * (1.0 - aim)
    if _t_pose_arms:
        # Импортированные солдаты стоят в T-позе: кости рук направлены по ±X.
        # Задаём направления цепочки в пространстве модели и переводим их в
        # локальные кватернионы костей (все rest-базисы у модели единичные).
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
            # Лицом вниз: bone +Y смотрит вперёд, руки вытянуты к оружию.
            l_up_aim = Vector3(0.46, 0.86, -0.10).normalized()
            l_low_aim = Vector3(0.55, 0.82, -0.12).normalized()
            r_up_aim = Vector3(-0.46, 0.86, -0.10).normalized()
            r_low_aim = Vector3(-0.55, 0.82, -0.12).normalized()
        else:
            # Стрелковая стойка: локти вниз, кисти сходятся к оружию.
            l_up_aim = Vector3(0.30, -0.75, 0.59).normalized()
            l_low_aim = Vector3(0.55, 0.12, 0.83).normalized()
            r_up_aim = Vector3(-0.62, -0.62, 0.48).normalized()
            r_low_aim = Vector3(-0.50, 0.10, 0.86).normalized()
        var l_up := l_up_idle.lerp(l_up_aim, aim_amount).normalized()
        var l_low := l_low_idle.lerp(l_low_aim, aim_amount).normalized()
        var r_up := r_up_idle.lerp(r_up_aim, aim_amount).normalized()
        var r_low := r_low_idle.lerp(r_low_aim, aim_amount).normalized()
        # Поворот кости от её rest-направления к целевому.
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
            # Лёжа: руки вытянуты вдоль корпуса вперёд (в model +Y).
            _set_pose("LeftUpperArm", _q(Vector3.UP, 0.35 * aim) * _q(Vector3.RIGHT, PI - 0.18), blend)
            _set_pose("RightUpperArm", _q(Vector3.UP, -0.35 * aim) * _q(Vector3.RIGHT, PI - 0.18), blend)
            _set_pose("LeftLowerArm", _q(Vector3.RIGHT, -0.12), blend)
            _set_pose("RightLowerArm", _q(Vector3.RIGHT, -0.12), blend)
            _set_pose("LeftHand", Quaternion.IDENTITY, blend)
            _set_pose("RightHand", Quaternion.IDENTITY, blend)
            return
        # У блочных моделей руки опущены вдоль корпуса. Плавно поднимаем их к
        # автомату при прицеливании; при ходьбе оставляем мягкий встречный мах.
        var aim_raise := 1.25 * aim * _aim_forward_sign
        var inward := 0.55 * aim
        _set_pose("LeftUpperArm", _q(Vector3.UP, inward) * _q(Vector3.RIGHT, aim_raise + left_swing - crouch * 0.10), blend)
        _set_pose("RightUpperArm", _q(Vector3.UP, -inward) * _q(Vector3.RIGHT, aim_raise + right_swing - crouch * 0.10), blend)
        _set_pose("LeftLowerArm", _q(Vector3.RIGHT, -0.20 * aim + fire * 0.12), blend)
        _set_pose("RightLowerArm", _q(Vector3.RIGHT, -0.24 * aim + fire * 0.12), blend)
        _set_pose("LeftHand", _q(Vector3.RIGHT, -0.08 * aim), blend)
        _set_pose("RightHand", _q(Vector3.RIGHT, -0.06 * aim), blend)

func _set_pose(bone_name: String, target: Quaternion, weight: float) -> void:
    if not _bone_ids.has(bone_name):
        return
    var current: Quaternion = _pose.get(bone_name, Quaternion.IDENTITY)
    var next := current.slerp(target, weight).normalized()
    _pose[bone_name] = next
    _skeleton.set_bone_pose_rotation(_bone_ids[bone_name], next)

func _q(axis: Vector3, angle: float) -> Quaternion:
    return Quaternion(axis.normalized(), angle)
