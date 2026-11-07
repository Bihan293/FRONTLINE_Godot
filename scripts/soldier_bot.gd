extends CharacterBody3D
class_name FRONTLINESoldierBot

## Умный ИИ-солдат для масштабных сражений в стиле Dummy War.
## Имеет полную физику перемещения, поиск укрытий, командное зрение,
## стрельбу очередями, перезарядку, подавление и физический рэгдолл при гибели.

signal soldier_killed(victim: FRONTLINESoldierBot, killer_name: String, weapon_name: String)
signal soldier_fired(pos: Vector3)

const PROCEDURAL = preload("res://scripts/procedural_soldier.gd")
const BLOCK_RIG_BUILDER = preload("res://scripts/block_rig_builder.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const FIELD_PICKUP_SCRIPT = preload("res://scripts/field_pickup.gd")
const BULLET_PROJECTILE_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const GRENADE_SCRIPT = preload("res://scripts/grenade.gd")
const SMOKE_SCRIPT = preload("res://scripts/smoke_grenade.gd")
const AMBIENCE = preload("res://scripts/battlefield_ambience.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")

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

# ИИ-состояния: 0: ПАТРУЛЬ/НАСТУПЛЕНИЕ, 1: ПЕРЕБЕЖКА В УКРЫТИЕ, 2: ПЕРЕСТРЕЛКА
var ai_state := 0
var current_target: Node3D = null
var target_pos := Vector3.ZERO
var target_check_timer := 0.0
var burst_count := 0
var burst_timer := 0.0
var fire_cooldown := 0.0

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
var _route_goal := Vector3.ZERO
var _route_has_attempted := false
var _shout_timer := 0.0
var bot_role: String = "ASSAULT"
var match_difficulty: int = 1
var difficulty_spread_mult: float = 1.0
var difficulty_reaction_mult: float = 1.0
var difficulty_recovery_mult: float = 1.0
var _medic_timer: float = randf_range(3.0, 6.0)

func _ready() -> void:
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

	_build_body_collision()
	_build_visuals()
	_build_weapon()
	_build_hitboxes()
	_build_label()
	_build_audio()

	target_check_timer = randf_range(0.1, 0.4) * difficulty_reaction_mult
	fire_cooldown = randf_range(0.4, 1.2) * difficulty_reaction_mult

func _build_body_collision() -> void:
	var body_collision := CollisionShape3D.new()
	body_collision.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	body_collision.shape = capsule
	body_collision.position.y = capsule.height * 0.5
	add_child(body_collision)

func _build_visuals() -> void:
	_pivot = Node3D.new()
	add_child(_pivot)

	_visual = Node3D.new()
	_visual.rotation.y = PI
	_pivot.add_child(_visual)

	var path := RED_SCENE if team_name.to_upper().contains("RED") else IRON_SCENE
	var packed = load(path)
	if packed == null:
		push_error("FRONTLINE: cannot load soldier GLB " + path)
		return
	var model = packed.instantiate()
	_visual.add_child(model)

	var skeleton := BLOCK_RIG_BUILDER.rig_model(model)
	var has_rig := skeleton is Skeleton3D
	if has_rig:
		_visual.set_script(PROCEDURAL)
		_proc = _visual as FRONTLINEProceduralSoldier
		_proc.set_t_pose_arms(false)
		_proc.set_aiming(true)
		_proc.set_motion(0.0, false)

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
	_sfx_shot.stream = SFX_SHOT
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
		if not is_on_floor():
			velocity.y -= 18.0 * delta
			move_and_slide()
		return

	# Гравитация
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	_handle_effects(delta)
	_update_ai(delta)
	move_and_slide()

	# Обновление анимаций процедуры
	var horiz_vel := Vector2(velocity.x, velocity.z).length()
	if _proc != null:
		_proc.set_motion(horiz_vel, horiz_vel > SPEED_WALK + 0.5)
		_proc.set_crouching(stance == 1)
		_proc.set_reloading(is_reloading)
	if _gun_pivot != null:
		var reload_tilt := -0.32 if is_reloading else 0.0
		_gun_pivot.rotation.z = lerpf(_gun_pivot.rotation.z, reload_tilt, clampf(delta * 8.0, 0.0, 1.0))

func _update_ai(delta: float) -> void:
	# Подавление постепенно рассеивается с учетом сложности
	if suppression > 0.0:
		suppression = maxf(0.0, suppression - delta * 0.35 * difficulty_recovery_mult)

	# Поведение санитара (Medic)
	if bot_role == "MEDIC" and not is_reloading:
		_medic_timer -= delta
		if _medic_timer <= 0.0:
			_medic_timer = randf_range(3.5, 6.0)
			_try_heal_nearby_ally()

	# Таймер перезарядки
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			ammo = MAG_SIZE
			is_reloading = false
		velocity.x = lerpf(velocity.x, 0.0, delta * 6.0)
		velocity.z = lerpf(velocity.z, 0.0, delta * 6.0)
		return

	# Проверка целей с учетом реакции на выбранной сложности
	target_check_timer -= delta
	if target_check_timer <= 0.0:
		target_check_timer = randf_range(0.2, 0.45) * difficulty_reaction_mult
		_find_target()

	if current_target != null and is_instance_valid(current_target):
		var target_is_dead: bool = current_target.get("is_dead") if "is_dead" in current_target else false
		if target_is_dead:
			current_target = null
		else:
			_combat_behavior(delta)
			return

	_advance_behavior(delta)

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

## Поиск ближайшего видимого противника (игрок или бот противоположной команды)
func _find_target() -> void:
	var best_target: Node3D = null
	var best_dist := 75.0

	# 1. Проверяем игрока
	var player = get_tree().get_first_node_in_group("player") as Node3D
	if player != null and is_instance_valid(player):
		var player_team: String = str(get_tree().get_meta("selected_team", "IRON LEGION"))
		var player_dead: bool = player.get("is_dead") if "is_dead" in player else false
		if not player_dead and player_team != team_name:
			var dist := global_position.distance_to(player.global_position)
			if dist < best_dist and _has_line_of_sight(player, player.global_position + Vector3(0, 1.4, 0)):
				best_dist = dist
				best_target = player

	# 2. Проверяем ботов вражеской команды
	var bots = get_tree().get_nodes_in_group("bots")
	for b in bots:
		if b == self or not is_instance_valid(b):
			continue
		var bot = b as FRONTLINESoldierBot
		if bot != null and not bot.is_dead and bot.team_name != team_name:
			var dist := global_position.distance_to(bot.global_position)
			if dist < best_dist and _has_line_of_sight(bot, bot.global_position + Vector3(0, 1.4, 0)):
				best_dist = dist
				best_target = bot

	current_target = best_target

## Проверка прямой видимости (нет ли стен/земли или дымовой завесы между ботом и целью)
func _has_line_of_sight(target_actor: Node3D, target_pos_3d: Vector3) -> bool:
	var from := global_position + Vector3(0, 1.5, 0)
	if SMOKE_SCRIPT.is_line_blocked_by_smoke(from, target_pos_3d):
		return false
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, target_pos_3d)
	query.exclude = _get_self_collision_rids()
	query.collide_with_areas = true
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider = hit.collider
	if collider == target_actor:
		return true
	return collider is Area3D and collider.get_meta("owner_actor", null) == target_actor

