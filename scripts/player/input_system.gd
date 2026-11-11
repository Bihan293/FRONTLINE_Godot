extends RefCounted
class_name FRONTLINEPlayerInput

## Ввод игрока: клавиатура/мышь, мобильные контролы, обзор и действия.
## Компонент переводит события в вызовы player-а, не владея оружием и камерой.

const MOBILE_CONTROLS = preload("res://scripts/mobile_controls.gd")
const MOUSE_SENS := 0.0022
const TOUCH_SENS := 0.0030

var mobile_controls: MobileControls
var mobile_move := Vector2.ZERO

var _player: CharacterBody3D

func setup(player: CharacterBody3D) -> void:
	_player = player

func build_mobile_controls() -> void:
	if not (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()):
		return
	var layer := CanvasLayer.new()
	layer.layer = 20
	_player.add_child(layer)
	mobile_controls = MOBILE_CONTROLS.new()
	layer.add_child(mobile_controls)
	mobile_controls.move_changed.connect(_on_move_changed)
	mobile_controls.look_delta.connect(_on_look_delta)
	mobile_controls.fire_changed.connect(_on_fire_changed)
	mobile_controls.aim_changed.connect(func(value: bool): _player.call("_set_aiming", value))
	mobile_controls.reload_pressed.connect(func(): _player.call("_reload"))
	mobile_controls.stance_down_pressed.connect(func(): _player.call("_down_action"))
	mobile_controls.stance_up_pressed.connect(func(): _player.call("_up_action"))
	if mobile_controls.has_signal("grenade_changed"):
		mobile_controls.grenade_changed.connect(_on_grenade_changed)
	else:
		mobile_controls.grenade_pressed.connect(func(): _player.call("_throw_grenade"))
	mobile_controls.smoke_pressed.connect(func(): _player.call("_throw_smoke"))
	mobile_controls.heal_pressed.connect(func(): _player.call("_use_heal"))
	if mobile_controls.has_signal("heal_released"):
		mobile_controls.heal_released.connect(func(): _player.call("_on_heal_released"))
	mobile_controls.peek_left_changed.connect(_on_peek_left)
	mobile_controls.peek_right_changed.connect(_on_peek_right)
	mobile_controls.cycle_weapon_pressed.connect(func(): _player.call("_cycle_weapon", 1))
	if mobile_controls.has_signal("equip_prev_pressed"):
		mobile_controls.equip_prev_pressed.connect(func(): _player.call("_cycle_equipment", -1))
	if mobile_controls.has_signal("equip_next_pressed"):
		mobile_controls.equip_next_pressed.connect(func(): _player.call("_cycle_equipment", 1))
	if mobile_controls.has_signal("sidearm_pressed"):
		mobile_controls.sidearm_pressed.connect(func(): _player.call("_toggle_sidearm"))
	if mobile_controls.has_signal("shovel_pressed"):
		mobile_controls.shovel_pressed.connect(func(): _player.call("_on_shovel_button"))
	mobile_controls.interact_pressed.connect(func(): _player.call("_interact_with_pickup"))
	if mobile_controls.has_signal("drone_pressed"):
		mobile_controls.drone_pressed.connect(func(): _player.call("_launch_drone"))
	if mobile_controls.has_signal("drone_vertical_changed"):
		mobile_controls.drone_vertical_changed.connect(func(direction: float, pressed: bool): _player.call("_on_drone_vertical_changed", direction, pressed))
	if str(_player.get("player_role")) == "RADIO_OPERATOR":
		mobile_controls.set_drone_visible(true)

