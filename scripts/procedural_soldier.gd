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
var _speed: float = 0.0
var _move_amount: float = 0.0
var _run_amount: float = 0.0
var _aim_amount: float = 0.0
var _crouch_amount: float = 0.0
var _sit_amount: float = 0.0
var _fire_amount: float = 0.0
var _look_yaw: float = 0.0
var _look_pitch: float = 0.0
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
    if _bone_ids.has("Hips"):
        _hips_id = _bone_ids["Hips"]
        _hips_rest = _skeleton.get_bone_rest(_hips_id).origin

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

func set_crouching(enabled: bool) -> void:
    _crouch_amount = 1.0 if enabled else 0.0

func set_sitting(enabled: bool) -> void:
    _sit_amount = 1.0 if enabled else 0.0

func set_firing(enabled: bool) -> void:
    _fire_amount = 1.0 if enabled else 0.0

func _process(delta: float) -> void:
    if _skeleton == null:
        return
    var blend := 1.0 - exp(-smoothing * delta)
    var gait_rate := lerpf(2.0, 5.2, _run_amount) * walk_cycle_rate
    if _move_amount > 0.02:
        _phase = fposmod(_phase + delta * gait_rate, TAU)

    var stride := sin(_phase) * _move_amount
    var opposite_stride := sin(_phase + PI) * _move_amount
    var bounce := absf(cos(_phase * 2.0)) * _move_amount
    var run_scale := 1.0 + 0.35 * _run_amount
    var aim := _aim_amount
    var crouch := _crouch_amount
    var sit := _sit_amount
    var fire := _fire_amount

    # Опускаем таз, чтобы присед/сидение читались, а ступни оставались у пола.
    var target_hip_drop := crouch * 0.28 + sit * 0.75
    _hip_drop = lerpf(_hip_drop, target_hip_drop, blend)
    if _hips_id >= 0:
        _skeleton.set_bone_pose_position(_hips_id, _hips_rest + Vector3(0, -_hip_drop, 0))

    # Lower body: alternating hip/knee/foot motion with a softer planted-foot phase.
    _set_pose("LeftUpperLeg", _q(Vector3.RIGHT, stride * 0.48 * run_scale - crouch * 0.28 - sit * 1.25), blend)
    _set_pose("RightUpperLeg", _q(Vector3.RIGHT, opposite_stride * 0.48 * run_scale - crouch * 0.28 - sit * 1.25), blend)
    _set_pose("LeftLowerLeg", _q(Vector3.RIGHT, maxf(0.0, -stride) * 0.72 + crouch * 0.62 + sit * 1.45), blend)
    _set_pose("RightLowerLeg", _q(Vector3.RIGHT, maxf(0.0, -opposite_stride) * 0.72 + crouch * 0.62 + sit * 1.45), blend)
    _set_pose("LeftFoot", _q(Vector3.RIGHT, -maxf(0.0, stride) * 0.20 - sit * 0.20), blend)
    _set_pose("RightFoot", _q(Vector3.RIGHT, -maxf(0.0, opposite_stride) * 0.20 - sit * 0.20), blend)

    # Torso follows the gait with damped counter-rotation and a subtle vertical rhythm.
    _set_pose("Hips", _q(Vector3.UP, sin(_phase) * 0.035 * _move_amount), blend)
    _set_pose("Spine", _q(Vector3.RIGHT, -0.05 * _run_amount - 0.10 * crouch + 0.12 * sit), blend)
    _set_pose("Chest", _q(Vector3.UP, -sin(_phase) * 0.045 * _move_amount) * _q(Vector3.RIGHT, -0.08 * aim), blend)
    _set_pose("Neck", _q(Vector3.RIGHT, _look_pitch * 0.25), blend)
    _set_pose("Head", _q(Vector3.UP, _look_yaw) * _q(Vector3.RIGHT, _look_pitch * 0.75), blend)

    # Arms counter-swing while moving; aiming smoothly blends both arms into a ready pose.
    var arm_swing := 0.38 * run_scale
    var left_swing := opposite_stride * arm_swing * (1.0 - aim)
    var right_swing := stride * arm_swing * (1.0 - aim)
    _set_pose("LeftShoulder", _q(Vector3.FORWARD, left_swing * 0.22), blend)
    _set_pose("RightShoulder", _q(Vector3.FORWARD, right_swing * 0.22), blend)
    _set_pose("LeftUpperArm", _q(Vector3.UP, lerpf(0.0, deg_to_rad(78.0), aim)) * _q(Vector3.FORWARD, left_swing), blend)
    _set_pose("RightUpperArm", _q(Vector3.UP, lerpf(0.0, deg_to_rad(-78.0), aim)) * _q(Vector3.FORWARD, right_swing), blend)
    _set_pose("LeftLowerArm", _q(Vector3.RIGHT, lerpf(0.0, -0.85, aim) + fire * 0.08), blend)
    _set_pose("RightLowerArm", _q(Vector3.RIGHT, lerpf(0.0, -0.85, aim) + fire * 0.08), blend)
    _set_pose("LeftHand", Quaternion.IDENTITY, blend)
    _set_pose("RightHand", Quaternion.IDENTITY, blend)

func _set_pose(bone_name: String, target: Quaternion, weight: float) -> void:
    if not _bone_ids.has(bone_name):
        return
    var current: Quaternion = _pose.get(bone_name, Quaternion.IDENTITY)
    var next := current.slerp(target, weight).normalized()
    _pose[bone_name] = next
    _skeleton.set_bone_pose_rotation(_bone_ids[bone_name], next)

func _q(axis: Vector3, angle: float) -> Quaternion:
    return Quaternion(axis.normalized(), angle)
