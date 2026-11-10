extends RefCounted

## Кровь, пулевые отверстия, гильзы, искры и эффекты попаданий.
## Оптимизировано для высокой производительности на мобильных устройствах.

static var _blood_tex: Texture2D
static var _hole_tex: Texture2D
static var _blood_mat: StandardMaterial3D
static var _hole_mat: StandardMaterial3D
static var _decals: Array = []
static var _blood_sphere: SphereMesh
static var _dust_sphere: SphereMesh
static var _spark_mesh: SphereMesh
static var _blood_particle_mat: StandardMaterial3D
static var _dust_particle_mat: StandardMaterial3D
static var _spark_mat: StandardMaterial3D
static var _casing_mesh: CylinderMesh
static var _casing_mat: StandardMaterial3D
static var _active_casings: Array = []
const MAX_ACTIVE_CASINGS := 40

class CasingNode extends Node3D:
	var velocity := Vector3.ZERO
	var angular_vel := Vector3.ZERO
	var life := 4.5
	var bounces := 0
	var settled := false

	func _process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		velocity.y -= 16.0 * delta
		position += velocity * delta
		rotation += angular_vel * delta
		if position.y <= 0.035 and velocity.y < 0.0:
			position.y = 0.035
			velocity.y = -velocity.y * 0.32
			velocity.x *= 0.65
			velocity.z *= 0.65
			angular_vel *= 0.5
			bounces += 1
			if bounces > 2:
				velocity = Vector3.ZERO
				angular_vel = Vector3.ZERO
				settled = true
				# Осевшая гильза больше не тратит кадр: висит до таймера.
				set_process(false)
				get_tree().create_timer(1.6, false).timeout.connect(queue_free)

class DroppedWeaponNode extends Node3D:
	var velocity := Vector3.ZERO
	var angular_vel := Vector3.ZERO
	var settled := false
	var life := 30.0

	func _process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		if settled:
			return
		velocity.y -= 15.0 * delta
		position += velocity * delta
		rotation += angular_vel * delta
		if position.y <= 0.06 and velocity.y < 0.0:
			position.y = 0.06
			velocity.y = -velocity.y * 0.22
			velocity.x *= 0.5
			velocity.z *= 0.5
			angular_vel *= 0.35
			if velocity.length_squared() < 0.06:
				settled = true
				velocity = Vector3.ZERO
				angular_vel = Vector3.ZERO

static func spawn_casing(parent: Node, spawn_pos: Vector3, eject_velocity: Vector3) -> void:
	if parent == null:
		return
	# Low-пресет: гильзы не спавним (каждая — отдельный нод и физтело).
	if GameSettings.quality == 0:
		return
	# Жесткий лимит: при шквальном огне старые гильзы удаляются, а не копятся.
	var i := _active_casings.size() - 1
	while i >= 0:
		if not is_instance_valid(_active_casings[i]):
			_active_casings.remove_at(i)
		i -= 1
	if _active_casings.size() >= MAX_ACTIVE_CASINGS:
		var oldest = _active_casings.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var c := CasingNode.new()
	c.position = spawn_pos
	c.velocity = eject_velocity + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.4), randf_range(-0.3, 0.3))
	c.angular_vel = Vector3(randf_range(-18.0, 18.0), randf_range(-22.0, 22.0), randf_range(-15.0, 15.0))
	var mi := MeshInstance3D.new()
	mi.mesh = _get_casing_mesh()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 16.0
	c.add_child(mi)
	parent.add_child(c)
	_active_casings.append(c)

static func spawn_dropped_weapon(parent: Node, spawn_pos: Vector3, weapon_mesh: Mesh, eject_vel: Vector3) -> void:
	if parent == null or weapon_mesh == null:
		return
	var w := DroppedWeaponNode.new()
	w.position = spawn_pos
	w.velocity = eject_vel + Vector3(randf_range(-0.5, 0.5), 1.2, randf_range(-0.5, 0.5))
	w.angular_vel = Vector3(randf_range(-4.0, 4.0), randf_range(-6.0, 6.0), randf_range(-4.0, 4.0))
	var mi := MeshInstance3D.new()
	mi.mesh = weapon_mesh
	mi.scale = Vector3.ONE * 0.95
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	w.add_child(mi)
	parent.add_child(w)

static func spawn_blood(parent: Node, pos: Vector3, normal: Vector3, world_parent: Node = null) -> void:
	spawn_directional_blood(parent, pos, normal, false, world_parent)

