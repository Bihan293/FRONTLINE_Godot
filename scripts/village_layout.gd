extends RefCounted
class_name FRONTLINEVillageLayout

const BUILDING_PACK = preload("res://scripts/tactical_buildings.gd")
const FURNITURE_PACK = preload("res://scripts/tactical_furniture.gd")
const STREET_PROP_PACK = preload("res://scripts/tactical_street_props.gd")

## Процедурная карта «ДЕРЕВНЯ» (VILLAGE) 180×150м в стиле Dummy War.
## Включает:
## - Центральная деревенская площадь с каменным колодцем (Сектор B: ПЛОЩАДЬ)
## - Старая церковь с колокольней и кладбищем (Сектор A: ЦЕРКОВЬ)
## - Ветряная мельница и амбар с сеновалом (Сектор C: МЕЛЬНИЦА)
## - 6 детализированных жилых домов и 2 наблюдательные вышки
## - Полевые уличные ассеты, стога сена, ограды и тактические укрытия
## - Базы Железного Легиона (юг) и Красного Фронта (север)

const MAP_WIDTH := 180.0
const MAP_DEPTH := 150.0
const LANDSCAPE_CELLS_X := 90
const LANDSCAPE_CELLS_Z := 75
static var _terrain_noise_cache: Array[FastNoiseLite] = []
static var _village_asset_cache: Array[Dictionary] = []
static var _building_box_cache: Dictionary = {}

static func spawns_iron() -> Array[Vector3]:
	return [
		_spawn_point(-24.0, 62.0),
		_spawn_point(-8.0, 65.0),
		_spawn_point(0.0, 68.0),
		_spawn_point(12.0, 65.0),
		_spawn_point(26.0, 62.0),
	]

static func spawns_red() -> Array[Vector3]:
	return [
		_spawn_point(-24.0, -62.0),
		_spawn_point(-8.0, -65.0),
		_spawn_point(0.0, -68.0),
		_spawn_point(12.0, -65.0),
		_spawn_point(26.0, -62.0),
	]

static func _spawn_point(x: float, z: float) -> Vector3:
	return Vector3(x, terrain_height_at(x, z) + 0.4, z)

static func sectors() -> Array[Dictionary]:
	return [
		{
			"name": "A",
			"label": "ЦЕРКОВЬ",
			"pos": Vector3(-45.0, terrain_height_at(-45.0, 0.0), 0.0),
			"radius": 14.0,
			"owner": "NEUTRAL",
		},
		{
			"name": "B",
			"label": "ПЛОЩАДЬ",
			"pos": Vector3(0.0, terrain_height_at(0.0, 0.0), 0.0),
			"radius": 14.0,
			"owner": "NEUTRAL",
		},
		{
			"name": "C",
			"label": "МЕЛЬНИЦА",
			"pos": Vector3(45.0, terrain_height_at(45.0, 0.0), 0.0),
			"radius": 14.0,
			"owner": "NEUTRAL",
		},
	]

static func barrels() -> Array[Vector3]:
	return [
		# Склад у мельницы
		_barrel_point(42.0, -8.0),
		_barrel_point(43.5, -8.0),
		# Двор церкви
		_barrel_point(-48.0, 6.0),
		# Центральная площадь у повозок
		_barrel_point(6.0, -4.0),
		# Перекрёсток южного въезда
		_barrel_point(-14.0, 32.0),
		# Перекрёсток северного въезда
		_barrel_point(16.0, -32.0),
		# База Легиона
		_barrel_point(18.0, 58.0),
		# База Красного Фронта
		_barrel_point(-18.0, -58.0),
	]

static func _barrel_point(x: float, z: float) -> Vector3:
	return Vector3(x, terrain_height_at(x, z), z)

