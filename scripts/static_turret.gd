extends Node3D
class_name FRONTLINEStaticTurret

## Стационарный пулемёт на тумбе (TASK-0012).
## Игрок занимает установку и выходит из неё по F (кнопка «interact»),
## целится стандартным взглядом — камера задаёт направление — и ведёт
## огонь сериями. Патроны бесконечны, темп ограничен отдачей.

const BULLET_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const WEAPON_SOUND = preload("res://scripts/weapon_sound_bank.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const VEHICLE_MESHES = preload("res://scripts/vehicle_meshes.gd")

const FIRE_INTERVAL := 0.085
const BULLET_SPEED := 730.0
const BULLET_DAMAGE := 26
const BULLET_RANGE := 190.0
const SPREAD := 0.012
const YAW_LIMIT := 2.5
const PITCH_LIMIT_MIN := -0.5
const PITCH_LIMIT_MAX := 0.62
const RAY_MASK := (1 << 0) | (1 << 1) | (1 << 2)
const MAX_HEALTH := 220.0

var occupant: Node3D = null
var health := MAX_HEALTH
var destroyed := false

var _fire_cooldown := 0.0
var _yaw: Node3D
var _pitch: Node3D
var _muzzle: Marker3D
var _flash: MeshInstance3D
var _flash_time := 0.0
var _sfx: AudioStreamPlayer3D
var _seat_socket: Marker3D = null
var _body_rid: RID
var _exclude_rids: Array[RID] = []

func _ready() -> void:
	add_to_group("enterable_vehicles")
	add_to_group("static_turrets")
	add_to_group("damageable")
	add_to_group("metal_targets")
	_build_base()
	_build_gun()
	_sfx = AudioStreamPlayer3D.new()
	_sfx.stream = WEAPON_SOUND.get_shot("ppsh41")
	_sfx.pitch_scale = 0.86
	_sfx.unit_size = 16.0
	_sfx.max_distance = 220.0
	_sfx.max_polyphony = 1
	_sfx.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	_sfx.bus = COMBAT_AUDIO.BUS_COMBAT_DIRECT
	add_child(_sfx)

func can_enter(player: Node3D) -> bool:
	if destroyed or occupant != null or player == null:
		return false
	if bool(player.get("is_dead")):
		return false
	if player.get("mounted_vehicle") != null or player.get("active_drone") != null:
		return false
	return true

func interaction_radius() -> float:
	return 2.4

func receive_hit(damage: int, attacker_pos: Vector3, _region: String = "chest", _attacker_name: String = "Unknown") -> int:
	if destroyed:
		return 0
	health -= float(damage)
	if is_instance_valid(get_parent()):
		HIT_EFFECTS.spawn_metal_sparks(get_parent(), attacker_pos, Vector3.UP)
	if health <= 0.0:
		_destroy()
	return damage

func _destroy() -> void:
	destroyed = true
	if occupant != null and is_instance_valid(occupant):
		if occupant.has_method("_exit_vehicle"):
			occupant.call("_exit_vehicle")
		occupant = null
	if is_instance_valid(get_parent()):
		HIT_EFFECTS.spawn_explosion(get_parent(), global_position + Vector3.UP * 0.8, 0.8)
	visible = false
	set_process(false)
	set_physics_process(false)
	queue_free()

func prompt_text(mobile: bool) -> String:
	if occupant != null:
		return "ВЫЙТИ" if mobile else "F — ВЫЙТИ"
	return "ЗАНЯТЬ MG" if mobile else "F — ЗАНЯТЬ MG"

func enter(player: Node3D) -> void:
	occupant = player

func exit_vehicle(player: Node3D) -> void:
	if player == occupant:
		occupant = null

func seat_position() -> Vector3:
	# Точка стойки стрелка — сокет GunnerStand из меш-билдера Antigravity.
	if _seat_socket != null:
		return _seat_socket.global_position
	return global_position + global_transform.basis.z * 0.46

func exit_position() -> Vector3:
	return seat_position() + global_transform.basis.z * 1.15

func driver_eye_height() -> float:
	return 1.08

func tick_driver(player: Node3D, delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if _flash_time > 0.0:
		_flash_time = maxf(0.0, _flash_time - delta)
		if _flash_time <= 0.0 and _flash != null:
			_flash.visible = false
	var camera: Camera3D = player.get("camera")
	if camera == null or _yaw == null or _pitch == null:
		return
	var dir := -camera.global_transform.basis.z
	if dir.length_squared() < 0.001:
		return
	dir = dir.normalized()
	var turret_yaw := atan2(-global_transform.basis.z.x, -global_transform.basis.z.z)
	var aim_yaw := atan2(-dir.x, -dir.z)
	_yaw.rotation.y = clampf(wrapf(aim_yaw - turret_yaw, -PI, PI), -YAW_LIMIT, YAW_LIMIT)
	var elevation: float = asin(clampf(dir.y, -1.0, 1.0))
	_pitch.rotation.x = clampf(elevation, PITCH_LIMIT_MIN, PITCH_LIMIT_MAX)

## Выстрел: пуля идёт из дульного среза в прицельную точку камеры.
func try_fire(player: Node3D) -> bool:
	if destroyed or occupant != player or _fire_cooldown > 0.0:
		return false
	var camera: Camera3D = player.get("camera")
	if camera == null or _muzzle == null:
		return false
	_fire_cooldown = FIRE_INTERVAL
	var forward := -camera.global_transform.basis.z
	var aim_end := camera.global_position + forward * BULLET_RANGE
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, aim_end)
	query.collision_mask = RAY_MASK
	query.exclude = [player.get_rid(), _body_rid]
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var aim_point: Vector3 = hit.get("position", aim_end)
	var origin := _muzzle.global_position
	var direction := (aim_point - origin).normalized()
	if direction.length_squared() < 0.01 or origin.distance_to(aim_point) < 1.0:
		direction = forward.normalized()
	var world := get_parent()
	if world != null and world.has_method("spawn_bullet_projectile"):
		world.call("spawn_bullet_projectile", origin, direction, BULLET_SPEED, BULLET_DAMAGE, BULLET_RANGE, "Player", team_name(), player)
	elif world != null:
		var bullet = BULLET_SCRIPT.new()
		world.add_child(bullet)
		bullet.configure(origin, direction, BULLET_SPEED, BULLET_DAMAGE, BULLET_RANGE, "Player", team_name(), player)
	if _flash != null:
		_flash.visible = true
		_flash_time = 0.05
	if _sfx != null:
		_sfx.global_position = origin
		_sfx.pitch_scale = 0.86 + randf_range(-0.03, 0.03)
		_sfx.play()
	HIT_EFFECTS.spawn_casing(world, origin - direction * 0.5 + Vector3.UP * 0.08, Vector3(randf_range(-1.2, 1.2), 2.4, randf_range(-1.2, 1.2)))
	return true

func team_name() -> String:
	return MatchState.player_team

## Мобильная оптимизация (TASK-0019): мелкие детали станка исчезают
## дальше 45 м, средние — дальше 90 м (число частей не меняется).
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

func _build_base() -> void:
	# Низкий бетонный фундамент под станок (меш умеет ставить треногу на землю).
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color(0.40, 0.38, 0.34)
	concrete.roughness = 0.98
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("owner_actor", self)
	_body_rid = body.get_rid()
	_exclude_rids = [body.get_rid()]
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.9, 0.25, 1.9)
	shape.shape = box
	shape.position = Vector3(0, 0.125, 0)
	body.add_child(shape)
	var pad := MeshInstance3D.new()
	var pad_mesh := BoxMesh.new()
	pad_mesh.size = Vector3(1.9, 0.25, 1.9)
	pad.mesh = pad_mesh
	pad.material_override = concrete
	pad.position = Vector3(0, 0.125, 0)
	body.add_child(pad)
	_sandbag(body, Vector3(-0.98, 0.30, 0.35))
	_sandbag(body, Vector3(0.98, 0.30, -0.15))

