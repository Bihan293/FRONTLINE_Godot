extends CharacterBody3D
class_name FRONTLINESoldierBot

## Умный ИИ-солдат для масштабных сражений в стиле Dummy War.
## Имеет полную физику перемещения, поиск укрытий, командное зрение,
## стрельбу очередями, перезарядку, подавление и физический рэгдолл при гибели.

signal soldier_killed(victim: FRONTLINESoldierBot, killer_name: String, weapon_name: String)
signal soldier_fired(pos: Vector3, team: String)

const PERCEPTION = preload("res://scripts/ai/bot_perception.gd")
const TUNING = preload("res://scripts/ai/bot_tuning.gd")
const PROCEDURAL = preload("res://scripts/procedural_soldier.gd")
const BLOCK_RIG_BUILDER = preload("res://scripts/block_rig_builder.gd")
const TACTICAL_GEAR = preload("res://scripts/tactical_gear.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const FIELD_PICKUP_SCRIPT = preload("res://scripts/field_pickup.gd")
const BULLET_PROJECTILE_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const GRENADE_SCRIPT = preload("res://scripts/grenade.gd")
const SMOKE_SCRIPT = preload("res://scripts/smoke_grenade.gd")
const AMBIENCE = preload("res://scripts/battlefield_ambience.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const WEAPON_SOUND = preload("res://scripts/weapon_sound_bank.gd")
const COUNTRYSIDE_LAYOUT = preload("res://scripts/countryside_layout.gd")

const IRON_SCENE := "res://assets/models/soldiers/FRONTLINE_German_Grey_Block_Soldier.glb"
const RED_SCENE := "res://assets/models/soldiers/FRONTLINE_Soviet_Khaki_Block_Soldier.glb"
const SFX_SHOT = preload("res://assets/audio/shot.wav")
const SFX_RELOAD_OUT = preload("res://assets/audio/reload_out.ogg")
const SFX_RELOAD_IN = preload("res://assets/audio/reload_in.wav")
const SFX_HIT_FLESH = preload("res://assets/audio/hit_flesh.ogg")

const SPEED_WALK := 3.4
const SPEED_SPRINT := 5.6
const SPEED_CROUCH := 1.9
const MAX_HEALTH := 100.0
const MAG_SIZE := 30
const WORLD_LAYER_MASK := 1 << 0
const HITBOX_LAYER_MASK := 1 << 1
const SOLDIER_LAYER_MASK := 1 << 2
const RAY_COLLISION_MASK := WORLD_LAYER_MASK | HITBOX_LAYER_MASK

@export var team_name: String = "IRON LEGION"
@export var soldier_name: String = "Soldier"
@export var bot_weapon_index: int = -1

var health: float = MAX_HEALTH
var is_dead := false
var stance := 0  # 0: stand, 1: crouch
var ammo := MAG_SIZE
var is_reloading := false
var reload_timer := 0.0
var suppression := 0.0
var grenades := 1
var grenade_cooldown := randf_range(8.0, 20.0)

# Явные состояния вместо набора флагов.
enum State { ADVANCE, COMBAT, INVESTIGATE, RELOAD, DEAD }
var ai_state := State.ADVANCE

# Единственный источник правды о цели — модуль восприятия.
var current_target: Node3D:
	get:
		return _perception.target if _perception != null else null
	set(value):
		if _perception != null:
			_perception.force_target(value)

var _perception: FRONTLINEBotPerception
var burst_count := 0
var fire_cooldown := 0.0

# Тактический боевой ИИ (Dummy War Tactical Firefight)
var target_acquisition_timer := 0.0
var combat_strafe_timer := 0.0
var combat_strafe_dir := Vector3.ZERO
var _last_target_id := 0

# Узлы модели
var _pivot: Node3D
var _visual: Node3D
var _proc: FRONTLINEProceduralSoldier
var _gun_pivot: Node3D
var _gun_mesh: MeshInstance3D
var _muzzle_node: Node3D
var _muzzle_flash: MeshInstance3D
var _flash_time := 0.0
var _label: Label3D
var _sfx_shot: AudioStreamPlayer3D
var _sfx_reload: AudioStreamPlayer3D
var _hitboxes: Array[Area3D] = []
var _navigation: FRONTLINEBotNavigation
var _route_path := PackedVector3Array()
var _route_index := 0
var _route_repath_timer := 0.0
# Антизастревание: решение принимается до move_and_slide, а не после.
var _stuck_check_timer := 0.0
var _stuck_last_pos := Vector3.ZERO
var _unstick_timer := 0.0
var _unstick_dir := Vector3.ZERO
var _unstick_jump := false
var _intended_speed := 0.0
# QA-optimization: кэш акустики (4 Гц вместо каждого выстрела).
var _audio_env_timer := 0.0
var _audio_indoors := false
var _audio_occluded := false
var _self_rids: Array[RID] = []
# Обход препятствий считается один раз за кадр по итоговому направлению.
var _avoid_timer := 0.0
var _avoid_in := Vector3.ZERO
var _avoid_out := Vector3.ZERO
var _avoid_front := PhysicsRayQueryParameters3D.new()
var _avoid_left := PhysicsRayQueryParameters3D.new()
var _avoid_right := PhysicsRayQueryParameters3D.new()
var _fire_query := PhysicsRayQueryParameters3D.new()
var _sep_timer := 0.0
var _drone_timer := 0.0
var _nearest_drone_cached: Node3D = null
# QA-fix TASK-0022: тактическая «живость» — перебежки, приседания, разброс маршрутов.
var _personal_offset_x := 0.0
var _bound_timer := 0.0
var _bound_crouch := false
var _scan_time := 0.0
# QA-fix TASK-0022: укрытия под огнём.
var _cover_target := Vector3.ZERO
var _cover_timer := 0.0
var _route_goal := Vector3.ZERO
var _route_has_attempted := false
var _shout_timer := 0.0
# Данные карты кэшируются один раз, а не пересчитываются каждый кадр.
var _cached_map_name := "BATTLEFIELD"
var _sector_positions := PackedFloat32Array([-52.0, 0.0, 52.0])
var _enemy_base_z := 56.0
var _idle_patrol_timer := 0.0
var _patrol_point := Vector3.ZERO
var bot_role: String = "ASSAULT"
var match_difficulty: int = 1
var difficulty_spread_mult: float = 1.0
var difficulty_reaction_mult: float = 1.0
var difficulty_recovery_mult: float = 1.0
var _medic_timer: float = randf_range(3.0, 6.0)
var _cached_cam: Camera3D = null
var _cached_player: Node3D = null
var _label_update_timer: float = 0.0

static var profile_build := false

func _ready() -> void:
	var t_build := Time.get_ticks_usec()
	# Индивидуальный маршрут и ритм перебежек, чтобы отделение не шло «паровозиком».
	_personal_offset_x = randf_range(-9.0, 9.0)
	_bound_timer = randf_range(0.6, 2.2)
	_bound_crouch = false
	_label_update_timer = randf_range(0.0, 0.25)
	add_to_group("bots")
	add_to_group("damageable_actor")
	collision_layer = SOLDIER_LAYER_MASK
	collision_mask = WORLD_LAYER_MASK | SOLDIER_LAYER_MASK
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(45.0)
	_navigation = get_node_or_null("/root/BotNavigation") as FRONTLINEBotNavigation

	match_difficulty = clampi(int(get_tree().get_meta("match_difficulty", 1)), 0, 2)
	match match_difficulty:
		0:
			difficulty_spread_mult = 1.45
			difficulty_reaction_mult = 1.6
			difficulty_recovery_mult = 0.7
		1:
			difficulty_spread_mult = 1.0
			difficulty_reaction_mult = 1.0
			difficulty_recovery_mult = 1.0
		2:
			difficulty_spread_mult = 0.65
			difficulty_reaction_mult = 0.65
			difficulty_recovery_mult = 1.5

	if bot_weapon_index < 0:
		var roll := randf()
		if roll < 0.32:
			bot_weapon_index = 0 # AK-47
			bot_role = "ASSAULT"
		elif roll < 0.50:
			bot_weapon_index = 1 # MP-40
			bot_role = "ASSAULT"
		elif roll < 0.66:
			bot_weapon_index = 5 # PPSh-41
			bot_role = "GUNNER"
		elif roll < 0.78:
			bot_weapon_index = 4 # Shotgun
			bot_role = "ASSAULT"
		elif roll < 0.88:
			bot_weapon_index = 2 # Mosin
			bot_role = "SNIPER"
		elif roll < 0.94:
			bot_weapon_index = 6 # Kar98k
			bot_role = "SNIPER"
		else:
			bot_weapon_index = 7 # Panzerfaust
			bot_role = "ANTI_ARMOR"

		if (bot_weapon_index == 1 or bot_weapon_index == 4) and randf() < 0.35:
			bot_role = "MEDIC"

	var t_collide0 := Time.get_ticks_usec()
	_build_body_collision()
	var t_visual0 := Time.get_ticks_usec()
	_build_visuals()
	var t_weapon0 := Time.get_ticks_usec()
	_build_weapon()
	var t_rest0 := Time.get_ticks_usec()
	_build_hitboxes()
	_rebuild_self_rids()
	_build_label()
	_build_audio()
	if profile_build:
		var t_end := Time.get_ticks_usec()
		print("BOT_BUILD collide=%.2f visual=%.2f weapon=%.2f rest=%.2f total=%.2f" % [
			float(t_visual0 - t_collide0) / 1000.0,
			float(t_weapon0 - t_visual0) / 1000.0,
			float(t_rest0 - t_weapon0) / 1000.0,
			float(t_end - t_rest0) / 1000.0,
			float(t_end - t_build) / 1000.0
		])

	_perception = PERCEPTION.new()
	_perception.setup(self, randf())
	_cache_map_data()
	_init_avoid_queries()
	_stuck_last_pos = global_position
	_route_repath_timer = randf_range(0.15, 0.9)
	fire_cooldown = randf_range(0.4, 1.2) * difficulty_reaction_mult

## Данные карты не меняются во время матча — считаем один раз.
func _cache_map_data() -> void:
	_cached_map_name = str(get_tree().get_meta("selected_map", "BATTLEFIELD"))
	if _cached_map_name == "VILLAGE":
		_sector_positions = PackedFloat32Array([-45.0, 0.0, 45.0])
		_enemy_base_z = 48.0
	elif _cached_map_name == "COUNTRYSIDE":
		var map_sectors: Array[Dictionary] = COUNTRYSIDE_LAYOUT.sectors()
		_sector_positions = PackedFloat32Array([
			map_sectors[0].pos.x,
			map_sectors[1].pos.x,
			map_sectors[2].pos.x
		])
		_enemy_base_z = 62.0
	else:
		_sector_positions = PackedFloat32Array([-52.0, 0.0, 52.0])
		_enemy_base_z = 56.0

func _init_avoid_queries() -> void:
	for query in [_avoid_front, _avoid_left, _avoid_right]:
		query.collision_mask = TUNING.WORLD_LAYER
		query.collide_with_areas = false
		query.collide_with_bodies = true
	_fire_query.collision_mask = TUNING.LOS_MASK
	_fire_query.collide_with_areas = true
	_fire_query.collide_with_bodies = true

func _build_body_collision() -> void:
	var body_collision := CollisionShape3D.new()
	body_collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	body_collision.shape = capsule
	body_collision.position.y = capsule.height * 0.5
	add_child(body_collision)

static var _visual_template_cache: Dictionary = {}

func _build_visuals() -> void:
	_pivot = Node3D.new()
	add_child(_pivot)

	var path := RED_SCENE if team_name.to_upper().contains("RED") else IRON_SCENE
	var is_red: bool = team_name.to_upper().contains("RED")
	var template: Node3D = _visual_template_cache.get(path)
	if template == null:
		template = _create_visual_template(path, is_red)
		if template == null:
			return
		# Храним нетронутый шаблон: у первого бота _ready() изменит позы костей.
		_visual_template_cache[path] = template.duplicate() as Node3D
	_visual = template.duplicate() as Node3D
	_pivot.add_child(_visual)
	if _visual.has_method("set_motion"):
		_proc = _visual as FRONTLINEProceduralSoldier
	# QA-optimization: мелкие детали модели скрываем на дистанции — меньше draw calls.
	if GameSettings.quality == 0 and _proc != null:
		_proc.set_t_pose_arms(false)
		_proc.set_aiming(true)
		_proc.set_motion(0.0, false)

## Собирает модель один раз на фракцию. Повторные боты — дешёвый duplicate()
## вместо загрузки GLB, снаряжения, рига и слияния меша.
func _create_visual_template(path: String, is_red: bool) -> Node3D:
	var visual := Node3D.new()
	visual.rotation.y = PI
	var packed = load(path)
	if packed == null:
		push_error("FRONTLINE: cannot load soldier GLB " + path)
		return null
	var model = packed.instantiate()
	TACTICAL_GEAR.add_tactical_loadout(model, is_red, true)
	visual.add_child(model)
	var skeleton := BLOCK_RIG_BUILDER.rig_model(model)
	if skeleton is Skeleton3D:
		BLOCK_RIG_BUILDER.merge_rigged_model(skeleton)
		# Скрипт ставим до входа в дерево, чтобы его _ready() сразу увидел скелет.
		visual.set_script(PROCEDURAL)
	return visual

func _build_weapon() -> void:
	_gun_pivot = Node3D.new()
	_gun_pivot.name = "GunPivot"
	_gun_pivot.position = Vector3(0.16, 1.25, -0.22)
	_pivot.add_child(_gun_pivot)

	var weapon_ids := ["ak47", "mp40", "mosin", "m1911", "shotgun", "ppsh41", "kar98k", "panzerfaust"]
	var wid: String = weapon_ids[clampi(bot_weapon_index, 0, weapon_ids.size() - 1)]

	if wid == "ak47":
		var ak_mesh := WEAPON_MESHES.ak_mesh()
		if ak_mesh != null:
			_gun_mesh = MeshInstance3D.new()
			_gun_mesh.mesh = ak_mesh
			_gun_mesh.scale = Vector3.ONE * 0.95
			_gun_mesh.rotation.y = PI
			_gun_pivot.add_child(_gun_mesh)

			_muzzle_node = Node3D.new()
			_muzzle_node.position = WEAPON_MESHES.MUZZLE_LOCAL * 0.95
			_muzzle_node.position.z = -_muzzle_node.position.z
			_gun_pivot.add_child(_muzzle_node)
	else:
		var model: Node3D = WEAPON_MESHES.make_weapon(wid)
		if model != null:
			model.scale = Vector3.ONE * 0.95
			_gun_pivot.add_child(model)
			_muzzle_node = model.get_node_or_null("Muzzle") as Node3D
			var meshes := model.find_children("*", "MeshInstance3D", true, false)
			if not meshes.is_empty():
				_gun_mesh = meshes[0] as MeshInstance3D

	if _muzzle_node == null:
		_muzzle_node = Node3D.new()
		_muzzle_node.position = Vector3(0.0, 0.05, -0.6)
		_gun_pivot.add_child(_muzzle_node)

	_muzzle_flash = MeshInstance3D.new()
	var flash_sphere := SphereMesh.new()
	flash_sphere.radius = 0.06
	flash_sphere.height = 0.12
	_muzzle_flash.mesh = flash_sphere
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.78, 0.25)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.6, 0.1)
	flash_mat.emission_energy_multiplier = 4.5
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_muzzle_flash.material_override = flash_mat
	_muzzle_flash.visible = false
	_muzzle_node.add_child(_muzzle_flash)

