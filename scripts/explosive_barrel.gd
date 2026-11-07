extends StaticBody3D
class_name FRONTLINEExplosiveBarrel

## Тактическая взрывная бочка с горючим в стиле Dummy War.
## Детонирует от выстрелов, осколков гранат и других бочек (цепная реакция).
## Наносит сильный радиальный урон, запускает рэгдоллы ударной волной.

signal barrel_exploded(pos: Vector3)

const SFX_HIT_METAL = preload("res://assets/audio/hit_metal.ogg")
const SFX_EXPLOSION = preload("res://assets/audio/explosion.wav")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")

const BLAST_RADIUS := 8.5
const MAX_DAMAGE := 145.0
const HITBOX_LAYER_MASK := 8 # Слой 4 (хитбоксы)

var health := 40.0
var is_burning := false
var is_exploded := false

var _barrel_mesh: MeshInstance3D
var _fire_particles: CPUParticles3D
var _hitbox: Area3D
var _fuse_timer := 0.0

func _ready() -> void:
	add_to_group("explosive_barrels")
	add_to_group("damageable")
	collision_layer = 1
	collision_mask = 1

	_build_collision()
	_build_visuals()
	_build_hitbox()

func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.44
	cyl.height = 1.25
	shape.shape = cyl
	shape.position = Vector3(0, 0.625, 0)
	add_child(shape)

func _build_visuals() -> void:
	_barrel_mesh = MeshInstance3D.new()
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = 0.42
	cyl_mesh.bottom_radius = 0.42
	cyl_mesh.height = 1.20
	cyl_mesh.radial_segments = 16
	_barrel_mesh.mesh = cyl_mesh
	_barrel_mesh.position = Vector3(0, 0.60, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.16, 0.12) # Насыщенный ярко-красный цвет бочки
	mat.roughness = 0.65
	mat.metallic = 0.35
	_barrel_mesh.material_override = mat
	add_child(_barrel_mesh)

	# Жёлтая полоса опасности по центру бочки
	var stripe := MeshInstance3D.new()
	var stripe_mesh := CylinderMesh.new()
	stripe_mesh.top_radius = 0.43
	stripe_mesh.bottom_radius = 0.43
	stripe_mesh.height = 0.28
	stripe_mesh.radial_segments = 16
	stripe.mesh = stripe_mesh
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.92, 0.78, 0.12) # Жёлтый предупреждающий
	stripe_mat.roughness = 0.7
	stripe.material_override = stripe_mat
	stripe.position = Vector3(0, 0.60, 0)
	add_child(stripe)

	# Чёрные стальные обода сверху и снизу
	for rim_y in [0.08, 1.12]:
		var rim := MeshInstance3D.new()
		var rim_mesh := CylinderMesh.new()
		rim_mesh.top_radius = 0.44
		rim_mesh.bottom_radius = 0.44
		rim_mesh.height = 0.08
		rim_mesh.radial_segments = 16
		rim.mesh = rim_mesh
		var rim_mat := StandardMaterial3D.new()
		rim_mat.albedo_color = Color(0.18, 0.18, 0.20)
		rim_mat.metallic = 0.6
		rim_mat.roughness = 0.5
		rim.material_override = rim_mat
		rim.position = Vector3(0, rim_y, 0)
		add_child(rim)

	# Верхняя крышка с пробкой
	var cap := MeshInstance3D.new()
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.08
	cap_mesh.bottom_radius = 0.08
	cap_mesh.height = 0.06
	cap.mesh = cap_mesh
	cap.position = Vector3(0.20, 1.22, 0.12)
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.12, 0.12, 0.12)
	cap.material_override = cap_mat
	add_child(cap)

func _build_hitbox() -> void:
	_hitbox = Area3D.new()
	_hitbox.collision_layer = HITBOX_LAYER_MASK
	_hitbox.collision_mask = 0
	_hitbox.add_to_group("damageable")
	_hitbox.set_meta("owner_actor", self)
	_hitbox.set_meta("owner_dummy", self)
	_hitbox.set_meta("region", "barrel")

	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.48
	cyl.height = 1.30
	shape.shape = cyl
	shape.position = Vector3(0, 0.65, 0)
	_hitbox.add_child(shape)
	add_child(_hitbox)

