extends CharacterBody3D
class_name FRONTLINESoldierBot

## Умный ИИ-солдат для масштабных сражений в стиле Dummy War.
## Имеет полную физику перемещения, поиск укрытий, командное зрение,
## стрельбу очередями, перезарядку, подавление и физический рэгдолл при гибели.

signal soldier_killed(victim: FRONTLINESoldierBot, killer_name: String, weapon_name: String)

const PROCEDURAL = preload("res://scripts/procedural_soldier.gd")
const BLOCK_RIG_BUILDER = preload("res://scripts/block_rig_builder.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")

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

@export var team_name: String = "IRON LEGION"
@export var soldier_name: String = "Soldier"

var health: float = MAX_HEALTH
var is_dead := false
var stance := 0  # 0: stand, 1: crouch
var ammo := MAG_SIZE
var is_reloading := false
var reload_timer := 0.0
var suppression := 0.0

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

func _ready() -> void:
	add_to_group("bots")
	add_to_group("damageable_actor")
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(45.0)

	_build_visuals()
	_build_weapon()
	_build_hitboxes()
	_build_label()
	_build_audio()

	target_check_timer = randf_range(0.1, 0.4)
	fire_cooldown = randf_range(0.4, 1.2)

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
	area.collision_layer = 2
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

func _build_label() -> void:
	_label = Label3D.new()
	_label.text = soldier_name
	_label.position = Vector3(0, 2.15, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 18
	_label.modulate = Color(0.85, 0.35, 0.35) if team_name.contains("RED") else Color(0.65, 0.75, 0.85)
	add_child(_label)

func _build_audio() -> void:
	_sfx_shot = AudioStreamPlayer3D.new()
	_sfx_shot.stream = SFX_SHOT
	_sfx_shot.unit_size = 14.0
	_sfx_shot.max_distance = 110.0
	_sfx_shot.max_polyphony = 2
	add_child(_sfx_shot)

	_sfx_reload = AudioStreamPlayer3D.new()
	_sfx_reload.stream = SFX_RELOAD_IN
	_sfx_reload.unit_size = 8.0
	_sfx_reload.max_distance = 45.0
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

func _update_ai(delta: float) -> void:
	# Подавление постепенно рассеивается
	if suppression > 0.0:
		suppression = maxf(0.0, suppression - delta * 0.35)

	# Таймер перезарядки
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			ammo = MAG_SIZE
			is_reloading = false
		velocity.x = lerpf(velocity.x, 0.0, delta * 6.0)
		velocity.z = lerpf(velocity.z, 0.0, delta * 6.0)
		return

	# Проверка целей
	target_check_timer -= delta
	if target_check_timer <= 0.0:
		target_check_timer = randf_range(0.2, 0.45)
		_find_target()

	if current_target != null and is_instance_valid(current_target):
		var target_is_dead: bool = current_target.get("is_dead") if "is_dead" in current_target else false
		if target_is_dead:
			current_target = null
		else:
			_combat_behavior(delta)
			return

	_advance_behavior(delta)

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
			if dist < best_dist and _has_line_of_sight(player.global_position + Vector3(0, 1.4, 0)):
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
			if dist < best_dist and _has_line_of_sight(bot.global_position + Vector3(0, 1.4, 0)):
				best_dist = dist
				best_target = bot

	current_target = best_target

## Проверка прямой видимости (нет ли стен/земли между ботом и целью)
func _has_line_of_sight(target_pos_3d: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 1.5, 0)
	var query := PhysicsRayQueryParameters3D.create(from, target_pos_3d)
	query.exclude = [self]
	var hit := space.intersect_ray(query)
	if hit:
		var col = hit.collider
		if col == current_target or (col.has_meta("owner_actor") and col.get_meta("owner_actor") == current_target):
			return true
		if hit.position.distance_to(target_pos_3d) < 1.2:
			return true
		return false
	return true

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
		var move_dir := to.normalized()
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

	# Стрельба очередями
	fire_cooldown -= delta
	if fire_cooldown <= 0.0:
		_shoot_burst()

## Наступление и патрулирование в сторону вражеской базы
func _advance_behavior(delta: float) -> void:
	stance = 0
	# Направление к вражеской базе (Красные идут в +Z, Легион в -Z)
	var forward_z: float = 1.0 if team_name.contains("RED") else -1.0
	var forward_dir := Vector3(sin(float(get_instance_id() % 5) * 0.4) * 0.25, 0.0, forward_z).normalized()

	velocity.x = forward_dir.x * SPEED_SPRINT
	velocity.z = forward_dir.z * SPEED_SPRINT

	var target_yaw := atan2(-forward_dir.x, -forward_dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(delta * 4.0, 0.0, 1.0))
	if _gun_pivot != null:
		_gun_pivot.rotation.x = 0.0
	if _proc != null:
		_proc.set_look(0.0, 0.0)

## Производит выстрел одной пулей очереди
func _shoot_burst() -> void:
	if ammo <= 0:
		_start_reload()
		return

	ammo -= 1
	_fire_single_shot()
	burst_count += 1

	if burst_count >= randi_range(3, 5):
		burst_count = 0
		fire_cooldown = randf_range(0.8, 1.8)
	else:
		fire_cooldown = 0.11

func _fire_single_shot() -> void:
	if _sfx_shot != null:
		_sfx_shot.pitch_scale = randf_range(0.92, 1.08)
		_sfx_shot.play()

	if _muzzle_flash != null:
		_muzzle_flash.visible = true
		_flash_time = 0.045

	if _proc != null:
		_proc.set_firing(true)

	# Выброс гильзы вправо
	var casing_pos := global_position + Vector3(0, 1.3, 0)
	var eject_dir := global_transform.basis.x * 2.2 + Vector3.UP * 1.5 - global_transform.basis.z * 0.4
	HIT_EFFECTS.spawn_casing(get_parent(), casing_pos, eject_dir)

	# Трассер и баллистика
	var from := _muzzle_node.global_position if _muzzle_node != null else global_position + Vector3(0, 1.3, 0)
	var target_pt := current_target.global_position + Vector3(0, 1.25, 0) if current_target != null else from - global_transform.basis.z * 40.0
	# Разброс оружия в зависимости от расстояния и подавления
	var spread: float = 0.02 + suppression * 0.05
	var shoot_dir := (target_pt - from).normalized()
	shoot_dir = shoot_dir.rotated(Vector3.UP, randf_range(-spread, spread))
	shoot_dir = shoot_dir.rotated(global_transform.basis.x, randf_range(-spread, spread))

	var to := from + shoot_dir * 120.0
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit := space.intersect_ray(query)

	if hit:
		var collider = hit.collider
		if collider.is_in_group("damageable"):
			var region: String = str(collider.get_meta("region", "chest"))
			var actor = collider.get_meta("owner_actor", collider.get_meta("owner_dummy", null))
			if actor != null and actor != self and actor.has_method("receive_hit"):
				var dmg := 22
				match region:
					"head": dmg = 85
					"chest": dmg = 38
					"leg": dmg = 18
				actor.receive_hit(dmg, global_position, region, soldier_name)
				HIT_EFFECTS.spawn_directional_blood(actor, hit.position, shoot_dir, dmg >= 70, get_parent())
		elif collider.is_in_group("player") or collider.name == "Player":
			if collider.has_method("receive_hit"):
				collider.receive_hit(24, global_position, "chest", soldier_name)
				HIT_EFFECTS.spawn_directional_blood(collider, hit.position, shoot_dir, false, get_parent())
		else:
			HIT_EFFECTS.spawn_bullet_hole(get_parent(), hit.position, hit.normal)

func _start_reload() -> void:
	if is_reloading:
		return
	is_reloading = true
	reload_timer = 2.4
	stance = 1
	if _sfx_reload != null:
		_sfx_reload.play()

func _handle_effects(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time -= delta
		if _flash_time <= 0.0 and _muzzle_flash != null:
			_muzzle_flash.visible = false
			if _proc != null:
				_proc.set_firing(false)

## Получение урона
func receive_hit(damage: int, attacker_pos: Vector3, region: String = "chest", attacker_name: String = "Unknown") -> int:
	if is_dead:
		return 0
	health -= damage
	suppression = minf(1.0, suppression + 0.45)

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

	# Отключаем хитбоксы попаданий
	for hb in _hitboxes:
		hb.collision_layer = 0

	# Выбрасываем оружие на землю
	if _gun_pivot != null and _gun_mesh != null:
		var drop_pos := _gun_pivot.global_position
		var drop_vel := Vector3(randf_range(-1.0, 1.0), 1.5, randf_range(-1.0, 1.0))
		HIT_EFFECTS.spawn_dropped_weapon(get_parent(), drop_pos, _gun_mesh.mesh, drop_vel)
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
	soldier_killed.emit(self, killer_name, "AK-47")

	# Очистка трупа через 25 секунд
	get_tree().create_timer(25.0).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)
