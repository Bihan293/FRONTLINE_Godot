extends RefCounted
class_name FRONTLINEPlayerShovel

## Лопата: копание, укладка грунта и переключение снаряжения.
## Компонент владеет грунтом и кулдауном, игрок остаётся телом.

const WORLD_LAYER_MASK := 1 << 0
const MAX_SOIL := 6
const ACTION_COOLDOWN := 0.55

var equipped := false
var carried_soil := 0
var action_cooldown := 0.0

var _player: CharacterBody3D
var _camera: Camera3D

func setup(player: CharacterBody3D, camera: Camera3D) -> void:
	_player = player
	_camera = camera

func toggle() -> void:
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")) or _player.get("active_drone") != null:
		return
	var grenades = _player.get("_grenades")
	if grenades != null and bool(grenades.call("is_busy")):
		return
	equipped = not equipped
	var weapons = _player.get("_weapons")
	weapons.call("cancel_reload")
	_player.call("_set_aiming", false)
	var controls = _player.get("mobile_controls")
	if controls != null:
		controls.call("reset_aim")
	_player.call("_equip_weapon_visual")
	_player.call("_refresh_ammo")

func on_button() -> void:
	if equipped and carried_soil > 0:
		use_action(true)
	else:
		toggle()

func use_action(place_soil: bool) -> void:
	if not equipped or bool(_player.get("is_dead")) or bool(_player.get("input_locked")) or action_cooldown > 0.0:
		return
	var ground := _player.get_tree().get_first_node_in_group("diggable_ground") as Node3D
	if ground == null:
		return
	var target := _target(ground)
	if target == Vector3.INF:
		return
	action_cooldown = ACTION_COOLDOWN
	if place_soil:
		if carried_soil <= 0 or not bool(ground.call("place_soil_at", target)):
			return
		carried_soil -= 1
	else:
		if carried_soil >= MAX_SOIL or not bool(ground.call("dig_at", target)):
			return
		carried_soil += 1
	_player.call("_refresh_ammo")
	_player.call("_refresh_equipment")

func tick(delta: float) -> void:
	action_cooldown = maxf(0.0, action_cooldown - delta)

func reset() -> void:
	equipped = false
	carried_soil = 0
	action_cooldown = 0.0

func _target(ground: Node3D) -> Vector3:
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return Vector3.INF
	forward = forward.normalized()
	var guess := _player.global_position + forward * 1.45
	guess = ground.call("clamp_to_map", guess)
	var floor_y := float(ground.call("surface_height_at", guess))
	var ray_from := _camera.global_position
	var ray_to := Vector3(guess.x, floor_y - 0.25, guess.z)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collision_mask = WORLD_LAYER_MASK
	query.exclude = [_player.get_rid()]
	query.collide_with_areas = false
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.get("collider") != ground:
		return Vector3.INF
	return hit.position