func _build_hitboxes() -> void:
	var shape_head := BoxShape3D.new()
	shape_head.size = Vector3(0.38, 0.38, 0.38)
	_add_hitbox("head", Vector3(0, 1.76, 0), shape_head)

	var shape_torso := BoxShape3D.new()
	shape_torso.size = Vector3(0.55, 0.70, 0.36)
	_add_hitbox("chest", Vector3(0, 1.20, 0), shape_torso)

	var shape_legs := BoxShape3D.new()
	shape_legs.size = Vector3(0.52, 0.85, 0.38)
	_add_hitbox("leg", Vector3(0, 0.42, 0), shape_legs)

func _add_hitbox(region: String, local_pos: Vector3, shape: Shape3D) -> void:
	var area := Area3D.new()
	area.collision_layer = HITBOX_LAYER_MASK
	area.collision_mask = 0
	area.set_meta("owner_actor", self)
	area.set_meta("region", region)
	area.add_to_group("damageable")
	var cs := CollisionShape3D.new()
	cs.shape = shape
	area.add_child(cs)
	area.position = local_pos
	_pivot.add_child(area)
	_hitboxes.append(area)

func _role_title() -> String:
	var is_red := team_name.contains("RED")
	match bot_role:
		"MEDIC":
			return "САНИТАР" if is_red else "SANITÄTER"
		"GUNNER":
			return "ПУЛЕМЁТ" if is_red else "MG"
		"SNIPER":
			return "СНАЙПЕР" if is_red else "SCHARF"
		"ANTI_ARMOR":
			return "ПТ" if is_red else "PANZER"
		_:
			return "ШТУРМ" if is_red else "STURM"

