extends CharacterBody3D

const MOBILE_CONTROLS = preload("res://scripts/mobile_controls.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const PLAYER_BODY = preload("res://scripts/player_body.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const FIELD_PICKUP_SCRIPT = preload("res://scripts/field_pickup.gd")
const ROCKET_PROJECTILE_SCRIPT = preload("res://scripts/rocket_projectile.gd")
const BULLET_PROJECTILE_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const RADIO_DRONE_SCRIPT = preload("res://scripts/radio_drone.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const WEAPON_SOUND = preload("res://scripts/weapon_sound_bank.gd")

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
var _weapon_view: FRONTLINEPlayerWeaponView
var _weapon_view_state := FRONTLINEWeaponViewState.new()
var weapon_root: Node3D:
	get: return _weapon_view.root if _weapon_view != null else null
var weapon_mount: Node3D:
	get: return _weapon_view.mount if _weapon_view != null else null
var weapon_muzzle: Node3D:
	get: return _weapon_view.muzzle if _weapon_view != null else null
var weapon_base: Vector3:
	get: return _weapon_view.base_position if _weapon_view != null else Vector3.ZERO
	set(value): if _weapon_view != null: _weapon_view.base_position = value
var weapon_aim_position: Vector3:
	get: return _weapon_view.aim_position if _weapon_view != null else Vector3.ZERO
	set(value): if _weapon_view != null: _weapon_view.aim_position = value
var muzzle_flash: MeshInstance3D:
	get: return _weapon_view.flash if _weapon_view != null else null
var muzzle_flash_time: float:
	get: return _weapon_view.flash_timer if _weapon_view != null else 0.0
	set(value): if _weapon_view != null: _weapon_view.flash_timer = value
var drone_controller_anchor: Marker3D
var drone_controller_view: Node3D
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
var _pickups := FRONTLINEPlayerPickups.new()

var _view_arms: FRONTLINEPlayerViewArms
var _view_arm_left: Node3D:
	get: return _view_arms.left_arm if _view_arms != null else null
var _view_arm_right: Node3D:
	get: return _view_arms.right_arm if _view_arms != null else null
var wrist_left_marker: Node3D:
	get: return _view_arms.wrist_left if _view_arms != null else null
var wrist_right_marker: Node3D:
	get: return _view_arms.wrist_right if _view_arms != null else null
var player_body: Node3D
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
var medkits := 2
var is_healing := false
var heal_timer := 0.0
var heal_target: Node3D
var heal_hold := false
var heal_anim_time := 0.0
var heal_view_root: Node3D
var heal_bandage: Node3D
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

# Гранаты: состояние и viewmodel живут в отдельном компоненте.
var _grenades := FRONTLINEPlayerGrenades.new()
var grenade_anim_state: int:
	get: return _grenades.state
	set(value): _grenades.state = value
var is_grenade_held: bool:
	get: return _grenades.is_held
var grenades: int:
	get: return _grenades.grenade_count
	set(value): _grenades.grenade_count = value
var smoke_grenades: int:
	get: return _grenades.smoke_count
	set(value): _grenades.smoke_count = value

# Здоровье и статус игрока
var health := MAX_HEALTH
var is_dead := false
var input_locked := false
var respawn_position := Vector3.ZERO

var _player_hud: FRONTLINEPlayerHUD
var hud: CanvasLayer:
	get: return _player_hud if _player_hud != null else null

var mobile_controls: MobileControls
var mobile_move := Vector2.ZERO
var _vehicles := FRONTLINEPlayerVehicles.new()
var mounted_vehicle: Node3D:
	get: return _vehicles.vehicle
var _prompt_timer := 0.0
var mobile_fire := false
var sprint_hold := 0.0
var pause_menu: FRONTLINEPauseMenu:
	get: return _player_hud.pause_menu if _player_hud != null else null

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
	_pickups.setup(self)
	_grenades.equipment_changed.connect(_refresh_equipment)
	_grenades.sound_requested.connect(_on_grenade_sound)
	_init_weapon_inventory()
	_build_player()
	_build_weapon()
	add_child(_grenades)
	_grenades.setup(self, camera, weapon_root)
	_vehicles.setup(self)
	_build_body()
	_build_audio()
	_build_mobile_controls()
	_build_hud()
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
	_weapon_view = FRONTLINEPlayerWeaponView.new()
	_weapon_view.name = "WeaponView"
	camera.add_child(_weapon_view)
	_weapon_view.setup(camera)
	_view_arms = FRONTLINEPlayerViewArms.new()
	_view_arms.name = "ViewArms"
	camera.add_child(_view_arms)
	_view_arms.setup(camera, weapon_root)
	_weapon_view.attach_arms(_view_arms)
	_equip_weapon_visual()
	_build_heal_view()

func _equip_weapon_visual() -> void:
	if _weapon_view == null:
		return
	var weapon_id := "entrenching_shovel" if is_shovel_equipped else str(_weapon_data().id)
	_weapon_view.equip(weapon_id, is_shovel_equipped)

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
	if is_dead or index < 0 or index >= FRONTLINEWeaponCatalog.count() or _grenades.is_busy():
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
	if _grenades.is_busy():
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
	if is_dead or input_locked or _grenades.is_busy():
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
	if is_dead or input_locked or active_drone != null or _grenades.is_busy():
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

func _update_view_arms() -> void:
	if _view_arms == null:
		return
	var visible := weapon_root != null and weapon_root.visible
	_view_arms.update(visible and not _grenades.is_busy())

func _update_viewmodel_visibility(scoped: bool) -> void:
	if weapon_root == null:
		return
	if is_dead:
		return
	# Во время гранаты/лечения/лопаты видимостью управляют их состояния.
	if is_healing or _grenades.is_busy() or is_shovel_equipped:
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

func open_pause_menu() -> void:
	if _player_hud != null:
		_player_hud.open_pause()

func _on_hud_deploy_requested() -> void:
	var world := get_parent()
	if world != null and world.has_method("open_tactical_deploy"):
		world.call("open_tactical_deploy")
	else:
		respawn()

func _on_pause_resumed() -> void:
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_input_locked(locked: bool) -> void:
	input_locked = locked
	if locked:
		velocity = Vector3.ZERO
		mobile_fire = false
		if _player_hud != null:
			_player_hud.set_pickup_prompt("")
			_player_hud.hide_death()
			_player_hud.set_crosshair_visible(false)
		if mobile_controls != null:
			mobile_controls.visible = false
			mobile_controls.set_interact_visible(false)
	else:
		if mobile_controls != null:
			mobile_controls.visible = true
		if _player_hud != null:
			_player_hud.set_crosshair_visible(not aiming)

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
	_player_hud = FRONTLINEPlayerHUD.new()
	add_child(_player_hud)
	_player_hud.setup(self)
	_player_hud.pause_resumed.connect(_on_pause_resumed)
	_player_hud.deploy_requested.connect(_on_hud_deploy_requested)
	_refresh_ammo()
	_refresh_health()
	_refresh_equipment()

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
	if _vehicles.vehicle != null and not is_instance_valid(_vehicles.vehicle):
		_vehicles.vehicle = null
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
	if _vehicles.vehicle != null and not is_instance_valid(_vehicles.vehicle):
		_vehicles.vehicle = null
	if _vehicles.is_mounted():
		# Сначала применяем взгляд, затем тик техники: турель берёт свежую
		# камеру (иначе наводка отстаёт на кадр).
		_apply_look(delta)
		_vehicles.process(delta)
		return
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
	if _player_hud != null:
		_player_hud.set_scope(scoped_ads)
		_player_hud.set_crosshair_visible(not is_dead and active_drone == null)
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

	# Визуал оружия обновляется отдельным компонентом.
	look_sway = look_sway.lerp(Vector2.ZERO, clampf(delta * 9.0, 0.0, 1.0))
	var view_state := _weapon_view_state
	view_state.delta = delta
	view_state.aim_blend = aim_blend
	view_state.aiming = aiming
	view_state.weapon_kick = weapon_kick
	view_state.look_sway = look_sway
	view_state.bob_time = bob_time
	view_state.breathing_time = breathing_time
	view_state.sprint_anim = sprint_anim
	view_state.landing_anim = landing_anim
	view_state.stance = stance
	view_state.strafe_x = mobile_move.x
	view_state.is_reloading = is_reloading
	view_state.reload_progress = _weapons.reload_progress()
	view_state.allow_arms = not _grenades.is_busy()
	_weapon_view.update(view_state)

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

	if _player_hud != null:
		_player_hud.update(delta, health)

	recoil = recoil.lerp(Vector2.ZERO, clampf(delta * 7.0, 0.0, 1.0))
	var target_height := 1.95 if stance == 0 else (1.35 if stance == 1 else 0.70)
	player_capsule.height = lerpf(player_capsule.height, target_height, clampf(delta * 10.0, 0.0, 1.0))
	player_collision.position.y = player_capsule.height * 0.5
	var target_y := 1.70 if stance == 0 else (1.28 if stance == 1 else 0.52)
	var run_boost := 1.0 + sprint_anim * 0.9
	var bob_factor := 0.20 if aiming else 1.0
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
	_vehicles.process(delta)

func _enter_vehicle(target: Node3D) -> void:
	_vehicles.enter(target)

func _exit_vehicle() -> void:
	_vehicles.exit()

func _nearest_enterable() -> Node3D:
	return _vehicles.nearest_enterable()

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
	if _grenades.is_busy():
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
	if _player_hud != null:
		_player_hud.flash_hit()
	if was_alive and actor.is_in_group("damageable_actor") and "health" in actor and float(actor.get("health")) <= 0.0:
		# QA-fix TASK-0022: вместо «pew»-джингла — глухой звук попадания.
		_play_sfx(sfx_kill, SFX_HIT_FLESH, -6.0, randf_range(0.72, 0.82))
		if world != null and world.has_method("add_kill"):
			world.call("add_kill")

func _reload() -> void:
	if is_shovel_equipped or _grenades.is_busy():
		return
	if is_healing or is_dead or input_locked:
		return
	if _weapons.start_reload():
		_play_sfx(sfx_reload_out, SFX_RELOAD_OUT, -6.0, 1.0)

func _on_weapon_reload_finished() -> void:
	_play_sfx(sfx_reload_in, SFX_RELOAD_IN, -4.0, 1.0)

func _on_grenade_sound(stream: AudioStream, volume_db: float, pitch: float) -> void:
	_play_sfx(sfx_reload_in, stream, volume_db, pitch)

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
	if _player_hud != null:
		_player_hud.set_heal_progress(clampf(1.0 - heal_timer / 2.2, 0.0, 1.0))

func _finish_heal_visual() -> void:
	heal_anim_time = 0.0
	if heal_view_root != null and is_instance_valid(heal_view_root):
		heal_view_root.visible = false
	if _player_hud != null:
		_player_hud.set_heal_progress(-1.0)
	if weapon_root != null and not is_dead and not is_shovel_equipped and not _grenades.is_busy():
		weapon_root.visible = true

func _on_mobile_grenade_changed(pressed: bool) -> void:
	if pressed:
		_grenades.start_hold()
	else:
		_grenades.release_throw()

func _on_heal_released() -> void:
	heal_hold = false
	if is_healing:
		_cancel_healing()

func _start_grenade_hold(payload: String = "frag") -> void:
	_grenades.start_hold(payload)

func _release_grenade_throw() -> void:
	_grenades.release_throw()

func _throw_grenade() -> void:
	_grenades.throw_grenade()

func _update_grenade_animation(delta: float) -> void:
	_grenades.tick(delta)

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
	if is_dead or input_locked or is_vaulting or active_drone != null or _grenades.is_busy():
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
	_grenades.throw_smoke()

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
	if _player_hud == null:
		return
	if is_shovel_equipped:
		_player_hud.set_ammo_text("ЛОПАТА   •   ГРУНТ %d / 6" % carried_soil)
		return
	var weapon := _weapon_data()
	var slot := "ЗАПАСНОЙ" if current_weapon_index == SIDEARM_INDEX else str(current_weapon_index + 1)
	_player_hud.set_ammo_text("%s  %s   %d / %d" % [slot, str(weapon.display_name), ammo, reserve_ammo])

func _refresh_health() -> void:
	if _player_hud != null:
		_player_hud.set_health(health)

func _refresh_equipment() -> void:
	if _player_hud == null:
		return
	var role_names := {"ASSAULT": "ШТУРМ", "MEDIC": "МЕДИК", "SNIPER": "СНАЙПЕР", "ANTI_TANK": "ПТ", "RADIO_OPERATOR": "РАДИСТ"}
	var role_text := str(role_names.get(player_role, "ШТУРМ"))
	var drone_text := " • FPV ГОТОВ" if player_role == "RADIO_OPERATOR" and drone_charge_available else (" • FPV ИСПОЛЬЗОВАН" if player_role == "RADIO_OPERATOR" else "")
	var soil_text := " • ГРУНТ:%d" % carried_soil if carried_soil > 0 else ""
	_player_hud.set_equipment_text("%s • ГР:%d • ДЫМ:%d • БИНТ:%d%s%s" % [role_text, grenades, smoke_grenades, medkits, drone_text, soil_text])

func register_field_pickup(pickup: Node3D) -> void:
	_pickups.register(pickup)
	_refresh_pickup_prompt()

func unregister_field_pickup(pickup: Node3D) -> void:
	_pickups.unregister(pickup)
	_refresh_pickup_prompt()

func _nearest_field_pickup() -> Node3D:
	return _pickups.nearest_field_pickup()

func _refresh_pickup_prompt() -> void:
	if _vehicles.vehicle != null and not is_instance_valid(_vehicles.vehicle):
		_vehicles.vehicle = null
	var target := _pickups.prompt_target()
	if _player_hud != null:
		var prompt_text := ""
		if target != null and target.has_method("prompt_text"):
			prompt_text = str(target.call("prompt_text", OS.has_feature("mobile")))
		_player_hud.set_pickup_prompt(prompt_text)
	if mobile_controls != null:
		mobile_controls.set_interact_visible(target != null)

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
		_pickups.unregister(pickup)
		_refresh_pickup_prompt()
		_play_sfx(sfx_ui, SFX_UI, -2.0, 1.12)

func can_take_field_ammo(amount: int) -> bool:
	return _pickups.can_take_field_ammo(amount)

func take_field_ammo(amount: int) -> int:
	return _pickups.take_field_ammo(amount)

func can_take_weapon_pickup(index: int, clip: int, reserve: int) -> bool:
	return _pickups.can_take_weapon(index, clip, reserve)

func take_weapon_pickup(index: int, clip: int, reserve: int) -> bool:
	return _pickups.take_weapon(index, clip, reserve)

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
	if _player_hud != null:
		_player_hud.show_damage(amount)

func receive_hit(damage: int, attacker_pos: Vector3, region: String = "chest", attacker_name: String = "Enemy") -> void:
	if is_dead:
		return
	_cancel_healing()
	health = maxf(0.0, health - float(damage))
	if _player_hud != null:
		_player_hud.flash_blood()
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
	_grenades.drop_on_death()
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
	if _player_hud != null:
		_player_hud.set_pickup_prompt("")
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
	if _player_hud != null:
		_player_hud.set_crosshair_visible(false)
		_player_hud.show_death(killer_name)
		get_tree().create_timer(2.6, false).timeout.connect(func():
			if is_dead and _player_hud != null and _player_hud.is_death_visible():
				var parent_node := get_parent()
				if parent_node != null and parent_node.has_method("open_tactical_deploy"):
					_player_hud.hide_death()
					parent_node.call("open_tactical_deploy")
		)

func respawn() -> void:
	if active_drone != null and is_instance_valid(active_drone):
		active_drone.return_to_operator()
	if camera != null:
		camera.current = true

	is_dead = false
	is_vaulting = false
	_grenades.reset()
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

	if _player_hud != null:
		_player_hud.reset_after_respawn()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
