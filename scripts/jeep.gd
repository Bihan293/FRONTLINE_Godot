extends CharacterBody3D
class_name FRONTLINEJeep

## Армейский джип с аркадной физикой (TASK-0012).
## Один водитель, вход/выход по F. Управление: W/S — газ/тормоз,
## A/D — руль, на мобильных — тот же джойстик. Пули бьют кузов:
## HP, дым при повреждении, при уничтожении — взрыв и гибель водителя.

const SFX_EXPLOSION = preload("res://assets/audio/explosion.wav")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const VEHICLE_MESHES = preload("res://scripts/vehicle_meshes.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const WEAPON_SOUND = preload("res://scripts/weapon_sound_bank.gd")
const BULLET_SCRIPT = preload("res://scripts/bullet_projectile.gd")

const MAX_FORWARD_SPEED := 13.5
const MAX_REVERSE_SPEED := 5.5
const ACCEL := 8.5
const BRAKE_DECEL := 15.0
const DRAG_DECEL := 3.5
const TURN_RATE := 1.35
## Масштаб визуала Antigravity: Willys ~4.9 м, коллайдер совпадает с мешем.
const MODEL_SCALE := 1.45
const WHEEL_RADIUS := 0.34 * MODEL_SCALE
const GRAVITY := 18.0

const TURRET_INTERVAL := 0.09
const TURRET_DAMAGE := 24
const TURRET_RANGE := 170.0
const TURRET_BULLET_SPEED := 730.0
const TURRET_RAY_MASK := (1 << 0) | (1 << 1) | (1 << 2)

const MAX_HEALTH := 260.0

var team_name := "NEUTRAL"
var health := MAX_HEALTH
var destroyed := false
var driver: Node3D = null

# Тестовый крюк: принудительный ввод, чтобы дымить физику без клавиатуры.
var throttle_override := 0.0
var steer_override := 0.0

var _speed := 0.0
var _model_root: Node3D = null
var _wheels: Array[Node3D] = []
var _driver_marker: Marker3D
var _smoke: CPUParticles3D
var _fire_particles: CPUParticles3D
var _turret_yaw: Node3D
var _turret_pitch: Node3D
var _turret_muzzle: Marker3D
var _fire_cooldown := 0.0
var _turret_audio: AudioStreamPlayer3D
var _turret_flash: MeshInstance3D
var _turret_flash_time := 0.0

func _ready() -> void:
	add_to_group("enterable_vehicles")
	add_to_group("damageable")
	add_to_group("metal_targets")
	set_meta("owner_actor", self)
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.45
	_build_collision()
	_build_visuals()
	_build_seats()

## Камера водителя следует за корпусом джипа (см. player._process_mounted_vehicle).
func camera_follows_vehicle() -> bool:
	return true

func can_enter(player: Node3D) -> bool:
	if destroyed or driver != null or player == null:
		return false
	if bool(player.get("is_dead")):
		return false
	if player.get("mounted_vehicle") != null or player.get("active_drone") != null:
		return false
	return true

func prompt_text(mobile: bool) -> String:
	if not is_instance_valid(driver) or driver == null:
		return "СЕСТЬ В ДЖИП" if mobile else "F — СЕСТЬ В ДЖИП"
	return "ВЫЙТИ" if mobile else "F — ВЫЙТИ"

func enter(player: Node3D) -> void:
	if destroyed or driver != null:
		return
	driver = player
	if player is PhysicsBody3D:
		add_collision_exception_with(player)

func exit_vehicle(player: Node3D) -> void:
	if not is_instance_valid(driver) or player != driver:
		return
	driver = null
	if is_instance_valid(player) and player is PhysicsBody3D:
		remove_collision_exception_with(player)

func seat_position() -> Vector3:
	return _driver_marker.global_position if _driver_marker != null else global_position

func exit_position() -> Vector3:
	var origin := global_position + Vector3.UP * 0.9
	var candidates := [
		global_position - global_transform.basis.x * 1.35 * MODEL_SCALE,
		global_position + global_transform.basis.x * 1.35 * MODEL_SCALE,
		global_position + global_transform.basis.z * 2.0 * MODEL_SCALE
	]
	var space := get_world_3d().direct_space_state
	for candidate in candidates:
		var query := PhysicsRayQueryParameters3D.create(origin, candidate + Vector3.UP * 0.9)
		query.collision_mask = 1
		query.exclude = [get_rid()]
		query.collide_with_areas = false
		if space.intersect_ray(query).is_empty():
			return candidate + Vector3.UP * 0.2
	return global_position + Vector3.UP * 0.6

func driver_eye_height() -> float:
	# Высота глаз над сиденьем, без повторного умножения на MODEL_SCALE.
	return 0.85

func interaction_radius() -> float:
	return 4.4

func receive_hit(damage: int, attacker_pos: Vector3, region: String = "chest", attacker_name: String = "Unknown") -> int:
	if destroyed:
		return 0
	health -= float(damage)
	if health <= 0.0:
		_explode()
		return damage
	var world := get_parent()
	if is_instance_valid(world):
		HIT_EFFECTS.spawn_metal_sparks(world, attacker_pos, Vector3.UP)
	if _smoke != null and health < MAX_HEALTH * 0.55:
		_smoke.emitting = true
	return damage

func _explode() -> void:
	if destroyed:
		return
	destroyed = true
	_speed = 0.0
	var pos := global_position + Vector3(0, 0.8, 0)
	if is_instance_valid(get_parent()):
		COMBAT_AUDIO.play_explosion_3d(get_parent(), pos, SFX_EXPLOSION, 30.0, 280.0, 1.0)
	_spawn_wreck_visuals()
	if _smoke != null:
		_smoke.emitting = true
	if _fire_particles != null:
		_fire_particles.emitting = true
	if is_instance_valid(driver) and driver.has_method("receive_hit"):
		driver.call("receive_hit", 500, global_position, "chest", "Джип взорвался")
	if is_instance_valid(driver):
		exit_vehicle(driver)

func _spawn_wreck_visuals() -> void:
	if _model_root == null:
		return
	var charred := StandardMaterial3D.new()
	charred.albedo_color = Color(0.09, 0.08, 0.08)
	charred.roughness = 1.0
	for mesh_inst in _model_root.find_children("*", "MeshInstance3D", true, false):
		mesh_inst.material_override = charred

## Мобильная оптимизация (TASK-0019): мелкие детали модели исчезают
## дальше 45 м, средние — дальше 90 м; несущие формы остаются всегда.
## Экономит десятки draw calls на технику вдали от игрока (llvmpipe,
## замер честно невозможен — оптимизация по числу частей).
func _apply_lod(root: Node3D) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := node as MeshInstance3D
		if mesh_inst == null or mesh_inst.mesh == null:
			continue
		var diagonal: float = mesh_inst.mesh.get_aabb().size.length()
		if diagonal < 0.45:
			mesh_inst.visibility_range_end = 45.0
			mesh_inst.visibility_range_end_margin = 6.0
		elif diagonal < 1.05:
			mesh_inst.visibility_range_end = 90.0
			mesh_inst.visibility_range_end_margin = 10.0

func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.62, 0.85, 3.72) * MODEL_SCALE
	shape.shape = box
	shape.position = Vector3(0, 0.52 * MODEL_SCALE, 0)
	add_child(shape)