func _process(delta: float) -> void:
	if is_burning and not is_exploded:
		_fuse_timer -= delta
		# Пульсация огненного свечения бочки
		if _barrel_mesh != null and _barrel_mesh.material_override != null:
			var pulse := (sin(Time.get_ticks_msec() * 0.02) + 1.0) * 0.5
			var mat = _barrel_mesh.material_override as StandardMaterial3D
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.35, 0.05)
			mat.emission_energy_multiplier = 1.5 + pulse * 3.5

		if _fuse_timer <= 0.0:
			explode("Взрыв бочки")

## Принятие урона пулями, осколками и взрывными волнами
func receive_hit(damage: int, hit_pos: Vector3, region: String = "barrel", attacker_name: String = "") -> int:
	if is_exploded:
		return 0

	# Звук попадания по металлу
	_play_metal_sfx(hit_pos)
	# Искры от рикошета
	_spawn_sparks(hit_pos)

	health -= float(damage)
	if health <= 0.0:
		explode(attacker_name if attacker_name != "" else "Взрыв бочки")
	elif not is_burning:
		_ignite()

	return damage

func _ignite() -> void:
	is_burning = true
	_fuse_timer = randf_range(0.9, 1.4)

	# Факел пламени из пробоины
	_fire_particles = CPUParticles3D.new()
	_fire_particles.amount = 24
	_fire_particles.lifetime = 0.5
	_fire_particles.direction = Vector3(randf_range(-0.4, 0.4), 1.0, randf_range(-0.4, 0.4)).normalized()
	_fire_particles.spread = 25.0
	_fire_particles.initial_velocity_min = 2.5
	_fire_particles.initial_velocity_max = 5.0
	_fire_particles.gravity = Vector3(0, 4.0, 0)
	_fire_particles.scale_amount_min = 0.08
	_fire_particles.scale_amount_max = 0.22
	_fire_particles.color = Color(1.0, 0.55, 0.1)
	_fire_particles.position = Vector3(0, 0.9, 0)
	add_child(_fire_particles)

func explode(killer_name: String = "Взрыв бочки") -> void:
	if is_exploded:
		return
	is_exploded = true
	var exp_pos := global_position + Vector3(0, 0.65, 0)

	# Отключаем коллизии и хитбокс
	collision_layer = 0
	collision_mask = 0
	if _hitbox != null:
		_hitbox.collision_layer = 0

	# 1. Визуальный взрыв: огненная сфера, свет, дым
	_spawn_explosion_visuals(exp_pos)

	# 2. Звук взрыва
	_play_explosion_sfx(exp_pos)

	# 3. Радиальный урон по ботам, игроку и соседним бочкам (цепная реакция!)
	_apply_blast_damage(exp_pos, killer_name)

	# 4. Тряска экрана игрока
	_shake_camera(exp_pos)

	# 5. Превращение бочки в обгоревший сплюснутый остов
	_turn_into_wreckage()

	barrel_exploded.emit(exp_pos)

func _spawn_explosion_visuals(pos: Vector3) -> void:
	var world := get_parent()
	if world == null:
		return

	# Огненный шар
	var fire := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.8
	sphere.height = 3.6
	fire.mesh = sphere
	var fire_mat := StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.70, 0.18)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.45, 0.05)
	fire_mat.emission_energy_multiplier = 8.0
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire.material_override = fire_mat
	fire.position = pos
	world.add_child(fire)

	# Вспышка света
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.72, 0.3)
	light.light_energy = 14.0
	light.omni_range = 28.0
	fire.add_child(light)

	# Частицы взрыва и осколков бочки
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 1.2
	p.amount = 45
	p.direction = Vector3.UP
	p.spread = 85.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 18.0
	p.gravity = Vector3(0, -12.0, 0)
	p.scale_amount_min = 0.08
	p.scale_amount_max = 0.28
	p.color = Color(0.20, 0.18, 0.16)
	p.position = pos
	world.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

	# Анимация затухания
	var tween := world.create_tween()
	tween.tween_property(fire, "scale", Vector3.ONE * 2.5, 0.14)
	tween.parallel().tween_property(fire_mat, "albedo_color:a", 0.0, 0.25)
	tween.parallel().tween_property(light, "light_energy", 0.0, 0.25)
	tween.tween_callback(fire.queue_free)

	# Подпалина на грунте
	HIT_EFFECTS.spawn_bullet_hole(world, pos, Vector3.UP)