func _get_self_collision_rids() -> Array[RID]:
	var rids: Array[RID] = [get_rid()]
	for hitbox in _hitboxes:
		if is_instance_valid(hitbox):
			rids.append(hitbox.get_rid())
	return rids

## Тактическое поведение в бою
func _combat_behavior(delta: float) -> void:
	var tpos := current_target.global_position
	var to := tpos - global_position
	var dist := to.length()

	# Плавный поворот к противнику
	var target_yaw := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 8.0, 0.0, 1.0))

	# Наклон оружия и головы
	if _gun_pivot != null:
		var pitch := atan2(to.y + 1.2 - _gun_pivot.global_position.y, Vector2(to.x, to.z).length())
		_gun_pivot.rotation.x = pitch
		if _proc != null:
			_proc.set_look(0.0, pitch)

	# Дистанционное маневрирование
	if dist > 32.0:
		# Сближение
		var move_dir := _route_direction(tpos, delta)
		velocity.x = move_dir.x * SPEED_WALK
		velocity.z = move_dir.z * SPEED_WALK
		stance = 0
	elif dist < 9.0:
		# Отход назад при сильном сближении
		var back_dir := -to.normalized()
		velocity.x = back_dir.x * SPEED_WALK * 0.7
		velocity.z = back_dir.z * SPEED_WALK * 0.7
		stance = 0
	else:
		# Остановка на выгодной дистанции, приседание за укрытие
		velocity.x = lerpf(velocity.x, 0.0, delta * 5.0)
		velocity.z = lerpf(velocity.z, 0.0, delta * 5.0)
		if suppression > 0.4:
			stance = 1
		else:
			stance = 0 if randf() > 0.3 else 1

	# Бросок гранаты при подходящей дистанции
	if dist >= 14.0 and dist <= 32.0 and grenades > 0:
		grenade_cooldown -= delta
		if grenade_cooldown <= 0.0:
			_throw_bot_grenade(tpos)

	# Стрельба очередями
	fire_cooldown -= delta
	if fire_cooldown <= 0.0:
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

	# Распределение ботов по тактическим направлениям:
	# 0: левый фланг к Сектору [A] (Церковь / Окопы)
	# 1: центр к Сектору [B] (Площадь / Руины)
	# 2: правый фланг к Сектору [C] (Мельница / Склад)
	var is_village: bool = str(get_tree().get_meta("selected_map", "BATTLEFIELD")) == "VILLAGE"
	var flank_dist: float = 45.0 if is_village else 52.0
	var enemy_base_z: float = 48.0 if is_village else 56.0

	var squad := int(get_instance_id() % 3)
	var sector_x := 0.0
	match squad:
		0: sector_x = -flank_dist
		1: sector_x = 0.0
		2: sector_x = flank_dist

	var offset_x := float(int(get_instance_id() % 5) - 2) * 2.5
	var target_sector := Vector3(sector_x + offset_x, 0.0, 0.0)

	# Если бот уже вышел к линии секторов (Z около 0), развиваем наступление вглубь вражеских рубежей
	var current_z := global_position.z
	var objective: Vector3
	if (forward_z > 0.0 and current_z > 8.0) or (forward_z < 0.0 and current_z < -8.0):
		# Продвижение на вражескую половину карты
		objective = Vector3(sector_x + offset_x, 0.0, forward_z * enemy_base_z)
	else:
		# Штурм ключевого сектора
		objective = target_sector

	var forward_dir := _route_direction(objective, delta)

	velocity.x = forward_dir.x * SPEED_SPRINT
	velocity.z = forward_dir.z * SPEED_SPRINT

	if forward_dir.length_squared() > 0.001:
		var target_yaw := atan2(-forward_dir.x, -forward_dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 4.0, 0.0, 1.0))
	if _gun_pivot != null:
		_gun_pivot.rotation.x = 0.0
	if _proc != null:
		_proc.set_look(0.0, 0.0)

