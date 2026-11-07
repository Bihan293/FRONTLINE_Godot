extends CharacterBody3D

const MOBILE_CONTROLS = preload("res://scripts/mobile_controls.gd")
const CROSSHAIR = preload("res://scripts/crosshair.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const PLAYER_BODY = preload("res://scripts/player_body.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const GRENADE_SCRIPT = preload("res://scripts/grenade.gd")
const SMOKE_SCRIPT = preload("res://scripts/smoke_grenade.gd")

const SFX_SHOT = preload("res://assets/audio/shot.wav")
const SFX_EMPTY = preload("res://assets/audio/empty.ogg")
const SFX_RELOAD_OUT = preload("res://assets/audio/reload_out.ogg")
const SFX_RELOAD_IN = preload("res://assets/audio/reload_in.wav")
const SFX_UI = preload("res://assets/audio/ui_click.ogg")
const SFX_HIT_FLESH = preload("res://assets/audio/hit_flesh.ogg")
const SFX_KILL = preload("res://assets/audio/kill.ogg")
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
const RESERVE_START := 150
const RELOAD_TIME := 2.2
const FIRE_INTERVAL := 0.10
const MAX_HEALTH := 100.0

const WEAPON_DEFS := [
	{"id": "ak47", "name": "AK-47", "mag": 30, "reserve": 150, "damage": 45, "interval": 0.10, "reload": 2.2, "spread": 0.006, "pellets": 1, "range": 140.0, "pitch": 1.0},
	{"id": "mp40", "name": "MP-40", "mag": 32, "reserve": 160, "damage": 27, "interval": 0.075, "reload": 2.0, "spread": 0.014, "pellets": 1, "range": 105.0, "pitch": 1.16},
	{"id": "mosin", "name": "MOSIN-NAGANT", "mag": 5, "reserve": 50, "damage": 84, "interval": 1.35, "reload": 2.6, "spread": 0.0018, "pellets": 1, "range": 220.0, "pitch": 0.76},
	{"id": "m1911", "name": "M1911", "mag": 8, "reserve": 56, "damage": 35, "interval": 0.24, "reload": 1.5, "spread": 0.009, "pellets": 1, "range": 80.0, "pitch": 1.3},
	{"id": "shotgun", "name": "PUMP SHOTGUN", "mag": 6, "reserve": 36, "damage": 10, "interval": 0.78, "reload": 3.2, "spread": 0.075, "pellets": 7, "range": 52.0, "pitch": 0.78},
]

const WORLD_LAYER_MASK := 1 << 0
const HITBOX_LAYER_MASK := 1 << 1
const SOLDIER_LAYER_MASK := 1 << 2
const RAY_COLLISION_MASK := WORLD_LAYER_MASK | HITBOX_LAYER_MASK

var camera: Camera3D
var player_capsule: CapsuleShape3D
var player_collision: CollisionShape3D
var weapon_root: Node3D
var weapon_mount: Node3D
var weapon_base := Vector3.ZERO
var weapon_aim_position := Vector3(0.0, -0.092, -0.56)
var muzzle_flash: MeshInstance3D
var muzzle_flash_time := 0.0
var weapon_kick := 0.0
var bob_time := 0.0
var breathing_time := 0.0
var aim_blend := 0.0
var aiming := false
var look_sway := Vector2.ZERO
var lean_amount := 0.0
var mobile_lean_left := false
var mobile_lean_right := false
var current_weapon_index := 0
var ammo_by_weapon: Array[int] = []
var reserve_by_weapon: Array[int] = []

var left_arm_pivot: Node3D
var left_arm_base := Vector3.ZERO
var player_body: Node3D
var wrist_right_marker: Node3D
var wrist_left_marker: Node3D
var damage_label: Label
var damage_time := 0.0
var hit_effect_time := 0.0

var pitch := 0.0
var yaw := 0.0
var recoil := Vector2.ZERO
var stance := 0
var fire_cooldown := 0.0
var ammo := MAG_SIZE
var reserve_ammo := RESERVE_START
var is_reloading := false
var reload_timer := 0.0

# Снаряжение игрока
var grenades := 3
var smoke_grenades := 2
var medkits := 2
var is_healing := false
var heal_timer := 0.0
var throwable_cooldown := 0.0

# Здоровье и статус игрока
var health := MAX_HEALTH
var is_dead := false
var input_locked := false
var blood_vignette_time := 0.0
var respawn_position := Vector3.ZERO

var hud: CanvasLayer
var ammo_label: Label
var equip_label: Label
var health_label: Label
var health_bar: ProgressBar
var blood_overlay: ColorRect
var death_screen: Control
var death_info_label: Label
var crosshair

var mobile_controls: MobileControls
var mobile_move := Vector2.ZERO
var mobile_fire := false
var sprint_hold := 0.0

var sfx_shot: AudioStreamPlayer
var sfx_empty: AudioStreamPlayer
var sfx_reload_out: AudioStreamPlayer
var sfx_reload_in: AudioStreamPlayer
var sfx_ui: AudioStreamPlayer
var sfx_footstep: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_kill: AudioStreamPlayer
var footstep_timer := 0.0

func _ready() -> void:
	add_to_group("player")
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(48.0)
	respawn_position = position
	_init_weapon_inventory()
	_build_player()
	_build_weapon()
	_build_body()
	_build_audio()
	_build_mobile_controls()
	_build_hud()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_apply_look()

func _build_player() -> void:
	collision_mask = WORLD_LAYER_MASK | SOLDIER_LAYER_MASK
	player_collision = CollisionShape3D.new()
	player_capsule = CapsuleShape3D.new()
	player_capsule.radius = 0.34
	player_capsule.height = 1.95
	player_collision.shape = player_capsule
	player_collision.position.y = 0.975
	add_child(player_collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.80, -0.10)
	camera.fov = 78.0
	camera.current = true
	add_child(camera)

func _build_weapon() -> void:
	weapon_root = Node3D.new()
	weapon_root.name = "ViewModel"
	weapon_root.position = Vector3(0.08, -0.17, -0.52)
	weapon_root.scale = Vector3.ONE * 0.62
	weapon_base = weapon_root.position
	camera.add_child(weapon_root)
	weapon_mount = Node3D.new()
	weapon_mount.name = "WeaponMount"
	weapon_root.add_child(weapon_mount)
	_equip_weapon_visual()
	_build_view_hands()

func _equip_weapon_visual() -> void:
	if weapon_mount == null:
		return
	for child in weapon_mount.get_children():
		child.queue_free()
	muzzle_flash = null
	var weapon_id: String = str(_weapon_data().id)
	var model: Node3D = WEAPON_MESHES.make_weapon(weapon_id)
	if model == null:
		push_error("FRONTLINE: cannot build weapon model " + weapon_id)
		return
	weapon_mount.add_child(model)
	var muzzle_anchor := model.get_node_or_null("Muzzle") as Node3D
	if muzzle_anchor == null:
		push_error("FRONTLINE: weapon has no muzzle marker " + weapon_id)
		return
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
	muzzle_flash.visible = false
	muzzle_flash.name = "MuzzleFlash"
	muzzle_anchor.add_child(muzzle_flash)

func _init_weapon_inventory() -> void:
	for definition in WEAPON_DEFS:
		ammo_by_weapon.append(int(definition.mag))
		reserve_by_weapon.append(int(definition.reserve))
	ammo = ammo_by_weapon[0]
	reserve_ammo = reserve_by_weapon[0]

func _weapon_data() -> Dictionary:
	return WEAPON_DEFS[current_weapon_index]

func _store_weapon_ammo() -> void:
	ammo_by_weapon[current_weapon_index] = ammo
	reserve_by_weapon[current_weapon_index] = reserve_ammo

func _switch_weapon(index: int) -> void:
	if is_dead or index < 0 or index >= WEAPON_DEFS.size() or index == current_weapon_index:
		return
	_store_weapon_ammo()
	is_reloading = false
	reload_timer = 0.0
	current_weapon_index = index
	ammo = ammo_by_weapon[index]
	reserve_ammo = reserve_by_weapon[index]
	weapon_kick = 0.0
	_equip_weapon_visual()
	_refresh_ammo()
	_play_sfx(sfx_ui, SFX_UI, -6.0, 1.0)

func _cycle_weapon(direction: int) -> void:
	var next_index := current_weapon_index + direction
	if next_index < 0:
		next_index = WEAPON_DEFS.size() - 1
	elif next_index >= WEAPON_DEFS.size():
		next_index = 0
	_switch_weapon(next_index)

func _build_body() -> void:
	var team := str(get_tree().get_meta("selected_team", "IRON LEGION"))
	var body = PLAYER_BODY.new()
	body.name = "PlayerBody"
	body.position = Vector3(0.0, 0.0, -0.45)
	add_child(body)
	body.setup(team.to_upper().contains("RED"), wrist_left_marker, wrist_right_marker)
	player_body = body

func _build_view_hands() -> void:
	wrist_right_marker = Node3D.new()
	wrist_right_marker.name = "WristR"
	wrist_right_marker.position = Vector3(0.0, -0.055, 0.02)
	weapon_root.add_child(wrist_right_marker)

	left_arm_pivot = Node3D.new()
	left_arm_pivot.name = "LeftArm"
	left_arm_pivot.position = Vector3(0.0, 0.0, -0.14)
	left_arm_base = left_arm_pivot.position
	weapon_root.add_child(left_arm_pivot)

	wrist_left_marker = Node3D.new()
	wrist_left_marker.name = "WristL"
	wrist_left_marker.position = Vector3(0.0, -0.055, 0.02)
	left_arm_pivot.add_child(wrist_left_marker)

func _set_aiming(enabled: bool) -> void:
	if aiming == enabled or is_dead or input_locked:
		return
	aiming = enabled

func set_input_locked(locked: bool) -> void:
	input_locked = locked
	if locked:
		velocity = Vector3.ZERO
		mobile_fire = false
		if mobile_controls != null:
			mobile_controls.visible = false
		if death_screen != null:
			death_screen.visible = false

func _build_audio() -> void:
	sfx_shot = _make_sfx()
	sfx_empty = _make_sfx()
	sfx_reload_out = _make_sfx()
	sfx_reload_in = _make_sfx()
	sfx_ui = _make_sfx()
	sfx_footstep = _make_sfx()
	sfx_hit = _make_sfx()
	sfx_kill = _make_sfx()

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
	mobile_controls.grenade_pressed.connect(_throw_grenade)
	mobile_controls.smoke_pressed.connect(_throw_smoke)
	mobile_controls.heal_pressed.connect(_use_heal)
	mobile_controls.peek_left_changed.connect(_on_mobile_peek_left)
	mobile_controls.peek_right_changed.connect(_on_mobile_peek_right)
	mobile_controls.cycle_weapon_pressed.connect(func(): _cycle_weapon(1))

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)

	blood_overlay = ColorRect.new()
	blood_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blood_overlay.color = Color(0.7, 0.0, 0.0, 0.0)
	blood_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(blood_overlay)

	crosshair = CROSSHAIR.new()
	hud.add_child(crosshair)

	var health_box := HBoxContainer.new()
	health_box.offset_left = 28.0
	health_box.offset_top = 24.0
	health_box.offset_right = 260.0
	health_box.offset_bottom = 60.0
	health_box.add_theme_constant_override("separation", 10)
	hud.add_child(health_box)

	health_label = Label.new()
	health_label.text = "HP 100"
	health_label.add_theme_font_size_override("font_size", 20)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	health_box.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.min_value = 0.0
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(140, 22)
	health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	health_box.add_child(health_bar)

	ammo_label = Label.new()
	ammo_label.anchor_left = 1.0
	ammo_label.anchor_right = 1.0
	ammo_label.anchor_top = 1.0
	ammo_label.anchor_bottom = 1.0
	ammo_label.offset_left = -390.0
	ammo_label.offset_right = -24.0
	ammo_label.offset_top = -430.0
	ammo_label.offset_bottom = -392.0
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ammo_label.add_theme_font_size_override("font_size", 24)
	ammo_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	ammo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	ammo_label.add_theme_constant_override("shadow_offset_x", 2)
	ammo_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(ammo_label)

	equip_label = Label.new()
	equip_label.anchor_left = 1.0
	equip_label.anchor_right = 1.0
	equip_label.anchor_top = 1.0
	equip_label.anchor_bottom = 1.0
	equip_label.offset_left = -360.0
	equip_label.offset_right = -24.0
	equip_label.offset_top = -390.0
	equip_label.offset_bottom = -360.0
	equip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	equip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equip_label.add_theme_font_size_override("font_size", 16)
	equip_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55))
	hud.add_child(equip_label)

	damage_label = Label.new()
	damage_label.anchor_left = 0.5
	damage_label.anchor_right = 0.5
	damage_label.anchor_top = 0.5
	damage_label.anchor_bottom = 0.5
	damage_label.offset_left = -90.0
	damage_label.offset_right = 90.0
	damage_label.offset_top = -78.0
	damage_label.offset_bottom = -34.0
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	damage_label.add_theme_font_size_override("font_size", 26)
	damage_label.add_theme_color_override("font_color", Color(1.0, 0.16, 0.12, 1.0))
	damage_label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0, 0.95))
	damage_label.add_theme_constant_override("outline_size", 7)
	damage_label.visible = false
	hud.add_child(damage_label)

	_build_death_screen()
	_refresh_ammo()
	_refresh_health()
	_refresh_equipment()