func _build_visuals() -> void:
	# Визуал — меш-билдер Antigravity (vehicle_meshes.gd): Willys-джип
	# с динамическими колёсами WheelFL..RR и турельной стойкой TurretMount.
	# Физика владения и вход/выход остаются в этом скрипте.
	_model_root = VEHICLE_MESHES.build_jeep()
	# QA-зачистка: увеличенный масштаб под Dummy War-ощущение техники.
	_model_root.scale = Vector3.ONE * MODEL_SCALE
	add_child(_model_root)
	_apply_lod(_model_root)
	for wheel_name in ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]:
		var wheel := _model_root.get_node_or_null(wheel_name) as Node3D
		if wheel != null:
			_wheels.append(wheel)

	_turret_yaw = _model_root.get_node_or_null("TurretYaw") as Node3D
	_turret_pitch = _model_root.get_node_or_null("TurretPitch") as Node3D
	_turret_muzzle = _model_root.get_node_or_null("Muzzle") as Marker3D
	_build_turret_audio()

	# Дым при повреждении.	# Дым при повреждении.
	_smoke = CPUParticles3D.new()
	_smoke.amount = 14
	_smoke.lifetime = 1.6
	_smoke.emitting = false
	_smoke.position = Vector3(0, 1.1, -1.0)
	_smoke.direction = Vector3(0, 1, 0)
	_smoke.initial_velocity_min = 0.6
	_smoke.initial_velocity_max = 1.1
	_smoke.scale_amount_min = 0.30
	_smoke.scale_amount_max = 0.85
	_smoke.color = Color(0.22, 0.22, 0.22, 0.55)
	var smoke_mesh := BoxMesh.new()
	smoke_mesh.size = Vector3(0.35, 0.35, 0.35)
	_smoke.mesh = smoke_mesh
	add_child(_smoke)

	_fire_particles = CPUParticles3D.new()
	_fire_particles.amount = 26
	_fire_particles.lifetime = 0.45
	_fire_particles.emitting = false
	_fire_particles.position = Vector3(0, 0.8, -0.6)
	_fire_particles.direction = Vector3(0, 1, 0)
	_fire_particles.initial_velocity_min = 1.4
	_fire_particles.initial_velocity_max = 2.6
	_fire_particles.scale_amount_min = 0.18
	_fire_particles.scale_amount_max = 0.42
	_fire_particles.color = Color(1.0, 0.52, 0.14)
	var fire_mesh := SphereMesh.new()
	fire_mesh.radius = 0.10
	fire_mesh.height = 0.20
	fire_mesh.radial_segments = 6
	fire_mesh.rings = 4
	_fire_particles.mesh = fire_mesh
	var fire_mat := StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.5, 0.1)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.45, 0.1)
	fire_mat.emission_energy_multiplier = 1.6
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fire_particles.material_override = fire_mat
	add_child(_fire_particles)

