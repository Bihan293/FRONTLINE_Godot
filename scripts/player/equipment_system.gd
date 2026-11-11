extends RefCounted
class_name FRONTLINEPlayerEquipment

## Роль, стартовое снаряжение и переключение оружия/лопаты.
## Компонент владеет WeaponController, игрок отвечает за viewmodel и HUD.

const SIDEARM_INDEX := FRONTLINEWeaponCatalog.SIDEARM_INDEX
const SFX_UI = preload("res://assets/audio/ui_click.ogg")

var weapons := FRONTLINEWeaponController.new()
var role := "ASSAULT"

var _player: CharacterBody3D

func setup(player: CharacterBody3D) -> void:
	_player = player

func init_inventory() -> void:
	role = _normalize_role(MatchState.player_role)
	configure_role(role)

	var grenades = _player.get("_grenades")
	var healing = _player.get("_healing")
	match MatchState.loadout_preset:
		"ASSAULT":
			grenades.set("grenade_count", int(grenades.get("grenade_count")) + 1)
			healing.set("medkits", maxi(1, int(healing.get("medkits")) - 1))
		"SURVIVAL":
			grenades.set("grenade_count", maxi(0, int(grenades.get("grenade_count")) - 1))
			healing.set("medkits", int(healing.get("medkits")) + 1)

	var chosen_primary := MatchState.primary_weapon_index
	if chosen_primary >= 0 and chosen_primary < FRONTLINEWeaponCatalog.count():
		weapons.set_primary_slot(chosen_primary)
	weapons.select_primary(true)

	var chosen_grenades := MatchState.grenades_override
	if chosen_grenades >= 0:
		grenades.set("grenade_count", chosen_grenades)
	var chosen_smoke := MatchState.smoke_override
	if chosen_smoke >= 0:
		grenades.set("smoke_count", chosen_smoke)
	var chosen_medkits := MatchState.medkits_override
	if chosen_medkits >= 0:
		healing.set("medkits", chosen_medkits)
	var chosen_rockets := MatchState.rockets_override
	if chosen_rockets >= 0:
		weapons.set_reserve_for(7, chosen_rockets)

func configure_role(role_name: String) -> void:
	role = _normalize_role(role_name)
	weapons.configure_role(role)
	var grenades = _player.get("_grenades")
	var healing = _player.get("_healing")
	var drone = _player.get("_drone")
	match role:
		"SNIPER":
			grenades.set("grenade_count", 1)
			grenades.set("smoke_count", 2)
			healing.set("medkits", 2)
			drone.set("charge_available", false)
		"ANTI_TANK":
			grenades.set("grenade_count", 1)
			grenades.set("smoke_count", 1)
			healing.set("medkits", 2)
			drone.set("charge_available", false)
		"MEDIC":
			grenades.set("grenade_count", 2)
			grenades.set("smoke_count", 2)
			healing.set("medkits", 5)
			drone.set("charge_available", false)
		"RADIO_OPERATOR":
			grenades.set("grenade_count", 1)
			grenades.set("smoke_count", 2)
			healing.set("medkits", 2)
			drone.set("charge_available", true)
		_:
			role = "ASSAULT"
			grenades.set("grenade_count", 3)
			grenades.set("smoke_count", 2)
			healing.set("medkits", 2)
			drone.set("charge_available", false)

func set_primary_slot(index: int) -> void:
	weapons.set_primary_slot(index)

func apply_loadout(role_name: String, primary_index: int) -> void:
	configure_role(role_name)
	if primary_index >= 0 and primary_index < FRONTLINEWeaponCatalog.count():
		weapons.set_primary_slot(primary_index)
	weapons.select_primary(true)
	var shovel = _player.get("_shovel")
	if shovel != null:
		shovel.set("equipped", false)
	_player.call("_equip_weapon_visual")
	_player.call("_refresh_ammo")
	_player.call("_refresh_equipment")

func weapon_data() -> FRONTLINEWeaponDef:
	return weapons.current_def()