func _build_death_screen() -> void:
	death_screen = Control.new()
	death_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_screen.visible = false
	hud.add_child(death_screen)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.02, 0.02, 0.75)
	death_screen.add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.offset_left = -220
	center.offset_right = 220
	center.offset_top = -140
	center.offset_bottom = 140
	center.add_theme_constant_override("separation", 16)
	death_screen.add_child(center)

	var title := Label.new()
	title.text = "ПОГИБ В БОЮ (K.I.A.)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.20))
	center.add_child(title)

	death_info_label = Label.new()
	death_info_label.text = "Вы были сражены в бою"
	death_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_info_label.add_theme_font_size_override("font_size", 18)
	death_info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	center.add_child(death_info_label)

	var respawn_btn := Button.new()
	respawn_btn.text = "ВОЗРОДИТЬСЯ (RESPAWN)"
	respawn_btn.custom_minimum_size = Vector2(300, 56)
	respawn_btn.add_theme_font_size_override("font_size", 20)
	respawn_btn.pressed.connect(respawn)
	center.add_child(respawn_btn)

	var menu_btn := Button.new()
	menu_btn.text = "В ГЛАВНОЕ МЕНЮ"
	menu_btn.custom_minimum_size = Vector2(300, 48)
	menu_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	center.add_child(menu_btn)

