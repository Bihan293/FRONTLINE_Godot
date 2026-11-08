extends CharacterBody3D

const MOBILE_CONTROLS = preload("res://scripts/mobile_controls.gd")
const CROSSHAIR = preload("res://scripts/crosshair.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const PLAYER_BODY = preload("res://scripts/player_body.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const GRENADE_SCRIPT = preload("res://scripts/grenade.gd")
const SMOKE_SCRIPT = preload("res://scripts/smoke_grenade.gd")
const FIELD_PICKUP_SCRIPT = preload("res://scripts/field_pickup.gd")
const ROCKET_PROJECTILE_SCRIPT = preload("res://scripts/rocket_projectile.gd")
const BULLET_PROJECTILE_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const RADIO_DRONE_SCRIPT = preload("res://scripts/radio_drone.gd")
const PAUSE_MENU = preload("res://scripts/pause_menu.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const WEAPON_SOUND = preload("res://scripts/weapon_sound_bank.gd")
const SHOW_VIEW_ARMS := false

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
const SIDEARM_INDEX := 3 # M1911 is carried as a backup sidearm by every role.

const WEAPON_DEFS := [
	{"id": "ak47", "name": "AK-47", "mag": 30, "reserve": 150, "damage": 45, "interval": 0.10, "reload": 2.2, "spread": 0.006, "pellets": 1, "range": 140.0, "muzzle_velocity": 715.0, "pitch": 1.0},
	{"id": "mp40", "name": "MP-40", "mag": 32, "reserve": 160, "damage": 27, "interval": 0.075, "reload": 2.0, "spread": 0.014, "pellets": 1, "range": 105.0, "muzzle_velocity": 380.0, "pitch": 1.16},
	{"id": "mosin", "name": "MOSIN-NAGANT", "mag": 5, "reserve": 50, "damage": 84, "interval": 1.35, "reload": 2.6, "spread": 0.0018, "pellets": 1, "range": 220.0, "muzzle_velocity": 865.0, "pitch": 0.76},
	{"id": "m1911", "name": "M1911", "mag": 8, "reserve": 56, "damage": 35, "interval": 0.24, "reload": 1.5, "spread": 0.009, "pellets": 1, "range": 80.0, "muzzle_velocity": 253.0, "pitch": 1.3},
	{"id": "shotgun", "name": "PUMP SHOTGUN", "mag": 6, "reserve": 36, "damage": 10, "interval": 0.78, "reload": 3.2, "spread": 0.075, "pellets": 7, "range": 52.0, "muzzle_velocity": 400.0, "pitch": 0.78},
	{"id": "ppsh41", "name": "PPSH-41", "mag": 71, "reserve": 213, "damage": 22, "interval": 0.065, "reload": 3.1, "spread": 0.016, "pellets": 1, "range": 95.0, "muzzle_velocity": 488.0, "pitch": 1.25},
	{"id": "kar98k", "name": "KAR98K SNIPER", "mag": 5, "reserve": 45, "damage": 95, "interval": 1.45, "reload": 2.8, "spread": 0.0008, "pellets": 1, "range": 260.0, "muzzle_velocity": 760.0, "pitch": 0.70},
	{"id": "panzerfaust", "name": "PANZERFAUST", "mag": 1, "reserve": 5, "damage": 220, "interval": 2.2, "reload": 3.5, "spread": 0.003, "pellets": 1, "range": 160.0, "pitch": 0.65},
]

const WORLD_LAYER_MASK := 1 << 0
const HITBOX_LAYER_MASK := 1 << 1
const SOLDIER_LAYER_MASK := 1 << 2
const RAY_COLLISION_MASK := WORLD_LAYER_MASK | HITBOX_LAYER_MASK

var camera: Camera3D
var audio_listener: AudioListener3D
var indoor_factor := 0.0
var _acoustic_timer := 0.0
var player_capsule: CapsuleShape3D
var player_collision: CollisionShape3D
var weapon_root: Node3D
var weapon_mount: Node3D
var weapon_muzzle: Node3D
var drone_controller_anchor: Marker3D
var drone_controller_view: Node3D
var weapon_base := Vector3.ZERO
var weapon_aim_position := Vector3(0.0, -0.075, -0.48)
var muzzle_flash: MeshInstance3D
var muzzle_flash_time := 0.0
var weapon_kick := 0.0
var sprint_anim := 0.0
var landing_anim := 0.0
var _was_on_floor := true
var bob_time := 0.0
var breathing_time := 0.0
var aim_blend := 0.0
var aiming := false
var look_sway := Vector2.ZERO
var lean_amount := 0.0
var mobile_lean_left := false
var mobile_lean_right := false

# === BODYCAM / DUMMY WAR РЕАЛИЗМ ===
var cam_yaw := 0.0
var cam_pitch := 0.0
var cam_roll := 0.0
var last_applied_yaw := 0.0
var cam_shake_trauma := 0.0
var bodycam_time := 0.0
var bodycam_rec_dot: Label = null
var bodycam_osd_label: Label = null
var bodycam_vignette: ColorRect = null
var current_weapon_index := 0
var last_primary_weapon_index := 0
var is_shovel_equipped := false
var carried_soil := 0
var shovel_action_cooldown := 0.0
var ammo_by_weapon: Array[int] = []
var reserve_by_weapon: Array[int] = []
var nearby_field_pickups: Array[Node3D] = []

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
var heal_target: Node3D
var throwable_cooldown := 0.0
var player_role := "ASSAULT"
var role_primary_weapon_index := 0
var role_weapon_indices: Array[int] = [0, 3]
var active_drone: CharacterBody3D = null
var drone_charge_available := true
var drone_vertical_input := 0.0

# Паркур / Преодоление препятствий (Parkour / Mantling / Vaulting)
var is_vaulting := false
var vault_timer := 0.0
var vault_duration := 0.38
var vault_start_pos := Vector3.ZERO
var vault_peak_pos := Vector3.ZERO
var vault_land_pos := Vector3.ZERO

# Анимация взведения и броска гранаты с удержанием кнопки (Cook / Aim & Release)
enum GrenadeActionState { IDLE, EQUIP, PULL_PIN, HOLD_AIM, THROW_SWING, RECOVER }
var grenade_anim_state: GrenadeActionState = GrenadeActionState.IDLE
var grenade_anim_timer := 0.0
var is_grenade_held := false
var grenade_view_root: Node3D
var grenade_pull_ring: Node3D
var grenade_safety_lever: Node3D
var grenade_hand_left: Node3D
var grenade_hand_right: Node3D
var grenade_has_spawned := false

# Здоровье и статус игрока
var health := MAX_HEALTH
var is_dead := false
var input_locked := false
var blood_vignette_time := 0.0
var respawn_position := Vector3.ZERO

var hud: CanvasLayer
var ammo_label: Label
var equip_label: Label
var pickup_label: Label
var health_label: Label
var health_bar: ProgressBar
var blood_overlay: ColorRect
var death_screen: Control
var death_info_label: Label
var crosshair

var mobile_controls: MobileControls
var mobile_move := Vector2.ZERO
var mounted_vehicle: Node3D = null
var mobile_fire := false
var sprint_hold := 0.0
var pause_menu: FRONTLINEPauseMenu
var _view_arm_left: MeshInstance3D
var _view_arm_right: MeshInstance3D

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
	_build_pause_menu()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cam_yaw = yaw
	cam_pitch = pitch
	last_applied_yaw = yaw
	_apply_look()

func _build_player() -> void:
	collision_layer = WORLD_LAYER_MASK
	collision_mask = WORLD_LAYER_MASK | SOLDIER_LAYER_MASK
	player_collision = CollisionShape3D.new()
	player_capsule = CapsuleShape3D.new()
	player_capsule.radius = 0.34
	player_capsule.height = 1.95
	player_collision.shape = player_capsule
	player_collision.position.y = 0.975
	add_child(player_collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.70, -0.08) # Нательное крепление бодикамеры (Bodycam)
	camera.fov = GameSettings.fov
	camera.current = true
	add_child(camera)
	audio_listener = AudioListener3D.new()
	audio_listener.name = "PlayerAudioListener"
	camera.add_child(audio_listener)
	audio_listener.make_current()

func _build_weapon() -> void:
	drone_controller_anchor = Marker3D.new()
	drone_controller_anchor.name = "DroneControllerAnchor"
	drone_controller_anchor.position = Vector3(0.20, -0.14, -0.46)
	camera.add_child(drone_controller_anchor)
	weapon_root = Node3D.new()
	weapon_root.name = "ViewModel"
	weapon_root.position = Vector3(0.24, -0.22, -0.55)
	weapon_root.scale = Vector3.ONE * 0.50
	weapon_base = weapon_root.position
	camera.add_child(weapon_root)
	weapon_mount = Node3D.new()
	weapon_mount.name = "WeaponMount"
	weapon_root.add_child(weapon_mount)
	_equip_weapon_visual()
	_build_view_hands()
	_build_grenade_view()

func _equip_weapon_visual() -> void:
	if weapon_mount == null:
		return
	for child in weapon_mount.get_children():
		child.queue_free()
	muzzle_flash = null
	weapon_muzzle = null
	var weapon_id: String = "entrenching_shovel" if is_shovel_equipped else str(_weapon_data().id)
	var model: Node3D = WEAPON_MESHES.make_weapon(weapon_id)
	if model == null:
		push_error("FRONTLINE: cannot build weapon model " + weapon_id)
		return
	weapon_mount.add_child(model)
	if is_shovel_equipped:
		weapon_base = Vector3(0.10, -0.13, -0.46)
		weapon_aim_position = Vector3(0.02, -0.08, -0.45)
		left_arm_base = Vector3(-0.02, -0.04, -0.24)
		if left_arm_pivot != null:
			left_arm_pivot.position = left_arm_base
		if wrist_right_marker != null:
			wrist_right_marker.position = Vector3(0.01, -0.05, 0.03)
		return
	var muzzle_anchor := model.get_node_or_null("Muzzle") as Node3D
	if muzzle_anchor == null:
		push_error("FRONTLINE: weapon has no muzzle marker " + weapon_id)
		return
	weapon_muzzle = muzzle_anchor
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
	muzzle_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle_flash.visible = false
	muzzle_flash.name = "MuzzleFlash"
	muzzle_anchor.add_child(muzzle_flash)

	# Уникальный реалистичный хват и положение для каждого класса оружия (Dummy War style)
	var hip_pos := Vector3(0.08, -0.17, -0.52)
	var aim_pos := Vector3(0.0, -0.092, -0.52)
	var left_wrist_offset := Vector3(-0.02, -0.03, -0.18)
	var right_wrist_offset := Vector3(0.01, -0.06, 0.02)

	match weapon_id:
		"ak47":
			hip_pos = Vector3(0.08, -0.17, -0.52)
			aim_pos = Vector3(0.0, -0.092, -0.52)
			left_wrist_offset = Vector3(-0.02, -0.03, -0.18) # цевьё
			right_wrist_offset = Vector3(0.01, -0.06, 0.02)
		"mp40":
			hip_pos = Vector3(0.075, -0.16, -0.48)
			aim_pos = Vector3(0.0, -0.082, -0.48)
			left_wrist_offset = Vector3(-0.02, -0.04, -0.14) # шахта магазина
			right_wrist_offset = Vector3(0.01, -0.06, 0.04)
		"mosin":
			hip_pos = Vector3(0.09, -0.17, -0.54)
			aim_pos = Vector3(0.0, -0.118, -0.50)
			left_wrist_offset = Vector3(-0.02, -0.025, -0.24) # длинное ложе
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"m1911":
			hip_pos = Vector3(0.05, -0.15, -0.44) # вынесенный пистолетный хват
			aim_pos = Vector3(0.0, -0.075, -0.40)
			left_wrist_offset = Vector3(-0.03, -0.055, 0.02) # хват второй рукой снизу
			right_wrist_offset = Vector3(0.01, -0.055, 0.02)
		"shotgun":
			hip_pos = Vector3(0.09, -0.18, -0.50)
			aim_pos = Vector3(0.0, -0.095, -0.48)
			left_wrist_offset = Vector3(-0.02, -0.04, -0.22) # подвижное цевьё
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"ppsh41":
			hip_pos = Vector3(0.08, -0.17, -0.48)
			aim_pos = Vector3(0.0, -0.088, -0.48)
			left_wrist_offset = Vector3(-0.02, -0.035, -0.16) # хват под барабаном
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"kar98k":
			hip_pos = Vector3(0.09, -0.17, -0.54)
			aim_pos = Vector3(0.0, -0.136, -0.46) # приклад плотно к плечу для оптики
			left_wrist_offset = Vector3(-0.02, -0.025, -0.24) # ложе
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"panzerfaust":
			hip_pos = Vector3(0.14, -0.09, -0.46) # удержание на правом плече
			aim_pos = Vector3(0.02, -0.065, -0.42) # прицельная планка
			left_wrist_offset = Vector3(-0.03, -0.02, -0.28) # поддержка трубы спереди
			right_wrist_offset = Vector3(0.01, 0.03, -0.08) # кнопка спуска сверху

	weapon_base = hip_pos
	weapon_aim_position = aim_pos
	left_arm_base = left_wrist_offset
	if left_arm_pivot != null:
		left_arm_pivot.position = left_wrist_offset
	if wrist_right_marker != null:
		wrist_right_marker.position = right_wrist_offset

func _init_weapon_inventory() -> void:
	for definition in WEAPON_DEFS:
		ammo_by_weapon.append(int(definition.mag))
		reserve_by_weapon.append(int(definition.reserve))

	player_role = str(get_tree().get_meta("selected_role", "ASSAULT"))
	match player_role:
		"SNIPER":
			role_primary_weapon_index = 6 # Kar98k
			role_weapon_indices = [6, 3]
			grenades = 1
			smoke_grenades = 2
			medkits = 2
		"ANTI_TANK":
			role_primary_weapon_index = 7 # Panzerfaust
			role_weapon_indices = [7, 5, 3]
			grenades = 1
			smoke_grenades = 1
			medkits = 2
		"MEDIC":
			role_primary_weapon_index = 1 # MP-40
			role_weapon_indices = [1, 3]
			grenades = 2
			smoke_grenades = 2
			medkits = 5
		"RADIO_OPERATOR":
			role_primary_weapon_index = 5 # PPSh-41
			role_weapon_indices = [5, 3]
			grenades = 1
			smoke_grenades = 2
			medkits = 2
		_:
			player_role = "ASSAULT"
			role_primary_weapon_index = 0 # AK-47
			role_weapon_indices = [0, 3]
			grenades = 3
			smoke_grenades = 2
			medkits = 2

	# Пресет снаряжения, выбранный на экране развёртывания.
	match str(get_tree().get_meta("selected_loadout", "BALANCED")):
		"ASSAULT":
			grenades += 1
			medkits = maxi(1, medkits - 1)
		"SURVIVAL":
			grenades = maxi(0, grenades - 1)
			medkits += 1

	# Ручная настройка на экране спавна: оружие и количество снаряжения.
	var chosen_primary := int(get_tree().get_meta("selected_primary", -1))
	if chosen_primary >= 0 and role_weapon_indices.has(chosen_primary):
		role_primary_weapon_index = chosen_primary
	var chosen_grenades := int(get_tree().get_meta("selected_grenades", -1))
	if chosen_grenades >= 0:
		grenades = chosen_grenades
	var chosen_smoke := int(get_tree().get_meta("selected_smoke", -1))
	if chosen_smoke >= 0:
		smoke_grenades = chosen_smoke
	var chosen_medkits := int(get_tree().get_meta("selected_medkits", -1))
	if chosen_medkits >= 0:
		medkits = chosen_medkits
	var chosen_rockets := int(get_tree().get_meta("selected_rockets", -1))
	if chosen_rockets >= 0:
		reserve_by_weapon[7] = chosen_rockets

	current_weapon_index = role_primary_weapon_index
	last_primary_weapon_index = role_primary_weapon_index
	ammo = ammo_by_weapon[current_weapon_index]
	reserve_ammo = reserve_by_weapon[current_weapon_index]

func _weapon_data() -> Dictionary:
	return WEAPON_DEFS[current_weapon_index]

func _store_weapon_ammo() -> void:
	ammo_by_weapon[current_weapon_index] = ammo
	reserve_by_weapon[current_weapon_index] = reserve_ammo

func _switch_weapon(index: int) -> void:
	if is_dead or index < 0 or index >= WEAPON_DEFS.size() or grenade_anim_state != GrenadeActionState.IDLE:
		return
	if not role_weapon_indices.has(index):
		return
	var was_shovel_equipped := is_shovel_equipped
	is_shovel_equipped = false
	if index == current_weapon_index:
		if was_shovel_equipped:
			_equip_weapon_visual()
			_refresh_ammo()
		return
	_store_weapon_ammo()
	is_reloading = false
	reload_timer = 0.0
	fire_cooldown = minf(fire_cooldown, 0.22)
	_set_aiming(false)
	if mobile_controls != null and mobile_controls.has_method("reset_aim"):
		mobile_controls.call("reset_aim")
	if index != SIDEARM_INDEX:
		last_primary_weapon_index = index
	current_weapon_index = index
	ammo = ammo_by_weapon[index]
	reserve_ammo = reserve_by_weapon[index]
	weapon_kick = 0.0
	if weapon_mount != null:
		weapon_mount.rotation = Vector3.ZERO
	_equip_weapon_visual()
	_refresh_ammo()
	_play_sfx(sfx_ui, SFX_UI, -6.0, 1.0)

func _cycle_weapon(direction: int) -> void:
	if role_weapon_indices.is_empty():
		return
	var slot := role_weapon_indices.find(current_weapon_index)
	if slot < 0:
		slot = 0
	slot = posmod(slot + direction, role_weapon_indices.size())
	_switch_weapon(role_weapon_indices[slot])

func _select_weapon_slot(slot: int) -> void:
	if slot < 0 or slot >= role_weapon_indices.size():
		return
	_switch_weapon(role_weapon_indices[slot])

func _toggle_sidearm() -> void:
	if is_dead or input_locked or grenade_anim_state != GrenadeActionState.IDLE:
		return
	if is_shovel_equipped:
		is_shovel_equipped = false
		_equip_weapon_visual()
	if current_weapon_index == SIDEARM_INDEX:
		_switch_weapon(last_primary_weapon_index)
	else:
		last_primary_weapon_index = current_weapon_index
		_switch_weapon(SIDEARM_INDEX)

func _toggle_shovel() -> void:
	if is_dead or input_locked or active_drone != null or grenade_anim_state != GrenadeActionState.IDLE:
		return
	is_shovel_equipped = not is_shovel_equipped
	is_reloading = false
	_set_aiming(false)
	if mobile_controls != null:
		mobile_controls.reset_aim()
	_equip_weapon_visual()
	_refresh_ammo()

func _on_shovel_button() -> void:
	if is_shovel_equipped and carried_soil > 0:
		_use_shovel_action(true)
	else:
		_toggle_shovel()

func _build_body() -> void:
	var team := str(get_tree().get_meta("selected_team", "IRON LEGION"))
	var body = PLAYER_BODY.new()
	body.name = "PlayerBody"
	body.position = Vector3(0.0, 0.0, -0.45)
	add_child(body)
	body.setup(team.to_upper().contains("RED"), wrist_left_marker, wrist_right_marker)
	body.visible = false  # торс/ноги не должны закрывать обзор при взгляде вниз
	player_body = body
	if player_role == "RADIO_OPERATOR":
		drone_controller_view = WEAPON_MESHES.make_weapon("drone_controller")
		if drone_controller_view != null:
			drone_controller_view.name = "RadioController"
			drone_controller_view.position = Vector3(0.20, 1.36, -0.11)
			drone_controller_view.visible = false
			player_body.add_child(drone_controller_view)

func set_drone_controller_feed(feed: Texture2D) -> void:
	if drone_controller_view == null or not is_instance_valid(drone_controller_view):
		return
	var screen := drone_controller_view.get_node_or_null("Screen") as MeshInstance3D
	if screen == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_texture = feed
	material.albedo_color = Color.WHITE
	material.roughness = 0.35
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen.material_override = material

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

	_add_view_hand(wrist_right_marker, false)
	_add_view_hand(wrist_left_marker, true)
	_view_arm_left = _make_view_arm("ViewArmL")
	_view_arm_right = _make_view_arm("ViewArmR")

func _make_view_arm(arm_name: String) -> MeshInstance3D:
	var arm := MeshInstance3D.new()
	arm.name = arm_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.050
	mesh.height = 1.0
	mesh.radial_segments = 8
	arm.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.10, 0.10, 0.08)
	material.roughness = 1.0
	arm.material_override = material
	arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if camera != null:
		camera.add_child(arm)
	return arm

func _update_view_arms() -> void:
	if camera == null:
		return
	if not SHOW_VIEW_ARMS:
		if _view_arm_left != null:
			_view_arm_left.visible = false
		if _view_arm_right != null:
			_view_arm_right.visible = false
		return
	if wrist_left_marker != null and _view_arm_left != null:
		var l_end := wrist_left_marker.global_position
		var l_start := l_end + camera.global_transform.basis * Vector3(-0.035, 0.055, 0.14)
		_place_view_arm(_view_arm_left, l_start, l_end)
	if wrist_right_marker != null and _view_arm_right != null:
		var r_end := wrist_right_marker.global_position
		var r_start := r_end + camera.global_transform.basis * Vector3(0.035, 0.055, 0.14)
		_place_view_arm(_view_arm_right, r_start, r_end)

func _place_view_arm(arm: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	var delta := end - start
	var length := delta.length()
	if length < 0.02:
		arm.visible = false
		return
	arm.visible = true
	var dir := delta / length
	arm.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, dir)).scaled(Vector3(1.0, length, 1.0)), (start + end) * 0.5)

