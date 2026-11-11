extends RefCounted
class_name FRONTLINEPlayerLocomotion

## Движение игрока: ввод, спринт, вес оружия, гравитация, шаги и посадка.
## Компонент двигает тело, камера и наклон остаются в player.gd.

const SFX_FOOTSTEPS = [
	preload("res://assets/audio/footstep_000.ogg"),
	preload("res://assets/audio/footstep_001.ogg"),
	preload("res://assets/audio/footstep_002.ogg"),
]

var sprint_anim := 0.0
var landing_anim := 0.0
var bob_time := 0.0
var breathing_time := 0.0
var planar_speed := 0.0
var current_speed := 0.0
var on_floor := false

var _player: CharacterBody3D
var _walk_speed := 5.2
var _sprint_speed := 7.4
var _sprint_hold := 0.0
var _was_on_floor := true

func setup(player: CharacterBody3D, walk_speed: float, sprint_speed: float) -> void:
	_player = player
	_walk_speed = walk_speed
	_sprint_speed = sprint_speed

func process(delta: float) -> void:
	var input_vec: Vector2 = _player.get("mobile_move")
	input_vec.x += float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	input_vec.y += float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	input_vec = input_vec.limit_length(1.0)

	var stance := int(_player.get("stance"))
	if stance == 0 and input_vec.length() > 0.92:
		_sprint_hold += delta
	else:
		_sprint_hold = 0.0

	current_speed = _walk_speed
	if (Input.is_key_pressed(KEY_SHIFT) or _sprint_hold > 0.7) and stance == 0:
		current_speed = _sprint_speed
	if str(_player.get("player_role")) == "ASSAULT" and current_speed == _sprint_speed:
		current_speed *= 1.08
	if stance == 1:
		current_speed *= 0.55
	elif stance == 2:
		current_speed *= 0.25

	# Вес оружия и замедление при ранении (TASK-0006)
	var weapon_weight_factor := 1.0
	var weapons = _player.get("_weapons")
	if weapons != null:
		var weapon = weapons.call("current_def")
		match str(weapon.id):
			"m1911": weapon_weight_factor = 1.02
			"mp40", "ppsh41": weapon_weight_factor = 0.97
			"ak47", "shotgun": weapon_weight_factor = 0.94
			"mosin", "kar98k": weapon_weight_factor = 0.90
			"panzerfaust": weapon_weight_factor = 0.80

	if float(_player.get("health")) < 35.0:
		current_speed = minf(current_speed * 0.88, _walk_speed * 0.92)

	var direction := (_player.transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
	var target_vel := direction * (current_speed * weapon_weight_factor)
	var accel := 28.0 if direction.length_squared() > 0.01 else 20.0
	var velocity: Vector3 = _player.velocity
	velocity.x = move_toward(velocity.x, target_vel.x, accel * delta * current_speed)
	velocity.z = move_toward(velocity.z, target_vel.z, accel * delta * current_speed)
	if not _player.is_on_floor():
		velocity.y -= 18.0 * delta
	_player.velocity = velocity
	var fall_speed := velocity.y
	_player.move_and_slide()
	var vault = _player.get("_vault")
	if vault != null:
		vault.call("try_step_up")

	on_floor = _player.is_on_floor()
	if on_floor and not _was_on_floor and fall_speed < -3.0:
		landing_anim = 1.0
		_player.call("_play_sfx", _player.get("sfx_footstep"), SFX_FOOTSTEPS[0], -2.5, 0.74)
	_was_on_floor = on_floor
	landing_anim = maxf(0.0, landing_anim - delta * 5.0)

	planar_speed = Vector2(_player.velocity.x, _player.velocity.z).length()
	var sprint_target := 1.0 if (planar_speed > _walk_speed + 0.4 and not bool(_player.get("aiming")) and stance == 0 and on_floor) else 0.0
	sprint_anim = lerpf(sprint_anim, sprint_target, clampf(delta * 8.0, 0.0, 1.0))

	if planar_speed > 0.4 and on_floor:
		bob_time += delta * (11.0 if planar_speed > _walk_speed + 0.5 else 7.5)
		var audio = _player.get("_audio")
		if audio != null:
			audio.call("update_footsteps", delta, planar_speed, true, _walk_speed)
	else:
		bob_time = fposmod(bob_time, TAU)
		breathing_time += delta
