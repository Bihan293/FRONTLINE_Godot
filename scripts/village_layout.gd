extends RefCounted
class_name FRONTLINEVillageLayout

## Процедурная карта «ДЕРЕВНЯ» (VILLAGE) 180×150м в стиле Dummy War.
## Включает:
## - Центральная деревенская площадь с каменным колодцем (Сектор B: ПЛОЩАДЬ)
## - Старая церковь с колокольней и кладбищем (Сектор A: ЦЕРКОВЬ)
## - Ветряная мельница и амбар с сеновалом (Сектор C: МЕЛЬНИЦА)
## - 6 деревенских домов с проёмами дверей и окон, печными трубами
## - Бревенчатые и каменные заборы, стога сена, баррикады из мешков
## - Базы Железного Легиона (юг) и Красного Фронта (север)

const MAP_WIDTH := 180.0
const MAP_DEPTH := 150.0

static func spawns_iron() -> Array[Vector3]:
	return [
		Vector3(-24.0, 0.4, 62.0),
		Vector3(-8.0, 0.4, 65.0),
		Vector3(0.0, 0.4, 68.0),
		Vector3(12.0, 0.4, 65.0),
		Vector3(26.0, 0.4, 62.0),
	]

static func spawns_red() -> Array[Vector3]:
	return [
		Vector3(-24.0, 0.4, -62.0),
		Vector3(-8.0, 0.4, -65.0),
		Vector3(0.0, 0.4, -68.0),
		Vector3(12.0, 0.4, -65.0),
		Vector3(26.0, 0.4, -62.0),
	]

static func sectors() -> Array[Dictionary]:
	return [
		{
			"name": "A",
			"label": "ЦЕРКОВЬ",
			"pos": Vector3(-45.0, 0.0, 0.0),
			"radius": 14.0,
			"owner": "NEUTRAL",
		},
		{
			"name": "B",
			"label": "ПЛОЩАДЬ",
			"pos": Vector3(0.0, 0.0, 0.0),
			"radius": 14.0,
			"owner": "NEUTRAL",
		},
		{
			"name": "C",
			"label": "МЕЛЬНИЦА",
			"pos": Vector3(45.0, 0.0, 0.0),
			"radius": 14.0,
			"owner": "NEUTRAL",
		},
	]

static func barrels() -> Array[Vector3]:
	return [
		# Склад у мельницы
		Vector3(42.0, 0.0, -8.0),
		Vector3(43.5, 0.0, -8.0),
		# Двор церкви
		Vector3(-48.0, 0.0, 6.0),
		# Центральная площадь у повозок
		Vector3(6.0, 0.0, -4.0),
		# Перекрёсток южного въезда
		Vector3(-14.0, 0.0, 32.0),
		# Перекрёсток северного въезда
		Vector3(16.0, 0.0, -32.0),
		# База Легиона
		Vector3(18.0, 0.0, 58.0),
		# База Красного Фронта
		Vector3(-18.0, 0.0, -58.0),
	]

