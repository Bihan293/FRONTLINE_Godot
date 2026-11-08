extends RefCounted
class_name FRONTLINETacticalBuildings

## Пак проработанных 3D-моделей зданий для тактического боя (FRONTLINE / Dummy War / Bodycam style).
## Включает:
## - 1-этажный опорный пункт / дом с круговой обороной и наружным выходом на крышу
## - 2-этажный городской дом с лестницей, балконом и выходом на крышу
## - 3-этажное административное здание / штаб с двухмаршевой лестницей, боковым и фронтальным балконами
## - 5-этажный жилой дом (многоэтажка) с центральным лестничным узлом, тактическими проломами в стенах,
##   балконами на всех этажах и эксплуатируемой крышей с укрытиями
##
## Все здания спроектированы БЕЗ мебели (чистая боевая архитектура):
## - Проработанные комнаты и коридоры для манёвров, зачистки помещений (CQB) и обходов с флангов
## - Дверные проёмы 1.30 м х 2.20 м (свободный проход для двух бойцов и ботов)
## - Оконные проёмы: подоконник 0.88 м (идеально для стрельбы с колена/стоя, наклонов Q/E и паркура/перемаха)
## - Лестничные пролёты со ступенями высотой 0.20 м (ниже floor_snap_length 0.25 м, без застреваний)
## - Балконы с защитным парапетом 0.98 м (1.0 м) для ведения огня и укрытия
## - Эксплуатируемые плоские крыши с периметральным защитным парапетом 1.05 м

const STORY_HEIGHT := 3.20 # Высота этажа (чистая высота потолка 2.96 м + плита 0.24 м)
const WALL_THICKNESS := 0.28 # Толщина несущих стен
const SILL_HEIGHT := 0.88 # Высота подоконника (рассчитана под паркур и упор оружия)
const WINDOW_HEIGHT := 1.25 # Высота окна (дает 1.25 м свободного просвета > 1.15 м для паркура)
const WINDOW_WIDTH := 1.30 # Ширина окна
const DOOR_HEIGHT := 2.20 # Высота двери
const DOOR_WIDTH := 1.30 # Ширина двери
const PARAPET_HEIGHT := 0.98 # Высота балконных и кровельных парапетов (укрытие 1.0 м)

# Палитра материалов (бетон, штукатурка, кирпич, плиты перекрытий, парапеты, сталь)
const COLOR_CONCRETE_WALL := Color(0.68, 0.65, 0.60)
const COLOR_STUCCO_WALL := Color(0.74, 0.71, 0.65)
const COLOR_BRICK_BASE := Color(0.48, 0.26, 0.20)
const COLOR_SLAB_FLOOR := Color(0.42, 0.40, 0.38)
const COLOR_INTERIOR_WALL := Color(0.78, 0.75, 0.70)
const COLOR_BALCONY_SLAB := Color(0.55, 0.52, 0.48)
const COLOR_PARAPET := Color(0.62, 0.59, 0.55)
const COLOR_STAIRS := Color(0.46, 0.44, 0.42)
const COLOR_ROOF_GRAVEL := Color(0.34, 0.34, 0.34)
const COLOR_LINTEL := Color(0.38, 0.35, 0.32)
const COLOR_STEEL := Color(0.30, 0.32, 0.34)
const COLOR_RUBBLE := Color(0.52, 0.48, 0.44)

static func get_available_types() -> Array[String]:
	return ["house_1story", "house_2story", "house_3story", "house_5story"]

static func get_building_info(type_name: String) -> Dictionary:
	match type_name:
		"house_1story":
			return {
				"name": "1-этажный тактический опорный пункт",
				"floors": 1,
				"width": 11.0,
				"length": 9.0,
				"height": 4.4,
				"balconies": 0,
				"roof_access": true,
				"description": "2 комнаты, коридор, круговые бойницы, внешняя лестница на крышу с парапетом 0.98м."
			}
		"house_2story":
			return {
				"name": "2-этажный городской дом",
				"floors": 2,
				"width": 12.0,
				"length": 10.0,
				"height": 7.8,
				"balconies": 1,
				"roof_access": true,
				"description": "4 комнаты, плавный лестничный марш (ступени 0.20м), фасадный балкон, выход на крышу."
			}
		"house_3story":
			return {
				"name": "3-этажное административное здание / штаб",
				"floors": 3,
				"width": 14.0,
				"length": 11.5,
				"height": 11.2,
				"balconies": 2,
				"roof_access": true,
				"description": "Двухстворчатый парадный портал, широкий центральный холл, боковой и фронтальный балконы, пентхаус на крыше."
			}
		"house_5story":
			return {
				"name": "5-этажный многоквартирный дом / руина",
				"floors": 5,
				"width": 16.0,
				"length": 13.0,
				"height": 18.8,
				"balconies": 6,
				"roof_access": true,
				"description": "Центральная двухмаршевая лестничная клетка, 16 квартир, проломы в перегородках для фланговых атак, терраса на крыше с укрытиями вентиляции."
			}
		_:
			return {}