static func terrain_height_at(x: float, z: float) -> float:
	var noises := _make_terrain_noises()
	var broad := noises[0].get_noise_2d(x, z) * 2.7
	var detail := noises[1].get_noise_2d(x, z) * 0.38
	var ridge := sin(x * 0.026 + z * 0.014) * cos(z * 0.031 - x * 0.009) * 0.62
	var height := broad + detail + ridge

	# Дороги, поселение и обе базы остаются ровными под существующей геометрией.
	var flat_weight := 0.0
	if absf(z) <= 76.0:
		flat_weight = maxf(flat_weight, 1.0 - _smoothstep(5.0, 15.0, absf(x)))
	if absf(x) <= 72.0:
		flat_weight = maxf(flat_weight, 1.0 - _smoothstep(4.0, 14.0, absf(z)))
	flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, Vector2(0.0, 0.0), Vector2(17.0, 17.0), 6.0))
	flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, Vector2(-45.0, 0.0), Vector2(29.0, 18.0), 6.0))
	flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, Vector2(45.0, 0.0), Vector2(20.0, 21.0), 7.0))
	for house in [Vector2(-20.0, -24.0), Vector2(20.0, -24.0), Vector2(-20.0, 24.0), Vector2(20.0, 24.0)]:
		flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, house, Vector2(10.0, 9.0), 4.0))
	flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, Vector2(-68.0, 22.0), Vector2(9.0, 8.0), 4.0))
	flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, Vector2(70.0, -26.0), Vector2(9.0, 8.0), 4.0))
	flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, Vector2(-34.0, 60.0), Vector2(7.0, 7.0), 3.0))
	flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, Vector2(34.0, -60.0), Vector2(7.0, 7.0), 3.0))
	flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, Vector2(0.0, 60.0), Vector2(38.0, 16.0), 5.0))
	flat_weight = maxf(flat_weight, _flat_zone_weight(x, z, Vector2(0.0, -60.0), Vector2(38.0, 16.0), 5.0))

	# У самой границы оставляем ровную кромку под лесные завалы и коллизию карты.
	var edge_distance := minf(MAP_WIDTH * 0.5 - absf(x), MAP_DEPTH * 0.5 - absf(z))
	var edge_weight := 1.0 - _smoothstep(4.0, 14.0, edge_distance)
	flat_weight = maxf(flat_weight, edge_weight)
	return lerpf(height, 0.0, clampf(flat_weight, 0.0, 1.0))

static func _make_terrain_noises() -> Array[FastNoiseLite]:
	if not _terrain_noise_cache.is_empty():
		return _terrain_noise_cache
	var broad := FastNoiseLite.new()
	broad.seed = 18411
	broad.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	broad.frequency = 0.012
	broad.fractal_octaves = 4
	broad.fractal_lacunarity = 2.0
	broad.fractal_gain = 0.48
	var detail := FastNoiseLite.new()
	detail.seed = 902
	detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail.frequency = 0.045
	detail.fractal_octaves = 2
	_terrain_noise_cache = [broad, detail]
	return _terrain_noise_cache

static func _flat_zone_weight(x: float, z: float, center: Vector2, half_size: Vector2, fade: float) -> float:
	var dx := maxf(absf(x - center.x) - half_size.x, 0.0)
	var dz := maxf(absf(z - center.y) - half_size.y, 0.0)
	return 1.0 - _smoothstep(0.0, fade, Vector2(dx, dz).length())

