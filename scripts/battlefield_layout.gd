extends RefCounted
class_name FRONTLINEBattlefieldLayout

## Генератор геометрии большой карты боевых действий (Battlefield: Trenches & No Man's Land).
## Размер 240 x 180 метров. Окопы, траншеи, воронки, руины, базы обеих фракций и сектора.

const HALF_X := 110.0
const HALF_Z := 85.0
const SPAWN_Y := 0.25

static func spawns_iron() -> Array[Vector3]:
	return [
		Vector3(-25.0, SPAWN_Y, 74.0),
		Vector3(-10.0, SPAWN_Y, 76.0),
		Vector3(10.0, SPAWN_Y, 76.0),
		Vector3(25.0, SPAWN_Y, 74.0),
		Vector3(0.0, SPAWN_Y, 82.0),
	]

static func spawns_red() -> Array[Vector3]:
	return [
		Vector3(-25.0, SPAWN_Y, -74.0),
		Vector3(-10.0, SPAWN_Y, -76.0),
		Vector3(10.0, SPAWN_Y, -76.0),
		Vector3(25.0, SPAWN_Y, -74.0),
		Vector3(0.0, SPAWN_Y, -82.0),
	]

static func sectors() -> Array[Dictionary]:
	return [
		{"name": "ALPHA", "pos": Vector3(-52.0, 0.0, 0.0), "radius": 14.0, "owner": "NEUTRAL"},
		{"name": "BRAVO", "pos": Vector3(0.0, 0.0, 0.0), "radius": 16.0, "owner": "NEUTRAL"},
		{"name": "CHARLIE", "pos": Vector3(52.0, 0.0, 0.0), "radius": 14.0, "owner": "NEUTRAL"},
	]

## Тактические точки укрытий для ботов (за мешками, в воронках, в окопах и руинах)
static func cover_points() -> Array[Vector3]:
	return [
		# Сектор Альфа (Западная траншея)
		Vector3(-55.0, 0.0, -12.0), Vector3(-48.0, 0.0, -12.0),
		Vector3(-56.0, 0.0, 0.0), Vector3(-47.0, 0.0, 0.0),
		Vector3(-54.0, 0.0, 12.0), Vector3(-49.0, 0.0, 12.0),
		# Сектор Браво (Центральные руины)
		Vector3(-8.0, 0.0, -8.0), Vector3(8.0, 0.0, -8.0),
		Vector3(-12.0, 0.0, 0.0), Vector3(12.0, 0.0, 0.0),
		Vector3(-8.0, 0.0, 8.0), Vector3(8.0, 0.0, 8.0),
		Vector3(0.0, 0.0, -14.0), Vector3(0.0, 0.0, 14.0),
		# Сектор Чарли (Восточные воронки и брустверы)
		Vector3(48.0, 0.0, -10.0), Vector3(55.0, 0.0, -10.0),
		Vector3(46.0, 0.0, 0.0), Vector3(56.0, 0.0, 0.0),
		Vector3(48.0, 0.0, 10.0), Vector3(55.0, 0.0, 10.0),
		# Промежуточные рубежи Север (Красные)
		Vector3(-30.0, 0.0, -38.0), Vector3(0.0, 0.0, -38.0), Vector3(30.0, 0.0, -38.0),
		Vector3(-60.0, 0.0, -42.0), Vector3(60.0, 0.0, -42.0),
		# Промежуточные рубежи Юг (Железный Легион)
		Vector3(-30.0, 0.0, 38.0), Vector3(0.0, 0.0, 38.0), Vector3(30.0, 0.0, 38.0),
		Vector3(-60.0, 0.0, 42.0), Vector3(60.0, 0.0, 42.0),
	]

