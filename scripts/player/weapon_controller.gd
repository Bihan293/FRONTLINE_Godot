extends RefCounted
class_name FRONTLINEWeaponController

## Состояние оружия игрока: слоты, патроны, перезарядка, темп стрельбы.
## Не знает про камеру, HUD и меши — только данные и правила.

signal weapon_changed(index: int)
signal ammo_changed
signal reload_started(duration: float)
signal reload_finished

const SIDEARM_INDEX := FRONTLINEWeaponCatalog.SIDEARM_INDEX

var current_index := 0
var last_primary_index := 0
var role := "ASSAULT"
var role_primary_index := 0
var role_weapon_indices: Array[int] = [0, SIDEARM_INDEX]
var ammo := 0
var reserve := 0
var is_reloading := false
var reload_timer := 0.0
var fire_cooldown := 0.0

var _ammo_by_weapon: Array[int] = []
var _reserve_by_weapon: Array[int] = []

func _init() -> void:
	_reset_storage()
	_load_current()

func configure_role(role_name: String) -> void:
	role = _normalize_role(role_name)
	match role:
		"SNIPER":
			role_primary_index = 6
			role_weapon_indices = [6, SIDEARM_INDEX]
		"ANTI_TANK":
			role_primary_index = 7
			role_weapon_indices = [7, 4, SIDEARM_INDEX]
		"MEDIC":
			role_primary_index = 1
			role_weapon_indices = [1, SIDEARM_INDEX]
		"RADIO_OPERATOR":
			role_primary_index = 5
			role_weapon_indices = [5, SIDEARM_INDEX]
		_:
			role = "ASSAULT"
			role_primary_index = 0
			role_weapon_indices = [0, SIDEARM_INDEX]
	current_index = role_primary_index
	last_primary_index = current_index
	_cancel_reload()
	_load_current()

func set_primary_slot(index: int) -> void:
	if index < 0 or index >= FRONTLINEWeaponCatalog.count():
		return
	role_primary_index = index
	role_weapon_indices = [index]
	if index != SIDEARM_INDEX:
		role_weapon_indices.append(SIDEARM_INDEX)

func apply_loadout(role_name: String, primary_index: int) -> void:
	configure_role(role_name)
	set_primary_slot(primary_index)
	select_primary(true)

func select_primary(refill_storage := false) -> void:
	if refill_storage:
		_reset_storage()
	current_index = role_primary_index
	last_primary_index = current_index
	_cancel_reload()
	_load_current()

func set_reserve_for(index: int, amount: int) -> void:
	if index < 0 or index >= _reserve_by_weapon.size():
		return
	_reserve_by_weapon[index] = maxi(0, amount)
	if index == current_index:
		reserve = _reserve_by_weapon[index]
		ammo_changed.emit()

func refill_all() -> void:
	_reset_storage()
	_load_current()

func switch_to(index: int) -> bool:
	if index < 0 or index >= FRONTLINEWeaponCatalog.count():
		return false
	if not role_weapon_indices.has(index) or index == current_index:
		return false
	_store_current()
	current_index = index
	if index != SIDEARM_INDEX:
		last_primary_index = index
	_cancel_reload()
	fire_cooldown = minf(fire_cooldown, 0.22)
	_load_current()
	weapon_changed.emit(current_index)
	return true

func toggle_sidearm() -> bool:
	var target := SIDEARM_INDEX if current_index != SIDEARM_INDEX else last_primary_index
	return switch_to(target)

func cycle(direction: int) -> bool:
	if role_weapon_indices.is_empty():
		return false
	var slot := role_weapon_indices.find(current_index)
	if slot < 0:
		slot = 0
	slot = posmod(slot + direction, role_weapon_indices.size())
	return switch_to(role_weapon_indices[slot])