func _build_label() -> void:
	_label = Label3D.new()
	_label.text = "%s [%s]" % [soldier_name, _role_title()]
	_label.position = Vector3(0, 2.15, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 18
	_label.modulate = Color(0.85, 0.35, 0.35) if team_name.contains("RED") else Color(0.65, 0.75, 0.85)
	add_child(_label)

func _build_audio() -> void:
	_sfx_shot = AudioStreamPlayer3D.new()
	var weapon_ids := ["ak47", "mp40", "mosin", "m1911", "shotgun", "ppsh41", "kar98k", "panzerfaust"]
	_sfx_shot.stream = WEAPON_SOUND.get_shot(weapon_ids[clampi(bot_weapon_index, 0, weapon_ids.size() - 1)])
	_sfx_shot.unit_size = 16.0
	_sfx_shot.max_distance = 220.0
	_sfx_shot.max_polyphony = 1
	_sfx_shot.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	_sfx_shot.bus = COMBAT_AUDIO.BUS_COMBAT_DIRECT
	add_child(_sfx_shot)

	_sfx_reload = AudioStreamPlayer3D.new()
	_sfx_reload.stream = SFX_RELOAD_IN
	_sfx_reload.unit_size = 8.0
	_sfx_reload.max_distance = 45.0
	_sfx_reload.bus = COMBAT_AUDIO.BUS_SFX
	add_child(_sfx_reload)

func _physics_process(delta: float) -> void:
	if is_dead:
		_apply_gravity(delta)
		move_and_slide()
		return

	_apply_gravity(delta)
	_handle_effects(delta)
	_audio_env_timer -= delta
	if _perception != null:
		_perception.tick(delta, _get_self_collision_rids())
	_update_ai(delta)
	_resolve_movement(delta)
	_intended_speed = Vector2(velocity.x, velocity.z).length()
	move_and_slide()
	_update_stuck_watch(delta)
	_update_animation(delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

## Единая точка применения движения: поведение задаёт намерение,
## здесь оно один раз обходит препятствия, расталкивается и выбирается
## из застревания. Никаких повторных рейкастов из каждого поведения.
func _resolve_movement(delta: float) -> void:
	var intent := Vector3(velocity.x, 0.0, velocity.z)
	if intent.length_squared() > 0.0001:
		var avoided := _avoid_obstacles(intent.normalized())
		var speed := intent.length()
		velocity.x = avoided.x * speed
		velocity.z = avoided.z * speed
	_apply_separation(delta)
	if _unstick_timer > 0.0:
		_unstick_timer -= delta
		if _unstick_dir.length_squared() > 0.01:
			velocity.x = _unstick_dir.x * SPEED_WALK
			velocity.z = _unstick_dir.z * SPEED_WALK
		if _unstick_jump and is_on_floor():
			velocity.y = 4.6
			_unstick_jump = false

func _update_animation(delta: float) -> void:
	var horiz_vel := Vector2(velocity.x, velocity.z).length()
	if _proc != null:
		_proc.set_motion(horiz_vel, horiz_vel > SPEED_WALK + 0.5)
		_proc.set_crouching(stance >= 1)
		if _proc.has_method("set_prone"):
			_proc.call("set_prone", stance == 2)
		_proc.set_reloading(is_reloading)
	if _gun_pivot != null:
		var reload_tilt := -0.32 if is_reloading else 0.0
		_gun_pivot.rotation.z = lerpf(_gun_pivot.rotation.z, reload_tilt, clampf(delta * 8.0, 0.0, 1.0))
	if _label == null:
		return
	_label_update_timer -= delta
	if _label_update_timer > 0.0:
		return
	_label_update_timer = 0.25
	if _cached_cam == null or not is_instance_valid(_cached_cam):
		var vp := get_viewport()
		_cached_cam = vp.get_camera_3d() if vp != null else null
	var label_dist := 999.0
	if _cached_cam != null and is_instance_valid(_cached_cam):
		label_dist = global_position.distance_to(_cached_cam.global_position)
	_label.visible = GameSettings.quality > 0 and label_dist < 36.0

## Мягкое расталкивание союзников: боты не сбиваются в кучу в углах и проходах.
func _apply_separation(delta: float) -> void:
	_sep_timer += delta
	if _sep_timer < 0.10:
		return
	var step := _sep_timer
	_sep_timer = 0.0
	var push := Vector3.ZERO
	for b in get_tree().get_nodes_in_group("bots"):
		if b == self or not is_instance_valid(b):
			continue
		var other := b as Node3D
		if other == null:
			continue
		var d := global_position - other.global_position
		d.y = 0.0
		var dist_sq := d.length_squared()
		if dist_sq > 0.0025 and dist_sq < 5.29:
			var dist := sqrt(dist_sq)
			push += (d / dist) * ((2.3 - dist) / 2.3)
	if push.length_squared() > 0.001:
		push = push.limit_length(1.0)
		velocity.x += push.x * 18.0 * step
		velocity.z += push.z * 18.0 * step

## Если бот хочет идти, но за 0.8 с сместился меньше 18 см — короткий
## боковой шаг с подскоком и сброс пути. Проверка идёт после move_and_slide,
## а само исправление применяется в _resolve_movement до следующего шага.
func _update_stuck_watch(delta: float) -> void:
	if _unstick_timer > 0.0:
		return
	_stuck_check_timer -= delta
	if _stuck_check_timer > 0.0:
		return
	_stuck_check_timer = 0.8
	var moved := global_position.distance_to(_stuck_last_pos)
	_stuck_last_pos = global_position
	if _intended_speed <= SPEED_CROUCH * 0.8 or moved >= 0.18:
		return
	var heading := Vector3(velocity.x, 0.0, velocity.z)
	if heading.length_squared() < 0.01:
		heading = -global_transform.basis.z
	heading = heading.normalized()
	var side := Vector3(-heading.z, 0.0, heading.x) * (1.0 if randf() < 0.5 else -1.0)
	_unstick_dir = (side + heading * 0.35).normalized()
	_unstick_timer = 0.55
	_unstick_jump = true
	_route_repath_timer = 0.0
	_route_has_attempted = false

func _update_ai(delta: float) -> void:
	# Подавление постепенно рассеивается с учетом сложности
	if suppression > 0.0:
		suppression = maxf(0.0, suppression - delta * 0.35 * difficulty_recovery_mult)

	# QA-fix TASK-0022: услышав жужжание дрона, бойцы разбегаются или стреляют по нему.
	_drone_timer -= delta
	if _drone_timer <= 0.0:
		_drone_timer = 0.5 + float(get_instance_id() % 5) * 0.02
		_nearest_drone_cached = _nearest_enemy_drone()
	var nearest_drone := _nearest_drone_cached
	if nearest_drone != null and not is_instance_valid(nearest_drone):
		nearest_drone = null
	if nearest_drone != null:
		var drone_range := global_position.distance_to(nearest_drone.global_position)
		if drone_range < 16.0 and current_target != nearest_drone:
			var away := global_position - nearest_drone.global_position
			away.y = 0.0
			if away.length_squared() > 0.01:
				away = away.normalized()
				if randf() < 0.6:
					_shout("ДРОН!" if team_name.contains("RED") else "DRONE!", Color(1.0, 0.3, 0.25))
				var flee_dir := _avoid_obstacles(away)
				velocity.x = flee_dir.x * SPEED_SPRINT
				velocity.z = flee_dir.z * SPEED_SPRINT
				stance = 0
				if is_on_floor() and randf() < 0.02:
					velocity.y = 4.2
				_route_repath_timer = 0.0
				_route_has_attempted = false
				return

	# Поведение санитара (Medic)
	if bot_role == "MEDIC" and not is_reloading:
		_medic_timer -= delta
		if _medic_timer <= 0.0:
			_medic_timer = randf_range(3.5, 6.0)
			_try_heal_nearby_ally()

	# Перезарядка: оружие молчит, но боец продолжает видеть, слышать и двигаться.
	if is_reloading:
		ai_state = State.RELOAD
		reload_timer -= delta
		stance = 1
		if reload_timer <= 0.0:
			ammo = MAG_SIZE
			is_reloading = false
		_reload_movement(delta)
		return

	var target := current_target
	if target != null and (not is_instance_valid(target) or _actor_is_dead(target)):
		current_target = null
		target = null

	if target != null and target.get_instance_id() != _last_target_id:
		_last_target_id = target.get_instance_id()
		target_acquisition_timer = randf_range(0.38, 0.65) * difficulty_reaction_mult
		if randf() < 0.40:
			_shout("ВИЖУ ВРАГА!" if team_name.contains("RED") else "KONTAKT!", Color(1.0, 0.85, 0.3))
	elif target == null:
		_last_target_id = 0

	# В бою остаёмся, пока цель видна или контакт свежий; иначе идём проверять
	# последнюю известную точку, а не мгновенно забываем врага.
	if target != null and (_perception.target_visible or _perception.last_seen_age <= 1.2):
		ai_state = State.COMBAT
		_combat_behavior(delta)
		return
	if _perception.has_alert():
		ai_state = State.INVESTIGATE
		_investigate_behavior(delta)
		return

	ai_state = State.ADVANCE
	_advance_behavior(delta)

func _actor_is_dead(actor: Node3D) -> bool:
	return bool(actor.get("is_dead")) if "is_dead" in actor else false

## Под огнём боец отходит, даже пока перезаряжается, вместо того чтобы
## стоять столбом спиной к стрелку.
func _reload_movement(delta: float) -> void:
	var threat := _perception.last_known_position
	if _perception.target_visible and current_target != null:
		threat = current_target.global_position
	var move := Vector3.ZERO
	if not threat.is_zero_approx() and global_position.distance_to(threat) < 32.0:
		move = global_position - threat
		move.y = 0.0
		if move.length_squared() > 0.01:
			move = move.normalized()
	velocity.x = lerpf(velocity.x, move.x * SPEED_CROUCH, delta * 4.0)
	velocity.z = lerpf(velocity.z, move.z * SPEED_CROUCH, delta * 4.0)

## Проверка последнего контакта: подойти, осмотреться, затем вернуться к наступлению.
func _investigate_behavior(delta: float) -> void:
	var point := _perception.alert_position
	var to := point - global_position
	to.y = 0.0
	if to.length() < 2.0 or _perception.alert_age > TUNING.ALERT_MEMORY - 0.5:
		_perception.clear_alert()
		_advance_behavior(delta)
		return
	var direction := _route_direction(point, delta)
	if direction.length_squared() < 0.01:
		_perception.clear_alert()
		_advance_behavior(delta)
		return
	velocity.x = direction.x * SPEED_WALK
	velocity.z = direction.z * SPEED_WALK
	stance = 0
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 5.0, 0.0, 1.0))
	if _gun_pivot != null:
		_gun_pivot.rotation.x = 0.0
	if _proc != null:
		_scan_time += delta
		_proc.set_look(sin(_scan_time * 1.6) * 0.35, 0.0)