func _on_move_changed(value: Vector2) -> void:
	mobile_move = value

func _on_look_delta(delta: Vector2) -> void:
	if is_dead:
		return
	yaw -= delta.x * TOUCH_SENS
	pitch = clampf(pitch - delta.y * TOUCH_SENS, -1.35, 1.35)
	look_sway += Vector2(delta.x, delta.y) * 0.00006
	look_sway = look_sway.limit_length(0.035)

func _on_fire_changed(pressed: bool) -> void:
	mobile_fire = pressed

func _on_mobile_peek_left(pressed: bool) -> void:
	mobile_lean_left = pressed

func _on_mobile_peek_right(pressed: bool) -> void:
	mobile_lean_right = pressed

func _unhandled_input(event: InputEvent) -> void:
	if is_dead or input_locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * MOUSE_SENS
		pitch = clampf(pitch - event.relative.y * MOUSE_SENS, -1.35, 1.35)
		look_sway += Vector2(event.relative.x, event.relative.y) * 0.00006
		look_sway = look_sway.limit_length(0.035)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not OS.has_feature("mobile"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_shoot()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_set_aiming(not aiming)
	elif event is InputEventMouseButton and event.pressed and not OS.has_feature("mobile"):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_weapon(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_weapon(1)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reload()
		elif event.keycode == KEY_C:
			_down_action()
		elif event.keycode == KEY_SPACE:
			_up_action()
		elif event.keycode == KEY_G:
			_throw_grenade()
		elif event.keycode == KEY_X or event.keycode == KEY_T:
			_throw_smoke()
		elif event.keycode == KEY_H:
			_use_heal()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			_switch_weapon(event.keycode - KEY_1)

func _physics_process(delta: float) -> void:
	if is_dead:
		if not is_on_floor():
			velocity.y -= 18.0 * delta
			move_and_slide()
		return
	if input_locked:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	throwable_cooldown = maxf(0.0, throwable_cooldown - delta)
	if crosshair != null:
		crosshair.visible = not is_dead and not aiming
	weapon_kick = lerpf(weapon_kick, 0.0, clampf(delta * 14.0, 0.0, 1.0))
	var blend := 1.0 - exp(-delta * 13.0)
	aim_blend = lerpf(aim_blend, 1.0 if aiming else 0.0, blend)
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	if planar_speed > 0.4 and is_on_floor():
		bob_time += delta * (11.0 if planar_speed > SPEED + 0.5 else 7.5)
		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep_timer = 0.32 if planar_speed > SPEED + 0.5 else 0.48
			var sfx: AudioStream = SFX_FOOTSTEPS[randi() % SFX_FOOTSTEPS.size()]
			_play_sfx(sfx_footstep, sfx, -14.0, randf_range(0.92, 1.08))
	else:
		bob_time = fposmod(bob_time, TAU)
		breathing_time += delta

	# Таймер лечения
	if is_healing:
		heal_timer -= delta
		if heal_timer <= 0.0:
			is_healing = false
			medkits = maxi(0, medkits - 1)
			health = minf(MAX_HEALTH, health + 45.0)
			_refresh_health()
			_refresh_equipment()
			_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -2.0, 1.1)

	# Вспышка крови на экране
	if blood_vignette_time > 0.0:
		blood_vignette_time = maxf(0.0, blood_vignette_time - delta * 2.5)
		blood_overlay.color.a = blood_vignette_time * 0.45
	else:
		var low_hp_alpha := clampf((35.0 - health) / 35.0, 0.0, 0.3) if health < 35.0 else 0.0
		blood_overlay.color.a = low_hp_alpha

	var bob_amount := 0.25 if aiming else 1.0
	var kick_offset := Vector3(0.0, 0.015, 0.04) * weapon_kick
	var bob_offset := Vector3(
		sin(bob_time) * 0.007 * bob_amount,
		absf(cos(bob_time)) * 0.006 * bob_amount,
		0.0
	)
	var breath_offset := Vector3(0.0, sin(breathing_time * 1.8) * 0.002, 0.0)
	var sway_offset := Vector3(-look_sway.x, look_sway.y, 0.0)
	look_sway = look_sway.lerp(Vector2.ZERO, clampf(delta * 8.0, 0.0, 1.0))
	var target_weapon_pos := weapon_base.lerp(weapon_aim_position, aim_blend) + kick_offset + bob_offset + breath_offset + sway_offset
	weapon_root.position = weapon_root.position.lerp(target_weapon_pos, clampf(delta * 20.0, 0.0, 1.0))
	weapon_root.rotation.x = -weapon_kick * 0.18 + sway_offset.y * 0.6
	weapon_root.rotation.y = sway_offset.x * 0.6

	if muzzle_flash_time > 0.0:
		muzzle_flash_time -= delta
		if muzzle_flash_time <= 0.0 and muzzle_flash != null:
			muzzle_flash.visible = false

	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			var need := int(_weapon_data().mag) - ammo
			var take := mini(need, reserve_ammo)
			ammo += take
			reserve_ammo -= take
			is_reloading = false
			_store_weapon_ammo()
			_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -4.0, 1.0)
			_refresh_ammo()

	if damage_time > 0.0:
		damage_time -= delta
		var fade := clampf(damage_time / 0.65, 0.0, 1.0)
		damage_label.modulate.a = fade
		damage_label.offset_top = -78.0 - (1.0 - fade) * 22.0
		damage_label.offset_bottom = damage_label.offset_top + 44.0
		if damage_time <= 0.0:
			damage_label.visible = false

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
	move_and_slide()

	recoil = recoil.lerp(Vector2.ZERO, clampf(delta * 7.0, 0.0, 1.0))
	var target_height := 1.95 if stance == 0 else (1.35 if stance == 1 else 0.70)
	player_capsule.height = lerpf(player_capsule.height, target_height, clampf(delta * 10.0, 0.0, 1.0))
	player_collision.position.y = player_capsule.height * 0.5
	var target_y := 1.80 if stance == 0 else (1.34 if stance == 1 else 0.54)
	var cam_bob_y := sin(bob_time * 2.0) * 0.004 * bob_amount
	var cam_bob_x := sin(bob_time) * 0.005 * bob_amount
	var lean_input := float(Input.is_key_pressed(KEY_E) or mobile_lean_right) - float(Input.is_key_pressed(KEY_Q) or mobile_lean_left)
	var lean_side := lean_input * 0.42
	if absf(lean_side) > 0.01:
		var lean_from := global_position + Vector3.UP * target_y
		var lean_to := lean_from + transform.basis.x * lean_side
		var lean_query := PhysicsRayQueryParameters3D.create(lean_from, lean_to)
		lean_query.collision_mask = WORLD_LAYER_MASK
		lean_query.exclude = [self]
		lean_query.collide_with_areas = false
		var lean_hit := get_world_3d().direct_space_state.intersect_ray(lean_query)
		if lean_hit:
			var available := maxf(0.0, lean_from.distance_to(lean_hit.position) - 0.12)
			lean_side = signf(lean_side) * minf(absf(lean_side), available)
	var lean_target := lean_side / 0.42
	lean_amount = lerpf(lean_amount, lean_target, clampf(delta * 12.0, 0.0, 1.0))
	camera.position.y = lerpf(camera.position.y, target_y + cam_bob_y, delta * 10.0)
	camera.position.x = lerpf(camera.position.x, cam_bob_x + lean_amount * 0.42, delta * 10.0)
	if player_body != null:
		player_body.set_motion(planar_speed, planar_speed > SPEED + 0.5)
		player_body.set_stance(stance)
		var look_down := clampf((-pitch - 0.22) / 0.45, 0.0, 1.0)
		player_body.set_look_down(look_down)
	_apply_look()

