extends Node3D

## Lightweight visible bullet. It travels through the world and checks only the
## segment covered this physics frame, so damage is delayed until impact.

const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_audio.gd")
const COLLISION_MASK := (1 << 0) | (1 << 1) | (1 << 2)

var velocity := Vector3.ZERO
var gravity := 9.81
var base_damage := 30
var player_damage := 0
var max_distance := 200.0
var distance_travelled := 0.0
var shooter_name := "Unknown"
var shooter_team := ""
var shooter: Node
var _excluded_rids: Array[RID] = []
var _visual: MeshInstance3D

func configure(start_pos: Vector3, direction: Vector3, speed: float, damage: int, range_m: float, owner_name: String, owner_team: String, owner: Node, damage_to_player := 0, gravity_mps2 := 9.81) -> void:
	global_position = start_pos
	velocity = direction.normalized() * maxf(speed, 1.0)
	base_damage = maxi(1, damage)
	player_damage = maxi(0, damage_to_player)
	max_distance = maxf(1.0, range_m)
	shooter_name = owner_name
	shooter_team = owner_team
	shooter = owner
	gravity = maxf(0.0, gravity_mps2)

func _ready() -> void:
	add_to_group("ballistic_bullets")
	_build_visual()
	_build_exclusions()
	_face_velocity()

func _physics_process(delta: float) -> void:
	if velocity.length_squared() < 1.0:
		queue_free()
		return
	var from := global_position
	var acceleration := Vector3.DOWN * gravity
	var step := velocity * delta + acceleration * (0.5 * delta * delta)
	var remaining_range := maxf(0.0, max_distance - distance_travelled)
	if step.length() > remaining_range and step.length() > 0.001:
		step *= remaining_range / step.length()
	var to := from + step
	var ear := COMBAT_AUDIO.get_listener_position(get_tree())
	COMBAT_AUDIO.trigger_bullet_flyby_3d(get_parent(), from, to, ear)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = COLLISION_MASK
	query.exclude = _excluded_rids
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_resolve_impact(hit, velocity.normalized())
		queue_free()
		return
	global_position = to
	velocity += acceleration * delta
	distance_travelled += step.length()
	if distance_travelled >= max_distance:
		queue_free()
		return
	_face_velocity()

static var _SHARED_MESH: BoxMesh = null
static var _SHARED_MAT: StandardMaterial3D = null

func _build_visual() -> void:
	if _SHARED_MESH == null:
		_SHARED_MESH = BoxMesh.new()
		_SHARED_MESH.size = Vector3(0.010, 0.010, 0.36)
	if _SHARED_MAT == null:
		_SHARED_MAT = StandardMaterial3D.new()
		_SHARED_MAT.albedo_color = Color(1.0, 0.78, 0.30)
		_SHARED_MAT.emission_enabled = true
		_SHARED_MAT.emission = Color(1.0, 0.55, 0.12)
		_SHARED_MAT.emission_energy_multiplier = 0.55
		_SHARED_MAT.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_visual = MeshInstance3D.new()
	_visual.name = "VisibleBullet"
	_visual.mesh = _SHARED_MESH
	_visual.material_override = _SHARED_MAT
	_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_visual)

func _build_exclusions() -> void:
	if not is_instance_valid(shooter):
		return
	if shooter is CollisionObject3D:
		_excluded_rids.append((shooter as CollisionObject3D).get_rid())
	for child in shooter.find_children("*", "Area3D", true, false):
		var area := child as Area3D
		if area != null:
			_excluded_rids.append(area.get_rid())

func _face_velocity() -> void:
	if velocity.length_squared() < 0.001:
		return
	var up := Vector3.FORWARD if absf(velocity.normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP
	look_at(global_position + velocity.normalized(), up)

func _resolve_impact(hit: Dictionary, direction: Vector3) -> void:
	var collider = hit.get("collider")
	var position: Vector3 = hit.get("position", global_position)
	var normal: Vector3 = hit.get("normal", -direction)
	var actor: Node
	if collider is Node:
		actor = collider.get_meta("owner_actor", collider.get_meta("owner_dummy", null))
		if actor == null and collider.has_method("receive_hit"):
			actor = collider
	if actor is Node and actor.has_method("receive_hit"):
		_apply_actor_hit(actor, collider, position, direction)
	else:
		var world := get_parent()
		if world != null:
			HIT_EFFECTS.spawn_bullet_hole(world, position, normal)
			COMBAT_AUDIO.play_surface_impact(world, position, normal, "ground")

func _apply_actor_hit(actor: Node, collider: Object, position: Vector3, direction: Vector3) -> void:
	if actor == shooter or not is_instance_valid(actor):
		return
	var region := "chest"
	if collider is Node and collider.has_meta("region"):
		region = str(collider.get_meta("region"))
	var target_team := ""
	if "team_name" in actor:
		target_team = str(actor.get("team_name"))
	elif actor.is_in_group("player"):
		target_team = str(get_tree().get_meta("selected_team", "IRON LEGION"))
	if target_team != "" and target_team == shooter_team:
		return

	var damage := player_damage if player_damage > 0 and actor.is_in_group("player") else base_damage
	match region:
		"head": damage = int(round(float(damage) * 2.2))
		"leg": damage = int(round(float(damage) * 0.45))
	var was_alive := not ("health" in actor) or float(actor.get("health")) > 0.0
	var attacker_pos := global_position - direction
	if is_instance_valid(shooter) and shooter is Node3D:
		attacker_pos = (shooter as Node3D).global_position
	var applied := int(actor.call("receive_hit", damage, attacker_pos, region, shooter_name))
	if applied <= 0:
		return
	var world := get_parent()
	if actor.is_in_group("explosive_barrels"):
		COMBAT_AUDIO.play_surface_impact(world, position, -direction, "metal")
	else:
		COMBAT_AUDIO.play_surface_impact(world, position, -direction, "flesh")
		HIT_EFFECTS.spawn_directional_blood(actor, position, direction, region == "head", world)
	if is_instance_valid(shooter) and shooter.has_method("on_projectile_hit"):
		shooter.call("on_projectile_hit", actor, applied, was_alive, region)

