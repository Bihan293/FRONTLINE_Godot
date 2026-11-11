extends RefCounted
class_name FRONTLINEPlayerPickups

## Полевые подборы: близость, подсказки, патроны и замена оружия.
## Компонент сам обновляет подсказку и мобильную кнопку взаимодействия.

const FIELD_PICKUP_SCRIPT = preload("res://scripts/field_pickup.gd")
const SFX_UI = preload("res://assets/audio/ui_click.ogg")

var nearby: Array[Node3D] = []
var _player: CharacterBody3D

func setup(player: CharacterBody3D) -> void:
	_player = player

func register(pickup: Node3D) -> void:
	if is_instance_valid(pickup) and not nearby.has(pickup):
		nearby.append(pickup)

func unregister(pickup: Node3D) -> void:
	nearby.erase(pickup)

func prune() -> void:
	var i := nearby.size() - 1
	while i >= 0:
		if not is_instance_valid(nearby[i]):
			nearby.remove_at(i)
		i -= 1

func nearest_field_pickup() -> Node3D:
	prune()
	var nearest: Node3D = null
	var nearest_distance := 2.6
	var candidates: Array[Node3D] = []
	for pickup in nearby:
		if not candidates.has(pickup):
			candidates.append(pickup)
	for group_name in ["field_weapon_pickups", "field_supply_crates"]:
		for node in _player.get_tree().get_nodes_in_group(group_name):
			var pickup := node as Node3D
			if pickup != null and not candidates.has(pickup):
				candidates.append(pickup)
	for pickup in candidates:
		if not is_instance_valid(pickup):
			continue
		if not pickup.has_method("can_collect") or not bool(pickup.call("can_collect", _player)):
			continue
		var distance := _player.global_position.distance_to(pickup.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = pickup
	return nearest

func refresh_prompt() -> void:
	var vehicles = _player.get("_vehicles")
	if vehicles != null:
		var vehicle = vehicles.get("vehicle")
		if vehicle != null and not is_instance_valid(vehicle):
			vehicles.set("vehicle", null)
	var target := prompt_target()
	var hud = _player.get("_player_hud")
	if hud != null:
		var prompt_text := ""
		if target != null and target.has_method("prompt_text"):
			prompt_text = str(target.call("prompt_text", OS.has_feature("mobile")))
		hud.call("set_pickup_prompt", prompt_text)
	var controls = _player.get("mobile_controls")
	if controls != null:
		controls.call("set_interact_visible", target != null)

func interact() -> void:
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")):
		return
	var mounted = _player.get("mounted_vehicle")
	if mounted != null and is_instance_valid(mounted):
		_player.call("_exit_vehicle")
		return
	var enterable: Node3D = _player.call("_nearest_enterable")
	if enterable != null:
		_player.call("_enter_vehicle", enterable)
		refresh_prompt()
		return
	var pickup := nearest_field_pickup()
	if pickup == null or not pickup.has_method("collect"):
		return
	if bool(pickup.call("collect", _player)):
		unregister(pickup)
		refresh_prompt()
		_player.call("_play_sfx", _player.get("sfx_ui"), SFX_UI, -2.0, 1.12)

func spawn_weapon_drop(index: int, clip: int, reserve: int) -> void:
	var parent := _player.get_parent()
	if parent == null:
		return
	var basis := _player.global_transform.basis
	var drop_pos := _player.global_position + basis.x * 0.75 + basis.z * 0.45 + Vector3.UP * 0.75
	var drop_velocity := basis.x * 1.0 + basis.z * 0.6 + Vector3.UP * 1.5
	if parent.has_method("spawn_weapon_pickup"):
		parent.call("spawn_weapon_pickup", drop_pos, index, clip, reserve, drop_velocity)
		return
	var dropped = FIELD_PICKUP_SCRIPT.new()
	dropped.configure_weapon(index, clip, reserve)
	parent.add_child(dropped)
	dropped.global_position = drop_pos
	dropped.launch(drop_velocity)

func prompt_target() -> Node3D:
	var mounted = _player.get("mounted_vehicle")
	if mounted != null and is_instance_valid(mounted):
		return mounted
	var enterable: Node3D = _player.call("_nearest_enterable")
	if enterable != null:
		return enterable
	return nearest_field_pickup()

func can_take_field_ammo(amount: int) -> bool:
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")) or amount <= 0:
		return false
	var weapons = _player.get("_weapons")
	return bool(weapons.call("can_take_reserve"))

func take_field_ammo(amount: int) -> int:
	if not can_take_field_ammo(amount):
		return 0
	var weapons = _player.get("_weapons")
	return int(weapons.call("add_reserve", amount))

func can_take_weapon(index: int, _clip: int, _reserve: int) -> bool:
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")):
		return false
	if index < 0 or index >= FRONTLINEWeaponCatalog.count():
		return false
	if index != int(_player.get("current_weapon_index")):
		return true
	var def := FRONTLINEWeaponCatalog.get_def(index)
	return int(_player.get("ammo")) < def.magazine or int(_player.get("reserve_ammo")) < def.reserve

func take_weapon(index: int, clip: int, reserve: int) -> bool:
	if not can_take_weapon(index, clip, reserve):
		return false
	var weapons = _player.get("_weapons")
	if index == int(_player.get("current_weapon_index")):
		weapons.call("refill_current", clip, reserve)
		_player.call("_refresh_ammo")
		return true

	var previous_index := int(_player.get("current_weapon_index"))
	var previous_clip := int(_player.get("ammo"))
	var previous_reserve := int(_player.get("reserve_ammo"))
	weapons.call("store_current")
	weapons.call("clear_slot", previous_index)
	spawn_weapon_drop(previous_index, previous_clip, previous_reserve)
	weapons.call("replace_role_slot", previous_index, index)
	weapons.call("equip_from_pickup", index, clip, reserve)
	_player.set("weapon_kick", 0.0)
	_player.call("_set_aiming", false)
	var controls = _player.get("mobile_controls")
	if controls != null and controls.has_method("reset_aim"):
		controls.call("reset_aim")
	_player.call("_equip_weapon_visual")
	_player.call("_refresh_ammo")
	return true
