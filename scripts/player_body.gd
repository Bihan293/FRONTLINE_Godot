extends Node3D

## Тело игрока от первого лица. Торс и ноги — настоящие кости модели,
## а руки через IK тянутся от плеч к рукоятке/цевью автомата.
## Камера стоит на уровне лба, поэтому видно своё тело, а не «парящие» руки.

const BLOCK_RIG_BUILDER = preload("res://scripts/block_rig_builder.gd")
const PROCEDURAL = preload("res://scripts/procedural_soldier.gd")

const GERMAN_MODEL := "res://assets/models/soldiers/FRONTLINE_German_Grey_Block_Soldier.glb"
const SOVIET_MODEL := "res://assets/models/soldiers/FRONTLINE_Soviet_Khaki_Block_Soldier.glb"
const GERMAN_HELMET := "res://assets/models/equipment/German_Helmet.glb"
const GERMAN_VEST := "res://assets/models/equipment/German_Vest.glb"
const SOVIET_HELMET := "res://assets/models/equipment/Soviet_Helmet.glb"
const SOVIET_VEST := "res://assets/models/equipment/Soviet_Vest.glb"

const ARM_UPPER := 0.33
const ARM_LOWER := 0.26
const PRONE_Y := 0.14
const HIP_HEIGHT := 0.875

var body_visual: Node3D
var skeleton: Skeleton3D
var torso_mesh: MeshInstance3D
var wrist_left: Node3D
var wrist_right: Node3D
var stance := 0
var look_down := 0.0
var _red := false
var _cuffs: Array = []
var _cuff_mat: StandardMaterial3D

func _ready() -> void:
    # IK должен выполняться после процедурной анимации торса/ног.
    process_priority = 100

