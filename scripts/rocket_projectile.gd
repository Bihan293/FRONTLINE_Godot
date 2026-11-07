extends Node3D
class_name FRONTLINERocketProjectile

## Реактивный снаряд / ракета гранатомёта (Panzerfaust / RPG) в стиле Dummy War.
## Летит с высокой скоростью, оставляет дымный шлейф и реактивную струю,
## мгновенно детонирует при контакте с поверхностью или бойцом, нанося сокрушительный радиальный урон.

signal detonated(pos: Vector3)

const SFX_EXPLOSION = preload("res://assets/audio/explosion.wav")
const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")

const BLAST_RADIUS := 10.5
const MAX_DAMAGE := 220
const SPEED := 48.0
const GRAVITY := 4.5
const MAX_LIFETIME := 5.0

var velocity := Vector3.ZERO
var shooter_name := "Player"
var team_name := "IRON LEGION"
var has_detonated := false
var lifetime := 0.0

var _smoke_trail: CPUParticles3D
var _exhaust_fire: MeshInstance3D

func _ready() -> void:
	_build_visuals()
	_build_smoke_trail()

func launch(start_pos: Vector3, dir: Vector3, shooter: String, team: String) -> void:
	global_position = start_pos
	velocity = dir.normalized() * SPEED
	shooter_name = shooter
	team_name = team
	look_at(global_position + dir, Vector3.UP)

func _physics_process(delta: float) -> void:
	if has_detonated:
		return

	lifetime += delta
	if lifetime >= MAX_LIFETIME:
		detonate(global_position)
		return

	velocity.y -= GRAVITY * delta
	var step := velocity * delta
	var from := global_position
	var to := from + step

	# Проверка столкновения лучом
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 | 2 | 4 # мир, хитбоксы, боты
	query.collide_with_areas = true
	var hit := space.intersect_ray(query)

	if not hit.is_empty():
		detonate(hit.position)
	else:
		global_position = to
		if velocity.length_squared() > 1.0:
			look_at(global_position + velocity, Vector3.UP)

func detonate(pos: Vector3) -> void:
	if has_detonated:
		return
	has_detonated = true

	var world := get_parent()
	if world == null:
		queue_free()
		return

	# 1. Вспышка и взрыв
	_spawn_explosion_visuals(world, pos)
	# 2. Звук взрыва
	_play_explosion_sfx(world, pos)
	# 3. Радиальный урон
	_apply_blast_damage(pos)
	# 4. Тряска камеры
	_shake_player_camera(pos)

	detonated.emit(pos)
	queue_free()

func _build_visuals() -> void:
	var root := Node3D.new()
	root.name = "RocketMesh"
	add_child(root)

	# Корпус трубы ракеты
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.045
	cyl.bottom_radius = 0.045
	cyl.height = 0.65
	body.mesh = cyl
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.32, 0.36, 0.26) # Оливково-армейский
	body_mat.roughness = 0.7
	body.material_override = body_mat
	body.rotation.x = PI * 0.5
	root.add_child(body)

	# Боевая кумулятивная головка (конус)
	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.01
	head_mesh.bottom_radius = 0.09
	head_mesh.height = 0.22
	head.mesh = head_mesh
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.24, 0.26, 0.20)
	head.material_override = head_mat
	head.position = Vector3(0, 0, -0.42)
	head.rotation.x = PI * 0.5
	root.add_child(head)

	# Хвостовые стабилизаторы
	for angle in [0.0, PI * 0.5]:
		var fin := MeshInstance3D.new()
		var fin_mesh := BoxMesh.new()
		fin_mesh.size = Vector3(0.01, 0.20, 0.14)
		fin.mesh = fin_mesh
		var fin_mat := StandardMaterial3D.new()
		fin_mat.albedo_color = Color(0.2, 0.2, 0.2)
		fin.material_override = fin_mat
		fin.position = Vector3(0, 0, 0.26)
		fin.rotation.z = angle
		root.add_child(fin)

	# Огненная струя реактивного двигателя
	_exhaust_fire = MeshInstance3D.new()
	var flame := SphereMesh.new()
	flame.radius = 0.05
	flame.height = 0.18
	_exhaust_fire.mesh = flame
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(1.0, 0.6, 0.1)
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 0.5, 0.1)
	fmat.emission_energy_multiplier = 6.0
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_exhaust_fire.material_override = fmat
	_exhaust_fire.position = Vector3(0, 0, 0.38)
	_exhaust_fire.rotation.x = PI * 0.5
	root.add_child(_exhaust_fire)

