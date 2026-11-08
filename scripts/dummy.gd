extends Node3D

const PROCEDURAL = preload("res://scripts/procedural_soldier.gd")
const BLOCK_RIG_BUILDER = preload("res://scripts/block_rig_builder.gd")
const TACTICAL_GEAR = preload("res://scripts/tactical_gear.gd")
const IRON_SCENE := "res://assets/models/soldiers/FRONTLINE_German_Grey_Block_Soldier.glb"
const RED_SCENE := "res://assets/models/soldiers/FRONTLINE_Soviet_Khaki_Block_Soldier.glb"
const SFX_SHOT = preload("res://assets/audio/shot.wav")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")

# Новые статичные GLB имеют origin у ступней и высоту около 1.94 м.
const MODEL_LIFT := 0.0
const MODEL_SCALE := 1.0
const PRONE_Y := 0.14
const HIP_HEIGHT := 0.875

static var _merged_mesh_cache: Dictionary = {}
static var _normal_mesh_cache: Dictionary = {}
static var _detail_texture: Texture2D

var team_name := "IRON LEGION"
var team_color := Color(0.28, 0.30, 0.32)
var dummy_name := "TARGET"
var health := 100.0

# Настройки поведения (задаются до add_child из polygon.gd).
var stance := "stand"
var patrol_axis := Vector3.ZERO
var patrol_range := 0.0
var patrol_speed := 1.0
var shooting := false
var shoot_target := Vector3.ZERO

var _pivot: Node3D
var _visual: Node3D
var _proc
var _label: Label3D
var _hitboxes: Array[StaticBody3D] = []
var _dead := false
var _fall := 0.0
var _respawn_timer := 0.0

var _base_position := Vector3.ZERO
var _patrol_time := 0.0
var _patrol_active := false

var _gun_pivot: Node3D
var _gun_muzzle: Node3D
var _muzzle_flash: MeshInstance3D
var _flash_time := 0.0
var _tracer: MeshInstance3D
var _tracer_time := 0.0
var _impact_flash: MeshInstance3D
var _impact_time := 0.0
var _shoot_timer := 0.0
var _firing_time := 0.0
var _idle_time := 0.0
var shots_fired := 0
var _sfx: AudioStreamPlayer3D

func _ready() -> void:
    add_to_group("training_dummy")
    _base_position = position
    _build_visual()
    _apply_stance()
    _build_hitboxes()
    _build_label()
    _build_gun()
    if shooting:
        _build_audio()
        _shoot_timer = randf_range(0.6, 2.2)
    _patrol_active = patrol_range > 0.01 and patrol_axis.length() > 0.01
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player != null and not shooting:
        _face_position(player.global_position, 1.0)
    # Статичным мишеням не нужно обновляться каждый кадр. Поворачиваемся к
    # игроку отложенно, потому что игрок создаётся после манекенов.
    if not _patrol_active and not shooting:
        _settle_static.call_deferred()

func _settle_static() -> void:
    var player := get_tree().get_first_node_in_group("player") as Node3D
    if player != null:
        _face_position(player.global_position, 1.0)
    # Оставляем process включённым: статичные манекены должны дышать,
    # поворачивать голову и шевелиться в сидячей/лежачей позе.

func _build_visual() -> void:
    _pivot = Node3D.new()
    add_child(_pivot)

    _visual = Node3D.new()
    _visual.position.y = MODEL_LIFT
    _visual.scale = Vector3.ONE * MODEL_SCALE
    _visual.rotation.y = PI  # модель смотрит в +Z, в Godot перед — это -Z

    var path := RED_SCENE if team_name.to_upper().contains("RED") else IRON_SCENE
    var packed = load(path)
    if packed == null:
        push_error("FRONTLINE: cannot load soldier model " + path)
        return
    var model = packed.instantiate()
    _prepare_model(model, path)
    var has_rig := model.find_child("Skeleton3D", true, false) is Skeleton3D
    _visual.add_child(model)
    if has_rig:
        _visual.set_script(PROCEDURAL)
    _pivot.add_child(_visual)
    if has_rig:
        _proc = _visual
        # Все манекены держат автомат: руки подняты к оружию, даже в патруле.
        _proc.set_t_pose_arms(false)
        _proc.set_aiming(true)
        _proc.set_motion(0.0, false)
        _proc.set_look(0.0, 0.0)