func _apply_look() -> void:
	rotation.y = yaw
	camera.rotation = Vector3(
		clampf(pitch + recoil.y, -1.45, 1.45),
		recoil.x,
		-lean_amount * deg_to_rad(9.0)
	)

func _down_action() -> void:
	if is_dead or input_locked:
		return
	stance = mini(2, stance + 1)

func _up_action() -> void:
	if is_dead or input_locked:
		return
	if stance > 0:
		stance -= 1
	elif is_on_floor():
		velocity.y = JUMP_VELOCITY

func _shoot() -> void:
	if is_reloading or is_healing or fire_cooldown > 0.0 or is_dead or input_locked:
		return
	var weapon := _weapon_data()
	if ammo <= 0:
		if reserve_ammo > 0:
			_reload()
		else:
			_play_sfx(sfx_empty, SFX_EMPTY, -5.0, randf_range(0.95, 1.05))
			fire_cooldown = 0.25
		return
	ammo -= 1
	fire_cooldown = float(weapon.interval)
	_store_weapon_ammo()
	_refresh_ammo()
	_play_sfx(sfx_shot, SFX_SHOT, -2.0, float(weapon.pitch) * randf_range(0.94, 1.06))

	var casing_pos := camera.global_position + camera.global_transform.basis.x * 0.22 - camera.global_transform.basis.y * 0.12 - camera.global_transform.basis.z * 0.35
	var casing_vel := camera.global_transform.basis.x * 2.6 + camera.global_transform.basis.y * 1.4 - camera.global_transform.basis.z * 0.4
	HIT_EFFECTS.spawn_casing(get_parent(), casing_pos, casing_vel)

	recoil.y = minf(recoil.y + randf_range(0.009, 0.015), 0.13)
	recoil.x = clampf(recoil.x + randf_range(-0.006, 0.006), -0.045, 0.045)
	weapon_kick = 0.07
	if muzzle_flash != null:
		muzzle_flash.visible = true
		muzzle_flash_time = 0.045
	_apply_look()

	var spread := float(weapon.spread) * (0.42 if aiming else 1.0)
	if stance == 0 and (mobile_move.length() > 0.2 or velocity.length() > SPEED + 0.5):
		spread += 0.012
	var hit_actors: Array[Node] = []
	var hit_damage: Array[int] = []
	var hit_details: Array[Dictionary] = []
	var pellet_count := int(weapon.pellets)
	for pellet_index in range(pellet_count):
		var dir := -camera.global_transform.basis.z
		dir = dir.rotated(camera.global_transform.basis.y, randf_range(-spread, spread))
		dir = dir.rotated(camera.global_transform.basis.x, randf_range(-spread, spread))
		var from := camera.global_position
		var to := from + dir * float(weapon["range"])
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = RAY_COLLISION_MASK
		query.exclude = [self]
		query.collide_with_areas = true
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue
		var body = hit.collider
		if not body.is_in_group("damageable"):
			HIT_EFFECTS.spawn_bullet_hole(get_parent(), hit.position, hit.normal)
			continue
		var region := str(body.get_meta("region", "chest"))
		var actor = body.get_meta("owner_actor", body.get_meta("owner_dummy", null))
		if actor == null and body.has_method("receive_hit"):
			actor = body
		if actor == null or not (actor is Node) or not actor.has_method("receive_hit"):
			continue
		var target_team: String = ""
		if "team_name" in actor:
			target_team = str(actor.team_name)
		var player_team: String = str(get_tree().get_meta("selected_team", "IRON LEGION"))
		if target_team != "" and target_team == player_team:
			continue
		var damage := int(weapon.damage)
		match region:
			"head": damage = int(round(float(damage) * 2.2))
			"leg": damage = int(round(float(damage) * 0.45))
		var actor_node := actor as Node
		var actor_index := hit_actors.find(actor_node)
		if actor_index < 0:
			actor_index = hit_actors.size()
			hit_actors.append(actor_node)
			hit_damage.append(0)
			hit_details.append({"region": region, "position": hit.position, "direction": dir})
		hit_damage[actor_index] += damage

	var confirmed_hit := false
	for i in range(hit_actors.size()):
		var actor := hit_actors[i]
		var detail: Dictionary = hit_details[i]
		var region := str(detail.region)
		var was_alive := not ("health" in actor) or float(actor.health) > 0.0
		var damage_applied: int = actor.receive_hit(hit_damage[i], camera.global_position, region, "Player")
		if damage_applied <= 0:
			continue
		confirmed_hit = true
		_pop_damage(damage_applied)
		if not actor.is_in_group("explosive_barrels"):
			_play_sfx(sfx_hit, SFX_HIT_FLESH, -4.0, randf_range(0.9, 1.1))
			HIT_EFFECTS.spawn_directional_blood(actor, detail.position, detail.direction, region == "head", get_parent())
		if crosshair != null:
			crosshair.flash_hit()
		if was_alive and ("health" in actor) and float(actor.health) <= 0.0:
			_play_sfx(sfx_kill, SFX_KILL, -2.0, 1.0)
			var world = get_parent()
			if world.has_method("add_kill"):
				world.add_kill()
	if confirmed_hit and pellet_count > 1:
		_play_sfx(sfx_hit, SFX_HIT_FLESH, -6.0, randf_range(0.9, 1.1))

