extends RefCounted
class_name FRONTLINEBotMotor

## Движение бота: навигационный маршрут, обход стен, расталкивание,
## антизастревание. Не принимает решений — только исполняет намерение.

const TUNING = preload("res://scripts/ai/bot_tuning.gd")

const WALK_SPEED := 3.4
const CROUCH_SPEED := 1.9

var _navigation: FRONTLINEBotNavigation

var _route_path := PackedVector3Array()
var _route_index := 0
var _route_goal := Vector3.ZERO
var _route_repath_timer := 0.0
var _route_has_attempted := false

var _stuck_check_timer := 0.0
var _stuck_last_pos := Vector3.ZERO
var _unstick_timer := 0.0
var _unstick_dir := Vector3.ZERO
var _unstick_jump := false
var _last_intended_speed := 0.0

var _avoid_timer := 0.0
var _avoid_in := Vector3.ZERO
var _avoid_out := Vector3.ZERO
var _avoid_front := PhysicsRayQueryParameters3D.new()
var _avoid_left := PhysicsRayQueryParameters3D.new()
var _avoid_right := PhysicsRayQueryParameters3D.new()

var _sep_timer := 0.0

func setup(bot: CharacterBody3D, navigation: FRONTLINEBotNavigation) -> void:
	_navigation = navigation
	for query in [_avoid_front, _avoid_left, _avoid_right]:
		query.collision_mask = TUNING.WORLD_LAYER
		query.collide_with_areas = false
		query.collide_with_bodies = true
	_stuck_last_pos = bot.global_position

func resolve(bot: CharacterBody3D, delta: float) -> Vector3:
	var velocity := bot.velocity
	var intent := Vector3(velocity.x, 0.0, velocity.z)
	if intent.length_squared() > 0.0001:
		var avoided := _avoid(bot, intent.normalized())
		var speed := intent.length()
		velocity.x = avoided.x * speed
		velocity.z = avoided.z * speed
	velocity = _separate(bot, velocity, delta)
	if _unstick_timer > 0.0:
		_unstick_timer -= delta
		if _unstick_dir.length_squared() > 0.01:
			velocity.x = _unstick_dir.x * WALK_SPEED
			velocity.z = _unstick_dir.z * WALK_SPEED
		if _unstick_jump and bot.is_on_floor():
			velocity.y = 4.6
			_unstick_jump = false
	_last_intended_speed = Vector2(velocity.x, velocity.z).length()
	return velocity

func update_stuck(bot: CharacterBody3D, delta: float) -> void:
	if _unstick_timer > 0.0:
		return
	_stuck_check_timer -= delta
	if _stuck_check_timer > 0.0:
		return
	_stuck_check_timer = 0.8
	var moved := bot.global_position.distance_to(_stuck_last_pos)
	_stuck_last_pos = bot.global_position
	if _last_intended_speed <= CROUCH_SPEED * 0.8 or moved >= 0.18:
		return
	var heading := Vector3(bot.velocity.x, 0.0, bot.velocity.z)
	if heading.length_squared() < 0.01:
		heading = -bot.global_transform.basis.z
	heading = heading.normalized()
	var side := Vector3(-heading.z, 0.0, heading.x) * (1.0 if randf() < 0.5 else -1.0)
	_unstick_dir = (side + heading * 0.35).normalized()
	_unstick_timer = 0.55
	_unstick_jump = true
	_route_repath_timer = 0.0
	_route_has_attempted = false

func route_direction(bot: CharacterBody3D, destination: Vector3, delta: float) -> Vector3:
	var direct := destination - bot.global_position
	direct.y = 0.0
	if direct.length_squared() <= 0.04:
		return Vector3.ZERO
	if _navigation == null:
		return direct.normalized()
	_route_repath_timer = maxf(0.0, _route_repath_timer - delta)
	var destination_moved := _route_goal.distance_squared_to(destination) > 25.0
	if not _route_has_attempted or _route_repath_timer <= 0.0 or destination_moved:
		_route_path = _navigation.find_path(bot.global_position, destination)
		_route_goal = destination
		_route_index = _closest_waypoint_index(bot.global_position, _route_path)
		_route_repath_timer = 2.4 + float(bot.get_instance_id() % 5) * 0.12
		_route_has_attempted = true
	if _route_path.is_empty():
		return direct.normalized()
	while _route_index < _route_path.size() - 1:
		var waypoint := _route_path[_route_index]
		waypoint.y = bot.global_position.y
		if bot.global_position.distance_to(waypoint) > 1.15:
			break
		_route_index += 1
	var next_point := _route_path[_route_index]
	var direction := next_point - bot.global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.04:
		return Vector3.ZERO
	return direction.normalized()

