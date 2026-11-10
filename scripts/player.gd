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
const SHOW_VIEW_ARMS := true
const VIEW_ARM_UPPER := 0.34
const VIEW_ARM_LOWER := 0.31

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
const RELOAD_TIME := 2.2
const FIRE_INTERVAL := 0.10
const MAX_HEALTH := 100.0
const SIDEARM_INDEX := 3 # M1911 is carried as a backup sidearm by every role.

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
var _weapon_rot_smooth := Vector3.ZERO
var sprint_anim := 0.0
var landing_anim := 0.0
var _was_on_floor := true
var bob_time := 0.0
var breathing_time := 0.0
var aim_blend := 0.0
var aiming := false
var look_sway := Vector2.ZERO
var lean_amount := 0.0
var lean_toggle := 0 # -1: наклон влево, 0: центр, 1: наклон вправо (Toggle Lean)
var _last_key_q := false
var _last_key_e := false
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
var _weapons := FRONTLINEWeaponController.new()
var current_weapon_index: int:
	get: return _weapons.current_index
	set(value): _weapons.current_index = value
var last_primary_weapon_index: int:
	get: return _weapons.last_primary_index
	set(value): _weapons.last_primary_index = value
var role_primary_weapon_index: int:
	get: return _weapons.role_primary_index
	set(value): _weapons.role_primary_index = value
var role_weapon_indices: Array[int]:
	get: return _weapons.role_weapon_indices
	set(value): _weapons.role_weapon_indices = value
var is_shovel_equipped := false
var carried_soil := 0
var shovel_action_cooldown := 0.0
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
var fire_cooldown: float:
	get: return _weapons.fire_cooldown
	set(value): _weapons.fire_cooldown = value
var ammo: int:
	get: return _weapons.ammo
	set(value): _weapons.ammo = value
var reserve_ammo: int:
	get: return _weapons.reserve
	set(value): _weapons.reserve = value
var is_reloading: bool:
	get: return _weapons.is_reloading
	set(value): _weapons.is_reloading = value
var reload_timer: float:
	get: return _weapons.reload_timer
	set(value): _weapons.reload_timer = value

# Снаряжение игрока
var grenades := 3
var smoke_grenades := 2
var medkits := 2
var is_healing := false
var heal_timer := 0.0
var heal_target: Node3D
var heal_hold := false
var heal_anim_time := 0.0
var heal_view_root: Node3D
var heal_bandage: Node3D
var heal_progress_bar: ProgressBar
var throwable_cooldown := 0.0
var player_role := "ASSAULT"
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
var _grenade_payload := "frag"
var _grenade_view_payload := ""
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
var _prompt_timer := 0.0
var _osd_timer := 0.0
var _mounted_last_vehicle_yaw := 0.0
var mobile_fire := false
var sprint_hold := 0.0
var pause_menu: FRONTLINEPauseMenu
var _view_arm_left: Node3D
var _view_arm_right: Node3D

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
	_weapons.ammo_changed.connect(_refresh_ammo)
	_weapons.reload_finished.connect(_on_weapon_reload_finished)
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
	# Low-пресет: дальний план 170 м — меньше vertices/overdraw.
	camera.far = GameSettings.view_distance()
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
	weapon_root.position = Vector3(0.24, -0.23, -0.60)
	# 0.72 — оружие читается реальным, но не занимает пол-экрана.
	weapon_root.scale = Vector3.ONE * 0.72
	weapon_base = weapon_root.position
	camera.add_child(weapon_root)
	weapon_mount = Node3D.new()
	weapon_mount.name = "WeaponMount"
	weapon_root.add_child(weapon_mount)
	_build_view_hands()
	_equip_weapon_visual()
	_build_grenade_view()
	_build_heal_view()

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
			aim_pos = Vector3(-0.0045, -0.070, -0.52)
			left_wrist_offset = Vector3(-0.02, -0.03, -0.18) # цевьё
			right_wrist_offset = Vector3(0.01, -0.06, 0.02)
		"mp40":
			hip_pos = Vector3(0.075, -0.16, -0.48)
			aim_pos = Vector3(0.0, -0.0375, -0.48)
			left_wrist_offset = Vector3(-0.02, -0.04, -0.14) # шахта магазина
			right_wrist_offset = Vector3(0.01, -0.06, 0.04)
		"mosin":
			hip_pos = Vector3(0.09, -0.17, -0.54)
			aim_pos = Vector3(0.0, -0.030, -0.50)
			left_wrist_offset = Vector3(-0.02, -0.025, -0.24) # длинное ложе
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"m1911":
			hip_pos = Vector3(0.05, -0.15, -0.44) # вынесенный пистолетный хват
			aim_pos = Vector3(0.0, -0.023, -0.38)
			left_wrist_offset = Vector3(-0.03, -0.055, 0.02) # хват второй рукой снизу
			right_wrist_offset = Vector3(0.01, -0.055, 0.02)
		"shotgun":
			hip_pos = Vector3(0.09, -0.18, -0.50)
			aim_pos = Vector3(0.0, -0.025, -0.46)
			left_wrist_offset = Vector3(-0.02, -0.04, -0.22) # подвижное цевьё
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"ppsh41":
			hip_pos = Vector3(0.08, -0.17, -0.48)
			aim_pos = Vector3(0.0, -0.026, -0.46)
			left_wrist_offset = Vector3(-0.02, -0.035, -0.16) # хват под барабаном
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"kar98k":
			hip_pos = Vector3(0.09, -0.17, -0.54)
			aim_pos = Vector3(0.0, -0.0375, -0.44) # оптическая ось прицела ZF-39 строго по центру
			left_wrist_offset = Vector3(-0.02, -0.025, -0.24) # ложе
			right_wrist_offset = Vector3(0.01, -0.06, 0.03)
		"panzerfaust":
			hip_pos = Vector3(0.14, -0.09, -0.46) # удержание на правом плече
			aim_pos = Vector3(0.0, -0.044, -0.42) # прицельная прорезь точно по центру
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
	player_role = _normalize_role(MatchState.player_role)
	_configure_role_loadout(player_role)

	# Пресет снаряжения, выбранный на экране развёртывания.
	match MatchState.loadout_preset:
		"ASSAULT":
			grenades += 1
			medkits = maxi(1, medkits - 1)
		"SURVIVAL":
			grenades = maxi(0, grenades - 1)
			medkits += 1

	var chosen_primary := MatchState.primary_weapon_index
	if chosen_primary >= 0 and chosen_primary < FRONTLINEWeaponCatalog.count():
		_weapons.set_primary_slot(chosen_primary)
	_weapons.select_primary(true)

	var chosen_grenades := MatchState.grenades_override
	if chosen_grenades >= 0:
		grenades = chosen_grenades
	var chosen_smoke := MatchState.smoke_override
	if chosen_smoke >= 0:
		smoke_grenades = chosen_smoke
	var chosen_medkits := MatchState.medkits_override
	if chosen_medkits >= 0:
		medkits = chosen_medkits
	var chosen_rockets := MatchState.rockets_override
	if chosen_rockets >= 0:
		_weapons.set_reserve_for(7, chosen_rockets)