## Низкополигональная кисть на оружии. Заменяет длинные IK-руки,
## которые вытягивались через весь экран.
func _add_view_hand(marker: Node3D, is_left: bool) -> void:
	var glove := StandardMaterial3D.new()
	glove.albedo_color = Color(0.17, 0.14, 0.11)
	glove.roughness = 0.92

	var hand := MeshInstance3D.new()
	hand.name = "HandL" if is_left else "HandR"
	var palm := BoxMesh.new()
	palm.size = Vector3(0.12, 0.10, 0.18)
	hand.mesh = palm
	hand.material_override = glove
	hand.position = Vector3(0.0, -0.015, -0.06)
	hand.rotation = Vector3(deg_to_rad(-6.0), deg_to_rad(9.0 if is_left else -9.0), 0.0)
	hand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(hand)

	var thumb := MeshInstance3D.new()
	thumb.name = "Thumb"
	var thumb_mesh := BoxMesh.new()
	thumb_mesh.size = Vector3(0.045, 0.05, 0.09)
	thumb.mesh = thumb_mesh
	thumb.material_override = glove
	thumb.position = Vector3(0.055 if is_left else -0.055, 0.01, -0.055)
	thumb.rotation = Vector3(deg_to_rad(12.0), 0.0, deg_to_rad(18.0 if is_left else -18.0))
	thumb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(thumb)

	var cuff := MeshInstance3D.new()
	cuff.name = "Cuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.045
	cuff_mesh.bottom_radius = 0.055
	cuff_mesh.height = 0.15
	cuff_mesh.radial_segments = 8
	cuff.mesh = cuff_mesh
	cuff.material_override = glove
	cuff.position = Vector3(0.0, -0.01, 0.07)
	cuff.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Рукав пока скрыт: на низкополигональной модели он читается как чёрный блок.
	cuff.visible = false
	marker.add_child(cuff)

