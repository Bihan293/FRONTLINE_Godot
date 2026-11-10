extends RefCounted
class_name FRONTLINEPlayerPickups

## Полевые подборы: близость, подсказки, патроны и замена оружия.
## Не владеет HUD и камерой — игрок забирает текст и обновляет UI.

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
	_player.call("_spawn_weapon_drop", previous_index, previous_clip, previous_reserve)
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