func _normalize_role(role: String) -> String:
	match role:
		"SNIPER", "ANTI_TANK", "MEDIC", "RADIO_OPERATOR":
			return role
		_:
			return "ASSAULT"

## Единственное место, где задаются роль и стартовое снаряжение.
## Оружейные слоты и патроны живут в FRONTLINEWeaponController.
func _configure_role_loadout(role: String) -> void:
	player_role = _normalize_role(role)
	_weapons.configure_role(player_role)
	match player_role:
		"SNIPER":
			grenades = 1
			smoke_grenades = 2
			medkits = 2
			drone_charge_available = false
		"ANTI_TANK":
			grenades = 1
			smoke_grenades = 1
			medkits = 2
			drone_charge_available = false
		"MEDIC":
			grenades = 2
			smoke_grenades = 2
			medkits = 5
			drone_charge_available = false
		"RADIO_OPERATOR":
			grenades = 1
			smoke_grenades = 2
			medkits = 2
			drone_charge_available = true
		_:
			player_role = "ASSAULT"
			grenades = 3
			smoke_grenades = 2
			medkits = 2
			drone_charge_available = false

func _set_primary_slot(index: int) -> void:
	_weapons.set_primary_slot(index)

## Публичный вход для экрана деплоя: роль и основное оружие переносятся
## между смертями, а не сбрасываются на ASSAULT.
func apply_loadout(role: String, primary_index: int) -> void:
	_configure_role_loadout(role)
	if primary_index >= 0 and primary_index < FRONTLINEWeaponCatalog.count():
		_weapons.set_primary_slot(primary_index)
	_weapons.select_primary(true)
	is_shovel_equipped = false
	_equip_weapon_visual()
	_refresh_ammo()
	_refresh_equipment()

func _weapon_data() -> FRONTLINEWeaponDef:
	return _weapons.current_def()

func _switch_weapon(index: int) -> void:
	if is_dead or index < 0 or index >= FRONTLINEWeaponCatalog.count() or grenade_anim_state != GrenadeActionState.IDLE:
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
	if not _weapons.switch_to(index):
		return
	_set_aiming(false)
	if mobile_controls != null and mobile_controls.has_method("reset_aim"):
		mobile_controls.call("reset_aim")
	weapon_kick = 0.0
	if weapon_mount != null:
		weapon_mount.rotation = Vector3.ZERO
	_equip_weapon_visual()
	_refresh_ammo()
	_play_sfx(sfx_ui, SFX_UI, -6.0, 1.0)

## QA-fix TASK-0022: цикл снаряжения в руке — автомат → пистолет → лопата.
## Вызывается стрелками «влево/вправо» у иконки оружия в HUD.
func _cycle_equipment(direction: int) -> void:
	if is_dead or input_locked or active_drone != null or mounted_vehicle != null:
		return
	if grenade_anim_state != GrenadeActionState.IDLE:
		return
	var cur := "primary"
	if is_shovel_equipped:
		cur = "shovel"
	elif current_weapon_index == SIDEARM_INDEX:
		cur = "sidearm"
	var order := ["primary", "sidearm", "shovel"]
	var idx: int = order.find(cur)
	idx = posmod(idx + direction, order.size())
	match str(order[idx]):
		"primary":
			if is_shovel_equipped:
				is_shovel_equipped = false
				_equip_weapon_visual()
				_refresh_ammo()
			if current_weapon_index == SIDEARM_INDEX:
				_switch_weapon(last_primary_weapon_index)
		"sidearm":
			if is_shovel_equipped:
				is_shovel_equipped = false
				_equip_weapon_visual()
			if current_weapon_index != SIDEARM_INDEX:
				_toggle_sidearm()
		"shovel":
			if not is_shovel_equipped:
				_toggle_shovel()
	_refresh_equipment_icon()

func _refresh_equipment_icon() -> void:
	if mobile_controls == null or not is_instance_valid(mobile_controls):
		return
	if not mobile_controls.has_method("set_equipment_info"):
		return
	var icon_id := "rifle"
	var label := "АВТОМАТ"
	if is_shovel_equipped:
		icon_id = "shovel"
		label = "ЛОПАТА"
	elif current_weapon_index == SIDEARM_INDEX:
		icon_id = "sidearm"
		label = "ПИСТОЛЕТ"
	else:
		var weapon := _weapon_data()
		var wid := str(weapon.id)
		if wid == "panzerfaust":
			icon_id = "rpg"
			label = "РПГ"
		else:
			label = str(weapon.display_name)
	mobile_controls.call("set_equipment_info", icon_id, label)

func _cycle_weapon(direction: int) -> void:
	if role_weapon_indices.is_empty():
		return
	var slot := role_weapon_indices.find(current_weapon_index)
	if slot < 0:
		slot = 0
	slot = posmod(slot + direction, role_weapon_indices.size())
	_switch_weapon(role_weapon_indices[slot])
	_refresh_equipment_icon()

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
	_weapons.cancel_reload()
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
	var team := MatchState.player_team
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

	# QA-fix TASK-0022: чёрные «отвязанные» кисти убраны; руки — изогнутые
	# двухзвенные конечности с ладонями на запястьях.
	_view_arm_left = _make_view_arm("ViewArmL", true)
	_view_arm_right = _make_view_arm("ViewArmR", false)

