extends CharacterBody3D
class_name FRONTLINESoldierBot

## Умный ИИ-солдат для масштабных сражений в стиле Dummy War.
## Имеет полную физику перемещения, поиск укрытий, командное зрение,
## стрельбу очередями, перезарядку, подавление и физический рэгдолл при гибели.

signal soldier_killed(victim: FRONTLINESoldierBot, killer_name: String, weapon_name: String)
signal soldier_fired(pos: Vector3, team: String)

const PERCEPTION = preload("res://scripts/ai/bot_perception.gd")
const TUNING = preload("res://scripts/ai/bot_tuning.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const FIELD_PICKUP_SCRIPT = preload("res://scripts/field_pickup.gd")
const GRENADE_SCRIPT = preload("res://scripts/grenade.gd")
const COUNTRYSIDE_LAYOUT = preload("res://scripts/countryside_layout.gd")


const SPEED_WALK := 3.4
const SPEED_SPRINT := 5.6
const SPEED_CROUCH := 1.9
const MAX_HEALTH := 100.0
const WORLD_LAYER_MASK := 1 << 0
const HITBOX_LAYER_MASK := 1 << 1
const SOLDIER_LAYER_MASK := 1 << 2
const RAY_COLLISION_MASK := WORLD_LAYER_MASK | HITBOX_LAYER_MASK

@export var team_name: String = "IRON LEGION"
@export var soldier_name: String = "Soldier"
@export var bot_weapon_index: int = -1

var _combat := FRONTLINEBotCombat.new()
var health: float = MAX_HEALTH
var is_dead := false
var stance := 0  # 0: stand, 1: crouch
var ammo: int:
	get: return _combat.ammo
	set(value): _combat.ammo = value
var is_reloading: bool:
	get: return _combat.is_reloading
	set(value): _combat.is_reloading = value
var reload_timer: float:
	get: return _combat.reload_timer
	set(value): _combat.reload_timer = value
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
var _motor := FRONTLINEBotMotor.new()
var burst_count: int:
	get: return _combat.burst_count
	set(value): _combat.burst_count = value
var fire_cooldown: float:
	get: return _combat.fire_cooldown
	set(value): _combat.fire_cooldown = value

# Тактический боевой ИИ (Dummy War Tactical Firefight)
var target_acquisition_timer := 0.0
var combat_strafe_timer := 0.0
var combat_strafe_dir := Vector3.ZERO
var _last_target_id := 0

# Узлы модели
var _hitboxes: Array[Area3D] = []
var _visuals: FRONTLINEBotVisuals
# Антизастревание: решение принимается до move_and_slide, а не после.
# QA-optimization: кэш акустики (4 Гц вместо каждого выстрела).
var _self_rids: Array[RID] = []
# Обход препятствий считается один раз за кадр по итоговому направлению.
var _avoid_timer := 0.0
var _avoid_in := Vector3.ZERO
var _avoid_out := Vector3.ZERO
var _avoid_front := PhysicsRayQueryParameters3D.new()
var _avoid_left := PhysicsRayQueryParameters3D.new()
var _avoid_right := PhysicsRayQueryParameters3D.new()
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
var _cached_player: Node3D = null

static var profile_build := false

func _ready() -> void:
	var t_build := Time.get_ticks_usec()
	# Индивидуальный маршрут и ритм перебежек, чтобы отделение не шло «паровозиком».
	_personal_offset_x = randf_range(-9.0, 9.0)
	_bound_timer = randf_range(0.6, 2.2)
	_bound_crouch = false
	add_to_group("bots")
	add_to_group("damageable_actor")
	collision_layer = SOLDIER_LAYER_MASK
	collision_mask = WORLD_LAYER_MASK | SOLDIER_LAYER_MASK
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(45.0)
	_motor.setup(self, get_node_or_null("/root/BotNavigation") as FRONTLINEBotNavigation)

	match_difficulty = MatchState.difficulty
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
	var t_rest0 := Time.get_ticks_usec()
	_build_hitboxes()
	_rebuild_self_rids()
	if profile_build:
		var t_end := Time.get_ticks_usec()
		print("BOT_BUILD collide=%.2f visuals=%.2f rest=%.2f total=%.2f" % [
			float(t_visual0 - t_collide0) / 1000.0,
			float(t_rest0 - t_visual0) / 1000.0,
			float(t_end - t_rest0) / 1000.0,
			float(t_end - t_build) / 1000.0
		])

	_perception = PERCEPTION.new()
	_perception.setup(self, randf())
	_cache_map_data()
	_combat.setup(bot_weapon_index, bot_role, difficulty_spread_mult, difficulty_reaction_mult)

## Данные карты не меняются во время матча — считаем один раз.
func _cache_map_data() -> void:
	_cached_map_name = MatchState.map_name
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
	_visuals = FRONTLINEBotVisuals.new()
	_visuals.name = "BotVisuals"
	add_child(_visuals)
	_visuals.setup(team_name, soldier_name, bot_weapon_index, bot_role)

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
	_visuals.add_child(area)
	_hitboxes.append(area)

func _physics_process(delta: float) -> void:
	if is_dead:
		_apply_gravity(delta)
		move_and_slide()
		return

	_apply_gravity(delta)
	_handle_effects(delta)
	if _perception != null:
		_perception.tick(delta, _get_self_collision_rids())
	_update_ai(delta)
	velocity = _motor.resolve(self, delta)
	move_and_slide()
	_motor.update_stuck(self, delta)
	_update_animation(delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

## Единая точка применения движения: поведение задаёт намерение,
## здесь оно один раз обходит препятствия, расталкивается и выбирается
## из застревания. Никаких повторных рейкастов из каждого поведения.
func _avoid_obstacles(desired_dir: Vector3) -> Vector3:
	return _motor.avoid(self, desired_dir)

func _route_direction(destination: Vector3, delta: float) -> Vector3:
	return _motor.route_direction(self, destination, delta)

func _update_animation(delta: float) -> void:
	var horiz_vel := Vector2(velocity.x, velocity.z).length()
	if _visuals != null:
		_visuals.update_motion(horiz_vel, horiz_vel > SPEED_WALK + 0.5, stance >= 1, stance == 2, is_reloading)
		_visuals.update_effects(delta, true)

## Мягкое расталкивание союзников: боты не сбиваются в кучу в углах и проходах.
func _update_ai(delta: float) -> void:
	_combat.tick(delta)
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
				var flee_dir := _motor.avoid(self, away)
				velocity.x = flee_dir.x * SPEED_SPRINT
				velocity.z = flee_dir.z * SPEED_SPRINT
				stance = 0
				if is_on_floor() and randf() < 0.02:
					velocity.y = 4.2
				_motor.invalidate_route()
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
		stance = 1
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
	var direction := _motor.route_direction(self, point, delta)
	if direction.length_squared() < 0.01:
		_perception.clear_alert()
		_advance_behavior(delta)
		return
	velocity.x = direction.x * SPEED_WALK
	velocity.z = direction.z * SPEED_WALK
	stance = 0
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 5.0, 0.0, 1.0))
	if _visuals != null:
		_visuals.set_gun_pitch(0.0)
		_scan_time += delta
		_visuals.set_look(sin(_scan_time * 1.6) * 0.35, 0.0)

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
			var seek_dir := _motor.route_direction(self, last_seen, delta)
			velocity.x = seek_dir.x * SPEED_WALK
			velocity.z = seek_dir.z * SPEED_WALK

	# Плавный поворот к противнику
	var target_yaw := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 8.0, 0.0, 1.0))

	# Наклон оружия и головы к реальной точке прицеливания.
	if _visuals != null:
		var aim_y := TUNING.aim_height(current_target)
		var pitch := atan2(to.y + aim_y - _visuals.gun_position().y, Vector2(to.x, to.z).length())
		_visuals.set_gun_pitch(pitch)
		_visuals.set_look(0.0, pitch)

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
		var move_dir := _motor.route_direction(self, tpos, delta)
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
	if can_see and dist <= TUNING.engage_range(bot_weapon_index):
		_combat.try_fire(self, true)

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

	var forward_dir := _motor.route_direction(self, objective, delta)

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
	if _visuals != null:
		_visuals.set_gun_pitch(0.0)
		_visuals.set_look(0.0, 0.0)

## Процедурный обход препятствий (стен, заборов, мешков).
## Вызывается ровно один раз за кадр из _resolve_movement.
func _handle_effects(delta: float) -> void:
	if _visuals != null:
		_visuals.update_effects(delta, true)

func _shout(phrase: String, color: Color) -> void:
	if _visuals != null and not is_dead:
		_visuals.shout(phrase, color)

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

	if _visuals != null and health > 0.0:
		_visuals.add_flinch(clampf(float(damage) * 0.035, 0.75, 2.0))
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
	if _visuals != null and _visuals.weapon_mesh() != null:
		var drop_pos := _visuals.weapon_drop_position()
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
		_visuals.hide_weapon()

	# Текст статуса и рэгдолл
	if _visuals != null:
		_visuals.mark_dead()
		_visuals.set_ragdoll(true, hit_dir, region == "head")

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