static func spawn_directional_blood(parent: Node, pos: Vector3, bullet_dir: Vector3, is_lethal: bool = false, world_parent: Node = null) -> void:
	if parent == null:
		return
	# QA-fix TASK-0022: кровь больше не «приклеенный к телу спрайт».
	# Декали живут в мире и остаются на земле/стене, когда тело падает.
	var mat := _blood_material()
	var normal := bullet_dir.normalized()
	if normal.length_squared() < 0.1:
		normal = Vector3.UP
	var ground_parent: Node = world_parent if world_parent != null else parent

	if is_lethal:
		# Большая лужа под телом + 2-3 боковых брызга вокруг.
		var main_pool := MeshInstance3D.new()
		var main_quad := PlaneMesh.new()
		main_quad.size = Vector2(randf_range(1.5, 2.1), randf_range(1.4, 2.0))
		main_pool.mesh = main_quad
		main_pool.material_override = mat
		main_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ground_parent.add_child(main_pool)
		main_pool.global_transform = _surface_transform(Vector3(pos.x, 0.015, pos.z), Vector3.UP, 0.0)
		main_pool.rotate_y(randf_range(0.0, TAU))
		_register_decal(main_pool)
		for splash_index in range(3):
			var angle := randf_range(0.0, TAU)
			var radius := randf_range(0.55, 1.35)
			var spot := MeshInstance3D.new()
			var spot_quad := PlaneMesh.new()
			var spot_size := randf_range(0.35, 0.75)
			spot_quad.size = Vector2(spot_size, spot_size)
			spot.mesh = spot_quad
			spot.material_override = mat
			spot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			ground_parent.add_child(spot)
			var splash_pos := Vector3(pos.x + cos(angle) * radius, 0.014, pos.z + sin(angle) * radius)
			spot.global_transform = _surface_transform(splash_pos, Vector3.UP, 0.0)
			spot.rotate_y(randf_range(0.0, TAU))
			_register_decal(spot)
	else:
		# Небольшая декаль в точке попадания, в мире (не на теле).
		var decal := MeshInstance3D.new()
		var quad := PlaneMesh.new()
		quad.size = Vector2(0.30, 0.30)
		decal.mesh = quad
		decal.material_override = mat
		decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ground_parent.add_child(decal)
		decal.global_transform = _surface_transform(pos + normal * 0.02, normal, 0.015)
		_register_decal(decal)

	# Направленные частицы брызг крови (артериальный фонтан при смертельном).
	var particles := _make_particles(ground_parent, pos, normal, false)
	if particles != null:
		particles.amount = 34 if is_lethal else 18
		particles.initial_velocity_min = 3.0 if is_lethal else 1.4
		particles.initial_velocity_max = 6.5 if is_lethal else 3.6
		particles.spread = 55.0
		particles.gravity = Vector3(0, -14.0, 0)
		particles.scale_amount_min = 0.02
		particles.scale_amount_max = 0.075
		particles.mesh = _get_blood_sphere()
		particles.emitting = true
		particles.finished.connect(particles.queue_free)

	# Мелкая кровавая взвесь вокруг раны (на low пропускаем: второй эмиттер).
	var mist := _make_particles(ground_parent, pos + normal * 0.15, normal, false) if GameSettings.quality > 0 else null
	if mist != null:
		mist.amount = 10
		mist.initial_velocity_min = 0.2
		mist.initial_velocity_max = 0.7
		mist.spread = 70.0
		mist.scale_amount_min = 0.10
		mist.scale_amount_max = 0.22
		mist.color = Color(0.42, 0.02, 0.015, 0.45)
		var haze := SphereMesh.new()
		haze.radius = 0.06
		haze.height = 0.12
		haze.radial_segments = 6
		haze.rings = 4
		mist.mesh = haze
		mist.emitting = true
		mist.finished.connect(mist.queue_free)

static var _explosion_bass: AudioStreamWAV = null