func _build_smoke_trail() -> void:
	_smoke_trail = CPUParticles3D.new()
	var smesh := SphereMesh.new()
	smesh.radius = 0.14
	smesh.height = 0.28
	var smat := StandardMaterial3D.new()
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(0.85, 0.85, 0.85, 0.45)
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smesh.material = smat
	_smoke_trail.mesh = smesh

	_smoke_trail.amount = 32
	_smoke_trail.lifetime = 0.8
	_smoke_trail.direction = Vector3.BACK
	_smoke_trail.spread = 15.0
	_smoke_trail.initial_velocity_min = 1.0
	_smoke_trail.initial_velocity_max = 3.0
	_smoke_trail.gravity = Vector3(0, 0.8, 0)
	_smoke_trail.scale_amount_min = 0.2
	_smoke_trail.scale_amount_max = 0.6
	_smoke_trail.position = Vector3(0, 0, 0.40)
	add_child(_smoke_trail)

func _spawn_explosion_visuals(world: Node, pos: Vector3) -> void:
	# Огненный шар
	var fire := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 2.2
	sphere.height = 4.4
	fire.mesh = sphere
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(1.0, 0.70, 0.2)
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 0.50, 0.1)
	fmat.emission_energy_multiplier = 9.0
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire.material_override = fmat
	fire.position = pos
	world.add_child(fire)

	# Вспышка света
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.75, 0.3)
	light.light_energy = 16.0
	light.omni_range = 32.0
	fire.add_child(light)

	# Разлёт осколков
	var p := CPUParticles3D.new()
	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.18, 0.18, 0.18)
	p.mesh = p_mesh
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 1.2
	p.amount = 55
	p.direction = Vector3.UP
	p.spread = 85.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 22.0
	p.gravity = Vector3(0, -12.0, 0)
	p.scale_amount_min = 0.1
	p.scale_amount_max = 0.35
	p.color = Color(0.22, 0.20, 0.18)
	p.position = pos
	world.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

	# Затухание
	var tween := world.create_tween()
	tween.tween_property(fire, "scale", Vector3.ONE * 2.8, 0.16)
	tween.parallel().tween_property(fmat, "albedo_color:a", 0.0, 0.28)
	tween.parallel().tween_property(light, "light_energy", 0.0, 0.28)
	tween.tween_callback(fire.queue_free)

	HIT_EFFECTS.spawn_bullet_hole(world, pos, Vector3.UP)

func _play_explosion_sfx(world: Node, pos: Vector3) -> void:
	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = SFX_EXPLOSION
	sfx.unit_size = 24.0
	sfx.max_distance = 150.0
	sfx.pitch_scale = randf_range(0.85, 0.95)
	sfx.position = pos
	world.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

func _apply_blast_damage(pos: Vector3) -> void:
	# Боты
	for b in get_tree().get_nodes_in_group("bots"):
		if b == null or not is_instance_valid(b):
			continue
		var bot = b as FRONTLINESoldierBot
		if bot != null and not bot.is_dead:
			if team_name != "" and bot.team_name == team_name:
				continue
			var dist := pos.distance_to(bot.global_position)
			if dist <= BLAST_RADIUS:
				var factor := 1.0 - (dist / BLAST_RADIUS)
				var dmg := int(round(MAX_DAMAGE * factor * factor))
				bot.receive_hit(dmg, pos, "chest", shooter_name)

	# Взрывные бочки
	for b in get_tree().get_nodes_in_group("explosive_barrels"):
		if b != null and is_instance_valid(b) and b.has_method("receive_hit"):
			var dist := pos.distance_to(b.global_position)
			if dist <= BLAST_RADIUS:
				var factor := 1.0 - (dist / BLAST_RADIUS)
				var dmg := int(round(MAX_DAMAGE * factor))
				b.receive_hit(dmg, pos, "barrel", shooter_name)

	# Игрок
	var player = get_tree().get_first_node_in_group("player") as Node3D
	var player_team: String = str(get_tree().get_meta("selected_team", "IRON LEGION"))
	if player != null and is_instance_valid(player) and player.has_method("receive_hit"):
		if team_name == "" or team_name != player_team or shooter_name == "Player":
			var dist := pos.distance_to(player.global_position)
			if dist <= BLAST_RADIUS:
				var factor := 1.0 - (dist / BLAST_RADIUS)
				var dmg := int(round(MAX_DAMAGE * factor * factor * 0.9))
				player.receive_hit(dmg, pos, "chest", shooter_name)

func _shake_player_camera(pos: Vector3) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player) and "recoil" in player:
		var dist := pos.distance_to(player.global_position)
		if dist < 40.0:
			var intensity := (1.0 - dist / 40.0) * 0.28
			player.recoil.y += intensity
			player.recoil.x += randf_range(-intensity, intensity)
