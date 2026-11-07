extends CharacterBody3D

const MOBILE_CONTROLS = preload("res://scripts/mobile_controls.gd")
const CROSSHAIR = preload("res://scripts/crosshair.gd")

const SFX_SHOT = preload("res://assets/audio/shot.wav")
const SFX_EMPTY = preload("res://assets/audio/empty.ogg")
const SFX_RELOAD_OUT = preload("res://assets/audio/reload_out.ogg")
const SFX_RELOAD_IN = preload("res://assets/audio/reload_in.wav")
const SFX_HIT = preload("res://assets/audio/hit_flesh.ogg")
const SFX_METAL = preload("res://assets/audio/hit_metal.ogg")
const SFX_KILL = preload("res://assets/audio/kill.ogg")
const SFX_UI = preload("res://assets/audio/ui_click.ogg")
const SFX_FOOTSTEPS = [
    preload("res://assets/audio/footstep_000.ogg"),
    preload("res://assets/audio/footstep_001.ogg"),
    preload("res://assets/audio/footstep_002.ogg"),
]

const MOUSE_SENS := 0.0022
const TOUCH_SENS := 0.0030
const SPEED := 5.2
const SPRINT_SPEED := 7.4
const JUMP_VELOCITY := 5.4
const MAG_SIZE := 30
const RESERVE_START := 120
const RELOAD_TIME := 2.2
const FIRE_INTERVAL := 0.10

var camera: Camera3D
var player_capsule: CapsuleShape3D
var player_collision: CollisionShape3D
var weapon_root: Node3D
var weapon_base := Vector3.ZERO
var weapon_aim_position := Vector3(0.0, -0.095, -0.68)
var muzzle_flash: MeshInstance3D
var muzzle_flash_time := 0.0
var weapon_kick := 0.0
var bob_time := 0.0
var breathing_time := 0.0
var aim_blend := 0.0
var aiming := false
var look_sway := Vector2.ZERO

# Перспективный viewmodel: правая рука на рукоятке, левая — на цевье.
var left_arm_pivot: Node3D
var left_arm_base := Vector3.ZERO
var detail_texture: Texture2D

var pitch := 0.0
var yaw := 0.0
var recoil := Vector2.ZERO
var stance := 0
var fire_cooldown := 0.0
var ammo := MAG_SIZE
var reserve_ammo := RESERVE_START
var is_reloading := false
var reload_timer := 0.0

var hud: CanvasLayer
var ammo_label: Label
var notice_label: Label
var crosshair
var notice_timer := 0.0

var mobile_controls
var mobile_move := Vector2.ZERO
var mobile_fire := false
var sprint_hold := 0.0

var sfx_shot: AudioStreamPlayer
var sfx_empty: AudioStreamPlayer
var sfx_reload_out: AudioStreamPlayer
var sfx_reload_in: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_metal: AudioStreamPlayer
var sfx_kill: AudioStreamPlayer
var sfx_ui: AudioStreamPlayer
var sfx_footstep: AudioStreamPlayer
var footstep_timer := 0.0

func _ready() -> void:
    add_to_group("player")
    floor_snap_length = 0.25
    floor_max_angle = deg_to_rad(48.0)
    _build_player()
    _build_weapon()
    _build_audio()
    _build_mobile_controls()
    _build_hud()
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _apply_look()

func _build_player() -> void:
    player_collision = CollisionShape3D.new()
    player_capsule = CapsuleShape3D.new()
    player_capsule.radius = 0.34
    player_capsule.height = 1.95
    player_collision.shape = player_capsule
    player_collision.position.y = 0.975
    add_child(player_collision)
    camera = Camera3D.new()
    camera.position = Vector3(0, 1.78, 0)
    camera.fov = 75.0
    camera.current = true
    add_child(camera)