## Генерирует массив словарей-боксов для добавления в layout карты (battlefield, village, polygon).
## Автоматически трансформирует координаты и габариты боксов с учетом origin и поворота rot_deg.
static func get_building_boxes(type_name: String, origin: Vector3 = Vector3.ZERO, rot_deg: float = 0.0) -> Array[Dictionary]:
	var local_boxes: Array[Dictionary] = []
	match type_name:
		"house_1story":
			_build_1story(local_boxes)
		"house_2story":
			_build_2story(local_boxes)
		"house_3story":
			_build_3story(local_boxes)
		"house_5story":
			_build_5story(local_boxes)
		_:
			_build_1story(local_boxes)

	# Применяем поворот и смещение к мировой точке origin
	var out: Array[Dictionary] = []
	var rad := deg_to_rad(rot_deg)
	var cos_a := cos(rad)
	var sin_a := sin(rad)

	for b in local_boxes:
		var lp: Vector3 = b.pos
		var ls: Vector3 = b.size
		var wp := Vector3(
			origin.x + (lp.x * cos_a - lp.z * sin_a),
			origin.y + lp.y,
			origin.z + (lp.x * sin_a + lp.z * cos_a)
		)
		var ws := ls
		if not is_zero_approx(sin_a):
			# При повороте на 90 или 270 градусов меняем размеры X и Z
			if is_equal_approx(absf(sin_a), 1.0):
				ws = Vector3(ls.z, ls.y, ls.x)
		out.append({
			"pos": wp,
			"size": ws,
			"color": b.color,
			"solid": b.get("solid", true),
			"kind": b.get("kind", "tactical_building"),
			"cast_shadow": b.get("cast_shadow", true)
		})
	return out

## Возвращает тактические точки здания (входы, окна, балконы, снайперские позиции на крыше)
## для интеграции с ботами и спавнами.
static func get_building_tactical_points(type_name: String, origin: Vector3 = Vector3.ZERO, rot_deg: float = 0.0) -> Dictionary:
	var local_pts: Dictionary = {
		"entrances": [],
		"windows": [],
		"balconies": [],
		"snipers": []
	}

	match type_name:
		"house_1story":
			local_pts["entrances"].append_array([Vector3(0.0, 0.20, -4.5), Vector3(0.0, 0.20, 4.5)])
			local_pts["windows"].append_array([
				Vector3(-3.2, 0.88, -4.5), Vector3(3.2, 0.88, -4.5),
				Vector3(-3.2, 0.88, 4.5), Vector3(3.2, 0.88, 4.5),
				Vector3(-5.5, 0.88, 0.0), Vector3(5.5, 0.88, 0.0)
			])
			local_pts["snipers"].append_array([
				Vector3(-4.8, 3.8, -3.8), Vector3(4.8, 3.8, -3.8),
				Vector3(-4.8, 3.8, 3.8), Vector3(4.8, 3.8, 3.8)
			])
		"house_2story":
			local_pts["entrances"].append_array([Vector3(-2.5, 0.20, -5.0), Vector3(2.5, 0.20, 5.0)])
			local_pts["balconies"].append(Vector3(0.0, 3.60, -5.7))
			local_pts["snipers"].append_array([
				Vector3(-5.2, 7.4, -4.2), Vector3(5.2, 7.4, -4.2),
				Vector3(-5.2, 7.4, 4.2), Vector3(5.2, 7.4, 4.2)
			])
		"house_3story":
			local_pts["entrances"].append_array([Vector3(0.0, 0.24, -5.75), Vector3(0.0, 0.24, 5.75)])
			local_pts["balconies"].append_array([
				Vector3(7.7, 3.66, 0.0), # Восток 2-й этаж
				Vector3(0.0, 7.08, -6.45) # Север 3-й этаж
			])
			local_pts["snipers"].append_array([
				Vector3(-6.2, 10.7, -5.0), Vector3(6.2, 10.7, -5.0),
				Vector3(-6.2, 10.7, 5.0), Vector3(6.2, 10.7, 5.0)
			])
		"house_5story":
			local_pts["entrances"].append_array([Vector3(0.0, 0.30, -6.5), Vector3(0.0, 0.30, 6.5)])
			local_pts["balconies"].append_array([
				Vector3(-3.8, 3.74, -7.25), Vector3(3.8, 7.18, -7.25),
				Vector3(-3.8, 10.62, -7.25), Vector3(3.8, 14.06, -7.25)
			])
			local_pts["snipers"].append_array([
				Vector3(-7.2, 17.7, -5.8), Vector3(7.2, 17.7, -5.8),
				Vector3(-7.2, 17.7, 5.8), Vector3(7.2, 17.7, 5.8)
			])

	var rad := deg_to_rad(rot_deg)
	var cos_a := cos(rad)
	var sin_a := sin(rad)
	var res: Dictionary = {}

	for category in local_pts.keys():
		var arr: Array[Vector3] = []
		for pt in local_pts[category]:
			var wp := Vector3(
				origin.x + (pt.x * cos_a - pt.z * sin_a),
				origin.y + pt.y,
				origin.z + (pt.x * sin_a + pt.z * cos_a)
			)
			arr.append(wp)
		res[category] = arr

	return res

