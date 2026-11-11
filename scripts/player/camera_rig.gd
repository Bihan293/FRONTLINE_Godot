extends RefCounted
class_name FRONTLINEPlayerCameraRig

## Камера от первого лица: bodycam-лаг, тряска, FOV, наклон и позиция.
## Компонент владеет Camera3D и AudioListener3D, игрок — вводом и оружием.

const WALK_SPEED := 5.2
const SPRINT_SPEED := 7.4
const WORLD_LAYER_MASK := 1 << 0

var camera: Camera3D
var audio_listener: AudioListener3D
var cam_yaw := 0.0
var cam_pitch := 0.0
var cam_shake_trauma := 0.0
var lean_amount := 0.0
var lean_toggle := 0 # -1: влево, 0: центр, 1: вправо

var _last_applied_yaw := 0.0
var _last_key_q := false
var _last_key_e := false
var _player: CharacterBody3D

func setup(player: CharacterBody3D) -> void:
	_player = player
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.70, -0.08) # Нательное крепление бодикамеры
	camera.fov = GameSettings.fov
	# Low-пресет: дальний план 170 м — меньше vertices/overdraw.
	camera.far = GameSettings.view_distance()
	camera.current = true
	_player.add_child(camera)
	audio_listener = AudioListener3D.new()
	audio_listener.name = "PlayerAudioListener"
	camera.add_child(audio_listener)
	audio_listener.make_current()
	cam_yaw = float(_player.get("yaw"))
	cam_pitch = float(_player.get("pitch"))
	_last_applied_yaw = cam_yaw
	apply_look()

func toggle_lean(side: int) -> void:
	if side < 0:
		lean_toggle = 0 if lean_toggle == -1 else -1
	else:
		lean_toggle = 0 if lean_toggle == 1 else 1

func update_fov(delta: float) -> void:
	if camera == null:
		return
	var target_fov := GameSettings.fov
	if bool(_player.get("aiming")):
		var weapons = _player.get("_weapons")
		var weapon = weapons.call("current_def")
		var weapon_id := str(weapon.id)
		if weapon_id == "kar98k":
			target_fov *= 0.38
		elif weapon_id == "mosin":
			target_fov *= 0.58
		else:
			target_fov *= 0.78
	camera.fov = lerpf(camera.fov, target_fov, clampf(delta * 9.0, 0.0, 1.0))

func process_lean_and_position(delta: float, planar_speed: float, current_speed: float) -> void:
	var stance := int(_player.get("stance"))
	var aiming := bool(_player.get("aiming"))
	var key_q := Input.is_key_pressed(KEY_Q)
	var key_e := Input.is_key_pressed(KEY_E)
	if key_q and not _last_key_q:
		toggle_lean(-1)
	if key_e and not _last_key_e:
		toggle_lean(1)
	_last_key_q = key_q
	_last_key_e = key_e
	if bool(_player.get("is_vaulting")) or planar_speed > WALK_SPEED + 0.4 or current_speed >= SPRINT_SPEED - 0.1:
		lean_toggle = 0

	var target_y := 1.70 if stance == 0 else (1.28 if stance == 1 else 0.52)
	var landing_anim := float(_player.get("landing_anim"))
	var sprint_anim := float(_player.get("sprint_anim"))
	var bob_time := float(_player.get("bob_time"))
	var run_boost := 1.0 + sprint_anim * 0.9
	var bob_factor := 0.20 if aiming else 1.0
	var cam_bob_y := absf(sin(bob_time * 2.0)) * 0.014 * run_boost * bob_factor
	var cam_bob_x := sin(bob_time) * 0.010 * run_boost * bob_factor

	var lean_side := float(lean_toggle) * 0.42
	if absf(lean_side) > 0.01:
		var lean_from := _player.global_position + Vector3.UP * target_y
		var lean_to := lean_from + _player.transform.basis.x * lean_side
		var lean_query := PhysicsRayQueryParameters3D.create(lean_from, lean_to)
		lean_query.collision_mask = WORLD_LAYER_MASK
		lean_query.exclude = [_player]
		lean_query.collide_with_areas = false
		var lean_hit := _player.get_world_3d().direct_space_state.intersect_ray(lean_query)
		if lean_hit:
			var available := maxf(0.0, lean_from.distance_to(lean_hit.position) - 0.12)
			lean_side = signf(lean_side) * minf(absf(lean_side), available)
	var lean_target := lean_side / 0.42
	lean_amount = lerpf(lean_amount, lean_target, clampf(delta * 12.0, 0.0, 1.0))
	camera.position.y = lerpf(camera.position.y, target_y + cam_bob_y - landing_anim * 0.09, delta * 12.0)
	camera.position.x = lerpf(camera.position.x, cam_bob_x + lean_amount * 0.42, delta * 12.0)