func _make_view_arm(arm_name: String, is_left: bool) -> Node3D:
	var arm := Node3D.new()
	arm.name = arm_name
	var player_team: String = MatchState.player_team
	var is_red: bool = player_team.to_upper().contains("RED") or player_team.to_upper().contains("SOVIET")
	var sleeve := StandardMaterial3D.new()
	# Тёмная полевая ткань — без «синих» оттенков, ближе к Dummy War.
	sleeve.albedo_color = Color(0.24, 0.20, 0.14) if is_red else Color(0.16, 0.18, 0.13)
	sleeve.roughness = 0.95
	var glove := StandardMaterial3D.new()
	glove.albedo_color = Color(0.32, 0.25, 0.18)
	glove.roughness = 0.90

	# Плечо (верхнее звено) и предплечье — два отдельных сегмента, локоть гнётся.
	var upper := MeshInstance3D.new()
	upper.name = "Upper"
	var upper_mesh := CylinderMesh.new()
	upper_mesh.top_radius = 0.052
	upper_mesh.bottom_radius = 0.044
	upper_mesh.height = 1.0
	upper_mesh.radial_segments = 10
	upper.mesh = upper_mesh
	upper.material_override = sleeve
	upper.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	upper.visible = true
	arm.add_child(upper)

	var forearm := MeshInstance3D.new()
	forearm.name = "Forearm"
	var forearm_mesh := CylinderMesh.new()
	forearm_mesh.top_radius = 0.042
	forearm_mesh.bottom_radius = 0.033
	forearm_mesh.height = 1.0
	forearm_mesh.radial_segments = 10
	forearm.mesh = forearm_mesh
	forearm.material_override = sleeve
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	forearm.visible = true
	arm.add_child(forearm)

	# Ладонь и большой палец — на конце предплечья.
	var palm := MeshInstance3D.new()
	palm.name = "Palm"
	var palm_mesh := BoxMesh.new()
	palm_mesh.size = Vector3(0.070, 0.040, 0.110)
	palm.mesh = palm_mesh
	palm.material_override = glove
	palm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm.add_child(palm)

	var thumb := MeshInstance3D.new()
	thumb.name = "Thumb"
	var thumb_mesh := BoxMesh.new()
	thumb_mesh.size = Vector3(0.026, 0.028, 0.055)
	thumb.mesh = thumb_mesh
	thumb.material_override = glove
	thumb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm.add_child(thumb)


	# Короткая манжета рукава за кистью (рука «входит» в кадр, не висит).
	var cuff := MeshInstance3D.new()
	cuff.name = "Cuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.030
	cuff_mesh.bottom_radius = 0.033
	cuff_mesh.height = 0.10
	cuff_mesh.radial_segments = 8
	cuff.mesh = cuff_mesh
	cuff.material_override = sleeve
	cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arm.add_child(cuff)

	# Пальцы, обхватывающие оружие (4 коротких фаланги на кисть).
	for finger_index in range(4):
		var finger := MeshInstance3D.new()
		finger.name = "Finger%d" % finger_index
		var finger_mesh := BoxMesh.new()
		finger_mesh.size = Vector3(0.019, 0.022, 0.060)
		finger.mesh = finger_mesh
		finger.material_override = glove
		finger.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		finger.set_meta("finger_index", finger_index)
		arm.add_child(finger)

	arm.set_meta("is_left", is_left)
	if camera != null:
		camera.add_child(arm)
	return arm

func _update_view_arms() -> void:
	if camera == null:
		return
	if not SHOW_VIEW_ARMS or (weapon_root != null and not weapon_root.visible) or grenade_anim_state != GrenadeActionState.IDLE:
		if _view_arm_left != null:
			_view_arm_left.visible = false
		if _view_arm_right != null:
			_view_arm_right.visible = false
		return
	# Руки идут от плеч у нижних углов кадра к кистям на оружии:
	# видно плечо -> локоть -> предплечье -> кисть, а не «парящие кисти».
	var cam_xf := camera.global_transform
	if wrist_left_marker != null and _view_arm_left != null:
		var l_shoulder: Vector3 = cam_xf * Vector3(-0.30, -0.28, -0.01)
		var l_pole: Vector3 = cam_xf.basis * Vector3(-0.65, -1.0, 0.05)
		_place_view_hand(_view_arm_left, wrist_left_marker.global_transform, true, l_shoulder, l_pole)
	if wrist_right_marker != null and _view_arm_right != null:
		var r_shoulder: Vector3 = cam_xf * Vector3(0.30, -0.28, -0.01)
		var r_pole: Vector3 = cam_xf.basis * Vector3(0.65, -1.0, 0.05)
		_place_view_hand(_view_arm_right, wrist_right_marker.global_transform, false, r_shoulder, r_pole)

func _place_view_hand(arm: Node3D, marker_xf: Transform3D, is_left: bool, shoulder: Vector3, pole: Vector3) -> void:
	arm.visible = true
	# Корень руки совмещаем с кистевым маркером оружия — ладонь и пальцы
	# остаются в системе координат оружия и двигаются вместе с отдачей.
	arm.global_transform = Transform3D(marker_xf.basis.orthonormalized(), marker_xf.origin)

	var wrist := marker_xf.origin
	var elbow := _solve_elbow(shoulder, wrist, pole)
	var upper := arm.get_node_or_null("Upper") as MeshInstance3D
	var forearm := arm.get_node_or_null("Forearm") as MeshInstance3D
	if upper != null:
		_place_limb_segment(upper, shoulder, elbow)
	if forearm != null:
		_place_limb_segment(forearm, elbow, wrist)

	var cuff := arm.get_node_or_null("Cuff") as MeshInstance3D
	if cuff != null:
		cuff.visible = true
		cuff.position = Vector3(0.0, -0.016, 0.085)
		cuff.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	var palm := arm.get_node_or_null("Palm") as MeshInstance3D
	if palm != null:
		palm.visible = true
		palm.position = Vector3(0.0, -0.012, -0.055)
		palm.rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(8.0 if is_left else -8.0), 0.0)
	var thumb := arm.get_node_or_null("Thumb") as MeshInstance3D
	if thumb != null:
		thumb.visible = true
		thumb.position = Vector3(0.05 if is_left else -0.05, 0.012, -0.048)
		thumb.rotation = Vector3(deg_to_rad(14.0), 0.0, deg_to_rad(20.0 if is_left else -20.0))
	# Пальцы охватывают оружие: четыре фаланги поперёк кисти.
	var finger_x := -0.030
	for finger_index in range(4):
		var finger := arm.get_node_or_null("Finger%d" % finger_index) as MeshInstance3D
		if finger == null:
			continue
		finger.visible = true
		finger.position = Vector3(finger_x + float(finger_index) * 0.020, -0.020, -0.085)
		finger.rotation = Vector3(deg_to_rad(72.0), 0.0, deg_to_rad(6.0 if is_left else -6.0))

## Двухзвенная IK: положение локтя по длинам плеча/предплечья и полюсу сгиба.
func _solve_elbow(shoulder: Vector3, wrist: Vector3, pole: Vector3) -> Vector3:
	var delta := wrist - shoulder
	var distance := delta.length()
	if distance < 0.05:
		return shoulder + Vector3.DOWN * 0.1
	var direction := delta / distance
	var max_reach := VIEW_ARM_UPPER + VIEW_ARM_LOWER - 0.01
	var reach := clampf(distance, 0.05, max_reach)
	var along := (VIEW_ARM_UPPER * VIEW_ARM_UPPER - VIEW_ARM_LOWER * VIEW_ARM_LOWER + reach * reach) / (2.0 * reach)
	var height := sqrt(maxf(VIEW_ARM_UPPER * VIEW_ARM_UPPER - along * along, 0.0001))
	var bend := pole - direction * pole.dot(direction)
	if bend.length_squared() < 0.001:
		bend = Vector3.DOWN
	return shoulder + direction * along + bend.normalized() * height

