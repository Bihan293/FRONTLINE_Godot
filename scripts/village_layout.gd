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
	# Двускатная крыша церкви
	_push(out, church_pos + Vector3(0, 6.0, 0), Vector3(16.4, 1.2, 10.4), Color(0.28, 0.20, 0.16), true, "church_roof")
	# Высокая колокольня (снайперская позиция!)
	_push(out, church_pos + Vector3(9.0, 4.5, 0), Vector3(5.0, 9.0, 5.0), Color(0.48, 0.46, 0.44), true, "bell_tower")
	_push(out, church_pos + Vector3(9.0, 9.6, 0), Vector3(5.4, 1.6, 5.4), Color(0.24, 0.16, 0.14), true, "tower_roof")
	# Боковые входы и амбразуры
	_push(out, church_pos + Vector3(-9.0, 1.2, 0), Vector3(2.2, 2.4, 3.5), Color(0.40, 0.38, 0.36), true, "church_porch")

	# Каменная ограда кладбища
	_push(out, church_pos + Vector3(0, 0.6, -14.0), Vector3(28.0, 1.2, 0.8), Color(0.44, 0.43, 0.40), true, "stone_fence")
	_push(out, church_pos + Vector3(0, 0.6, 14.0), Vector3(28.0, 1.2, 0.8), Color(0.44, 0.43, 0.40), true, "stone_fence")
	_push(out, church_pos + Vector3(-14.0, 0.6, 0), Vector3(0.8, 1.2, 28.0), Color(0.44, 0.43, 0.40), true, "stone_fence")

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
	_push(out, farm_pos + Vector3(0, 8.6, -5.0), Vector3(7.0, 1.4, 7.0), Color(0.32, 0.22, 0.15), true, "windmill_cap")
	# Лопасти мельницы (деревянный каркас)
	_push(out, farm_pos + Vector3(0, 7.5, -8.6), Vector3(9.0, 0.8, 0.3), Color(0.30, 0.20, 0.12), true, "mill_blades")
	_push(out, farm_pos + Vector3(0, 7.5, -8.6), Vector3(0.8, 9.0, 0.3), Color(0.30, 0.20, 0.12), true, "mill_blades")

	# Большой деревянный амбар с сеновалом
	_push(out, farm_pos + Vector3(-2.0, 2.2, 10.0), Vector3(14.0, 4.4, 9.0), Color(0.38, 0.26, 0.17), true, "barn_wall")
	_push(out, farm_pos + Vector3(-2.0, 4.8, 10.0), Vector3(14.6, 1.2, 9.6), Color(0.26, 0.18, 0.12), true, "barn_roof")

	# Стога сена и штабели брёвен
	for sp in [Vector3(12.0, 1.2, 4.0), Vector3(12.0, 1.2, -6.0), Vector3(-12.0, 1.2, -4.0)]:
		_push(out, farm_pos + sp, Vector3(3.4, 2.4, 3.4), Color(0.62, 0.54, 0.26), true, "haystack")

	# Деревянный забор фермы
	_push(out, farm_pos + Vector3(0, 0.5, -16.0), Vector3(30.0, 1.0, 0.4), Color(0.36, 0.26, 0.16), true, "wood_fence")
	_push(out, farm_pos + Vector3(0, 0.5, 18.0), Vector3(30.0, 1.0, 0.4), Color(0.36, 0.26, 0.16), true, "wood_fence")
	_push(out, farm_pos + Vector3(16.0, 0.5, 0), Vector3(0.4, 1.0, 34.0), Color(0.36, 0.26, 0.16), true, "wood_fence")

	# -------------------------------------------------------------------------
	# 5. ЖИЛЫЕ ДОМА ДЕРЕВНИ (6 КОТТЕДЖЕЙ)
	# -------------------------------------------------------------------------
	var houses := [
		# Северо-западный дом (X = -20, Z = -22)
		{"pos": Vector3(-20.0, 0.0, -22.0), "size": Vector3(10.0, 3.8, 8.0)},
		# Северо-восточный дом (X = 20, Z = -22)
		{"pos": Vector3(20.0, 0.0, -22.0), "size": Vector3(10.0, 3.8, 8.0)},
		# Юго-западный дом (X = -20, Z = 22)
		{"pos": Vector3(-20.0, 0.0, 22.0), "size": Vector3(10.0, 3.8, 8.0)},
		# Юго-восточный дом (X = 20, Z = 22)
		{"pos": Vector3(20.0, 0.0, 22.0), "size": Vector3(10.0, 3.8, 8.0)},
		# Западный дом у церкви (X = -65, Z = 18)
		{"pos": Vector3(-65.0, 0.0, 18.0), "size": Vector3(9.0, 3.6, 7.5)},
		# Восточный дом у фермы (X = 65, Z = -18)
		{"pos": Vector3(65.0, 0.0, -18.0), "size": Vector3(9.0, 3.6, 7.5)},
	]

	for h in houses:
		var hp: Vector3 = h.pos
		var hs: Vector3 = h.size
		# Стены дома (деревянный брус)
		_push(out, hp + Vector3(0, hs.y * 0.5, 0), hs, Color(0.35, 0.25, 0.16), true, "house_wall")
		# Скатная крыша
		_push(out, hp + Vector3(0, hs.y + 0.5, 0), Vector3(hs.x + 0.6, 1.0, hs.z + 0.6), Color(0.24, 0.16, 0.12), true, "house_roof")
		# Кирпичная печная труба
		_push(out, hp + Vector3(hs.x * 0.3, hs.y + 1.2, hs.z * 0.25), Vector3(1.0, 2.2, 1.0), Color(0.48, 0.22, 0.18), true, "chimney")
		# Пристройка / дровяник
		_push(out, hp + Vector3(-hs.x * 0.5 - 1.2, 1.1, 0), Vector3(2.4, 2.2, hs.z * 0.6), Color(0.30, 0.20, 0.12), true, "shed")
		# Заборчик палисадника
		_push(out, hp + Vector3(0, 0.45, hs.z * 0.5 + 3.0), Vector3(hs.x + 4.0, 0.9, 0.3), Color(0.40, 0.30, 0.20), true, "picket_fence")

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