func tick(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if not is_reloading:
		return
	reload_timer -= delta
	if reload_timer <= 0.0:
		_finish_reload()

func start_reload() -> bool:
	if is_reloading:
		return false
	var def := current_def()
	if ammo >= def.magazine or reserve <= 0:
		return false
	is_reloading = true
	reload_timer = def.reload_time
	reload_started.emit(def.reload_time)
	return true

func cancel_reload() -> void:
	if is_reloading:
		_cancel_reload()

func can_fire() -> bool:
	return not is_reloading and fire_cooldown <= 0.0 and ammo > 0

func consume_round() -> bool:
	if ammo <= 0:
		return false
	ammo -= 1
	ammo_changed.emit()
	return true

func add_reserve(amount: int) -> int:
	if amount <= 0:
		return 0
	var def := current_def()
	var applied := mini(amount, def.reserve - reserve)
	if applied <= 0:
		return 0
	reserve += applied
	_reserve_by_weapon[current_index] = reserve
	ammo_changed.emit()
	return applied

func refill_current(clip: int, extra_reserve: int) -> void:
	var def := current_def()
	var needed := def.magazine - ammo
	var taken := mini(needed, maxi(0, clip))
	ammo += taken
	var leftover := maxi(0, clip) - taken
	reserve = mini(def.reserve, reserve + leftover + maxi(0, extra_reserve))
	_store_current()
	ammo_changed.emit()

func replace_role_slot(old_index: int, new_index: int) -> void:
	if new_index < 0 or new_index >= FRONTLINEWeaponCatalog.count():
		return
	var slot := role_weapon_indices.find(old_index)
	if slot >= 0:
		role_weapon_indices[slot] = new_index
	elif not role_weapon_indices.has(new_index):
		role_weapon_indices.insert(0, new_index)

func equip_from_pickup(index: int, clip: int, reserve_amount: int) -> void:
	if index < 0 or index >= FRONTLINEWeaponCatalog.count():
		return
	var def := FRONTLINEWeaponCatalog.get_def(index)
	current_index = index
	_ammo_by_weapon[index] = mini(def.magazine, maxi(0, clip))
	_reserve_by_weapon[index] = mini(def.reserve, maxi(0, reserve_amount))
	_cancel_reload()
	fire_cooldown = 0.0
	_load_current()
	weapon_changed.emit(index)

func store_current() -> void:
	_store_current()

func clear_slot(index: int) -> void:
	if index < 0 or index >= _ammo_by_weapon.size():
		return
	_ammo_by_weapon[index] = 0
	_reserve_by_weapon[index] = 0
	if index == current_index:
		ammo = 0
		reserve = 0
		ammo_changed.emit()

func can_take_reserve() -> bool:
	return reserve < current_def().reserve

func current_def() -> FRONTLINEWeaponDef:
	return FRONTLINEWeaponCatalog.get_def(current_index)

func reload_progress() -> float:
	if not is_reloading:
		return 0.0
	var def := current_def()
	return clampf(1.0 - reload_timer / maxf(0.01, def.reload_time), 0.0, 1.0)

func _load_current() -> void:
	ammo = _ammo_by_weapon[current_index]
	reserve = _reserve_by_weapon[current_index]
	ammo_changed.emit()

func _store_current() -> void:
	_ammo_by_weapon[current_index] = ammo
	_reserve_by_weapon[current_index] = reserve

func _finish_reload() -> void:
	var def := current_def()
	var needed := def.magazine - ammo
	var taken := mini(needed, reserve)
	ammo += taken
	reserve -= taken
	is_reloading = false
	reload_timer = 0.0
	_reserve_by_weapon[current_index] = reserve
	ammo_changed.emit()
	reload_finished.emit()

func _cancel_reload() -> void:
	is_reloading = false
	reload_timer = 0.0

func _reset_storage() -> void:
	_ammo_by_weapon.clear()
	_reserve_by_weapon.clear()
	for def in FRONTLINEWeaponCatalog.all():
		_ammo_by_weapon.append(def.magazine)
		_reserve_by_weapon.append(def.reserve)

func _normalize_role(role_name: String) -> String:
	match role_name:
		"SNIPER", "ANTI_TANK", "MEDIC", "RADIO_OPERATOR":
			return role_name
		_:
			return "ASSAULT"