static func boxes() -> Array:
	var out: Array = []

	# 1. ОБЩИЙ ГРУНТ И ЗЕМЛЯ БОЛЬШОЙ КАРТЫ (240 x 180 м)
	_push(out, Vector3(0, -0.4, 0), Vector3(240, 0.7, 185), Color(0.24, 0.26, 0.21), true, "terrain")
	# Дороги и вытоптанная нейтральная полоса
	_push(out, Vector3(0, 0.015, 0), Vector3(16, 0.04, 160), Color(0.32, 0.28, 0.22), false, "road")
	_push(out, Vector3(0, 0.018, 0), Vector3(160, 0.03, 14), Color(0.29, 0.26, 0.20), false, "crossroad")

	# Спавн-площадки
	for p in spawns_iron():
		_push(out, p + Vector3(0, -0.22, 0), Vector3(4.8, 0.06, 4.8), Color(0.18, 0.20, 0.22), false, "pad_iron")
	for p in spawns_red():
		_push(out, p + Vector3(0, -0.22, 0), Vector3(4.8, 0.06, 4.8), Color(0.28, 0.18, 0.15), false, "pad_red")

	# =========================================================================
	# 2. ЮЖНАЯ БАЗА: IRON LEGION (Z = 65..85)
	# =========================================================================
	# Главный командный бункер (бетон)
	_push(out, Vector3(0, 1.8, 82), Vector3(22, 3.6, 1.4), Color(0.38, 0.40, 0.42), true, "bunker_wall")
	_push(out, Vector3(-10.5, 1.8, 76), Vector3(1.4, 3.6, 12), Color(0.38, 0.40, 0.42), true, "bunker_wall")
	_push(out, Vector3(10.5, 1.8, 76), Vector3(1.4, 3.6, 12), Color(0.38, 0.40, 0.42), true, "bunker_wall")
	_push(out, Vector3(0, 3.7, 76), Vector3(22, 0.6, 14), Color(0.32, 0.34, 0.36), true, "bunker_roof")
	# Фасад бункера с амбразурами и проходом
	_push(out, Vector3(-6.5, 1.8, 70), Vector3(7, 3.6, 1.4), Color(0.38, 0.40, 0.42), true, "bunker_wall")
	_push(out, Vector3(6.5, 1.8, 70), Vector3(7, 3.6, 1.4), Color(0.38, 0.40, 0.42), true, "bunker_wall")
	_push(out, Vector3(0, 3.0, 70), Vector3(6, 1.2, 1.4), Color(0.38, 0.40, 0.42), true, "bunker_wall")

	# Огневые позиции из мешков с песком базы Легиона
	for x in [-32.0, -18.0, 18.0, 32.0]:
		_push(out, Vector3(x, 0.5, 62), Vector3(7.5, 1.0, 1.2), Color(0.48, 0.43, 0.31), true, "sandbag")
	# Боковые брустверы
	_push(out, Vector3(-40, 0.6, 68), Vector3(1.2, 1.2, 16), Color(0.46, 0.41, 0.30), true, "sandbag")
	_push(out, Vector3(40, 0.6, 68), Vector3(1.2, 1.2, 16), Color(0.46, 0.41, 0.30), true, "sandbag")

	# Ящики со снарядами и бочки
	for p in [Vector3(-14, 0.6, 75), Vector3(-12.5, 0.6, 75), Vector3(-14, 1.7, 75),
			 Vector3(14, 0.6, 75), Vector3(15.2, 0.6, 75), Vector3(14, 1.7, 75)]:
		_push(out, p, Vector3(1.3, 1.3, 1.3), Color(0.34, 0.28, 0.18), true, "crate")

	# =========================================================================
	# 3. СЕВЕРНАЯ БАЗА: RED FRONT (Z = -65..-85)
	# =========================================================================
	# Командный дзот Красного Фронта (дерево и земля)
	_push(out, Vector3(0, 1.8, -82), Vector3(22, 3.6, 1.5), Color(0.35, 0.26, 0.18), true, "log_wall")
	_push(out, Vector3(-10.5, 1.8, -76), Vector3(1.5, 3.6, 12), Color(0.35, 0.26, 0.18), true, "log_wall")
	_push(out, Vector3(10.5, 1.8, -76), Vector3(1.5, 3.6, 12), Color(0.35, 0.26, 0.18), true, "log_wall")
	_push(out, Vector3(0, 3.7, -76), Vector3(22, 0.7, 14), Color(0.28, 0.22, 0.15), true, "log_roof")
	# Фасад дзота с амбразурами
	_push(out, Vector3(-6.5, 1.8, -70), Vector3(7, 3.6, 1.5), Color(0.35, 0.26, 0.18), true, "log_wall")
	_push(out, Vector3(6.5, 1.8, -70), Vector3(7, 3.6, 1.5), Color(0.35, 0.26, 0.18), true, "log_wall")
	_push(out, Vector3(0, 3.0, -70), Vector3(6, 1.2, 1.5), Color(0.35, 0.26, 0.18), true, "log_wall")

	# Укрепления из мешков Красного Фронта
	for x in [-32.0, -18.0, 18.0, 32.0]:
		_push(out, Vector3(x, 0.5, -62), Vector3(7.5, 1.0, 1.2), Color(0.44, 0.38, 0.28), true, "sandbag")
	_push(out, Vector3(-40, 0.6, -68), Vector3(1.2, 1.2, 16), Color(0.44, 0.38, 0.28), true, "sandbag")
	_push(out, Vector3(40, 0.6, -68), Vector3(1.2, 1.2, 16), Color(0.44, 0.38, 0.28), true, "sandbag")

	# Снабжение Красного Фронта
	for p in [Vector3(-14, 0.6, -75), Vector3(-12.5, 0.6, -75), Vector3(-14, 1.7, -75),
			 Vector3(14, 0.6, -75), Vector3(15.2, 0.6, -75), Vector3(14, 1.7, -75)]:
		_push(out, p, Vector3(1.3, 1.3, 1.3), Color(0.30, 0.22, 0.15), true, "crate")

	# =========================================================================
	# 4. СЕКТОР BRAVO (ЦЕНТР, Z = -25..25): РАЗРУШЕННЫЙ ГОРОД / РУИНЫ
	# =========================================================================
	# Центральные кирпичные руины (укрытия в полный рост и бойницы)
	_push(out, Vector3(-14, 1.5, -12), Vector3(1.2, 3.0, 14), Color(0.46, 0.26, 0.20), true, "ruins")
	_push(out, Vector3(14, 1.5, -12), Vector3(1.2, 3.0, 14), Color(0.46, 0.26, 0.20), true, "ruins")
	_push(out, Vector3(-14, 1.5, 12), Vector3(1.2, 3.0, 14), Color(0.46, 0.26, 0.20), true, "ruins")
	_push(out, Vector3(14, 1.5, 12), Vector3(1.2, 3.0, 14), Color(0.46, 0.26, 0.20), true, "ruins")

	# Поперечные полуразрушенные стены с проломами
	_push(out, Vector3(-8, 1.2, 0), Vector3(12, 2.4, 1.2), Color(0.44, 0.25, 0.19), true, "ruins")
	_push(out, Vector3(8, 1.2, 0), Vector3(12, 2.4, 1.2), Color(0.44, 0.25, 0.19), true, "ruins")
	# Низкие обломки и баррикады внутри сектора Bravo
	_push(out, Vector3(0, 0.5, -7), Vector3(5, 1.0, 1.0), Color(0.40, 0.38, 0.35), true, "debris")
	_push(out, Vector3(0, 0.5, 7), Vector3(5, 1.0, 1.0), Color(0.40, 0.38, 0.35), true, "debris")

	# =========================================================================
	# 5. СЕКТОР ALPHA (ЗАПАД, X = -65..-40): СЕТЬ ПЕРЕДОВЫХ ОКОПОВ
	# =========================================================================
	# Зигзагообразные земляные брустверы траншей
	_push(out, Vector3(-58, 0.7, -24), Vector3(1.4, 1.4, 22), Color(0.35, 0.30, 0.22), true, "trench_wall")
	_push(out, Vector3(-48, 0.7, -24), Vector3(1.4, 1.4, 22), Color(0.35, 0.30, 0.22), true, "trench_wall")
	_push(out, Vector3(-53, 0.7, -13), Vector3(12, 1.4, 1.4), Color(0.35, 0.30, 0.22), true, "trench_wall")
	_push(out, Vector3(-58, 0.7, 0), Vector3(1.4, 1.4, 24), Color(0.35, 0.30, 0.22), true, "trench_wall")
	_push(out, Vector3(-48, 0.7, 0), Vector3(1.4, 1.4, 24), Color(0.35, 0.30, 0.22), true, "trench_wall")
	_push(out, Vector3(-53, 0.7, 12), Vector3(12, 1.4, 1.4), Color(0.35, 0.30, 0.22), true, "trench_wall")
	_push(out, Vector3(-58, 0.7, 24), Vector3(1.4, 1.4, 22), Color(0.35, 0.30, 0.22), true, "trench_wall")
	_push(out, Vector3(-48, 0.7, 24), Vector3(1.4, 1.4, 22), Color(0.35, 0.30, 0.22), true, "trench_wall")
	# Деревянные настилы на дне траншеи
	_push(out, Vector3(-53, 0.02, 0), Vector3(8.5, 0.05, 52), Color(0.28, 0.22, 0.16), false, "duckboard")

	# =========================================================================
	# 6. СЕКТОР CHARLIE (ВОСТОК, X = 40..65): АРТИЛЛЕРИЙСКИЕ ВОРОНКИ И РЕДУТЫ
	# =========================================================================
	# Защитные земляные валы вокруг воронок
	for offset_z in [-20.0, 0.0, 20.0]:
		_push(out, Vector3(52, 0.6, offset_z - 6), Vector3(12, 1.2, 1.4), Color(0.32, 0.27, 0.20), true, "crater_berm")
		_push(out, Vector3(52, 0.6, offset_z + 6), Vector3(12, 1.2, 1.4), Color(0.32, 0.27, 0.20), true, "crater_berm")
		_push(out, Vector3(45, 0.6, offset_z), Vector3(1.4, 1.2, 10), Color(0.32, 0.27, 0.20), true, "crater_berm")
		_push(out, Vector3(59, 0.6, offset_z), Vector3(1.4, 1.2, 10), Color(0.32, 0.27, 0.20), true, "crater_berm")
		# Тёмное дно воронки
		_push(out, Vector3(52, 0.015, offset_z), Vector3(8, 0.03, 8), Color(0.18, 0.15, 0.12), false, "crater_dirt")

	# =========================================================================
	# 7. ПРОТИВОТАНКОВЫЕ ЕЖИ И БАРРИКАДЫ НЕЙТРАЛЬНОЙ ПОЛОСЫ
	# =========================================================================
	for x in [-36.0, -22.0, 22.0, 36.0]:
		for z in [-28.0, 28.0]:
			_push(out, Vector3(x, 0.5, z), Vector3(2.4, 1.0, 0.3), Color(0.24, 0.25, 0.27), true, "hedgehog")
			_push(out, Vector3(x, 0.5, z), Vector3(0.3, 1.0, 2.4), Color(0.24, 0.25, 0.27), true, "hedgehog")

	# Внешние ограничительные насыпи карты (чтобы не упасть в пустоту)
	_push(out, Vector3(0, 3.0, -92), Vector3(240, 6.0, 4.0), Color(0.22, 0.24, 0.20), true, "boundary")
	_push(out, Vector3(0, 3.0, 92), Vector3(240, 6.0, 4.0), Color(0.22, 0.24, 0.20), true, "boundary")
	_push(out, Vector3(-120, 3.0, 0), Vector3(4.0, 6.0, 185), Color(0.22, 0.24, 0.20), true, "boundary")
	_push(out, Vector3(120, 3.0, 0), Vector3(4.0, 6.0, 185), Color(0.22, 0.24, 0.20), true, "boundary")

	return out

static func _push(out: Array, pos: Vector3, size: Vector3, color: Color, solid: bool, kind: String) -> void:
	out.append({
		"pos": pos,
		"size": size,
		"color": color,
		"solid": solid,
		"kind": kind,
	})