func apply_look(delta: float = 0.016) -> void:
	var yaw := float(_player.get("yaw"))
	var pitch := float(_player.get("pitch"))
	var recoil: Vector2 = _player.get("recoil")
	var aiming := bool(_player.get("aiming"))
	var aim_blend := float(_player.get("aim_blend"))
	_player.rotation.y = yaw
	var mobile_move: Vector2 = _player.get("mobile_move")
	var strafe_roll := -mobile_move.x * deg_to_rad(2.2) if not aiming else 0.0

	# Инерция и упругий лаг нательной камеры (Bodycam)
	var cam_lag_speed := lerpf(16.0, 38.0, aim_blend)
	cam_yaw = lerp_angle(cam_yaw, yaw, clampf(delta * cam_lag_speed, 0.0, 1.0))
	cam_pitch = lerpf(cam_pitch, pitch, clampf(delta * cam_lag_speed, 0.0, 1.0))
	var yaw_diff := wrapf(cam_yaw - yaw, -PI, PI)
	var yaw_speed := (yaw - _last_applied_yaw) / maxf(delta, 0.001)
	_last_applied_yaw = yaw
	var turn_roll := clampf(-yaw_speed * 0.010, -deg_to_rad(3.5), deg_to_rad(3.5)) * (1.0 - aim_blend * 0.85)

	cam_shake_trauma = maxf(0.0, cam_shake_trauma - delta * 4.2)
	var shake_mag := cam_shake_trauma * cam_shake_trauma
	var shake_rot := Vector3(
		randf_range(-1.0, 1.0) * deg_to_rad(2.2) * shake_mag,
		randf_range(-1.0, 1.0) * deg_to_rad(1.8) * shake_mag,
		randf_range(-1.0, 1.0) * deg_to_rad(2.5) * shake_mag
	)

	var run_boost := 1.0 + float(_player.get("sprint_anim")) * 0.9
	var bob_factor := 0.20 if aiming else 1.0
	var cam_bob_roll := cos(float(_player.get("bob_time"))) * deg_to_rad(1.3 * run_boost) * bob_factor if not aiming else 0.0
	var total_roll := -lean_amount * deg_to_rad(9.5) + strafe_roll + turn_roll + cam_bob_roll + shake_rot.z
	camera.rotation = Vector3(
		clampf(cam_pitch + recoil.y - float(_player.get("landing_anim")) * deg_to_rad(3.5) + shake_rot.x, -1.45, 1.45),
		yaw_diff * 0.65 + recoil.x + shake_rot.y,
		total_roll
	)

func add_trauma(amount: float) -> void:
	cam_shake_trauma = clampf(cam_shake_trauma + amount, 0.0, 1.0)

func apply_explosion_shake(explosion_pos: Vector3, radius: float = 32.0, max_trauma: float = 0.95) -> void:
	var distance := _player.global_position.distance_to(explosion_pos)
	if distance >= radius:
		return
	var factor := 1.0 - (distance / radius)
	add_trauma(factor * max_trauma)
	var recoil: Vector2 = _player.get("recoil")
	recoil.y += factor * 0.08
	recoil.x += randf_range(-factor, factor) * 0.06
	_player.set("recoil", recoil)