func invalidate_route() -> void:
	_route_repath_timer = 0.0
	_route_has_attempted = false

func _closest_waypoint_index(here_pos: Vector3, path: PackedVector3Array) -> int:
	var best := 0
	var best_dist := INF
	var here := Vector2(here_pos.x, here_pos.z)
	for i in range(path.size()):
		var point := Vector2(path[i].x, path[i].z)
		var dist := here.distance_squared_to(point)
		if dist < best_dist:
			best_dist = dist
			best = i
	return best

func _separate(bot: CharacterBody3D, velocity: Vector3, delta: float) -> Vector3:
	_sep_timer += delta
	if _sep_timer < 0.10:
		return velocity
	var step := _sep_timer
	_sep_timer = 0.0
	var push := Vector3.ZERO
	for node in bot.get_tree().get_nodes_in_group("bots"):
		if node == bot or not is_instance_valid(node):
			continue
		var other := node as Node3D
		if other == null:
			continue
		var offset := bot.global_position - other.global_position
		offset.y = 0.0
		var dist_sq := offset.length_squared()
		if dist_sq > 0.0025 and dist_sq < 5.29:
			var dist := sqrt(dist_sq)
			push += (offset / dist) * ((2.3 - dist) / 2.3)
	if push.length_squared() > 0.001:
		push = push.limit_length(1.0)
		velocity.x += push.x * 18.0 * step
		velocity.z += push.z * 18.0 * step
	return velocity

func avoid(bot: CharacterBody3D, desired_dir: Vector3) -> Vector3:
	return _avoid(bot, desired_dir)

func _avoid(bot: CharacterBody3D, desired_dir: Vector3) -> Vector3:
	_avoid_timer -= bot.get_physics_process_delta_time()
	if _avoid_timer > 0.0 and _avoid_in.dot(desired_dir) > 0.92:
		return _avoid_out
	_avoid_in = desired_dir
	_avoid_timer = 0.10 + float(bot.get_instance_id() % 4) * 0.01
	_avoid_out = _avoid_cast(bot, desired_dir)
	return _avoid_out

func _avoid_cast(bot: CharacterBody3D, desired_dir: Vector3) -> Vector3:
	if desired_dir.length_squared() < 0.01:
		return desired_dir
	var space := bot.get_world_3d().direct_space_state
	var from := bot.global_position + Vector3(0.0, 0.70, 0.0)
	var forward := desired_dir.normalized()
	var rids: Array[RID] = bot.call("get_projectile_rids")

	_avoid_front.from = from
	_avoid_front.to = from + forward * 1.8
	_avoid_front.exclude = rids
	var hit_front := space.intersect_ray(_avoid_front)
	if hit_front.is_empty():
		return desired_dir

	var right_probe := forward.rotated(Vector3.UP, deg_to_rad(50.0))
	var left_probe := forward.rotated(Vector3.UP, deg_to_rad(-50.0))

	_avoid_right.from = from
	_avoid_right.to = from + right_probe * 1.8
	_avoid_right.exclude = rids
	var hit_right := space.intersect_ray(_avoid_right)

	_avoid_left.from = from
	_avoid_left.to = from + left_probe * 1.8
	_avoid_left.exclude = rids
	var hit_left := space.intersect_ray(_avoid_left)

	if hit_right.is_empty():
		return right_probe
	if hit_left.is_empty():
		return left_probe
	var normal: Vector3 = hit_front.get("normal", -forward)
	var tangent := Vector3(-normal.z, 0.0, normal.x)
	return tangent if tangent.dot(desired_dir) >= 0.0 else -tangent