static func boxes() -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	# -------------------------------------------------------------------------
	# 1. ЛАНДШАФТ И ДОРОГИ
	# -------------------------------------------------------------------------
	# Основное поле (зеленовато-бурый полевой грунт)
	_push(out, Vector3(0, -0.5, 0), Vector3(180, 1.0, 150), Color(0.24, 0.28, 0.18), true, "ground")

	# Центральная деревенская грунтовая дорога (Север - Юг)
	_push(out, Vector3(0, 0.02, 0), Vector3(12.0, 0.05, 148), Color(0.36, 0.31, 0.22), false, "road")

	# Поперечная дорога между церковью, площадью и мельницей (Запад - Восток)
	_push(out, Vector3(0, 0.02, 0), Vector3(140.0, 0.05, 10.0), Color(0.34, 0.29, 0.20), false, "road")

	# Мощёная булыжником центральная площадь
	_push(out, Vector3(0, 0.04, 0), Vector3(32.0, 0.06, 32.0), Color(0.42, 0.40, 0.36), false, "plaza")

	# Спавн-площадки
	for p in spawns_iron():
		_push(out, p + Vector3(0, -0.22, 0), Vector3(4.5, 0.06, 4.5), Color(0.20, 0.24, 0.28), false, "pad_iron")
	for p in spawns_red():
		_push(out, p + Vector3(0, -0.22, 0), Vector3(4.5, 0.06, 4.5), Color(0.32, 0.20, 0.18), false, "pad_red")

	# -------------------------------------------------------------------------
	# 2. СЕКТОР B: ЦЕНТРАЛЬНАЯ ПЛОЩАДЬ И КОЛОДЕЦ (X = 0, Z = 0)
	# -------------------------------------------------------------------------
	# Старинный каменный колодец в центре
	_push(out, Vector3(0, 0.5, 0), Vector3(3.2, 1.0, 3.2), Color(0.45, 0.44, 0.42), true, "well_base")
	_push(out, Vector3(-1.2, 1.6, 0), Vector3(0.3, 1.4, 0.3), Color(0.32, 0.22, 0.14), true, "well_post")
	_push(out, Vector3(1.2, 1.6, 0), Vector3(0.3, 1.4, 0.3), Color(0.32, 0.22, 0.14), true, "well_post")
	_push(out, Vector3(0, 2.4, 0), Vector3(3.4, 0.3, 3.4), Color(0.35, 0.18, 0.12), true, "well_roof")

	# Торговые ряды и деревянные телеги
	_push(out, Vector3(-8.0, 0.6, -7.0), Vector3(4.5, 1.2, 2.2), Color(0.42, 0.28, 0.16), true, "market_stall")
	_push(out, Vector3(8.0, 0.6, 7.0), Vector3(4.5, 1.2, 2.2), Color(0.42, 0.28, 0.16), true, "market_stall")
	_push(out, Vector3(-9.0, 0.5, 8.0), Vector3(3.2, 1.0, 1.8), Color(0.36, 0.24, 0.14), true, "cart")
	_push(out, Vector3(9.0, 0.5, -8.0), Vector3(3.2, 1.0, 1.8), Color(0.36, 0.24, 0.14), true, "cart")

	# Укрытия из мешков с песком вокруг площади
	_push(out, Vector3(-5.0, 0.5, -12.0), Vector3(6.0, 1.0, 1.0), Color(0.50, 0.45, 0.32), true, "sandbag")
	_push(out, Vector3(5.0, 0.5, 12.0), Vector3(6.0, 1.0, 1.0), Color(0.50, 0.45, 0.32), true, "sandbag")

	# -------------------------------------------------------------------------
	# 3. СЕКТОР A: ЦЕРКОВЬ С КОЛОКОЛЬНЕЙ И КЛАДБИЩЕМ (X = -45, Z = 0)
	# -------------------------------------------------------------------------
	var church_pos := Vector3(-45.0, 0.0, 0.0)
	# Главный зал церкви (камень и кирпич)
	_push(out, church_pos + Vector3(0, 2.8, 0), Vector3(16.0, 5.6, 10.0), Color(0.52, 0.50, 0.47), true, "church_hall")
	# Двускатная крыша церкви с навесом
	_push(out, church_pos + Vector3(0, 6.0, 0), Vector3(17.2, 1.2, 11.2), Color(0.28, 0.20, 0.16), true, "church_roof")
	# Высокая колокольня (снайперская позиция!)
	_push(out, church_pos + Vector3(9.0, 4.5, 0), Vector3(5.0, 9.0, 5.0), Color(0.48, 0.46, 0.44), true, "bell_tower")
	_push(out, church_pos + Vector3(9.0, 9.6, 0), Vector3(5.6, 1.6, 5.6), Color(0.24, 0.16, 0.14), true, "tower_roof")
	# Парадное каменное крыльцо и вход
	_push(out, church_pos + Vector3(-9.0, 0.2, 0), Vector3(2.6, 0.4, 4.0), Color(0.42, 0.40, 0.38), true, "church_steps")
	_push(out, church_pos + Vector3(-9.0, 1.5, 0), Vector3(2.2, 2.2, 3.5), Color(0.40, 0.38, 0.36), true, "church_porch")

	# Пролом в северной стене церкви для флангового паркура (высота 0.95 м + осыпь камней)
	_push(out, church_pos + Vector3(0, 0.48, -5.0), Vector3(2.6, 0.96, 0.9), Color(0.46, 0.44, 0.40), true, "church_breach")
	_push(out, church_pos + Vector3(0, 0.28, -5.9), Vector3(3.2, 0.56, 1.2), Color(0.40, 0.38, 0.34), true, "rubble")

	# Внутренние укрытия церкви: алтарный блок и деревянные скамьи
	_push(out, church_pos + Vector3(5.0, 0.5, 0), Vector3(2.8, 1.0, 1.4), Color(0.45, 0.35, 0.25), true, "altar")
	_push(out, church_pos + Vector3(-3.0, 0.45, -2.4), Vector3(4.5, 0.9, 0.8), Color(0.34, 0.24, 0.15), true, "church_pew")
	_push(out, church_pos + Vector3(-3.0, 0.45, 2.4), Vector3(4.5, 0.9, 0.8), Color(0.34, 0.24, 0.15), true, "church_pew")

	# Каменная ограда кладбища с перелазами (высота 1.08 м) и проломами
	_push(out, church_pos + Vector3(-7.0, 0.54, -14.0), Vector3(14.0, 1.08, 0.6), Color(0.44, 0.43, 0.40), true, "stone_fence")
	_push(out, church_pos + Vector3(7.0, 0.54, -14.0), Vector3(14.0, 1.08, 0.6), Color(0.44, 0.43, 0.40), true, "stone_fence")
	_push(out, church_pos + Vector3(0, 0.35, -14.0), Vector3(2.4, 0.70, 0.8), Color(0.38, 0.37, 0.34), true, "fence_rubble") # Пролом для паркура!
	_push(out, church_pos + Vector3(0, 0.54, 14.0), Vector3(28.0, 1.08, 0.6), Color(0.44, 0.43, 0.40), true, "stone_fence")
	_push(out, church_pos + Vector3(-14.0, 0.54, 0), Vector3(0.6, 1.08, 28.0), Color(0.44, 0.43, 0.40), true, "stone_fence")

	# Могильные надгробия (укрытия для пригибания)
	for gz in [-10.0, -6.0, 6.0, 10.0]:
		for gx in [-6.0, 0.0]:
			_push(out, church_pos + Vector3(gx, 0.45, gz), Vector3(1.2, 0.9, 0.5), Color(0.38, 0.37, 0.35), true, "tombstone")

	# -------------------------------------------------------------------------
	# 4. СЕКТОР C: ВЕТРЯНАЯ МЕЛЬНИЦА И АМБАР (X = 45, Z = 0)
	# -------------------------------------------------------------------------
	var farm_pos := Vector3(45.0, 0.0, 0.0)
	# Башня мельницы (основание 6.5×6.5, высота 8м)
	_push(out, farm_pos + Vector3(0, 4.0, -5.0), Vector3(6.5, 8.0, 6.5), Color(0.46, 0.42, 0.36), true, "windmill_tower")
	_push(out, farm_pos + Vector3(0, 8.6, -5.0), Vector3(7.4, 1.4, 7.4), Color(0.32, 0.22, 0.15), true, "windmill_cap")
	# Лопасти мельницы (деревянный каркас)
	_push(out, farm_pos + Vector3(0, 7.5, -8.6), Vector3(9.0, 0.8, 0.3), Color(0.30, 0.20, 0.12), true, "mill_blades")
	_push(out, farm_pos + Vector3(0, 7.5, -8.6), Vector3(0.8, 9.0, 0.3), Color(0.30, 0.20, 0.12), true, "mill_blades")

	# Большой деревянный амбар с проёмом ворот и сеновалом
	_push(out, farm_pos + Vector3(-5.5, 2.2, 10.0), Vector3(6.5, 4.4, 9.0), Color(0.38, 0.26, 0.17), true, "barn_wall")
	_push(out, farm_pos + Vector3(4.5, 2.2, 10.0), Vector3(6.5, 4.4, 9.0), Color(0.38, 0.26, 0.17), true, "barn_wall")
	_push(out, farm_pos + Vector3(-0.5, 3.8, 10.0), Vector3(3.5, 1.2, 9.0), Color(0.38, 0.26, 0.17), true, "barn_lintel")
	_push(out, farm_pos + Vector3(-0.5, 4.8, 10.0), Vector3(15.4, 1.2, 10.2), Color(0.26, 0.18, 0.12), true, "barn_roof")

	# Стога сена и штабели брёвен (низкие укрытия и ступени)
	for sp in [Vector3(12.0, 1.2, 4.0), Vector3(12.0, 1.2, -6.0), Vector3(-12.0, 1.2, -4.0)]:
		_push(out, farm_pos + sp, Vector3(3.4, 2.4, 3.4), Color(0.62, 0.54, 0.26), true, "haystack")
	# Лестница из тюков сена к окну сеновала
	_push(out, farm_pos + Vector3(-2.0, 0.5, 5.0), Vector3(2.2, 1.0, 2.0), Color(0.60, 0.52, 0.24), true, "haystack")
	_push(out, farm_pos + Vector3(-2.0, 1.2, 7.0), Vector3(2.2, 1.4, 2.0), Color(0.60, 0.52, 0.24), true, "haystack")

	# Деревянный жердевой забор фермы (высота 1.10 м - перепрыгиваемый!) с воротами
	_push(out, farm_pos + Vector3(-8.0, 0.55, -16.0), Vector3(14.0, 1.10, 0.24), Color(0.38, 0.28, 0.18), true, "wood_fence")
	_push(out, farm_pos + Vector3(8.0, 0.55, -16.0), Vector3(14.0, 1.10, 0.24), Color(0.38, 0.28, 0.18), true, "wood_fence")
	_push(out, farm_pos + Vector3(0, 0.55, 18.0), Vector3(30.0, 1.10, 0.24), Color(0.38, 0.28, 0.18), true, "wood_fence")
	_push(out, farm_pos + Vector3(16.0, 0.55, 0), Vector3(0.24, 1.10, 34.0), Color(0.38, 0.28, 0.18), true, "wood_fence")

	# -------------------------------------------------------------------------
	# 5. ДЕТАЛЬНЫЕ ЖИЛЫЕ ДОМА ДЕРЕВНИ С ОКНАМИ ДЛЯ ПАРКУРА, КРЫЛЬЦОМ И УКРЫТИЯМИ
	# -------------------------------------------------------------------------
	var houses := [
		# Северо-западный дом (X = -20, Z = -22, вход на юг к дороге)
		{"pos": Vector3(-20.0, 0.0, -22.0), "size": Vector3(10.0, 3.8, 8.0), "front_z": 1.0},
		# Северо-восточный дом (X = 20, Z = -22, вход на юг к дороге)
		{"pos": Vector3(20.0, 0.0, -22.0), "size": Vector3(10.0, 3.8, 8.0), "front_z": 1.0},
		# Юго-западный дом (X = -20, Z = 22, вход на север к дороге)
		{"pos": Vector3(-20.0, 0.0, 22.0), "size": Vector3(10.0, 3.8, 8.0), "front_z": -1.0},
		# Юго-восточный дом (X = 20, Z = 22, вход на север к дороге)
		{"pos": Vector3(20.0, 0.0, 22.0), "size": Vector3(10.0, 3.8, 8.0), "front_z": -1.0},
		# Западный дом у церкви (X = -65, Z = 18, вход на север)
		{"pos": Vector3(-65.0, 0.0, 18.0), "size": Vector3(9.2, 3.6, 7.6), "front_z": -1.0},
		# Восточный дом у фермы (X = 65, Z = -18, вход на юг)
		{"pos": Vector3(65.0, 0.0, -18.0), "size": Vector3(9.2, 3.6, 7.6), "front_z": 1.0},
	]

	for h in houses:
		_build_cottage(out, h.pos, h.size, float(h.front_z))

	# -------------------------------------------------------------------------
	# 6. ЮЖНЫЙ ВОЕННЫЙ ЛАГЕРЬ: IRON LEGION (Z = 50..70)
	# -------------------------------------------------------------------------
	var iron_base := Vector3(0.0, 0.0, 60.0)
	# Командная армейская палатка (брезент цвета фельдграу)
	_push(out, iron_base + Vector3(0, 1.8, 0), Vector3(12.0, 3.6, 8.0), Color(0.28, 0.32, 0.30), true, "hq_tent")
	_push(out, iron_base + Vector3(0, 3.8, 0), Vector3(12.4, 0.6, 8.4), Color(0.24, 0.28, 0.26), true, "hq_roof")

	# Сторожевая деревянная вышка
	_push(out, iron_base + Vector3(-20.0, 3.0, 0), Vector3(3.6, 6.0, 3.6), Color(0.32, 0.24, 0.16), true, "watchtower")
	_push(out, iron_base + Vector3(-20.0, 6.4, 0), Vector3(4.2, 1.0, 4.2), Color(0.24, 0.18, 0.12), true, "tower_platform")

	# Баррикады и мешки с песком южного рубежа
	for x in [-32.0, -14.0, 14.0, 32.0]:
		_push(out, iron_base + Vector3(x, 0.5, -8.0), Vector3(8.0, 1.0, 1.2), Color(0.48, 0.43, 0.31), true, "sandbag")

	# -------------------------------------------------------------------------
	# 7. СЕВЕРНЫЙ ВОЕННЫЙ ЛАГЕРЬ: RED FRONT (Z = -50..-70)
	# -------------------------------------------------------------------------
	var red_base := Vector3(0.0, 0.0, -60.0)
	# Полевой штабной блиндаж (брёвна и накаты земли)
	_push(out, red_base + Vector3(0, 1.6, 0), Vector3(12.0, 3.2, 8.0), Color(0.34, 0.24, 0.17), true, "hq_bunker")
	_push(out, red_base + Vector3(0, 3.5, 0), Vector3(12.6, 0.8, 8.6), Color(0.26, 0.20, 0.14), true, "bunker_earth")

	# Наблюдательный пункт
	_push(out, red_base + Vector3(20.0, 3.0, 0), Vector3(3.6, 6.0, 3.6), Color(0.32, 0.24, 0.16), true, "watchtower")
	_push(out, red_base + Vector3(20.0, 6.4, 0), Vector3(4.2, 1.0, 4.2), Color(0.24, 0.18, 0.12), true, "tower_platform")

	# Баррикады и мешки северного рубежа
	for x in [-32.0, -14.0, 14.0, 32.0]:
		_push(out, red_base + Vector3(x, 0.5, 8.0), Vector3(8.0, 1.0, 1.2), Color(0.48, 0.43, 0.31), true, "sandbag")

	# -------------------------------------------------------------------------
	# 8. ВНЕШНЯЯ ГРАНИЦА КАРТЫ (непроходимые лесные завалы и скалы)
	# -------------------------------------------------------------------------
	# Западная стена (X = -90)
	_push(out, Vector3(-90, 4.0, 0), Vector3(4, 8, 154), Color(0.22, 0.26, 0.18), true, "forest_wall")
	# Восточная стена (X = 90)
	_push(out, Vector3(90, 4.0, 0), Vector3(4, 8, 154), Color(0.22, 0.26, 0.18), true, "forest_wall")
	# Северная стена (Z = -75)
	_push(out, Vector3(0, 4.0, -75), Vector3(184, 8, 4), Color(0.22, 0.26, 0.18), true, "forest_wall")
	# Южная стена (Z = 75)
	_push(out, Vector3(0, 4.0, 75), Vector3(184, 8, 4), Color(0.22, 0.26, 0.18), true, "forest_wall")

	return out

