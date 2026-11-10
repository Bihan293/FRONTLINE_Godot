extends Node
class_name FRONTLINEPlayerGrenades

## Гранаты игрока: F-1, дымовая, замах, выдёргивание чеки, бросок.
## Компонент владеет состоянием и viewmodel, игрок только вызывает API.

signal equipment_changed
signal sound_requested(stream: AudioStream, volume_db: float, pitch: float)

enum State { IDLE, EQUIP, PULL_PIN, HOLD_AIM, THROW_SWING, RECOVER }

const GRENADE_SCRIPT = preload("res://scripts/grenade.gd")
const SMOKE_SCRIPT = preload("res://scripts/smoke_grenade.gd")
const WEAPON_MESHES = preload("res://scripts/weapon_meshes.gd")
const SFX_RELOAD_OUT = preload("res://assets/audio/reload_out.ogg")
const SFX_RELOAD_IN = preload("res://assets/audio/reload_in.wav")

var state: State = State.IDLE
var grenade_count := 3
var smoke_count := 2
var is_held := false

var _payload := "frag"
var _view_payload := ""
var _timer := 0.0
var _has_spawned := false
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
	if payload == "smoke":
		if smoke_count <= 0:
			return
	elif grenade_count <= 0:
		return
	if _player == null:
		return
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")):
		return
	if bool(_player.get("is_healing")) or _player.get("active_drone") != null:
		return
	if bool(_player.get("is_reloading")) or bool(_player.get("is_vaulting")):
		return
	_payload = payload
	_ensure_view(payload)
	is_held = true
	if state == State.IDLE or state == State.RECOVER:
		state = State.EQUIP
		_timer = 0.12
		_has_spawned = false
		if _view_root != null:
			_view_root.visible = true
			_view_root.position = Vector3(0.20, -0.36, -0.32)
			_view_root.rotation = Vector3(deg_to_rad(-18.0), deg_to_rad(-10.0), 0.0)
			if _pull_ring != null:
				_pull_ring.position = Vector3(-0.035, 0.0, 0.0)
				_pull_ring.visible = true
			if _safety_lever != null:
				_safety_lever.rotation = Vector3.ZERO
				_safety_lever.visible = true
			if _hand_left != null:
				_hand_left.visible = true
				_hand_left.position.x = -0.075
		sound_requested.emit(SFX_RELOAD_OUT, -8.0, 1.35)

func release_throw() -> void:
	is_held = false
	if state == State.HOLD_AIM:
		state = State.THROW_SWING
		_timer = 0.26
		if _player != null:
			sound_requested.emit(SFX_RELOAD_IN, -2.0, 1.45)

func throw_grenade() -> void:
	if grenade_count <= 0 or _player == null or bool(_player.get("is_dead")):
		return
	if state == State.IDLE:
		start_hold()
		release_throw()

func throw_smoke() -> void:
	if smoke_count <= 0 or _player == null or bool(_player.get("is_dead")):
		return
	if bool(_player.get("input_locked")):
		return
	if state == State.IDLE:
		start_hold("smoke")
		release_throw()