func _apply_stance() -> void:
    if _visual == null:
        return
    var crouch := false
    var sit := false
    _visual.rotation.x = 0.0
    match stance:
        "crouch":
            crouch = true
            _visual.position.y = MODEL_LIFT
        "sit":
            sit = true
            _visual.position.y = MODEL_LIFT
        "prone":
            # Лицом вниз, головой вперёд (в локальную -Z, как и оружие).
            # Блочная модель имеет origin у ступней, поэтому при повороте
            # компенсируем высоту таза, чтобы корпус лёг вокруг бёдер.
            _visual.rotation.x = PI * 0.5
            _visual.position = Vector3(0.0, PRONE_Y, HIP_HEIGHT)
        _:
            _visual.position = Vector3(0.0, MODEL_LIFT, 0.0)
    if _proc != null:
        _proc.set_crouching(crouch)
        _proc.set_sitting(sit)
        _proc.set_prone(stance == "prone")

func _build_hitboxes() -> void:
    var boxes: Array = []
    match stance:
        "crouch":
            boxes = [
                [Vector3(0, 1.52, 0), Vector3(0.40, 0.40, 0.40), "head"],
                [Vector3(0, 1.10, 0), Vector3(0.55, 0.48, 0.36), "chest"],
                [Vector3(0, 0.77, 0), Vector3(0.48, 0.28, 0.34), "stomach"],
                [Vector3(-0.35, 1.01, 0), Vector3(0.20, 0.56, 0.25), "arm"],
                [Vector3(0.35, 1.01, 0), Vector3(0.20, 0.56, 0.25), "arm"],
                [Vector3(-0.17, 0.36, 0), Vector3(0.29, 0.72, 0.32), "leg"],
                [Vector3(0.17, 0.36, 0), Vector3(0.29, 0.72, 0.32), "leg"],
            ]
        "sit":
            boxes = [
                [Vector3(0, 1.31, 0), Vector3(0.40, 0.40, 0.40), "head"],
                [Vector3(0, 0.84, 0), Vector3(0.55, 0.48, 0.36), "chest"],
                [Vector3(0, 0.53, 0), Vector3(0.48, 0.26, 0.34), "stomach"],
                [Vector3(-0.35, 0.80, -0.30), Vector3(0.20, 0.44, 0.60), "arm"],
                [Vector3(0.35, 0.80, -0.30), Vector3(0.20, 0.44, 0.60), "arm"],
                [Vector3(-0.17, 0.28, -0.32), Vector3(0.29, 0.40, 0.78), "leg"],
                [Vector3(0.17, 0.28, -0.32), Vector3(0.29, 0.40, 0.78), "leg"],
            ]
        "prone":
            boxes = [
                [Vector3(0, 0.20, -0.94), Vector3(0.44, 0.32, 0.46), "head"],
                [Vector3(0, 0.18, -0.52), Vector3(0.62, 0.32, 0.62), "chest"],
                [Vector3(0, 0.17, -0.12), Vector3(0.52, 0.28, 0.50), "stomach"],
                [Vector3(-0.28, 0.17, -0.95), Vector3(0.22, 0.26, 0.80), "arm"],
                [Vector3(0.28, 0.17, -0.95), Vector3(0.22, 0.26, 0.80), "arm"],
                [Vector3(-0.12, 0.16, 0.36), Vector3(0.28, 0.26, 0.98), "leg"],
                [Vector3(0.12, 0.16, 0.36), Vector3(0.28, 0.26, 0.98), "leg"],
            ]
        _:
            boxes = [
                [Vector3(0, 1.81, 0), Vector3(0.40, 0.40, 0.40), "head"],
                [Vector3(0, 1.34, 0), Vector3(0.55, 0.46, 0.36), "chest"],
                [Vector3(0, 0.99, 0), Vector3(0.48, 0.28, 0.34), "stomach"],
                [Vector3(-0.31, 1.12, 0), Vector3(0.20, 0.64, 0.25), "arm"],
                [Vector3(0.31, 1.12, 0), Vector3(0.20, 0.64, 0.25), "arm"],
                [Vector3(-0.11, 0.45, 0), Vector3(0.29, 0.90, 0.32), "leg"],
                [Vector3(0.11, 0.45, 0), Vector3(0.29, 0.90, 0.32), "leg"],
            ]
    for b in boxes:
        _add_hitbox(b[0], b[1], b[2])

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
    _label.font_size = 30
    _label.outline_size = 6
    _label.outline_modulate = Color(0, 0, 0, 0.85)
    _label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _label.no_depth_test = false
    _label.visibility_range_end = 55.0
    match stance:
        "crouch":
            _label.position = Vector3(0, 1.92, 0)
        "sit":
            _label.position = Vector3(0, 1.60, 0)
        "prone":
            _label.position = Vector3(0, 0.62, -0.70)
        _:
            _label.position = Vector3(0, 2.22, 0)
    add_child(_label)

