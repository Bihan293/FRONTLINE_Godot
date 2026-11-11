extends CharacterBody3D

const PLAYER_BODY = preload("res://scripts/player_body.gd")
const FIELD_PICKUP_SCRIPT = preload("res://scripts/field_pickup.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const PLAYER_HUD_SCENE = preload("res://scenes/PlayerHUD.tscn")

const SFX_FOOTSTEPS = [
	preload("res://assets/audio/footstep_000.ogg"),
	preload("res://assets/audio/footstep_001.ogg"),
	preload("res://assets/audio/footstep_002.ogg"),
]

const SPEED := 5.2
const SPRINT_SPEED := 7.4
const JUMP_VELOCITY := 5.4
const MAX_HEALTH := 100.0
const SIDEARM_INDEX := 3 # M1911 is carried as a backup sidearm by every role.

const WORLD_LAYER_MASK := 1 << 0
const HITBOX_LAYER_MASK := 1 << 1
const SOLDIER_LAYER_MASK := 1 << 2
const RAY_COLLISION_MASK := WORLD_LAYER_MASK | HITBOX_LAYER_MASK

var _camera_rig := FRONTLINEPlayerCameraRig.new()
var camera: Camera3D:
	get:
		return _camera_rig.camera
var audio_listener: AudioListener3D:
	get:
		return _camera_rig.audio_listener
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
var weapon_kick := 0.0
var weapon_action_offset := Vector3.ZERO
var weapon_mesh_visible := true
var _locomotion := FRONTLINEPlayerLocomotion.new()
var sprint_anim: float:
	get:
		return _locomotion.sprint_anim
var landing_anim: float:
	get:
		return _locomotion.landing_anim
	set(value):
		_locomotion.landing_anim = value
var bob_time: float:
	get:
		return _locomotion.bob_time
var breathing_time: float:
	get:
		return _locomotion.breathing_time
var aim_blend := 0.0
var aiming := false
var look_sway := Vector2.ZERO
var lean_toggle: int:
	get:
		return _camera_rig.lean_toggle

# === BODYCAM / DUMMY WAR РЕАЛИЗМ ===
var _equipment := FRONTLINEPlayerEquipment.new()
var _combat := FRONTLINEPlayerCombat.new()
var _weapons: FRONTLINEWeaponController:
	get:
		return _equipment.weapons
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
var _shovel := FRONTLINEPlayerShovel.new()
var is_shovel_equipped: bool:
	get:
		return _shovel.equipped
	set(value):
		_shovel.equipped = value
var carried_soil: int:
	get:
		return _shovel.carried_soil
	set(value):
		_shovel.carried_soil = value
var shovel_action_cooldown: float:
	get:
		return _shovel.action_cooldown
	set(value):
		_shovel.action_cooldown = value
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
var _healing := FRONTLINEPlayerHealing.new()
var medkits: int:
	get:
		return _healing.medkits
	set(value):
		_healing.medkits = value
var is_healing: bool:
	get:
		return _healing.is_healing
var heal_view_root: Node3D:
	get:
		return _healing.heal_view_root
var throwable_cooldown := 0.0
var player_role: String:
	get:
		return _equipment.role
	set(value):
		_equipment.role = value
var _drone := FRONTLINEPlayerDrone.new()
var active_drone: CharacterBody3D:
	get:
		return _drone.active_drone

# Паркур / Преодоление препятствий (Parkour / Mantling / Vaulting)
var _vault := FRONTLINEPlayerVault.new()
var is_vaulting: bool:
	get:
		return _vault.is_vaulting

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
var _health := FRONTLINEPlayerHealth.new()
var health: float:
	get:
		return _health.health
	set(value):
		_health.health = value
var is_dead: bool:
	get:
		return _health.is_dead
	set(value):
		_health.is_dead = value
var respawn_position: Vector3:
	get:
		return _health.respawn_position
	set(value):
		_health.respawn_position = value
var input_locked := false

var _player_hud: FRONTLINEPlayerHUD
var hud: CanvasLayer:
	get: return _player_hud if _player_hud != null else null

var _input := FRONTLINEPlayerInput.new()
var mobile_controls: MobileControls:
	get:
		return _input.mobile_controls
var mobile_move: Vector2:
	get:
		return _input.mobile_move
	set(value):
		_input.mobile_move = value
var _vehicles := FRONTLINEPlayerVehicles.new()
var mounted_vehicle: Node3D:
	get: return _vehicles.vehicle
var _prompt_timer := 0.0
var mobile_fire := false
var pause_menu: FRONTLINEPauseMenu:
	get: return _player_hud.pause_menu if _player_hud != null else null

var _audio := FRONTLINEPlayerAudio.new()
var sfx_shot: AudioStreamPlayer:
	get:
		return _audio.sfx_shot
var sfx_empty: AudioStreamPlayer:
	get:
		return _audio.sfx_empty
var sfx_reload_out: AudioStreamPlayer:
	get:
		return _audio.sfx_reload_out
var sfx_reload_in: AudioStreamPlayer:
	get:
		return _audio.sfx_reload_in
var sfx_ui: AudioStreamPlayer:
	get:
		return _audio.sfx_ui
var sfx_footstep: AudioStreamPlayer:
	get:
		return _audio.sfx_footstep
var sfx_hit: AudioStreamPlayer:
	get:
		return _audio.sfx_hit
var sfx_kill: AudioStreamPlayer:
	get:
		return _audio.sfx_kill

func _ready() -> void:
	add_to_group("player")
	_health.setup(self, MAX_HEALTH)
	_equipment.setup(self)
	_combat.setup(self)
	_input.setup(self)
	floor_snap_length = 0.25
	floor_max_angle = deg_to_rad(48.0)
	respawn_position = position
	_weapons.ammo_changed.connect(_refresh_ammo)
	_weapons.reload_finished.connect(_on_weapon_reload_finished)
	_pickups.setup(self)
	_grenades.equipment_changed.connect(_refresh_equipment)
	_grenades.sound_requested.connect(_on_grenade_sound)
	_equipment.init_inventory()
	_build_player()
	_camera_rig.setup(self)
	_healing.setup(self, camera, MAX_HEALTH)
	_drone.setup(self, camera, audio_listener)
	_shovel.setup(self, camera)
	_locomotion.setup(self, SPEED, SPRINT_SPEED)
	_build_weapon()
	add_child(_grenades)
	_grenades.setup(self, camera, weapon_root)
	_vehicles.setup(self)
	_vault.setup(self, SPRINT_SPEED)
	_build_body()
	_audio.setup(self)
	_input.build_mobile_controls()
	_build_hud()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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

func _build_weapon() -> void:
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
	_healing.build_view()

func _equip_weapon_visual() -> void:
	if _weapon_view == null:
		return
	var weapon_id := "entrenching_shovel" if is_shovel_equipped else str(_weapon_data().id)
	_weapon_view.equip(weapon_id, is_shovel_equipped)

func _configure_role_loadout(role_name: String) -> void:
	_equipment.configure_role(role_name)

## Публичный вход для экрана деплоя: роль и основное оружие переносятся
## между смертями, а не сбрасываются на ASSAULT.
func apply_loadout(role_name: String, primary_index: int) -> void:
	_equipment.apply_loadout(role_name, primary_index)

func _weapon_data() -> FRONTLINEWeaponDef:
	return _equipment.weapon_data()

func _switch_weapon(index: int) -> void:
	_equipment.switch_weapon(index)

## QA-fix TASK-0022: цикл снаряжения в руке — автомат → пистолет → лопата.
func _cycle_equipment(direction: int) -> void:
	_equipment.cycle_equipment(direction)

func _refresh_equipment_icon() -> void:
	_equipment.refresh_equipment_icon()

func _cycle_weapon(direction: int) -> void:
	_equipment.cycle_weapon(direction)

func _select_weapon_slot(slot: int) -> void:
	_equipment.select_weapon_slot(slot)

func _toggle_sidearm() -> void:
	_equipment.toggle_sidearm()

func _toggle_shovel() -> void:
	_shovel.toggle()

func _on_shovel_button() -> void:
	_shovel.on_button()

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
		_drone.build_controller_view(player_body)

func set_drone_controller_feed(feed: Texture2D) -> void:
	_drone.set_controller_feed(feed)

func _update_view_arms() -> void:
	if _view_arms == null:
		return
	var manual := _view_arms.has_manual_pose()
	_view_arms.update(not is_dead and (weapon_root.visible or manual))

func _set_weapon_mesh_visible(value: bool) -> void:
	weapon_mesh_visible = value

func _set_weapon_action_offset(offset: Vector3) -> void:
	weapon_action_offset = offset

func _set_action_hands(left_xf: Transform3D, right_xf: Transform3D, show_left := true, show_right := true) -> void:
	if _view_arms != null:
		_view_arms.set_manual_pose(left_xf, right_xf, show_left, show_right)

func _clear_action_hands() -> void:
	if _view_arms != null:
		_view_arms.clear_manual_pose()

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

func _play_sfx(audio_player: AudioStreamPlayer, stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	_audio.play(audio_player, stream, volume_db, pitch)

func _refresh_equipment_after_hud() -> void:
	_refresh_equipment_icon()

func _build_hud() -> void:
	_player_hud = PLAYER_HUD_SCENE.instantiate() as FRONTLINEPlayerHUD
	add_child(_player_hud)
	_player_hud.setup(self)
	_player_hud.pause_resumed.connect(_on_pause_resumed)
	_player_hud.deploy_requested.connect(_on_hud_deploy_requested)
	_refresh_ammo()
	_refresh_health()
	_refresh_equipment()

func _on_move_changed(value: Vector2) -> void:
	_input.mobile_move = value

func _on_look_delta(delta: Vector2) -> void:
	_input.preview_look(delta)

func _on_mobile_peek_left(pressed: bool) -> void:
	if pressed:
		_camera_rig.toggle_lean(-1)

func _on_mobile_peek_right(pressed: bool) -> void:
	if pressed:
		_camera_rig.toggle_lean(1)

func _on_drone_vertical_changed(direction: float, pressed: bool) -> void:
	_drone.set_vertical_input(direction, pressed)

func _launch_drone() -> void:
	_drone.toggle_launch()

func _unhandled_input(event: InputEvent) -> void:
	_input.handle(event)

func _physics_process(delta: float) -> void:
	if is_dead:
		_vault.cancel()
		if not is_on_floor():
			velocity.y -= 18.0 * delta
			move_and_slide()
		return
	if input_locked:
		_vault.cancel()
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
	if _vault.is_vaulting:
		_vault.process(delta)
		return
	if _drone.is_active():
		_drone.update_controls()
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
	_audio.update_acoustics(delta)
	COMBAT_AUDIO.listener_pos = camera.global_position
	COMBAT_AUDIO.listener_valid = true

	_weapons.tick(delta)
	throwable_cooldown = maxf(0.0, throwable_cooldown - delta)
	_shovel.tick(delta)
	_update_grenade_animation(delta)
	var blend := 1.0 - exp(-delta * 13.0)
	aim_blend = lerpf(aim_blend, 1.0 if aiming else 0.0, blend)
	var scoped_ads := aiming and str(_weapon_data().id) == "kar98k" and aim_blend > 0.85
	if _player_hud != null:
		_player_hud.set_scope(scoped_ads)
		_player_hud.set_crosshair_visible(not is_dead and active_drone == null)
	_update_viewmodel_visibility(scoped_ads)
	_camera_rig.update_fov(delta)
	_healing.tick(delta)

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
	view_state.allow_arms = not is_dead and (weapon_root.visible or (_view_arms != null and _view_arms.has_manual_pose()))
	view_state.action_offset = weapon_action_offset
	view_state.weapon_visible = weapon_mesh_visible
	_weapon_view.update(view_state)

	if mobile_fire or (not OS.has_feature("mobile") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		_shoot()

	_locomotion.process(delta)
	var planar_speed := _locomotion.planar_speed
	var current_speed := _locomotion.current_speed
	var on_floor := _locomotion.on_floor

	if _player_hud != null:
		_player_hud.update(delta, health)

	recoil = recoil.lerp(Vector2.ZERO, clampf(delta * 7.0, 0.0, 1.0))
	var target_height := 1.95 if stance == 0 else (1.35 if stance == 1 else 0.70)
	player_capsule.height = lerpf(player_capsule.height, target_height, clampf(delta * 10.0, 0.0, 1.0))
	player_collision.position.y = player_capsule.height * 0.5
	_camera_rig.process_lean_and_position(delta, planar_speed, current_speed)
	if player_body != null:
		player_body.set_motion(planar_speed, planar_speed > SPEED + 0.5)
		player_body.set_stance(stance)
		var look_down := clampf((-pitch - 0.22) / 0.45, 0.0, 1.0)
		player_body.set_look_down(look_down)
	_camera_rig.apply_look(delta)

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
	_camera_rig.apply_look(delta)

func add_camera_trauma(amount: float) -> void:
	_camera_rig.add_trauma(amount)

func apply_explosion_shake(explosion_pos: Vector3, radius: float = 32.0, max_trauma: float = 0.95) -> void:
	_camera_rig.apply_explosion_shake(explosion_pos, radius, max_trauma)

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
	_combat.shoot()

func _use_shovel_action(place_soil: bool) -> void:
	_shovel.use_action(place_soil)

func on_projectile_hit(actor: Node, damage_applied: int, was_alive: bool, region: String) -> void:
	_combat.on_projectile_hit(actor, damage_applied, was_alive, region)

func _reload() -> void:
	_combat.reload()

func _on_weapon_reload_finished() -> void:
	_combat.on_reload_finished()

func _on_grenade_sound(stream: AudioStream, volume_db: float, pitch: float) -> void:
	_play_sfx(sfx_reload_in, stream, volume_db, pitch)

func _on_mobile_grenade_changed(pressed: bool) -> void:
	if pressed:
		_grenades.start_hold()
	else:
		_grenades.release_throw()

func _on_heal_released() -> void:
	_healing.release_hold()

func _start_grenade_hold(payload: String = "frag") -> void:
	_grenades.start_hold(payload)

func _release_grenade_throw() -> void:
	_grenades.release_throw()

func _throw_grenade() -> void:
	_grenades.throw_grenade()

func _update_grenade_animation(delta: float) -> void:
	_grenades.tick(delta)

func _try_step_up() -> void:
	_vault.try_step_up()

func _try_vault() -> bool:
	return _vault.try_vault()

func _start_smoke_hold() -> void:
	_grenades.start_hold("smoke")

func _throw_smoke() -> void:
	_grenades.throw_smoke()

func _use_heal() -> void:
	_healing.use()

func _cancel_healing() -> void:
	_healing.cancel()

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
	var drone_text := " • FPV ГОТОВ" if player_role == "RADIO_OPERATOR" and _drone.charge_available else (" • FPV ИСПОЛЬЗОВАН" if player_role == "RADIO_OPERATOR" else "")
	var soil_text := " • ГРУНТ:%d" % carried_soil if carried_soil > 0 else ""
	_player_hud.set_equipment_text("%s • ГР:%d • ДЫМ:%d • БИНТ:%d%s%s" % [role_text, grenades, smoke_grenades, medkits, drone_text, soil_text])

func register_field_pickup(pickup: Node3D) -> void:
	_pickups.register(pickup)
	_pickups.refresh_prompt()

func unregister_field_pickup(pickup: Node3D) -> void:
	_pickups.unregister(pickup)
	_pickups.refresh_prompt()

func _refresh_pickup_prompt() -> void:
	_pickups.refresh_prompt()

func _interact_with_pickup() -> void:
	_pickups.interact()

func can_take_field_ammo(amount: int) -> bool:
	return _pickups.can_take_field_ammo(amount)

func take_field_ammo(amount: int) -> int:
	return _pickups.take_field_ammo(amount)

func can_take_weapon_pickup(index: int, clip: int, reserve: int) -> bool:
	return _pickups.can_take_weapon(index, clip, reserve)

func take_weapon_pickup(index: int, clip: int, reserve: int) -> bool:
	return _pickups.take_weapon(index, clip, reserve)

func _spawn_weapon_drop(index: int, clip: int, reserve: int) -> void:
	_pickups.spawn_weapon_drop(index, clip, reserve)

func _pop_damage(amount: int) -> void:
	_health.pop_damage(amount)

func receive_hit(damage: int, attacker_pos: Vector3, region: String = "chest", attacker_name: String = "Enemy") -> void:
	_health.receive_hit(damage, attacker_pos, region, attacker_name)

func respawn() -> void:
	_health.respawn()