func tick(delta: float) -> void:
	if state == State.IDLE:
		if _view_root != null and _view_root.visible:
			_view_root.visible = false
		if _weapon_root != null and not _weapon_root.visible and not bool(_player.get("is_dead")) and not bool(_player.get("is_shovel_equipped")):
			_weapon_root.visible = true
		return

	if _weapon_root != null:
		_weapon_root.visible = false
		var base_y: float = (_player.get("weapon_base") as Vector3).y
		_weapon_root.position.y = lerpf(_weapon_root.position.y, base_y - 0.28, delta * 14.0)

	_timer -= delta
	match state:
		State.EQUIP:
			if _view_root != null:
				_view_root.position = _view_root.position.lerp(Vector3(0.18, -0.14, -0.36), delta * 18.0)
				_view_root.rotation.x = lerpf(_view_root.rotation.x, deg_to_rad(6.0), delta * 18.0)
			if _timer <= 0.0:
				state = State.PULL_PIN
				_timer = 0.16
				sound_requested.emit(SFX_RELOAD_IN, -4.0, 1.55)
		State.PULL_PIN:
			var progress := 1.0 - clampf(_timer / 0.16, 0.0, 1.0)
			if _pull_ring != null:
				_pull_ring.position.x = lerpf(-0.035, -0.16, progress)
			if _hand_left != null:
				_hand_left.position.x = lerpf(-0.075, -0.22, progress)
			if _timer <= 0.0:
				if _pull_ring != null:
					_pull_ring.visible = false
				if _hand_left != null:
					_hand_left.visible = false
				if is_held:
					state = State.HOLD_AIM
				else:
					state = State.THROW_SWING
					_timer = 0.26
		State.HOLD_AIM:
			if _view_root != null:
				_view_root.position = _view_root.position.lerp(Vector3(0.24, -0.09, -0.30), delta * 16.0)
				_view_root.rotation = _view_root.rotation.lerp(Vector3(deg_to_rad(28.0), deg_to_rad(-16.0), deg_to_rad(12.0)), delta * 16.0)
			if not is_held:
				state = State.THROW_SWING
				_timer = 0.18
		State.THROW_SWING:
			var swing := 1.0 - clampf(_timer / 0.26, 0.0, 1.0)
			if _view_root != null:
				_view_root.position = _view_root.position.lerp(Vector3(0.06, -0.12, -0.62), delta * 26.0)
				_view_root.rotation = _view_root.rotation.lerp(Vector3(deg_to_rad(-38.0), deg_to_rad(10.0), deg_to_rad(-14.0)), delta * 26.0)
			if swing >= 0.72 and not _has_spawned:
				_spawn_thrown_grenade()
			if _timer <= 0.0:
				state = State.RECOVER
				_timer = 0.20
				if _view_root != null:
					_view_root.visible = false
		State.RECOVER:
			if _timer <= 0.0:
				state = State.IDLE

func reset() -> void:
	state = State.IDLE
	is_held = false
	_timer = 0.0
	_has_spawned = false
	if _view_root != null:
		_view_root.visible = false
	if _player != null and _player.get("is_dead") != true and not bool(_player.get("is_shovel_equipped")):
		if _weapon_root != null:
			_weapon_root.visible = true

func drop_on_death() -> void:
	if is_held and not _has_spawned and grenade_count > 0:
		_spawn_thrown_grenade()
	reset()

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
		var direction := -_camera.global_transform.basis.z + Vector3.UP * 0.20
		smoke.position = _throw_origin()
		smoke.linear_velocity = direction.normalized() * 13.5 + (_player.velocity * 0.4)
		smoke.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
		smoke.thrower_name = "Player"
		parent.add_child(smoke)
		sound_requested.emit(SFX_RELOAD_OUT, -3.0, 1.4)
		if _safety_lever != null:
			_safety_lever.visible = false
		_hide_view_after_throw()
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
		var direction := -_camera.global_transform.basis.z + Vector3.UP * 0.20
		grenade.position = _throw_origin()
		grenade.linear_velocity = direction.normalized() * 14.5 + (_player.velocity * 0.45)
	grenade.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-12.0, 12.0), randf_range(-8.0, 8.0))
	grenade.thrower_name = "Player"
	grenade.team_name = MatchState.player_team
	parent.add_child(grenade)
	sound_requested.emit(SFX_RELOAD_OUT, -3.0, 1.4)
	if _safety_lever != null:
		_safety_lever.visible = false
	_hide_view_after_throw()

func _throw_origin() -> Vector3:
	if _view_root != null and is_instance_valid(_view_root):
		return _view_root.global_position
	return _camera.global_position + _camera.global_transform.basis.x * 0.24 - _camera.global_transform.basis.y * 0.34 - _camera.global_transform.basis.z * 0.48

func _hide_view_after_throw() -> void:
	if _view_root != null:
		_view_root.visible = false

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
	_view_root.position = Vector3(0.18, -0.16, -0.38)
	_view_root.scale = Vector3.ONE * 0.72
	_view_root.visible = false
	_camera.add_child(_view_root)
	_safety_lever = _view_root.find_child("SafetyLever", true, false)
	_pull_ring = _view_root.find_child("PullRing", true, false)
	_hand_left = _view_root.find_child("HandLeft", true, false)
	_hand_right = _view_root.find_child("HandRight", true, false)
