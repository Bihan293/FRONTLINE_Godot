extends Node
class_name FRONTLINEPlayerGrenades

## Гранаты игрока: опускание оружия, взятие гранаты, выдёргивание чеки,
## удержание и бросок. Руки — общие IK-руки игрока, без отдельных моделей.

signal equipment_changed
signal sound_requested(stream: AudioStream, volume_db: float, pitch: float)

enum State { IDLE, LOWER, RAISE, HOLD_PIN, PULL_PIN, HOLD_ARMED, THROW, RECOVER }

const GRENADE_SCRIPT = preload("res://scripts/grenade.gd")
const SMOKE_SCRIPT = preload("res://scripts/smoke_grenade.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const SFX_RELOAD_OUT = preload("res://assets/audio/reload_out.ogg")
const SFX_RELOAD_IN = preload("res://assets/audio/reload_in.wav")

const LOWER_TIME := 0.24
const RAISE_TIME := 0.42
const PIN_TIME := 0.55
const THROW_TIME := 0.34
const RECOVER_TIME := 0.42
const WEAPON_LOWER := 0.26

const HOLD_GRENADE_POS := Vector3(0.0, -0.24, -0.63)
const LOW_GRENADE_POS := Vector3(0.12, -0.44, -0.58)
const THROW_GRENADE_POS := Vector3(0.0, -0.12, -0.95)
const LOW_LEFT := Vector3(-0.18, -0.45, -0.60)
const LOW_RIGHT := Vector3(0.18, -0.43, -0.61)
const HOLD_LEFT := Vector3(-0.035, -0.17, -0.69)
const HOLD_RIGHT := Vector3(0.085, -0.28, -0.69)
const PULL_LEFT := Vector3(-0.21, -0.05, -0.64)
const BRACE_LEFT := Vector3(-0.10, -0.32, -0.70)
const THROW_LEFT := Vector3(-0.08, -0.30, -0.84)
const THROW_RIGHT := Vector3(0.03, -0.13, -0.90)

var state: State = State.IDLE
var grenade_count := 3
var smoke_count := 2
var is_held := false

var _payload := "frag"
var _view_payload := ""
var _timer := 0.0
var _duration := 0.0
var _throw_after_pin := false
var _has_spawned := false
var _action_active := false
var _idle_time := 0.0
var _player: CharacterBody3D
var _camera: Camera3D
var _weapon_root: Node3D
var _view_root: Node3D
var _pull_ring: Node3D
var _safety_lever: Node3D
var _hand_left: Node3D
var _hand_right: Node3D

func setup(player: CharacterBody3D, camera: Camera3D, weapon_root: Node3D) -> void:
	_player = player
	_camera = camera
	_weapon_root = weapon_root
	_ensure_view(_payload)

func is_busy() -> bool:
	return state != State.IDLE

func is_holding() -> bool:
	return is_held

func start_hold(payload: String = "frag") -> void:
	if _player == null or bool(_player.get("is_dead")) or bool(_player.get("input_locked")):
		return
	if bool(_player.get("is_healing")) or _player.get("active_drone") != null:
		return
	if bool(_player.get("is_reloading")) or bool(_player.get("is_vaulting")):
		return
	if state == State.HOLD_PIN:
		_begin_pin_pull()
		return
	if state == State.HOLD_ARMED:
		_begin_throw()
		return
	if state != State.IDLE:
		return
	if payload == "smoke":
		if smoke_count <= 0:
			return
	elif grenade_count <= 0:
		return
	_player.call("_set_aiming", false)
	var weapon_root = _player.get("weapon_root")
	if weapon_root != null:
		weapon_root.visible = true
	_payload = payload
	_ensure_view(payload)
	is_held = true
	_throw_after_pin = false
	_has_spawned = false
	_action_active = true
	_idle_time = 0.0
	state = State.LOWER
	_timer = LOWER_TIME
	_duration = LOWER_TIME
	_player.call("_set_weapon_mesh_visible", true)
	_player.call("_set_weapon_action_offset", Vector3.ZERO)
	if _view_root != null:
		_view_root.visible = false
	sound_requested.emit(SFX_RELOAD_OUT, -8.0, 1.30)

func release_throw() -> void:
	if state == State.PULL_PIN:
		_throw_after_pin = true
	elif state == State.HOLD_ARMED:
		_begin_throw()

func throw_grenade() -> void:
	if state == State.IDLE:
		start_hold("frag")
	release_throw()

func throw_smoke() -> void:
	if state == State.IDLE:
		start_hold("smoke")
	release_throw()

func tick(delta: float) -> void:
	if state == State.IDLE:
		if _action_active:
			_finish_action()
		return
	_action_active = true
	match state:
		State.LOWER:
			_tick_lower(delta)
		State.RAISE:
			_tick_raise(delta)
		State.HOLD_PIN:
			_tick_hold_pin(delta)
		State.PULL_PIN:
			_tick_pull_pin(delta)
		State.HOLD_ARMED:
			_tick_hold_armed(delta)
		State.THROW:
			_tick_throw(delta)
		State.RECOVER:
			_tick_recover(delta)

func reset() -> void:
	state = State.IDLE
	is_held = false
	_timer = 0.0
	_duration = 0.0
	_throw_after_pin = false
	_has_spawned = false
	_action_active = false
	_idle_time = 0.0
	if _view_root != null and is_instance_valid(_view_root):
		_view_root.visible = false
	if _player != null:
		_player.call("_clear_action_hands")
		_player.call("_set_weapon_mesh_visible", true)
		_player.call("_set_weapon_action_offset", Vector3.ZERO)
		if _weapon_root != null and not bool(_player.get("is_dead")) and not bool(_player.get("is_shovel_equipped")):
			_weapon_root.visible = true

func drop_on_death() -> void:
	if is_held and not _has_spawned and grenade_count > 0:
		_spawn_thrown_grenade()
	reset()

func _tick_lower(delta: float) -> void:
	_timer -= delta
	var progress := _ease(1.0 - clampf(_timer / maxf(0.01, _duration), 0.0, 1.0))
	_player.call("_set_weapon_action_offset", Vector3(0.0, -WEAPON_LOWER * progress, 0.0))
	if _timer > 0.0:
		return
	if _view_root == null:
		state = State.RECOVER
		_timer = RECOVER_TIME
		_duration = RECOVER_TIME
		return
	_player.call("_set_weapon_mesh_visible", false)
	_view_root.visible = true
	_place_grenade(LOW_GRENADE_POS, LOW_LEFT, LOW_RIGHT)
	state = State.RAISE
	_timer = RAISE_TIME
	_duration = RAISE_TIME
	sound_requested.emit(SFX_RELOAD_IN, -7.0, 1.15)

func _tick_raise(delta: float) -> void:
	_timer -= delta
	var progress := _ease(1.0 - clampf(_timer / maxf(0.01, _duration), 0.0, 1.0))
	var grenade_pos := LOW_GRENADE_POS.lerp(HOLD_GRENADE_POS, progress)
	var left := LOW_LEFT.lerp(HOLD_LEFT, progress)
	var right := LOW_RIGHT.lerp(HOLD_RIGHT, progress)
	_place_grenade(grenade_pos, left, right)
	if _timer <= 0.0:
		state = State.HOLD_PIN
		_idle_time = 0.0
		if _pull_ring != null:
			_pull_ring.visible = true
		if _safety_lever != null:
			_safety_lever.visible = true

func _tick_hold_pin(delta: float) -> void:
	_idle_time += delta
	var sway := sin(_idle_time * 1.8) * 0.0025
	_place_grenade(HOLD_GRENADE_POS + Vector3(0.0, sway, 0.0), HOLD_LEFT, HOLD_RIGHT)

func _tick_pull_pin(delta: float) -> void:
	_timer -= delta
	var progress := _ease(1.0 - clampf(_timer / maxf(0.01, _duration), 0.0, 1.0))
	var left := HOLD_LEFT.lerp(PULL_LEFT, progress)
	_place_grenade(HOLD_GRENADE_POS, left, HOLD_RIGHT)
	if _pull_ring != null:
		_pull_ring.position.x = lerpf(-0.035, -0.105, progress)
	if _timer > 0.0:
		return
	if _pull_ring != null:
		_pull_ring.visible = false
	if _throw_after_pin:
		_begin_throw()
	else:
		state = State.HOLD_ARMED
		_idle_time = 0.0

func _tick_hold_armed(delta: float) -> void:
	_idle_time += delta
	var sway := sin(_idle_time * 2.2) * 0.002
	_place_grenade(HOLD_GRENADE_POS + Vector3(0.0, sway, 0.0), BRACE_LEFT, HOLD_RIGHT)

func _tick_throw(delta: float) -> void:
	_timer -= delta
	var progress := _ease(1.0 - clampf(_timer / maxf(0.01, _duration), 0.0, 1.0))
	var grenade_pos := HOLD_GRENADE_POS.lerp(THROW_GRENADE_POS, progress)
	var left := BRACE_LEFT.lerp(THROW_LEFT, progress)
	var right := HOLD_RIGHT.lerp(THROW_RIGHT, progress)
	_place_grenade(grenade_pos, left, right)
	if progress >= 0.58 and not _has_spawned:
		_spawn_thrown_grenade()
	if _timer > 0.0:
		return
	if _view_root != null:
		_view_root.visible = false
	_player.call("_clear_action_hands")
	_player.call("_set_weapon_mesh_visible", true)
	state = State.RECOVER
	_timer = RECOVER_TIME
	_duration = RECOVER_TIME

func _tick_recover(delta: float) -> void:
	_timer -= delta
	var progress := _ease(1.0 - clampf(_timer / maxf(0.01, _duration), 0.0, 1.0))
	_player.call("_set_weapon_action_offset", Vector3(0.0, -WEAPON_LOWER * (1.0 - progress), 0.0))
	if _timer <= 0.0:
		state = State.IDLE
		is_held = false
		_action_active = false
		_player.call("_set_weapon_action_offset", Vector3.ZERO)
		_player.call("_set_weapon_mesh_visible", true)
		_player.call("_clear_action_hands")
		_has_spawned = false

func _begin_pin_pull() -> void:
	if _player == null or bool(_player.get("is_dead")):
		return
	state = State.PULL_PIN
	_timer = PIN_TIME
	_duration = PIN_TIME
	_idle_time = 0.0
	sound_requested.emit(SFX_RELOAD_IN, -5.0, 1.55)

func _begin_throw() -> void:
	if state == State.THROW:
		return
	state = State.THROW
	_timer = THROW_TIME
	_duration = THROW_TIME
	_throw_after_pin = false
	_has_spawned = false
	sound_requested.emit(SFX_RELOAD_IN, -2.0, 1.45)

func _finish_action() -> void:
	_action_active = false
	_player.call("_clear_action_hands")
	_player.call("_set_weapon_mesh_visible", true)
	_player.call("_set_weapon_action_offset", Vector3.ZERO)
	_player.call("_refresh_equipment")

func _spawn_thrown_grenade() -> void:
	if _has_spawned:
		return
	var parent := _player.get_parent()
	if parent == null:
		return
	if _payload == "smoke":
		if smoke_count <= 0:
			return
		_has_spawned = true
		smoke_count -= 1
		equipment_changed.emit()
		var smoke := SMOKE_SCRIPT.new()
		var direction := -_camera.global_transform.basis.z + Vector3.UP * 0.18
		smoke.position = _throw_origin()
		smoke.linear_velocity = direction.normalized() * 13.5 + (_player.velocity * 0.4)
		smoke.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
		smoke.thrower_name = "Player"
		parent.add_child(smoke)
		sound_requested.emit(SFX_RELOAD_OUT, -3.0, 1.4)
		if _safety_lever != null:
			_safety_lever.visible = false
		return
	if grenade_count <= 0:
		return
	_has_spawned = true
	grenade_count -= 1
	equipment_changed.emit()
	var grenade := GRENADE_SCRIPT.new()
	if bool(_player.get("is_dead")):
		grenade.position = _player.global_position + Vector3(0.0, 0.45, 0.0)
		grenade.linear_velocity = Vector3(randf_range(-0.6, 0.6), 1.2, randf_range(-0.6, 0.6))
	else:
		var direction := -_camera.global_transform.basis.z + Vector3.UP * 0.18
		grenade.position = _throw_origin()
		grenade.linear_velocity = direction.normalized() * 14.5 + (_player.velocity * 0.45)
	grenade.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
	grenade.thrower_name = "Player"
	grenade.team_name = MatchState.player_team
	parent.add_child(grenade)
	sound_requested.emit(SFX_RELOAD_OUT, -3.0, 1.4)
	if _safety_lever != null:
		_safety_lever.visible = false

func _throw_origin() -> Vector3:
	if _view_root != null and is_instance_valid(_view_root):
		return _view_root.global_position
	return _camera.global_position + _camera.global_transform.basis.x * 0.24 - _camera.global_transform.basis.y * 0.34 - _camera.global_transform.basis.z * 0.48

func _place_grenade(grenade_pos: Vector3, left_pos: Vector3, right_pos: Vector3) -> void:
	if _view_root == null:
		return
	_view_root.visible = true
	_view_root.position = grenade_pos
	_view_root.rotation = Vector3(deg_to_rad(12.0), deg_to_rad(-10.0), deg_to_rad(8.0))
	_player.call("_set_action_hands", _hand_xf(left_pos, true), _hand_xf(right_pos, false), true, true)

func _hand_xf(local_pos: Vector3, is_left: bool) -> Transform3D:
	var angles := Vector3(-26.0, 38.0, 6.0) if not is_left else Vector3(-26.0, -38.0, -6.0)
	var basis := Basis.from_euler(Vector3(deg_to_rad(angles.x), deg_to_rad(angles.y), deg_to_rad(angles.z)))
	return Transform3D(basis, local_pos)

func _ease(value: float) -> float:
	return smoothstep(0.0, 1.0, value)

func _ensure_view(payload: String) -> void:
	if _view_root != null and is_instance_valid(_view_root) and _view_payload == payload:
		return
	if _view_root != null and is_instance_valid(_view_root):
		_view_root.queue_free()
	_view_root = WEAPON_MESHES.make_smoke_view_model() if payload == "smoke" else WEAPON_MESHES.make_grenade_view_model()
	_view_payload = payload
	if _view_root == null or _camera == null:
		return
	_view_root.name = "GrenadeView"
	_view_root.position = LOW_GRENADE_POS
	_view_root.scale = Vector3.ONE * 1.35
	_view_root.visible = false
	_camera.add_child(_view_root)
	_safety_lever = _view_root.find_child("SafetyLever", true, false)
	_pull_ring = _view_root.find_child("PullRing", true, false)
	_hand_left = _view_root.find_child("HandLeft", true, false)
	_hand_right = _view_root.find_child("HandRight", true, false)
	# Руки теперь общие IK-руки игрока, а не тёмные боксы внутри viewmodel.
	if _hand_left != null:
		_hand_left.visible = false
	if _hand_right != null:
		_hand_right.visible = false