func _build_weapon() -> void:
    weapon_root = Node3D.new()
    weapon_root.name = "ViewModel"
    weapon_root.position = Vector3(0.15, -0.19, -0.64)
    weapon_root.scale = Vector3.ONE * 0.68
    weapon_base = weapon_root.position
    camera.add_child(weapon_root)

    var packed = load("res://assets/models/ak47/ak47_lowpoly.glb")
    var muzzle_anchor: Node3D = weapon_root
    if packed != null:
        var ak = packed.instantiate()
        ak.rotation.y = PI  # ствол модели смотрит в +Z, в Godot вперёд — -Z
        weapon_root.add_child(ak)
        _tune_ak_materials(ak)
        var muzzle_node = ak.find_child("Muzzle", true, false)
        if muzzle_node is Node3D:
            muzzle_anchor = muzzle_node
    else:
        push_error("FRONTLINE: cannot load AK-47 model")
        var fallback := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(0.10, 0.13, 0.66)
        fallback.mesh = box
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color(0.14, 0.12, 0.09)
        fallback.material_override = mat
        weapon_root.add_child(fallback)

    muzzle_flash = MeshInstance3D.new()
    var flash_mesh := SphereMesh.new()
    flash_mesh.radius = 0.055
    flash_mesh.height = 0.11
    muzzle_flash.mesh = flash_mesh
    var flash_mat := StandardMaterial3D.new()
    flash_mat.albedo_color = Color(1.0, 0.75, 0.25)
    flash_mat.emission_enabled = true
    flash_mat.emission = Color(1.0, 0.55, 0.12)
    flash_mat.emission_energy_multiplier = 5.0
    flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    muzzle_flash.material_override = flash_mat
    muzzle_flash.position = Vector3.ZERO
    muzzle_flash.visible = false
    muzzle_anchor.add_child(muzzle_flash)
    _build_view_hands()

func _tune_ak_materials(root: Node) -> void:
    for mi in root.find_children("*", "MeshInstance3D", true, false):
        if mi.mesh == null:
            continue
        for s in range(mi.mesh.get_surface_count()):
            var mat = mi.mesh.surface_get_material(s)
            if mat is StandardMaterial3D:
                var m: StandardMaterial3D = mat.duplicate()
                var c: Color = m.albedo_color
                if c.get_luminance() > 0.45:
                    # Дерево: приклад и цевьё.
                    m.albedo_color = Color(0.40, 0.235, 0.105)
                    m.metallic = 0.05
                    m.roughness = 0.58
                elif c.get_luminance() < 0.34:
                    # Воронёная сталь.
                    m.albedo_color = Color(0.135, 0.145, 0.155)
                    m.metallic = 0.55
                    m.roughness = 0.42
                else:
                    m.metallic = 0.35
                    m.roughness = 0.50
                m.cull_mode = BaseMaterial3D.CULL_DISABLED
                mi.mesh.surface_set_material(s, m)

func _make_detail_texture() -> Texture2D:
    var noise := FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.055
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
        Color(0.78, 0.78, 0.78), Color(0.92, 0.92, 0.92), Color(1, 1, 1)])
    tex.color_ramp = ramp
    return tex

func _vm_material(color: Color, roughness := 0.95, metallic := 0.0, textured := true) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    mat.metallic = metallic
    if textured:
        if detail_texture == null:
            detail_texture = _make_detail_texture()
        mat.albedo_texture = detail_texture
        mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    return mat

func _vm_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
    var inst := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    inst.mesh = mesh
    inst.material_override = mat
    inst.position = pos
    inst.rotation = rot
    inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(inst)
    return inst

func _vm_limb(parent: Node3D, a: Vector3, b: Vector3, r_a: float, r_b: float, mat: Material) -> MeshInstance3D:
    var inst := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = r_b
    mesh.bottom_radius = r_a
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 10
    mesh.rings = 1
    inst.mesh = mesh
    inst.material_override = mat
    inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    inst.position = (a + b) * 0.5
    var dir := (b - a).normalized()
    if dir.length_squared() > 0.001:
        inst.basis = Basis(Quaternion(Vector3.UP, dir))
    parent.add_child(inst)
    return inst