## Ищет точку рядом, из-за которой цель не видит бота (стена/мешки/техника).
## Кандидат обязан стоять на земле и реально перекрывать линию от глаз цели.
func _find_cover_point() -> Vector3:
	if current_target == null or not is_instance_valid(current_target):
		return Vector3.ZERO
	var space := get_world_3d().direct_space_state
	var best := Vector3.ZERO
	var best_score := -1.0
	var target_eye := current_target.global_position + Vector3.UP * TUNING.aim_height(current_target)
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + randf_range(-0.25, 0.25)
		var candidate := global_position + Vector3(cos(angle), 0.0, sin(angle)) * randf_range(2.2, 4.0)

		var ground_q := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 1.5, candidate - Vector3.UP * 1.5)
		ground_q.collision_mask = TUNING.WORLD_LAYER
		ground_q.exclude = _self_rids
		ground_q.collide_with_areas = false
		var ground := space.intersect_ray(ground_q)
		if ground.is_empty():
			continue
		candidate.y = ground.position.y

		var sight_q := PhysicsRayQueryParameters3D.create(target_eye, candidate + Vector3.UP * 1.0)
		sight_q.collision_mask = TUNING.WORLD_LAYER
		sight_q.exclude = _self_rids
		sight_q.collide_with_areas = false
		var sight_hit := space.intersect_ray(sight_q)
		if sight_hit.is_empty() or sight_hit.get("collider") == current_target:
			continue
		if sight_hit.position.distance_to(target_eye) > target_eye.distance_to(candidate) - 0.4:
			continue

		var score := 1.0 - candidate.distance_to(global_position) * 0.04 + randf() * 0.2
		if score > best_score:
			best_score = score
			best = candidate
	return best