func _route_direction(destination: Vector3, delta: float) -> Vector3:
	var direct := destination - global_position
	direct.y = 0.0
	if direct.length_squared() <= 0.04:
		return Vector3.ZERO
	if _navigation == null:
		return direct.normalized()

	_route_repath_timer = maxf(0.0, _route_repath_timer - delta)
	var destination_moved := _route_goal.distance_squared_to(destination) > 16.0
	if not _route_has_attempted or _route_repath_timer <= 0.0 or destination_moved:
		_route_path = _navigation.find_path(global_position, destination)
		_route_goal = destination
		_route_index = 0
		_route_repath_timer = 0.9
		_route_has_attempted = true
		if _route_path.is_empty():
			return direct.normalized()
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

## Производит выстрел с учетом типа вооружения бота
func _shoot_burst() -> void:
	if ammo <= 0:
		_start_reload()
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
	soldier_fired.emit(global_position)
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
			_sfx_shot.pitch_scale = float(prof.get("pitch", 1.0)) * randf_range(0.95, 1.05)
			_sfx_shot.volume_db = float(prof.get("vol", -2.0))
			var world_3d := get_world_3d()
			if COMBAT_AUDIO.is_indoors(world_3d, from):
				_sfx_shot.bus = COMBAT_AUDIO.BUS_INDOOR_REVERB
				_sfx_shot.attenuation_filter_cutoff_hz = 18000.0
				_sfx_shot.attenuation_filter_db = 0.0
			elif COMBAT_AUDIO.check_occlusion(world_3d, from, listener_pos):
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

	var target_pt := current_target.global_position + Vector3(0, 1.25, 0) if current_target != null else from - global_transform.basis.z * 40.0
	var spread: float = (0.02 + suppression * 0.05) * difficulty_spread_mult
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
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node != null and is_instance_valid(player_node) and "camera" in player_node and player_node.camera != null:
		FRONTLINEAmbience.check_bullet_flyby(from, to, player_node.camera.global_position)

	var bullet_speeds := [715.0, 380.0, 865.0, 253.0, 400.0, 488.0, 760.0, 48.0]
	var bullet_speed: float = bullet_speeds[clampi(bot_weapon_index, 0, bullet_speeds.size() - 1)]
	var damage_to_target := 24
	var damage_to_player := 22
	match bot_weapon_index:
		2, 6:
			damage_to_target = 52
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
		bullet.configure(from, shoot_dir, bullet_speed, damage_to_target, bullet_range, soldier_name, team_name, self, damage_to_player)
		world.add_child(bullet)

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