func _set_aiming(enabled: bool) -> void:
	if aiming == enabled or is_dead or input_locked:
		return
	aiming = enabled

func _update_camera_fov(delta: float) -> void:
	if camera == null:
		return
	var target_fov := GameSettings.fov
	if aiming:
		var wid: String = str(_weapon_data().id)
		if wid == "kar98k":
			target_fov *= 0.38
		elif wid == "mosin":
			target_fov *= 0.58
		else:
			target_fov *= 0.78
	camera.fov = lerpf(camera.fov, target_fov, clampf(delta * 9.0, 0.0, 1.0))

func _build_pause_menu() -> void:
	pause_menu = PAUSE_MENU.new()
	add_child(pause_menu)
	pause_menu.resumed.connect(_on_pause_resumed)

	# Кнопка паузы для телефона и мыши; клавиатура использует ESC.
	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_right = 1.0
	pause_btn.offset_left = -108.0
	pause_btn.offset_right = -20.0
	pause_btn.offset_top = 16.0
	pause_btn.offset_bottom = 56.0
	pause_btn.add_theme_font_size_override("font_size", 18)
	pause_btn.pressed.connect(open_pause_menu)
	if hud != null:
		hud.add_child(pause_btn)

func open_pause_menu() -> void:
	if pause_menu != null and not get_tree().paused:
		pause_menu.open()

func _on_pause_resumed() -> void:
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_input_locked(locked: bool) -> void:
	input_locked = locked
	if locked:
		velocity = Vector3.ZERO
		mobile_fire = false
		if pickup_label != null:
			pickup_label.visible = false
		if mobile_controls != null:
			mobile_controls.visible = false
			mobile_controls.set_interact_visible(false)
		if death_screen != null:
			death_screen.visible = false
		if crosshair != null:
			crosshair.visible = false
	else:
		if mobile_controls != null:
			mobile_controls.visible = true
		if crosshair != null:
			crosshair.visible = not aiming

func _build_audio() -> void:
	sfx_shot = _make_sfx(COMBAT_AUDIO.BUS_COMBAT_DIRECT)
	sfx_empty = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_reload_out = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_reload_in = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_ui = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_footstep = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_hit = _make_sfx(COMBAT_AUDIO.BUS_SFX)
	sfx_kill = _make_sfx(COMBAT_AUDIO.BUS_SFX)

func _make_sfx(bus_name: StringName = &"SFX") -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.max_polyphony = 4
	p.bus = bus_name
	add_child(p)
	return p

func _update_acoustics(delta: float) -> void:
	_acoustic_timer -= delta
	if _acoustic_timer <= 0.0:
		_acoustic_timer = 0.25 # 4 раза в секунду — оптимально для 60 FPS на мобилках
		if camera != null and is_inside_tree():
			var world_3d := get_world_3d()
			var under_roof := COMBAT_AUDIO.is_indoors(world_3d, camera.global_position, 8.5)
			var target_factor := 1.0 if under_roof else 0.0
			indoor_factor = lerpf(indoor_factor, target_factor, 0.45)

func _play_player_shot_sfx(wid: String, default_pitch: float) -> void:
	var prof: Dictionary = COMBAT_AUDIO.WEAPON_PROFILES.get(wid, {})
	var pitch: float = float(prof.get("pitch", default_pitch)) * randf_range(0.96, 1.04)
	var vol: float = float(prof.get("vol", -2.0))
	if indoor_factor > 0.35:
		vol += indoor_factor * 1.5
		sfx_shot.bus = COMBAT_AUDIO.BUS_INDOOR_REVERB
	else:
		sfx_shot.bus = COMBAT_AUDIO.BUS_COMBAT_DIRECT
	_play_sfx(sfx_shot, WEAPON_SOUND.get_shot(wid), vol, pitch)

func _play_sfx(player: AudioStreamPlayer, stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	if player == null or stream == null:
		return
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()

func _touch_ui_enabled() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

func _build_mobile_controls() -> void:
	# На ПК с мышью сенсорные кнопки только засоряют экран.
	if not _touch_ui_enabled():
		return
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
	if mobile_controls.has_signal("grenade_changed"):
		mobile_controls.grenade_changed.connect(_on_mobile_grenade_changed)
	else:
		mobile_controls.grenade_pressed.connect(_throw_grenade)
	mobile_controls.smoke_pressed.connect(_throw_smoke)
	mobile_controls.heal_pressed.connect(_use_heal)
	mobile_controls.peek_left_changed.connect(_on_mobile_peek_left)
	mobile_controls.peek_right_changed.connect(_on_mobile_peek_right)
	mobile_controls.cycle_weapon_pressed.connect(func(): _cycle_weapon(1))
	if mobile_controls.has_signal("sidearm_pressed"):
		mobile_controls.sidearm_pressed.connect(_toggle_sidearm)
	if mobile_controls.has_signal("shovel_pressed"):
		mobile_controls.shovel_pressed.connect(_on_shovel_button)
	mobile_controls.interact_pressed.connect(_interact_with_pickup)
	if mobile_controls.has_signal("drone_pressed"):
		mobile_controls.drone_pressed.connect(_launch_drone)
	if mobile_controls.has_signal("drone_vertical_changed"):
		mobile_controls.drone_vertical_changed.connect(_on_drone_vertical_changed)
	if player_role == "RADIO_OPERATOR":
		mobile_controls.set_drone_visible(true)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)

	blood_overlay = ColorRect.new()
	blood_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blood_overlay.color = Color(0.7, 0.0, 0.0, 0.0)
	blood_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(blood_overlay)

	# Мягкая процедурная виньетка оптической линзы нательной камеры (Bodycam Vignette)
	bodycam_vignette = ColorRect.new()
	bodycam_vignette.name = "BodycamVignette"
	bodycam_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bodycam_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vign_mat := ShaderMaterial.new()
	var vign_shader := Shader.new()
	vign_shader.code = """
shader_type canvas_item;
void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    float vig = smoothstep(0.42, 0.74, dist);
    COLOR = vec4(0.01, 0.02, 0.03, vig * 0.45);
}
"""
	vign_mat.shader = vign_shader
	bodycam_vignette.material = vign_mat
	hud.add_child(bodycam_vignette)

	# Нательный OSD бодикамеры (Bodycam OSD): правый верхний угол левее кнопки паузы
	var bodycam_container := VBoxContainer.new()
	bodycam_container.name = "BodycamOSD"
	bodycam_container.anchor_left = 1.0
	bodycam_container.anchor_right = 1.0
	bodycam_container.offset_left = -440.0
	bodycam_container.offset_right = -120.0
	bodycam_container.offset_top = 16.0
	bodycam_container.offset_bottom = 64.0
	bodycam_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bodycam_container.add_theme_constant_override("separation", 2)
	hud.add_child(bodycam_container)

	var line1 := HBoxContainer.new()
	line1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bodycam_container.add_child(line1)

	var cam_title := Label.new()
	cam_title.text = "AXON BODY 4   "
	cam_title.add_theme_font_size_override("font_size", 14)
	cam_title.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 0.88))
	cam_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	cam_title.add_theme_constant_override("shadow_offset_x", 2)
	cam_title.add_theme_constant_override("shadow_offset_y", 2)
	cam_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line1.add_child(cam_title)

	bodycam_rec_dot = Label.new()
	bodycam_rec_dot.text = "● REC"
	bodycam_rec_dot.add_theme_font_size_override("font_size", 14)
	bodycam_rec_dot.add_theme_color_override("font_color", Color(1.0, 0.18, 0.15, 1.0))
	bodycam_rec_dot.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	bodycam_rec_dot.add_theme_constant_override("shadow_offset_x", 2)
	bodycam_rec_dot.add_theme_constant_override("shadow_offset_y", 2)
	bodycam_rec_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line1.add_child(bodycam_rec_dot)

	bodycam_osd_label = Label.new()
	bodycam_osd_label.text = "2026-11-08 14:32:05Z   BAT 94%"
	bodycam_osd_label.add_theme_font_size_override("font_size", 13)
	bodycam_osd_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.90, 0.80))
	bodycam_osd_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	bodycam_osd_label.add_theme_constant_override("shadow_offset_x", 2)
	bodycam_osd_label.add_theme_constant_override("shadow_offset_y", 2)
	bodycam_osd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bodycam_container.add_child(bodycam_osd_label)

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
	ammo_label.offset_top = -78.0
	ammo_label.offset_bottom = -38.0
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
	equip_label.offset_left = -640.0
	equip_label.offset_right = -24.0
	equip_label.offset_top = -112.0
	equip_label.offset_bottom = -82.0
	equip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	equip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equip_label.add_theme_font_size_override("font_size", 15)
	equip_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.55))
	hud.add_child(equip_label)

	# На телефоне патроны и экипировка размещаются левее блока кнопок огня и приседа (не перекрывая aim)
	if _touch_ui_enabled():
		ammo_label.anchor_left = 1.0
		ammo_label.anchor_right = 1.0
		ammo_label.anchor_top = 1.0
		ammo_label.anchor_bottom = 1.0
		ammo_label.offset_left = -560.0
		ammo_label.offset_right = -170.0
		ammo_label.offset_top = -68.0
		ammo_label.offset_bottom = -34.0
		ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		equip_label.anchor_left = 1.0
		equip_label.anchor_right = 1.0
		equip_label.anchor_top = 1.0
		equip_label.anchor_bottom = 1.0
		equip_label.offset_left = -660.0
		equip_label.offset_right = -170.0
		equip_label.offset_top = -102.0
		equip_label.offset_bottom = -72.0
		equip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	pickup_label = Label.new()
	pickup_label.anchor_left = 0.5
	pickup_label.anchor_right = 0.5
	pickup_label.anchor_top = 1.0
	pickup_label.anchor_bottom = 1.0
	pickup_label.offset_left = -220.0
	pickup_label.offset_right = 220.0
	pickup_label.offset_top = -92.0
	pickup_label.offset_bottom = -54.0
	pickup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pickup_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pickup_label.add_theme_font_size_override("font_size", 20)
	pickup_label.add_theme_color_override("font_color", Color(0.97, 0.88, 0.55))
	pickup_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.02, 0.95))
	pickup_label.add_theme_constant_override("shadow_offset_x", 2)
	pickup_label.add_theme_constant_override("shadow_offset_y", 2)
	pickup_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pickup_label.visible = false
	hud.add_child(pickup_label)

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
	if active_drone != null and is_instance_valid(active_drone):
		active_drone.drone_yaw -= delta.x * TOUCH_SENS * 1.5
		active_drone.drone_pitch = clampf(active_drone.drone_pitch - delta.y * TOUCH_SENS * 1.5, deg_to_rad(-45.0), deg_to_rad(45.0))
		return
	# QA-sweep bugfix: в технике взгляд идёт через тот же accumulate-путь —
	# иначе на мобильных камера не вращалась после посадки. Чувствительность
	# понижена: тяжёлая техника/турель наводится медленнее оружия.
	if mounted_vehicle != null and is_instance_valid(mounted_vehicle):
		var turret_sense := TOUCH_SENS * 0.62 * GameSettings.sensitivity_scale(false)
		yaw -= delta.x * turret_sense
		var mount_touch_pitch := delta.y * turret_sense
		if GameSettings.invert_y:
			mount_touch_pitch = -mount_touch_pitch
		pitch = clampf(pitch - mount_touch_pitch, -1.35, 1.35)
		return
	var zoom_factor := (camera.fov / GameSettings.fov) if camera != null else 1.0
	var sense := TOUCH_SENS * GameSettings.sensitivity_scale(aiming) * zoom_factor
	yaw -= delta.x * sense
	var pitch_delta := delta.y * sense
	if GameSettings.invert_y:
		pitch_delta = -pitch_delta
	pitch = clampf(pitch - pitch_delta, -1.35, 1.35)
	look_sway += Vector2(delta.x, delta.y) * 0.00035
	look_sway = look_sway.limit_length(0.045)