## QA-fix TASK-0022: объёмный взрыв — слои огня, ударная волна, дым, осколки,
## вспышка, подпалина и низкочастотный «бум». Заменяет «пик и жёлтый шар».
static func spawn_explosion(parent: Node, pos: Vector3, power := 1.0) -> void:
	if parent == null:
		return
	var low := GameSettings.quality == 0

	# 1) Огненные шары (два слоя, аддитивное смешивание).
	for i in range(2):
		var radius := (0.85 + 0.45 * float(i)) * power
		var sphere := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 10
		mesh.rings = 6
		sphere.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.55, 0.15, 0.95 if i == 0 else 0.55)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.38, 0.07)
		mat.emission_energy_multiplier = 3.2
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		sphere.material_override = mat
		sphere.position = pos + Vector3.UP * 0.55 * power
		sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(sphere)
		var tw := sphere.create_tween()
		tw.tween_property(sphere, "scale", Vector3.ONE * (2.4 + float(i)), 0.30 + 0.10 * float(i)).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.32 + 0.16 * float(i))
		tw.tween_callback(sphere.queue_free)

	# 2) Ударная волна по земле.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85 * power
	torus.outer_radius = 1.12 * power
	torus.rings = 12
	torus.ring_segments = 8
	ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.88, 0.80, 0.62, 0.50)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = ring_mat
	ring.position = pos + Vector3.UP * 0.12
	ring.scale = Vector3(1.0, 0.22, 1.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
	var ring_tw := ring.create_tween()
	ring_tw.tween_property(ring, "scale", Vector3(7.5, 0.3, 7.5) * power, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	ring_tw.parallel().tween_property(ring_mat, "albedo_color:a", 0.0, 0.5)
	ring_tw.tween_callback(ring.queue_free)

	# 3) Поднимающийся столб дыма (плавно, не мгновенный шар).
	var smoke := CPUParticles3D.new()
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	var puff_mat := StandardMaterial3D.new()
	puff_mat.albedo_color = Color(0.30, 0.29, 0.27, 0.42)
	puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = puff_mat
	smoke.mesh = puff
	smoke.amount = 20 if low else 32
	smoke.lifetime = 3.4
	smoke.one_shot = true
	smoke.explosiveness = 0.55
	smoke.direction = Vector3.UP
	smoke.spread = 52.0
	smoke.initial_velocity_min = 1.4
	smoke.initial_velocity_max = 4.2
	smoke.gravity = Vector3(0.25, 0.55, 0.18)
	smoke.scale_amount_min = 1.0 if low else 1.3
	smoke.scale_amount_max = 2.4 if low else 3.2
	smoke.position = pos + Vector3.UP * 0.45
	smoke.fixed_fps = 20
	# Дальние облака не рисуем — огромные прозрачные сферы убивают fillrate.
	smoke.visibility_range_end = 70.0 if low else 200.0
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(smoke)
	smoke.emitting = true
	smoke.finished.connect(smoke.queue_free)

	# 4) Осколки и искры.
	var debris := CPUParticles3D.new()
	var frag := BoxMesh.new()
	frag.size = Vector3(0.06, 0.06, 0.10)
	var frag_mat := StandardMaterial3D.new()
	frag_mat.albedo_color = Color(0.30, 0.27, 0.22)
	frag_mat.emission_enabled = true
	frag_mat.emission = Color(0.9, 0.45, 0.12)
	frag_mat.emission_energy_multiplier = 0.6
	frag.material = frag_mat
	debris.mesh = frag
	debris.amount = 18 if low else 34
	debris.lifetime = 1.1
	debris.one_shot = true
	debris.explosiveness = 0.95
	debris.direction = Vector3.UP
	debris.spread = 85.0
	debris.initial_velocity_min = 5.0 * power
	debris.initial_velocity_max = 15.0 * power
	debris.gravity = Vector3(0, -16.0, 0)
	debris.angular_velocity_min = -420.0
	debris.angular_velocity_max = 420.0
	debris.scale_amount_min = 0.6
	debris.scale_amount_max = 1.4
	debris.position = pos + Vector3.UP * 0.3
	debris.fixed_fps = 24
	debris.visibility_range_end = 80.0 if low else 200.0
	debris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(debris)
	debris.emitting = true
	debris.finished.connect(debris.queue_free)

	# 5) Вспышка света.
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.70, 0.30)
	light.light_energy = 10.0 * power
	light.omni_range = 16.0 * power
	light.position = pos + Vector3.UP * 0.8
	parent.add_child(light)
	var light_tw := light.create_tween()
	light_tw.tween_property(light, "light_energy", 0.0, 0.30)
	light_tw.tween_callback(light.queue_free)

	# 6) Подпалина на земле.
	var scorch := MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(3.4 * power, 3.4 * power)
	scorch.mesh = quad
	var scorch_mat := StandardMaterial3D.new()
	scorch_mat.albedo_texture = _get_hole_texture()
	scorch_mat.albedo_color = Color(0.20, 0.18, 0.16, 0.85)
	scorch_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scorch_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scorch_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	scorch.material_override = scorch_mat
	scorch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(scorch)
	scorch.global_transform = _surface_transform(Vector3(pos.x, 0.02, pos.z), Vector3.UP, 0.0)
	_register_decal(scorch)

	# 7) Низкочастотный «бум» — взрыв слышно и телом, а не только ушами.
	if _explosion_bass == null:
		_explosion_bass = _make_bass_boom()
	var boom := AudioStreamPlayer3D.new()
	boom.stream = _explosion_bass
	boom.unit_size = 26.0 * power
	boom.max_distance = 320.0
	boom.volume_db = 4.0
	boom.max_polyphony = 1
	boom.attenuation_model = AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC
	parent.add_child(boom)
	boom.global_position = pos
	boom.play()
	boom.finished.connect(boom.queue_free)

static func _make_bass_boom() -> AudioStreamWAV:
	const RATE := 22050
	var count := int(RATE * 1.1)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	for i in range(count):
		var t := float(i) / float(RATE)
		var env := exp(-t * 3.4)
		var sub := sin(TAU * 38.0 * t) * 0.65
		var body := sin(TAU * 64.0 * t) * 0.35 * exp(-t * 6.0)
		var rumble := rng.randf_range(-1.0, 1.0) * 0.10 * exp(-t * 2.2)
		var value := int(clampf((sub + body + rumble) * env * 0.95, -1.0, 1.0) * 32767.0)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	return stream

static func spawn_bullet_hole(parent: Node, pos: Vector3, normal: Vector3) -> void:
	if parent == null:
		return
	# Low-пресет: не плодим дырки от пуль (десятки квадов в бою).
	if GameSettings.quality == 0:
		return
	var mat := _hole_material()
	var decal := MeshInstance3D.new()
	var quad := PlaneMesh.new()
	quad.size = Vector2(0.24, 0.24)
	decal.mesh = quad
	decal.material_override = mat
	decal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(decal)
	decal.global_transform = _surface_transform(pos, normal, 0.012)
	_register_decal(decal)

	var particles := _make_particles(parent, pos, normal, true)
	if particles != null:
		particles.amount = 12
		particles.initial_velocity_min = 0.6
		particles.initial_velocity_max = 1.8
		particles.spread = 65.0
		particles.scale_amount_min = 0.015
		particles.scale_amount_max = 0.035
		particles.mesh = _get_dust_sphere()
		particles.emitting = true
		particles.finished.connect(particles.queue_free)

static func spawn_metal_sparks(parent: Node, pos: Vector3, normal: Vector3) -> void:
	if parent == null:
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.35
	p.direction = normal
	p.gravity = Vector3(0, -12.0, 0)
	p.amount = 14
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 6.0
	p.spread = 50.0
	p.scale_amount_min = 0.01
	p.scale_amount_max = 0.03
	p.color = Color(1.0, 0.88, 0.3)
	p.mesh = _get_spark_sphere()
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)