func _sandbag(parent: Node3D, pos: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.44, 0.40, 0.30)
	mat.roughness = 1.0
	var inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.22, 0.34)
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	inst.rotation = Vector3(0.0, randf_range(-0.25, 0.25), 0.0)
	parent.add_child(inst)

func _build_gun() -> void:
	# Визуал станкового пулемёта — меш-билдер Antigravity
	# (Tripod / SwivelYaw / GunPitch / Muzzle / GunnerStand).
	# Прицеливание, огонь и владение остаются в этом скрипте.
	var mg := VEHICLE_MESHES.build_stationary_mg()
	mg.position = Vector3(0, 0.25, 0)
	add_child(mg)
	_apply_lod(mg)
	_yaw = mg.get_node_or_null("SwivelYaw")
	_pitch = mg.get_node_or_null("GunPitch")
	_seat_socket = mg.get_node_or_null("GunnerStand") as Marker3D
	if _yaw == null or _pitch == null:
		var yaw := Node3D.new()
		yaw.name = "SwivelYaw"
		yaw.position = Vector3(0, 1.05, 0)
		add_child(yaw)
		var pitch := Node3D.new()
		pitch.name = "GunPitch"
		yaw.add_child(pitch)
		_yaw = yaw
		_pitch = pitch
	_muzzle = _pitch.get_node_or_null("Muzzle") as Marker3D
	if _muzzle == null:
		_muzzle = Marker3D.new()
		_muzzle.position = Vector3(0, 0.02, -1.12)
		_pitch.add_child(_muzzle)
	var flash := MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.09
	flash_mesh.height = 0.18
	flash_mesh.radial_segments = 6
	flash_mesh.rings = 4
	flash.mesh = flash_mesh
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.82, 0.35)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(1.0, 0.72, 0.2)
	flash_mat.emission_energy_multiplier = 2.2
	flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = flash_mat
	flash.position = Vector3(0, 0, -0.08)
	flash.visible = false
	_muzzle.add_child(flash)
	_flash = flash