func _place_limb_segment(mesh_inst: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.01:
		mesh_inst.visible = false
		return
	mesh_inst.visible = true
	var up := d / l
	var right := up.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = up.cross(Vector3.RIGHT)
	right = right.normalized()
	var fwd := up.cross(right).normalized()
	mesh_inst.global_transform = Transform3D(Basis(right, up * l, fwd), (a + b) * 0.5)

func _update_viewmodel_visibility(scoped: bool) -> void:
	if weapon_root == null:
		return
	if is_dead:
		return
	# Во время гранаты/лечения/лопаты видимостью управляют их состояния.
	if is_healing or grenade_anim_state != GrenadeActionState.IDLE or is_shovel_equipped:
		return
	weapon_root.visible = not scoped

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

func _play_player_shot_sfx(wid: String, _default_pitch: float) -> void:
	var prof: Dictionary = COMBAT_AUDIO.WEAPON_PROFILES.get(wid, {})
	# Высота уже зашита в ресемплированный сэмпл банка; второй pitch-множитель
	# делал звук мультяшным.
	var pitch := randf_range(0.97, 1.03)
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
	if mobile_controls.has_signal("heal_released"):
		mobile_controls.heal_released.connect(_on_heal_released)
	mobile_controls.peek_left_changed.connect(_on_mobile_peek_left)
	mobile_controls.peek_right_changed.connect(_on_mobile_peek_right)
	mobile_controls.cycle_weapon_pressed.connect(func(): _cycle_weapon(1))
	if mobile_controls.has_signal("equip_prev_pressed"):
		mobile_controls.equip_prev_pressed.connect(func(): _cycle_equipment(-1))
	if mobile_controls.has_signal("equip_next_pressed"):
		mobile_controls.equip_next_pressed.connect(func(): _cycle_equipment(1))
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

func _refresh_equipment_after_hud() -> void:
	_refresh_equipment_icon()

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

	# QA-fix TASK-0022: зелёная полоса перевязки по центру снизу.
	heal_progress_bar = ProgressBar.new()
	heal_progress_bar.min_value = 0.0
	heal_progress_bar.max_value = 100.0
	heal_progress_bar.value = 0.0
	heal_progress_bar.show_percentage = false
	heal_progress_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	heal_progress_bar.offset_left = -170.0
	heal_progress_bar.offset_right = 170.0
	heal_progress_bar.offset_top = -150.0
	heal_progress_bar.offset_bottom = -134.0
	heal_progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heal_bg := StyleBoxFlat.new()
	heal_bg.bg_color = Color(0.06, 0.09, 0.06, 0.85)
	heal_bg.set_corner_radius_all(4)
	var heal_fill := StyleBoxFlat.new()
	heal_fill.bg_color = Color(0.30, 0.85, 0.35, 0.95)
	heal_fill.set_corner_radius_all(4)
	heal_progress_bar.add_theme_stylebox_override("background", heal_bg)
	heal_progress_bar.add_theme_stylebox_override("fill", heal_fill)
	heal_progress_bar.visible = false
	hud.add_child(heal_progress_bar)

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
	respawn_btn.text = "ТАКТИЧЕСКИЙ ДЕПЛОЙ (DEPLOY)"
	respawn_btn.custom_minimum_size = Vector2(300, 56)
	respawn_btn.add_theme_font_size_override("font_size", 20)
	respawn_btn.pressed.connect(func():
		var world := get_parent()
		if world != null and world.has_method("open_tactical_deploy"):
			if death_screen != null:
				death_screen.visible = false
			world.call("open_tactical_deploy")
		else:
			respawn()
	)
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
	var mount_factor := 0.62 if (mounted_vehicle != null and is_instance_valid(mounted_vehicle)) else 1.0
	var sense := TOUCH_SENS * GameSettings.sensitivity_scale(aiming) * zoom_factor * mount_factor
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
	if pressed:
		lean_toggle = 0 if lean_toggle == -1 else -1

func _on_mobile_peek_right(pressed: bool) -> void:
	if pressed:
		lean_toggle = 0 if lean_toggle == 1 else 1

func _on_drone_vertical_changed(direction: float, pressed: bool) -> void:
	drone_vertical_input = direction if pressed else 0.0

func _drone_tether_length() -> float:
	match MatchState.map_name:
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
	# QA-fix TASK-0022: оператор остаётся видимым в мире, в своей позе.
	# Раньше тело было скрыто (первый вид), и в FPV казалось, что персонаж пропал.
	if player_body != null and is_instance_valid(player_body):
		player_body.visible = true
		if player_body.has_method("set_external_view"):
			player_body.call("set_external_view", true)
		if player_body.has_method("set_motion"):
			player_body.call("set_motion", 0.0, false)
		if player_body.has_method("set_stance"):
			player_body.call("set_stance", stance)
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
	# Возврат к первому виду: тело снова скрыто, чтобы не закрывать обзор.
	if player_body != null and is_instance_valid(player_body) and not is_dead:
		if player_body.has_method("set_external_view"):
			player_body.call("set_external_view", false)
		player_body.visible = false
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
	if event is InputEventKey and not event.pressed and event.keycode == KEY_H:
		heal_hold = false
		if is_healing:
			_cancel_healing()
		return
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
		elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
			_select_weapon_slot(event.keycode - KEY_1)
		elif event.keycode == KEY_F:
			_interact_with_pickup()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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
		# Сначала применяем взгляд, затем тик техники: турель берёт свежую
		# камеру (иначе наводка отстаёт на кадр).
		_apply_look(delta)
		_process_mounted_vehicle(delta)
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
	# QA-optimization: подсказки и UI не пересобираются каждый кадр.
	_prompt_timer -= delta
	if _prompt_timer <= 0.0:
		_prompt_timer = 0.2
		_refresh_pickup_prompt()
	_update_acoustics(delta)
	COMBAT_AUDIO.listener_pos = camera.global_position
	COMBAT_AUDIO.listener_valid = true

	_weapons.tick(delta)
	throwable_cooldown = maxf(0.0, throwable_cooldown - delta)
	shovel_action_cooldown = maxf(0.0, shovel_action_cooldown - delta)
	_update_grenade_animation(delta)
	var blend := 1.0 - exp(-delta * 13.0)
	aim_blend = lerpf(aim_blend, 1.0 if aiming else 0.0, blend)
	var scoped_ads := aiming and str(_weapon_data().id) == "kar98k" and aim_blend > 0.85
	if crosshair != null:
		if crosshair.has_method("set_sniper_scope"):
			crosshair.call("set_sniper_scope", scoped_ads)
		crosshair.visible = not is_dead and active_drone == null
	_update_viewmodel_visibility(scoped_ads)
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

	# Таймер лечения (TASK-0022: удержание кнопки + анимация перевязки)
	if is_healing:
		var moving_to_cancel := mobile_move.length() > 0.15 or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D)
		# Отпустил кнопку — перевязка прерывается (флаг един для тача и клавиши).
		var hold_released := not heal_hold
		if moving_to_cancel or hold_released:
			_cancel_healing()
		else:
			_update_heal_visual(delta)
			heal_timer -= delta
			if heal_timer <= 0.0:
				if heal_target != null and is_instance_valid(heal_target) and not bool(heal_target.get("is_dead")):
					heal_target.set("health", minf(MAX_HEALTH, float(heal_target.get("health")) + 40.0))
				else:
					health = minf(MAX_HEALTH, health + 45.0)
				is_healing = false
				heal_target = null
				medkits = maxi(0, medkits - 1)
				_finish_heal_visual()
				_refresh_health()
				_refresh_equipment()
				_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -2.0, 1.1)

	# Вспышка крови на экране
	var blood_alpha := 0.0
	if blood_vignette_time > 0.0:
		blood_vignette_time = maxf(0.0, blood_vignette_time - delta * 2.5)
		blood_alpha = blood_vignette_time * 0.45
	elif health < 35.0:
		blood_alpha = clampf((35.0 - health) / 35.0, 0.0, 0.3)
	if not is_equal_approx(blood_overlay.color.a, blood_alpha):
		blood_overlay.color.a = blood_alpha
	blood_overlay.visible = blood_alpha > 0.004

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
	# QA-fix TASK-0022: плавный spring-сглаженный поворот оружия — без рывков
	# при движении взгляда и отдаче.
	var target_rot := Vector3(
		-weapon_kick * 0.22 + sway_rot.x + sprint_rot.x + landing_rot.x,
		sway_rot.y + sprint_rot.y,
		sway_rot.z + sprint_rot.z - strafe_roll * 0.40
	)
	_weapon_rot_smooth = _weapon_rot_smooth.lerp(target_rot, clampf(delta * 16.0, 0.0, 1.0))
	weapon_root.rotation = _weapon_rot_smooth
	_update_view_arms()

	if muzzle_flash_time > 0.0:
		muzzle_flash_time -= delta
		if muzzle_flash_time <= 0.0 and muzzle_flash != null:
			muzzle_flash.visible = false

	if is_reloading:
		var progress := _weapons.reload_progress()
		if weapon_mount != null:
			weapon_mount.rotation.z = sin(progress * PI) * 0.14
			weapon_mount.rotation.x = -sin(progress * PI) * 0.08
		if left_arm_pivot != null:
			var reach_offset := Vector3(0.0, -0.10 * sin(progress * PI), 0.06 * sin(progress * PI))
			left_arm_pivot.position = left_arm_base + reach_offset

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
	_try_step_up()

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
	_osd_timer -= delta
	if _osd_timer <= 0.0 and bodycam_osd_label != null:
		_osd_timer = 1.0
		var dt := Time.get_datetime_dict_from_system()
		bodycam_osd_label.text = "%04d-%02d-%02d %02d:%02d:%02dZ   BAT 94%%" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]

	recoil = recoil.lerp(Vector2.ZERO, clampf(delta * 7.0, 0.0, 1.0))
	var target_height := 1.95 if stance == 0 else (1.35 if stance == 1 else 0.70)
	player_capsule.height = lerpf(player_capsule.height, target_height, clampf(delta * 10.0, 0.0, 1.0))
	player_collision.position.y = player_capsule.height * 0.5
	var target_y := 1.70 if stance == 0 else (1.28 if stance == 1 else 0.52)
	var cam_bob_y := absf(sin(bob_time * 2.0)) * 0.014 * run_boost * bob_factor
	var cam_bob_x := sin(bob_time) * 0.010 * run_boost * bob_factor
	var key_q := Input.is_key_pressed(KEY_Q)
	var key_e := Input.is_key_pressed(KEY_E)
	if key_q and not _last_key_q:
		lean_toggle = 0 if lean_toggle == -1 else -1
	if key_e and not _last_key_e:
		lean_toggle = 0 if lean_toggle == 1 else 1
	_last_key_q = key_q
	_last_key_e = key_e
	if is_vaulting or planar_speed > SPEED + 0.4 or current_speed >= SPRINT_SPEED - 0.1:
		lean_toggle = 0
	var lean_input := float(lean_toggle)
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
	# QA-fix TASK-0022: в джипе камера едет вместе с корпусом — игроку не нужно
	# «доворачивать» взгляд на каждом повороте (турели остаются свободными).
	if mounted_vehicle.has_method("camera_follows_vehicle") and bool(mounted_vehicle.call("camera_follows_vehicle")):
		var vehicle_yaw: float = mounted_vehicle.global_rotation.y
		yaw += wrapf(vehicle_yaw - _mounted_last_vehicle_yaw, -PI, PI)
		_mounted_last_vehicle_yaw = vehicle_yaw
	# В технике всегда показываем точку прицеливания (без снайперского скопа).
	if crosshair != null and not is_dead:
		if crosshair.has_method("set_sniper_scope"):
			crosshair.call("set_sniper_scope", false)
		crosshair.visible = true
	if mounted_vehicle.has_method("tick_driver"):
		mounted_vehicle.call("tick_driver", self, delta)
	var firing := mobile_fire or (not OS.has_feature("mobile") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	if firing and mounted_vehicle.has_method("try_fire"):
		mounted_vehicle.call("try_fire", self)
	_apply_look(delta)
	_refresh_pickup_prompt()

func _enter_vehicle(vehicle: Node3D) -> void:
	if is_dead or input_locked or mounted_vehicle != null:
		return
	if vehicle == null or not is_instance_valid(vehicle):
		return
	if not vehicle.has_method("enter") or not bool(vehicle.call("can_enter", self)):
		return
	mounted_vehicle = vehicle
	_mounted_last_vehicle_yaw = vehicle.global_rotation.y
	if vehicle.has_method("camera_follows_vehicle") and bool(vehicle.call("camera_follows_vehicle")):
		yaw = _mounted_last_vehicle_yaw
	vehicle.call("enter", self)
	if vehicle is PhysicsBody3D:
		add_collision_exception_with(vehicle)
	velocity = Vector3.ZERO
	if mobile_controls != null and mobile_controls.has_method("set_vehicle_mode"):
		mobile_controls.call("set_vehicle_mode", true)
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
	if mobile_controls != null and mobile_controls.has_method("set_vehicle_mode"):
		mobile_controls.call("set_vehicle_mode", false)
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
	var best_score := INF
	for node in get_tree().get_nodes_in_group("enterable_vehicles"):
		var station := node as Node3D
		if station == null or not is_instance_valid(station):
			continue
		if not station.has_method("can_enter") or not bool(station.call("can_enter", self)):
			continue
		var radius := 2.8
		if station.has_method("interaction_radius"):
			radius = float(station.call("interaction_radius"))
		var distance := global_position.distance_to(station.global_position)
		if distance > radius:
			continue
		var score := distance / maxf(radius, 0.1)
		if score < best_score:
			best_score = score
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
	if not _weapons.consume_round():
		return
	fire_cooldown = float(weapon.fire_interval)
	_play_player_shot_sfx(str(weapon.id), float(weapon.sound_pitch))

	# QA-fix TASK-0022: попадание считается ДО отдачи. Раньше recoil успевал
	# повернуть камеру на ~1.5-2°, и снайперская пуля в прицеле уходила выше
	# цели (в зуме это стабильный промах «не регает урон»).
	var pre_recoil_dir := -camera.global_transform.basis.z
	var pre_aim_end := camera.global_position + pre_recoil_dir * float(weapon.range_m)
	var pre_aim_query := PhysicsRayQueryParameters3D.create(camera.global_position, pre_aim_end)
	pre_aim_query.collision_mask = RAY_COLLISION_MASK
	pre_aim_query.exclude = [get_rid()]
	pre_aim_query.collide_with_areas = true
	var pre_aim_hit := get_world_3d().direct_space_state.intersect_ray(pre_aim_query)
	var pre_aim_point: Vector3 = pre_aim_hit.get("position", pre_aim_end)

	if str(weapon.id) == "panzerfaust":
		recoil.y = minf(recoil.y + 0.055, 0.18)
		recoil.x = clampf(recoil.x + randf_range(-0.015, 0.015), -0.06, 0.06)
		weapon_kick = 0.16
		if muzzle_flash != null:
			muzzle_flash.visible = true
			muzzle_flash_time = 0.08
		_apply_look()
		var shoot_dir := pre_recoil_dir
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
		var player_team: String = MatchState.player_team
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
	var aim_point := pre_aim_point
	var base_direction := (aim_point - bullet_origin).normalized()
	var player_team: String = MatchState.player_team
	var pellet_count := int(weapon.pellets)
	for pellet_index in range(pellet_count):
		var dir := base_direction
		dir = dir.rotated(camera.global_transform.basis.y, randf_range(-spread, spread))
		dir = dir.rotated(camera.global_transform.basis.x, randf_range(-spread, spread))
		_spawn_ballistic_bullet(
			bullet_origin,
			dir,
			float(weapon.muzzle_velocity),
			int(weapon.damage),
			float(weapon.range_m),
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
	world.add_child(bullet)
	bullet.configure(origin, direction, speed, damage, range_m, owner_name, owner_team, owner)
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
		# QA-fix TASK-0022: вместо «pew»-джингла — глухой звук попадания.
		_play_sfx(sfx_kill, SFX_HIT_FLESH, -6.0, randf_range(0.72, 0.82))
		if world != null and world.has_method("add_kill"):
			world.call("add_kill")

func _reload() -> void:
	if is_shovel_equipped or grenade_anim_state != GrenadeActionState.IDLE:
		return
	if is_healing or is_dead or input_locked:
		return
	if _weapons.start_reload():
		_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -6.0, 1.0)

func _on_weapon_reload_finished() -> void:
	if weapon_mount != null:
		weapon_mount.rotation = Vector3.ZERO
	if left_arm_pivot != null:
		left_arm_pivot.position = left_arm_base
	_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -4.0, 1.0)

