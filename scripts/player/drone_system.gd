extends RefCounted
class_name FRONTLINEPlayerDrone

## FPV-дрон радиста: запуск, управление, возврат и подрыв.
## Компонент владеет дроном и планшетом, игрок остаётся телом.

const RADIO_DRONE_SCRIPT = preload("res://scripts/radio_drone.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const MOUSE_SENS := 0.0022

var active_drone: CharacterBody3D = null
var charge_available := true
var vertical_input := 0.0

var _player: CharacterBody3D
var _camera: Camera3D
var _audio_listener: AudioListener3D
var _controller_anchor: Marker3D
var _controller_view: Node3D

func setup(player: CharacterBody3D, camera: Camera3D, audio_listener: AudioListener3D) -> void:
	_player = player
	_camera = camera
	_audio_listener = audio_listener
	_controller_anchor = Marker3D.new()
	_controller_anchor.name = "DroneControllerAnchor"
	_controller_anchor.position = Vector3(0.20, -0.14, -0.46)
	_camera.add_child(_controller_anchor)

func is_active() -> bool:
	return active_drone != null and is_instance_valid(active_drone)

func build_controller_view(player_body: Node3D) -> void:
	_controller_view = WEAPON_MESHES.make_weapon("drone_controller")
	if _controller_view == null:
		return
	_controller_view.name = "RadioController"
	_controller_view.position = Vector3(0.20, 1.36, -0.11)
	_controller_view.visible = false
	player_body.add_child(_controller_view)

func set_controller_feed(feed: Texture2D) -> void:
	if _controller_view == null or not is_instance_valid(_controller_view):
		return
	var screen := _controller_view.get_node_or_null("Screen") as MeshInstance3D
	if screen == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_texture = feed
	material.albedo_color = Color.WHITE
	material.roughness = 0.35
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen.material_override = material

func set_vertical_input(direction: float, pressed: bool) -> void:
	vertical_input = direction if pressed else 0.0

func toggle_launch() -> void:
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")) or str(_player.get("player_role")) != "RADIO_OPERATOR":
		return
	if is_active():
		active_drone.return_to_operator()
		return
	if not charge_available or _player.get_parent() == null:
		return
	charge_available = false
	var drone: CharacterBody3D = RADIO_DRONE_SCRIPT.new()
	if drone == null:
		return
	_player.get_parent().add_child(drone)
	var spawn_pos := _controller_anchor.global_position + (-_camera.global_transform.basis.z * 0.45) + Vector3.UP * 0.08
	drone.launch(spawn_pos, float(_player.get("yaw")), _player, _tether_length())
	drone.returned.connect(_end_control)
	drone.detonated.connect(_on_detonated)
	active_drone = drone
	var body: Node3D = _player.get("player_body")
	if body != null and is_instance_valid(body):
		body.visible = true
		if body.has_method("set_external_view"):
			body.call("set_external_view", true)
		if body.has_method("set_motion"):
			body.call("set_motion", 0.0, false)
		if body.has_method("set_stance"):
			body.call("set_stance", int(_player.get("stance")))
	_camera.current = false
	if drone != null and drone.has_node("DroneCamera/DroneListener"):
		(drone.get_node("DroneCamera/DroneListener") as AudioListener3D).make_current()
	if _controller_view != null:
		_controller_view.visible = true
	var controls = _player.get("mobile_controls")
	if controls != null:
		controls.call("set_drone_mode", true)
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_player.call("_refresh_equipment")

func _on_detonated(_position: Vector3) -> void:
	_end_control()

func _end_control() -> void:
	active_drone = null
	vertical_input = 0.0
	if _controller_view != null and is_instance_valid(_controller_view):
		_controller_view.visible = false
	if _camera != null and is_instance_valid(_camera):
		_camera.current = true
		if _audio_listener != null and is_instance_valid(_audio_listener):
			_audio_listener.make_current()
	var controls = _player.get("mobile_controls")
	if controls != null:
		controls.call("set_drone_mode", false)
	var body: Node3D = _player.get("player_body")
	if body != null and is_instance_valid(body) and not bool(_player.get("is_dead")):
		if body.has_method("set_external_view"):
			body.call("set_external_view", false)
		body.visible = false
	if not OS.has_feature("mobile") and not bool(_player.get("is_dead")):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_player.call("_refresh_equipment")

func look_delta(delta: Vector2, sensitivity: float) -> bool:
	if not is_active():
		return false
	active_drone.drone_yaw -= delta.x * sensitivity * 1.5
	active_drone.drone_pitch = clampf(active_drone.drone_pitch - delta.y * sensitivity * 1.5, deg_to_rad(-45.0), deg_to_rad(45.0))
	return true

func update_controls() -> void:
	if not is_active():
		return
	var mobile_move: Vector2 = _player.get("mobile_move")
	var move_x := mobile_move.x
	var move_y := mobile_move.y
	move_x += float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	move_y += float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	active_drone.move_input = Vector2(move_x, move_y).limit_length(1.0)
	var vertical := vertical_input
	vertical += float(Input.is_key_pressed(KEY_SPACE)) - float(Input.is_key_pressed(KEY_CTRL))
	active_drone.vertical_input = clampf(vertical, -1.0, 1.0)

## Возвращает true, если событие поглощено управлением дроном.
func handle_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_V and str(_player.get("player_role")) == "RADIO_OPERATOR":
		toggle_launch()
		return true
	if not is_active():
		return false
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
	return true

func detonate() -> void:
	if is_active():
		active_drone.detonate(active_drone.global_position)

func return_to_operator() -> void:
	if is_active():
		active_drone.return_to_operator()

func _tether_length() -> float:
	match MatchState.map_name:
		"VILLAGE":
			return 105.0
		"POLYGON":
			return 55.0
		_:
			return 150.0
