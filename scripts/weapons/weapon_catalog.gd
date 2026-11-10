extends RefCounted
class_name FRONTLINEWeaponCatalog

## Единый каталог оружия. Индексы стабильны: на них ссылаются роли,
## сохранения и тесты, поэтому порядок менять нельзя.

const SIDEARM_INDEX := 3

static var _defs: Array[FRONTLINEWeaponDef] = []

static func all() -> Array[FRONTLINEWeaponDef]:
	if _defs.is_empty():
		_build()
	return _defs

static func count() -> int:
	return all().size()

static func get_def(index: int) -> FRONTLINEWeaponDef:
	var defs := all()
	return defs[clampi(index, 0, defs.size() - 1)]

static func find_by_id(weapon_id: String) -> int:
	var defs := all()
	for i in range(defs.size()):
		if defs[i].id == weapon_id:
			return i
	return -1

static func _build() -> void:
	_defs = [
		_def("ak47", "AK-47", 30, 150, 45, 0.10, 2.2, 0.006, 1, 140.0, 715.0, 1.0),
		_def("mp40", "MP-40", 32, 160, 27, 0.075, 2.0, 0.014, 1, 105.0, 380.0, 1.16),
		_def("mosin", "MOSIN-NAGANT", 5, 50, 84, 1.35, 2.6, 0.0018, 1, 220.0, 865.0, 0.76),
		_def("m1911", "M1911", 8, 56, 35, 0.24, 1.5, 0.009, 1, 80.0, 253.0, 1.3),
		_def("shotgun", "PUMP SHOTGUN", 6, 36, 10, 0.78, 3.2, 0.075, 7, 52.0, 400.0, 0.78),
		_def("ppsh41", "PPSH-41", 71, 213, 22, 0.065, 3.1, 0.016, 1, 95.0, 488.0, 1.25),
		_def("kar98k", "KAR98K SNIPER", 5, 45, 95, 1.45, 2.8, 0.0008, 1, 260.0, 760.0, 0.70),
		_def("panzerfaust", "PANZERFAUST", 1, 5, 220, 2.2, 3.5, 0.003, 1, 160.0, 0.0, 0.65),
	]

static func _def(
	p_id: String,
	p_name: String,
	p_magazine: int,
	p_reserve: int,
	p_damage: int,
	p_interval: float,
	p_reload: float,
	p_spread: float,
	p_pellets: int,
	p_range: float,
	p_velocity: float,
	p_pitch: float
) -> FRONTLINEWeaponDef:
	var def := FRONTLINEWeaponDef.new()
	def.id = p_id
	def.display_name = p_name
	def.magazine = p_magazine
	def.reserve = p_reserve
	def.damage = p_damage
	def.fire_interval = p_interval
	def.reload_time = p_reload
	def.spread = p_spread
	def.pellets = p_pellets
	def.range_m = p_range
	def.muzzle_velocity = p_velocity
	def.sound_pitch = p_pitch
	return def