func _reload() -> void:
	var weapon := _weapon_data()
	if is_reloading or is_healing or ammo >= int(weapon.mag) or reserve_ammo <= 0 or is_dead or input_locked:
		return
	is_reloading = true
	reload_timer = float(weapon.reload)
	_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -6.0, 1.0)

func _throw_grenade() -> void:
	if grenades <= 0 or is_dead:
		return
	grenades -= 1
	_refresh_equipment()
	var g := GRENADE_SCRIPT.new()
	var spawn_pos := camera.global_position + camera.global_transform.basis.x * 0.22 - camera.global_transform.basis.y * 0.12 - camera.global_transform.basis.z * 0.5
	var throw_dir := -camera.global_transform.basis.z + Vector3.UP * 0.24
	g.position = spawn_pos
	g.linear_velocity = throw_dir.normalized() * 19.5 + velocity * 0.4
	g.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
	g.thrower_name = "Player"
	g.team_name = str(get_tree().get_meta("selected_team", "IRON LEGION"))
	get_parent().add_child(g)
	_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -3.0, 1.4)

func _throw_smoke() -> void:
	if smoke_grenades <= 0 or is_dead:
		return
	smoke_grenades -= 1
	_refresh_equipment()
	var s := SMOKE_SCRIPT.new()
	var spawn_pos := camera.global_position + camera.global_transform.basis.x * 0.22 - camera.global_transform.basis.y * 0.12 - camera.global_transform.basis.z * 0.5
	var throw_dir := -camera.global_transform.basis.z + Vector3.UP * 0.24
	s.position = spawn_pos
	s.linear_velocity = throw_dir.normalized() * 19.5 + velocity * 0.4
	s.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
	s.thrower_name = "Player"
	get_parent().add_child(s)
	_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -3.0, 1.4)

