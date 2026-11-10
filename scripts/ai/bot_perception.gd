extends RefCounted
class_name FRONTLINEBotPerception

## Восприятие бойца: зрение, слух, память о последней угрозе.
## Модуль ничего не двигает и не стреляет — только отвечает на вопросы
## «кого я вижу», «где последний контакт» и «стоит ли идти проверять шум».

const TUNING = preload("res://scripts/ai/bot_tuning.gd")
const SMOKE = preload("res://scripts/smoke_grenade.gd")

var target: Node3D = null
var target_visible := false
var last_known_position := Vector3.ZERO
var last_seen_age := TUNING.TARGET_MEMORY
var alert_position := Vector3.ZERO
var alert_age := TUNING.ALERT_MEMORY

var _owner: CharacterBody3D
var _query := PhysicsRayQueryParameters3D.new()
var _self_rids: Array[RID] = []
var _player: Node3D = null
var _scan_timer := 0.0
var _los_timer := 0.0
var _phase := 0.0

func setup(owner: CharacterBody3D, phase: float) -> void:
	_owner = owner
	_phase = phase
	_scan_timer = phase
	_query.collide_with_areas = true
	_query.collide_with_bodies = true
	_query.hit_from_inside = false
	_query.collision_mask = TUNING.LOS_MASK

## Вызывается один раз за физический кадр до принятия решений.
func tick(delta: float, self_rids: Array[RID]) -> void:
	if _owner == null or not is_instance_valid(_owner):
		return
	_self_rids = self_rids
	_scan_timer -= delta
	alert_age += delta
	last_seen_age += delta

	if target != null and (not is_instance_valid(target) or _actor_is_dead(target)):
		_lose_target()

	if target != null:
		_los_timer -= delta
		if _los_timer <= 0.0:
			_los_timer = TUNING.LOS_INTERVAL * (0.92 + 0.16 * _phase)
			target_visible = _can_see(target, _eye_point(), _needs_solid_hit(target))
			if target_visible:
				last_known_position = target.global_position
				last_seen_age = 0.0
		if not target_visible and last_seen_age > TUNING.TARGET_MEMORY:
			_lose_target()

	if _scan_timer <= 0.0:
		_scan()
		_scan_timer = _next_scan_interval()

## Повреждение — самый надежный источник информации: даже если стрелок
## за укрытием, боец знает направление и идет проверять.
func notify_damage(attacker_pos: Vector3) -> void:
	alert_position = attacker_pos
	alert_age = 0.0
	_scan_timer = 0.0
	if target == null:
		last_known_position = attacker_pos

## Слух: выстрел/взрыв в радиусе слышимости поднимает тревогу.
func notify_gunshot(sound_pos: Vector3) -> void:
	if alert_age < 1.2:
		return
	var max_dist := TUNING.HEARING_RADIUS
	if _owner.global_position.distance_squared_to(sound_pos) > max_dist * max_dist:
		return
	alert_position = sound_pos
	alert_age = 0.0
	if target == null:
		_scan_timer = minf(_scan_timer, 0.1)

func has_alert() -> bool:
	return alert_age < TUNING.ALERT_MEMORY and not alert_position.is_zero_approx()

func clear_alert() -> void:
	alert_age = TUNING.ALERT_MEMORY
	alert_position = Vector3.ZERO

func force_target(value: Node3D) -> void:
	target = value
	target_visible = value != null
	last_seen_age = 0.0 if value != null else TUNING.TARGET_MEMORY
	if value != null:
		last_known_position = value.global_position
		_los_timer = 0.0

func fire_point() -> Vector3:
	if target == null or not is_instance_valid(target):
		return _eye_point() - _owner.global_transform.basis.z * 20.0
	return target.global_position + Vector3.UP * TUNING.aim_height(target)

func _lose_target() -> void:
	if target != null and last_seen_age < TUNING.TARGET_MEMORY:
		alert_position = last_known_position
		alert_age = minf(alert_age, TUNING.ALERT_MEMORY - 0.5)
	target = null
	target_visible = false
	last_seen_age = TUNING.TARGET_MEMORY

func _next_scan_interval() -> float:
	if target != null and target_visible:
		return TUNING.SCAN_INTERVAL_VISIBLE
	if target != null:
		return TUNING.SCAN_INTERVAL_TRACKING
	return TUNING.SCAN_INTERVAL_IDLE * (0.9 + 0.2 * _phase)