func setup(is_red: bool, left_wrist: Node3D, right_wrist: Node3D) -> void:
    _red = is_red
    wrist_left = left_wrist
    wrist_right = right_wrist

    var model_path := SOVIET_MODEL if _red else GERMAN_MODEL
    var packed = load(model_path)
    if packed == null:
        push_error("FRONTLINE: cannot load player body " + model_path)
        return
    var model: Node3D = packed.instantiate()
    _add_equipment(model)
    var skel := BLOCK_RIG_BUILDER.rig_model(model)
    # Торс (грудь + бронежилет + таз) и всё остальное (ноги, руки, голова)
    # держим отдельными мешами: торс можно спрятать, когда камера внутри него.
    torso_mesh = BLOCK_RIG_BUILDER.merge_rigged_model(skel, [], ["Chest", "Hips"], false)
    BLOCK_RIG_BUILDER.merge_rigged_model(skel, ["Chest", "Hips", "LeftUpperArm", "RightUpperArm"], [], true)

    body_visual = Node3D.new()
    body_visual.name = "BodyVisual"
    body_visual.rotation.y = PI
    body_visual.add_child(model)
    body_visual.set_script(PROCEDURAL)
    add_child(body_visual)
    # Тени от собственного тела/рук в first-person выглядят как чёрные крылья.
    for mesh_instance in body_visual.find_children("*", "MeshInstance3D", true, false):
        (mesh_instance as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    skeleton = skel
    body_visual.set_t_pose_arms(false)
    body_visual.set_aiming(false)
    body_visual.set_motion(0.0, false)
    body_visual.set_hide_head(true)
    _build_cuffs()

func _add_equipment(root: Node3D) -> void:
    var helmet_path := SOVIET_HELMET if _red else GERMAN_HELMET
    var vest_path := SOVIET_VEST if _red else GERMAN_VEST
    var helmet = load(helmet_path)
    if helmet != null:
        var h: Node3D = helmet.instantiate()
        h.name = "Helmet"
        h.position = Vector3(0.0, 1.78, 0.0)
        # Камера стоит внутри шлема — изнутри он закрывает половину экрана.
        h.visible = false
        root.add_child(h)
    var vest = load(vest_path)
    if vest != null:
        var v: Node3D = vest.instantiate()
        v.name = "Vest"
        v.position = Vector3(0.0, 1.345, 0.0)
        v.scale = Vector3(1.12, 1.03, 1.18)
        v.visible = false
        root.add_child(v)

func _build_cuffs() -> void:
    _cuff_mat = StandardMaterial3D.new()
    _cuff_mat.albedo_color = Color(0.10, 0.10, 0.09)
    _cuff_mat.roughness = 0.98
    for i in range(2):
        var cuff := MeshInstance3D.new()
        var mesh := CylinderMesh.new()
        mesh.top_radius = 0.050
        mesh.bottom_radius = 0.050
        mesh.height = 1.0
        mesh.radial_segments = 12
        cuff.mesh = mesh
        cuff.material_override = _cuff_mat
        cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        cuff.visible = false
        add_child(cuff)
        _cuffs.append(cuff)

func _place_cuff(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
    var d := b - a
    var length := d.length()
    if length < 0.001:
        return
    var dir := d / length
    var basis := Basis(Quaternion(Vector3.UP, dir)).scaled(Vector3(1.0, length, 1.0))
    node.global_transform = Transform3D(basis, (a + b) * 0.5)

func set_motion(speed: float, running: bool) -> void:
    if body_visual != null:
        body_visual.set_motion(speed, running)

func set_stance(value: int) -> void:
    if stance == value:
        return
    stance = value
    if body_visual != null:
        body_visual.set_crouching(value == 1)
        body_visual.set_prone(value == 2)

func set_look_down(value: float) -> void:
    look_down = clampf(value, 0.0, 1.0)

func _process(_delta: float) -> void:
    if body_visual == null or skeleton == null:
        return
    if stance == 2:
        body_visual.rotation.x = PI * 0.5
        body_visual.position = Vector3(0.0, PRONE_Y, HIP_HEIGHT)
    else:
        body_visual.rotation.x = 0.0
        body_visual.position = Vector3.ZERO
    if torso_mesh != null:
        # Торс показываем только когда игрок реально смотрит вниз.
        # Иначе камера оказывается внутри бронежилета и он закрывает пол-экрана.
        torso_mesh.visible = stance == 0 and look_down > 0.55
    _apply_arm(0)
    _apply_arm(1)

func _apply_arm(side: int) -> void:
    var upper_name := "LeftUpperArm" if side == 0 else "RightUpperArm"
    var lower_name := "LeftLowerArm" if side == 0 else "RightLowerArm"
    var hand_name := "LeftHand" if side == 0 else "RightHand"
    var upper := skeleton.find_bone(upper_name)
    var lower := skeleton.find_bone(lower_name)
    var hand := skeleton.find_bone(hand_name)
    if upper < 0 or lower < 0 or hand < 0:
        return
    var wrist: Node3D = wrist_left if side == 0 else wrist_right
    if wrist == null:
        return
    var shoulder: Vector3 = skeleton.get_bone_global_pose(upper).origin
    var target: Vector3 = skeleton.global_transform.affine_inverse() * wrist.global_position
    var delta := target - shoulder
    var dist := delta.length()
    if dist < 0.05:
        return
    var dir := delta / dist
    var a := clampf((ARM_UPPER * ARM_UPPER - ARM_LOWER * ARM_LOWER + dist * dist) / (2.0 * dist), 0.0, ARM_UPPER)
    var h := sqrt(maxf(ARM_UPPER * ARM_UPPER - a * a, 0.0004))
    var pole := Vector3(-0.8 if side == 0 else 0.8, -0.75, -0.15)
    pole = (pole - dir * pole.dot(dir)).normalized()
    var elbow := shoulder + dir * a + pole * h

    var d_upper := (elbow - shoulder).normalized()
    var d_lower := (target - elbow).normalized()
    var parent_idx := skeleton.get_bone_parent(upper)
    var parent_basis := skeleton.get_bone_global_pose(parent_idx).basis
    var q_upper := Quaternion(Vector3.DOWN, (parent_basis.inverse() * d_upper).normalized())
    skeleton.set_bone_pose_rotation(upper, q_upper)
    var upper_basis := parent_basis * Basis(q_upper)
    var q_lower := Quaternion(Vector3.DOWN, (upper_basis.inverse() * d_lower).normalized())
    skeleton.set_bone_pose_rotation(lower, q_lower)
    skeleton.set_bone_pose_rotation(hand, Quaternion.IDENTITY)
    # Руки в first-person почти убираем: из-за IK они вытягиваются
    # в длинные чёрные полосы поверх экрана. Оружие держит viewmodel.
    skeleton.set_bone_pose_scale(upper, Vector3(0.02, 1.0, 0.02))
    skeleton.set_bone_pose_scale(lower, Vector3(0.02, 1.0, 0.02))
    skeleton.set_bone_pose_scale(hand, Vector3(1.0, 1.0, 1.0))
    if side < _cuffs.size():
        var world_target := skeleton.global_transform * target
        var world_elbow := skeleton.global_transform * elbow
        var fore := (world_target - world_elbow).normalized()
        _place_cuff(_cuffs[side], world_target - fore * 0.10, world_target - fore * 0.01)