func _nearest_enemy_drone() -> Node3D:
	var nearest: Node3D = null
	var best := 999.0
	for d in get_tree().get_nodes_in_group("radio_drones"):
		var drone := d as Node3D
		if drone == null or not is_instance_valid(drone):
			continue
		if str(drone.get("operator_team")) == team_name:
			continue
		if bool(drone.get("is_exploding")):
			continue
		var dist := global_position.distance_to(drone.global_position)
		if dist < best:
			best = dist
			nearest = drone
	return nearest

func _try_heal_nearby_ally() -> void:
	var bots := get_tree().get_nodes_in_group("bots")
	for b in bots:
		if b == self or not is_instance_valid(b):
			continue
		var other := b as CharacterBody3D
		if other != null and "team_name" in other and str(other.get("team_name")) == team_name:
			var other_health: float = float(other.get("health"))
			var other_dead: bool = bool(other.get("is_dead"))
			if not other_dead and other_health < 75.0 and global_position.distance_to(other.global_position) <= 6.5:
				other.set("health", minf(MAX_HEALTH, other_health + 25.0))
				_shout("ПЕРЕВЯЗКА!" if team_name.contains("RED") else "VERBAND!", Color(0.35, 0.92, 0.45))
				break

func _get_self_collision_rids() -> Array[RID]:
	# QA-optimization: массив RID собирается один раз, а не на каждый рейкаст.
	if _self_rids.is_empty():
		_rebuild_self_rids()
	return _self_rids

func _rebuild_self_rids() -> void:
	_self_rids.clear()
	_self_rids.append(get_rid())
	for hitbox in _hitboxes:
		if is_instance_valid(hitbox):
			_self_rids.append(hitbox.get_rid())

## Публичный кэш для пуль (bullet_projectile больше не обходит дерево бота).
func get_projectile_rids() -> Array[RID]:
	return _get_self_collision_rids()

## Тактическое поведение в бою (Dummy War Tactical Firefight)
func _combat_behavior(delta: float) -> void:
	var tpos := current_target.global_position
	var to := tpos - global_position
	var dist := to.length()

	# Видимость считает модуль восприятия. Если цель пропала — идём к
	# последней известной точке, а не стреляем в стену и не стоим.
	var can_see := _perception.target_visible
	if not can_see:
		fire_cooldown = maxf(fire_cooldown, 0.30)
		var last_seen := _perception.last_known_position
		if not last_seen.is_zero_approx() and global_position.distance_to(last_seen) > 1.5:
			var seek_dir := _route_direction(last_seen, delta)
			velocity.x = seek_dir.x * SPEED_WALK
			velocity.z = seek_dir.z * SPEED_WALK

	# Плавный поворот к противнику
	var target_yaw := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 8.0, 0.0, 1.0))

	# Наклон оружия и головы к реальной точке прицеливания.
	if _gun_pivot != null:
		var aim_y := TUNING.aim_height(current_target)
		var pitch := atan2(to.y + aim_y - _gun_pivot.global_position.y, Vector2(to.x, to.z).length())
		_gun_pivot.rotation.x = pitch
		if _proc != null:
			_proc.set_look(0.0, pitch)

	# Задержка наведения (Aim Acquisition): бот не стреляет мгновенно при первом обнаружении
	if target_acquisition_timer > 0.0:
		target_acquisition_timer -= delta
		velocity.x = lerpf(velocity.x, 0.0, delta * 6.0)
		velocity.z = lerpf(velocity.z, 0.0, delta * 6.0)
		return

	# Дистанция боя зависит от оружия: снайпер держится позади, ППШ лезет в ближний бой.
	var preferred_max := minf(TUNING.engage_range(bot_weapon_index) * 0.7, 42.0)

	# Тактическое маневрирование в перестрелке: стрейф, укрытия, выглядывание (peeking)
	combat_strafe_timer -= delta
	if combat_strafe_timer <= 0.0:
		combat_strafe_timer = randf_range(1.2, 2.5)
		# QA-fix TASK-0022: бойцы почти всегда в движении — короткие паузы,
		# а не «стоим по 2.5 секунды и ничего не делаем».
		var maneuver := randf()
		if maneuver < 0.45:
			var right := global_transform.basis.x
			right.y = 0.0
			combat_strafe_dir = right.normalized()
			stance = 0 if randf() > 0.45 else 1
		elif maneuver < 0.90:
			var left := -global_transform.basis.x
			left.y = 0.0
			combat_strafe_dir = left.normalized()
			stance = 0 if randf() > 0.45 else 1
		else:
			# Короткая остановка «отстреляться из укрытия».
			combat_strafe_dir = Vector3.ZERO
			stance = 1
			combat_strafe_timer = randf_range(0.35, 0.7)

	if dist > preferred_max:
		# Сближение по навигационному маршруту.
		var move_dir := _route_direction(tpos, delta)
		velocity.x = move_dir.x * SPEED_WALK
		velocity.z = move_dir.z * SPEED_WALK
		stance = 0
	elif dist < 8.5 or health < 45.0 or ((bot_weapon_index == 2 or bot_weapon_index == 6) and dist < 16.0):
		# Отход назад при сильном сближении, ранении или если снайперу навязали ближний бой
		var back_dir := -to.normalized()
		var speed_k := 0.75 if health >= 45.0 else 0.90
		velocity.x = back_dir.x * SPEED_WALK * speed_k
		velocity.z = back_dir.z * SPEED_WALK * speed_k
		stance = 1 if health < 45.0 else 0
	else:
		# Огневой контакт: активный стрейф и огонь из укрытия
		if suppression > 0.55 and randf() < 0.45:
			stance = 2 # под плотным огнём залегает
		elif suppression > 0.30 or dist > 18.0:
			stance = 1 # приседает для стрельбы из укрытия
		elif dist < 12.0:
			stance = 0 # в упор встаёт и стрейфит
		if combat_strafe_dir != Vector3.ZERO:
			var sdir := combat_strafe_dir
			var strafe_speed := SPEED_WALK * (0.9 if stance == 0 else 0.55)
			velocity.x = lerpf(velocity.x, sdir.x * strafe_speed, delta * 6.0)
			velocity.z = lerpf(velocity.z, sdir.z * strafe_speed, delta * 6.0)
		else:
			velocity.x = lerpf(velocity.x, 0.0, delta * 5.0)
			velocity.z = lerpf(velocity.z, 0.0, delta * 5.0)
		# Даже в паузе бот не «замирает»: лёгкий дрейф в сторону.
		if Vector2(velocity.x, velocity.z).length() < 0.6:
			var tangent := Vector3(-to.normalized().z, 0.0, to.normalized().x) * (1.0 if randf() < 0.5 else -1.0)
			velocity.x += tangent.x * delta * 6.0
			velocity.z += tangent.z * delta * 6.0

	# Под огнём/ранении ищет укрытие и смещается к нему, а не стоит в открытую.
	if (health < 70.0 or suppression > 0.40) and dist > 12.0:
		_cover_timer -= delta
		if _cover_timer <= 0.0:
			_cover_timer = randf_range(1.8, 3.2)
			_cover_target = _find_cover_point()
		if _cover_target != Vector3.ZERO:
			var to_cover := _cover_target - global_position
			to_cover.y = 0.0
			if to_cover.length() > 0.8:
				var cover_dir := to_cover.normalized()
				velocity.x = lerpf(velocity.x, cover_dir.x * SPEED_WALK * 1.15, clampf(delta * 7.0, 0.0, 1.0))
				velocity.z = lerpf(velocity.z, cover_dir.z * SPEED_WALK * 1.15, clampf(delta * 7.0, 0.0, 1.0))
				stance = 1

	# Бросок гранаты при подходящей дистанции
	if can_see and dist >= 14.0 and dist <= 32.0 and grenades > 0:
		grenade_cooldown -= delta
		if grenade_cooldown <= 0.0:
			_throw_bot_grenade(tpos)

	# Стрельба очередями — только по видимой цели в пределах дальности оружия.
	fire_cooldown -= delta
	if fire_cooldown <= 0.0 and can_see and dist <= TUNING.engage_range(bot_weapon_index):
		_shoot_burst()