func _scan() -> void:
	var tree := _owner.get_tree()
	if tree == null:
		return
	var eye := _eye_point()
	var max_range := TUNING.engage_range(int(_owner.get("bot_weapon_index")))
	var best: Node3D = null
	var best_dist := INF

	# Игрок — приоритетная цель, но только если он враждебен и в поле внимания.
	var player := _get_player(tree)
	if player != null and is_instance_valid(player) and _is_enemy(player):
		var pdist := _owner.global_position.distance_to(player.global_position)
		if pdist <= max_range and _in_awareness_cone(player, pdist):
			if pdist <= TUNING.PROXIMITY_AWARENESS or _can_see(player, eye):
				best = player
				best_dist = pdist

	# Ближайшие враги: проверяем лучами не больше MAX_CANDIDATES, а не всех.
	var nearest: Array[Node3D] = []
	var nearest_dist: Array[float] = []
	for node in tree.get_nodes_in_group("bots"):
		var bot := node as Node3D
		if bot == null or bot == _owner or not is_instance_valid(bot):
			continue
		if bot.get("team_name") == _owner.get("team_name") or _actor_is_dead(bot):
			continue
		var dist := _owner.global_position.distance_to(bot.global_position)
		if dist > max_range or not _in_awareness_cone(bot, dist):
			continue
		_insert_nearest(nearest, nearest_dist, bot, dist)

	for i in range(nearest.size()):
		if nearest_dist[i] <= TUNING.PROXIMITY_AWARENESS or _can_see(nearest[i], eye):
			if nearest_dist[i] < best_dist:
				best = nearest[i]
				best_dist = nearest_dist[i]
			break

	if best != null:
		if best != target:
			target = best
			last_seen_age = 0.0
			alert_position = best.global_position
			alert_age = 0.0
		target_visible = true
		last_known_position = best.global_position

func _insert_nearest(nodes: Array[Node3D], dists: Array[float], node: Node3D, dist: float) -> void:
	var index := nodes.size()
	while index > 0 and dists[index - 1] > dist:
		index -= 1
	nodes.insert(index, node)
	dists.insert(index, dist)
	while nodes.size() > TUNING.MAX_CANDIDATES:
		nodes.pop_back()
		dists.pop_back()

func _can_see(actor: Node3D, eye: Vector3, require_solid_hit := false) -> bool:
	var space := _owner.get_world_3d().direct_space_state
	var points := _sample_points(actor)
	# Дым проверяем один раз на цель, а не на каждый из трёх лучей.
	if SMOKE.is_line_blocked_by_smoke(eye, points[1]):
		return false
	for point in points:
		_query.from = eye
		_query.to = point
		_query.exclude = _self_rids
		var hit := space.intersect_ray(_query)
		if hit.is_empty():
			if not require_solid_hit:
				return true
			continue
		var collider: Object = hit.get("collider")
		if collider == actor:
			return true
		if collider is Area3D and collider.has_meta("owner_actor"):
			if collider.get_meta("owner_actor") == actor:
				return true
		# Что-то за целью не перекрывает её, если цель ближе препятствия.
		if eye.distance_to(point) <= eye.distance_to(hit.get("position", eye)) + 0.2:
			return true
	return false

func _sample_points(actor: Node3D) -> Array[Vector3]:
	var origin := actor.global_position
	var stance_value := 0
	if "stance" in actor:
		stance_value = int(actor.get("stance"))
	if actor.has_method("get_projectile_rids"):
		# У ботов хитбоксы фиксированные: голова, грудь, ноги.
		return [origin + Vector3.UP * 1.70, origin + Vector3.UP * 1.20, origin + Vector3.UP * 0.55]
	match stance_value:
		1:
			return [origin + Vector3.UP * 1.25, origin + Vector3.UP * 0.95, origin + Vector3.UP * 0.55]
		2:
			return [origin + Vector3.UP * 0.72, origin + Vector3.UP * 0.45, origin + Vector3.UP * 0.22]
		_:
			return [origin + Vector3.UP * 1.72, origin + Vector3.UP * 1.25, origin + Vector3.UP * 0.62]

func _eye_point() -> Vector3:
	var stance_value := int(_owner.get("stance")) if "stance" in _owner else 0
	return _owner.global_position + Vector3.UP * TUNING.eye_height(stance_value)

func _in_awareness_cone(actor: Node3D, dist: float) -> bool:
	if dist <= TUNING.PROXIMITY_AWARENESS:
		return true
	var to := actor.global_position - _owner.global_position
	to.y = 0.0
	if to.length_squared() < 0.001:
		return true
	var forward := -_owner.global_transform.basis.z
	forward.y = 0.0
	return forward.normalized().dot(to.normalized()) >= TUNING.FOV_DOT

func _needs_solid_hit(actor: Node3D) -> bool:
	# Дрон — маленькая летающая цель: без попадания луча в его коллайдер не считаем видимым.
	return actor.is_in_group("radio_drones")

func _get_player(tree: SceneTree) -> Node3D:
	if _player == null or not is_instance_valid(_player):
		_player = tree.get_first_node_in_group("player") as Node3D
	return _player

func _is_enemy(actor: Node3D) -> bool:
	if _actor_is_dead(actor):
		return false
	if actor.is_in_group("radio_drones"):
		return str(actor.get("operator_team")) != str(_owner.get("team_name"))
	if actor.is_in_group("player"):
		return str(_owner.get_tree().get_meta("selected_team", "IRON LEGION")) != str(_owner.get("team_name"))
	return str(actor.get("team_name")) != str(_owner.get("team_name"))

func _actor_is_dead(actor: Node3D) -> bool:
	if not is_instance_valid(actor):
		return true
	return bool(actor.get("is_dead")) if "is_dead" in actor else false
