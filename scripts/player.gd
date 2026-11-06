extends CharacterBody3D

const SPEED := 5.2
const SPRINT_SPEED := 7.4
const JUMP_VELOCITY := 5.4
const MOUSE_SENS := 0.0022
var camera: Camera3D
var pitch := 0.0
var yaw := 0.0
var stance := 0 # 0 standing, 1 crouched, 2 prone
var fire_cooldown := 0.0
var ammo := 71
var reserve_ammo := 213
var is_reloading := false
var reload_timer := 0.0
var hud: CanvasLayer
var ammo_label: Label
var notice_label: Label
var touch_move := Vector2.ZERO
var fire_touch := false
var look_touch := Vector2.ZERO
var mobile_move := Vector2.ZERO
var mobile_look := Vector2.ZERO
var mobile_buttons := {}

func _ready() -> void:
    _build_player()
    _build_mobile_controls()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_player() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    collision.shape = capsule
    add_child(collision)
    camera = Camera3D.new()
    camera.position = Vector3(0,1.48,0)
    camera.current = true
    add_child(camera)
    # Simple first-person PPSh model
    var gun := MeshInstance3D.new()
    var gun_mesh := BoxMesh.new()
    gun_mesh.size = Vector3(0.16,0.18,0.72)
    gun.mesh = gun_mesh
    gun.position = Vector3(0.28,-0.25,-0.55)
    var gun_mat := StandardMaterial3D.new()
    gun_mat.albedo_color = Color(0.16,0.13,0.1)
    gun.material_override = gun_mat
    camera.add_child(gun)
    var barrel := MeshInstance3D.new()
    var barrel_mesh := CylinderMesh.new()
    barrel_mesh.top_radius = 0.035
    barrel_mesh.bottom_radius = 0.035
    barrel_mesh.height = 0.5
    barrel.mesh = barrel_mesh
    barrel.rotation_degrees.x = 90
    barrel.position = Vector3(0.28,-0.2,-1.08)
    barrel.material_override = gun_mat
    camera.add_child(barrel)

func _build_mobile_controls() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    ammo_label = Label.new()
    ammo_label.position = Vector2(18, 18)
    ammo_label.add_theme_font_size_override("font_size", 22)
    hud.add_child(ammo_label)
    notice_label = Label.new()
    notice_label.position = Vector2(18, 52)
    notice_label.add_theme_font_size_override("font_size", 18)
    hud.add_child(notice_label)
    _make_button("ОГОНЬ", Vector2(-165,-150), Vector2(135,90), func(): _shoot())
    _make_button("ПЕРЕЗАРЯДКА", Vector2(-165,-250), Vector2(135,48), func(): _reload())
    _make_button("ВВЕРХ", Vector2(-315,-150), Vector2(105,48), func(): _up_action())
    _make_button("ВНИЗ", Vector2(-315,-95), Vector2(105,48), func(): _down_action())
    _make_hold_button("W", Vector2(25,-165), Vector2(58,48), Vector2(0,-1), true)
    _make_hold_button("A", Vector2(0,-110), Vector2(58,48), Vector2(-1,0), true)
    _make_hold_button("S", Vector2(25,-55), Vector2(58,48), Vector2(0,1), true)
    _make_hold_button("D", Vector2(85,-110), Vector2(58,48), Vector2(1,0), true)
    _make_hold_button("◀", Vector2(-460,-110), Vector2(55,48), Vector2(-1,0), false)
    _make_hold_button("▶", Vector2(-400,-110), Vector2(55,48), Vector2(1,0), false)
    _make_hold_button("▲", Vector2(-430,-165), Vector2(55,48), Vector2(0,-1), false)
    _make_hold_button("▼", Vector2(-430,-55), Vector2(55,48), Vector2(0,1), false)