func _throw_bot_grenade(target_pt: Vector3) -> void:
	grenades -= 1
	grenade_cooldown = randf_range(25.0, 45.0)
	_shout("ГРАНАТА!" if team_name.contains("RED") else "GRANATE!", Color(1.0, 0.55, 0.1))
	var g := GRENADE_SCRIPT.new()
	var from := global_position + Vector3(0, 1.4, 0)
	var to_vec := target_pt - from
	var horiz_dist := Vector2(to_vec.x, to_vec.z).length()
	var dir := to_vec.normalized() + Vector3.UP * 0.35
	g.position = from + dir * 0.6
	g.linear_velocity = dir.normalized() * clampf(horiz_dist * 0.85 + 5.0, 11.0, 22.0)
	g.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
	g.thrower_name = soldier_name
	g.team_name = team_name
	get_parent().add_child(g)

## Наступление и тактический захват секторов A, B, C с продвижением к базе врага
func _advance_behavior(delta: float) -> void:
	stance = 0
	# Направление к рубежу противника (Красные идут в +Z, Легион в -Z).
	var forward_z: float = 1.0 if team_name.contains("RED") else -1.0

	# Распределение ботов по тактическим направлениям (данные карты кэшированы).
	var squad := int(get_instance_id() % 3)
	var sector_x: float = _sector_positions[squad]

	var offset_x := float(int(get_instance_id() % 5) - 2) * 2.5 + _personal_offset_x
	var target_sector := Vector3(sector_x + offset_x, 0.0, 0.0)

	# Если бот уже вышел к линии секторов (Z около 0), развиваем наступление вглубь вражеских рубежей
	var current_z := global_position.z
	var objective: Vector3
	if (forward_z > 0.0 and current_z > 8.0) or (forward_z < 0.0 and current_z < -8.0):
		# Продвижение на вражескую половину карты
		objective = Vector3(sector_x + offset_x, 0.0, forward_z * _enemy_base_z)
	else:
		# Штурм ключевого сектора
		objective = target_sector

	# На рубеже бот не замирает навсегда: выбирает микропатруль вокруг точки.
	if global_position.distance_to(objective) < 5.0:
		_idle_patrol_timer -= delta
		if _idle_patrol_timer <= 0.0:
			_idle_patrol_timer = randf_range(4.0, 8.0)
			_patrol_point = objective + Vector3(randf_range(-7.0, 7.0), 0.0, randf_range(-7.0, 7.0))
		objective = _patrol_point

	var forward_dir := _route_direction(objective, delta)

	# Перебежки «от укрытия к укрытию»: короткий спринт, затем пауза-сканирование
	# в приседе. Так отделение не идёт гуськом и не стоит толпой.
	_bound_timer -= delta
	if _bound_timer <= 0.0:
		_bound_crouch = not _bound_crouch
		_bound_timer = randf_range(0.35, 0.7) if _bound_crouch else randf_range(1.4, 2.8)
		_scan_time = 0.0
	if _bound_crouch:
		stance = 1
		velocity.x = lerpf(velocity.x, 0.0, clampf(delta * 5.0, 0.0, 1.0))
		velocity.z = lerpf(velocity.z, 0.0, clampf(delta * 5.0, 0.0, 1.0))
		_scan_time += delta
		rotation.y += sin(_scan_time * 2.2) * 1.1 * delta
	else:
		stance = 0
		velocity.x = forward_dir.x * SPEED_SPRINT
		velocity.z = forward_dir.z * SPEED_SPRINT

	if not _bound_crouch and forward_dir.length_squared() > 0.001:
		var target_yaw := atan2(-forward_dir.x, -forward_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 4.0, 0.0, 1.0))
	if _gun_pivot != null:
		_gun_pivot.rotation.x = 0.0
	if _proc != null:
		_proc.set_look(0.0, 0.0)

## Процедурный обход препятствий (стен, заборов, мешков).
## Вызывается ровно один раз за кадр из _resolve_movement.
func _avoid_obstacles(desired_dir: Vector3) -> Vector3:
	_avoid_timer -= get_physics_process_delta_time()
	if _avoid_timer > 0.0 and _avoid_in.dot(desired_dir) > 0.92:
		return _avoid_out
	_avoid_in = desired_dir
	_avoid_timer = 0.10 + float(get_instance_id() % 4) * 0.01
	_avoid_out = _avoid_obstacles_cast(desired_dir)
	return _avoid_out

func _avoid_obstacles_cast(desired_dir: Vector3) -> Vector3:
	if desired_dir.length_squared() < 0.01:
		return desired_dir
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0.0, 0.70, 0.0)
	var forward := desired_dir.normalized()
	var rids := _get_self_collision_rids()

	_avoid_front.from = from
	_avoid_front.to = from + forward * 1.8
	_avoid_front.exclude = rids
	var hit_front := space.intersect_ray(_avoid_front)
	if hit_front.is_empty():
		return desired_dir

	var r_probe := forward.rotated(Vector3.UP, deg_to_rad(50.0))
	var l_probe := forward.rotated(Vector3.UP, deg_to_rad(-50.0))

	_avoid_right.from = from
	_avoid_right.to = from + r_probe * 1.8
	_avoid_right.exclude = rids
	var hit_r := space.intersect_ray(_avoid_right)

	_avoid_left.from = from
	_avoid_left.to = from + l_probe * 1.8
	_avoid_left.exclude = rids
	var hit_l := space.intersect_ray(_avoid_left)

	if hit_r.is_empty():
		return r_probe
	if hit_l.is_empty():
		return l_probe
	var n: Vector3 = hit_front.get("normal", -forward)
	var tan_dir := Vector3(-n.z, 0.0, n.x)
	return tan_dir if tan_dir.dot(desired_dir) >= 0.0 else -tan_dir