## QA-fix TASK-0022: нательная анимация перевязки — бинт в руке перед камерой.
func _build_heal_view() -> void:
	if heal_view_root != null and is_instance_valid(heal_view_root):
		return
	var root := Node3D.new()
	root.name = "HealView"
	root.visible = false
	camera.add_child(root)

	var sleeve := StandardMaterial3D.new()
	sleeve.albedo_color = Color(0.24, 0.25, 0.19)
	sleeve.roughness = 0.95
	var glove_mat := StandardMaterial3D.new()
	glove_mat.albedo_color = Color(0.33, 0.26, 0.19)
	glove_mat.roughness = 0.9

	# Предплечье, которое перевязываем.
	var forearm := MeshInstance3D.new()
	var f_mesh := CylinderMesh.new()
	f_mesh.top_radius = 0.044
	f_mesh.bottom_radius = 0.052
	f_mesh.height = 0.44
	f_mesh.radial_segments = 8
	forearm.mesh = f_mesh
	forearm.material_override = sleeve
	forearm.position = Vector3(-0.16, -0.24, -0.42)
	forearm.rotation = Vector3(deg_to_rad(74.0), 0.0, deg_to_rad(-24.0))
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(forearm)

	# Рулон бинта (двигается вокруг предплечья).
	var bandage := Node3D.new()
	bandage.name = "Bandage"
	var roll := MeshInstance3D.new()
	var r_mesh := CylinderMesh.new()
	r_mesh.top_radius = 0.056
	r_mesh.bottom_radius = 0.056
	r_mesh.height = 0.095
	r_mesh.radial_segments = 10
	roll.mesh = r_mesh
	var bandage_mat := StandardMaterial3D.new()
	bandage_mat.albedo_color = Color(0.88, 0.85, 0.74)
	bandage_mat.roughness = 1.0
	roll.material_override = bandage_mat
	roll.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	roll.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bandage.add_child(roll)
	bandage.position = Vector3(0.02, -0.18, -0.42)
	root.add_child(bandage)
	heal_bandage = bandage

	# Кисть, держащая бинт.
	var hand := MeshInstance3D.new()
	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(0.06, 0.034, 0.095)
	hand.mesh = h_mesh
	hand.material_override = glove_mat
	hand.position = Vector3(0.09, -0.20, -0.40)
	hand.rotation = Vector3(deg_to_rad(18.0), deg_to_rad(-12.0), 0.0)
	hand.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(hand)

	heal_view_root = root