## Получение урона
func receive_hit(damage: int, attacker_pos: Vector3, region: String = "chest", attacker_name: String = "Unknown") -> int:
	if is_dead:
		return 0
	health -= damage
	suppression = minf(1.0, suppression + 0.45)
	if _proc != null and health > 0.0:
		_proc.add_flinch(0.55 if region == "chest" else 0.75)
	if health > 0.0 and randf() < 0.45:
		_shout("РАНЕН!" if team_name.contains("RED") else "GETROFFEN!", Color(0.95, 0.25, 0.25))

	# Поворачиваемся в сторону стрелявшего при неожиданной атаке
	if current_target == null:
		var to := attacker_pos - global_position
		rotation.y = atan2(-to.x, -to.z)

	if health <= 0.0:
		_die(attacker_pos, region, attacker_name)
	return damage

## Гибель бойца: физический рэгдолл, падение оружия, лужа крови и сигнал
func _die(attacker_pos: Vector3, region: String, killer_name: String) -> void:
	is_dead = true
	health = 0.0
	velocity = Vector3.ZERO
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

	# Запускаем физический рэгдолл скелета
	var hit_dir := (global_position - attacker_pos).normalized()
	if _proc != null:
		_proc.set_ragdoll(true, hit_dir, region == "head")

	# Направленные брызги крови и лужа под телом
	HIT_EFFECTS.spawn_directional_blood(self, global_position + Vector3(0, 0.9, 0), hit_dir, region == "head", get_parent())

	# Сигнал для киллфида
	var w_names := ["AK-47", "MP-40", "MOSIN-NAGANT", "M1911", "PUMP SHOTGUN", "PPSH-41", "KAR98K", "PANZERFAUST"]
	var w_name: String = w_names[clampi(bot_weapon_index, 0, w_names.size() - 1)]
	soldier_killed.emit(self, killer_name, w_name)

	# Очистка трупа через 25 секунд
	get_tree().create_timer(25.0, false).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)
