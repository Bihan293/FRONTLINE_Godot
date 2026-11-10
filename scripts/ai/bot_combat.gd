extends RefCounted
class_name FRONTLINEBotCombat

## Стрельба бота: патроны, очереди, перезарядка, разброс и баллистика.
## Решения о цели принимает бот, компонент только исполняет выстрел.

const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const BULLET_PROJECTILE_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const AMBIENCE = preload("res://scripts/battlefield_ambience.gd")
const ROCKET_SCRIPT = preload("res://scripts/rocket_projectile.gd")

const MAG_SIZE := 30
const WEAPON_IDS := ["ak47", "mp40", "mosin", "m1911", "shotgun", "ppsh41", "kar98k", "panzerfaust"]
const BULLET_SPEEDS := [715.0, 380.0, 865.0, 253.0, 400.0, 488.0, 760.0, 48.0]

var ammo := MAG_SIZE
var is_reloading := false
var reload_timer := 0.0
var burst_count := 0
var fire_cooldown := 0.0

var _weapon_index := 0
var _bot_role := "ASSAULT"
var _spread_mult := 1.0
var _reaction_mult := 1.0
var _fire_query := PhysicsRayQueryParameters3D.new()

func setup(weapon_index: int, bot_role: String, spread_mult: float, reaction_mult: float) -> void:
	_weapon_index = clampi(weapon_index, 0, WEAPON_IDS.size() - 1)
	_bot_role = bot_role
	_spread_mult = spread_mult
	_reaction_mult = reaction_mult
	_fire_query.collision_mask = 1 | 2
	_fire_query.collide_with_areas = true
	_fire_query.collide_with_bodies = true
	fire_cooldown = randf_range(0.4, 1.2) * reaction_mult