func _update_heal_visual(delta: float) -> void:
	if not is_healing:
		return
	heal_anim_time += delta
	if heal_view_root != null and is_instance_valid(heal_view_root):
		heal_view_root.visible = true
	if weapon_root != null:
		weapon_root.visible = false
	if heal_bandage != null and is_instance_valid(heal_bandage):
		var t := heal_anim_time
		# Бинт наматывается по кругу вокруг предплечья.
		heal_bandage.position = Vector3(
			0.03 + sin(t * 7.5) * 0.055,
			-0.185 + cos(t * 6.0) * 0.05,
			-0.42 + cos(t * 7.5) * 0.02
		)
		heal_bandage.rotation = Vector3(t * 2.4, t * 1.7, t * 2.1)
	if heal_progress_bar != null:
		heal_progress_bar.visible = true
		heal_progress_bar.value = clampf((1.0 - heal_timer / 2.2) * 100.0, 0.0, 100.0)

func _finish_heal_visual() -> void:
	heal_anim_time = 0.0
	if heal_view_root != null and is_instance_valid(heal_view_root):
		heal_view_root.visible = false
	if heal_progress_bar != null:
		heal_progress_bar.visible = false
	if weapon_root != null and not is_dead and not is_shovel_equipped and grenade_anim_state == GrenadeActionState.IDLE:
		weapon_root.visible = true