func _build_gun() -> void:
    _gun_pivot = Node3D.new()
    _gun_pivot.name = "GunPivot"
    var gun_pos := Vector3(0.05, 1.34, -0.55)
    match stance:
        "crouch":
            gun_pos = Vector3(0.05, 1.08, -0.55)
        "sit":
            gun_pos = Vector3(0.05, 0.86, -0.55)
        "prone":
            gun_pos = Vector3(0.05, 0.28, -1.25)
    _gun_pivot.position = gun_pos
    _pivot.add_child(_gun_pivot)

    var gun_root := Node3D.new()
    _gun_pivot.add_child(gun_root)
    var ak_root := Node3D.new()
    ak_root.name = "AK47"
    ak_root.rotation.y = PI
    ak_root.scale = Vector3.ONE * 0.9
    gun_root.add_child(ak_root)
    var ak_mesh := WEAPON_MESHES.ak_mesh()
    if ak_mesh != null:
        var ak_inst := MeshInstance3D.new()
        ak_inst.name = "AK47Mesh"
        ak_inst.mesh = ak_mesh
        ak_root.add_child(ak_inst)

    _gun_muzzle = Node3D.new()
    _gun_muzzle.position = WEAPON_MESHES.MUZZLE_LOCAL
    ak_root.add_child(_gun_muzzle)

    _muzzle_flash = MeshInstance3D.new()
    var flash_mesh := SphereMesh.new()
    flash_mesh.radius = 0.10
    flash_mesh.height = 0.20
    _muzzle_flash.mesh = flash_mesh
    _muzzle_flash.material_override = _emissive(Color(1.0, 0.72, 0.22))
    _muzzle_flash.visible = false
    _gun_muzzle.add_child(_muzzle_flash)

    var dist := _gun_muzzle.global_position.distance_to(shoot_target)
    dist = maxf(dist, 2.0)
    _tracer = MeshInstance3D.new()
    var tracer_mesh := BoxMesh.new()
    tracer_mesh.size = Vector3(0.03, 0.03, dist)
    _tracer.mesh = tracer_mesh
    _tracer.material_override = _emissive(Color(1.0, 0.86, 0.35))
    _tracer.position = Vector3(0, 0, dist * 0.5)
    _tracer.visible = false
    _gun_muzzle.add_child(_tracer)

    _impact_flash = MeshInstance3D.new()
    var impact_mesh := SphereMesh.new()
    impact_mesh.radius = 0.20
    impact_mesh.height = 0.40
    _impact_flash.mesh = impact_mesh
    _impact_flash.material_override = _emissive(Color(1.0, 0.55, 0.18))
    _impact_flash.visible = false
    add_child(_impact_flash)
    _impact_flash.global_position = shoot_target