func _build_seats() -> void:
	var seat: Marker3D = null
	if _model_root != null:
		seat = _model_root.get_node_or_null("DriverSeat") as Marker3D
	if seat == null:
		seat = Marker3D.new()
		seat.name = "DriverSeat"
		seat.position = Vector3(-0.34, 0.66, -0.42)
		add_child(seat)
	_driver_marker = seat

func _read_driver_input() -> Vector2:
	if destroyed:
		return Vector2.ZERO
	if absf(throttle_override) > 0.001 or absf(steer_override) > 0.001:
		return Vector2(steer_override, throttle_override)
	if driver == null or not is_instance_valid(driver):
		return Vector2.ZERO
	var move := Vector2.ZERO
	if "mobile_move" in driver:
		var mm: Vector2 = driver.get("mobile_move")
		move = Vector2(mm.x, -mm.y)
	if not OS.has_feature("mobile"):
		move.x += float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		move.y += float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) - float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	return move.limit_length(1.0)

func _build_turret_audio() -> void:
	_turret_audio = AudioStreamPlayer3D.new()
	_turret_audio.stream = WEAPON_SOUND.get_shot("ppsh41")
	_turret_audio.unit_size = 15.0
	_turret_audio.max_distance = 180.0
	_turret_audio.max_polyphony = 1
	_turret_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	_turret_audio.bus = COMBAT_AUDIO.BUS_COMBAT_DIRECT
	add_child(_turret_audio)
	if _turret_muzzle == null:
		return
	_turret_flash = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	_turret_flash.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.15)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_turret_flash.material_override = mat
	_turret_flash.visible = false
	_turret_muzzle.add_child(_turret_flash)

