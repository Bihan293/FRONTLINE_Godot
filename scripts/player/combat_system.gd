extends RefCounted
class_name FRONTLINEPlayerCombat

## Стрельба, перезарядка и обратная связь по попаданиям.
## Компонент ведёт огонь через WeaponController, игрок владеет камерой и HUD.

const HIT_EFFECTS = preload("res://scripts/hit_effects.gd")
const ROCKET_PROJECTILE_SCRIPT = preload("res://scripts/rocket_projectile.gd")
const BULLET_PROJECTILE_SCRIPT = preload("res://scripts/bullet_projectile.gd")
const SFX_EMPTY = preload("res://assets/audio/empty.ogg")
const SFX_RELOAD_OUT = preload("res://assets/audio/reload_out.ogg")
const SFX_RELOAD_IN = preload("res://assets/audio/reload_in.wav")
const SFX_HIT_FLESH = preload("res://assets/audio/hit_flesh.ogg")

const SPEED := 5.2
const WORLD_LAYER_MASK := 1 << 0
const HITBOX_LAYER_MASK := 1 << 1
const RAY_COLLISION_MASK := WORLD_LAYER_MASK | HITBOX_LAYER_MASK

var _player: CharacterBody3D

func setup(player: CharacterBody3D) -> void:
	_player = player

func shoot() -> void:
	var weapons = _player.get("_weapons")
	var grenades = _player.get("_grenades")
	if grenades != null and bool(grenades.call("is_busy")):
		return
	var shovel = _player.get("_shovel")
	if shovel != null and bool(shovel.get("equipped")):
		_player.call("_use_shovel_action", false)
		return
	if bool(_player.get("is_healing")):
		_player.call("_cancel_healing")
	if weapons.is_reloading or weapons.fire_cooldown > 0.0 or bool(_player.get("is_dead")) or bool(_player.get("input_locked")):
		return
	var weapon: FRONTLINEWeaponDef = weapons.current_def()
	if weapons.ammo <= 0:
		if weapons.reserve > 0 and not weapons.is_reloading:
			reload()
		else:
			_player.call("_play_sfx", _player.get("sfx_empty"), SFX_EMPTY, -5.0, randf_range(0.95, 1.05))
			weapons.fire_cooldown = 0.25
		return
	if not weapons.consume_round():
		return
	weapons.fire_cooldown = float(weapon.fire_interval)
	var audio = _player.get("_audio")
	if audio != null:
		audio.call("play_shot", str(weapon.id))

	var camera: Camera3D = _player.get("camera")
	# QA-fix TASK-0022: попадание считается ДО отдачи. Раньше recoil успевал
	# повернуть камеру на ~1.5-2°, и снайперская пуля в прицеле уходила выше
	# цели (в зуме это стабильный промах «не регает урон»).
	var pre_recoil_dir := -camera.global_transform.basis.z
	var pre_aim_end := camera.global_position + pre_recoil_dir * float(weapon.range_m)
	var pre_aim_query := PhysicsRayQueryParameters3D.create(camera.global_position, pre_aim_end)
	pre_aim_query.collision_mask = RAY_COLLISION_MASK
	pre_aim_query.exclude = [_player.get_rid()]
	pre_aim_query.collide_with_areas = true
	var pre_aim_hit := _player.get_world_3d().direct_space_state.intersect_ray(pre_aim_query)
	var pre_aim_point: Vector3 = pre_aim_hit.get("position", pre_aim_end)

	var recoil: Vector2 = _player.get("recoil")
	if str(weapon.id) == "panzerfaust":
		recoil.y = minf(recoil.y + 0.055, 0.18)
		recoil.x = clampf(recoil.x + randf_range(-0.015, 0.015), -0.06, 0.06)
		_player.set("recoil", recoil)
		_player.set("weapon_kick", 0.16)
		var muzzle_flash: MeshInstance3D = _player.get("muzzle_flash")
		if muzzle_flash != null:
			muzzle_flash.visible = true
			_player.set("muzzle_flash_time", 0.08)
		_player.call("_apply_look")
		var shoot_dir := pre_recoil_dir
		var desired_spawn := camera.global_position + shoot_dir * 0.45 + camera.global_transform.basis.x * 0.14 - camera.global_transform.basis.y * 0.08
		var wall_query := PhysicsRayQueryParameters3D.create(camera.global_position, desired_spawn)
		wall_query.collision_mask = WORLD_LAYER_MASK
		wall_query.exclude = [_player.get_rid()]
		var wall_hit := _player.get_world_3d().direct_space_state.intersect_ray(wall_query)
		var spawn_pos := desired_spawn
		if not wall_hit.is_empty():
			spawn_pos = wall_hit.position - shoot_dir * 0.10

		var rocket = ROCKET_PROJECTILE_SCRIPT.new()
		_player.get_parent().add_child(rocket)
		rocket.launch(spawn_pos, shoot_dir, "Player", MatchState.player_team, _player)
		return

	var casing_pos := camera.global_position + camera.global_transform.basis.x * 0.22 - camera.global_transform.basis.y * 0.12 - camera.global_transform.basis.z * 0.35
	var casing_vel := camera.global_transform.basis.x * 2.6 + camera.global_transform.basis.y * 1.4 - camera.global_transform.basis.z * 0.4
	HIT_EFFECTS.spawn_casing(_player.get_parent(), casing_pos, casing_vel)

	var kick_strength: float = 0.08
	var trauma_add: float = 0.18
	match str(weapon.id):
		"shotgun":
			kick_strength = 0.22
			trauma_add = 0.45
			recoil.y = minf(recoil.y + 0.038, 0.16)
			recoil.x = clampf(recoil.x + randf_range(-0.015, 0.015), -0.05, 0.05)
		"mosin", "kar98k":
			kick_strength = 0.18
			trauma_add = 0.38
			recoil.y = minf(recoil.y + 0.030, 0.15)
			recoil.x = clampf(recoil.x + randf_range(-0.012, 0.012), -0.045, 0.045)
		"ak47":
			kick_strength = 0.11
			trauma_add = 0.24
			recoil.y = minf(recoil.y + randf_range(0.012, 0.020), 0.14)
			recoil.x = clampf(recoil.x + randf_range(-0.008, 0.008), -0.045, 0.045)
		"mp40", "ppsh41":
			kick_strength = 0.07
			trauma_add = 0.14
			recoil.y = minf(recoil.y + randf_range(0.006, 0.011), 0.11)
			recoil.x = clampf(recoil.x + randf_range(-0.005, 0.005), -0.035, 0.035)
		_:
			kick_strength = 0.08
			trauma_add = 0.16
			recoil.y = minf(recoil.y + randf_range(0.008, 0.014), 0.12)
			recoil.x = clampf(recoil.x + randf_range(-0.006, 0.006), -0.04, 0.04)
	_player.set("recoil", recoil)

	_player.set("weapon_kick", kick_strength)
	_player.call("add_camera_trauma", trauma_add)
	var flash: MeshInstance3D = _player.get("muzzle_flash")
	if flash != null:
		flash.visible = true
		_player.set("muzzle_flash_time", 0.045)
	_player.call("_apply_look")

	var mobile_move: Vector2 = _player.get("mobile_move")
	var velocity: Vector3 = _player.velocity
	var aiming := bool(_player.get("aiming"))
	var stance := int(_player.get("stance"))
	var spread := float(weapon.spread) * (0.42 if aiming else 1.0)
	if stance == 0 and (mobile_move.length() > 0.2 or velocity.length() > SPEED + 0.5):
		spread += 0.012
	var weapon_muzzle: Node3D = _player.get("weapon_muzzle")
	var bullet_origin := weapon_muzzle.global_position if is_instance_valid(weapon_muzzle) else camera.global_position
	# The camera ray selects the point the player is aiming at; it never applies
	# damage. The actual round travels from the muzzle to that point and collides
	# along its own path, preserving the visible muzzle-to-sight parallax.
	var base_direction := (pre_aim_point - bullet_origin).normalized()
	var player_team: String = MatchState.player_team
	var pellet_count := int(weapon.pellets)
	for _pellet_index in range(pellet_count):
		var dir := base_direction
		dir = dir.rotated(camera.global_transform.basis.y, randf_range(-spread, spread))
		dir = dir.rotated(camera.global_transform.basis.x, randf_range(-spread, spread))
		_spawn_ballistic_bullet(
			bullet_origin,
			dir,
			float(weapon.muzzle_velocity),
			int(weapon.damage),
			float(weapon.range_m),
			"Player",
			player_team,
			_player
		)