func _emissive(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 5.0
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat

func _build_audio() -> void:
    _sfx = AudioStreamPlayer3D.new()
    _sfx.stream = SFX_SHOT
    _sfx.volume_db = -13.0
    _sfx.max_distance = 70.0
    _sfx.unit_size = 12.0
    _gun_pivot.add_child(_sfx)

func receive_hit(param1, param2 = Vector3.ZERO, param3 = "", _param4 = "") -> int:
    if _dead:
        return 0
    var damage := 15
    var region := "chest"
    var attacker_pos := Vector3.ZERO
    if param1 is int or param1 is float:
        damage = int(param1)
        attacker_pos = param2 if param2 is Vector3 else Vector3.ZERO
        region = param3 if not param3.is_empty() else "chest"
    else:
        region = str(param1)
        match region:
            "head": damage = 100
            "chest": damage = 45
            "stomach": damage = 35
            "arm": damage = 15
            "leg": damage = 20
    health -= damage
    if health <= 0.0:
        _die(attacker_pos, region == "head")
    return damage

func _die(attacker_pos: Vector3 = Vector3.ZERO, is_headshot: bool = false) -> void:
    _dead = true
    _fall = 0.0
    _respawn_timer = 3.5
    set_process(true)
    for box in _hitboxes:
        box.collision_layer = 0
    if _gun_pivot != null:
        _gun_pivot.visible = false
    if _label != null:
        _label.text = "КИА"
        _label.modulate = Color(1.0, 0.35, 0.30)
    var hit_dir := (global_position - attacker_pos).normalized() if attacker_pos.length_squared() > 0.1 else Vector3.FORWARD
    if _proc != null:
        _proc.set_ragdoll(true, hit_dir, is_headshot)

func _process(delta: float) -> void:
    if _dead:
        _fall = minf(1.0, _fall + delta * 2.4)
        if _pivot != null:
            _pivot.rotation.x = -PI * 0.5 * _fall
        _update_effects(delta)
        _respawn_timer -= delta
        if _respawn_timer <= 0.0:
            _respawn()
        return

    if _pivot != null:
        _pivot.rotation.x = 0.0

    if _patrol_active:
        _patrol_time += delta * patrol_speed
        var offset := sin(_patrol_time) * patrol_range
        position = _base_position + patrol_axis.normalized() * offset
        var velocity := cos(_patrol_time) * patrol_range * patrol_speed
        if _proc != null:
            _proc.set_motion(absf(velocity) * 1.6, false)
    elif _proc != null:
        _proc.set_motion(0.0, false)
        _idle_time += delta
        # Лёгкое «дыхание» и осмотр по сторонам, чтобы статичные позы ожили.
        var yaw_look := sin(_idle_time * 0.35 + float(get_instance_id() % 100) * 0.06) * 0.28
        var pitch_look := sin(_idle_time * 0.21 + 1.7) * 0.05
        _proc.set_look(yaw_look, pitch_look)

    var player := get_tree().get_first_node_in_group("player") as Node3D
    if shooting:
        _aim_at_target(delta)
        _shoot_timer -= delta
        if _shoot_timer <= 0.0:
            _fire()
            _shoot_timer = randf_range(1.6, 2.8)
    elif player != null:
        _face_position(player.global_position, delta)

    _update_effects(delta)

func _face_position(target: Vector3, delta: float) -> void:
    var to := target - global_position
    to.y = 0.0
    if to.length() < 0.15:
        return
    var target_yaw := atan2(-to.x, -to.z)
    rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 3.0, 0.0, 1.0))

func _aim_at_target(delta: float) -> void:
    if _gun_pivot == null:
        return
    _face_position(Vector3(shoot_target.x, global_position.y, shoot_target.z), delta)
    var to := shoot_target - _gun_pivot.global_position
    var horizontal := Vector2(to.x, to.z).length()
    var pitch := atan2(to.y, horizontal)
    _gun_pivot.rotation.x = pitch
    if _proc != null:
        _proc.set_look(0.0, pitch)

func _fire() -> void:
    shots_fired += 1
    if _muzzle_flash != null:
        _muzzle_flash.visible = true
        _flash_time = 0.07
    if _tracer != null:
        _tracer.visible = true
        _tracer_time = 0.05
    if _impact_flash != null:
        _impact_flash.visible = true
        _impact_time = 0.10
    if _proc != null:
        _proc.set_firing(true)
        _firing_time = 0.12
    if _sfx != null:
        _sfx.pitch_scale = randf_range(0.92, 1.05)
        _sfx.play()
    var casing_pos := global_position + Vector3(0, 1.25, 0)
    var eject_dir := global_transform.basis.x * 2.0 + Vector3.UP * 1.4 - global_transform.basis.z * 0.3
    HIT_EFFECTS.spawn_casing(get_parent(), casing_pos, eject_dir)

func _update_effects(delta: float) -> void:
    if _flash_time > 0.0:
        _flash_time -= delta
        if _flash_time <= 0.0 and _muzzle_flash != null:
            _muzzle_flash.visible = false
    if _tracer_time > 0.0:
        _tracer_time -= delta
        if _tracer_time <= 0.0 and _tracer != null:
            _tracer.visible = false
    if _impact_time > 0.0:
        _impact_time -= delta
        if _impact_time <= 0.0 and _impact_flash != null:
            _impact_flash.visible = false
    if _firing_time > 0.0:
        _firing_time -= delta
        if _firing_time <= 0.0 and _proc != null:
            _proc.set_firing(false)