func _build_view_hands() -> void:
    var team := str(get_tree().get_meta("selected_team", "IRON LEGION"))
    var sleeve_color := Color(0.22, 0.24, 0.20)
    if team.to_upper().contains("RED"):
        sleeve_color = Color(0.24, 0.27, 0.17)

    var glove := _vm_material(Color(0.155, 0.105, 0.068), 0.88)
    var glove_pad := _vm_material(Color(0.235, 0.175, 0.115), 0.85)
    var sleeve := _vm_material(sleeve_color, 1.0)
    var cuff := _vm_material(Color(0.12, 0.12, 0.10), 0.95)

    # --- Правая рука на рукоятке -----------------------------------------
    _vm_box(weapon_root, Vector3(0.025, -0.105, 0.012), Vector3(0.070, 0.095, 0.075), glove, Vector3(0.16, 0.0, -0.10))
    # Пальцы, обхватывающие рукоятку спереди.
    for i in range(4):
        _vm_box(weapon_root,
            Vector3(-0.010, -0.078 - 0.021 * i, -0.032),
            Vector3(0.068, 0.018, 0.034), glove)
    # Большой палец с внутренней стороны.
    _vm_box(weapon_root, Vector3(-0.035, -0.075, 0.030), Vector3(0.024, 0.055, 0.026), glove, Vector3(0.25, 0.0, 0.15))
    # Костяшки/накладка на тыльной стороне кисти.
    _vm_box(weapon_root, Vector3(0.064, -0.115, 0.012), Vector3(0.014, 0.068, 0.058), glove_pad)
    var r_wrist := Vector3(0.035, -0.125, 0.035)
    var r_elbow := Vector3(0.165, -0.390, 0.105)
    _vm_limb(weapon_root, r_wrist, r_wrist.lerp(r_elbow, 0.14), 0.047, 0.050, cuff)
    _vm_limb(weapon_root, r_wrist.lerp(r_elbow, 0.12), r_elbow, 0.046, 0.062, sleeve)
    _vm_limb(weapon_root, r_elbow, r_elbow.lerp(r_wrist, 0.22), 0.062, 0.064, sleeve)

    # --- Левая рука на цевье ---------------------------------------------
    left_arm_pivot = Node3D.new()
    left_arm_pivot.name = "LeftArm"
    left_arm_pivot.position = Vector3(0.0, 0.0, -0.24)
    left_arm_base = left_arm_pivot.position
    weapon_root.add_child(left_arm_pivot)

    _vm_box(left_arm_pivot, Vector3(-0.045, -0.055, 0.0), Vector3(0.075, 0.055, 0.125), glove, Vector3(-0.10, 0.0, 0.0))
    # Пальцы поверх цевья с дальней стороны.
    for i in range(4):
        _vm_box(left_arm_pivot,
            Vector3(-0.072, -0.010, -0.050 + 0.030 * i),
            Vector3(0.024, 0.072, 0.022), glove)
    # Большой палец снизу-сбоку.
    _vm_box(left_arm_pivot, Vector3(0.002, -0.052, 0.018), Vector3(0.022, 0.045, 0.042), glove, Vector3(0.0, 0.0, -0.35))
    # Накладка на тыльной стороне ладони.
    _vm_box(left_arm_pivot, Vector3(-0.086, -0.076, -0.006), Vector3(0.018, 0.032, 0.092), glove_pad)
    var l_wrist := Vector3(-0.055, -0.085, -0.004)
    var l_elbow := Vector3(-0.170, -0.390, 0.095)
    _vm_limb(left_arm_pivot, l_wrist, l_wrist.lerp(l_elbow, 0.14), 0.045, 0.048, cuff)
    _vm_limb(left_arm_pivot, l_wrist.lerp(l_elbow, 0.12), l_elbow, 0.044, 0.060, sleeve)
    _vm_limb(left_arm_pivot, l_elbow, l_elbow.lerp(l_wrist, 0.22), 0.060, 0.062, sleeve)

func _set_aiming(enabled: bool) -> void:
    if aiming == enabled:
        return
    aiming = enabled

func _build_audio() -> void:
    sfx_shot = _make_sfx()
    sfx_empty = _make_sfx()
    sfx_reload_out = _make_sfx()
    sfx_reload_in = _make_sfx()
    sfx_hit = _make_sfx()
    sfx_metal = _make_sfx()
    sfx_kill = _make_sfx()
    sfx_ui = _make_sfx()
    sfx_footstep = _make_sfx()