static func _build_cottage(out: Array[Dictionary], hp: Vector3, hs: Vector3, front_z_dir: float) -> void:
	var wall_col := Color(0.35, 0.25, 0.16)
	var trim_col := Color(0.25, 0.17, 0.11)
	var roof_col := Color(0.24, 0.16, 0.12)
	var brick_col := Color(0.48, 0.22, 0.18)
	var floor_col := Color(0.30, 0.22, 0.14)
	var cover_col := Color(0.32, 0.20, 0.12)
	var sandbag_col := Color(0.50, 0.45, 0.32)
	var fence_col := Color(0.40, 0.30, 0.20)

	var fz: float = hp.z + front_z_dir * (hs.z * 0.5 - 0.18)
	var bz: float = hp.z - front_z_dir * (hs.z * 0.5 - 0.18)
	var wx: float = hp.x - hs.x * 0.5 + 0.18
	var ex: float = hp.x + hs.x * 0.5 - 0.18

	# 1. ФАСАД С ДВЕРЬЮ И ОКНОМ ДЛЯ ПАРКУРА
	# Левый глухой простенок
	_push(out, Vector3(hp.x - 2.8, hs.y * 0.5, fz), Vector3(3.4, hs.y, 0.35), wall_col, true, "house_wall")
	# Дверной проём (ширина 1.4 м, высота 2.2 м) + перемычка над дверью
	_push(out, Vector3(hp.x - 0.4, 2.2 + (hs.y - 2.2) * 0.5, fz), Vector3(1.4, hs.y - 2.2, 0.35), wall_col, true, "door_lintel")
	# Межоконный простенок
	_push(out, Vector3(hp.x + 0.9, hs.y * 0.5, fz), Vector3(1.2, hs.y, 0.35), wall_col, true, "house_wall")
	# Фасадное окно для паркура: подоконник 0.88 м, открытый проём 1.22 м, перемычка
	_push(out, Vector3(hp.x + 2.2, 0.44, fz), Vector3(1.4, 0.88, 0.35), wall_col, true, "window_sill")
	_push(out, Vector3(hp.x + 2.2, 0.88, fz), Vector3(1.6, 0.08, 0.45), trim_col, true, "window_sill_board")
	_push(out, Vector3(hp.x + 2.2, 2.10 + (hs.y - 2.10) * 0.5, fz), Vector3(1.4, hs.y - 2.10, 0.35), wall_col, true, "window_lintel")
	_push(out, Vector3(hp.x + 2.2, 1.49, fz + front_z_dir * 0.19), Vector3(1.5, 1.25, 0.04), trim_col, false, "window_frame")
	_push(out, Vector3(hp.x + 3.1, 1.49, fz + front_z_dir * 0.19), Vector3(0.45, 1.15, 0.04), trim_col, false, "shutter")
	# Правый угол фасада
	_push(out, Vector3(hp.x + 4.0, hs.y * 0.5, fz), Vector3(2.2, hs.y, 0.35), wall_col, true, "house_wall")

	# 2. ЗАДНЯЯ СТЕНА С ТЫЛЬНЫМ ОКНОМ ДЛЯ ПАРКУРА
	_push(out, Vector3(hp.x - 2.5, hs.y * 0.5, bz), Vector3(4.0, hs.y, 0.35), wall_col, true, "house_wall")
	_push(out, Vector3(hp.x + 0.2, 0.44, bz), Vector3(1.4, 0.88, 0.35), wall_col, true, "window_sill")
	_push(out, Vector3(hp.x + 0.2, 0.88, bz), Vector3(1.6, 0.08, 0.45), trim_col, true, "window_sill_board")
	_push(out, Vector3(hp.x + 0.2, 2.10 + (hs.y - 2.10) * 0.5, bz), Vector3(1.4, hs.y - 2.10, 0.35), wall_col, true, "window_lintel")
	_push(out, Vector3(hp.x + 0.2, 1.49, bz - front_z_dir * 0.19), Vector3(1.5, 1.25, 0.04), trim_col, false, "window_frame")
	_push(out, Vector3(hp.x + 3.1, hs.y * 0.5, bz), Vector3(4.4, hs.y, 0.35), wall_col, true, "house_wall")

	# 3. БОКОВЫЕ СТЕНЫ (ЗАПАД И ВОСТОК) С БОКОВЫМИ ОКНАМИ
	# Западная стена с окном на улицу
	_push(out, Vector3(wx, hs.y * 0.5, hp.z - 2.2), Vector3(0.35, hs.y, 2.8), wall_col, true, "house_wall")
	_push(out, Vector3(wx, 0.44, hp.z), Vector3(0.35, 0.88, 1.4), wall_col, true, "window_sill")
	_push(out, Vector3(wx, 0.88, hp.z), Vector3(0.45, 0.08, 1.6), trim_col, true, "window_sill_board")
	_push(out, Vector3(wx, 2.10 + (hs.y - 2.10) * 0.5, hp.z), Vector3(0.35, hs.y - 2.10, 1.4), wall_col, true, "window_lintel")
	_push(out, Vector3(wx - 0.19, 1.49, hp.z), Vector3(0.04, 1.25, 1.5), trim_col, false, "window_frame")
	_push(out, Vector3(wx, hs.y * 0.5, hp.z + 2.2), Vector3(0.35, hs.y, 2.8), wall_col, true, "house_wall")

	# Восточная стена с окном во двор
	_push(out, Vector3(ex, hs.y * 0.5, hp.z - 2.2), Vector3(0.35, hs.y, 2.8), wall_col, true, "house_wall")
	_push(out, Vector3(ex, 0.44, hp.z), Vector3(0.35, 0.88, 1.4), wall_col, true, "window_sill")
	_push(out, Vector3(ex, 0.88, hp.z), Vector3(0.45, 0.08, 1.6), trim_col, true, "window_sill_board")
	_push(out, Vector3(ex, 2.10 + (hs.y - 2.10) * 0.5, hp.z), Vector3(0.35, hs.y - 2.10, 1.4), wall_col, true, "window_lintel")
	_push(out, Vector3(ex + 0.19, 1.49, hp.z), Vector3(0.04, 1.25, 1.5), trim_col, false, "window_frame")
	_push(out, Vector3(ex, hs.y * 0.5, hp.z + 2.2), Vector3(0.35, hs.y, 2.8), wall_col, true, "house_wall")

	# 4. ПАРАДНОЕ КРЫЛЬЦО СО СТУПЕНЬКАМИ И НАВЕСОМ
	# Ступени крыльца (высота 0.18 м и 0.36 м)
	_push(out, Vector3(hp.x - 0.4, 0.09, fz + front_z_dir * 1.05), Vector3(1.8, 0.18, 0.45), trim_col, true, "porch_step")
	_push(out, Vector3(hp.x - 0.4, 0.18, fz + front_z_dir * 0.65), Vector3(1.8, 0.36, 0.45), trim_col, true, "porch_step")
	_push(out, Vector3(hp.x - 0.4, 0.21, fz + front_z_dir * 0.25), Vector3(2.2, 0.42, 0.50), trim_col, true, "porch_deck")
	# Деревянные столбы крыльца
	_push(out, Vector3(hp.x - 1.3, 1.35, fz + front_z_dir * 0.95), Vector3(0.18, 2.7, 0.18), trim_col, true, "porch_post")
	_push(out, Vector3(hp.x + 0.5, 1.35, fz + front_z_dir * 0.95), Vector3(0.18, 2.7, 0.18), trim_col, true, "porch_post")
	# Навес крыльца со скатом
	_push(out, Vector3(hp.x - 0.4, 2.75, fz + front_z_dir * 0.60), Vector3(2.4, 0.30, 1.4), roof_col, true, "porch_roof")

	# 5. КРЫША С ВЫНОСОМ И КАРНИЗАМИ
	_push(out, Vector3(hp.x, hs.y + 0.45, hp.z), Vector3(hs.x + 1.3, 0.9, hs.z + 1.3), roof_col, true, "house_roof")
	_push(out, Vector3(hp.x, hs.y + 1.05, hp.z), Vector3(hs.x + 0.8, 0.4, 0.3), trim_col, false, "attic_pediment")

	# 6. КИРПИЧНАЯ РУССКАЯ ПЕЧЬ И ТРУБА
	_push(out, Vector3(hp.x - hs.x * 0.25, 0.7, hp.z - front_z_dir * hs.z * 0.15), Vector3(1.6, 1.4, 1.6), brick_col, true, "stove_base")
	_push(out, Vector3(hp.x - hs.x * 0.25, hs.y * 0.5 + 1.0, hp.z - front_z_dir * hs.z * 0.15), Vector3(0.85, hs.y + 1.8, 0.85), brick_col, true, "chimney")
	_push(out, Vector3(hp.x - hs.x * 0.25, hs.y + 1.9, hp.z - front_z_dir * hs.z * 0.15), Vector3(1.05, 0.20, 1.05), brick_col, true, "chimney_cap")

	# 7. ВНУТРЕННИЙ ИНТЕРЬЕР И УКРЫТИЯ
	# Дощатый пол
	_push(out, Vector3(hp.x, 0.02, hp.z), Vector3(hs.x - 0.8, 0.04, hs.z - 0.8), floor_col, false, "house_floor")
	# Массивный деревянный стол (высота 0.85 м - укрытие и перепрыгивание)
	_push(out, Vector3(hp.x + hs.x * 0.20, 0.425, hp.z + front_z_dir * hs.z * 0.05), Vector3(2.0, 0.85, 1.0), cover_col, true, "table")
	# Сундук со снаряжением в углу
	_push(out, Vector3(hp.x + hs.x * 0.35, 0.425, hp.z - front_z_dir * hs.z * 0.30), Vector3(1.1, 0.85, 0.8), cover_col, true, "chest")
	# Мешки с песком под фасадным окном (огневая позиция внутри комнаты)
	_push(out, Vector3(hp.x + 2.2, 0.34, fz - front_z_dir * 0.45), Vector3(1.4, 0.68, 0.5), sandbag_col, true, "sandbag")

	# 8. ДЕРЕВЯННЫЙ ЗАБОР ПАЛИСАДНИКА (ШТАКЕТНИК ВЫСОТОЙ 1.08 М - ПАРКУРНЫЙ!)
	var fence_z: float = fz + front_z_dir * 3.6
	var yard_w: float = hs.x + 4.0
	# Передний заборчик с проходом калитки (проход 2.2 м по центру)
	_push(out, Vector3(hp.x - yard_w * 0.28, 0.54, fence_z), Vector3(yard_w * 0.44, 1.08, 0.20), fence_col, true, "picket_fence")
	_push(out, Vector3(hp.x + yard_w * 0.28, 0.54, fence_z), Vector3(yard_w * 0.44, 1.08, 0.20), fence_col, true, "picket_fence")
	# Столбики калитки
	_push(out, Vector3(hp.x - 1.15, 0.61, fence_z), Vector3(0.24, 1.22, 0.24), trim_col, true, "fence_post")
	_push(out, Vector3(hp.x + 1.15, 0.61, fence_z), Vector3(0.24, 1.22, 0.24), trim_col, true, "fence_post")
	# Боковые заборы усадьбы (соединяются с домом)
	var side_len: float = 3.6
	_push(out, Vector3(hp.x - yard_w * 0.5, 0.54, fz + front_z_dir * (side_len * 0.5)), Vector3(0.20, 1.08, side_len), fence_col, true, "picket_fence")
	_push(out, Vector3(hp.x + yard_w * 0.5, 0.54, fz + front_z_dir * (side_len * 0.5)), Vector3(0.20, 1.08, side_len), fence_col, true, "picket_fence")

static func _push(arr: Array[Dictionary], pos: Vector3, size: Vector3, color: Color, coll: bool, tag: String) -> void:
	arr.append({
		"pos": pos,
		"size": size,
		"color": color,
		"solid": coll,
		"coll": coll,
		"kind": tag,
		"tag": tag,
	})