func _use_heal() -> void:
	if medkits <= 0 or is_dead or is_healing or health >= MAX_HEALTH:
		return
	is_healing = true
	heal_timer = 2.2
	_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -4.0, 1.0)

func _refresh_ammo() -> void:
	if ammo_label == null:
		return
	var weapon := _weapon_data()
	ammo_label.text = "%d  %s   %d / %d" % [current_weapon_index + 1, str(weapon.name), ammo, reserve_ammo]

func _refresh_health() -> void:
	if health_label != null:
		health_label.text = "HP %d" % int(round(health))
	if health_bar != null:
		health_bar.value = health

func _refresh_equipment() -> void:
	if equip_label != null:
		equip_label.text = "ГРАНАТЫ: %d   •   ДЫМ: %d   •   БИНТЫ: %d" % [grenades, smoke_grenades, medkits]

func _pop_damage(amount: int) -> void:
	if damage_label == null:
		return
	damage_label.text = "−%d" % amount
	damage_label.visible = true
	damage_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	damage_label.offset_top = -78.0
	damage_label.offset_bottom = -34.0
	damage_time = 0.65

func receive_hit(damage: int, attacker_pos: Vector3, region: String = "chest", attacker_name: String = "Enemy") -> void:
	if is_dead:
		return
	health = maxf(0.0, health - float(damage))
	blood_vignette_time = 1.0
	_play_sfx(sfx_hit, SFX_HIT_FLESH, 0.0, randf_range(0.9, 1.1))

	var to_attacker := (attacker_pos - global_position).normalized()
	recoil.y += randf_range(0.02, 0.05)
	recoil.x += clampf(-to_attacker.x * 0.04, -0.06, 0.06)

	_refresh_health()

	if health <= 0.0:
		_die(attacker_name)

