extends RefCounted
class_name FRONTLINEPlayerVehicles

## Посадка, выезд и обслуживание техники/турелей.
## Игрок остаётся физическим телом, компонент только переключает режим.

var vehicle: Node3D = null
var _player: CharacterBody3D
var _last_vehicle_yaw := 0.0

func setup(player: CharacterBody3D) -> void:
	_player = player

func is_mounted() -> bool:
	return vehicle != null and is_instance_valid(vehicle)

func enter(target: Node3D) -> bool:
	if _player == null or target == null or not is_instance_valid(target):
		return false
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")) or is_mounted():
		return false
	if not target.has_method("enter") or not bool(target.call("can_enter", _player)):
		return false
	vehicle = target
	_last_vehicle_yaw = target.global_rotation.y
	if target.has_method("camera_follows_vehicle") and bool(target.call("camera_follows_vehicle")):
		_player.set("yaw", _last_vehicle_yaw)
	target.call("enter", _player)
	if target is PhysicsBody3D:
		_player.add_collision_exception_with(target)
	_player.set("velocity", Vector3.ZERO)
	var controls = _player.get("mobile_controls")
	if controls != null and controls.has_method("set_vehicle_mode"):
		controls.call("set_vehicle_mode", true)
	var weapon_root: Node3D = _player.get("weapon_root")
	if weapon_root != null:
		weapon_root.visible = false
	var camera: Camera3D = _player.get("camera")
	var eye_height := 1.20
	if target.has_method("driver_eye_height"):
		eye_height = float(target.call("driver_eye_height"))
	if camera != null:
		camera.position.y = eye_height
	if target.has_method("seat_position"):
		_player.global_position = target.call("seat_position")
	return true

func exit() -> void:
	var current := vehicle
	vehicle = null
	if current != null and is_instance_valid(current):
		if current.has_method("exit_vehicle"):
			current.call("exit_vehicle", _player)
		if current is PhysicsBody3D:
			_player.remove_collision_exception_with(current)
		if current.has_method("exit_position"):
			_player.global_position = current.call("exit_position")
	_player.set("velocity", Vector3.ZERO)
	var controls = _player.get("mobile_controls")
	if controls != null and controls.has_method("set_vehicle_mode"):
		controls.call("set_vehicle_mode", false)
	var camera: Camera3D = _player.get("camera")
	if camera != null:
		camera.position.y = 1.70
	var weapon_root: Node3D = _player.get("weapon_root")
	if weapon_root != null and not bool(_player.get("is_dead")):
		weapon_root.visible = true
	var body: Node3D = _player.get("player_body")
	if body != null and not bool(_player.get("is_dead")):
		body.visible = false

func process(delta: float) -> void:
	if not is_mounted():
		vehicle = null
		return
	_player.set("velocity", Vector3.ZERO)
	if vehicle.has_method("camera_follows_vehicle") and bool(vehicle.call("camera_follows_vehicle")):
		var vehicle_yaw: float = vehicle.global_rotation.y
		var yaw := float(_player.get("yaw")) + wrapf(vehicle_yaw - _last_vehicle_yaw, -PI, PI)
		_player.set("yaw", yaw)
		_last_vehicle_yaw = vehicle_yaw
	var hud = _player.get("_player_hud")
	if hud != null and not bool(_player.get("is_dead")):
		hud.call("set_scope", false)
		hud.call("set_crosshair_visible", true)
	if vehicle.has_method("tick_driver"):
		vehicle.call("tick_driver", _player, delta)
	var firing: bool = bool(_player.get("mobile_fire")) or (not OS.has_feature("mobile") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	if firing and vehicle.has_method("try_fire"):
		vehicle.call("try_fire", _player)
	_player.call("_apply_look", delta)
	_player.call("_refresh_pickup_prompt")

func nearest_enterable() -> Node3D:
	if is_mounted() or _player == null:
		return null
	var nearest: Node3D = null
	var best_score := INF
	for node in _player.get_tree().get_nodes_in_group("enterable_vehicles"):
		var station := node as Node3D
		if station == null or not is_instance_valid(station):
			continue
		if not station.has_method("can_enter") or not bool(station.call("can_enter", _player)):
			continue
		var radius := 2.8
		if station.has_method("interaction_radius"):
			radius = float(station.call("interaction_radius"))
		var distance := _player.global_position.distance_to(station.global_position)
		if distance > radius:
			continue
		var score := distance / maxf(radius, 0.1)
		if score < best_score:
			best_score = score
			nearest = station
	return nearest