func _make_sfx() -> AudioStreamPlayer:
    var p := AudioStreamPlayer.new()
    p.max_polyphony = 4
    add_child(p)
    return p

func _play_sfx(player: AudioStreamPlayer, stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
    if player == null or stream == null:
        return
    player.stream = stream
    player.volume_db = volume_db
    player.pitch_scale = pitch
    player.play()

func _build_mobile_controls() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 20
    add_child(layer)
    mobile_controls = MOBILE_CONTROLS.new()
    layer.add_child(mobile_controls)
    mobile_controls.move_changed.connect(_on_move_changed)
    mobile_controls.look_delta.connect(_on_look_delta)
    mobile_controls.fire_changed.connect(_on_fire_changed)
    mobile_controls.aim_changed.connect(_set_aiming)
    mobile_controls.reload_pressed.connect(_reload)
    mobile_controls.stance_down_pressed.connect(_down_action)
    mobile_controls.stance_up_pressed.connect(_up_action)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    hud.layer = 10
    add_child(hud)
    crosshair = CROSSHAIR.new()
    hud.add_child(crosshair)
    ammo_label = Label.new()
    ammo_label.anchor_left = 1.0
    ammo_label.anchor_right = 1.0
    ammo_label.anchor_top = 1.0
    ammo_label.anchor_bottom = 1.0
    ammo_label.offset_left = -310.0
    ammo_label.offset_right = -24.0
    ammo_label.offset_top = -238.0
    ammo_label.offset_bottom = -200.0
    ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    ammo_label.add_theme_font_size_override("font_size", 24)
    ammo_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
    ammo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
    ammo_label.add_theme_constant_override("shadow_offset_x", 2)
    ammo_label.add_theme_constant_override("shadow_offset_y", 2)
    hud.add_child(ammo_label)
    notice_label = Label.new()
    notice_label.anchor_left = 0.0
    notice_label.anchor_right = 1.0
    notice_label.offset_left = 0.0
    notice_label.offset_right = 0.0
    notice_label.offset_top = 68.0
    notice_label.offset_bottom = 102.0
    notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    notice_label.add_theme_font_size_override("font_size", 20)
    notice_label.add_theme_color_override("font_color", Color(1, 0.92, 0.65, 1.0))
    notice_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
    notice_label.add_theme_constant_override("shadow_offset_x", 2)
    notice_label.add_theme_constant_override("shadow_offset_y", 2)
    hud.add_child(notice_label)
    _refresh_ammo()

func _on_move_changed(value: Vector2) -> void:
    mobile_move = value

func _on_look_delta(delta: Vector2) -> void:
    yaw -= delta.x * TOUCH_SENS
    pitch = clampf(pitch - delta.y * TOUCH_SENS, -1.35, 1.35)
    look_sway += Vector2(delta.x, delta.y) * 0.00006
    look_sway = look_sway.limit_length(0.035)

func _on_fire_changed(pressed: bool) -> void:
    mobile_fire = pressed

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * MOUSE_SENS
        pitch = clampf(pitch - event.relative.y * MOUSE_SENS, -1.35, 1.35)
        look_sway += Vector2(event.relative.x, event.relative.y) * 0.00006
        look_sway = look_sway.limit_length(0.035)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not OS.has_feature("mobile"):
        _shoot()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
        _set_aiming(event.pressed)
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R:
            _reload()
        elif event.keycode == KEY_C:
            _down_action()
        elif event.keycode == KEY_SPACE:
            _up_action()
        elif event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    weapon_kick = lerpf(weapon_kick, 0.0, clampf(delta * 14.0, 0.0, 1.0))
    var blend := 1.0 - exp(-delta * 13.0)
    aim_blend = lerpf(aim_blend, 1.0 if aiming else 0.0, blend)
    var planar_speed := Vector2(velocity.x, velocity.z).length()
    if planar_speed > 0.4 and is_on_floor():
        bob_time += delta * (6.0 + planar_speed * 0.7)
    breathing_time += delta * 1.35
    var bob_amount := clampf(planar_speed / SPEED, 0.0, 1.2)
    var bob := Vector3(sin(bob_time) * 0.010, absf(cos(bob_time)) * 0.008, 0.0) * bob_amount
    var base_position := weapon_base.lerp(weapon_aim_position, aim_blend)
    var reload_phase := 0.0
    if is_reloading:
        reload_phase = sin((1.0 - reload_timer / RELOAD_TIME) * PI)
    var sway := Vector3(look_sway.x, -look_sway.y, 0.0)
    var breathing := sin(breathing_time) * 0.0025 * (1.0 - aim_blend * 0.5)
    var weapon_target := base_position + bob + Vector3(0.0, breathing + weapon_kick * 0.20 - reload_phase * 0.10, weapon_kick * 0.75)
    weapon_root.position = weapon_root.position.lerp(weapon_target, blend)
    var hip_yaw := 0.030 * (1.0 - aim_blend)
    var weapon_rotation_target := Vector3(weapon_kick * 0.9 - reload_phase * 0.24, sway.x * 0.45 + hip_yaw, sway.y * 0.5 + reload_phase * 0.18)
    weapon_root.rotation = weapon_root.rotation.lerp(weapon_rotation_target, blend)
    camera.fov = lerpf(camera.fov, 75.0 - 23.0 * aim_blend, blend)
    look_sway = look_sway.lerp(Vector2.ZERO, clampf(delta * 5.5, 0.0, 1.0))
    if left_arm_pivot != null:
        var left_target := left_arm_base + Vector3(0.0, -0.14 * reload_phase, 0.14 * reload_phase)
        left_arm_pivot.position = left_arm_pivot.position.lerp(left_target, blend)
        left_arm_pivot.rotation = left_arm_pivot.rotation.lerp(Vector3(-0.35 * reload_phase, 0.0, 0.22 * reload_phase), blend)

    # Шаги: частота зависит от скорости, звук — случайный из трёх вариантов.
    if planar_speed > 0.6 and is_on_floor():
        footstep_timer -= delta
        if footstep_timer <= 0.0:
            var step_index := randi() % SFX_FOOTSTEPS.size()
            _play_sfx(sfx_footstep, SFX_FOOTSTEPS[step_index], -13.0, randf_range(0.92, 1.08))
            footstep_timer = clampf(0.66 - planar_speed * 0.05, 0.26, 0.62)
    else:
        footstep_timer = 0.12
    if muzzle_flash_time > 0.0:
        muzzle_flash_time -= delta
        if muzzle_flash_time <= 0.0:
            muzzle_flash.visible = false

    if is_reloading:
        reload_timer -= delta
        if reload_timer <= 0.0:
            var need := MAG_SIZE - ammo
            var take := mini(need, reserve_ammo)
            ammo += take
            reserve_ammo -= take
            is_reloading = false
            _play_sfx(sfx_reload_in, SFX_RELOAD_IN, -4.0, 1.0)
            _set_notice("ПЕРЕЗАРЯЖЕНО", 1.2)
            _refresh_ammo()

    if notice_timer > 0.0:
        notice_timer -= delta
        if notice_timer <= 0.0:
            notice_label.text = ""

    if mobile_fire or (not OS.has_feature("mobile") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
        _shoot()

    var input_vec := mobile_move
    input_vec.x += float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
    input_vec.y += float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
    input_vec = input_vec.limit_length(1.0)

    if stance == 0 and input_vec.length() > 0.92:
        sprint_hold += delta
    else:
        sprint_hold = 0.0

    var current_speed := SPEED
    if (Input.is_key_pressed(KEY_SHIFT) or sprint_hold > 0.7) and stance == 0:
        current_speed = SPRINT_SPEED
    if stance == 1:
        current_speed *= 0.55
    elif stance == 2:
        current_speed *= 0.25

    var direction := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
    velocity.x = direction.x * current_speed
    velocity.z = direction.z * current_speed
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    elif Input.is_key_pressed(KEY_SPACE) and stance == 0:
        velocity.y = JUMP_VELOCITY
    move_and_slide()

    recoil = recoil.lerp(Vector2.ZERO, clampf(delta * 7.0, 0.0, 1.0))
    var target_height := 1.95 if stance == 0 else (1.35 if stance == 1 else 0.70)
    player_capsule.height = lerpf(player_capsule.height, target_height, clampf(delta * 10.0, 0.0, 1.0))
    player_collision.position.y = player_capsule.height * 0.5
    var target_y := 1.78 if stance == 0 else (1.20 if stance == 1 else 0.52)
    camera.position.y = lerpf(camera.position.y, target_y, delta * 10.0)
    _apply_look()

func _apply_look() -> void:
    rotation.y = yaw
    camera.rotation = Vector3(
        clampf(pitch + recoil.y, -1.45, 1.45),
        recoil.x,
        0.0
    )

func _down_action() -> void:
    _play_sfx(sfx_ui, SFX_UI, -8.0, randf_range(0.96, 1.04))
    stance = mini(2, stance + 1)
    _update_stance()

func _up_action() -> void:
    _play_sfx(sfx_ui, SFX_UI, -8.0, randf_range(0.96, 1.04))
    if stance > 0:
        stance -= 1
        _update_stance()
    elif is_on_floor():
        velocity.y = JUMP_VELOCITY

func _update_stance() -> void:
    _set_notice(["СТОЯ", "ПРИСЕЛ", "ЛЁЖА"][stance], 1.2)

func _shoot() -> void:
    if is_reloading or fire_cooldown > 0.0:
        return
    if ammo <= 0:
        _play_sfx(sfx_empty, SFX_EMPTY, -5.0, randf_range(0.95, 1.05))
        fire_cooldown = 0.25
        _set_notice("НЕТ ПАТРОНОВ — ПЕРЕЗАРЯДКА", 1.4)
        return
    ammo -= 1
    fire_cooldown = FIRE_INTERVAL
    _refresh_ammo()
    _play_sfx(sfx_shot, SFX_SHOT, -2.0, randf_range(0.94, 1.06))
    # Отдача: подброс вверх + лёгкий горизонтальный разброс.
    recoil.y = minf(recoil.y + randf_range(0.009, 0.015), 0.13)
    recoil.x = clampf(recoil.x + randf_range(-0.006, 0.006), -0.045, 0.045)
    weapon_kick = 0.07
    muzzle_flash.visible = true
    muzzle_flash_time = 0.045
    _apply_look()

    var spread := 0.0
    if stance == 0 and (mobile_move.length() > 0.2 or velocity.length() > SPEED + 0.5):
        spread = 0.012
    var dir := -camera.global_transform.basis.z
    dir = dir.rotated(camera.global_transform.basis.y, randf_range(-spread, spread))
    dir = dir.rotated(camera.global_transform.basis.x, randf_range(-spread, spread))
    var from := camera.global_position
    var to := from + dir * 120.0
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit:
        var body = hit.collider
        if body.is_in_group("damageable"):
            var region := str(body.get_meta("region", "chest"))
            var dummy = body.get_meta("owner_dummy")
            var was_alive: bool = dummy.health > 0.0
            var damage: int = dummy.receive_hit(region)
            _play_sfx(sfx_hit, SFX_HIT, -4.0, randf_range(0.92, 1.06))
            _set_notice("ПОПАДАНИЕ: %s  −%d HP" % [region.to_upper(), damage], 1.1)
            if crosshair != null:
                crosshair.flash_hit()
            if was_alive and dummy.health <= 0.0:
                _play_sfx(sfx_kill, SFX_KILL, -3.0, 1.0)
                var world = get_parent()
                if world.has_method("add_kill"):
                    world.add_kill()
        else:
            _play_sfx(sfx_metal, SFX_METAL, -6.0, randf_range(0.94, 1.06))
            _set_notice("ПОПАДАНИЕ В УКРЫТИЕ", 0.8)
    else:
        _set_notice("ПРОМАХ", 0.7)

func _reload() -> void:
    if is_reloading or ammo >= MAG_SIZE or reserve_ammo <= 0:
        return
    is_reloading = true
    reload_timer = RELOAD_TIME
    _play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -6.0, 1.0)
    _set_notice("ПЕРЕЗАРЯДКА...", RELOAD_TIME)

func _refresh_ammo() -> void:
    ammo_label.text = "AK-47   %d / %d" % [ammo, reserve_ammo]

func _set_notice(text: String, time: float = 1.5) -> void:
    notice_label.text = text
    notice_timer = time
