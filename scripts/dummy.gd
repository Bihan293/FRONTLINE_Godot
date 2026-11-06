extends Node3D

const PROCEDURAL = preload("res://scripts/procedural_soldier.gd")
const IRON_SCENE := "res://assets/models/soldiers/FRONTLINE_IRON_LEGION_Soldier_RIG_v1.glb"
const RED_SCENE := "res://assets/models/soldiers/FRONTLINE_RED_FRONT_Soldier_RIG_v1.glb"

# Модель авторится ростом 2.39 м с origin по центру.
const MODEL_SCALE := 0.75
const MODEL_LIFT := 0.9225

static var _normal_mesh_cache: Dictionary = {}

var team_name := "IRON LEGION"
var team_color := Color(0.28, 0.30, 0.32)
var dummy_name := "TARGET"
var health := 100.0

var _pivot: Node3D
var _visual: Node3D
var _proc
var _label: Label3D
var _hitboxes: Array[StaticBody3D] = []
var _dead := false
var _fall := 0.0
var _respawn_timer := 0.0

func _ready() -> void:
    _build_visual()
    _build_hitboxes()
    _build_label()
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player != null:
        set_look_at_player(player, 1.0)

func _build_visual() -> void:
    _pivot = Node3D.new()
    add_child(_pivot)

    _visual = Node3D.new()
    _visual.scale = Vector3.ONE * MODEL_SCALE
    _visual.position.y = MODEL_LIFT
    _visual.rotation.y = PI  # модель смотрит в +Z, в Godot перед — это -Z

    var path := RED_SCENE if team_name.to_upper().contains("RED") else IRON_SCENE
    var packed = load(path)
    if packed == null:
        push_error("FRONTLINE: cannot load soldier model " + path)
        return
    var model = packed.instantiate()
    _fix_normals(model)
    _visual.add_child(model)
    _visual.set_script(PROCEDURAL)
    _pivot.add_child(_visual)
    _proc = _visual
    # Сразу стойка «оружие к бою», иначе модель стоит в T-позе.
    _proc.set_aiming(true)
    _proc.set_motion(0.0, false)
    _proc.set_look(0.0, 0.0)

func _fix_normals(root: Node) -> void:
    # Исходные GLB солдат не содержат NORMAL. Godot их не генерирует,
    # поэтому делаем плоские нормали (deindex + generate_normals) и кешируем.
    for mi in root.find_children("*", "MeshInstance3D", true, false):
        var src: Mesh = mi.mesh
        if src == null or src.get_surface_count() == 0:
            continue
        var fmt: int = int(src.surface_get_format(0))
        if fmt & Mesh.ARRAY_FORMAT_NORMAL:
            continue
        var key := src.get_instance_id()
        if _normal_mesh_cache.has(key):
            mi.mesh = _normal_mesh_cache[key]
            continue
        var st := SurfaceTool.new()
        st.create_from(src, 0)
        st.deindex()
        st.generate_normals()
        var fixed: ArrayMesh = st.commit()
        if fixed == null:
            continue
        fixed.surface_set_material(0, src.surface_get_material(0))
        _normal_mesh_cache[key] = fixed
        mi.mesh = fixed

func _build_hitboxes() -> void:
    _add_hitbox(Vector3(0, 1.62, 0), Vector3(0.30, 0.30, 0.30), "head")
    _add_hitbox(Vector3(0, 1.24, 0), Vector3(0.46, 0.42, 0.30), "chest")
    _add_hitbox(Vector3(0, 0.95, 0), Vector3(0.40, 0.22, 0.28), "stomach")
    _add_hitbox(Vector3(-0.36, 1.16, 0), Vector3(0.16, 0.52, 0.20), "arm")
    _add_hitbox(Vector3(0.36, 1.16, 0), Vector3(0.16, 0.52, 0.20), "arm")
    _add_hitbox(Vector3(-0.13, 0.44, 0), Vector3(0.22, 0.82, 0.24), "leg")
    _add_hitbox(Vector3(0.13, 0.44, 0), Vector3(0.22, 0.82, 0.24), "leg")

func _add_hitbox(pos: Vector3, size: Vector3, region: String) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    body.collision_layer = 2
    body.collision_mask = 0
    body.add_to_group("damageable")
    body.set_meta("region", region)
    body.set_meta("owner_dummy", self)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = size
    shape.shape = box
    body.add_child(shape)
    add_child(body)
    _hitboxes.append(body)

func _build_label() -> void:
    _label = Label3D.new()
    _label.text = dummy_name
    _label.position = Vector3(0, 2.05, 0)
    _label.font_size = 28
    _label.outline_size = 6
    _label.outline_modulate = Color(0, 0, 0, 0.85)
    _label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _label.no_depth_test = true
    add_child(_label)

func receive_hit(region: String) -> int:
    if _dead:
        return 0
    var damage := 15
    match region:
        "head":
            damage = 100
        "chest":
            damage = 45
        "stomach":
            damage = 35
        "arm":
            damage = 15
        "leg":
            damage = 20
    health -= damage
    if health <= 0.0:
        _die()
    return damage

func _die() -> void:
    _dead = true
    _fall = 0.0
    _respawn_timer = 2.2
    for box in _hitboxes:
        box.collision_layer = 0
    if _label != null:
        _label.text = "УБИТ"
        _label.modulate = Color(1.0, 0.35, 0.30)

func _process(delta: float) -> void:
    if _dead:
        _fall = minf(1.0, _fall + delta * 2.4)
        _pivot.rotation.x = -PI * 0.5 * _fall
        _respawn_timer -= delta
        if _respawn_timer <= 0.0:
            _respawn()
        return
    _pivot.rotation.x = 0.0
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player != null:
        set_look_at_player(player, delta)

func set_look_at_player(player: Node3D, delta: float) -> void:
    var target := player.global_position
    target.y = global_position.y
    var to := target - global_position
    if to.length() < 0.15:
        return
    var target_yaw := atan2(-to.x, -to.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 2.0, 0.0, 1.0))

func _respawn() -> void:
    _dead = false
    health = 100.0
    _pivot.rotation.x = 0.0
    for box in _hitboxes:
        box.collision_layer = 2
    if _label != null:
        _label.text = dummy_name
        _label.modulate = Color(1, 1, 1)
