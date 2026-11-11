extends RefCounted
class_name FRONTLINEBattlefieldLayout

## Генератор геометрии большой карты боевых действий (Battlefield: Trenches & No Man's Land).
## Размер 240 x 180 метров. Окопы, траншеи, воронки, руины, базы обеих фракций и сектора.

const HALF_X := 110.0
const HALF_Z := 85.0
const SPAWN_Y := 0.25

static func spawns_iron() -> Array[Vector3]:
	return [
		Vector3(-25.0, SPAWN_Y, 76.0),
		Vector3(-6.0, SPAWN_Y, 76.0),
		Vector3(6.0, SPAWN_Y, 76.0),
		Vector3(25.0, SPAWN_Y, 76.0),
		Vector3(0.0, SPAWN_Y, 76.0),
	]

static func spawns_red() -> Array[Vector3]:
	return [
		Vector3(-25.0, SPAWN_Y, -76.0),
		Vector3(-6.0, SPAWN_Y, -76.0),
		Vector3(6.0, SPAWN_Y, -76.0),
		Vector3(25.0, SPAWN_Y, -76.0),
		Vector3(0.0, SPAWN_Y, -76.0),
	]

static func sectors() -> Array[Dictionary]:
	return [
		{"name": "ALPHA", "pos": Vector3(-52.0, 0.0, 0.0), "radius": 14.0, "owner": "NEUTRAL"},
		{"name": "BRAVO", "pos": Vector3(0.0, 0.0, 0.0), "radius": 16.0, "owner": "NEUTRAL"},
		{"name": "CHARLIE", "pos": Vector3(52.0, 0.0, 0.0), "radius": 14.0, "owner": "NEUTRAL"},
	]

## Позиции взрывных бочек с горючим (склады, руины, укрепления)
static func barrels() -> Array[Vector3]:
	return [
		# База Железного Легиона
		Vector3(-18.0, 0.0, 72.0), Vector3(18.0, 0.0, 72.0),
		# База Красного Фронта
		Vector3(-18.0, 0.0, -72.0), Vector3(18.0, 0.0, -72.0),
		# Сектор Браво (Центральные руины - пары для цепной детонации)
		Vector3(-11.0, 0.0, -5.0), Vector3(-9.2, 0.0, -5.0),
		Vector3(11.0, 0.0, 5.0), Vector3(9.2, 0.0, 5.0),
		Vector3(0.0, 0.0, 10.0), Vector3(0.0, 0.0, -10.0),
		# Сектор Альфа (Западные траншеи)
		Vector3(-53.0, 0.0, -8.0), Vector3(-51.0, 0.0, -8.0),
		Vector3(-53.0, 0.0, 8.0),
		# Сектор Чарли (Восточные артиллерийские редуты)
		Vector3(52.0, 0.0, -20.0), Vector3(54.0, 0.0, -20.0),
		Vector3(52.0, 0.0, 20.0),
		# Нейтральная полоса у ежей
		Vector3(-22.0, 0.0, 24.0), Vector3(22.0, 0.0, -24.0),
	]

