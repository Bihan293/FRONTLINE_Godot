extends Node3D

## Headless coverage for visible ballistic shots: muzzle origin, travel delay,
## wall blocking, and friendly-fire collision.

const BULLET_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const BARREL_SCRIPT = preload("res://scripts/explosive_barrel.gd")
const BATTLEFIELD_SCENE = preload("res://scenes/Battlefield.tscn")

class SmokeTarget extends StaticBody3D:
	var team_name := "RED TEAM"
	var health := 100

	func receive_hit(damage: int, _attacker_pos: Vector3, _region: String = "chest", _attacker_name: String = "Test") -> int:
		health -= damage
		return damage

var _failures: Array[String] = []
var _shooter: Node3D

func _ready() -> void:
	_shooter = Node3D.new()
	_shooter.name = "TestShooter"
	add_child(_shooter)
	await get_tree().physics_frame
	await _test_muzzle_origin_and_travel_time()
	await _test_barrel_ignites_on_impact()
	await _test_wall_blocks_bullet()
	await _test_friendly_fire_blocks_bullet()
	await _test_player_shot_starts_at_weapon_muzzle()
	_report()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _make_target(pos: Vector3, team: String) -> SmokeTarget:
	var target := SmokeTarget.new()
	target.team_name = team
	target.position = pos
	target.collision_layer = 1 << 2
	target.collision_mask = 0
	target.add_to_group("explosive_barrels") # Keep test impacts free of particle/decal effects.
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55
	shape.shape = sphere
	target.add_child(shape)
	add_child(target)
	return target

func _spawn_bullet(muzzle: Node3D, speed: float, range_m := 30.0, team := "IRON LEGION") -> Node3D:
	var bullet = BULLET_SCRIPT.new()
	bullet.configure(muzzle.global_position, Vector3.FORWARD, speed, 20, range_m, "Test shooter", team, _shooter, 20, 0.0)
	add_child(bullet)
	return bullet

func _make_muzzle(pos: Vector3) -> Marker3D:
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = pos
	add_child(muzzle)
	return muzzle

func _test_muzzle_origin_and_travel_time() -> void:
	var muzzle := _make_muzzle(Vector3(2.0, 1.5, 0.0))
	var target := _make_target(Vector3(2.0, 1.5, -6.0), "RED TEAM")
	var bullet := _spawn_bullet(muzzle, 20.0)
	_check(bullet.global_position.is_equal_approx(muzzle.global_position), "bullet did not start at the muzzle marker")
	await get_tree().create_timer(0.08).timeout
	_check(target.health == 100, "bullet damaged target before its travel time elapsed")
	_check(bullet.global_position.z < muzzle.global_position.z, "visible bullet did not move downrange")
	await get_tree().create_timer(0.5).timeout
	_check(target.health == 80, "bullet did not apply damage on impact")
	_check(not is_instance_valid(bullet), "bullet remained alive after impact")
	target.queue_free()
	muzzle.queue_free()
	await get_tree().physics_frame

func _test_wall_blocks_bullet() -> void:
	var wall := StaticBody3D.new()
	wall.position = Vector3(0.0, 1.5, -3.0)
	wall.collision_layer = 1
	wall.collision_mask = 0
	var wall_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 3.0, 0.2)
	wall_shape.shape = box
	wall.add_child(wall_shape)
	add_child(wall)
	var target := _make_target(Vector3(0.0, 1.5, -7.0), "RED TEAM")
	var muzzle := _make_muzzle(Vector3(0.0, 1.5, 0.0))
	_spawn_bullet(muzzle, 40.0)
	await get_tree().create_timer(0.35).timeout
	_check(target.health == 100, "bullet passed through a blocking wall")
	wall.queue_free()
	target.queue_free()
	muzzle.queue_free()
	await get_tree().physics_frame

func _test_barrel_ignites_on_impact() -> void:
	var barrel = BARREL_SCRIPT.new()
	barrel.position = Vector3(0.0, 0.0, -4.0)
	add_child(barrel)
	var muzzle := _make_muzzle(Vector3(0.0, 0.65, 0.0))
	_spawn_bullet(muzzle, 40.0)
	await get_tree().create_timer(0.25).timeout
	_check(barrel.is_burning, "bullet impact did not ignite the explosive barrel")
	barrel.queue_free()
	muzzle.queue_free()
	await get_tree().physics_frame

func _test_friendly_fire_blocks_bullet() -> void:
	var ally := _make_target(Vector3(0.0, 1.5, -3.0), "IRON LEGION")
	var enemy := _make_target(Vector3(0.0, 1.5, -7.0), "RED TEAM")
	var muzzle := _make_muzzle(Vector3(0.0, 1.5, 0.0))
	_spawn_bullet(muzzle, 40.0)
	await get_tree().create_timer(0.35).timeout
	_check(ally.health == 100, "bullet damaged a friendly actor")
	_check(enemy.health == 100, "bullet passed through a friendly actor")
	ally.queue_free()
	enemy.queue_free()
	muzzle.queue_free()
	await get_tree().physics_frame

func _test_player_shot_starts_at_weapon_muzzle() -> void:
	MatchState.map_name = "BATTLEFIELD"
	MatchState.mode = "CONQUEST"
	MatchState.player_team = "IRON LEGION"
	var battlefield := BATTLEFIELD_SCENE.instantiate()
	add_child(battlefield)
	await get_tree().process_frame
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	_check(player != null, "Battlefield did not create the player for muzzle-origin test")
	if player != null:
		var muzzle := player.get("weapon_muzzle") as Node3D
		_check(muzzle != null, "player weapon has no muzzle marker")
		if muzzle != null:
			get_tree().paused = true
			player.set("fire_cooldown", 0.0)
			player.call("_shoot")
			var fired_bullet: Node3D
			for projectile in get_tree().get_nodes_in_group("ballistic_bullets"):
				if projectile.get("shooter") == player:
					fired_bullet = projectile as Node3D
					break
			_check(fired_bullet != null, "player shot did not create a ballistic projectile")
			if fired_bullet != null:
				_check(fired_bullet.global_position.distance_to(muzzle.global_position) < 0.001, "player projectile did not start at the weapon muzzle")
			get_tree().paused = false
	battlefield.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame

func _report() -> void:
	if _failures.is_empty():
		print("PROJECTILE_SMOKE_OK")
	else:
		for failure in _failures:
			push_error("PROJECTILE_SMOKE_FAIL: " + failure)
		print("PROJECTILE_SMOKE_FAILED: %d" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)