func reload() -> void:
	var shovel = _player.get("_shovel")
	if shovel != null and bool(shovel.get("equipped")):
		return
	var grenades = _player.get("_grenades")
	if grenades != null and bool(grenades.call("is_busy")):
		return
	if bool(_player.get("is_healing")) or bool(_player.get("is_dead")) or bool(_player.get("input_locked")):
		return
	var weapons = _player.get("_weapons")
	if bool(weapons.call("start_reload")):
		_player.call("_play_sfx", _player.get("sfx_reload_out"), SFX_RELOAD_OUT, -6.0, 1.0)

func on_reload_finished() -> void:
	_player.call("_play_sfx", _player.get("sfx_reload_in"), SFX_RELOAD_IN, -4.0, 1.0)

func on_projectile_hit(actor: Node, damage_applied: int, was_alive: bool, _region: String) -> void:
	if not is_instance_valid(actor) or damage_applied <= 0:
		return
	_player.call("_pop_damage", damage_applied)
	var world := _player.get_parent()
	if world != null and world.has_method("record_player_damage"):
		world.call("record_player_damage", damage_applied)
	if not actor.is_in_group("explosive_barrels"):
		_player.call("_play_sfx", _player.get("sfx_hit"), SFX_HIT_FLESH, -4.0, randf_range(0.9, 1.1))
	var hud = _player.get("_player_hud")
	if hud != null:
		hud.call("flash_hit")
	if was_alive and actor.is_in_group("damageable_actor") and "health" in actor and float(actor.get("health")) <= 0.0:
		# QA-fix TASK-0022: вместо «pew»-джингла — глухой звук попадания.
		_player.call("_play_sfx", _player.get("sfx_kill"), SFX_HIT_FLESH, -6.0, randf_range(0.72, 0.82))
		if world != null and world.has_method("add_kill"):
			world.call("add_kill")

func _spawn_ballistic_bullet(origin: Vector3, direction: Vector3, speed: float, damage: int, range_m: float, owner_name: String, owner_team: String, owner: Node) -> bool:
	var world := _player.get_parent()
	if world == null:
		return false
	if world.has_method("spawn_bullet_projectile"):
		return bool(world.call("spawn_bullet_projectile", origin, direction, speed, damage, range_m, owner_name, owner_team, owner))
	var bullet = BULLET_PROJECTILE_SCRIPT.new()
	world.add_child(bullet)
	bullet.configure(origin, direction, speed, damage, range_m, owner_name, owner_team, owner)
	return true