func _on_fire_changed(pressed: bool) -> void:
	mobile_fire = pressed
	if pressed and is_healing:
		_cancel_healing()
	if pressed and active_drone != null and is_instance_valid(active_drone):
		active_drone.detonate(active_drone.global_position)

func _on_mobile_peek_left(pressed: bool) -> void:
	mobile_lean_left = pressed

func _on_mobile_peek_right(pressed: bool) -> void:
	mobile_lean_right = pressed

func _on_drone_vertical_changed(direction: float, pressed: bool) -> void:
	drone_vertical_input = direction if pressed else 0.0

func _drone_tether_length() -> float:
	match str(get_tree().get_meta("selected_map", "BATTLEFIELD")):
		"VILLAGE":
			return 105.0
		"POLYGON":
			return 55.0
		_:
			return 150.0

func _launch_drone() -> void:
	if is_dead or input_locked or player_role != "RADIO_OPERATOR":
		return
	if active_drone != null and is_instance_valid(active_drone):
		active_drone.return_to_operator()
		return
	if not drone_charge_available or get_parent() == null:
		return
	drone_charge_available = false
	var drone: CharacterBody3D = RADIO_DRONE_SCRIPT.new()
	if drone == null:
		return
	get_parent().add_child(drone)
	var spawn_pos := drone_controller_anchor.global_position + (-camera.global_transform.basis.z * 0.45) + Vector3.UP * 0.08
	drone.launch(spawn_pos, yaw, self, _drone_tether_length())
	drone.returned.connect(_on_drone_returned)
	drone.detonated.connect(_on_drone_detonated)
	active_drone = drone
	camera.current = false
	if drone != null and drone.has_node("DroneCamera/DroneListener"):
		(drone.get_node("DroneCamera/DroneListener") as AudioListener3D).make_current()
	if drone_controller_view != null:
		drone_controller_view.visible = true
	if mobile_controls != null:
		mobile_controls.set_drone_mode(true)
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh_equipment()

func _on_drone_returned() -> void:
	_end_drone_control()

func _on_drone_detonated(_position: Vector3) -> void:
	_end_drone_control()

func _end_drone_control() -> void:
	active_drone = null
	drone_vertical_input = 0.0
	if drone_controller_view != null and is_instance_valid(drone_controller_view):
		drone_controller_view.visible = false
	if camera != null and is_instance_valid(camera):
		camera.current = true
		if audio_listener != null and is_instance_valid(audio_listener):
			audio_listener.make_current()
	if mobile_controls != null:
		mobile_controls.set_drone_mode(false)
	if not OS.has_feature("mobile") and not is_dead:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh_equipment()