func _make_button(text: String, offset: Vector2, size: Vector2, action: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.size = size
    b.anchor_left = 1.0
    b.anchor_right = 1.0
    b.anchor_top = 1.0
    b.anchor_bottom = 1.0
    b.position = offset
    b.pressed.connect(action)
    hud.add_child(b)

func _make_hold_button(text: String, offset: Vector2, size: Vector2, direction: Vector2, is_move: bool) -> void:
    var b := Button.new()
    b.text = text
    b.size = size
    b.anchor_left = 0.0 if offset.x >= 0 else 1.0
    b.anchor_right = 0.0 if offset.x >= 0 else 1.0
    b.anchor_top = 1.0
    b.anchor_bottom = 1.0
    b.position = offset
    b.button_down.connect(func(): _set_mobile_direction(is_move, direction))
    b.button_up.connect(func(): _set_mobile_direction(is_move, Vector2.ZERO))
    hud.add_child(b)

func _set_mobile_direction(is_move: bool, direction: Vector2) -> void:
    if is_move:
        mobile_move = direction
    else:
        mobile_look = direction

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * MOUSE_SENS
        pitch = clamp(pitch - event.relative.y * MOUSE_SENS, -1.35, 1.35)
        rotation.y = yaw
        camera.rotation.x = pitch
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _shoot()
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            pass
    elif event is InputEventKey and event.pressed:
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
    if is_reloading:
        reload_timer -= delta
        if reload_timer <= 0:
            var need := 71 - ammo
            var take := mini(need, reserve_ammo)
            ammo += take
            reserve_ammo -= take
            is_reloading = false
            notice_label.text = "Перезаряжено"
    ammo_label.text = "ППШ-41   %d / %d" % [ammo, reserve_ammo]
    if Input.is_key_pressed(KEY_TAB):
        pass

    var input_vec := mobile_move
    input_vec.x += float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
    input_vec.y += float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
    input_vec = input_vec.limit_length(1.0)
    yaw -= mobile_look.x * delta * 1.8
    pitch = clamp(pitch + mobile_look.y * delta * 1.4, -1.35, 1.35)
    rotation.y = yaw
    camera.rotation.x = pitch
    var direction := (transform.basis * Vector3(input_vec.x,0,input_vec.y)).normalized()
    var current_speed := SPEED
    if Input.is_key_pressed(KEY_SHIFT) and stance == 0:
        current_speed = SPRINT_SPEED
    if stance == 1:
        current_speed *= 0.55
    elif stance == 2:
        current_speed *= 0.25
    velocity.x = direction.x * current_speed
    velocity.z = direction.z * current_speed
    if not is_on_floor():
        velocity.y -= 18.0 * delta
    elif Input.is_key_pressed(KEY_SPACE) and stance == 0:
        velocity.y = JUMP_VELOCITY
    move_and_slide()
    var target_y := 1.48 if stance == 0 else (0.95 if stance == 1 else 0.48)
    camera.position.y = lerpf(camera.position.y, target_y, delta * 10.0)

func _down_action() -> void:
    stance = mini(2, stance + 1)
    _update_stance()

func _up_action() -> void:
    if stance > 0:
        stance -= 1
        _update_stance()
    elif is_on_floor():
        velocity.y = JUMP_VELOCITY

func _update_stance() -> void:
    notice_label.text = ["СТОЯ", "ПРИСЕЛ", "ЛЁЖА"][stance]

func _shoot() -> void:
    if is_reloading or fire_cooldown > 0:
        return
    if ammo <= 0:
        notice_label.text = "Нет патронов — нажми ПЕРЕЗАРЯДКА"
        return
    ammo -= 1
    fire_cooldown = 0.095
    pitch = clamp(pitch - 0.012, -1.35, 1.35)
    camera.rotation.x = pitch
    var from := camera.global_position
    var to := from + (-camera.global_transform.basis.z * 100.0)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit:
        var body = hit.collider
        if body.is_in_group("damageable"):
            var region := str(body.get_meta("region", "chest"))
            var dummy = body.get_meta("owner_dummy")
            var damage: int = dummy.receive_hit(region)
            notice_label.text = "ПОПАДАНИЕ: %s  -%d HP" % [region.to_upper(), damage]
            if dummy.health >= 100.0:
                var world = get_parent()
                if world.has_method("add_kill"):
                    world.add_kill()
        else:
            notice_label.text = "ПОПАДАНИЕ"
    else:
        notice_label.text = "ПРОМАХ"

func _reload() -> void:
    if is_reloading or ammo >= 71 or reserve_ammo <= 0:
        return
    is_reloading = true
    reload_timer = 2.6
    notice_label.text = "ПЕРЕЗАРЯДКА..."