## Создаёт полноценную отдельную ноду Node3D со StaticBody3D и коллизиями.
static func create_building_node(type_name: String) -> Node3D:
	var root := Node3D.new()
	root.name = type_name.capitalize().replace(" ", "")

	var boxes := get_building_boxes(type_name, Vector3.ZERO, 0.0)
	var body := StaticBody3D.new()
	body.name = "BuildingCollisions"
	root.add_child(body)

	for b in boxes:
		var pos: Vector3 = b.pos
		var size: Vector3 = b.size
		var color: Color = b.color
		var solid: bool = bool(b.get("solid", true))

		if solid:
			var shape := CollisionShape3D.new()
			var box_shape := BoxShape3D.new()
			box_shape.size = size
			shape.shape = box_shape
			shape.position = pos
			body.add_child(shape)

		var mesh_instance := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = size
		mesh_instance.mesh = box_mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.85
		mesh_instance.material_override = mat
		mesh_instance.position = pos
		if not bool(b.get("cast_shadow", true)):
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mesh_instance)

	return root

# ==============================================================================
# 1-ЭТАЖНЫЙ ОПОРНЫЙ ПУНКТ (11м х 9м х 4.4м)
# ==============================================================================
static func _build_1story(out: Array[Dictionary]) -> void:
	var w := 11.0
	var l := 9.0
	var h := STORY_HEIGHT
	var hw := w * 0.5
	var hl := l * 0.5

	# Цоколь и пол
	_push(out, Vector3(0.0, 0.10, 0.0), Vector3(w + 0.4, 0.20, l + 0.4), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.22, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor")

	# Фасад (Z = -hl): дверь по центру + 2 окна по бокам
	_build_wall_with_doors_and_windows(out,
		Vector3(0.0, 0.20, -hl), w, h, true,
		[0.0], # Дверь по центру (x=0)
		[-3.2, 3.2] # 2 фасадных окна (подоконник 0.88м)
	)

	# Задняя стена (Z = hl): запасной выход + 2 окна
	_build_wall_with_doors_and_windows(out,
		Vector3(0.0, 0.20, hl), w, h, true,
		[0.0], # Задняя дверь
		[-3.2, 3.2] # 2 тыльных окна
	)

	# Левая боковая стена (X = -hw): с 1 окном для флангового огня
	_build_wall_with_doors_and_windows(out,
		Vector3(-hw, 0.20, 0.0), l, h, false,
		[], # дверей нет
		[0.0] # 1 центральное окно
	)

	# Правая боковая стена (X = hw): с 1 окном
	_build_wall_with_doors_and_windows(out,
		Vector3(hw, 0.20, 0.0), l, h, false,
		[],
		[0.0]
	)

	# Внутренние перегородки (2 боевые комнаты и центральный коридор шириной 2.4 м)
	_build_wall_with_doors_and_windows(out,
		Vector3(-1.20, 0.20, 0.0), l - 1.0, h, false,
		[-1.5, 1.5], # 2 двери в левые комнаты
		[]
	)
	_build_wall_with_doors_and_windows(out,
		Vector3(1.20, 0.20, 0.0), l - 1.0, h, false,
		[-1.5, 1.5], # 2 двери в правые комнаты
		[]
	)

	# Эксплуатируемая крыша с парапетом 0.98 м для снайперской круговой обороны
	var y_roof := h + 0.20
	_push(out, Vector3(0.0, y_roof + 0.12, 0.0), Vector3(w + 0.6, 0.24, l + 0.6), COLOR_ROOF_GRAVEL, true, "roof_slab")
	_build_parapet_ring(out, Vector3(0.0, y_roof + 0.24, 0.0), w + 0.6, l + 0.6, PARAPET_HEIGHT)

	# Внешняя тактическая лестница на крышу с западной стороны (X = -hw - 0.55 м)
	_build_stair_flight(out, Vector3(-hw - 0.65, 0.20, -1.8), 1.10, h, 1)
	# Площадка выхода на крышу
	_push(out, Vector3(-hw - 0.65, y_roof + 0.12, 0.5), Vector3(1.2, 0.24, 1.4), COLOR_SLAB_FLOOR, true, "stair_landing")

# ==============================================================================
# 2-ЭТАЖНЫЙ ГОРОДСКОЙ ДОМ С БАЛКОНОМ И ЛЕСТНИЦЕЙ (12м х 10м х 7.8м)
# ==============================================================================
static func _build_2story(out: Array[Dictionary]) -> void:
	var w := 12.0
	var l := 10.0
	var h := STORY_HEIGHT
	var hw := w * 0.5
	var hl := l * 0.5

	# Цоколь и пол 1-го этажа
	_push(out, Vector3(0.0, 0.10, 0.0), Vector3(w + 0.4, 0.20, l + 0.4), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.22, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor_1")

	# --- 1 ЭТАЖ (Y = 0.20..3.40) ---
	# Фасад: парадный вход + 2 окна
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, -hl), w, h, true, [-2.5], [2.2, -4.8])
	# Задняя стена: выход во двор + 2 окна
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, hl), w, h, true, [2.5], [-2.2, 4.8])
	# Боковые стены
	_build_wall_with_doors_and_windows(out, Vector3(-hw, 0.20, 0.0), l, h, false, [], [-2.4, 2.4])
	_build_wall_with_doors_and_windows(out, Vector3(hw, 0.20, 0.0), l, h, false, [], [-2.4, 2.4])
	# Внутренний коридор 1-го этажа
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, 0.0), w - 1.0, h, true, [-1.8, 2.5], [])

	# Лестничный пролёт с 1-го на 2-й этаж (16 ступеней по 0.20 м, длина 3.52 м, без застревания)
	var stair_x := -hw + 1.30
	var stair_z := hl - 2.80
	_build_stair_flight(out, Vector3(stair_x, 0.20, stair_z), 1.30, h, 1)

	# Перекрытие 2-го этажа (с вырезом под лестничный марш)
	_build_floor_slab_with_stair_opening(out, 0.20 + h, w, l, Vector3(stair_x, 0.20 + h, stair_z), Vector3(1.6, 0.28, 3.8))

	# --- 2 ЭТАЖ (Y = 3.60..6.80) ---
	var y2 := 0.20 + h + 0.20
	# Фасад 2-го этажа: дверь на балкон + 2 окна
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, -hl), w, h, true, [0.0], [-3.8, 3.8])
	# Балкон на фасаде 2-го этажа: консольная плита 3.8м х 1.4м + парапет 0.98м (направлен вперед на Север)
	_build_balcony(out, Vector3(0.0, y2, -hl - 0.70), 3.80, 1.40, PARAPET_HEIGHT, Vector3(0, 0, -1))

	# Задняя стена 2-го этажа: 3 окна
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, hl), w, h, true, [], [-3.6, 0.0, 3.6])
	# Боковые стены 2-го этажа
	_build_wall_with_doors_and_windows(out, Vector3(-hw, y2, 0.0), l, h, false, [], [-2.4, 2.4])
	_build_wall_with_doors_and_windows(out, Vector3(hw, y2, 0.0), l, h, false, [], [-2.4, 2.4])
	# Внутренние перегородки 2-го этажа (холл и 2 комнаты)
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, 0.0), w - 1.0, h, true, [-2.2, 2.2], [])

	# Лестница с 2-го этажа на крышу
	_build_stair_flight(out, Vector3(stair_x, y2, stair_z), 1.30, h, 1)

	# Эксплуатируемая крыша с пентхаусом и выходом
	var y_roof := y2 + h
	_build_roof_with_penthouse(out, y_roof, w, l, Vector3(stair_x, y_roof, stair_z))