func _play_explosion_sfx(pos: Vector3) -> void:
	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = SFX_EXPLOSION
	sfx.unit_size = 18.0
	sfx.max_distance = 120.0
	sfx.pitch_scale = randf_range(0.9, 1.1)
	sfx.position = pos
	get_parent().add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _play_metal_sfx(pos: Vector3) -> void:
	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = SFX_HIT_METAL
	sfx.unit_size = 6.0
	sfx.max_distance = 45.0
	sfx.pitch_scale = randf_range(0.95, 1.15)
	sfx.position = pos
	get_parent().add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _spawn_sparks(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.35
	p.amount = 12
	p.direction = Vector3.UP
	p.spread = 75.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.scale_amount_min = 0.02
	p.scale_amount_max = 0.05
	p.color = Color(1.0, 0.8, 0.2)
	p.position = pos
	get_parent().add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

func _apply_blast_damage(pos: Vector3, killer: String) -> void:
	# 1. Поражение пехотных ботов
	var bots = get_tree().get_nodes_in_group("bots")
	for b in bots:
		if b == null or not is_instance_valid(b):
			continue
		var bot = b as FRONTLINESoldierBot
		if bot != null and not bot.is_dead:
			var dist := pos.distance_to(bot.global_position)
			if dist <= BLAST_RADIUS:
				var factor := 1.0 - (dist / BLAST_RADIUS)
				var dmg := int(round(MAX_DAMAGE * factor * factor))
				bot.receive_hit(dmg, pos, "chest", killer)

	# 2. Поражение игрока
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player) and player.has_method("receive_hit"):
		var dist := pos.distance_to(player.global_position)
		if dist <= BLAST_RADIUS:
			var factor := 1.0 - (dist / BLAST_RADIUS)
			var dmg := int(round(MAX_DAMAGE * factor * factor * 0.9))
			player.receive_hit(dmg, pos, "chest", killer)

	# 3. Цепная детонация соседних бочек!
	var barrels = get_tree().get_nodes_in_group("explosive_barrels")
	for b in barrels:
		if b == null or not is_instance_valid(b) or b == self:
			continue
		var barrel = b as FRONTLINEExplosiveBarrel
		if barrel != null and not barrel.is_exploded:
			var dist := pos.distance_to(barrel.global_position)
			if dist <= BLAST_RADIUS:
				var factor := 1.0 - (dist / BLAST_RADIUS)
				var dmg := int(round(MAX_DAMAGE * factor))
				barrel.receive_hit(dmg, pos, "barrel", killer)

func _shake_camera(pos: Vector3) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player) and "recoil" in player:
		var dist := pos.distance_to(player.global_position)
		if dist < 32.0:
			var intensity := (1.0 - dist / 32.0) * 0.18
			player.recoil.y += intensity
			player.recoil.x += randf_range(-intensity, intensity) * 0.9

func _turn_into_wreckage() -> void:
	if _fire_particles != null:
		_fire_particles.queue_free()

	# Сплюснутый обугленный корпус
	if _barrel_mesh != null:
		var wreck_mesh := CylinderMesh.new()
		wreck_mesh.top_radius = 0.52
		wreck_mesh.bottom_radius = 0.55
		wreck_mesh.height = 0.40
		wreck_mesh.radial_segments = 12
		_barrel_mesh.mesh = wreck_mesh
		_barrel_mesh.position = Vector3(0, 0.20, 0)

		var wreck_mat := StandardMaterial3D.new()
		wreck_mat.albedo_color = Color(0.12, 0.11, 0.10)
		wreck_mat.roughness = 0.95
		wreck_mat.metallic = 0.1
		_barrel_mesh.material_override = wreck_mat

	# Стелющийся остаточный дым
	var smoke := CPUParticles3D.new()
	smoke.amount = 12
	smoke.lifetime = 1.8
	smoke.direction = Vector3.UP
	smoke.spread = 20.0
	smoke.initial_velocity_min = 0.6
	smoke.initial_velocity_max = 1.6
	smoke.gravity = Vector3(0, 0.5, 0)
	smoke.scale_amount_min = 0.15
	smoke.scale_amount_max = 0.45
	smoke.color = Color(0.18, 0.18, 0.18, 0.6)
	smoke.position = Vector3(0, 0.35, 0)
	add_child(smoke)