func _build_grenade_view() -> void:
	# По умолчанию в руках осколочная; дымовая подменяет модель при замахе.
	_ensure_grenade_view("frag")

func _ensure_grenade_view(payload: String) -> void:
	if grenade_view_root != null and is_instance_valid(grenade_view_root) and _grenade_view_payload == payload:
		return
	if grenade_view_root != null and is_instance_valid(grenade_view_root):
		grenade_view_root.queue_free()
	grenade_view_root = WEAPON_MESHES.make_smoke_view_model() if payload == "smoke" else WEAPON_MESHES.make_grenade_view_model()
	_grenade_view_payload = payload
	if grenade_view_root == null:
		return
	grenade_view_root.name = "GrenadeView"
	grenade_view_root.position = Vector3(0.18, -0.16, -0.38)
	grenade_view_root.scale = Vector3.ONE * 0.72
	grenade_view_root.visible = false
	camera.add_child(grenade_view_root)

	grenade_safety_lever = grenade_view_root.find_child("SafetyLever", true, false)
	grenade_pull_ring = grenade_view_root.find_child("PullRing", true, false)
	grenade_hand_left = grenade_view_root.find_child("HandLeft", true, false)
	grenade_hand_right = grenade_view_root.find_child("HandRight", true, false)

func _on_heal_released() -> void:
	heal_hold = false
	if is_healing:
		_cancel_healing()

func _on_mobile_grenade_changed(pressed: bool) -> void:
	if pressed:
		_start_grenade_hold()
	else:
		_release_grenade_throw()

func _start_grenade_hold(payload: String = "frag") -> void:
	if payload == "smoke":
		if smoke_grenades <= 0:
			return
	elif grenades <= 0:
		return
	if is_dead or input_locked or is_healing or active_drone != null or is_reloading or is_vaulting:
		return
	_grenade_payload = payload
	_ensure_grenade_view(payload)
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
			# Левая рука видна, пока тянет чеку; после рывка убирается.
			if grenade_hand_left != null:
				grenade_hand_left.visible = true
				grenade_hand_left.position.x = -0.075
		_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -8.0, 1.35)

func _release_grenade_throw() -> void:
	is_grenade_held = false
	if grenade_anim_state == GrenadeActionState.HOLD_AIM:
		grenade_anim_state = GrenadeActionState.THROW_SWING
		grenade_anim_timer = 0.26
		_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -2.0, 1.45)
	elif grenade_anim_state == GrenadeActionState.PULL_PIN or grenade_anim_state == GrenadeActionState.EQUIP:
		pass

func _grenade_throw_origin() -> Vector3:
	if grenade_view_root != null and is_instance_valid(grenade_view_root):
		return grenade_view_root.global_position
	return camera.global_position + camera.global_transform.basis.x * 0.24 - camera.global_transform.basis.y * 0.34 - camera.global_transform.basis.z * 0.48

func _spawn_thrown_grenade() -> void:
	if grenade_has_spawned:
		return
	if _grenade_payload == "smoke":
		if smoke_grenades <= 0:
			return
		grenade_has_spawned = true
		smoke_grenades -= 1
		_refresh_equipment()
		var smoke := SMOKE_SCRIPT.new()
		var smoke_dir := -camera.global_transform.basis.z + Vector3.UP * 0.20
		smoke.position = _grenade_throw_origin()
		smoke.linear_velocity = smoke_dir.normalized() * 13.5 + velocity * 0.4
		smoke.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
		smoke.thrower_name = "Player"
		get_parent().add_child(smoke)
		_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -3.0, 1.4)
		if grenade_safety_lever != null:
			grenade_safety_lever.visible = false
		_hide_grenade_view_after_throw()
		return
	if grenades <= 0:
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
		# Граната вылетает из кисти, а не из центра камеры.
		var throw_dir := -camera.global_transform.basis.z + Vector3.UP * 0.20
		g.position = _grenade_throw_origin()
		g.linear_velocity = throw_dir.normalized() * 14.5 + velocity * 0.45
	g.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
	g.thrower_name = "Player"
	g.team_name = MatchState.player_team
	get_parent().add_child(g)
	_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -3.0, 1.4)
	if grenade_safety_lever != null:
		grenade_safety_lever.visible = false
	_hide_grenade_view_after_throw()

func _hide_grenade_view_after_throw() -> void:
	if grenade_view_root != null and is_instance_valid(grenade_view_root):
		grenade_view_root.visible = false