func handle(event: InputEvent) -> void:
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")):
		return
	var mounted = _player.get("mounted_vehicle")
	if mounted != null and is_instance_valid(mounted):
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var sense := MOUSE_SENS * GameSettings.sensitivity_scale(false)
			_set_yaw(float(_player.get("yaw")) - event.relative.x * sense)
			var mount_pitch_delta: float = event.relative.y * sense
			if GameSettings.invert_y:
				mount_pitch_delta = -mount_pitch_delta
			_set_pitch(clampf(float(_player.get("pitch")) - mount_pitch_delta, -1.35, 1.35))
			_add_look_sway(Vector2(event.relative.x, event.relative.y) * 0.00006, 0.035)
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_F:
				_player.call("_exit_vehicle")
			elif event.keycode == KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	var vehicles = _player.get("_vehicles")
	if vehicles != null:
		var vehicle = vehicles.get("vehicle")
		if vehicle != null and not is_instance_valid(vehicle):
			vehicles.set("vehicle", null)
	if event is InputEventKey and not event.pressed and event.keycode == KEY_H:
		var healing = _player.get("_healing")
		if healing != null:
			healing.call("release_hold")
		return
	var drone = _player.get("_drone")
	if drone != null and bool(drone.call("handle_input", event)):
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var camera: Camera3D = _player.get("camera")
		var zoom_factor := (camera.fov / GameSettings.fov) if camera != null else 1.0
		var sense := MOUSE_SENS * GameSettings.sensitivity_scale(bool(_player.get("aiming"))) * zoom_factor
		_set_yaw(float(_player.get("yaw")) - event.relative.x * sense)
		var pitch_delta: float = event.relative.y * sense
		if GameSettings.invert_y:
			pitch_delta = -pitch_delta
		_set_pitch(clampf(float(_player.get("pitch")) - pitch_delta, -1.35, 1.35))
		_add_look_sway(Vector2(event.relative.x, event.relative.y) * 0.00035, 0.045)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not OS.has_feature("mobile"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			_player.call("_shoot")
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if bool(_player.get("is_shovel_equipped")):
			_player.call("_use_shovel_action", true)
		else:
			_player.call("_set_aiming", not bool(_player.get("aiming")))
	elif event is InputEventMouseButton and event.pressed and not OS.has_feature("mobile"):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_player.call("_cycle_weapon", -1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_player.call("_cycle_weapon", 1)
	elif event is InputEventKey:
		if event.keycode == KEY_G:
			if event.pressed and not event.echo:
				_player.call("_start_grenade_hold")
			elif not event.pressed:
				_player.call("_release_grenade_throw")
			return
		if not event.pressed or event.echo:
			return
		if event.keycode == KEY_9:
			_player.call("_toggle_sidearm")
		elif event.keycode == KEY_0 or event.keycode == KEY_B:
			_player.call("_toggle_shovel")
		elif event.keycode == KEY_R:
			_player.call("_reload")
		elif event.keycode == KEY_C:
			_player.call("_down_action")
		elif event.keycode == KEY_SPACE:
			_player.call("_up_action")
		elif event.keycode == KEY_X or event.keycode == KEY_T:
			_player.call("_throw_smoke")
		elif event.keycode == KEY_H:
			_player.call("_use_heal")
		elif event.keycode >= KEY_1 and event.keycode <= KEY_8:
			_player.call("_select_weapon_slot", event.keycode - KEY_1)
		elif event.keycode == KEY_F:
			_player.call("_interact_with_pickup")
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func preview_look(delta: Vector2) -> void:
	_on_look_delta(delta)

func _on_move_changed(value: Vector2) -> void:
	mobile_move = value

func _on_look_delta(delta: Vector2) -> void:
	if bool(_player.get("is_dead")):
		return
	var drone = _player.get("_drone")
	if drone != null and bool(drone.call("look_delta", delta, TOUCH_SENS)):
		return
	var mounted = _player.get("mounted_vehicle")
	if mounted != null and is_instance_valid(mounted):
		var turret_sense := TOUCH_SENS * 0.62 * GameSettings.sensitivity_scale(false)
		_set_yaw(float(_player.get("yaw")) - delta.x * turret_sense)
		var mount_touch_pitch := delta.y * turret_sense
		if GameSettings.invert_y:
			mount_touch_pitch = -mount_touch_pitch
		_set_pitch(clampf(float(_player.get("pitch")) - mount_touch_pitch, -1.35, 1.35))
		return
	var camera: Camera3D = _player.get("camera")
	var zoom_factor := (camera.fov / GameSettings.fov) if camera != null else 1.0
	var mount_factor := 0.62 if (mounted != null and is_instance_valid(mounted)) else 1.0
	var sense := TOUCH_SENS * GameSettings.sensitivity_scale(bool(_player.get("aiming"))) * zoom_factor * mount_factor
	_set_yaw(float(_player.get("yaw")) - delta.x * sense)
	var pitch_delta := delta.y * sense
	if GameSettings.invert_y:
		pitch_delta = -pitch_delta
	_set_pitch(clampf(float(_player.get("pitch")) - pitch_delta, -1.35, 1.35))
	_add_look_sway(Vector2(delta.x, delta.y) * 0.00035, 0.045)

func _on_fire_changed(pressed: bool) -> void:
	_player.set("mobile_fire", pressed)
	if pressed:
		_player.call("_cancel_healing")
		var drone = _player.get("_drone")
		if drone != null:
			drone.call("detonate")

func _on_peek_left(pressed: bool) -> void:
	if pressed:
		_player.call("_on_mobile_peek_left", true)

func _on_peek_right(pressed: bool) -> void:
	if pressed:
		_player.call("_on_mobile_peek_right", true)

func _on_grenade_changed(pressed: bool) -> void:
	_player.call("_on_mobile_grenade_changed", pressed)

func _set_yaw(value: float) -> void:
	_player.set("yaw", value)

func _set_pitch(value: float) -> void:
	_player.set("pitch", value)

func _add_look_sway(delta: Vector2, limit: float) -> void:
	var sway: Vector2 = _player.get("look_sway") + delta
	_player.set("look_sway", sway.limit_length(limit))