## Тактические точки укрытий для ботов (за мешками, в воронках, в окопах и руинах)
static func cover_points() -> Array[Vector3]:
	return [
		# Сектор Альфа (Западная траншея)
		Vector3(-55.0, 0.0, -12.0), Vector3(-46.0, 0.0, -12.0),
		Vector3(-56.0, 0.0, 0.0), Vector3(-47.0, 0.0, 0.0),
		Vector3(-54.0, 0.0, 10.2), Vector3(-49.0, 0.0, 13.8),
		# Сектор Браво (Центральные руины)
		Vector3(-8.0, 0.0, -8.0), Vector3(8.0, 0.0, -8.0),
		Vector3(-12.0, 0.0, -2.0), Vector3(12.0, 0.0, 2.0),
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
	# 4. СЕКТОР BRAVO (ЦЕНТР, Z = -25..25): РАЗРУШЕННЫЙ ГОРОД / РУИНЫ С ОКНАМИ ДЛЯ ПАРКУРА
	# =========================================================================
	var brick_col := Color(0.48, 0.26, 0.20)
	var rubble_col := Color(0.44, 0.28, 0.22)
	var slab_col := Color(0.42, 0.43, 0.44)

	# --- Северо-западное крыло руин с окнами для паркура ---
	_push(out, Vector3(-14, 1.7, -17.5), Vector3(1.2, 3.4, 4.0), brick_col, true, "ruins")
	_push(out, Vector3(-14, 0.45, -13.5), Vector3(1.2, 0.90, 2.0), brick_col, true, "window_sill") # Оконный проём для паркура!
	_push(out, Vector3(-14, 2.75, -13.5), Vector3(1.2, 1.30, 2.0), brick_col, true, "window_lintel")
	_push(out, Vector3(-14, 0.24, -13.5), Vector3(2.4, 0.48, 2.6), rubble_col, true, "rubble") # Осыпь для запрыгивания
	_push(out, Vector3(-14, 1.7, -8.5), Vector3(1.2, 3.4, 5.0), brick_col, true, "ruins")

	# Пролом в стене для прямого перемахивания (высота 0.96 м)
	_push(out, Vector3(-14, 0.48, -4.5), Vector3(1.2, 0.96, 2.6), brick_col, true, "wall_breach")
	_push(out, Vector3(-12.5, 0.26, -4.5), Vector3(2.0, 0.52, 3.0), rubble_col, true, "rubble")

	# --- Северо-восточное крыло руин с окнами для паркура ---
	_push(out, Vector3(14, 1.7, -17.5), Vector3(1.2, 3.4, 4.0), brick_col, true, "ruins")
	_push(out, Vector3(14, 0.45, -13.5), Vector3(1.2, 0.90, 2.0), brick_col, true, "window_sill")
	_push(out, Vector3(14, 2.75, -13.5), Vector3(1.2, 1.30, 2.0), brick_col, true, "window_lintel")
	_push(out, Vector3(14, 0.24, -13.5), Vector3(2.4, 0.48, 2.6), rubble_col, true, "rubble")
	_push(out, Vector3(14, 1.7, -8.5), Vector3(1.2, 3.4, 5.0), brick_col, true, "ruins")

	_push(out, Vector3(14, 0.48, -4.5), Vector3(1.2, 0.96, 2.6), brick_col, true, "wall_breach")
	_push(out, Vector3(12.5, 0.26, -4.5), Vector3(2.0, 0.52, 3.0), rubble_col, true, "rubble")

	# --- Юго-западное крыло руин с окнами для паркура ---
	_push(out, Vector3(-14, 1.7, 8.5), Vector3(1.2, 3.4, 5.0), brick_col, true, "ruins")
	_push(out, Vector3(-14, 0.45, 13.5), Vector3(1.2, 0.90, 2.0), brick_col, true, "window_sill")
	_push(out, Vector3(-14, 2.75, 13.5), Vector3(1.2, 1.30, 2.0), brick_col, true, "window_lintel")
	_push(out, Vector3(-14, 0.24, 13.5), Vector3(2.4, 0.48, 2.6), rubble_col, true, "rubble")
	_push(out, Vector3(-14, 1.7, 17.5), Vector3(1.2, 3.4, 4.0), brick_col, true, "ruins")

	_push(out, Vector3(-14, 0.48, 4.5), Vector3(1.2, 0.96, 2.6), brick_col, true, "wall_breach")
	_push(out, Vector3(-12.5, 0.26, 4.5), Vector3(2.0, 0.52, 3.0), rubble_col, true, "rubble")

	# --- Юго-восточное крыло руин с окнами для паркура ---
	_push(out, Vector3(14, 1.7, 8.5), Vector3(1.2, 3.4, 5.0), brick_col, true, "ruins")
	_push(out, Vector3(14, 0.45, 13.5), Vector3(1.2, 0.90, 2.0), brick_col, true, "window_sill")
	_push(out, Vector3(14, 2.75, 13.5), Vector3(1.2, 1.30, 2.0), brick_col, true, "window_lintel")
	_push(out, Vector3(14, 0.24, 13.5), Vector3(2.4, 0.48, 2.6), rubble_col, true, "rubble")
	_push(out, Vector3(14, 1.7, 17.5), Vector3(1.2, 3.4, 4.0), brick_col, true, "ruins")

	_push(out, Vector3(14, 0.48, 4.5), Vector3(1.2, 0.96, 2.6), brick_col, true, "wall_breach")
	_push(out, Vector3(12.5, 0.26, 4.5), Vector3(2.0, 0.52, 3.0), rubble_col, true, "rubble")

	# Поперечные полуразрушенные стены с проломами и вольтируемыми секциями (1.04 м)
	_push(out, Vector3(-10, 1.2, 0), Vector3(7.5, 2.4, 1.2), brick_col, true, "ruins")
	_push(out, Vector3(-4.5, 0.52, 0), Vector3(3.2, 1.04, 1.1), brick_col, true, "ruins_low") # Стенка 1.04м для вольтирования!
	_push(out, Vector3(4.5, 0.52, 0), Vector3(3.2, 1.04, 1.1), brick_col, true, "ruins_low")
	_push(out, Vector3(10, 1.2, 0), Vector3(7.5, 2.4, 1.2), brick_col, true, "ruins")

	# Обрушенные плиты перекрытия (пандусы на второй ярус)
	_push(out, Vector3(-8.0, 0.85, 7.5), Vector3(4.5, 0.35, 3.2), slab_col, true, "fallen_slab")
	_push(out, Vector3(8.0, 0.85, -7.5), Vector3(4.5, 0.35, 3.2), slab_col, true, "fallen_slab")

	# Пулемётные брустверы из мешков с песком в центре сектора Bravo
	_push(out, Vector3(0, 0.54, -7.0), Vector3(6.0, 1.08, 1.2), Color(0.48, 0.43, 0.31), true, "sandbag")
	_push(out, Vector3(0, 0.54, 7.0), Vector3(6.0, 1.08, 1.2), Color(0.48, 0.43, 0.31), true, "sandbag")

	# =========================================================================
	# 5. СЕКТОР ALPHA (ЗАПАД, X = -65..-40): СЕТЬ ОКОПОВ, НАСТИЛЫ И БРУСТВЕРЫ
	# =========================================================================
	var trench_col := Color(0.35, 0.30, 0.22)
	var wood_col := Color(0.36, 0.28, 0.18)
	var banquette_col := Color(0.30, 0.24, 0.16)
	var sandbag_col := Color(0.48, 0.43, 0.31)

	# Зигзагообразные земляные стены окопов
	_push(out, Vector3(-58, 0.7, -24), Vector3(1.4, 1.4, 22), trench_col, true, "trench_wall")
	_push(out, Vector3(-48, 0.7, -24), Vector3(1.4, 1.4, 22), trench_col, true, "trench_wall")
	_push(out, Vector3(-58, 0.7, 0), Vector3(1.4, 1.4, 24), trench_col, true, "trench_wall")
	_push(out, Vector3(-48, 0.7, 0), Vector3(1.4, 1.4, 24), trench_col, true, "trench_wall")
	_push(out, Vector3(-58, 0.7, 24), Vector3(1.4, 1.4, 22), trench_col, true, "trench_wall")
	_push(out, Vector3(-48, 0.7, 24), Vector3(1.4, 1.4, 22), trench_col, true, "trench_wall")

	# Тяжёлые бревенчатые траверсы на стыках окопов
	_push(out, Vector3(-53, 0.8, -13), Vector3(12, 1.6, 1.6), Color(0.32, 0.24, 0.16), true, "log_traverse")
	_push(out, Vector3(-53, 0.8, 12), Vector3(12, 1.6, 1.6), Color(0.32, 0.24, 0.16), true, "log_traverse")

	# Дощатые настилы (Duckboards) на дне траншеи
	_push(out, Vector3(-53, 0.03, -24), Vector3(3.4, 0.06, 20.0), wood_col, false, "duckboard")
	_push(out, Vector3(-53, 0.03, 0), Vector3(3.4, 0.06, 22.0), wood_col, false, "duckboard")
	_push(out, Vector3(-53, 0.03, 24), Vector3(3.4, 0.06, 20.0), wood_col, false, "duckboard")
	_push(out, Vector3(-53, 0.03, -12), Vector3(8.0, 0.06, 2.6), wood_col, false, "duckboard")
	_push(out, Vector3(-53, 0.03, 12), Vector3(8.0, 0.06, 2.6), wood_col, false, "duckboard")

	# Стрелковые ступени (банкеты / banquettes) вдоль стен траншеи (высота 0.42 м)
	_push(out, Vector3(-56.5, 0.21, -24), Vector3(0.75, 0.42, 18.0), banquette_col, true, "banquette")
	_push(out, Vector3(-49.5, 0.21, -24), Vector3(0.75, 0.42, 18.0), banquette_col, true, "banquette")
	_push(out, Vector3(-56.5, 0.21, 0), Vector3(0.75, 0.42, 20.0), banquette_col, true, "banquette")
	_push(out, Vector3(-49.5, 0.21, 0), Vector3(0.75, 0.42, 20.0), banquette_col, true, "banquette")
	_push(out, Vector3(-56.5, 0.21, 24), Vector3(0.75, 0.42, 18.0), banquette_col, true, "banquette")
	_push(out, Vector3(-49.5, 0.21, 24), Vector3(0.75, 0.42, 18.0), banquette_col, true, "banquette")

	# Ступени быстрого выхода / выпрыгивания из траншеи
	_push(out, Vector3(-51.5, 0.36, -6.0), Vector3(2.5, 0.36, 1.8), Color(0.32, 0.24, 0.16), true, "trench_step")
	_push(out, Vector3(-51.5, 0.36, 6.0), Vector3(2.5, 0.36, 1.8), Color(0.32, 0.24, 0.16), true, "trench_step")

	# Мешки с песком на брустверах окопов (огневые бойницы)
	_push(out, Vector3(-58.6, 1.55, -24), Vector3(0.8, 0.55, 20.0), sandbag_col, true, "sandbag")
	_push(out, Vector3(-47.4, 1.55, -24), Vector3(0.8, 0.55, 20.0), sandbag_col, true, "sandbag")
	_push(out, Vector3(-58.6, 1.55, 0), Vector3(0.8, 0.55, 22.0), sandbag_col, true, "sandbag")
	_push(out, Vector3(-47.4, 1.55, 0), Vector3(0.8, 0.55, 22.0), sandbag_col, true, "sandbag")
	_push(out, Vector3(-58.6, 1.55, 24), Vector3(0.8, 0.55, 20.0), sandbag_col, true, "sandbag")
	_push(out, Vector3(-47.4, 1.55, 24), Vector3(0.8, 0.55, 20.0), sandbag_col, true, "sandbag")

	# =========================================================================
	# 6. СЕКТОР CHARLIE (ВОСТОК, X = 40..65): АРТИЛЛЕРИЙСКИЕ ВОРОНКИ И РЕДУТЫ
	# =========================================================================
	for offset_z in [-20.0, 0.0, 20.0]:
		# Земляные брустверы воронок с мешками (высота 1.08 м - паркурные!)
		_push(out, Vector3(52, 0.54, offset_z - 6.5), Vector3(12.0, 1.08, 1.4), sandbag_col, true, "sandbag")
		_push(out, Vector3(52, 0.54, offset_z + 6.5), Vector3(12.0, 1.08, 1.4), sandbag_col, true, "sandbag")
		_push(out, Vector3(44.5, 0.54, offset_z), Vector3(1.4, 1.08, 11.0), sandbag_col, true, "sandbag")
		_push(out, Vector3(59.5, 0.54, offset_z), Vector3(1.4, 1.08, 11.0), sandbag_col, true, "sandbag")
		# Внутренняя бревенчатая крепь редута
		_push(out, Vector3(52, 0.38, offset_z - 5.0), Vector3(9.0, 0.76, 0.3), Color(0.34, 0.25, 0.17), true, "log_revetment")
		_push(out, Vector3(52, 0.38, offset_z + 5.0), Vector3(9.0, 0.76, 0.3), Color(0.34, 0.25, 0.17), true, "log_revetment")
		# Тёмное дно воронки
		_push(out, Vector3(52, 0.015, offset_z), Vector3(7.5, 0.03, 7.5), Color(0.18, 0.15, 0.12), false, "crater_dirt")

	# =========================================================================
	# 7. ПРОТИВОТАНКОВЫЕ ЕЖИ И КОЛЮЧАЯ ПРОВОЛОКА НА КОЛЬЯХ (НЕЙТРАЛЬНАЯ ПОЛОСА)
	# =========================================================================
	var steel_col := Color(0.26, 0.27, 0.29)
	var stake_col := Color(0.30, 0.22, 0.14)
	var wire_col := Color(0.28, 0.29, 0.31)

	# Настоящие 3-балочные сварные противотанковые ежи (высота 1.10 м - паркурные!)
	for x in [-36.0, -20.0, 20.0, 36.0]:
		for z in [-32.0, 32.0]:
			_push(out, Vector3(x, 0.55, z), Vector3(2.2, 0.22, 0.22), steel_col, true, "hedgehog")
			_push(out, Vector3(x, 0.55, z), Vector3(0.22, 0.22, 2.2), steel_col, true, "hedgehog")
			_push(out, Vector3(x, 0.55, z), Vector3(0.22, 1.10, 0.22), steel_col, true, "hedgehog")

	# Заграждения из колючей проволоки на деревянных кольях (высота 0.95 м - перепрыгиваемые!)
	for wx in [-42.0, -26.0, 26.0, 42.0]:
		for wz in [-22.0, 22.0]:
			_push(out, Vector3(wx - 3.2, 0.58, wz), Vector3(0.18, 1.16, 0.18), stake_col, true, "wire_stake")
			_push(out, Vector3(wx, 0.58, wz), Vector3(0.18, 1.16, 0.18), stake_col, true, "wire_stake")
			_push(out, Vector3(wx + 3.2, 0.58, wz), Vector3(0.18, 1.16, 0.18), stake_col, true, "wire_stake")
			_push(out, Vector3(wx, 0.48, wz), Vector3(7.6, 0.95, 0.35), wire_col, true, "barbed_wire")

	# Внешние ограничительные насыпи карты (чтобы не упасть в пустоту)
	_push(out, Vector3(0, 3.0, -92), Vector3(240, 6.0, 4.0), Color(0.22, 0.24, 0.20), true, "boundary")
	_push(out, Vector3(0, 3.0, 92), Vector3(240, 6.0, 4.0), Color(0.22, 0.24, 0.20), true, "boundary")
	_push(out, Vector3(-120, 3.0, 0), Vector3(4.0, 6.0, 185), Color(0.22, 0.24, 0.20), true, "boundary")
	_push(out, Vector3(120, 3.0, 0), Vector3(4.0, 6.0, 185), Color(0.22, 0.24, 0.20), true, "boundary")

	return out

## Крупные несущие конструкции поля боя, отбрасывающие тени.
## Настилы траншей (duckboard), ступени, брустверы, мешки с песком, ежи,
## проволока и осыпи отключают тени для двукратного сокращения теневых проходов.
const SHADOW_KINDS := {
	"boundary": true,
	"bunker_wall": true,
	"bunker_roof": true,
	"log_wall": true,
	"log_roof": true,
	"ruins": true,
	"window_lintel": true,
}

static func _push(out: Array, pos: Vector3, size: Vector3, color: Color, solid: bool, kind: String, cast_shadow: Variant = null) -> void:
	var shadow: bool = (cast_shadow as bool) if cast_shadow != null else SHADOW_KINDS.get(kind, false)
	out.append({
		"pos": pos,
		"size": size,
		"color": color,
		"solid": solid,
		"kind": kind,
		"cast_shadow": shadow,
	})
