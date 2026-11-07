extends CharacterBody3D
class_name FRONTLINEGrenade

## Боевая осколочная граната в стиле Dummy War.
## Имеет баллистическую траекторию броска, отскок от препятствий,
## искрящийся запал, взрыв с ударной волной, вспышкой, осколками и радиусом поражения.

signal exploded(pos: Vector3)

const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const FUSE_TIME := 3.0
const BLAST_RADIUS := 9.0
const MAX_DAMAGE := 140

var thrower_name := "Player"
var team_name := "IRON LEGION"
var linear_velocity := Vector3.ZERO
var angular_velocity := Vector3.ZERO
var fuse_timer := FUSE_TIME
var has_exploded := false

var _mesh_root: Node3D
var _fuse_sparks: CPUParticles3D
var _bounces := 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # Только статический мир/стены

	_build_visuals()
	_build_fuse_sparks()

func _build_visuals() -> void:
	_mesh_root = Node3D.new()
	add_child(_mesh_root)

	# Корпус гранаты (рифлёный оливково-зелёный цилиндр)
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.055
	cyl.bottom_radius = 0.050
	cyl.height = 0.14
	cyl.radial_segments = 8
	body.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.28, 0.18)
	mat.roughness = 0.75
	mat.metallic = 0.35
	body.material_override = mat
	_mesh_root.add_child(body)

	# Запал и спусковой рычаг
	var fuse := MeshInstance3D.new()
	var fuse_cyl := CylinderMesh.new()
	fuse_cyl.top_radius = 0.018
	fuse_cyl.bottom_radius = 0.018
	fuse_cyl.height = 0.045
	fuse.mesh = fuse_cyl
	fuse.position.y = 0.09
	var fuse_mat := StandardMaterial3D.new()
	fuse_mat.albedo_color = Color(0.65, 0.65, 0.68)
	fuse_mat.metallic = 0.8
	fuse.material_override = fuse_mat
	_mesh_root.add_child(fuse)

func _build_fuse_sparks() -> void:
	_fuse_sparks = CPUParticles3D.new()
	_fuse_sparks.position.y = 0.11
	_fuse_sparks.amount = 10
	_fuse_sparks.lifetime = 0.25
	_fuse_sparks.explosiveness = 0.1
	_fuse_sparks.direction = Vector3.UP
	_fuse_sparks.spread = 45.0
	_fuse_sparks.initial_velocity_min = 0.4
	_fuse_sparks.initial_velocity_max = 1.1
	_fuse_sparks.gravity = Vector3(0, -4.0, 0)
	_fuse_sparks.scale_amount_min = 0.01
	_fuse_sparks.scale_amount_max = 0.025
	_fuse_sparks.color = Color(1.0, 0.75, 0.2)
	_mesh_root.add_child(_fuse_sparks)
	_fuse_sparks.emitting = true

func _physics_process(delta: float) -> void:
	if has_exploded:
		return

	fuse_timer -= delta
	if fuse_timer <= 0.0:
		explode()
		return

	# Гравитация и перемещение
	linear_velocity.y -= 16.0 * delta
	velocity = linear_velocity
	var collision := move_and_collide(velocity * delta)

	if collision:
		var normal := collision.get_normal()
		linear_velocity = linear_velocity.bounce(normal) * 0.42
		angular_velocity *= 0.55
		_bounces += 1
		if linear_velocity.length_squared() < 0.2 and normal.y > 0.7:
			linear_velocity = Vector3.ZERO
			angular_velocity = Vector3.ZERO

	# Вращение в полёте
	_mesh_root.rotate_x(angular_velocity.x * delta)
	_mesh_root.rotate_y(angular_velocity.y * delta)
	_mesh_root.rotate_z(angular_velocity.z * delta)

func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	var exp_pos := global_position

	# 1. Вспышка и огненная сфера
	_spawn_explosion_visuals(exp_pos)

	# 2. Урон и импульс по радиусу
	_apply_blast_damage(exp_pos)

	# 3. Встряска камеры игрока
	_shake_player_camera(exp_pos)

	exploded.emit(exp_pos)
	queue_free()

func _spawn_explosion_visuals(pos: Vector3) -> void:
	var world := get_parent()
	if world == null:
		return

	# Сфера огня
	var fire := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.4
	sphere.height = 2.8
	fire.mesh = sphere
	var fire_mat := StandardMaterial3D.new()
	fire_mat.albedo_color = Color(1.0, 0.65, 0.15)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.45, 0.08)
	fire_mat.emission_energy_multiplier = 7.0
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire.material_override = fire_mat
	fire.position = pos + Vector3(0, 0.5, 0)
	world.add_child(fire)

	# Динамический свет вспышки
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.7, 0.25)
	light.light_energy = 9.0
	light.omni_range = 22.0
	fire.add_child(light)

	# Частицы дыма и разлёта осколков
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.8
	p.amount = 32
	p.direction = Vector3.UP
	p.spread = 85.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 14.0
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.04
	p.scale_amount_max = 0.12
	p.color = Color(0.28, 0.26, 0.24)
	p.position = pos + Vector3(0, 0.3, 0)
	world.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

	# Анимация затухания вспышки
	var tween := world.create_tween()
	tween.tween_property(fire, "scale", Vector3.ONE * 2.2, 0.12)
	tween.parallel().tween_property(fire_mat, "albedo_color:a", 0.0, 0.22)
	tween.parallel().tween_property(light, "light_energy", 0.0, 0.22)
	tween.tween_callback(fire.queue_free)

	# Подпалина на земле
	HIT_EFFECTS.spawn_bullet_hole(world, pos, Vector3.UP)

func _apply_blast_damage(pos: Vector3) -> void:
	var space := get_world_3d().direct_space_state

	# Поражение ботов
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
				bot.receive_hit(dmg, pos, "chest", thrower_name)

	# Поражение манекенов на полигоне
	var dummies = get_tree().get_nodes_in_group("training_dummy")
	for d in dummies:
		if d != null and is_instance_valid(d) and d.has_method("receive_hit"):
			var dist := pos.distance_to(d.global_position)
			if dist <= BLAST_RADIUS:
				var factor := 1.0 - (dist / BLAST_RADIUS)
				var dmg := int(round(MAX_DAMAGE * factor * factor))
				d.receive_hit(dmg, pos, "chest", thrower_name)

	# Поражение игрока
	var player = get_tree().get_first_node_in_group("player") as Node3D
	if player != null and is_instance_valid(player) and player.has_method("receive_hit"):
		var dist := pos.distance_to(player.global_position)
		if dist <= BLAST_RADIUS:
			var factor := 1.0 - (dist / BLAST_RADIUS)
			var dmg := int(round(MAX_DAMAGE * factor * factor * 0.85))
			player.receive_hit(dmg, pos, "chest", thrower_name)

func _shake_player_camera(pos: Vector3) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player) and "recoil" in player:
		var dist := pos.distance_to(player.global_position)
		if dist < 30.0:
			var intensity := (1.0 - dist / 30.0) * 0.15
			player.recoil.y += intensity
			player.recoil.x += randf_range(-intensity, intensity) * 0.8