func _update_drone_controls() -> void:
	if active_drone == null or not is_instance_valid(active_drone):
		return
	var move_x := mobile_move.x
	var move_y := mobile_move.y
	move_x += float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	move_y += float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	active_drone.move_input = Vector2(move_x, move_y).limit_length(1.0)
	var vertical := drone_vertical_input
	vertical += float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_CTRL))
	active_drone.vertical_input = clampf(vertical, -1.0, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead or input_locked:
		return
	if mounted_vehicle != null and is_instance_valid(mounted_vehicle):
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var sense := MOUSE_SENS * GameSettings.sensitivity_scale(false)
			yaw -= event.relative.x * sense
			var mount_pitch_delta: float = event.relative.y * sense
			if GameSettings.invert_y:
				mount_pitch_delta = -mount_pitch_delta
			pitch = clampf(pitch - mount_pitch_delta, -1.35, 1.35)
			look_sway += Vector2(event.relative.x, event.relative.y) * 0.00006
			look_sway = look_sway.limit_length(0.035)
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_F:
				_exit_vehicle()
			elif event.keycode == KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if mounted_vehicle != null:
		mounted_vehicle = null
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V and player_role == "RADIO_OPERATOR":
		_launch_drone()
		return
	if active_drone != null and is_instance_valid(active_drone):
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			active_drone.drone_yaw -= event.relative.x * MOUSE_SENS * 1.5
			active_drone.drone_pitch = clampf(active_drone.drone_pitch - event.relative.y * MOUSE_SENS * 1.5, deg_to_rad(-45.0), deg_to_rad(45.0))
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				active_drone.return_to_operator()
			elif event.keycode == KEY_ENTER:
				active_drone.detonate(active_drone.global_position)
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				active_drone.detonate(active_drone.global_position)
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var zoom_factor := (camera.fov / GameSettings.fov) if camera != null else 1.0
		var sense := MOUSE_SENS * GameSettings.sensitivity_scale(aiming) * zoom_factor
		yaw -= event.relative.x * sense
		var pitch_delta: float = event.relative.y * sense
		if GameSettings.invert_y:
			pitch_delta = -pitch_delta
		pitch = clampf(pitch - pitch_delta, -1.35, 1.35)
		look_sway += Vector2(event.relative.x, event.relative.y) * 0.00035
		look_sway = look_sway.limit_length(0.045)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not OS.has_feature("mobile"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_shoot()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_shovel_equipped:
			_use_shovel_action(true)
		else:
			_set_aiming(not aiming)
	elif event is InputEventMouseButton and event.pressed and not OS.has_feature("mobile"):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_weapon(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_weapon(1)
	elif event is InputEventKey:
		if event.keycode == KEY_G:
			if event.pressed and not event.echo:
				_start_grenade_hold()
			elif not event.pressed:
				_release_grenade_throw()
			return
		if not event.pressed or event.echo:
			return
		if event.keycode == KEY_9:
			_toggle_sidearm()
		elif event.keycode == KEY_0 or event.keycode == KEY_B:
			_toggle_shovel()
		elif event.keycode == KEY_R:
			_reload()
		elif event.keycode == KEY_C:
			_down_action()
		elif event.keycode == KEY_SPACE:
			_up_action()
		elif event.keycode == KEY_X or event.keycode == KEY_T:
			_throw_smoke()
		elif event.keycode == KEY_H:
			_use_heal()
		elif event.keycode == KEY_F:
			_interact_with_pickup()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
			_select_weapon_slot(event.keycode - KEY_1)

func _physics_process(delta: float) -> void:
	if is_dead:
		is_vaulting = false
		if not is_on_floor():
			velocity.y -= 18.0 * delta
			move_and_slide()
		return
	if input_locked:
		is_vaulting = false
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if mounted_vehicle != null and is_instance_valid(mounted_vehicle):
		_process_mounted_vehicle(delta)
		# QA-sweep bugfix: без применения взгляда камера не вращалась в технике.
		_apply_look(delta)
		return
	if mounted_vehicle != null:
		mounted_vehicle = null
	if is_vaulting:
		_process_vault(delta)
		return
	if active_drone != null and is_instance_valid(active_drone):
		_update_drone_controls()
		velocity.x = move_toward(velocity.x, 0.0, 22.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 22.0 * delta)
		if not is_on_floor():
			velocity.y -= 18.0 * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return
	_refresh_pickup_prompt()
	_update_acoustics(delta)

	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	throwable_cooldown = maxf(0.0, throwable_cooldown - delta)
	shovel_action_cooldown = maxf(0.0, shovel_action_cooldown - delta)
	_update_grenade_animation(delta)
	if crosshair != null:
		var is_kar98k_scope := aiming and str(_weapon_data().id) == "kar98k"
		if crosshair.has_method("set_sniper_scope"):
			crosshair.call("set_sniper_scope", is_kar98k_scope)
		crosshair.visible = not is_dead and (is_kar98k_scope or not aiming)
	weapon_kick = lerpf(weapon_kick, 0.0, clampf(delta * 14.0, 0.0, 1.0))
	var blend := 1.0 - exp(-delta * 13.0)
	aim_blend = lerpf(aim_blend, 1.0 if aiming else 0.0, blend)
	_update_camera_fov(delta)
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
		var moving_to_cancel := mobile_move.length() > 0.15 or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D)
		if moving_to_cancel:
			_cancel_healing()
		else:
			heal_timer -= delta
			if heal_timer <= 0.0:
				if heal_target != null and is_instance_valid(heal_target) and not bool(heal_target.get("is_dead")):
					heal_target.set("health", minf(MAX_HEALTH, float(heal_target.get("health")) + 40.0))
				else:
					health = minf(MAX_HEALTH, health + 45.0)
				is_healing = false
				heal_target = null
				medkits = maxi(0, medkits - 1)
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

	# Bodycam / Dummy War физика оружия: вес, покачивание и свободная наводка
	var run_boost := 1.0 + sprint_anim * 0.9
	var bob_factor := 0.20 if aiming else 1.0
	var bob_offset := Vector3(
		sin(bob_time) * 0.010 * run_boost * bob_factor,
		absf(cos(bob_time)) * 0.009 * run_boost * bob_factor,
		0.0
	)
	var breath_offset := Vector3(0.0, sin(breathing_time * 1.8) * 0.002, 0.0)
	var kick_offset := Vector3(0.0, 0.020, 0.05) * weapon_kick

	# Подавление свободного sway при прицеливании для идеального ADS (аудит QA)
	var sway_mult := 1.0 - aim_blend * 0.90
	var sway_pos := Vector3(-look_sway.x * 0.85, look_sway.y * 0.85, 0.0) * sway_mult
	var sway_rot := Vector3(look_sway.y * 1.8, -look_sway.x * 2.2, look_sway.x * 1.5) * sway_mult
	look_sway = look_sway.lerp(Vector2.ZERO, clampf(delta * 9.0, 0.0, 1.0))

	var stance_offset := Vector3.ZERO
	if stance == 1:
		stance_offset = Vector3(0.0, -0.015, 0.02)
	elif stance == 2:
		stance_offset = Vector3(0.0, -0.06, 0.05)

	# Тактический спринт (Low Ready / удержание оружия при беге)
	var sprint_offset := Vector3(0.06, -0.11, 0.04) * sprint_anim
	var sprint_rot := Vector3(sprint_anim * 0.20, sprint_anim * 0.12, -sprint_anim * 0.35)

	# Просадка оружия при приземлении
	var landing_offset := Vector3(0.0, -0.05, 0.03) * landing_anim
	var landing_rot := Vector3(landing_anim * 0.10, 0.0, 0.0)

	var target_weapon_pos := weapon_base.lerp(weapon_aim_position, aim_blend) + kick_offset + bob_offset + breath_offset + sway_pos + stance_offset + sprint_offset + landing_offset
	weapon_root.position = weapon_root.position.lerp(target_weapon_pos, clampf(delta * 22.0, 0.0, 1.0))

	var strafe_roll := -mobile_move.x * deg_to_rad(2.2) if not aiming else 0.0
	weapon_root.rotation = Vector3(
		-weapon_kick * 0.22 + sway_rot.x + sprint_rot.x + landing_rot.x,
		sway_rot.y + sprint_rot.y,
		sway_rot.z + sprint_rot.z - strafe_roll * 0.40
	)
	_update_view_arms()

	if muzzle_flash_time > 0.0:
		muzzle_flash_time -= delta
		if muzzle_flash_time <= 0.0 and muzzle_flash != null:
			muzzle_flash.visible = false

	if is_reloading:
		reload_timer -= delta
		var reload_total: float = float(_weapon_data().get("reload", 2.2))
		var progress := 1.0 - clampf(reload_timer / maxf(0.01, reload_total), 0.0, 1.0)
		if weapon_mount != null:
			weapon_mount.rotation.z = sin(progress * PI) * 0.14
			weapon_mount.rotation.x = -sin(progress * PI) * 0.08
		if left_arm_pivot != null:
			var reach_offset := Vector3(0.0, -0.10 * sin(progress * PI), 0.06 * sin(progress * PI))
			left_arm_pivot.position = left_arm_base + reach_offset
		if reload_timer <= 0.0:
			var need := int(_weapon_data().mag) - ammo
			var take := mini(need, reserve_ammo)
			ammo += take
			reserve_ammo -= take
			is_reloading = false
			if weapon_mount != null:
				weapon_mount.rotation = Vector3.ZERO
			if left_arm_pivot != null:
				left_arm_pivot.position = left_arm_base
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
	if player_role == "ASSAULT" and current_speed == SPRINT_SPEED:
		current_speed *= 1.08
	if stance == 1:
		current_speed *= 0.55
	elif stance == 2:
		current_speed *= 0.25

	# Вес оружия и замедление при ранении (TASK-0006)
	var weapon_weight_factor := 1.0
	match str(_weapon_data().id):
		"m1911": weapon_weight_factor = 1.02
		"mp40", "ppsh41": weapon_weight_factor = 0.97
		"ak47", "shotgun": weapon_weight_factor = 0.94
		"mosin", "kar98k": weapon_weight_factor = 0.90
		"panzerfaust": weapon_weight_factor = 0.80

	if health < 35.0:
		current_speed = minf(current_speed * 0.88, SPEED * 0.92)

	var direction := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
	var target_vel := direction * (current_speed * weapon_weight_factor)
	var accel := 28.0 if direction.length_squared() > 0.01 else 20.0
	velocity.x = move_toward(velocity.x, target_vel.x, accel * delta * current_speed)
	velocity.z = move_toward(velocity.z, target_vel.z, accel * delta * current_speed)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	var fall_speed := velocity.y
	move_and_slide()

	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor and fall_speed < -3.0:
		landing_anim = 1.0
		_play_sfx(sfx_footstep, SFX_FOOTSTEPS[0], -2.5, 0.74) # Глухой тактический звук приземления и снаряжения
	_was_on_floor = on_floor
	landing_anim = maxf(0.0, landing_anim - delta * 5.0)
	var sprint_target := 1.0 if (planar_speed > SPEED + 0.4 and not aiming and stance == 0 and on_floor) else 0.0
	sprint_anim = lerpf(sprint_anim, sprint_target, clampf(delta * 8.0, 0.0, 1.0))

	# Обновление времени и OSD бодикамеры (Bodycam)
	bodycam_time += delta
	if bodycam_rec_dot != null:
		bodycam_rec_dot.modulate.a = 0.30 + 0.70 * absf(sin(bodycam_time * 3.6))
	if bodycam_osd_label != null:
		var dt := Time.get_datetime_dict_from_system()
		bodycam_osd_label.text = "%04d-%02d-%02d %02d:%02d:%02dZ   BAT 94%%" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]

	recoil = recoil.lerp(Vector2.ZERO, clampf(delta * 7.0, 0.0, 1.0))
	var target_height := 1.95 if stance == 0 else (1.35 if stance == 1 else 0.70)
	player_capsule.height = lerpf(player_capsule.height, target_height, clampf(delta * 10.0, 0.0, 1.0))
	player_collision.position.y = player_capsule.height * 0.5
	var target_y := 1.70 if stance == 0 else (1.28 if stance == 1 else 0.52)
	var cam_bob_y := absf(sin(bob_time * 2.0)) * 0.014 * run_boost * bob_factor
	var cam_bob_x := sin(bob_time) * 0.010 * run_boost * bob_factor
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
	camera.position.y = lerpf(camera.position.y, target_y + cam_bob_y - landing_anim * 0.09, delta * 12.0)
	camera.position.x = lerpf(camera.position.x, cam_bob_x + lean_amount * 0.42, delta * 12.0)
	if player_body != null:
		player_body.set_motion(planar_speed, planar_speed > SPEED + 0.5)
		player_body.set_stance(stance)
		var look_down := clampf((-pitch - 0.22) / 0.45, 0.0, 1.0)
		player_body.set_look_down(look_down)
	_apply_look(delta)

## === Техника и турели (TASK-0012) ===

func _process_mounted_vehicle(delta: float) -> void:
	velocity = Vector3.ZERO
	if mounted_vehicle.has_method("tick_driver"):
		mounted_vehicle.call("tick_driver", self, delta)
	var firing := mobile_fire or (not OS.has_feature("mobile") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	if firing and mounted_vehicle.has_method("try_fire"):
		mounted_vehicle.call("try_fire", self)
	_refresh_pickup_prompt()

func _enter_vehicle(vehicle: Node3D) -> void:
	if is_dead or input_locked or mounted_vehicle != null:
		return
	if vehicle == null or not is_instance_valid(vehicle):
		return
	if not vehicle.has_method("enter") or not bool(vehicle.call("can_enter", self)):
		return
	mounted_vehicle = vehicle
	vehicle.call("enter", self)
	if vehicle is PhysicsBody3D:
		add_collision_exception_with(vehicle)
	velocity = Vector3.ZERO
	if weapon_root != null:
		weapon_root.visible = false
	var eye_height := 1.20
	if vehicle.has_method("driver_eye_height"):
		eye_height = float(vehicle.call("driver_eye_height"))
	camera.position.y = eye_height
	if vehicle.has_method("seat_position"):
		global_position = vehicle.call("seat_position")

func _exit_vehicle() -> void:
	var vehicle := mounted_vehicle
	mounted_vehicle = null
	if vehicle != null and is_instance_valid(vehicle):
		if vehicle.has_method("exit_vehicle"):
			vehicle.call("exit_vehicle", self)
		if vehicle is PhysicsBody3D:
			remove_collision_exception_with(vehicle)
		if vehicle.has_method("exit_position"):
			global_position = vehicle.call("exit_position")
	velocity = Vector3.ZERO
	# Стоячая высота камеры после высадки (lerp в _physics_process дочекается).
	camera.position.y = 1.70
	if weapon_root != null and not is_dead:
		weapon_root.visible = true
	if player_body != null and not is_dead:
		player_body.visible = false

func _nearest_enterable() -> Node3D:
	if mounted_vehicle != null:
		return null
	var nearest: Node3D = null
	var best_distance := 2.8
	for node in get_tree().get_nodes_in_group("enterable_vehicles"):
		var station := node as Node3D
		if station == null or not is_instance_valid(station):
			continue
		if not station.has_method("can_enter") or not bool(station.call("can_enter", self)):
			continue
		var distance := global_position.distance_to(station.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest = station
	return nearest

func _apply_look(delta: float = 0.016) -> void:
	rotation.y = yaw
	var strafe_roll := -mobile_move.x * deg_to_rad(2.2) if not aiming else 0.0

	# Инерция и упругий лаг нательной камеры (Bodycam)
	var cam_lag_speed := lerpf(16.0, 38.0, aim_blend)
	cam_yaw = lerp_angle(cam_yaw, yaw, clampf(delta * cam_lag_speed, 0.0, 1.0))
	cam_pitch = lerpf(cam_pitch, pitch, clampf(delta * cam_lag_speed, 0.0, 1.0))
	var yaw_diff := wrapf(cam_yaw - yaw, -PI, PI)
	var yaw_speed := (yaw - last_applied_yaw) / maxf(delta, 0.001)
	last_applied_yaw = yaw
	var turn_roll := clampf(-yaw_speed * 0.010, -deg_to_rad(3.5), deg_to_rad(3.5)) * (1.0 - aim_blend * 0.85)

	# Сотрясение камеры (Травма от выстрелов и взрывов)
	cam_shake_trauma = maxf(0.0, cam_shake_trauma - delta * 4.2)
	var shake_mag := cam_shake_trauma * cam_shake_trauma
	var shake_rot := Vector3(
		randf_range(-1.0, 1.0) * deg_to_rad(2.2) * shake_mag,
		randf_range(-1.0, 1.0) * deg_to_rad(1.8) * shake_mag,
		randf_range(-1.0, 1.0) * deg_to_rad(2.5) * shake_mag
	)

	var run_boost := 1.0 + sprint_anim * 0.9
	var bob_factor := 0.20 if aiming else 1.0
	var cam_bob_roll := cos(bob_time) * deg_to_rad(1.3 * run_boost) * bob_factor if not aiming else 0.0

	var total_roll := -lean_amount * deg_to_rad(9.5) + strafe_roll + turn_roll + cam_bob_roll + shake_rot.z
	camera.rotation = Vector3(
		clampf(cam_pitch + recoil.y - landing_anim * deg_to_rad(3.5) + shake_rot.x, -1.45, 1.45),
		yaw_diff * 0.65 + recoil.x + shake_rot.y,
		total_roll
	)

func add_camera_trauma(amount: float) -> void:
	cam_shake_trauma = clampf(cam_shake_trauma + amount, 0.0, 1.0)

func apply_explosion_shake(explosion_pos: Vector3, radius: float = 32.0, max_trauma: float = 0.95) -> void:
	var dist := global_position.distance_to(explosion_pos)
	if dist < radius:
		var factor := 1.0 - (dist / radius)
		add_camera_trauma(factor * max_trauma)
		recoil.y += factor * 0.08
		recoil.x += randf_range(-factor, factor) * 0.06

func _down_action() -> void:
	if is_dead or input_locked:
		return
	stance = mini(2, stance + 1)

func _up_action() -> void:
	if is_dead or input_locked:
		return
	if stance > 0:
		stance -= 1
		return
	if _try_vault():
		return
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func _shoot() -> void:
	if grenade_anim_state != GrenadeActionState.IDLE:
		return
	if is_shovel_equipped:
		_use_shovel_action(false)
		return
	if is_healing:
		_cancel_healing()
	if is_reloading or fire_cooldown > 0.0 or is_dead or input_locked:
		return
	var weapon := _weapon_data()
	if ammo <= 0:
		if reserve_ammo > 0 and not is_reloading:
			_reload()
		else:
			_play_sfx(sfx_empty, SFX_EMPTY, -5.0, randf_range(0.95, 1.05))
			fire_cooldown = 0.25
		return
	ammo -= 1
	fire_cooldown = float(weapon.interval)
	_store_weapon_ammo()
	_refresh_ammo()
	_play_player_shot_sfx(str(weapon.id), float(weapon.pitch))

	if str(weapon.id) == "panzerfaust":
		recoil.y = minf(recoil.y + 0.055, 0.18)
		recoil.x = clampf(recoil.x + randf_range(-0.015, 0.015), -0.06, 0.06)
		weapon_kick = 0.16
		if muzzle_flash != null:
			muzzle_flash.visible = true
			muzzle_flash_time = 0.08
		_apply_look()
		var shoot_dir := -camera.global_transform.basis.z
		var desired_spawn := camera.global_position + shoot_dir * 0.45 + camera.global_transform.basis.x * 0.14 - camera.global_transform.basis.y * 0.08
		var wall_query := PhysicsRayQueryParameters3D.create(camera.global_position, desired_spawn)
		wall_query.collision_mask = WORLD_LAYER_MASK
		wall_query.exclude = [get_rid()]
		var wall_hit := get_world_3d().direct_space_state.intersect_ray(wall_query)
		var spawn_pos := desired_spawn
		if not wall_hit.is_empty():
			spawn_pos = wall_hit.position - shoot_dir * 0.10

		var rocket = ROCKET_PROJECTILE_SCRIPT.new()
		get_parent().add_child(rocket)
		var player_team: String = str(get_tree().get_meta("selected_team", "IRON LEGION"))
		rocket.launch(spawn_pos, shoot_dir, "Player", player_team, self)
		return

	var casing_pos := camera.global_position + camera.global_transform.basis.x * 0.22 - camera.global_transform.basis.y * 0.12 - camera.global_transform.basis.z * 0.35
	var casing_vel := camera.global_transform.basis.x * 2.6 + camera.global_transform.basis.y * 1.4 - camera.global_transform.basis.z * 0.4
	HIT_EFFECTS.spawn_casing(get_parent(), casing_pos, casing_vel)

	var kick_strength: float = 0.08
	var trauma_add: float = 0.18
	match str(weapon.id):
		"shotgun":
			kick_strength = 0.22
			trauma_add = 0.45
			recoil.y = minf(recoil.y + 0.038, 0.16)
			recoil.x = clampf(recoil.x + randf_range(-0.015, 0.015), -0.05, 0.05)
		"mosin", "kar98k":
			kick_strength = 0.18
			trauma_add = 0.38
			recoil.y = minf(recoil.y + 0.030, 0.15)
			recoil.x = clampf(recoil.x + randf_range(-0.012, 0.012), -0.045, 0.045)
		"ak47":
			kick_strength = 0.11
			trauma_add = 0.24
			recoil.y = minf(recoil.y + randf_range(0.012, 0.020), 0.14)
			recoil.x = clampf(recoil.x + randf_range(-0.008, 0.008), -0.045, 0.045)
		"mp40", "ppsh41":
			kick_strength = 0.07
			trauma_add = 0.14
			recoil.y = minf(recoil.y + randf_range(0.006, 0.011), 0.11)
			recoil.x = clampf(recoil.x + randf_range(-0.005, 0.005), -0.035, 0.035)
		_:
			kick_strength = 0.08
			trauma_add = 0.16
			recoil.y = minf(recoil.y + randf_range(0.008, 0.014), 0.12)
			recoil.x = clampf(recoil.x + randf_range(-0.006, 0.006), -0.04, 0.04)

	weapon_kick = kick_strength
	add_camera_trauma(trauma_add)
	if muzzle_flash != null:
		muzzle_flash.visible = true
		muzzle_flash_time = 0.045
	_apply_look()

	var spread := float(weapon.spread) * (0.42 if aiming else 1.0)
	if stance == 0 and (mobile_move.length() > 0.2 or velocity.length() > SPEED + 0.5):
		spread += 0.012
	var bullet_origin := weapon_muzzle.global_position if is_instance_valid(weapon_muzzle) else camera.global_position
	# The camera ray selects the point the player is aiming at; it never applies
	# damage. The actual round travels from the muzzle to that point and collides
	# along its own path, preserving the visible muzzle-to-sight parallax.
	var camera_direction := -camera.global_transform.basis.z
	var aim_end := camera.global_position + camera_direction * float(weapon["range"])
	var aim_query := PhysicsRayQueryParameters3D.create(camera.global_position, aim_end)
	aim_query.collision_mask = RAY_COLLISION_MASK
	aim_query.exclude = [get_rid()]
	aim_query.collide_with_areas = true
	var aim_hit := get_world_3d().direct_space_state.intersect_ray(aim_query)
	var aim_point: Vector3 = aim_hit.get("position", aim_end)
	var base_direction := (aim_point - bullet_origin).normalized()
	var player_team: String = str(get_tree().get_meta("selected_team", "IRON LEGION"))
	var pellet_count := int(weapon.pellets)
	for pellet_index in range(pellet_count):
		var dir := base_direction
		dir = dir.rotated(camera.global_transform.basis.y, randf_range(-spread, spread))
		dir = dir.rotated(camera.global_transform.basis.x, randf_range(-spread, spread))
		_spawn_ballistic_bullet(
			bullet_origin,
			dir,
			float(weapon.get("muzzle_velocity", 650.0)),
			int(weapon.damage),
			float(weapon["range"]),
			"Player",
			player_team,
			self
		)

func _shovel_target(ground: Node3D) -> Vector3:
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return Vector3.INF
	forward = forward.normalized()
	var guess := global_position + forward * 1.45
	guess = ground.call("clamp_to_map", guess)
	var floor_y := float(ground.call("surface_height_at", guess))
	var ray_from := camera.global_position
	var ray_to := Vector3(guess.x, floor_y - 0.25, guess.z)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collision_mask = WORLD_LAYER_MASK
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.get("collider") != ground:
		return Vector3.INF
	return hit.position

func _use_shovel_action(place_soil: bool) -> void:
	if not is_shovel_equipped or is_dead or input_locked or shovel_action_cooldown > 0.0:
		return
	var ground := get_tree().get_first_node_in_group("diggable_ground") as Node3D
	if ground == null:
		return
	var target := _shovel_target(ground)
	if target == Vector3.INF:
		return
	shovel_action_cooldown = 0.55
	if place_soil:
		if carried_soil <= 0 or not bool(ground.call("place_soil_at", target)):
			return
		carried_soil -= 1
	else:
		if carried_soil >= 6 or not bool(ground.call("dig_at", target)):
			return
		carried_soil += 1
	_refresh_ammo()
	_refresh_equipment()

func _spawn_ballistic_bullet(origin: Vector3, direction: Vector3, speed: float, damage: int, range_m: float, owner_name: String, owner_team: String, owner: Node) -> bool:
	var world := get_parent()
	if world == null:
		return false
	if world.has_method("spawn_bullet_projectile"):
		return bool(world.call("spawn_bullet_projectile", origin, direction, speed, damage, range_m, owner_name, owner_team, owner))
	var bullet = BULLET_PROJECTILE_SCRIPT.new()
	bullet.configure(origin, direction, speed, damage, range_m, owner_name, owner_team, owner)
	world.add_child(bullet)
	return true

func on_projectile_hit(actor: Node, damage_applied: int, was_alive: bool, _region: String) -> void:
	if not is_instance_valid(actor) or damage_applied <= 0:
		return
	_pop_damage(damage_applied)
	var world := get_parent()
	if world != null and world.has_method("record_player_damage"):
		world.call("record_player_damage", damage_applied)
	if not actor.is_in_group("explosive_barrels"):
		_play_sfx(sfx_hit, SFX_HIT_FLESH, -4.0, randf_range(0.9, 1.1))
	if crosshair != null:
		crosshair.flash_hit()
	if was_alive and actor.is_in_group("damageable_actor") and "health" in actor and float(actor.get("health")) <= 0.0:
		_play_sfx(sfx_kill, SFX_KILL, -2.0, 1.0)
		if world != null and world.has_method("add_kill"):
			world.call("add_kill")

func _reload() -> void:
	if is_shovel_equipped or grenade_anim_state != GrenadeActionState.IDLE:
		return
	var weapon := _weapon_data()
	if is_reloading or is_healing or ammo >= int(weapon.mag) or reserve_ammo <= 0 or is_dead or input_locked:
		return
	is_reloading = true
	reload_timer = float(weapon.reload)
	_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -6.0, 1.0)

func _build_grenade_view() -> void:
	if grenade_view_root != null and is_instance_valid(grenade_view_root):
		return
	grenade_view_root = WEAPON_MESHES.make_grenade_view_model()
	if grenade_view_root == null:
		return
	grenade_view_root.name = "GrenadeView"
	grenade_view_root.position = Vector3(0.18, -0.16, -0.38)
	grenade_view_root.scale = Vector3.ONE * 0.52
	grenade_view_root.visible = false
	camera.add_child(grenade_view_root)

	grenade_safety_lever = grenade_view_root.find_child("SafetyLever", true, false)
	grenade_pull_ring = grenade_view_root.find_child("PullRing", true, false)
	grenade_hand_left = grenade_view_root.find_child("HandLeft", true, false)
	grenade_hand_right = grenade_view_root.find_child("HandRight", true, false)

func _on_mobile_grenade_changed(pressed: bool) -> void:
	if pressed:
		_start_grenade_hold()
	else:
		_release_grenade_throw()

func _start_grenade_hold() -> void:
	if grenades <= 0 or is_dead or input_locked or is_healing or active_drone != null or is_reloading or is_vaulting:
		return
	is_grenade_held = true
	if grenade_anim_state == GrenadeActionState.IDLE or grenade_anim_state == GrenadeActionState.RECOVER:
		grenade_anim_state = GrenadeActionState.EQUIP
		grenade_anim_timer = 0.12
		grenade_has_spawned = false
		if grenade_view_root != null:
			grenade_view_root.visible = true
			grenade_view_root.position = Vector3(0.20, -0.36, -0.32)
			grenade_view_root.rotation = Vector3(deg_to_rad(-18.0), deg_to_rad(-10.0), 0.0)
			if grenade_pull_ring != null:
				grenade_pull_ring.position = Vector3(-0.035, 0.0, 0.0)
				grenade_pull_ring.visible = true
			if grenade_safety_lever != null:
				grenade_safety_lever.rotation = Vector3.ZERO
				grenade_safety_lever.visible = true
			if grenade_hand_left != null:
				grenade_hand_left.position = Vector3(-0.075, 0.065, 0.0)
				grenade_hand_left.visible = true
		_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -8.0, 1.35)

func _release_grenade_throw() -> void:
	is_grenade_held = false
	if grenade_anim_state == GrenadeActionState.HOLD_AIM:
		grenade_anim_state = GrenadeActionState.THROW_SWING
		grenade_anim_timer = 0.18
		_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -2.0, 1.45)
	elif grenade_anim_state == GrenadeActionState.PULL_PIN or grenade_anim_state == GrenadeActionState.EQUIP:
		pass