static func _smoothstep(edge0: float, edge1: float, value: float) -> float:
	var t := clampf((value - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func create_landscape_mesh(cells_x: int = LANDSCAPE_CELLS_X, cells_z: int = LANDSCAPE_CELLS_Z) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stride := cells_x + 1
	for z_index in range(cells_z + 1):
		var z := -MAP_DEPTH * 0.5 + MAP_DEPTH * float(z_index) / float(cells_z)
		for x_index in range(cells_x + 1):
			var x := -MAP_WIDTH * 0.5 + MAP_WIDTH * float(x_index) / float(cells_x)
			tool.set_color(_landscape_vertex_color(x, z))
			tool.set_uv(Vector2((x + MAP_WIDTH * 0.5) * 0.12, (z + MAP_DEPTH * 0.5) * 0.12))
			tool.add_vertex(Vector3(x, terrain_height_at(x, z), z))
	for z_index in range(cells_z):
		for x_index in range(cells_x):
			var a := z_index * stride + x_index
			var b := a + 1
			var c := a + stride
			var d := c + 1
			tool.add_index(a)
			tool.add_index(c)
			tool.add_index(d)
			tool.add_index(a)
			tool.add_index(d)
			tool.add_index(b)
	tool.generate_normals()
	return tool.commit()

static func _landscape_vertex_color(x: float, z: float) -> Color:
	var noise := _make_terrain_noises()[1].get_noise_2d(x * 2.0, z * 2.0) * 0.035
	var grass := Color(0.37, 0.40, 0.27).lightened(noise)
	var road_distance := INF
	if absf(z) <= 76.0:
		road_distance = minf(road_distance, absf(x))
	if absf(x) <= 72.0:
		road_distance = minf(road_distance, absf(z))
	if road_distance < 3.6:
		return Color(0.30, 0.27, 0.21)
	if road_distance < 6.5:
		return grass.lerp(Color(0.30, 0.27, 0.21), 1.0 - (road_distance - 3.6) / 2.9)
	return grass

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

	# Старые коробочные прилавки, телеги и разрозненные мешки на площади удалены.

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
	# 6. ЮЖНЫЙ ВОЕННЫЙ ЛАГЕРЬ: IRON LEGION (Z = 50..70)
	# -------------------------------------------------------------------------
	var iron_base := Vector3(0.0, 0.0, 60.0)
	# Командная армейская палатка (брезент цвета фельдграу)
	_push(out, iron_base + Vector3(0, 1.8, 0), Vector3(12.0, 3.6, 8.0), Color(0.28, 0.32, 0.30), true, "hq_tent")
	_push(out, iron_base + Vector3(0, 3.8, 0), Vector3(12.4, 0.6, 8.4), Color(0.24, 0.28, 0.26), true, "hq_roof")

	# -------------------------------------------------------------------------
	# 7. СЕВЕРНЫЙ ВОЕННЫЙ ЛАГЕРЬ: RED FRONT (Z = -50..-70)
	# -------------------------------------------------------------------------
	var red_base := Vector3(0.0, 0.0, -60.0)
	# Полевой штабной блиндаж (брёвна и накаты земли)
	_push(out, red_base + Vector3(0, 1.6, 0), Vector3(12.0, 3.2, 8.0), Color(0.34, 0.24, 0.17), true, "hq_bunker")
	_push(out, red_base + Vector3(0, 3.5, 0), Vector3(12.6, 0.8, 8.6), Color(0.26, 0.20, 0.14), true, "bunker_earth")

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

	# Новые детализированные дома, меблировка и полевые ассеты.
	out.append_array(_village_asset_boxes())

	return out

static func _village_building_sites() -> Array[Dictionary]:
	return [
		{"position": Vector3(-20.0, 0.0, -24.0), "type": "house_2story", "rotation": 0.0},
		{"position": Vector3(20.0, 0.0, -24.0), "type": "house_1story", "rotation": 0.0},
		{"position": Vector3(-20.0, 0.0, 24.0), "type": "house_ruin_destroyed", "rotation": 180.0},
		{"position": Vector3(20.0, 0.0, 24.0), "type": "house_l_shaped_villa", "rotation": 180.0},
		{"position": Vector3(-68.0, 0.0, 22.0), "type": "house_2story", "rotation": 180.0},
		{"position": Vector3(70.0, 0.0, -26.0), "type": "house_1story", "rotation": 0.0},
		{"position": Vector3(-34.0, 0.0, 60.0), "type": "house_checkpoint_tower", "rotation": 0.0},
		{"position": Vector3(34.0, 0.0, -60.0), "type": "house_checkpoint_tower", "rotation": 180.0}
	]

static func _village_prop_sites() -> Array[Dictionary]:
	var placements: Array[Dictionary] = [
		{"type": "wooden_utility_pole", "x": -9.0, "z": -42.0, "rotation": 0.0},
		{"type": "wooden_utility_pole", "x": 9.0, "z": -42.0, "rotation": 0.0},
		{"type": "wooden_utility_pole", "x": -9.0, "z": 42.0, "rotation": 0.0},
		{"type": "wooden_utility_pole", "x": 9.0, "z": 42.0, "rotation": 0.0},
		{"type": "road_sign_direction", "x": 8.5, "z": -18.0, "rotation": 0.0},
		{"type": "road_sign_yield", "x": -8.5, "z": 18.0, "rotation": 180.0},
		{"type": "bus_stop_shelter", "x": 10.0, "z": -51.0, "rotation": 90.0},
		{"type": "burnt_car_sedan", "x": -25.0, "z": 0.0, "rotation": 0.0},
		{"type": "military_truck_wreck", "x": 30.0, "z": 0.0, "rotation": 0.0},
		{"type": "ammo_crate_stack", "x": -62.0, "z": -19.0, "rotation": 90.0},
		{"type": "sandbag_wall_straight", "x": -20.0, "z": 15.0, "rotation": 0.0},
		{"type": "sandbag_wall_straight", "x": 20.0, "z": -15.0, "rotation": 0.0},
		{"type": "sandbag_firing_nest", "x": -36.0, "z": 48.0, "rotation": 0.0},
		{"type": "sandbag_firing_nest", "x": 36.0, "z": -48.0, "rotation": 180.0},
		{"type": "concrete_pipe_segment", "x": 39.0, "z": 31.0, "rotation": 90.0}
	]
	for placement in placements:
		var x: float = placement.x
		var z: float = placement.z
		placement["position"] = Vector3(x, terrain_height_at(x, z), z)
	return placements

static func _village_asset_boxes() -> Array[Dictionary]:
	if not _village_asset_cache.is_empty():
		return _village_asset_cache
	var all_boxes: Array[Dictionary] = []
	for site in _village_building_sites():
		for box in _site_geometry_boxes(site):
			var tagged := box.duplicate()
			tagged["kind"] = "village_asset"
			all_boxes.append(tagged)
	for placement in _village_prop_sites():
		var boxes := STREET_PROP_PACK.get_prop_boxes(str(placement.type), placement.position, float(placement.rotation))
		for box in boxes:
			var tagged := box.duplicate()
			tagged["kind"] = "village_asset"
			all_boxes.append(tagged)
	_village_asset_cache = all_boxes
	return _village_asset_cache

static func _site_geometry_boxes(site: Dictionary) -> Array[Dictionary]:
	var position: Vector3 = site.position
	var type_name: String = site.type
	var rotation: float = site.rotation
	var cache_key := "%s:%s:%s" % [str(position), type_name, str(rotation)]
	if _building_box_cache.has(cache_key):
		return _building_box_cache[cache_key]
	var origin := Vector3(position.x, terrain_height_at(position.x, position.z), position.z)
	var boxes := BUILDING_PACK.get_building_boxes(type_name, origin, rotation)
	for item in _furniture_placements(type_name):
		var local: Vector3 = item.position
		var item_origin := _rotate_local_offset(origin, local, rotation)
		boxes.append_array(FURNITURE_PACK.get_furniture_boxes(str(item.type), item_origin, rotation))
	_building_box_cache[cache_key] = boxes
	return boxes

static func _furniture_placements(building_type: String) -> Array[Dictionary]:
	match building_type:
		"house_1story":
			return [
				{"type": "dining_table", "position": Vector3(-3.45, 0.24, 0.0)},
				{"type": "dining_chair", "position": Vector3(-3.45, 0.24, -1.25)},
				{"type": "dining_chair", "position": Vector3(-3.45, 0.24, 1.25)},
				{"type": "wood_stove", "position": Vector3(3.60, 0.24, -1.50)},
				{"type": "single_bed", "position": Vector3(3.50, 0.24, 1.70)}
			]
		"house_2story":
			return [
				{"type": "sofa", "position": Vector3(-3.10, 0.24, 2.65)},
				{"type": "dining_table", "position": Vector3(3.10, 0.24, 2.65)},
				{"type": "kitchen_cabinet", "position": Vector3(-3.35, 0.24, -3.10)},
				{"type": "single_bed", "position": Vector3(3.10, 0.24, -2.80)},
				{"type": "wardrobe", "position": Vector3(4.75, 0.24, -3.75)}
			]
		_:
			return []

static func _rotate_local_offset(origin: Vector3, local: Vector3, rotation_deg: float) -> Vector3:
	var angle := deg_to_rad(rotation_deg)
	return Vector3(
		origin.x + local.x * cos(angle) - local.z * sin(angle),
		origin.y + local.y,
		origin.z + local.x * sin(angle) + local.z * cos(angle)
	)

static func add_tactical_assets(parent: Node3D, with_collision: bool = true) -> void:
	for site in _village_building_sites():
		var type_name: String = site.type
		var node_name := "Village_" + type_name.capitalize().replace("_", "")
		_add_asset_batch(parent, node_name, _site_geometry_boxes(site), with_collision, true)
	var props: Array[Dictionary] = []
	for placement in _village_prop_sites():
		props.append_array(STREET_PROP_PACK.get_prop_boxes(str(placement.type), placement.position, float(placement.rotation)))
	_add_asset_batch(parent, "VillageStreetAssets", props, with_collision, false)

static func _add_asset_batch(parent: Node3D, node_name: String, boxes: Array[Dictionary], with_collision: bool, cast_shadows: bool) -> void:
	if boxes.is_empty():
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var collision_faces := PackedVector3Array()
	for box in boxes:
		_append_asset_box(surface, collision_faces, box.pos, box.size, box.color, with_collision and bool(box.get("solid", true)))
	var mesh := surface.commit()
	if mesh != null:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color.WHITE
		material.vertex_color_use_as_albedo = true
		material.vertex_color_is_srgb = true
		material.roughness = 0.94
		var instance := MeshInstance3D.new()
		instance.name = node_name
		instance.mesh = mesh
		instance.material_override = material
		if not cast_shadows:
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)
	if with_collision and not collision_faces.is_empty():
		var body := StaticBody3D.new()
		body.name = node_name + "Collision"
		var collision := CollisionShape3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.set_backface_collision_enabled(true)
		shape.set_faces(collision_faces)
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)

