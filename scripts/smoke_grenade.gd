extends CharacterBody3D
class_name FRONTLINESmokeGrenade

## Тактическая дымовая граната в стиле Dummy War.
## При детонации испускает плотную завесу белого дыма (радиус 9.5 м на 15 секунд),
## блокирующую видимость и прицеливание ботов в открытых секторах и траншеях.

signal smoke_deployed(pos: Vector3)

const SFX_HISS = preload("res://assets/audio/smoke_hiss.wav")
const FUSE_TIME := 1.6
const SMOKE_DURATION := 15.0
const SMOKE_RADIUS := 9.5

static var active_clouds: Array[Dictionary] = []

var thrower_name := "Player"
var linear_velocity := Vector3.ZERO
var angular_velocity := Vector3.ZERO
var fuse_timer := FUSE_TIME
var has_deployed := false

var _mesh_root: Node3D
var _bounces := 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_build_collision()
	_build_visuals()

func _build_collision() -> void:
	var col_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.09
	col_shape.shape = sphere
	add_child(col_shape)

func _build_visuals() -> void:
	_mesh_root = Node3D.new()
	add_child(_mesh_root)

	# Корпус дымовой шашки (светло-серый цилиндр с зелёной полосой)
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.08
	cyl.height = 0.28
	body.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.80, 0.82)
	mat.roughness = 0.5
	mat.metallic = 0.3
	body.material_override = mat
	_mesh_root.add_child(body)

	# Тактическая зелёная маркировочная полоса
	var band := MeshInstance3D.new()
	var band_mesh := CylinderMesh.new()
	band_mesh.top_radius = 0.082
	band_mesh.bottom_radius = 0.082
	band_mesh.height = 0.08
	band.mesh = band_mesh
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.20, 0.65, 0.30)
	band.material_override = band_mat
	_mesh_root.add_child(band)

func _physics_process(delta: float) -> void:
	if has_deployed:
		return

	fuse_timer -= delta
	if fuse_timer <= 0.0:
		deploy_smoke()
		return

	linear_velocity.y -= 15.0 * delta
	var motion := linear_velocity * delta
	var col := move_and_collide(motion)
	if col:
		var normal := col.get_normal()
		linear_velocity = linear_velocity.bounce(normal) * 0.45
		angular_velocity *= 0.55
		_bounces += 1
		if linear_velocity.length_squared() < 0.2 and normal.y > 0.7:
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO

	_mesh_root.rotate_x(angular_velocity.x * delta)
	_mesh_root.rotate_y(angular_velocity.y * delta)
	_mesh_root.rotate_z(angular_velocity.z * delta)

func deploy_smoke() -> void:
	if has_deployed:
		return
	has_deployed = true
	var deploy_pos := global_position

	# Регистрация зоны блокировки видимости
	var cloud_record: Dictionary = {
		"pos": deploy_pos,
		"radius": SMOKE_RADIUS,
		"expire_time": Time.get_ticks_msec() + int(SMOKE_DURATION * 1000.0)
	}
	active_clouds.append(cloud_record)

	# Звук шипения пиротехнического состава
	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = SFX_HISS
	sfx.unit_size = 14.0
	sfx.max_distance = 65.0
	sfx.position = deploy_pos
	get_parent().add_child(sfx)
	sfx.play()

	# Плотные клубы дыма (CPU Particles)
	var p := CPUParticles3D.new()
	var smoke_mesh := SphereMesh.new()
	smoke_mesh.radius = 0.55
	smoke_mesh.height = 1.10
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.albedo_color = Color(0.92, 0.94, 0.96, 0.40)
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mesh.material = smoke_mat
	p.mesh = smoke_mesh

	# QA-fix TASK-0022: дым раскрывается плавно (3-4 с), а не «блоком за секунду».
	# Экономно: один эмиттер, fixed_fps 20, количество частиц зависит от пресета.
	var low_quality := GameSettings.quality == 0
	p.amount = 36 if low_quality else 60
	p.lifetime = 7.0
	p.explosiveness = 0.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.1
	p.direction = Vector3(0.15, 1.0, 0.05)
	p.spread = 65.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.6
	p.gravity = Vector3(0.22, 0.10, 0.12)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.color = Color(0.90, 0.92, 0.94, 0.0)
	p.fixed_fps = 20
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.position = deploy_pos + Vector3(0, 0.25, 0)
	get_parent().add_child(p)
	p.emitting = true

	# Облако «наливается»: частицы растут и уплотняются первые ~3.5 секунды.
	var grow_tw := p.create_tween()
	grow_tw.tween_property(p, "scale_amount_min", 2.6, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	grow_tw.parallel().tween_property(p, "scale_amount_max", 4.8, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	grow_tw.parallel().tween_property(p, "color:a", 0.62, 3.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	smoke_deployed.emit(deploy_pos)

	# Завершение дымовой завесы через 15 секунд
	get_tree().create_timer(SMOKE_DURATION, false).timeout.connect(func():
		active_clouds.erase(cloud_record)
		if is_instance_valid(p):
			p.emitting = false
			get_tree().create_timer(2.5, false).timeout.connect(func():
				if is_instance_valid(p):
					p.queue_free()
			)
		if is_instance_valid(sfx):
			sfx.stop()
			sfx.queue_free()
		if is_instance_valid(self):
			queue_free()
	)

## Проверяет, перекрывает ли активная дымовая завеса линию обзора между двумя точками
static func is_line_blocked_by_smoke(from: Vector3, to: Vector3) -> bool:
	_cleanup_expired_clouds()
	var seg := to - from
	var seg_len := seg.length()
	if seg_len < 0.1:
		return false
	var dir := seg / seg_len

	for cloud in active_clouds:
		var cpos: Vector3 = cloud.pos
		var cradius: float = cloud.radius
		# Если стрелок или цель находятся внутри радиуса дыма
		if from.distance_to(cpos) <= cradius or to.distance_to(cpos) <= cradius:
			return true
		# Проекция центра облака на отрезок
		var to_center := cpos - from
		var proj := to_center.dot(dir)
		if proj >= 0.0 and proj <= seg_len:
			var closest_point := from + dir * proj
			if closest_point.distance_to(cpos) <= cradius:
				return true
	return false

static func _cleanup_expired_clouds() -> void:
	var now := Time.get_ticks_msec()
	var i := active_clouds.size() - 1
	while i >= 0:
		if now > int(active_clouds[i].expire_time):
			active_clouds.remove_at(i)
		i -= 1