func _spawn_thrown_grenade() -> void:
	if grenade_has_spawned or grenades <= 0:
		return
	grenade_has_spawned = true
	grenades -= 1
	_refresh_equipment()
	var g := GRENADE_SCRIPT.new()
	if is_dead:
		# Мёртвый сброс гранаты под ноги (Dead-man drop при гибели во время замаха)
		g.position = global_position + Vector3(0.0, 0.45, 0.0)
		g.linear_velocity = Vector3(randf_range(-0.6, 0.6), 1.2, randf_range(-0.6, 0.6))
	else:
		var spawn_pos := camera.global_position + camera.global_transform.basis.x * 0.20 - camera.global_transform.basis.y * 0.10 - camera.global_transform.basis.z * 0.45
		var throw_dir := -camera.global_transform.basis.z + Vector3.UP * 0.24
		g.position = spawn_pos
		g.linear_velocity = throw_dir.normalized() * 20.5 + velocity * 0.45
	g.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
	g.thrower_name = "Player"
	g.team_name = str(get_tree().get_meta("selected_team", "IRON LEGION"))
	get_parent().add_child(g)
	_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -3.0, 1.4)
	if grenade_safety_lever != null:
		grenade_safety_lever.visible = false

func _update_grenade_animation(delta: float) -> void:
	if grenade_anim_state == GrenadeActionState.IDLE:
		if grenade_view_root != null and grenade_view_root.visible:
			grenade_view_root.visible = false
		return

	if weapon_root != null:
		weapon_root.position.y = lerpf(weapon_root.position.y, weapon_base.y - 0.28, delta * 14.0)

	grenade_anim_timer -= delta

	match grenade_anim_state:
		GrenadeActionState.EQUIP:
			if grenade_view_root != null:
				grenade_view_root.position = grenade_view_root.position.lerp(Vector3(0.18, -0.14, -0.36), delta * 18.0)
				grenade_view_root.rotation.x = lerpf(grenade_view_root.rotation.x, deg_to_rad(6.0), delta * 18.0)
			if grenade_anim_timer <= 0.0:
				grenade_anim_state = GrenadeActionState.PULL_PIN
				grenade_anim_timer = 0.16
				_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -4.0, 1.55)

		GrenadeActionState.PULL_PIN:
			var pull_progress := 1.0 - clampf(grenade_anim_timer / 0.16, 0.0, 1.0)
			if grenade_pull_ring != null:
				grenade_pull_ring.position.x = lerpf(-0.035, -0.16, pull_progress)
			if grenade_hand_left != null:
				grenade_hand_left.position.x = lerpf(-0.075, -0.22, pull_progress)
			if grenade_anim_timer <= 0.0:
				if grenade_pull_ring != null:
					grenade_pull_ring.visible = false
				if grenade_hand_left != null:
					grenade_hand_left.visible = false
				if is_grenade_held:
					grenade_anim_state = GrenadeActionState.HOLD_AIM
				else:
					grenade_anim_state = GrenadeActionState.THROW_SWING
					grenade_anim_timer = 0.18

		GrenadeActionState.HOLD_AIM:
			if grenade_view_root != null:
				var hold_target_pos := Vector3(0.24, -0.09, -0.30)
				var hold_target_rot := Vector3(deg_to_rad(28.0), deg_to_rad(-16.0), deg_to_rad(12.0))
				grenade_view_root.position = grenade_view_root.position.lerp(hold_target_pos, delta * 16.0)
				grenade_view_root.rotation = grenade_view_root.rotation.lerp(hold_target_rot, delta * 16.0)
			if not is_grenade_held:
				grenade_anim_state = GrenadeActionState.THROW_SWING
				grenade_anim_timer = 0.18

		GrenadeActionState.THROW_SWING:
			var swing_progress := 1.0 - clampf(grenade_anim_timer / 0.18, 0.0, 1.0)
			if grenade_view_root != null:
				var throw_target_pos := Vector3(0.06, -0.12, -0.62)
				var throw_target_rot := Vector3(deg_to_rad(-38.0), deg_to_rad(10.0), deg_to_rad(-14.0))
				grenade_view_root.position = grenade_view_root.position.lerp(throw_target_pos, delta * 26.0)
				grenade_view_root.rotation = grenade_view_root.rotation.lerp(throw_target_rot, delta * 26.0)
			if swing_progress >= 0.40 and not grenade_has_spawned:
				_spawn_thrown_grenade()
			if grenade_anim_timer <= 0.0:
				grenade_anim_state = GrenadeActionState.RECOVER
				grenade_anim_timer = 0.20
				if grenade_view_root != null:
					grenade_view_root.visible = false

		GrenadeActionState.RECOVER:
			if grenade_anim_timer <= 0.0:
				grenade_anim_state = GrenadeActionState.IDLE

