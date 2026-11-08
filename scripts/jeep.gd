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

const MAX_FORWARD_SPEED := 13.5
const MAX_REVERSE_SPEED := 5.5
const ACCEL := 8.5
const BRAKE_DECEL := 15.0
const DRAG_DECEL := 3.5
const TURN_RATE := 1.35
## Масштаб визуала Antigravity. Отзыв QA (2026-11-08): джип был «игрушечным».
## 1.45 даёт Willys ~4.9 м длиной — чанки-аркада, как ощущается в Dummy War.
const MODEL_SCALE := 1.45
const WHEEL_RADIUS := 0.34 * MODEL_SCALE
const GRAVITY := 18.0

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
	if _driver_marker == null:
		return global_position + global_transform.basis.x * -1.35 * MODEL_SCALE
	return global_position - global_transform.basis.x * 1.35 * MODEL_SCALE + Vector3.UP * 0.2

func driver_eye_height() -> float:
	# Eye above the taller (scaled) cowl.
	return 1.06 * MODEL_SCALE

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

	var wheel_spin := _speed * delta / WHEEL_RADIUS
	for wheel in _wheels:
		if is_instance_valid(wheel):
			wheel.rotate_object_local(Vector3(1, 0, 0), -wheel_spin)

	if is_instance_valid(driver) and driver != null:
		driver.global_position = seat_position()
		driver.velocity = Vector3.ZERO