# ==============================================================================
# 3-ЭТАЖНОЕ АДМИНИСТРАТИВНОЕ ЗДАНИЕ / ШТАБ (14м х 11.5м х 11.2м)
# ==============================================================================
static func _build_3story(out: Array[Dictionary]) -> void:
	var w := 14.0
	var l := 11.5
	var h := STORY_HEIGHT
	var hw := w * 0.5
	var hl := l * 0.5

	# Фундамент
	_push(out, Vector3(0.0, 0.12, 0.0), Vector3(w + 0.5, 0.24, l + 0.5), COLOR_BRICK_BASE, true, "building_base")

	var stair_x := 0.0
	var stair_z := hl - 2.80
	var stair_w := 1.50

	for floor_idx in range(3):
		var y_floor := 0.24 + floor_idx * (h + 0.22)
		var is_ground := (floor_idx == 0)

		# Пол этажа (кроме первого, который на цоколе)
		if not is_ground:
			_build_floor_slab_with_stair_opening(out, y_floor - 0.22, w, l, Vector3(stair_x, y_floor - 0.22, stair_z), Vector3(stair_w + 0.4, 0.24, 3.8))

		# Наружные стены
		if is_ground:
			# Двойной парадный портал на 1-м этаже (ширина 2.0 м)
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, -hl), w, h, true, [0.0], [-4.2, 4.2])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, hl), w, h, true, [0.0], [-4.2, 4.2])
		elif floor_idx == 1:
			# 2-й этаж: боковой балкон на восточном фасаде (X = +hw)
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, -hl), w, h, true, [-3.2], [0.0, 3.2])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, hl), w, h, true, [], [-4.2, 0.0, 4.2])
			_build_balcony(out, Vector3(hw + 0.70, y_floor, 0.0), 3.60, 1.40, PARAPET_HEIGHT, Vector3(1, 0, 0))
			_build_wall_with_doors_and_windows(out, Vector3(hw, y_floor, 0.0), l, h, false, [0.0], [-3.2, 3.2])
		else:
			# 3-й этаж: фронтальный балкон с панорамным обзором
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, -hl), w, h, true, [0.0], [-4.2, 4.2])
			_build_balcony(out, Vector3(0.0, y_floor, -hl - 0.70), 4.20, 1.40, PARAPET_HEIGHT, Vector3(0, 0, -1))
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, hl), w, h, true, [], [-4.2, 0.0, 4.2])
			_build_wall_with_doors_and_windows(out, Vector3(hw, y_floor, 0.0), l, h, false, [], [-3.2, 0.0, 3.2])

		# Западная стена
		if floor_idx != 1:
			_build_wall_with_doors_and_windows(out, Vector3(-hw, y_floor, 0.0), l, h, false, [], [-3.2, 0.0, 3.2])
		else:
			_build_wall_with_doors_and_windows(out, Vector3(-hw, y_floor, 0.0), l, h, false, [], [-3.2, 3.2])

		# Внутренние тактические перегородки (4 изолированные комнаты на каждом этаже)
		_build_wall_with_doors_and_windows(out, Vector3(-2.8, y_floor, -1.0), w * 0.45, h, true, [-1.2], [])
		_build_wall_with_doors_and_windows(out, Vector3(2.8, y_floor, -1.0), w * 0.45, h, true, [1.2], [])

		# Лестничный марш на следующий этаж
		_build_stair_flight(out, Vector3(stair_x, y_floor, stair_z), stair_w, h, -1)

	# Крыша 3-го этажа с пентхаусом
	var y_roof := 0.24 + 3 * (h + 0.22)
	_build_roof_with_penthouse(out, y_roof, w, l, Vector3(stair_x, y_roof, stair_z))

