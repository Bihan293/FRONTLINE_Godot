extends RefCounted
class_name FRONTLINEPlayerHealth

## Здоровье игрока: урон, смерть, экран K.I.A. и респавн.
## Компонент владеет состоянием жизни, игрок остаётся телом и владельцем HUD.

const WORLD_LAYER_MASK := 1 << 0
const SFX_HIT_FLESH = preload("res://assets/audio/hit_flesh.ogg")

var health := 100.0
var is_dead := false
var respawn_position := Vector3.ZERO

var _player: CharacterBody3D
var _max_health := 100.0

func setup(player: CharacterBody3D, max_health: float) -> void:
	_player = player
	_max_health = max_health
	health = max_health

func receive_hit(damage: int, attacker_pos: Vector3, region: String = "chest", attacker_name: String = "Enemy") -> void:
	if is_dead:
		return
	_player.call("_cancel_healing")
	health = maxf(0.0, health - float(damage))
	var hud = _player.get("_player_hud")
	if hud != null:
		hud.call("flash_blood")
	_player.call("_play_sfx", _player.get("sfx_hit"), SFX_HIT_FLESH, 0.0, randf_range(0.9, 1.1))

	var recoil: Vector2 = _player.get("recoil")
	var to_attacker := (attacker_pos - _player.global_position).normalized()
	recoil.y += randf_range(0.02, 0.05)
	recoil.x += clampf(-to_attacker.x * 0.04, -0.06, 0.06)
	_player.set("recoil", recoil)

	_player.call("_refresh_health")
	if health <= 0.0:
		die(attacker_name, attacker_pos, region)

func die(killer_name: String, attacker_pos: Vector3 = Vector3.ZERO, region: String = "chest") -> void:
	var drone = _player.get("_drone")
	if drone != null:
		drone.call("return_to_operator")
	var mounted = _player.get("mounted_vehicle")
	if mounted != null and is_instance_valid(mounted):
		_player.call("_exit_vehicle")
	_player.call("_cancel_healing")
	var camera: Camera3D = _player.get("camera")
	if camera != null:
		camera.current = true
	var controls = _player.get("mobile_controls")
	if controls != null:
		controls.call("set_drone_mode", false)

	is_dead = true
	var vault = _player.get("_vault")
	if vault != null:
		vault.call("cancel")
	var grenades = _player.get("_grenades")
	if grenades != null:
		grenades.call("drop_on_death")
	health = 0.0
	_player.velocity = Vector3.ZERO
	_player.collision_layer = 0
	var body: Node3D = _player.get("player_body")
	if body != null and body.has_method("set_ragdoll"):
		var hit_dir := _player.global_position - attacker_pos
		body.visible = true
		body.call("set_ragdoll", true, hit_dir, region == "head")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var world := _player.get_parent()
	if world != null and world.has_method("record_player_death"):
		world.call("record_player_death")
	var hud = _player.get("_player_hud")
	if hud != null:
		hud.call("set_pickup_prompt", "")
	if controls != null:
		controls.call("set_interact_visible", false)

	# Pull back from the eyes so the death is visible as a body, not only a red overlay.
	if camera != null:
		camera.position = Vector3(0.0, 2.15, 3.1)
		camera.rotation = Vector3(deg_to_rad(-27.0), 0.0, 0.0)
	var weapon_root: Node3D = _player.get("weapon_root")
	if weapon_root != null:
		weapon_root.visible = false
	var arm_left: Node3D = _player.get("_view_arm_left")
	if arm_left != null:
		arm_left.visible = false
	var arm_right: Node3D = _player.get("_view_arm_right")
	if arm_right != null:
		arm_right.visible = false
	if hud != null:
		hud.call("set_crosshair_visible", false)
		hud.call("show_death", killer_name)
		_player.get_tree().create_timer(2.6, false).timeout.connect(func():
			if not is_dead:
				return
			var current_hud = _player.get("_player_hud")
			if current_hud != null and bool(current_hud.call("is_death_visible")):
				var parent_node := _player.get_parent()
				if parent_node != null and parent_node.has_method("open_tactical_deploy"):
					current_hud.call("hide_death")
					parent_node.call("open_tactical_deploy")
		)

func respawn() -> void:
	var drone = _player.get("_drone")
	if drone != null:
		drone.call("return_to_operator")
	var camera: Camera3D = _player.get("camera")
	if camera != null:
		camera.current = true

	is_dead = false
	var vault = _player.get("_vault")
	if vault != null:
		vault.call("cancel")
	var grenades = _player.get("_grenades")
	if grenades != null:
		grenades.call("reset")
	_player.collision_layer = WORLD_LAYER_MASK
	health = _max_health
	var body: Node3D = _player.get("player_body")
	if body != null and body.has_method("set_ragdoll"):
		body.call("set_ragdoll", false)
		body.visible = false
	var weapon_root: Node3D = _player.get("weapon_root")
	if weapon_root != null:
		weapon_root.visible = true
	var arm_left: Node3D = _player.get("_view_arm_left")
	if arm_left != null:
		arm_left.visible = true
	var arm_right: Node3D = _player.get("_view_arm_right")
	if arm_right != null:
		arm_right.visible = true

	# Роль и основное оружие сохраняются; сбрасываются только патроны и снаряжение.
	var chosen_primary := int(_player.get("role_primary_weapon_index"))
	_player.call("_configure_role_loadout", str(_player.get("player_role")))
	var weapons = _player.get("_weapons")
	if chosen_primary >= 0 and chosen_primary < FRONTLINEWeaponCatalog.count():
		weapons.call("set_primary_slot", chosen_primary)
	weapons.call("select_primary", true)

	var shovel = _player.get("_shovel")
	if shovel != null:
		shovel.call("reset")
	_player.call("_equip_weapon_visual")

	var healing = _player.get("_healing")
	if healing != null:
		healing.call("reset")
	if drone != null:
		drone.set("vertical_input", 0.0)
	_player.set("aiming", false)
	_player.set("aim_blend", 0.0)
	if camera != null:
		camera.fov = GameSettings.fov
	var controls = _player.get("mobile_controls")
	if controls != null:
		if controls.has_method("reset_aim"):
			controls.call("reset_aim")
		if controls.has_method("set_drone_visible"):
			controls.call("set_drone_visible", str(_player.get("player_role")) == "RADIO_OPERATOR")
		if controls.has_method("set_drone_mode"):
			controls.call("set_drone_mode", false)
	_player.set("stance", 0)
	_player.set("lean_amount", 0.0)
	_player.position = respawn_position
	if camera != null:
		camera.position = Vector3(0, 1.80, -0.10)
		camera.rotation = Vector3.ZERO
	_player.set("pitch", 0.0)
	_player.set("yaw", 0.0)
	_player.call("_refresh_ammo")
	_player.call("_refresh_health")
	_player.call("_refresh_equipment")

	var hud = _player.get("_player_hud")
	if hud != null:
		hud.call("reset_after_respawn")
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func pop_damage(amount: int) -> void:
	var hud = _player.get("_player_hud")
	if hud != null:
		hud.call("show_damage", amount)