func _throw_grenade() -> void:
	if grenades <= 0 or is_dead:
		return
	if grenade_anim_state == GrenadeActionState.IDLE:
		_start_grenade_hold()
		_release_grenade_throw()

## Механика паркура (преодоление заборов, подоконников и низких укрытий)
func _try_vault() -> bool:
	if is_dead or input_locked or is_vaulting or active_drone != null or grenade_anim_state != GrenadeActionState.IDLE:
		return false
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return false

	var fwd := -camera.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 0.01:
		fwd = -global_transform.basis.z
	fwd = fwd.normalized()

	# 1. Луч на уровне пояса (0.65 м)
	var waist_from := global_position + Vector3(0.0, 0.65, 0.0)
	var waist_to := waist_from + fwd * 1.35
	var q_waist := PhysicsRayQueryParameters3D.create(waist_from, waist_to)
	q_waist.collision_mask = WORLD_LAYER_MASK
	q_waist.exclude = [get_rid()]
	q_waist.collide_with_areas = false
	var waist_hit := space_state.intersect_ray(q_waist)
	if waist_hit.is_empty():
		return false

	var hit_pos: Vector3 = waist_hit.position

	# 2. Поиск верхней кромки уступа/подоконника
	var over_pos := hit_pos + fwd * 0.32 + Vector3(0.0, 1.40, 0.0)
	var down_to := over_pos + Vector3(0.0, -1.90, 0.0)
	var q_down := PhysicsRayQueryParameters3D.create(over_pos, down_to)
	q_down.collision_mask = WORLD_LAYER_MASK
	q_down.exclude = [get_rid()]
	q_down.collide_with_areas = false
	var top_hit := space_state.intersect_ray(q_down)
	if top_hit.is_empty():
		return false

	var ledge_y: float = top_hit.position.y
	var ledge_height: float = ledge_y - global_position.y
	if ledge_height < 0.40 or ledge_height > 1.55:
		return false

	# 3. Проверка свободного пространства сверху (для окна/забора)
	var head_from := hit_pos + Vector3(0.0, (ledge_y - hit_pos.y) + 0.15, 0.0)
	var head_to := head_from + Vector3(0.0, 1.15, 0.0)
	var q_head := PhysicsRayQueryParameters3D.create(head_from, head_to)
	q_head.collision_mask = WORLD_LAYER_MASK
	q_head.exclude = [get_rid()]
	var head_hit := space_state.intersect_ray(q_head)
	if not head_hit.is_empty():
		return false

	# 4. Проверка точки приземления
	var land_pos := hit_pos + fwd * 0.95
	var land_from := land_pos + Vector3(0.0, 1.0, 0.0)
	var land_to := land_from + Vector3(0.0, -2.6, 0.0)
	var q_land := PhysicsRayQueryParameters3D.create(land_from, land_to)
	q_land.collision_mask = WORLD_LAYER_MASK
	q_land.exclude = [get_rid()]
	var land_hit := space_state.intersect_ray(q_land)
	if not land_hit.is_empty():
		land_pos.y = land_hit.position.y
	else:
		land_pos.y = global_position.y

	is_vaulting = true
	vault_timer = 0.0
	vault_duration = 0.38
	vault_start_pos = global_position
	vault_peak_pos = Vector3(hit_pos.x, maxf(ledge_y + 0.28, global_position.y + 0.75), hit_pos.z)
	vault_land_pos = land_pos
	player_capsule.height = 1.15
	_play_sfx(sfx_footstep, SFX_FOOTSTEPS[0], -6.0, 1.25)
	return true

func _process_vault(delta: float) -> void:
	vault_timer += delta
	var t := clampf(vault_timer / maxf(0.01, vault_duration), 0.0, 1.0)
	var ease_t := smoothstep(0.0, 1.0, t)
	var target_horiz := vault_start_pos.lerp(vault_land_pos, ease_t)
	var arc := sin(t * PI) * (vault_peak_pos.y - minf(vault_start_pos.y, vault_land_pos.y) + 0.12)
	var target_y := lerpf(vault_start_pos.y, vault_land_pos.y, ease_t) + arc
	global_position = Vector3(target_horiz.x, target_y, target_horiz.z)

	var cam_dip := -sin(t * PI) * deg_to_rad(6.5)
	camera.rotation.x = clampf(pitch + recoil.y + cam_dip, -1.45, 1.45)
	if weapon_root != null:
		weapon_root.position.y = lerpf(weapon_root.position.y, weapon_base.y - 0.14 * sin(t * PI), delta * 24.0)
		weapon_root.rotation.z = lerpf(weapon_root.rotation.z, -deg_to_rad(15.0) * sin(t * PI), delta * 24.0)

	if t >= 1.0:
		is_vaulting = false
		global_position = vault_land_pos
		var fwd := (vault_land_pos - vault_start_pos)
		fwd.y = 0.0
		velocity = fwd.normalized() * SPRINT_SPEED
		velocity.y = -0.5
		landing_anim = 0.5
		player_capsule.height = 1.95 if stance == 0 else (1.35 if stance == 1 else 0.70)
		move_and_slide()

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
	if medkits <= 0 or is_dead or is_healing:
		return
	heal_target = null
	if player_role == "MEDIC":
		var player_team := str(get_tree().get_meta("selected_team", "IRON LEGION"))
		var nearest_dist := 6.5
		for bot in get_tree().get_nodes_in_group("bots"):
			if bot == null or not is_instance_valid(bot) or bool(bot.get("is_dead")):
				continue
			if str(bot.get("team_name")) != player_team or not ("health" in bot):
				continue
			var distance := global_position.distance_to((bot as Node3D).global_position)
			if float(bot.get("health")) < MAX_HEALTH and distance < nearest_dist:
				nearest_dist = distance
				heal_target = bot as Node3D
		if heal_target != null:
			var start := global_position + Vector3.UP * 1.1
			var finish := heal_target.global_position + Vector3.UP * 0.9
			var query := PhysicsRayQueryParameters3D.create(start, finish)
			query.collision_mask = WORLD_LAYER_MASK
			query.exclude = [get_rid()]
			if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				heal_target = null
	if heal_target == null and health >= MAX_HEALTH:
		return
	is_healing = true
	heal_timer = 2.2
	_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -4.0, 1.0)
	_refresh_equipment()

func _cancel_healing() -> void:
	if not is_healing:
		return
	is_healing = false
	heal_target = null
	heal_timer = 0.0
	_refresh_equipment()

func _refresh_ammo() -> void:
	if ammo_label == null:
		return
	if is_shovel_equipped:
		ammo_label.text = "ЛОПАТА   •   ГРУНТ %d / 6" % carried_soil
		return
	var weapon := _weapon_data()
	var slot := "ЗАПАСНОЙ" if current_weapon_index == SIDEARM_INDEX else str(current_weapon_index + 1)
	ammo_label.text = "%s  %s   %d / %d" % [slot, str(weapon.name), ammo, reserve_ammo]

func _refresh_health() -> void:
	if health_label != null:
		health_label.text = "HP %d" % int(round(health))
	if health_bar != null:
		health_bar.value = health

func _refresh_equipment() -> void:
	if equip_label != null:
		var role_names := {"ASSAULT": "ШТУРМ", "MEDIC": "МЕДИК", "SNIPER": "СНАЙПЕР", "ANTI_TANK": "ПТ", "RADIO_OPERATOR": "РАДИСТ"}
		var role_text := str(role_names.get(player_role, "ШТУРМ"))
		var drone_text := " • FPV ГОТОВ" if player_role == "RADIO_OPERATOR" and drone_charge_available else (" • FPV ИСПОЛЬЗОВАН" if player_role == "RADIO_OPERATOR" else "")
		var soil_text := " • ГРУНТ:%d" % carried_soil if carried_soil > 0 else ""
		equip_label.text = "%s • ГР:%d • ДЫМ:%d • БИНТ:%d%s%s" % [role_text, grenades, smoke_grenades, medkits, drone_text, soil_text]