# ==============================================================================
# 5-ЭТАЖНЫЙ МНОГОКВАРТИРНЫЙ ДОМ (16м х 13м х 18.8м)
# ==============================================================================
static func _build_5story(out: Array[Dictionary]) -> void:
	var w := 16.0
	var l := 13.0
	var h := STORY_HEIGHT
	var hw := w * 0.5
	var hl := l * 0.5

	# Массивный железобетонный цоколь
	_push(out, Vector3(0.0, 0.15, 0.0), Vector3(w + 0.6, 0.30, l + 0.6), COLOR_BRICK_BASE, true, "building_base")

	var stair_x := 0.0
	var stair_z := 0.0 # Центральная двухмаршевая лестничная клетка
	var stair_w := 1.40

	for floor_idx in range(5):
		var y_floor := 0.30 + floor_idx * (h + 0.24)
		var is_ground := (floor_idx == 0)

		# Плита перекрытия (с проёмом для лестничных маршей)
		if not is_ground:
			_build_floor_slab_with_stair_opening(out, y_floor - 0.24, w, l, Vector3(stair_x, y_floor - 0.24, stair_z), Vector3(3.2, 0.26, 4.4))

		# Наружные фасадные стены (Z = -hl и Z = hl)
		if is_ground:
			# 1-й этаж: парадный подъезд по центру + окна
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, -hl), w, h, true, [0.0], [-5.2, -2.6, 2.6, 5.2])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, hl), w, h, true, [0.0], [-5.2, -2.6, 2.6, 5.2])
		else:
			# 2, 3, 4, 5 этажи: чередующиеся тактические балконы с парапетом
			var has_balcony_left: bool = (floor_idx % 2 == 1)
			var has_balcony_right: bool = (floor_idx % 2 == 0)

			var doors_f: Array = []
			var windows_f: Array = []

			if has_balcony_left:
				doors_f.append(-3.8)
				_build_balcony(out, Vector3(-3.8, y_floor, -hl - 0.75), 3.20, 1.50, PARAPET_HEIGHT, Vector3(0, 0, -1))
			else:
				windows_f.append(-3.8)

			if has_balcony_right:
				doors_f.append(3.8)
				_build_balcony(out, Vector3(3.8, y_floor, -hl - 0.75), 3.20, 1.50, PARAPET_HEIGHT, Vector3(0, 0, -1))
			else:
				windows_f.append(3.8)

			windows_f.append_array([-6.0, 0.0, 6.0])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, -hl), w, h, true, doors_f, windows_f)

			# Задняя стена с балконами на противоположной стороне
			var doors_b: Array = []
			var windows_b: Array = []
			if not has_balcony_left:
				doors_b.append(-3.8)
				_build_balcony(out, Vector3(-3.8, y_floor, hl + 0.75), 3.20, 1.50, PARAPET_HEIGHT, Vector3(0, 0, 1))
			else:
				windows_b.append(-3.8)
			if not has_balcony_right:
				doors_b.append(3.8)
				_build_balcony(out, Vector3(3.8, y_floor, hl + 0.75), 3.20, 1.50, PARAPET_HEIGHT, Vector3(0, 0, 1))
			else:
				windows_b.append(3.8)
			windows_b.append_array([-6.0, 0.0, 6.0])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, hl), w, h, true, doors_b, windows_b)

		# Торцевые боковые стены здания (X = -hw и X = hw) с окнами
		_build_wall_with_doors_and_windows(out, Vector3(-hw, y_floor, 0.0), l, h, false, [], [-3.6, 3.6])
		_build_wall_with_doors_and_windows(out, Vector3(hw, y_floor, 0.0), l, h, false, [], [-3.6, 3.6])

		# Внутренние стены: центральная лестничная шахта и изолированные квартиры
		_build_wall_with_doors_and_windows(out, Vector3(-1.8, y_floor, 0.0), l - 1.2, h, false, [-3.2, 3.2], [])
		_build_wall_with_doors_and_windows(out, Vector3(1.8, y_floor, 0.0), l - 1.2, h, false, [-3.2, 3.2], [])

		# Поперечные перегородки квартир
		# На 3-м и 4-м этажах добавляем тактические проломы в стенах для фланговых манёвров!
		var door_left := [-1.2]
		var door_right := [1.2]
		if floor_idx == 2:
			door_left.append(1.6) # Пролом в левой квартире (Floor 3)
			_push(out, Vector3(-4.8, y_floor + 0.25, 1.6), Vector3(1.4, 0.45, 0.8), COLOR_RUBBLE, true, "rubble")
		elif floor_idx == 3:
			door_right.append(-1.6) # Пролом в правой квартире (Floor 4)
			_push(out, Vector3(4.8, y_floor + 0.25, -1.6), Vector3(1.4, 0.45, 0.8), COLOR_RUBBLE, true, "rubble")

		_build_wall_with_doors_and_windows(out, Vector3(-4.8, y_floor, 0.0), hw - 2.0, h, true, door_left, [])
		_build_wall_with_doors_and_windows(out, Vector3(4.8, y_floor, 0.0), hw - 2.0, h, true, door_right, [])

		# Двухмаршевая лестничная клетка с промежуточной площадкой:
		# Марш 1 (левый): с y_floor до y_floor + h * 0.5 в сторону +Z
		_build_stair_flight(out, Vector3(stair_x - 0.75, y_floor, stair_z - 0.3), stair_w * 0.95, h * 0.5, 1)
		# Промежуточная площадка лестничной клетки на середине этажа
		_push(out, Vector3(stair_x, y_floor + h * 0.5 - 0.10, stair_z + 1.65), Vector3(3.0, 0.20, 1.4), COLOR_SLAB_FLOOR, true, "stair_landing")
		# Марш 2 (правый): с y_floor + h * 0.5 до y_floor + h в сторону -Z
		_build_stair_flight(out, Vector3(stair_x + 0.75, y_floor + h * 0.5, stair_z - 0.3), stair_w * 0.95, h * 0.5, -1)

	# 6. Эксплуатируемая крыша 5-этажки (боевая арена на высоте 18 метров)
	var y_roof := 0.30 + 5 * (h + 0.24)
	_build_roof_with_penthouse(out, y_roof, w, l, Vector3(stair_x, y_roof, stair_z))

	# Укрытия вентиляции и шахты лифта на крыше
	_push(out, Vector3(-4.5, y_roof + 0.70, 2.5), Vector3(2.2, 1.4, 2.2), COLOR_CONCRETE_WALL, true, "vent_shaft")
	_push(out, Vector3(4.5, y_roof + 0.70, -2.5), Vector3(2.2, 1.4, 2.2), COLOR_CONCRETE_WALL, true, "vent_shaft")