func _route_direction(destination: Vector3, delta: float) -> Vector3:
	var direct := destination - global_position
	direct.y = 0.0
	if direct.length_squared() <= 0.04:
		return Vector3.ZERO
	if _navigation == null:
		return direct.normalized()

	_route_repath_timer = maxf(0.0, _route_repath_timer - delta)
	var destination_moved := _route_goal.distance_squared_to(destination) > 25.0
	if not _route_has_attempted or _route_repath_timer <= 0.0 or destination_moved:
		_route_path = _navigation.find_path(global_position, destination)
		_route_goal = destination
		_route_index = _closest_waypoint_index(_route_path)
		_route_repath_timer = 2.4 + float(get_instance_id() % 5) * 0.12
		_route_has_attempted = true
	if _route_path.is_empty():
		return direct.normalized()

	while _route_index < _route_path.size() - 1:
		var waypoint := _route_path[_route_index]
		waypoint.y = global_position.y
		if global_position.distance_to(waypoint) > 1.15:
			break
		_route_index += 1

	var next_point := _route_path[_route_index]
	var direction := next_point - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.04:
		return Vector3.ZERO
	return direction.normalized()

## После перестройки пути продолжаем с ближайшего сегмента, а не с нулевого.
func _closest_waypoint_index(path: PackedVector3Array) -> int:
	var best := 0
	var best_dist := INF
	var here := Vector2(global_position.x, global_position.z)
	for i in range(path.size()):
		var point := Vector2(path[i].x, path[i].z)
		var dist := here.distance_squared_to(point)
		if dist < best_dist:
			best_dist = dist
			best = i
	return best

## Ствол не должен стрелять в стену/союзника: проверяем линию от дула до цели.
func _muzzle_clear() -> bool:
	if current_target == null or _muzzle_node == null:
		return true
	var from := _muzzle_node.global_position
	var aim := _perception.fire_point()
	var distance := from.distance_to(aim)
	if distance < 0.1:
		return true
	_fire_query.from = from
	_fire_query.to = aim
	_fire_query.exclude = _get_self_collision_rids()
	var hit := get_world_3d().direct_space_state.intersect_ray(_fire_query)
	if hit.is_empty():
		return true
	var collider: Object = hit.get("collider")
	if collider == current_target:
		return true
	if collider is Area3D and collider.has_meta("owner_actor"):
		return collider.get_meta("owner_actor") == current_target
	return false

## Производит выстрел с учетом типа вооружения бота
func _shoot_burst() -> void:
	if ammo <= 0:
		_start_reload()
		return
	if not _muzzle_clear():
		fire_cooldown = 0.20
		return

	ammo -= 1
	_fire_single_shot()
	burst_count += 1

	match bot_weapon_index:
		2, 6:
			burst_count = 0
			fire_cooldown = randf_range(1.3, 2.1) * difficulty_reaction_mult
		4:
			burst_count = 0
			fire_cooldown = randf_range(0.85, 1.4) * difficulty_reaction_mult
		7:
			burst_count = 0
			fire_cooldown = randf_range(3.2, 4.8) * difficulty_reaction_mult
		3:
			if burst_count >= randi_range(1, 3):
				burst_count = 0
				fire_cooldown = randf_range(0.6, 1.2) * difficulty_reaction_mult
			else:
				fire_cooldown = 0.24
		5:
			var max_burst: int = randi_range(9, 15) if bot_role == "GUNNER" else randi_range(6, 10)
			if burst_count >= max_burst:
				burst_count = 0
				fire_cooldown = randf_range(0.65, 1.3) * difficulty_reaction_mult
			else:
				fire_cooldown = 0.065
		1:
			if burst_count >= randi_range(4, 7):
				burst_count = 0
				fire_cooldown = randf_range(0.7, 1.5) * difficulty_reaction_mult
			else:
				fire_cooldown = 0.08
		_:
			if burst_count >= randi_range(3, 5):
				burst_count = 0
				fire_cooldown = randf_range(0.8, 1.8) * difficulty_reaction_mult
			else:
				fire_cooldown = 0.10

func _fire_single_shot() -> void:
	soldier_fired.emit(global_position, team_name)
	var from := _muzzle_node.global_position if _muzzle_node != null else global_position + Vector3(0, 1.3, 0)

	const WID_NAMES := ["ak47", "mp40", "mosin", "m1911", "shotgun", "ppsh41", "kar98k", "panzerfaust"]
	var wid: String = WID_NAMES[clampi(bot_weapon_index, 0, WID_NAMES.size() - 1)]
	var prof: Dictionary = COMBAT_AUDIO.WEAPON_PROFILES.get(wid, {})

	if _sfx_shot != null:
		var listener_pos := COMBAT_AUDIO.get_listener_position(get_tree())
		var dist_sq := from.distance_squared_to(listener_pos)
		var max_dist := float(prof.get("max_dist", 220.0))
		if dist_sq <= max_dist * max_dist:
			_sfx_shot.unit_size = float(prof.get("unit_size", 16.0))
			_sfx_shot.max_distance = max_dist
			_sfx_shot.pitch_scale = randf_range(0.96, 1.04)
			_sfx_shot.volume_db = float(prof.get("vol", -2.0))
			# QA-optimization: акустика пересчитывается 4 раза/с, а не на каждый
			# выстрел — иначе 7 автоматчиков дают сотни рейкастов в секунду.
			if _audio_env_timer <= 0.0:
				_audio_env_timer = 0.25
				var world_3d := get_world_3d()
				_audio_indoors = COMBAT_AUDIO.is_indoors(world_3d, from)
				_audio_occluded = (not _audio_indoors) and COMBAT_AUDIO.check_occlusion(world_3d, from, listener_pos)
			if _audio_indoors:
				_sfx_shot.bus = COMBAT_AUDIO.BUS_INDOOR_REVERB
				_sfx_shot.attenuation_filter_cutoff_hz = 18000.0
				_sfx_shot.attenuation_filter_db = 0.0
			elif _audio_occluded:
				_sfx_shot.bus = COMBAT_AUDIO.BUS_COMBAT_OCCLUDED
				_sfx_shot.attenuation_filter_cutoff_hz = 1250.0
				_sfx_shot.attenuation_filter_db = -8.0
			else:
				_sfx_shot.bus = COMBAT_AUDIO.BUS_COMBAT_DIRECT
				_sfx_shot.attenuation_filter_cutoff_hz = 20500.0
				_sfx_shot.attenuation_filter_db = 0.0
			_sfx_shot.play()

	if _muzzle_flash != null:
		_muzzle_flash.visible = true
		_flash_time = 0.045

	if _proc != null:
		_proc.set_firing(true)

	var target_pt := _perception.fire_point() if current_target != null else from - global_transform.basis.z * 40.0
	# Реалистичный разброс человека (вместо лазерного 0.02)
	var base_spread: float = 0.045 if bot_role == "SNIPER" else 0.068
	base_spread += minf(float(burst_count) * 0.009, 0.048)
	base_spread += suppression * 0.062
	if Vector2(velocity.x, velocity.z).length() > 0.4:
		base_spread += 0.028
	if stance == 1:
		base_spread *= 0.78
	var spread: float = base_spread * difficulty_spread_mult
	var shoot_dir := (target_pt - from).normalized()
	shoot_dir = shoot_dir.rotated(Vector3.UP, randf_range(-spread, spread))
	shoot_dir = shoot_dir.rotated(global_transform.basis.x, randf_range(-spread, spread))

	if bot_weapon_index == 7:
		var rocket_scene = preload("res://scripts/rocket_projectile.gd")
		var rocket = rocket_scene.new()
		get_parent().add_child(rocket)
		rocket.launch(from, shoot_dir, soldier_name, team_name)
		return

	# Выброс гильзы вправо
	var casing_pos := global_position + Vector3(0, 1.3, 0)
	var eject_dir := global_transform.basis.x * 2.2 + Vector3.UP * 1.5 - global_transform.basis.z * 0.4
	HIT_EFFECTS.spawn_casing(get_parent(), casing_pos, eject_dir)

	var bullet_range := 150.0
	var to := from + shoot_dir * bullet_range
	if _cached_player == null or not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player") as Node3D
	var player_node := _cached_player
	if player_node != null and is_instance_valid(player_node) and "camera" in player_node and player_node.camera != null:
		FRONTLINEAmbience.check_bullet_flyby(from, to, player_node.camera.global_position)

	var bullet_speeds := [715.0, 380.0, 865.0, 253.0, 400.0, 488.0, 760.0, 48.0]
	var bullet_speed: float = bullet_speeds[clampi(bot_weapon_index, 0, bullet_speeds.size() - 1)]
	var damage_to_target := 20
	var damage_to_player := 16
	match bot_weapon_index:
		2, 6:
			damage_to_target = 46
			damage_to_player = 40
			damage_to_player = 48
		4:
			damage_to_target = 35
			damage_to_player = 32
		5:
			damage_to_target = 18
			damage_to_player = 16
		1:
			damage_to_target = 20
			damage_to_player = 20
	var world := get_parent()
	if world != null and world.has_method("spawn_bullet_projectile"):
		world.call("spawn_bullet_projectile", from, shoot_dir, bullet_speed, damage_to_target, bullet_range, soldier_name, team_name, self, damage_to_player)
	elif world != null:
		var bullet = BULLET_PROJECTILE_SCRIPT.new()
		world.add_child(bullet)
		bullet.configure(from, shoot_dir, bullet_speed, damage_to_target, bullet_range, soldier_name, team_name, self, damage_to_player)