func _respawn() -> void:
    _dead = false
    health = 100.0
    position = _base_position
    _patrol_time = 0.0
    if _pivot != null:
        _pivot.rotation.x = 0.0
    for box in _hitboxes:
        box.collision_layer = 2
    if _gun_pivot != null:
        _gun_pivot.visible = true
    if _label != null:
        _label.text = dummy_name
        _label.modulate = Color(1, 1, 1)
    if _proc != null:
        _proc.set_ragdoll(false)
        _proc.set_firing(false)
        _proc.set_motion(0.0, false)
    if shooting:
        _shoot_timer = randf_range(0.8, 2.0)
    if not _patrol_active and not shooting:
        set_process(false)

func _prepare_model(root: Node, path: String) -> void:
    # Новые блочные GLB собираем на скелет из жёстких сегментов; старые
    # skinned GLB по-прежнему сливаются в один меш для мобильной производительности.
    var skeleton := root.find_child("Skeleton3D", true, false) as Skeleton3D
    if skeleton == null:
        _add_equipment(root, path)
        _fix_normals(root)
        var built := BLOCK_RIG_BUILDER.rig_model(root)
        BLOCK_RIG_BUILDER.merge_rigged_model(built)
        return
    var parts: Array = []
    for child in skeleton.get_children():
        if child is MeshInstance3D:
            parts.append(child)
    if parts.is_empty():
        return
    var skin: Skin = parts[0].skin
    var merged: ArrayMesh = _merged_mesh_cache.get(path)
    if merged == null:
        merged = _merge_meshes(parts)
        _merged_mesh_cache[path] = merged
    for part in parts:
        skeleton.remove_child(part)
        part.queue_free()
    var inst := MeshInstance3D.new()
    inst.name = "MergedSoldier"
    inst.mesh = merged
    inst.skin = skin
    inst.skeleton = NodePath("..")
    skeleton.add_child(inst)

func _merge_meshes(parts: Array) -> ArrayMesh:
    var verts := PackedVector3Array()
    var normals := PackedVector3Array()
    var colors := PackedColorArray()
    var bones := PackedInt32Array()
    var weights := PackedFloat32Array()
    var has_skin_data := false
    for part in parts:
        var src: Mesh = part.mesh
        if src == null:
            continue
        for surf in range(src.get_surface_count()):
            # Исходный меш без NORMAL: разворачиваем индексы и генерируем
            # плоские нормали (низкополигональный вид сохраняется).
            var st := SurfaceTool.new()
            st.create_from(src, surf)
            st.deindex()
            st.generate_normals()
            var tmp: ArrayMesh = st.commit()
            if tmp == null or tmp.get_surface_count() == 0:
                continue
            var arrays: Array = tmp.surface_get_arrays(0)
            var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            if v.is_empty() or n.size() != v.size():
                continue
            var color := Color(0.66, 0.66, 0.66)
            var mat = src.surface_get_material(surf)
            if mat is StandardMaterial3D:
                color = mat.albedo_color
            verts.append_array(v)
            normals.append_array(n)
            for _i in range(v.size()):
                colors.append(color)
            var b = arrays[Mesh.ARRAY_BONES]
            var w = arrays[Mesh.ARRAY_WEIGHTS]
            if b != null and w != null and b.size() == v.size() * 4 and w.size() == v.size() * 4:
                bones.append_array(b)
                weights.append_array(w)
                has_skin_data = true
    var out := ArrayMesh.new()
    if verts.is_empty():
        return out
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_COLOR] = colors
    if has_skin_data:
        arrays[Mesh.ARRAY_BONES] = bones
        arrays[Mesh.ARRAY_WEIGHTS] = weights
    out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color.WHITE
    mat.vertex_color_use_as_albedo = true
    mat.vertex_color_is_srgb = true
    mat.roughness = 0.95
    # Лёгкая тканевая/металлическая фактура, чтобы плоские vertex-цвета не
    # выглядели «пластиковыми». Трипланарное проецирование не требует UV.
    if _detail_texture == null:
        _detail_texture = _make_detail_texture()
    mat.albedo_texture = _detail_texture
    mat.uv1_triplanar = true
    mat.uv1_scale = Vector3(1.7, 1.7, 1.7)
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    out.surface_set_material(0, mat)
    return out

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

func _add_equipment(root: Node3D, model_path: String) -> void:
    var is_red := model_path.to_upper().contains("SOVIET") or team_name.to_upper().contains("RED")
    TACTICAL_GEAR.add_tactical_loadout(root, is_red, true)

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