# ==============================================================================
# ВСПОМОГАТЕЛЬНЫЕ АРХИТЕКТУРНЫЕ КОМПОНЕНТЫ
# ==============================================================================

## Строит стену заданной длины и высоты с вырезами под двери и окна.
## axis_x = true: стена расположена вдоль оси X (Z постоянный)
## axis_x = false: стена расположена вдоль оси Z (X постоянный)
static func _build_wall_with_doors_and_windows(
	out: Array[Dictionary],
	center: Vector3,
	length: float,
	height: float,
	axis_x: bool,
	door_offsets: Array,
	window_offsets: Array
) -> void:
	var th := WALL_THICKNESS
	var sill_h := SILL_HEIGHT
	var win_h := WINDOW_HEIGHT
	var win_w := WINDOW_WIDTH
	var door_h := DOOR_HEIGHT
	var door_w := DOOR_WIDTH

	# Сортируем все проёмы вдоль длины стены
	var cuts: Array[Dictionary] = []
	for d in door_offsets:
		cuts.append({"type": "door", "center": float(d), "width": door_w})
	for w in window_offsets:
		cuts.append({"type": "window", "center": float(w), "width": win_w})

	cuts.sort_custom(func(a, b): return a.center < b.center)

	var cur_pos := -length * 0.5
	for cut in cuts:
		var cut_c: float = cut.center
		var cut_w: float = cut.width
		var cut_start := cut_c - cut_w * 0.5
		var cut_end := cut_c + cut_w * 0.5

		# Глухой простенок перед проёмом
		if cut_start > cur_pos + 0.05:
			var segment_len := cut_start - cur_pos
			var seg_c := cur_pos + segment_len * 0.5
			_push_wall_segment(out, center, seg_c, height * 0.5, segment_len, height, th, axis_x, COLOR_CONCRETE_WALL)

		# Обработка самого проёма
		if cut.type == "door":
			# Перемычка над дверью
			var lintel_h := height - door_h
			if lintel_h > 0.05:
				_push_wall_segment(out, center, cut_c, door_h + lintel_h * 0.5, cut_w, lintel_h, th, axis_x, COLOR_LINTEL)
		elif cut.type == "window":
			# Подоконная стенка (укрытие для стрельбы с колена и опора для паркура/перемаха)
			_push_wall_segment(out, center, cut_c, sill_h * 0.5, cut_w, sill_h, th, axis_x, COLOR_CONCRETE_WALL)
			# Подоконная доска (декоративный отлив, без теней)
			_push_wall_segment(out, center, cut_c, sill_h, cut_w + 0.15, 0.06, th + 0.10, axis_x, COLOR_LINTEL, false)
			# Перемычка над окном
			var lintel_bottom := sill_h + win_h
			var lintel_h := height - lintel_bottom
			if lintel_h > 0.05:
				_push_wall_segment(out, center, cut_c, lintel_bottom + lintel_h * 0.5, cut_w, lintel_h, th, axis_x, COLOR_LINTEL)

		cur_pos = cut_end

	# Завершающий глухой простенок до конца стены
	var end_pos := length * 0.5
	if end_pos > cur_pos + 0.05:
		var segment_len := end_pos - cur_pos
		var seg_c := cur_pos + segment_len * 0.5
		_push_wall_segment(out, center, seg_c, height * 0.5, segment_len, height, th, axis_x, COLOR_CONCRETE_WALL)