func tick(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if not is_reloading:
		return
	reload_timer -= delta
	if reload_timer <= 0.0:
		ammo = MAG_SIZE
		is_reloading = false

func start_reload(bot: CharacterBody3D) -> void:
	if is_reloading:
		return
	is_reloading = true
	reload_timer = 2.4
	bot.set("stance", 1)
	var red := str(bot.get("team_name")).contains("RED")
	bot.call("_shout", "ПЕРЕЗАРЯДКА!" if red else "LADE NACH!", Color(0.3, 0.8, 1.0))
	var visuals = bot.get("_visuals")
	if visuals != null:
		visuals.call("play_reload")

func try_fire(bot: CharacterBody3D, can_see: bool) -> void:
	if is_reloading or fire_cooldown > 0.0 or not can_see:
		return
	if ammo <= 0:
		start_reload(bot)
		return
	if not _muzzle_clear(bot):
		fire_cooldown = 0.20
		return
	ammo -= 1
	_fire_single_shot(bot)
	burst_count += 1
	match _weapon_index:
		2, 6:
			burst_count = 0
			fire_cooldown = randf_range(1.3, 2.1) * _reaction_mult
		4:
			burst_count = 0
			fire_cooldown = randf_range(0.85, 1.4) * _reaction_mult
		7:
			burst_count = 0
			fire_cooldown = randf_range(3.2, 4.8) * _reaction_mult
		3:
			if burst_count >= randi_range(1, 3):
				burst_count = 0
				fire_cooldown = randf_range(0.6, 1.2) * _reaction_mult
			else:
				fire_cooldown = 0.24
		5:
			var max_burst: int = randi_range(9, 15) if _bot_role == "GUNNER" else randi_range(6, 10)
			if burst_count >= max_burst:
				burst_count = 0
				fire_cooldown = randf_range(0.65, 1.3) * _reaction_mult
			else:
				fire_cooldown = 0.065
		1:
			if burst_count >= randi_range(4, 7):
				burst_count = 0
				fire_cooldown = randf_range(0.7, 1.5) * _reaction_mult
			else:
				fire_cooldown = 0.08
		_:
			if burst_count >= randi_range(3, 5):
				burst_count = 0
				fire_cooldown = randf_range(0.8, 1.8) * _reaction_mult
			else:
				fire_cooldown = 0.10

func _fire_single_shot(bot: CharacterBody3D) -> void:
	var team := str(bot.get("team_name"))
	var soldier_name := str(bot.get("soldier_name"))
	bot.emit_signal("soldier_fired", bot.global_position, team)
	var visuals = bot.get("_visuals")
	var from := bot.global_position + Vector3(0, 1.3, 0)
	if visuals != null:
		from = visuals.call("muzzle_position")
		visuals.call("play_shot", from)
		visuals.call("flash_muzzle")
		visuals.call("set_firing", true)

	var perception = bot.get("_perception")
	var target_pt: Vector3 = perception.call("fire_point") if perception != null and bot.get("current_target") != null else from - bot.global_transform.basis.z * 40.0
	var base_spread: float = 0.045 if _bot_role == "SNIPER" else 0.068
	base_spread += minf(float(burst_count) * 0.009, 0.048)
	base_spread += float(bot.get("suppression")) * 0.062
	var velocity: Vector3 = bot.velocity
	if Vector2(velocity.x, velocity.z).length() > 0.4:
		base_spread += 0.028
	if int(bot.get("stance")) == 1:
		base_spread *= 0.78
	var spread := base_spread * _spread_mult
	var shoot_dir := (target_pt - from).normalized()
	shoot_dir = shoot_dir.rotated(Vector3.UP, randf_range(-spread, spread))
	shoot_dir = shoot_dir.rotated(bot.global_transform.basis.x, randf_range(-spread, spread))

	if _weapon_index == 7:
		var rocket = ROCKET_SCRIPT.new()
		bot.get_parent().add_child(rocket)
		rocket.launch(from, shoot_dir, soldier_name, team)
		return

	var casing_pos := bot.global_position + Vector3(0, 1.3, 0)
	var eject_dir := bot.global_transform.basis.x * 2.2 + Vector3.UP * 1.5 - bot.global_transform.basis.z * 0.4
	HIT_EFFECTS.spawn_casing(bot.get_parent(), casing_pos, eject_dir)

	var bullet_range := 150.0
	var to := from + shoot_dir * bullet_range
	var player_node := bot.get_tree().get_first_node_in_group("player") as Node3D
	if player_node != null and "camera" in player_node and player_node.get("camera") != null:
		AMBIENCE.check_bullet_flyby(from, to, (player_node.get("camera") as Camera3D).global_position)

	var bullet_speed: float = BULLET_SPEEDS[_weapon_index]
	var damage_to_target := 20
	var damage_to_player := 16
	match _weapon_index:
		2, 6:
			damage_to_target = 46
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
	var world := bot.get_parent()
	if world != null and world.has_method("spawn_bullet_projectile"):
		world.call("spawn_bullet_projectile", from, shoot_dir, bullet_speed, damage_to_target, bullet_range, soldier_name, team, bot, damage_to_player)
	elif world != null:
		var bullet = BULLET_PROJECTILE_SCRIPT.new()
		world.add_child(bullet)
		bullet.configure(from, shoot_dir, bullet_speed, damage_to_target, bullet_range, soldier_name, team, bot, damage_to_player)

func _muzzle_clear(bot: CharacterBody3D) -> bool:
	var target = bot.get("current_target")
	if target == null or bot.get("_visuals") == null:
		return true
	var visuals = bot.get("_visuals")
	var from: Vector3 = visuals.call("muzzle_position")
	var perception = bot.get("_perception")
	var aim: Vector3 = perception.call("fire_point")
	if from.distance_to(aim) < 0.1:
		return true
	_fire_query.from = from
	_fire_query.to = aim
	_fire_query.exclude = bot.call("get_projectile_rids")
	var hit := bot.get_world_3d().direct_space_state.intersect_ray(_fire_query)
	if hit.is_empty():
		return true
	var collider: Object = hit.get("collider")
	if collider == target:
		return true
	if collider is Area3D and collider.has_meta("owner_actor"):
		return collider.get_meta("owner_actor") == target
	return false