static func _make_particles(parent: Node, pos: Vector3, normal: Vector3, dust: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.55 if not dust else 0.7
	p.direction = normal
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.02
	p.scale_amount_max = 0.04
	p.color = Color(0.42, 0.02, 0.01) if not dust else Color(0.55, 0.55, 0.5)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	p.global_position = pos
	return p

static func _surface_transform(pos: Vector3, normal: Vector3, offset: float) -> Transform3D:
	var n := normal.normalized()
	if n.length_squared() < 0.1:
		n = Vector3.UP
	var up := Vector3.UP
	if absf(n.dot(up)) > 0.95:
		up = Vector3.FORWARD
	var x := up.cross(n).normalized()
	var y := n.cross(x).normalized()
	var basis := Basis(x, y, n)
	return Transform3D(basis, pos + n * offset)

static func _register_decal(decal: MeshInstance3D) -> void:
	_decals.append(decal)
	# На низком пресете держим меньше декалей (draw calls + overdraw на телефоне).
	var max_decals := 12 if GameSettings.quality == 0 else 60
	while _decals.size() > max_decals:
		var old = _decals.pop_front()
		if old != null and is_instance_valid(old):
			old.queue_free()

static func _blood_material() -> StandardMaterial3D:
	if _blood_mat != null:
		return _blood_mat
	_blood_mat = StandardMaterial3D.new()
	_blood_mat.albedo_texture = _get_blood_texture()
	_blood_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_blood_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_blood_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _blood_mat

static func _hole_material() -> StandardMaterial3D:
	if _hole_mat != null:
		return _hole_mat
	_hole_mat = StandardMaterial3D.new()
	_hole_mat.albedo_texture = _get_hole_texture()
	_hole_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_hole_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hole_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _hole_mat

static func _get_blood_texture() -> Texture2D:
	if _blood_tex != null:
		return _blood_tex
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 9173
	for i in range(22):
		_paint_circle(img, rng.randi_range(16, 112), rng.randi_range(16, 112),
			rng.randi_range(6, 22), Color(0.40, 0.015, 0.012, rng.randf_range(0.65, 0.98)))
	for i in range(65):
		_paint_circle(img, rng.randi_range(6, 122), rng.randi_range(6, 122),
			rng.randi_range(1, 5), Color(0.32, 0.01, 0.008, rng.randf_range(0.5, 0.9)))
	_blood_tex = ImageTexture.create_from_image(img)
	return _blood_tex

static func _get_hole_texture() -> Texture2D:
	if _hole_tex != null:
		return _hole_tex
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_paint_circle(img, 32, 32, 10, Color(0.02, 0.02, 0.02, 0.98))
	_paint_circle(img, 32, 32, 17, Color(0.20, 0.19, 0.17, 0.55))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4421
	for i in range(9):
		_paint_circle(img, 32 + rng.randi_range(-22, 22), 32 + rng.randi_range(-22, 22),
			rng.randi_range(1, 3), Color(0.08, 0.07, 0.06, 0.6))
	_hole_tex = ImageTexture.create_from_image(img)
	return _hole_tex

static func _paint_circle(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	var r2 := radius * radius
	for y in range(maxi(0, cy - radius), mini(img.get_height(), cy + radius + 1)):
		for x in range(maxi(0, cx - radius), mini(img.get_width(), cx + radius + 1)):
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= r2:
				img.set_pixel(x, y, color)

static func _get_blood_sphere() -> SphereMesh:
	if _blood_sphere == null:
		_blood_sphere = SphereMesh.new()
		_blood_sphere.radius = 0.03
		_blood_sphere.height = 0.06
		_blood_sphere.radial_segments = 6
		_blood_sphere.rings = 3
		_blood_particle_mat = StandardMaterial3D.new()
		_blood_particle_mat.albedo_color = Color(0.48, 0.01, 0.008)
		_blood_particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_blood_sphere.material = _blood_particle_mat
	return _blood_sphere

static func _get_dust_sphere() -> SphereMesh:
	if _dust_sphere == null:
		_dust_sphere = SphereMesh.new()
		_dust_sphere.radius = 0.025
		_dust_sphere.height = 0.05
		_dust_sphere.radial_segments = 5
		_dust_sphere.rings = 3
		_dust_particle_mat = StandardMaterial3D.new()
		_dust_particle_mat.albedo_color = Color(0.55, 0.55, 0.50)
		_dust_particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_dust_sphere.material = _dust_particle_mat
	return _dust_sphere

static func _get_spark_sphere() -> SphereMesh:
	if _spark_mesh == null:
		_spark_mesh = SphereMesh.new()
		_spark_mesh.radius = 0.02
		_spark_mesh.height = 0.04
		_spark_mesh.radial_segments = 4
		_spark_mesh.rings = 2
		_spark_mat = StandardMaterial3D.new()
		_spark_mat.albedo_color = Color(1.0, 0.9, 0.4)
		_spark_mat.emission_enabled = true
		_spark_mat.emission = Color(1.0, 0.8, 0.2)
		_spark_mat.emission_energy_multiplier = 4.0
		_spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_spark_mesh.material = _spark_mat
	return _spark_mesh

static func _get_casing_mesh() -> CylinderMesh:
	if _casing_mesh != null:
		return _casing_mesh
	_casing_mesh = CylinderMesh.new()
	_casing_mesh.top_radius = 0.007
	_casing_mesh.bottom_radius = 0.007
	_casing_mesh.height = 0.034
	_casing_mesh.radial_segments = 6
	_casing_mat = StandardMaterial3D.new()
	_casing_mat.albedo_color = Color(0.88, 0.76, 0.35)
	_casing_mat.metallic = 0.88
	_casing_mat.roughness = 0.32
	_casing_mesh.material = _casing_mat
	return _casing_mesh