func register_field_pickup(pickup: Node3D) -> void:
	if is_instance_valid(pickup) and not nearby_field_pickups.has(pickup):
		nearby_field_pickups.append(pickup)
		_refresh_pickup_prompt()

func unregister_field_pickup(pickup: Node3D) -> void:
	nearby_field_pickups.erase(pickup)
	_refresh_pickup_prompt()

func _nearest_field_pickup() -> Node3D:
	var nearest: Node3D = null
	var nearest_distance := 2.25
	for i in range(nearby_field_pickups.size() - 1, -1, -1):
		var pickup: Node3D = nearby_field_pickups[i]
		if not is_instance_valid(pickup):
			nearby_field_pickups.remove_at(i)
			continue
		if not pickup.has_method("can_collect") or not bool(pickup.call("can_collect", self)):
			continue
		var dist := global_position.distance_to(pickup.global_position)
		if dist < nearest_distance:
			nearest_distance = dist
			nearest = pickup
	return nearest

func _refresh_pickup_prompt() -> void:
	if mounted_vehicle != null and not is_instance_valid(mounted_vehicle):
		mounted_vehicle = null
	var enterable: Node3D = null
	var pickup: Node3D = null
	if mounted_vehicle == null:
		enterable = _nearest_enterable()
		pickup = _nearest_field_pickup()
	var prompt: Node3D = null
	if mounted_vehicle != null:
		prompt = mounted_vehicle
	elif enterable != null:
		prompt = enterable
	elif pickup != null:
		prompt = pickup
	if pickup_label != null:
		pickup_label.visible = prompt != null
		if prompt != null and prompt.has_method("prompt_text"):
			pickup_label.text = str(prompt.call("prompt_text", OS.has_feature("mobile")))
	if mobile_controls != null:
		var show_interact := (mounted_vehicle != null or enterable != null or pickup != null) and OS.has_feature("mobile")
		mobile_controls.set_interact_visible(show_interact)

func _interact_with_pickup() -> void:
	if is_dead or input_locked:
		return
	if mounted_vehicle != null:
		_exit_vehicle()
		return
	var enterable := _nearest_enterable()
	if enterable != null:
		_enter_vehicle(enterable)
		_refresh_pickup_prompt()
		return
	var pickup := _nearest_field_pickup()
	if pickup == null or not pickup.has_method("collect"):
		return
	if bool(pickup.call("collect", self)):
		nearby_field_pickups.erase(pickup)
		_refresh_pickup_prompt()
		_play_sfx(sfx_ui, SFX_UI, -2.0, 1.12)

func can_take_field_ammo(amount: int) -> bool:
	if is_dead or input_locked or amount <= 0:
		return false
	return reserve_ammo < int(_weapon_data().reserve)

func take_field_ammo(amount: int) -> int:
	if not can_take_field_ammo(amount):
		return 0
	var before := reserve_ammo
	reserve_ammo = mini(int(_weapon_data().reserve), reserve_ammo + amount)
	_store_weapon_ammo()
	_refresh_ammo()
	return reserve_ammo - before

func can_take_weapon_pickup(index: int, clip: int, reserve: int) -> bool:
	if is_dead or input_locked or index < 0 or index >= WEAPON_DEFS.size():
		return false
	var stored_clip := ammo if index == current_weapon_index else ammo_by_weapon[index]
	var stored_reserve := reserve_ammo if index == current_weapon_index else reserve_by_weapon[index]
	var definition: Dictionary = WEAPON_DEFS[index]
	return index != current_weapon_index or stored_clip < mini(int(definition.mag), maxi(0, clip)) or stored_reserve < mini(int(definition.reserve), maxi(0, reserve))

func take_weapon_pickup(index: int, clip: int, reserve: int) -> bool:
	if not can_take_weapon_pickup(index, clip, reserve):
		return false
	if index == current_weapon_index:
		var definition: Dictionary = WEAPON_DEFS[index]
		ammo = mini(int(definition.mag), maxi(ammo, clip))
		reserve_ammo = mini(int(definition.reserve), maxi(reserve_ammo, reserve))
		_store_weapon_ammo()
		_refresh_ammo()
		return true

	var previous_index := current_weapon_index
	var previous_clip := ammo
	var previous_reserve := reserve_ammo
	_store_weapon_ammo()
	ammo_by_weapon[previous_index] = 0
	reserve_by_weapon[previous_index] = 0
	_spawn_weapon_drop(previous_index, previous_clip, previous_reserve)

	# Свободный подбор любого оружия: заменяем слот основного оружия в пуле
	if not role_weapon_indices.has(index):
		var prev_slot := role_weapon_indices.find(previous_index)
		if prev_slot >= 0:
			role_weapon_indices[prev_slot] = index
		else:
			role_weapon_indices.insert(0, index)

	current_weapon_index = index
	var incoming: Dictionary = WEAPON_DEFS[index]
	ammo = mini(int(incoming.mag), maxi(ammo_by_weapon[index], clip))
	reserve_ammo = mini(int(incoming.reserve), maxi(reserve_by_weapon[index], reserve))
	is_reloading = false
	reload_timer = 0.0
	weapon_kick = 0.0
	_set_aiming(false)
	if mobile_controls != null and mobile_controls.has_method("reset_aim"):
		mobile_controls.call("reset_aim")
	_store_weapon_ammo()
	_equip_weapon_visual()
	_refresh_ammo()
	return true

func _spawn_weapon_drop(index: int, clip: int, reserve: int) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var drop_pos := global_position + transform.basis.x * 0.75 + transform.basis.z * 0.45 + Vector3.UP * 0.75
	var drop_velocity := transform.basis.x * 1.0 + transform.basis.z * 0.6 + Vector3.UP * 1.5
	if parent.has_method("spawn_weapon_pickup"):
		parent.call("spawn_weapon_pickup", drop_pos, index, clip, reserve, drop_velocity)
		return
	var dropped = FIELD_PICKUP_SCRIPT.new()
	dropped.configure_weapon(index, clip, reserve)
	parent.add_child(dropped)
	dropped.global_position = drop_pos
	dropped.launch(drop_velocity)

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
	_cancel_healing()
	health = maxf(0.0, health - float(damage))
	blood_vignette_time = 1.0
	_play_sfx(sfx_hit, SFX_HIT_FLESH, 0.0, randf_range(0.9, 1.1))

	var to_attacker := (attacker_pos - global_position).normalized()
	recoil.y += randf_range(0.02, 0.05)
	recoil.x += clampf(-to_attacker.x * 0.04, -0.06, 0.06)

	_refresh_health()

	if health <= 0.0:
		_die(attacker_name, attacker_pos, region)

func _die(killer_name: String, attacker_pos: Vector3 = Vector3.ZERO, region: String = "chest") -> void:
	if active_drone != null and is_instance_valid(active_drone):
		active_drone.return_to_operator()
	if mounted_vehicle != null and is_instance_valid(mounted_vehicle):
		_exit_vehicle()
	_cancel_healing()
	if camera != null:
		camera.current = true
	if mobile_controls != null:
		mobile_controls.set_drone_mode(false)

	is_dead = true
	is_vaulting = false
	if is_grenade_held and not grenade_has_spawned and grenades > 0:
		_spawn_thrown_grenade()
	is_grenade_held = false
	grenade_has_spawned = false
	grenade_anim_state = GrenadeActionState.IDLE
	if grenade_view_root != null:
		grenade_view_root.visible = false
	health = 0.0
	velocity = Vector3.ZERO
	collision_layer = 0
	if player_body != null and player_body.has_method("set_ragdoll"):
		var hit_dir := global_position - attacker_pos
		player_body.visible = true
		player_body.call("set_ragdoll", true, hit_dir, region == "head")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var world := get_parent()
	if world != null and world.has_method("record_player_death"):
		world.call("record_player_death")
	if pickup_label != null:
		pickup_label.visible = false
	if mobile_controls != null:
		mobile_controls.set_interact_visible(false)

	# Pull back from the eyes so the death is visible as a body, not only a red overlay.
	camera.position = Vector3(0.0, 2.15, 3.1)
	camera.rotation = Vector3(deg_to_rad(-27.0), 0.0, 0.0)
	if weapon_root != null:
		weapon_root.visible = false
	if _view_arm_left != null:
		_view_arm_left.visible = false
	if _view_arm_right != null:
		_view_arm_right.visible = false
	if crosshair != null:
		crosshair.visible = false

	if death_info_label != null:
		death_info_label.text = "Вас уничтожил: " + killer_name
	if death_screen != null:
		death_screen.visible = true

func respawn() -> void:
	if active_drone != null and is_instance_valid(active_drone):
		active_drone.return_to_operator()
	if camera != null:
		camera.current = true

	is_dead = false
	is_vaulting = false
	is_grenade_held = false
	grenade_has_spawned = false
	grenade_anim_state = GrenadeActionState.IDLE
	if grenade_view_root != null:
		grenade_view_root.visible = false
	collision_layer = WORLD_LAYER_MASK
	health = MAX_HEALTH
	if player_body != null and player_body.has_method("set_ragdoll"):
		player_body.call("set_ragdoll", false)
		player_body.visible = false
	if weapon_root != null:
		weapon_root.visible = true
	if _view_arm_left != null:
		_view_arm_left.visible = true
	if _view_arm_right != null:
		_view_arm_right.visible = true
	for i in range(WEAPON_DEFS.size()):
		ammo_by_weapon[i] = int(WEAPON_DEFS[i].mag)
		reserve_by_weapon[i] = int(WEAPON_DEFS[i].reserve)

	match player_role:
		"SNIPER":
			current_weapon_index = 6
			grenades = 1
			smoke_grenades = 2
			medkits = 2
			drone_charge_available = false
		"ANTI_TANK":
			current_weapon_index = 7
			grenades = 1
			smoke_grenades = 1
			medkits = 2
			drone_charge_available = false
		"MEDIC":
			current_weapon_index = 1
			grenades = 2
			smoke_grenades = 2
			medkits = 5
			drone_charge_available = false
		"RADIO_OPERATOR":
			current_weapon_index = 5
			grenades = 1
			smoke_grenades = 2
			medkits = 2
			drone_charge_available = true
		_:
			current_weapon_index = 0
			grenades = 3
			smoke_grenades = 2
			medkits = 2
			drone_charge_available = false

	is_shovel_equipped = false
	carried_soil = 0
	shovel_action_cooldown = 0.0
	last_primary_weapon_index = current_weapon_index
	ammo = ammo_by_weapon[current_weapon_index]
	reserve_ammo = reserve_by_weapon[current_weapon_index]
	_equip_weapon_visual()

	is_reloading = false
	reload_timer = 0.0
	is_healing = false
	heal_target = null
	drone_vertical_input = 0.0
	aiming = false
	aim_blend = 0.0
	camera.fov = GameSettings.fov
	if mobile_controls != null:
		if mobile_controls.has_method("reset_aim"):
			mobile_controls.call("reset_aim")
		if mobile_controls.has_method("set_drone_visible"):
			mobile_controls.set_drone_visible(player_role == "RADIO_OPERATOR")
		if mobile_controls.has_method("set_drone_mode"):
			mobile_controls.set_drone_mode(false)
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