func _start_reload() -> void:
	if is_reloading:
		return
	is_reloading = true
	reload_timer = 2.4
	stance = 1
	_shout("ПЕРЕЗАРЯДКА!" if team_name.contains("RED") else "LADE NACH!", Color(0.3, 0.8, 1.0))
	if _sfx_reload != null:
		_sfx_reload.play()

func _handle_effects(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time <= 0.0 and _muzzle_flash != null:
			_muzzle_flash.visible = false
			if _proc != null:
				_proc.set_firing(false)
	if _shout_timer > 0.0:
		_shout_timer -= delta
		if _shout_timer <= 0.0 and not is_dead and _label != null:
			_label.text = soldier_name
			_label.modulate = Color(0.85, 0.35, 0.35) if team_name.contains("RED") else Color(0.65, 0.75, 0.85)

func _shout(phrase: String, color: Color) -> void:
	if _label == null or is_dead:
		return
	_label.text = "[ " + phrase + " ]"
	_label.modulate = color
	_shout_timer = 1.8

## Публичный слух: координатор боя сообщает о выстрелах и взрывах.
func hear_gunshot(sound_pos: Vector3) -> void:
	if is_dead or _perception == null:
		return
	_perception.notify_gunshot(sound_pos)

## Получение урона
func receive_hit(damage: int, attacker_pos: Vector3, region: String = "chest", attacker_name: String = "Unknown") -> int:
	if is_dead:
		return 0
	health -= damage
	suppression = minf(1.0, suppression + 0.45)

	# Физический кинетический импульс пули (Dummy War / Bodycam)
	var hit_dir := (global_position - attacker_pos).normalized()
	hit_dir.y = 0.0
	velocity += hit_dir * clampf(float(damage) * 0.14, 1.4, 5.5)

	if _proc != null and health > 0.0:
		_proc.add_flinch(clampf(float(damage) * 0.035, 0.75, 2.0))
	if health > 0.0 and randf() < 0.45:
		_shout("РАНЕН!" if team_name.contains("RED") else "GETROFFEN!", Color(0.95, 0.25, 0.25))

	# Поворачиваемся в сторону стрелявшего при неожиданной атаке
	if _perception != null:
		_perception.notify_damage(attacker_pos)
	if current_target == null:
		var to := attacker_pos - global_position
		rotation.y = atan2(-to.x, -to.z)

	if health <= 0.0:
		_die(attacker_pos, region, attacker_name)
	return damage

## Гибель бойца: физический рэгдолл, падение оружия, лужа крови и сигнал
func _die(attacker_pos: Vector3, region: String, killer_name: String) -> void:
	is_dead = true
	ai_state = State.DEAD
	health = 0.0
	# Труп выходит из боевых групп сразу: иначе он остается в сканах цели,
	# расталкивания и миникарты до самого удаления.
	remove_from_group("bots")
	remove_from_group("damageable_actor")
	for group_bot in _hitboxes:
		if is_instance_valid(group_bot):
			group_bot.remove_from_group("damageable")
	var hit_dir := (global_position - attacker_pos).normalized()
	hit_dir.y = 0.0
	velocity = hit_dir * 3.2 + Vector3.UP * 1.0
	# Труп продолжает держаться на земле, но не блокирует живых бойцов невидимой капсулой.
	collision_layer = 0
	collision_mask = WORLD_LAYER_MASK

	# Отключаем хитбоксы попаданий
	for hb in _hitboxes:
		hb.collision_layer = 0

	# Выбрасываем оружие на землю
	if _gun_pivot != null and _gun_mesh != null:
		var drop_pos := _gun_pivot.global_position
		var drop_vel := Vector3(randf_range(-1.0, 1.0), 1.5, randf_range(-1.0, 1.0))
		var world := get_parent()
		var drop_idx := clampi(bot_weapon_index, 0, 7)
		var drop_clip_defs := [30, 32, 5, 8, 6, 71, 5, 1]
		var drop_res_defs := [60, 64, 20, 24, 18, 71, 20, 2]
		var d_clip: int = drop_clip_defs[drop_idx]
		var d_res: int = drop_res_defs[drop_idx]
		if world != null and world.has_method("spawn_weapon_pickup"):
			world.call("spawn_weapon_pickup", drop_pos, drop_idx, d_clip, d_res, drop_vel)
		elif world != null:
			var pickup = FIELD_PICKUP_SCRIPT.new()
			pickup.configure_weapon(drop_idx, d_clip, d_res)
			world.add_child(pickup)
			pickup.global_position = drop_pos
			pickup.launch(drop_vel)
		_gun_pivot.visible = false

	# Текст статуса
	if _label != null:
		_label.text = "КИА"
		_label.modulate = Color(0.9, 0.2, 0.2, 0.8)
		_label.visible = false

	# Запускаем физический рэгдолл скелета
	if _proc != null:
		_proc.set_ragdoll(true, hit_dir, region == "head")

	# Направленные брызги крови и лужа под телом
	HIT_EFFECTS.spawn_directional_blood(self, global_position + Vector3(0, 0.9, 0), hit_dir, region == "head", get_parent())

	# Сигнал для киллфида
	var w_names := ["AK-47", "MP-40", "MOSIN-NAGANT", "M1911", "PUMP SHOTGUN", "PPSH-41", "KAR98K", "PANZERFAUST"]
	var w_name: String = w_names[clampi(bot_weapon_index, 0, w_names.size() - 1)]
	soldier_killed.emit(self, killer_name, w_name)

	# Очистка трупа через 12 секунд: короче окно — меньше нагрузка на групповые сканы.
	get_tree().create_timer(12.0, false).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)