func switch_weapon(index: int) -> void:
	if bool(_player.get("is_dead")) or index < 0 or index >= FRONTLINEWeaponCatalog.count():
		return
	var grenades = _player.get("_grenades")
	if grenades != null and bool(grenades.call("is_busy")):
		return
	if not weapons.role_weapon_indices.has(index):
		return
	var shovel = _player.get("_shovel")
	var was_shovel_equipped := shovel != null and bool(shovel.get("equipped"))
	if shovel != null:
		shovel.set("equipped", false)
	if index == weapons.current_index:
		if was_shovel_equipped:
			_player.call("_equip_weapon_visual")
			_player.call("_refresh_ammo")
		return
	if not weapons.switch_to(index):
		return
	_player.call("_set_aiming", false)
	var controls = _player.get("mobile_controls")
	if controls != null and controls.has_method("reset_aim"):
		controls.call("reset_aim")
	_player.set("weapon_kick", 0.0)
	var mount: Node3D = _player.get("weapon_mount")
	if mount != null:
		mount.rotation = Vector3.ZERO
	_player.call("_equip_weapon_visual")
	_player.call("_refresh_ammo")
	_player.call("_play_sfx", _player.get("sfx_ui"), SFX_UI, -6.0, 1.0)

## QA-fix TASK-0022: цикл снаряжения в руке — автомат → пистолет → лопата.
func cycle_equipment(direction: int) -> void:
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")):
		return
	if _player.get("active_drone") != null or _player.get("mounted_vehicle") != null:
		return
	var grenades = _player.get("_grenades")
	if grenades != null and bool(grenades.call("is_busy")):
		return
	var shovel = _player.get("_shovel")
	var shovel_equipped := shovel != null and bool(shovel.get("equipped"))
	var current := "primary"
	if shovel_equipped:
		current = "shovel"
	elif weapons.current_index == SIDEARM_INDEX:
		current = "sidearm"
	var order := ["primary", "sidearm", "shovel"]
	var index: int = order.find(current)
	index = posmod(index + direction, order.size())
	match str(order[index]):
		"primary":
			if shovel_equipped:
				shovel.set("equipped", false)
				_player.call("_equip_weapon_visual")
				_player.call("_refresh_ammo")
			if weapons.current_index == SIDEARM_INDEX:
				switch_weapon(weapons.last_primary_index)
		"sidearm":
			if shovel_equipped:
				shovel.set("equipped", false)
				_player.call("_equip_weapon_visual")
			if weapons.current_index != SIDEARM_INDEX:
				toggle_sidearm()
		"shovel":
			if not shovel_equipped:
				_player.call("_toggle_shovel")
	refresh_equipment_icon()

func refresh_equipment_icon() -> void:
	var controls = _player.get("mobile_controls")
	if controls == null or not is_instance_valid(controls):
		return
	if not controls.has_method("set_equipment_info"):
		return
	var shovel = _player.get("_shovel")
	var shovel_equipped := shovel != null and bool(shovel.get("equipped"))
	var icon_id := "rifle"
	var label := "АВТОМАТ"
	if shovel_equipped:
		icon_id = "shovel"
		label = "ЛОПАТА"
	elif weapons.current_index == SIDEARM_INDEX:
		icon_id = "sidearm"
		label = "ПИСТОЛЕТ"
	else:
		var weapon := weapon_data()
		if str(weapon.id) == "panzerfaust":
			icon_id = "rpg"
			label = "РПГ"
		else:
			label = str(weapon.display_name)
	controls.call("set_equipment_info", icon_id, label)

func cycle_weapon(direction: int) -> void:
	if weapons.role_weapon_indices.is_empty():
		return
	var slot := weapons.role_weapon_indices.find(weapons.current_index)
	if slot < 0:
		slot = 0
	slot = posmod(slot + direction, weapons.role_weapon_indices.size())
	switch_weapon(weapons.role_weapon_indices[slot])
	refresh_equipment_icon()

func select_weapon_slot(slot: int) -> void:
	if slot < 0 or slot >= weapons.role_weapon_indices.size():
		return
	switch_weapon(weapons.role_weapon_indices[slot])

func toggle_sidearm() -> void:
	if bool(_player.get("is_dead")) or bool(_player.get("input_locked")):
		return
	var grenades = _player.get("_grenades")
	if grenades != null and bool(grenades.call("is_busy")):
		return
	var shovel = _player.get("_shovel")
	if shovel != null and bool(shovel.get("equipped")):
		shovel.set("equipped", false)
		_player.call("_equip_weapon_visual")
	if weapons.current_index == SIDEARM_INDEX:
		switch_weapon(weapons.last_primary_index)
	else:
		switch_weapon(SIDEARM_INDEX)

func _normalize_role(role_name: String) -> String:
	match role_name:
		"SNIPER", "ANTI_TANK", "MEDIC", "RADIO_OPERATOR":
			return role_name
		_:
			return "ASSAULT"