static func _append_asset_box(surface: SurfaceTool, collision_faces: PackedVector3Array, center: Vector3, size: Vector3, color: Color, collidable: bool) -> void:
	var half := size * 0.5
	var x0 := center.x - half.x
	var x1 := center.x + half.x
	var y0 := center.y - half.y
	var y1 := center.y + half.y
	var z0 := center.z - half.z
	var z1 := center.z + half.z
	_add_asset_quad(surface, collision_faces, Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3.LEFT, color, collidable)
	_add_asset_quad(surface, collision_faces, Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3.RIGHT, color, collidable)
	_add_asset_quad(surface, collision_faces, Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3.DOWN, color, collidable)
	_add_asset_quad(surface, collision_faces, Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3.UP, color, collidable)
	_add_asset_quad(surface, collision_faces, Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3.BACK, color, collidable)
	_add_asset_quad(surface, collision_faces, Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3.FORWARD, color, collidable)

static func _add_asset_quad(surface: SurfaceTool, collision_faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, color: Color, collidable: bool) -> void:
	surface.set_normal(normal)
	surface.set_color(color)
	surface.set_uv(Vector2(0.0, 0.0))
	surface.add_vertex(a)
	surface.set_uv(Vector2(1.0, 0.0))
	surface.add_vertex(b)
	surface.set_uv(Vector2(1.0, 1.0))
	surface.add_vertex(c)
	surface.set_uv(Vector2(0.0, 0.0))
	surface.add_vertex(a)
	surface.set_uv(Vector2(1.0, 1.0))
	surface.add_vertex(c)
	surface.set_uv(Vector2(0.0, 1.0))
	surface.add_vertex(d)
	if collidable:
		collision_faces.append_array([a, b, c, a, c, d])

## Крупные несущие конструкции, отбрасывающие тени на карте.
## Мелкие декорации, штакетники, рамы, ставни, ступени, мебель и осыпи
## отключают отбрасывание теней, экономя более 50% теневых draw calls на мобильных GPU.
const SHADOW_TAGS := {
	"church_hall": true,
	"church_roof": true,
	"bell_tower": true,
	"tower_roof": true,
	"windmill_tower": true,
	"windmill_cap": true,
	"barn_wall": true,
	"barn_lintel": true,
	"barn_roof": true,
	"hq_tent": true,
	"hq_roof": true,
	"hq_bunker": true,
	"bunker_earth": true,
	"forest_wall": true,
}

static func _push(arr: Array[Dictionary], pos: Vector3, size: Vector3, color: Color, coll: bool, tag: String, cast_shadow: Variant = null) -> void:
	var shadow: bool = (cast_shadow as bool) if cast_shadow != null else SHADOW_TAGS.get(tag, false)
	arr.append({
		"pos": pos,
		"size": size,
		"color": color,
		"solid": coll,
		"coll": coll,
		"kind": tag,
		"tag": tag,
		"cast_shadow": shadow,
	})