## Наведение спаренного пулемёта по камере водителя.
func tick_driver(player: Node3D, delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if _turret_flash_time > 0.0:
		_turret_flash_time = maxf(0.0, _turret_flash_time - delta)
		if _turret_flash_time <= 0.0 and _turret_flash != null:
			_turret_flash.visible = false
	if _turret_yaw == null or _turret_pitch == null:
		return
	var camera: Camera3D = player.get("camera")
	if camera == null:
		return
	var dir := -camera.global_transform.basis.z
	if dir.length_squared() < 0.001:
		return
	dir = dir.normalized()
	var local_yaw := wrapf(atan2(-dir.x, -dir.z) - global_rotation.y, -PI, PI)
	_turret_yaw.rotation.y = clampf(local_yaw, -PI, PI)
	_turret_pitch.rotation.x = clampf(asin(clampf(dir.y, -1.0, 1.0)), -0.35, 0.55)

func try_fire(player: Node3D) -> bool:
	if destroyed or driver != player or _fire_cooldown > 0.0:
		return false
	var camera: Camera3D = player.get("camera")
	if camera == null:
		return false
	_fire_cooldown = TURRET_INTERVAL
	var origin := _turret_muzzle.global_position if _turret_muzzle != null else global_position + Vector3.UP * 1.55
	var forward := -camera.global_transform.basis.z
	var aim_end := camera.global_position + forward * TURRET_RANGE
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, aim_end)
	query.collision_mask = TURRET_RAY_MASK
	query.collide_with_areas = true
	query.exclude = [player.get_rid(), get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var aim_point: Vector3 = hit.get("position", aim_end)
	var direction := (aim_point - origin).normalized()
	if direction.length_squared() < 0.01:
		direction = forward
	var player_team := MatchState.player_team
	var world := get_parent()
	if world != null and world.has_method("spawn_bullet_projectile"):
		world.call("spawn_bullet_projectile", origin, direction, TURRET_BULLET_SPEED, TURRET_DAMAGE, TURRET_RANGE, "Player", player_team, player)
	elif world != null:
		var bullet = BULLET_SCRIPT.new()
		world.add_child(bullet)
		bullet.configure(origin, direction, TURRET_BULLET_SPEED, TURRET_DAMAGE, TURRET_RANGE, "Player", player_team, player)
	if _turret_audio != null:
		_turret_audio.global_position = origin
		_turret_audio.pitch_scale = 0.92 + randf_range(-0.03, 0.03)
		_turret_audio.play()
	if _turret_flash != null:
		_turret_flash.visible = true
		_turret_flash_time = 0.05
	HIT_EFFECTS.spawn_casing(world, origin - direction * 0.4 + Vector3.UP * 0.08, Vector3(randf_range(-1.0, 1.0), 2.2, randf_range(-1.0, 1.0)))
	return true

func _physics_process(delta: float) -> void:
	var input := _read_driver_input()
	var throttle := clampf(input.y, -1.0, 1.0)
	var steer := clampf(input.x, -1.0, 1.0)

	if destroyed:
		throttle = 0.0

	if throttle < -0.05 and _speed > 0.4:
		_speed = move_toward(_speed, 0.0, BRAKE_DECEL * delta)
	elif throttle > 0.05:
		_speed = move_toward(_speed, MAX_FORWARD_SPEED * throttle, ACCEL * delta)
	elif throttle < -0.05:
		_speed = move_toward(_speed, MAX_REVERSE_SPEED * throttle, ACCEL * delta)
	else:
		_speed = move_toward(_speed, 0.0, DRAG_DECEL * delta)

	if absf(_speed) > 0.6:
		var rate := TURN_RATE * steer * (0.55 + 0.45 * minf(absf(_speed) / MAX_FORWARD_SPEED, 1.0))
		if _speed < 0.0:
			rate = -rate
		rotation.y -= rate * delta

	var forward := -global_transform.basis.z
	velocity.x = forward.x * _speed
	velocity.z = forward.z * _speed
	velocity.y = -GRAVITY * (0.0 if is_on_floor() else 1.0)
	move_and_slide()

	# Удар о стену/дерево гасит скорость, иначе джип «шлифует» препятствие.
	if absf(_speed) > 1.0:
		for i in range(get_slide_collision_count()):
			var collision := get_slide_collision(i)
			if collision.get_normal().y < 0.45:
				_speed = move_toward(_speed, 0.0, BRAKE_DECEL * 1.4 * delta)
				break

	var wheel_spin := _speed * delta / WHEEL_RADIUS
	for wheel in _wheels:
		if is_instance_valid(wheel):
			wheel.rotate_object_local(Vector3(1, 0, 0), -wheel_spin)

	if is_instance_valid(driver) and driver != null:
		driver.global_position = seat_position()
		driver.velocity = Vector3.ZERO