static func _push_wall_segment(out: Array[Dictionary], origin: Vector3, offset_l: float, offset_y: float, len_val: float, h_val: float, th_val: float, axis_x: bool, color: Color, cast_shadow: Variant = null) -> void:
	var p: Vector3
	var s: Vector3
	if axis_x:
		p = Vector3(origin.x + offset_l, origin.y + offset_y, origin.z)
		s = Vector3(len_val, h_val, th_val)
	else:
		p = Vector3(origin.x, origin.y + offset_y, origin.z + offset_l)
		s = Vector3(th_val, h_val, len_val)
	_push(out, p, s, color, true, "wall", cast_shadow)

## Плита межэтажного перекрытия с вырезом под лестничный марш.
static func _build_floor_slab_with_stair_opening(out: Array[Dictionary], y: float, w: float, l: float, stair_pos: Vector3, stair_size: Vector3) -> void:
	var th := 0.24
	var hw := w * 0.5
	var hl := l * 0.5
	var shw := stair_size.x * 0.5
	var shl := stair_size.z * 0.5

	# Разбиваем плиту на 4 сегмента вокруг лестничного проёма
	# 1. Передняя часть
	var front_len := (stair_pos.z - shl) - (-hl)
	if front_len > 0.2:
		_push(out, Vector3(0.0, y, -hl + front_len * 0.5), Vector3(w, th, front_len), COLOR_SLAB_FLOOR, true, "floor_slab")

	# 2. Задняя часть
	var back_len := hl - (stair_pos.z + shl)
	if back_len > 0.2:
		_push(out, Vector3(0.0, y, hl - back_len * 0.5), Vector3(w, th, back_len), COLOR_SLAB_FLOOR, true, "floor_slab")

	# 3. Левая часть от проёма
	var left_w := (stair_pos.x - shw) - (-hw)
	if left_w > 0.2:
		_push(out, Vector3(-hw + left_w * 0.5, y, stair_pos.z), Vector3(left_w, th, stair_size.z), COLOR_SLAB_FLOOR, true, "floor_slab")

	# 4. Правая часть от проёма
	var right_w := hw - (stair_pos.x + shw)
	if right_w > 0.2:
		_push(out, Vector3(hw - right_w * 0.5, y, stair_pos.z), Vector3(right_w, th, stair_size.z), COLOR_SLAB_FLOOR, true, "floor_slab")

## Лестничный марш со ступенями высотой <= 0.20 м (идеальный подъем без застреваний персонажа).
static func _build_stair_flight(out: Array[Dictionary], center: Vector3, width: float, height: float, dir_z: int) -> void:
	var steps := 16 if height >= 3.0 else 8
	var step_h := height / float(steps)
	var flight_len := 3.52 if height >= 3.0 else 1.84
	var step_len := flight_len / float(steps)
	var z_sign := float(dir_z)

	# Ступени (визуальные + коллизия, без отбрасывания теней для мобильной оптимизации)
	for i in range(steps):
		var y := center.y + (float(i) + 0.5) * step_h
		var z := center.z - z_sign * (flight_len * 0.5) + z_sign * (float(i) + 0.5) * step_len
		_push(out, Vector3(center.x, y, z), Vector3(width, step_h, step_len + 0.04), COLOR_STAIRS, true, "stair_step", false)