func _die(killer_name: String) -> void:
	is_dead = true
	health = 0.0
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	camera.position.y = 0.28
	camera.rotation.z = deg_to_rad(35.0)

	if death_info_label != null:
		death_info_label.text = "Вас уничтожил: " + killer_name
	if death_screen != null:
		death_screen.visible = true

func respawn() -> void:
	is_dead = false
	health = MAX_HEALTH
	for i in range(WEAPON_DEFS.size()):
		ammo_by_weapon[i] = int(WEAPON_DEFS[i].mag)
		reserve_by_weapon[i] = int(WEAPON_DEFS[i].reserve)
	ammo = ammo_by_weapon[current_weapon_index]
	reserve_ammo = reserve_by_weapon[current_weapon_index]
	is_reloading = false
	reload_timer = 0.0
	grenades = 3
	smoke_grenades = 2
	medkits = 2
	is_healing = false
	stance = 0
	lean_amount = 0.0
	mobile_lean_left = false
	mobile_lean_right = false
	position = respawn_position
	camera.position = Vector3(0, 1.80, -0.10)
	camera.rotation = Vector3.ZERO
	pitch = 0.0
	yaw = 0.0
	_refresh_ammo()
	_refresh_health()
	_refresh_equipment()

	if death_screen != null:
		death_screen.visible = false
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