func _update_grenade_animation(delta: float) -> void:
	if grenade_anim_state == GrenadeActionState.IDLE:
		if grenade_view_root != null and grenade_view_root.visible:
			grenade_view_root.visible = false
		# QA-fix TASK-0022: оружие возвращается в руки после броска.
		if weapon_root != null and not weapon_root.visible and not is_dead and not is_shovel_equipped:
			weapon_root.visible = true
		return

	# QA-fix TASK-0022: на время работы с гранатой оружие полностью убирается —
	# раньше автомат оставался на экране вместе с руками гранаты («каша»).
	if weapon_root != null:
		weapon_root.visible = false

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
					grenade_anim_timer = 0.26

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
			var swing_progress := 1.0 - clampf(grenade_anim_timer / 0.26, 0.0, 1.0)
			if grenade_view_root != null:
				var throw_target_pos := Vector3(0.06, -0.12, -0.62)
				var throw_target_rot := Vector3(deg_to_rad(-38.0), deg_to_rad(10.0), deg_to_rad(-14.0))
				grenade_view_root.position = grenade_view_root.position.lerp(throw_target_pos, delta * 26.0)
				grenade_view_root.rotation = grenade_view_root.rotation.lerp(throw_target_rot, delta * 26.0)
			if swing_progress >= 0.72 and not grenade_has_spawned:
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
## QA-fix TASK-0022: ступеньки/бордюры/швы до 0.55 м больше не «застревают».
## Раньше CharacterBody3D упирался в любой пиксельный выступ; теперь, если
## перед игроком низкий бортик с проходимой площадкой сверху, капсула
## аккуратно приподнимается на него.
func _try_step_up() -> void:
	if is_vaulting or stance != 0 or not is_on_floor():
		return
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length_squared() < 0.30:
		return
	var dir := horizontal.normalized()
	var feet := global_position
	var space := get_world_3d().direct_space_state
	var low_from := feet + Vector3.UP * 0.08 + dir * 0.28
	var low_q := PhysicsRayQueryParameters3D.create(low_from, low_from + dir * 0.36)
	low_q.collision_mask = WORLD_LAYER_MASK
	low_q.exclude = [get_rid()]
	low_q.collide_with_areas = false
	var low_hit := space.intersect_ray(low_q)
	if low_hit.is_empty():
		return
	var top_from: Vector3 = low_hit.position + Vector3.UP * 0.70
	var top_q := PhysicsRayQueryParameters3D.create(top_from, top_from + Vector3.DOWN * 0.85)
	top_q.collision_mask = WORLD_LAYER_MASK
	top_q.exclude = [get_rid()]
	top_q.collide_with_areas = false
	var top_hit := space.intersect_ray(top_q)
	if top_hit.is_empty():
		return
	var rise: float = float(top_hit.position.y) - feet.y
	if rise < 0.03 or rise > 0.55:
		return
	if float(top_hit.get("normal", Vector3.UP).y) < 0.55:
		return
	var clearance := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.33
	capsule.height = 1.15
	clearance.shape = capsule
	clearance.transform = Transform3D(Basis(), feet + Vector3.UP * (rise + 0.65) + dir * 0.30)
	clearance.collision_mask = WORLD_LAYER_MASK
	clearance.exclude = [get_rid()]
	clearance.collide_with_areas = false
	if not space.intersect_shape(clearance, 1).is_empty():
		return
	global_position = feet + Vector3.UP * (rise + 0.03)
	velocity.y = maxf(velocity.y, 0.0)

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
	if smoke_grenades <= 0 or is_dead or input_locked:
		return
	# QA-fix TASK-0022: дымовая бросается через ту же анимацию, что и Ф-1
	# (достал -> выдернул чеку -> замах -> бросок), а не «вылетает из головы».
	if grenade_anim_state == GrenadeActionState.IDLE:
		_start_grenade_hold("smoke")
		_release_grenade_throw()

func _use_heal() -> void:
	if medkits <= 0 or is_dead or is_healing:
		return
	heal_target = null
	if player_role == "MEDIC":
		var player_team := MatchState.player_team
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
	heal_hold = true
	heal_anim_time = 0.0
	heal_timer = 2.2
	_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -4.0, 1.0)
	_refresh_equipment()

func _cancel_healing() -> void:
	if not is_healing:
		return
	is_healing = false
	heal_target = null
	heal_timer = 0.0
	heal_hold = false
	_finish_heal_visual()
	_refresh_equipment()

func _refresh_ammo() -> void:
	if ammo_label == null:
		return
	if is_shovel_equipped:
		ammo_label.text = "ЛОПАТА   •   ГРУНТ %d / 6" % carried_soil
		return
	var weapon := _weapon_data()
	var slot := "ЗАПАСНОЙ" if current_weapon_index == SIDEARM_INDEX else str(current_weapon_index + 1)
	ammo_label.text = "%s  %s   %d / %d" % [slot, str(weapon.display_name), ammo, reserve_ammo]

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
	var nearest_distance := 2.6
	var candidates: Array[Node3D] = []
	for p in nearby_field_pickups:
		if is_instance_valid(p) and not candidates.has(p):
			candidates.append(p)
	for p in get_tree().get_nodes_in_group("field_weapon_pickups"):
		if is_instance_valid(p) and not candidates.has(p):
			candidates.append(p as Node3D)
	for p in get_tree().get_nodes_in_group("field_supply_crates"):
		if is_instance_valid(p) and not candidates.has(p):
			candidates.append(p as Node3D)

	for pickup in candidates:
		if not is_instance_valid(pickup):
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
			var new_text := str(prompt.call("prompt_text", OS.has_feature("mobile")))
			if pickup_label.text != new_text:
				pickup_label.text = new_text
	if mobile_controls != null:
		var show_interact := (mounted_vehicle != null or enterable != null or pickup != null)
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
	return _weapons.can_take_reserve()

func take_field_ammo(amount: int) -> int:
	if not can_take_field_ammo(amount):
		return 0
	return _weapons.add_reserve(amount)

func can_take_weapon_pickup(index: int, clip: int, reserve: int) -> bool:
	if is_dead or input_locked or index < 0 or index >= FRONTLINEWeaponCatalog.count():
		return false
	if index != current_weapon_index:
		return true
	var stored_clip := ammo
	var stored_reserve := reserve_ammo
	var definition: FRONTLINEWeaponDef = FRONTLINEWeaponCatalog.get_def(index)
	var max_mag := int(definition.magazine)
	var max_reserve := int(definition.reserve)
	return stored_clip < max_mag or stored_reserve < max_reserve

func take_weapon_pickup(index: int, clip: int, reserve: int) -> bool:
	if not can_take_weapon_pickup(index, clip, reserve):
		return false
	if index == current_weapon_index:
		_weapons.refill_current(clip, reserve)
		return true

	var previous_index := current_weapon_index
	var previous_clip := ammo
	var previous_reserve := reserve_ammo
	_weapons.store_current()
	_weapons.clear_slot(previous_index)
	_spawn_weapon_drop(previous_index, previous_clip, previous_reserve)

	_weapons.replace_role_slot(previous_index, index)
	_weapons.equip_from_pickup(index, clip, reserve)
	weapon_kick = 0.0
	_set_aiming(false)
	if mobile_controls != null and mobile_controls.has_method("reset_aim"):
		mobile_controls.call("reset_aim")
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
		get_tree().create_timer(2.6, false).timeout.connect(func():
			if is_dead and death_screen != null and death_screen.visible:
				var parent_node := get_parent()
				if parent_node != null and parent_node.has_method("open_tactical_deploy"):
					death_screen.visible = false
					parent_node.call("open_tactical_deploy")
		)

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

	# Роль и основное оружие сохраняются; сбрасываются только патроны и снаряжение.
	var chosen_primary := role_primary_weapon_index
	_configure_role_loadout(player_role)
	if chosen_primary >= 0 and chosen_primary < FRONTLINEWeaponCatalog.count():
		_weapons.set_primary_slot(chosen_primary)
	_weapons.select_primary(true)

	is_shovel_equipped = false
	carried_soil = 0
	shovel_action_cooldown = 0.0
	_equip_weapon_visual()

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