## Консольный балкон с защитным парапетом высотой 0.98 м (1.0 м).
## facing: направление выступа балкона наружу (Vector3.FORWARD, BACK, RIGHT, LEFT).
static func _build_balcony(out: Array[Dictionary], center: Vector3, width: float, depth: float, parapet_h: float, facing: Vector3 = Vector3(0, 0, -1)) -> void:
	var slab_th := 0.22
	var pt := 0.16
	var py := center.y + parapet_h * 0.5

	if absf(facing.z) >= 0.5:
		# Балкон направлен вдоль оси Z (Север или Юг)
		_push(out, Vector3(center.x, center.y - slab_th * 0.5, center.z), Vector3(width, slab_th, depth), COLOR_BALCONY_SLAB, true, "balcony_slab")
		var outer_z := center.z + facing.z * (depth * 0.5 - pt * 0.5)
		# Главный наружный парапет (фронтальное укрытие)
		_push(out, Vector3(center.x, py, outer_z), Vector3(width, parapet_h, pt), COLOR_PARAPET, true, "balcony_parapet")
		# Боковые парапеты
		_push(out, Vector3(center.x - width * 0.5 + pt * 0.5, py, center.z), Vector3(pt, parapet_h, depth - pt), COLOR_PARAPET, true, "balcony_parapet")
		_push(out, Vector3(center.x + width * 0.5 - pt * 0.5, py, center.z), Vector3(pt, parapet_h, depth - pt), COLOR_PARAPET, true, "balcony_parapet")
	else:
		# Балкон направлен вдоль оси X (Восток или Запад)
		_push(out, Vector3(center.x, center.y - slab_th * 0.5, center.z), Vector3(depth, slab_th, width), COLOR_BALCONY_SLAB, true, "balcony_slab")
		var outer_x := center.x + facing.x * (depth * 0.5 - pt * 0.5)
		# Главный наружный парапет
		_push(out, Vector3(outer_x, py, center.z), Vector3(pt, parapet_h, width), COLOR_PARAPET, true, "balcony_parapet")
		# Боковые парапеты
		_push(out, Vector3(center.x, py, center.z - width * 0.5 + pt * 0.5), Vector3(depth - pt, parapet_h, pt), COLOR_PARAPET, true, "balcony_parapet")
		_push(out, Vector3(center.x, py, center.z + width * 0.5 - pt * 0.5), Vector3(depth - pt, parapet_h, pt), COLOR_PARAPET, true, "balcony_parapet")

## Эксплуатируемая плоская крыша с надстройкой выхода (пентхаус) и периметральным парапетом.
static func _build_roof_with_penthouse(out: Array[Dictionary], y: float, w: float, l: float, stair_pos: Vector3) -> void:
	var slab_th := 0.28
	# Основная плита крыши
	_push(out, Vector3(0.0, y, 0.0), Vector3(w + 0.6, slab_th, l + 0.6), COLOR_ROOF_GRAVEL, true, "roof_slab")

	# Парапет по всему внешнему периметру крыши (высота 1.05 м)
	_build_parapet_ring(out, Vector3(0.0, y + slab_th * 0.5, 0.0), w + 0.6, l + 0.6, PARAPET_HEIGHT + 0.07)

	# Надстройка выхода с лестницы (пентхаус 2.4м высотой с дверным выходом на крышу)
	var ph_w := 2.80
	var ph_l := 3.40
	var ph_h := 2.40
	var py := y + slab_th * 0.5
	# Стены надстройки с дверным проёмом
	_build_wall_with_doors_and_windows(out, Vector3(stair_pos.x, py, stair_pos.z - ph_l * 0.5), ph_w, ph_h, true, [0.0], [])
	_build_wall_with_doors_and_windows(out, Vector3(stair_pos.x, py, stair_pos.z + ph_l * 0.5), ph_w, ph_h, true, [], [])
	_build_wall_with_doors_and_windows(out, Vector3(stair_pos.x - ph_w * 0.5, py, stair_pos.z), ph_l, ph_h, false, [], [])
	_build_wall_with_doors_and_windows(out, Vector3(stair_pos.x + ph_w * 0.5, py, stair_pos.z), ph_l, ph_h, false, [], [])
	# Крыша надстройки
	_push(out, Vector3(stair_pos.x, py + ph_h + 0.10, stair_pos.z), Vector3(ph_w + 0.3, 0.20, ph_l + 0.3), COLOR_CONCRETE_WALL, true, "penthouse_roof")

## Защитное кольцо парапета по периметру прямоугольника.
static func _build_parapet_ring(out: Array[Dictionary], base: Vector3, w: float, l: float, height: float) -> void:
	var pt := 0.20
	var py := base.y + height * 0.5
	var hw := w * 0.5
	var hl := l * 0.5
	# Север
	_push(out, Vector3(base.x, py, base.z - hl + pt * 0.5), Vector3(w, height, pt), COLOR_PARAPET, true, "roof_parapet")
	# Юг
	_push(out, Vector3(base.x, py, base.z + hl - pt * 0.5), Vector3(w, height, pt), COLOR_PARAPET, true, "roof_parapet")
	# Запад
	_push(out, Vector3(base.x - hw + pt * 0.5, py, base.z), Vector3(pt, height, l - pt * 2.0), COLOR_PARAPET, true, "roof_parapet")
	# Восток
	_push(out, Vector3(base.x + hw - pt * 0.5, py, base.z), Vector3(pt, height, l - pt * 2.0), COLOR_PARAPET, true, "roof_parapet")

static func _push(arr: Array[Dictionary], pos: Vector3, size: Vector3, color: Color, coll: bool, tag: String, cast_shadow: Variant = null) -> void:
	var shadow_val: bool = coll
	if cast_shadow != null:
		shadow_val = bool(cast_shadow)
	else:
		# Оптимизация теней для мобильных GPU (GL Compatibility):
		# Ступени лестниц, декоративные отливы подоконников, мелкие полы и обломки не отбрасывают тени!
		if tag in ["stair_step", "window_sill_board", "floor", "floor_1", "building_base", "rubble"]:
			shadow_val = false
	arr.append({
		"pos": pos,
		"size": size,
		"color": color,
		"solid": coll,
		"kind": tag,
		"cast_shadow": shadow_val
	})
