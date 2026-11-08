extends RefCounted
class_name FRONTLINETacticalBuildings

## Пак проработанных 3D-моделей зданий для тактического боя (FRONTLINE / Dummy War / Bodycam style).
## Включает 9 уникальных боевых типов:
## 1. house_1story — 1-этажный опорный пункт с круговыми бойницами и выходом на крышу
## 2. house_2story — 2-этажный городской дом с лестницей, балконом и выходом на крышу
## 3. house_3story — 3-этажное административное здание / штаб с холлами и 2 балконами
## 4. house_5story — 5-этажный жилой дом с двухмаршевой лестницей, проломами в стенах и террасой на крыше
## 5. house_barn_hangar — промышленный ангар с высокими потолками, воротами для техники и подвесными мостками
## 6. house_ruin_destroyed — разрушенное 3-этажное здание с пандусами из обрушившихся плит и снайперским гнездом
## 7. house_checkpoint_tower — 3-ярусная укреплённая наблюдательная вышка / КПП с круговой 360° боевой площадкой
## 8. house_l_shaped_villa — 2-этажная Г-образная усадьба/вилла с внутренним двором для перекрёстного огня и угловым балконом
## 9. house_bunker_pillbox — тяжёлый железобетонный ДОТ со сверхтолстыми стенами, зигзаг-тамбуром и узкими амбразурами
##
## Все здания спроектированы БЕЗ мебели (чистая тактическая архитектура):
## - Проработанные комнаты и коридоры для манёвров, зачистки помещений (CQB) и обходов с флангов
## - Дверные проёмы 1.30–2.00 м (свободный проход для двух бойцов и ботов)
## - Оконные проёмы: подоконник 0.88–0.90 м (идеально для упора оружия, наклонов Q/E и паркура/перемаха)
## - Лестничные пролёты со ступенями высотой <= 0.20 м (гарантированно ниже floor_snap_length 0.25 м, без застревания)
## - Балконы с защитным парапетом 0.98 м (1.0 м) для укрытия и обстрела улицы
## - Эксплуатируемые крыши с периметральным защитным парапетом 1.05 м

const STORY_HEIGHT := 3.20 # Высота этажа
const WALL_THICKNESS := 0.28 # Толщина типовых стен
const SILL_HEIGHT := 0.88 # Высота подоконника
const WINDOW_HEIGHT := 1.25 # Высота окна
const WINDOW_WIDTH := 1.30 # Ширина окна
const DOOR_HEIGHT := 2.20 # Высота двери
const DOOR_WIDTH := 1.30 # Ширина двери
const PARAPET_HEIGHT := 0.98 # Высота балконных и кровельных парапетов (1.0 м)

# Палитра материалов (бетон, штукатурка, кирпич, плиты перекрытий, парапеты, сталь, булыжник)
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
const COLOR_WOOD_BEAM := Color(0.36, 0.26, 0.18)
const COLOR_GLASS_TINT := Color(0.65, 0.78, 0.82)

static func get_available_types() -> Array[String]:
	return [
		"house_1story",
		"house_2story",
		"house_3story",
		"house_5story",
		"house_barn_hangar",
		"house_ruin_destroyed",
		"house_checkpoint_tower",
		"house_l_shaped_villa",
		"house_bunker_pillbox",
		"building_supermarket",
		"building_shopping_mall",
		"building_hospital",
		"building_school"
	]

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
				"description": "Центральная двухмаршевая лестничная клетка, 16 квартир, проломы в перегородках, терраса на крыше с укрытиями вентиляции."
			}
		"house_barn_hangar":
			return {
				"name": "Промышленный ангар / амбар-депо",
				"floors": 2,
				"width": 18.0,
				"length": 14.0,
				"height": 7.6,
				"balconies": 0,
				"roof_access": true,
				"description": "Высокие потолки, сквозные ворота 4.2м для техники, подвесные галереи на высоте 3.6м с мостиком и стальной лестницей."
			}
		"house_ruin_destroyed":
			return {
				"name": "Разрушенное 3-этажное здание / руина",
				"floors": 3,
				"width": 13.0,
				"length": 10.0,
				"height": 8.8,
				"balconies": 1,
				"roof_access": true,
				"description": "Артиллерийские проломы в стенах, наклонные пандусы из обрушившихся плит вместо лестниц, снайперское гнездо на 3 этаже."
			}
		"house_checkpoint_tower":
			return {
				"name": "3-ярусная укреплённая наблюдательная вышка / КПП",
				"floors": 3,
				"width": 7.0,
				"length": 7.0,
				"height": 11.6,
				"balconies": 1,
				"roof_access": true,
				"description": "Караулка внизу, наблюдательный пункт на 2 ярусе, открытая 360° снайперская площадка с навесом наверху."
			}
		"house_l_shaped_villa":
			return {
				"name": "2-этажная Г-образная усадьба с двориком",
				"floors": 2,
				"width": 15.0,
				"length": 14.0,
				"height": 7.8,
				"balconies": 1,
				"roof_access": true,
				"description": "Г-образная форма с внутренним двориком для перекрёстного огня из двух крыльев, угловой балкон 2 этажа, коридоры 90°."
			}
		"house_bunker_pillbox":
			return {
				"name": "Тяжёлый железобетонный ДОТ / бункер",
				"floors": 1,
				"width": 10.0,
				"length": 8.0,
				"height": 3.6,
				"balconies": 0,
				"roof_access": true,
				"description": "Стены 0.60м, зигзагообразный противоосколочный тамбур, 4 пулемётные амбразуры с широким сектором обстрела."
			}
		"building_supermarket":
			return {
				"name": "Супермаркет / магазин с дебаркадером",
				"floors": 1,
				"width": 22.0,
				"length": 16.0,
				"height": 5.8,
				"balconies": 0,
				"roof_access": true,
				"description": "Просторный торговый зал, кассовая зона, витрины, задний склад с разгрузочной рампой и пожарная лестница на крышу."
			}
		"building_shopping_mall":
			return {
				"name": "2-этажный торговый центр (ТЦ) с атриумом",
				"floors": 2,
				"width": 26.0,
				"length": 20.0,
				"height": 9.2,
				"balconies": 4,
				"roof_access": true,
				"description": "Двухсветный атриум, галереи 2 этажа с ограждениями, бутики, эскалаторный марш, зенитный фонарь и крыша."
			}
		"building_hospital":
			return {
				"name": "3-этажный клинический корпус больницы",
				"floors": 3,
				"width": 24.0,
				"length": 16.0,
				"height": 11.6,
				"balconies": 0,
				"roof_access": true,
				"description": "Приёмный покой скорой, длинный коридор с палатами CQB, операционный блок, две лестничные клетки и вертолётная площадка на крыше."
			}
		"building_school":
			return {
				"name": "2-этажная школа со спортзалом",
				"floors": 2,
				"width": 28.0,
				"length": 18.0,
				"height": 8.6,
				"balconies": 1,
				"roof_access": true,
				"description": "Учебное крыло с классами и широким коридором, высокий спортзал двойной высоты (7м) с балконом для зрителей."
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
		"house_barn_hangar":
			_build_barn_hangar(local_boxes)
		"house_ruin_destroyed":
			_build_ruin_destroyed(local_boxes)
		"house_checkpoint_tower":
			_build_checkpoint_tower(local_boxes)
		"house_l_shaped_villa":
			_build_l_shaped_villa(local_boxes)
		"house_bunker_pillbox":
			_build_bunker_pillbox(local_boxes)
		"building_supermarket":
			_build_supermarket(local_boxes)
		"building_shopping_mall":
			_build_shopping_mall(local_boxes)
		"building_hospital":
			_build_hospital(local_boxes)
		"building_school":
			_build_school(local_boxes)
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
		"house_barn_hangar":
			local_pts["entrances"].append_array([
				Vector3(0.0, 0.20, -6.0), Vector3(0.0, 0.20, 6.0), # Ворота
				Vector3(-9.0, 0.20, 0.0), Vector3(9.0, 0.20, 0.0)  # Пешеходные двери
			])
			local_pts["balconies"].append_array([
				Vector3(-7.6, 3.60, 0.0), Vector3(7.6, 3.60, 0.0), # Мостки
				Vector3(0.0, 3.60, 0.0) # Мостик-переход
			])
			local_pts["snipers"].append_array([
				Vector3(-7.6, 3.60, -4.5), Vector3(7.6, 3.60, -4.5),
				Vector3(-7.6, 3.60, 4.5), Vector3(7.6, 3.60, 4.5)
			])
		"house_ruin_destroyed":
			local_pts["entrances"].append_array([Vector3(-2.0, 0.20, -5.0), Vector3(3.2, 0.60, -5.0)])
			local_pts["balconies"].append(Vector3(-2.5, 3.40, -5.7))
			local_pts["snipers"].append_array([
				Vector3(-4.0, 6.80, -3.5), # Снайперское гнездо 3 этажа
				Vector3(4.0, 3.40, 2.0)
			])
		"house_checkpoint_tower":
			local_pts["entrances"].append_array([Vector3(0.0, 0.20, -3.5), Vector3(0.0, 0.20, 3.5)])
			local_pts["balconies"].append(Vector3(0.0, 7.20, 0.0))
			local_pts["snipers"].append_array([
				Vector3(-2.5, 7.20, -2.5), Vector3(2.5, 7.20, -2.5),
				Vector3(-2.5, 7.20, 2.5), Vector3(2.5, 7.20, 2.5)
			])
		"house_l_shaped_villa":
			local_pts["entrances"].append_array([
				Vector3(-2.0, 0.20, -7.0), # Парадный вход
				Vector3(-3.0, 0.20, 0.0),  # Вход из дворика
				Vector3(0.5, 0.20, 3.5)    # Вход в боковое крыло
			])
			local_pts["balconies"].append(Vector3(-1.0, 3.60, 0.7))
			local_pts["snipers"].append_array([
				Vector3(-6.5, 7.40, -6.0), Vector3(6.5, 7.40, -6.0),
				Vector3(6.5, 7.40, 6.0)
			])
		"house_bunker_pillbox":
			local_pts["entrances"].append(Vector3(1.5, 0.20, 5.2)) # За противоосколочным экраном
			local_pts["windows"].append_array([
				Vector3(-2.6, 0.90, -4.0), Vector3(2.6, 0.90, -4.0), # Фронтальные амбразуры
				Vector3(-5.0, 0.90, -1.0), Vector3(5.0, 0.90, -1.0)  # Боковые амбразуры
			])
			local_pts["snipers"].append(Vector3(0.0, 3.50, 0.0)) # Перископ на крыше
		"building_supermarket":
			local_pts["entrances"].append_array([
				Vector3(0.0, 0.20, 8.0), # Главный вход
				Vector3(4.0, 0.90, -8.0), # Дебаркадер
				Vector3(-6.0, 0.20, -8.0) # Служебный вход
			])
			local_pts["windows"].append_array([
				Vector3(-5.0, 0.88, 8.0), Vector3(5.0, 0.88, 8.0)
			])
			local_pts["snipers"].append_array([
				Vector3(-10.0, 5.0, -7.0), Vector3(10.0, 5.0, 7.0)
			])
		"building_shopping_mall":
			local_pts["entrances"].append_array([
				Vector3(-3.0, 0.20, 10.0), Vector3(3.0, 0.20, 10.0), # Порталы
				Vector3(-6.0, 0.20, -10.0), Vector3(6.0, 0.20, -10.0) # Задние выходы
			])
			local_pts["balconies"].append_array([
				Vector3(0.0, 3.80, -3.8), Vector3(0.0, 3.80, 3.8), # Галереи атриума
				Vector3(-4.8, 3.80, 0.0), Vector3(4.8, 3.80, 0.0)
			])
			local_pts["snipers"].append_array([
				Vector3(-12.0, 8.0, -9.0), Vector3(12.0, 8.0, 9.0)
			])
		"building_hospital":
			local_pts["entrances"].append_array([
				Vector3(0.0, 0.20, 8.0), # Приёмный покой
				Vector3(-8.0, 0.20, -8.0), # Служебный выход
				Vector3(-12.0, 0.20, 0.0), Vector3(12.0, 0.20, 0.0)
			])
			local_pts["windows"].append_array([
				Vector3(-5.0, 0.88, 8.0), Vector3(5.0, 0.88, 8.0),
				Vector3(-5.0, 4.28, 8.0), Vector3(5.0, 4.28, 8.0),
				Vector3(-5.0, 7.68, 8.0), Vector3(5.0, 7.68, 8.0)
			])
			local_pts["snipers"].append_array([
				Vector3(-11.0, 10.6, -7.0), Vector3(11.0, 10.6, 7.0),
				Vector3(0.0, 10.6, 0.0) # Вертолётная площадка
			])
		"building_school":
			local_pts["entrances"].append_array([
				Vector3(6.0, 0.20, 9.0), # Парадный вход школы
				Vector3(-7.0, 0.20, -9.0) # Запасной выход спортзала
			])
			local_pts["balconies"].append(Vector3(-1.0, 3.60, 0.0)) # Балкон спортзала
			local_pts["windows"].append_array([
				Vector3(4.0, 0.88, 9.0), Vector3(9.0, 0.88, 9.0),
				Vector3(4.0, 4.28, 9.0), Vector3(9.0, 4.28, 9.0)
			])
			local_pts["snipers"].append_array([
				Vector3(-13.0, 7.8, -8.0), Vector3(13.0, 7.8, 8.0)
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

	# Кэшируем материалы по цвету для оптимизации GPU draw calls и памяти
	var mat_cache: Dictionary = {}

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
		var mat: StandardMaterial3D = mat_cache.get(color)
		if mat == null:
			mat = StandardMaterial3D.new()
			mat.albedo_color = color
			mat.roughness = 0.85
			mat_cache[color] = mat
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

	_push(out, Vector3(0.0, 0.10, 0.0), Vector3(w + 0.4, 0.20, l + 0.4), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.22, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor")

	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, -hl), w, h, true, [0.0], [-3.2, 3.2])
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, hl), w, h, true, [0.0], [-3.2, 3.2])
	_build_wall_with_doors_and_windows(out, Vector3(-hw, 0.20, 0.0), l, h, false, [], [0.0])
	_build_wall_with_doors_and_windows(out, Vector3(hw, 0.20, 0.0), l, h, false, [], [0.0])

	_build_wall_with_doors_and_windows(out, Vector3(-1.20, 0.20, 0.0), l - 1.0, h, false, [-1.5, 1.5], [])
	_build_wall_with_doors_and_windows(out, Vector3(1.20, 0.20, 0.0), l - 1.0, h, false, [-1.5, 1.5], [])

	var y_roof := h + 0.20
	_push(out, Vector3(0.0, y_roof + 0.12, 0.0), Vector3(w + 0.6, 0.24, l + 0.6), COLOR_ROOF_GRAVEL, true, "roof_slab")
	_build_parapet_ring(out, Vector3(0.0, y_roof + 0.24, 0.0), w + 0.6, l + 0.6, PARAPET_HEIGHT)

	_build_stair_flight(out, Vector3(-hw - 0.65, 0.20, -1.8), 1.10, h, 1)
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

	_push(out, Vector3(0.0, 0.10, 0.0), Vector3(w + 0.4, 0.20, l + 0.4), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.22, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor_1")

	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, -hl), w, h, true, [-2.5], [2.2, -4.8])
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, hl), w, h, true, [2.5], [-2.2, 4.8])
	_build_wall_with_doors_and_windows(out, Vector3(-hw, 0.20, 0.0), l, h, false, [], [-2.4, 2.4])
	_build_wall_with_doors_and_windows(out, Vector3(hw, 0.20, 0.0), l, h, false, [], [-2.4, 2.4])
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, 0.0), w - 1.0, h, true, [-1.8, 2.5], [])

	var stair_x := -hw + 1.30
	var stair_z := hl - 2.80
	_build_stair_flight(out, Vector3(stair_x, 0.20, stair_z), 1.30, h, 1)
	_build_floor_slab_with_stair_opening(out, 0.20 + h, w, l, Vector3(stair_x, 0.20 + h, stair_z), Vector3(1.6, 0.28, 3.8))

	var y2 := 0.20 + h + 0.20
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, -hl), w, h, true, [0.0], [-3.8, 3.8])
	_build_balcony(out, Vector3(0.0, y2, -hl - 0.70), 3.80, 1.40, PARAPET_HEIGHT, Vector3(0, 0, -1))
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, hl), w, h, true, [], [-3.6, 0.0, 3.6])
	_build_wall_with_doors_and_windows(out, Vector3(-hw, y2, 0.0), l, h, false, [], [-2.4, 2.4])
	_build_wall_with_doors_and_windows(out, Vector3(hw, y2, 0.0), l, h, false, [], [-2.4, 2.4])
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, 0.0), w - 1.0, h, true, [-2.2, 2.2], [])

	_build_stair_flight(out, Vector3(stair_x, y2, stair_z), 1.30, h, 1)
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

	_push(out, Vector3(0.0, 0.12, 0.0), Vector3(w + 0.5, 0.24, l + 0.5), COLOR_BRICK_BASE, true, "building_base")

	var stair_x := 0.0
	var stair_z := hl - 2.80
	var stair_w := 1.50

	for floor_idx in range(3):
		var y_floor := 0.24 + floor_idx * (h + 0.22)
		var is_ground := (floor_idx == 0)

		if not is_ground:
			_build_floor_slab_with_stair_opening(out, y_floor - 0.22, w, l, Vector3(stair_x, y_floor - 0.22, stair_z), Vector3(stair_w + 0.4, 0.24, 3.8))

		if is_ground:
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, -hl), w, h, true, [0.0], [-4.2, 4.2])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, hl), w, h, true, [0.0], [-4.2, 4.2])
		elif floor_idx == 1:
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, -hl), w, h, true, [-3.2], [0.0, 3.2])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, hl), w, h, true, [], [-4.2, 0.0, 4.2])
			_build_balcony(out, Vector3(hw + 0.70, y_floor, 0.0), 3.60, 1.40, PARAPET_HEIGHT, Vector3(1, 0, 0))
			_build_wall_with_doors_and_windows(out, Vector3(hw, y_floor, 0.0), l, h, false, [0.0], [-3.2, 3.2])
		else:
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, -hl), w, h, true, [0.0], [-4.2, 4.2])
			_build_balcony(out, Vector3(0.0, y_floor, -hl - 0.70), 4.20, 1.40, PARAPET_HEIGHT, Vector3(0, 0, -1))
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, hl), w, h, true, [], [-4.2, 0.0, 4.2])
			_build_wall_with_doors_and_windows(out, Vector3(hw, y_floor, 0.0), l, h, false, [], [-3.2, 0.0, 3.2])

		if floor_idx != 1:
			_build_wall_with_doors_and_windows(out, Vector3(-hw, y_floor, 0.0), l, h, false, [], [-3.2, 0.0, 3.2])
		else:
			_build_wall_with_doors_and_windows(out, Vector3(-hw, y_floor, 0.0), l, h, false, [], [-3.2, 3.2])

		_build_wall_with_doors_and_windows(out, Vector3(-2.8, y_floor, -1.0), w * 0.45, h, true, [-1.2], [])
		_build_wall_with_doors_and_windows(out, Vector3(2.8, y_floor, -1.0), w * 0.45, h, true, [1.2], [])

		_build_stair_flight(out, Vector3(stair_x, y_floor, stair_z), stair_w, h, -1)

	var y_roof := 0.24 + 3 * (h + 0.22)
	_build_roof_with_penthouse(out, y_roof, w, l, Vector3(stair_x, y_roof, stair_z), Vector3(stair_w + 0.4, 0.28, 3.8))

# ==============================================================================
# 5-ЭТАЖНЫЙ МНОГОКВАРТИРНЫЙ ДОМ (16м х 13м х 18.8м)
# ==============================================================================
static func _build_5story(out: Array[Dictionary]) -> void:
	var w := 16.0
	var l := 13.0
	var h := STORY_HEIGHT
	var hw := w * 0.5
	var hl := l * 0.5

	_push(out, Vector3(0.0, 0.15, 0.0), Vector3(w + 0.6, 0.30, l + 0.6), COLOR_BRICK_BASE, true, "building_base")

	var stair_x := 0.0
	var stair_z := 0.0
	var stair_w := 1.40

	for floor_idx in range(5):
		var y_floor := 0.30 + floor_idx * (h + 0.24)
		var is_ground := (floor_idx == 0)

		if not is_ground:
			_build_floor_slab_with_stair_opening(out, y_floor - 0.24, w, l, Vector3(stair_x, y_floor - 0.24, stair_z), Vector3(3.2, 0.26, 4.4))

		if is_ground:
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, -hl), w, h, true, [0.0], [-5.2, -2.6, 2.6, 5.2])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_floor, hl), w, h, true, [0.0], [-5.2, -2.6, 2.6, 5.2])
		else:
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

		_build_wall_with_doors_and_windows(out, Vector3(-hw, y_floor, 0.0), l, h, false, [], [-3.6, 3.6])
		_build_wall_with_doors_and_windows(out, Vector3(hw, y_floor, 0.0), l, h, false, [], [-3.6, 3.6])

		_build_wall_with_doors_and_windows(out, Vector3(-1.8, y_floor, 0.0), l - 1.2, h, false, [-3.2, 3.2], [])
		_build_wall_with_doors_and_windows(out, Vector3(1.8, y_floor, 0.0), l - 1.2, h, false, [-3.2, 3.2], [])

		var door_left := [-1.2]
		var door_right := [1.2]
		if floor_idx == 2:
			door_left.append(1.6)
			_push(out, Vector3(-4.8, y_floor + 0.25, 1.6), Vector3(1.4, 0.45, 0.8), COLOR_RUBBLE, true, "rubble")
		elif floor_idx == 3:
			door_right.append(-1.6)
			_push(out, Vector3(4.8, y_floor + 0.25, -1.6), Vector3(1.4, 0.45, 0.8), COLOR_RUBBLE, true, "rubble")

		_build_wall_with_doors_and_windows(out, Vector3(-4.8, y_floor, 0.0), hw - 2.0, h, true, door_left, [])
		_build_wall_with_doors_and_windows(out, Vector3(4.8, y_floor, 0.0), hw - 2.0, h, true, door_right, [])

		_build_stair_flight(out, Vector3(stair_x - 0.75, y_floor, stair_z - 0.3), stair_w * 0.95, h * 0.5, 1)
		_push(out, Vector3(stair_x, y_floor + h * 0.5 - 0.10, stair_z + 1.65), Vector3(3.0, 0.20, 1.4), COLOR_SLAB_FLOOR, true, "stair_landing")
		_build_stair_flight(out, Vector3(stair_x + 0.75, y_floor + h * 0.5, stair_z - 0.3), stair_w * 0.95, h * 0.5, -1)

	var y_roof := 0.30 + 5 * (h + 0.24)
	_build_roof_with_penthouse(out, y_roof, w, l, Vector3(stair_x, y_roof, stair_z), Vector3(3.2, 0.28, 4.4))

	_push(out, Vector3(-4.5, y_roof + 0.70, 2.5), Vector3(2.2, 1.4, 2.2), COLOR_CONCRETE_WALL, true, "vent_shaft")
	_push(out, Vector3(4.5, y_roof + 0.70, -2.5), Vector3(2.2, 1.4, 2.2), COLOR_CONCRETE_WALL, true, "vent_shaft")

# ==============================================================================
# 5. ПРОМЫШЛЕННЫЙ АНГАР / АМБАР-ДЕПО (18м х 14м х 7.6м)
# ==============================================================================
static func _build_barn_hangar(out: Array[Dictionary]) -> void:
	var w := 18.0
	var l := 14.0
	var h := 7.20
	var hw := w * 0.5
	var hl := l * 0.5

	# Цоколь и пол
	_push(out, Vector3(0.0, 0.10, 0.0), Vector3(w + 0.6, 0.20, l + 0.6), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.22, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor")

	# Фасадные ворота для техники (Z = -hl, ширина 4.2м, высота 3.8м) + пешеходная дверь
	# Левый простенок
	_push_wall_segment(out, Vector3(0.0, 0.20, -hl), -5.85, h * 0.5, 6.30, h, WALL_THICKNESS, true, COLOR_CONCRETE_WALL)
	# Ворота в центре: перемычка над воротами (от 3.8м до 7.2м)
	_push_wall_segment(out, Vector3(0.0, 0.20, -hl), 0.0, 3.8 + (h - 3.8) * 0.5, 4.40, h - 3.8, WALL_THICKNESS, true, COLOR_LINTEL)
	# Правый простенок
	_push_wall_segment(out, Vector3(0.0, 0.20, -hl), 5.85, h * 0.5, 6.30, h, WALL_THICKNESS, true, COLOR_CONCRETE_WALL)

	# Задняя стена с симметричными воротами (сквозной проезд техники)
	_push_wall_segment(out, Vector3(0.0, 0.20, hl), -5.85, h * 0.5, 6.30, h, WALL_THICKNESS, true, COLOR_CONCRETE_WALL)
	_push_wall_segment(out, Vector3(0.0, 0.20, hl), 0.0, 3.8 + (h - 3.8) * 0.5, 4.40, h - 3.8, WALL_THICKNESS, true, COLOR_LINTEL)
	_push_wall_segment(out, Vector3(0.0, 0.20, hl), 5.85, h * 0.5, 6.30, h, WALL_THICKNESS, true, COLOR_CONCRETE_WALL)

	# Боковые стены с пешеходными дверями и верхними окнами
	_build_wall_with_doors_and_windows(out, Vector3(-hw, 0.20, 0.0), l, h, false, [0.0], [-3.8, 3.8])
	_build_wall_with_doors_and_windows(out, Vector3(hw, 0.20, 0.0), l, h, false, [0.0], [-3.8, 3.8])

	# Подвесные боевые мостки / галереи на высоте 3.6м:
	var y_catwalk := 3.60
	# Западная галерея
	_push(out, Vector3(-hw + 1.0, y_catwalk, 0.0), Vector3(2.0, 0.22, l - 0.4), COLOR_SLAB_FLOOR, true, "catwalk")
	_push(out, Vector3(-hw + 2.0, y_catwalk + PARAPET_HEIGHT * 0.5, 0.0), Vector3(0.14, PARAPET_HEIGHT, l - 0.4), COLOR_PARAPET, true, "balcony_parapet")

	# Восточная галерея
	_push(out, Vector3(hw - 1.0, y_catwalk, 0.0), Vector3(2.0, 0.22, l - 0.4), COLOR_SLAB_FLOOR, true, "catwalk")
	_push(out, Vector3(hw - 2.0, y_catwalk + PARAPET_HEIGHT * 0.5, 0.0), Vector3(0.14, PARAPET_HEIGHT, l - 0.4), COLOR_PARAPET, true, "balcony_parapet")

	# Мостик-переход между галереями над техникой (в центре Z = 0)
	_push(out, Vector3(0.0, y_catwalk, 0.0), Vector3(w - 4.0, 0.22, 1.40), COLOR_SLAB_FLOOR, true, "catwalk_bridge")
	_push(out, Vector3(0.0, y_catwalk + PARAPET_HEIGHT * 0.5, -0.70), Vector3(w - 4.0, PARAPET_HEIGHT, 0.14), COLOR_PARAPET, true, "balcony_parapet")
	_push(out, Vector3(0.0, y_catwalk + PARAPET_HEIGHT * 0.5, 0.70), Vector3(w - 4.0, PARAPET_HEIGHT, 0.14), COLOR_PARAPET, true, "balcony_parapet")

	# Стальная лестница на мостки (вдоль западной стены)
	_build_stair_flight(out, Vector3(-hw + 1.0, 0.20, -2.4), 1.20, y_catwalk - 0.20, 1)

	# Кровля с фермами и выходом
	var y_roof := h + 0.20
	_push(out, Vector3(0.0, y_roof, 0.0), Vector3(w + 0.6, 0.28, l + 0.6), COLOR_ROOF_GRAVEL, true, "roof_slab")
	_build_parapet_ring(out, Vector3(0.0, y_roof + 0.14, 0.0), w + 0.6, l + 0.6, PARAPET_HEIGHT)

# ==============================================================================
# 6. РАЗРУШЕННОЕ 3-ЭТАЖНОЕ ЗДАНИЕ / РУИНА (13м х 10м х 8.8м)
# ==============================================================================
static func _build_ruin_destroyed(out: Array[Dictionary]) -> void:
	var w := 13.0
	var l := 10.0
	var h := STORY_HEIGHT
	var hw := w * 0.5
	var hl := l * 0.5

	# Цоколь и воронка от взрыва
	_push(out, Vector3(0.0, 0.10, 0.0), Vector3(w + 0.4, 0.20, l + 0.4), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.22, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor")

	# 1 ЭТАЖ: проломы в кирпичной кладке и осыпи
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, -hl), w, h, true, [-2.0, 3.2], [-4.8])
	_push(out, Vector3(3.2, 0.45, -hl), Vector3(1.6, 0.50, 0.9), COLOR_RUBBLE, true, "rubble")

	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, hl), w, h, true, [0.0], [-3.8])
	_build_wall_with_doors_and_windows(out, Vector3(-hw, 0.20, 0.0), l, h, false, [], [-2.4, 2.4])
	# Восточная стена частично обвалена (низкий пролом для паркура 0.88м)
	_push_wall_segment(out, Vector3(hw, 0.20, 0.0), -2.5, h * 0.5, 5.0, h, WALL_THICKNESS, false, COLOR_CONCRETE_WALL)
	_push_wall_segment(out, Vector3(hw, 0.20, 0.0), 2.5, SILL_HEIGHT * 0.5, 5.0, SILL_HEIGHT, WALL_THICKNESS, false, COLOR_CONCRETE_WALL)

	# НАКЛОННЫЙ ПАНДУС ИЗ ОБРУШИВШЕЙСЯ ПЛИТЫ С 1 НА 2 ЭТАЖ (вместо лестницы!)
	# 16 ступеней с высотой 0.20м, образующих плавный забегаемый пандус
	_build_stair_flight(out, Vector3(-1.8, 0.20, 0.0), 2.20, h, 1)
	_push(out, Vector3(-1.8, 0.35, -2.2), Vector3(2.6, 0.40, 1.2), COLOR_RUBBLE, true, "rubble")

	# 2 ЭТАЖ: частично уцелевшие плиты
	var y2 := 0.20 + h + 0.20
	_push(out, Vector3(-hw + 3.4, y2 - 0.22, 0.0), Vector3(6.8, 0.24, l - 0.4), COLOR_SLAB_FLOOR, true, "floor_slab")
	_build_wall_with_doors_and_windows(out, Vector3(-hw + 3.4, y2, -hl), 6.8, h, true, [-1.5], [1.5])
	_build_wall_with_doors_and_windows(out, Vector3(-hw, y2, 0.0), l, h, false, [], [0.0])

	# Обвалившийся балкон на 2 этаже
	_build_balcony(out, Vector3(-2.5, y2, -hl - 0.70), 3.0, 1.40, PARAPET_HEIGHT, Vector3(0, 0, -1))

	# НАКЛОННЫЙ ПАНДУС С 2 НА 3 ЭТАЖ
	_build_stair_flight(out, Vector3(-hw + 1.8, y2, 1.2), 1.80, h, -1)

	# 3 ЭТАЖ: Снайперское гнездо в уцелевшем углу здания
	var y3 := y2 + h
	_push(out, Vector3(-hw + 2.5, y3, -hl + 2.5), Vector3(5.0, 0.28, 5.0), COLOR_SLAB_FLOOR, true, "floor_slab")
	# Угловые стены снайперского гнезда с парапетом
	_push(out, Vector3(-hw + 2.5, y3 + PARAPET_HEIGHT * 0.5, -hl + 0.15), Vector3(5.0, PARAPET_HEIGHT, 0.30), COLOR_PARAPET, true, "balcony_parapet")
	_push(out, Vector3(-hw + 0.15, y3 + PARAPET_HEIGHT * 0.5, -hl + 2.5), Vector3(0.30, PARAPET_HEIGHT, 5.0), COLOR_PARAPET, true, "balcony_parapet")
	_push(out, Vector3(-hw + 2.5, y3 + PARAPET_HEIGHT * 0.5, -hl + 5.0), Vector3(5.0, PARAPET_HEIGHT, 0.30), COLOR_PARAPET, true, "balcony_parapet")

# ==============================================================================
# 7. 3-ЯРУСНАЯ УКРЕПЛЁННАЯ ВЫШКА / КПП (7м х 7м х 11.6м)
# ==============================================================================
static func _build_checkpoint_tower(out: Array[Dictionary]) -> void:
	var w := 7.0
	var l := 7.0
	var h := STORY_HEIGHT
	var hw := w * 0.5
	var hl := l * 0.5

	# Цоколь
	_push(out, Vector3(0.0, 0.12, 0.0), Vector3(w + 0.4, 0.24, l + 0.4), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.24, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor")

	# 1 ЯРУС: Караульное помещение КПП
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.24, -hl), w, h, true, [0.0], [])
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.24, hl), w, h, true, [0.0], [])
	_build_wall_with_doors_and_windows(out, Vector3(-hw, 0.24, 0.0), l, h, false, [], [0.0])
	_build_wall_with_doors_and_windows(out, Vector3(hw, 0.24, 0.0), l, h, false, [], [0.0])

	# Лестница на 2 ярус
	_build_stair_flight(out, Vector3(-hw + 1.10, 0.24, 0.0), 1.10, h, 1)

	# 2 ЯРУС: Наблюдательный пост (Y = 3.68..6.88)
	var y2 := 0.24 + h + 0.20
	_build_floor_slab_with_stair_opening(out, y2 - 0.20, w, l, Vector3(-hw + 1.10, y2 - 0.20, 0.0), Vector3(1.3, 0.24, 3.8))
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, -hl), w, h, true, [], [0.0])
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, hl), w, h, true, [], [0.0])
	_build_wall_with_doors_and_windows(out, Vector3(-hw, y2, 0.0), l, h, false, [], [])
	_build_wall_with_doors_and_windows(out, Vector3(hw, y2, 0.0), l, h, false, [], [0.0])

	# Лестница на 3 ярус (вдоль восточной стены)
	_build_stair_flight(out, Vector3(hw - 1.10, y2, 0.0), 1.10, h, -1)

	# 3 ЯРУС: Круговая 360° боевая площадка (Y = 7.32..10.52)
	var y3 := y2 + h + 0.20
	_build_floor_slab_with_stair_opening(out, y3 - 0.20, w, l, Vector3(hw - 1.10, y3 - 0.20, 0.0), Vector3(1.3, 0.24, 3.8))
	# Круговой парапет высотой 1.0м
	_build_parapet_ring(out, Vector3(0.0, y3, 0.0), w, l, PARAPET_HEIGHT)

	# 4 угловые несущие колонны навеса
	var col_h := 3.0
	_push(out, Vector3(-hw + 0.3, y3 + col_h * 0.5, -hl + 0.3), Vector3(0.4, col_h, 0.4), COLOR_CONCRETE_WALL, true, "column")
	_push(out, Vector3(hw - 0.3, y3 + col_h * 0.5, -hl + 0.3), Vector3(0.4, col_h, 0.4), COLOR_CONCRETE_WALL, true, "column")
	_push(out, Vector3(-hw + 0.3, y3 + col_h * 0.5, hl - 0.3), Vector3(0.4, col_h, 0.4), COLOR_CONCRETE_WALL, true, "column")
	_push(out, Vector3(hw - 0.3, y3 + col_h * 0.5, hl - 0.3), Vector3(0.4, col_h, 0.4), COLOR_CONCRETE_WALL, true, "column")

	# Навес крыши над наблюдателями
	_push(out, Vector3(0.0, y3 + col_h + 0.12, 0.0), Vector3(w + 0.6, 0.24, l + 0.6), COLOR_ROOF_GRAVEL, true, "roof_slab")

# ==============================================================================
# 8. 2-ЭТАЖНАЯ Г-ОБРАЗНАЯ УСАДЬБА / ВИЛЛА (15м х 14м х 7.8м)
# ==============================================================================
static func _build_l_shaped_villa(out: Array[Dictionary]) -> void:
	var h := STORY_HEIGHT
	# Основное крыло: X от -7.5 до +7.5 (15м), Z от -7.0 до 0.0 (7м)
	# Боковое крыло: X от +0.5 до +7.5 (7м), Z от 0.0 до +7.0 (7м)
	# Внутренний двор: X от -7.5 до +0.5 (8м), Z от 0.0 до +7.0 (7м)

	# Цоколь обоих крыльев
	_push(out, Vector3(0.0, 0.10, -3.5), Vector3(15.4, 0.20, 7.4), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(4.0, 0.10, 3.5), Vector3(7.4, 0.20, 7.4), COLOR_BRICK_BASE, true, "building_base")

	# Пол 1 этажа
	_push(out, Vector3(0.0, 0.22, -3.5), Vector3(15.0, 0.04, 7.0), COLOR_SLAB_FLOOR, false, "floor")
	_push(out, Vector3(4.0, 0.22, 3.5), Vector3(7.0, 0.04, 7.0), COLOR_SLAB_FLOOR, false, "floor")

	# Внешние фасадные стены (Север Z = -7.0, Восток X = +7.5, Юг Z = +7.0, Запад X = -7.5)
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.20, -7.0), 15.0, h, true, [-2.0], [-5.5, 4.5])
	_build_wall_with_doors_and_windows(out, Vector3(7.5, 0.20, 0.0), 14.0, h, false, [], [-4.0, 4.0])
	_build_wall_with_doors_and_windows(out, Vector3(4.0, 0.20, 7.0), 7.0, h, true, [0.0], [-2.0, 2.0])
	_build_wall_with_doors_and_windows(out, Vector3(-7.5, 0.20, -3.5), 7.0, h, false, [], [-1.8, 1.8])

	# Внутренние стены, выходящие в дворик (перекрёстный огонь!)
	_build_wall_with_doors_and_windows(out, Vector3(-3.5, 0.20, 0.0), 8.0, h, true, [-1.5], [1.8])
	_build_wall_with_doors_and_windows(out, Vector3(0.5, 0.20, 3.5), 7.0, h, false, [0.0], [-2.0, 2.0])

	# Лестничный марш на 2 этаж
	_build_stair_flight(out, Vector3(-5.8, 0.20, -3.5), 1.30, h, 1)

	# 2 ЭТАЖ (Y = 3.60..6.80)
	var y2 := 0.20 + h + 0.20
	# Плиты перекрытия (с вырезом под лестничный марш)
	_build_floor_slab_with_stair_opening(out, y2 - 0.22, 15.0, 7.0, Vector3(-5.8, y2 - 0.22, -3.5), Vector3(1.6, 0.24, 3.8))
	_push(out, Vector3(4.0, y2 - 0.22, 3.5), Vector3(7.0, 0.24, 7.0), COLOR_SLAB_FLOOR, true, "floor_slab")

	# Стены 2 этажа
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, -7.0), 15.0, h, true, [], [-5.0, 0.0, 5.0])
	_build_wall_with_doors_and_windows(out, Vector3(7.5, y2, 0.0), 14.0, h, false, [], [-4.0, 4.0])
	_build_wall_with_doors_and_windows(out, Vector3(4.0, y2, 7.0), 7.0, h, true, [], [-2.0, 2.0])
	_build_wall_with_doors_and_windows(out, Vector3(-7.5, y2, -3.5), 7.0, h, false, [], [0.0])

	# Выход на угловой балкон
	_build_wall_with_doors_and_windows(out, Vector3(-3.5, y2, 0.0), 8.0, h, true, [-1.5], [2.0])
	_build_wall_with_doors_and_windows(out, Vector3(0.5, y2, 3.5), 7.0, h, false, [0.0], [2.0])

	# Угловой балкон 2 этажа над двориком
	_build_balcony(out, Vector3(-3.5, y2, 0.70), 8.0, 1.40, PARAPET_HEIGHT, Vector3(0, 0, 1))
	_build_balcony(out, Vector3(-0.20, y2, 3.5), 6.0, 1.40, PARAPET_HEIGHT, Vector3(-1, 0, 0))

	# Лестница на крышу
	_build_stair_flight(out, Vector3(-5.8, y2, -3.5), 1.30, h, 1)

	# Крыша Г-образной виллы (с вырезом под выход лестницы в пентхаус)
	var y_roof := y2 + h
	_build_floor_slab_with_stair_opening(out, y_roof, 15.4, 7.4, Vector3(-5.8, y_roof, -3.5), Vector3(1.6, 0.28, 3.8), COLOR_ROOF_GRAVEL, "roof_slab")
	_push(out, Vector3(4.0, y_roof, 3.5), Vector3(7.4, 0.28, 7.4), COLOR_ROOF_GRAVEL, true, "roof_slab")

	var ph_w := 2.80
	var ph_l := 3.40
	var ph_h := 2.40
	var py := y_roof + 0.14
	var ph_pos := Vector3(-5.8, py, -3.5)
	_build_wall_with_doors_and_windows(out, Vector3(ph_pos.x, py, ph_pos.z - ph_l * 0.5), ph_w, ph_h, true, [0.0], [])
	_build_wall_with_doors_and_windows(out, Vector3(ph_pos.x, py, ph_pos.z + ph_l * 0.5), ph_w, ph_h, true, [], [])
	_build_wall_with_doors_and_windows(out, Vector3(ph_pos.x - ph_w * 0.5, py, ph_pos.z), ph_l, ph_h, false, [], [])
	_build_wall_with_doors_and_windows(out, Vector3(ph_pos.x + ph_w * 0.5, py, ph_pos.z), ph_l, ph_h, false, [], [])
	_push(out, Vector3(ph_pos.x, py + ph_h + 0.10, ph_pos.z), Vector3(ph_w + 0.3, 0.20, ph_l + 0.3), COLOR_CONCRETE_WALL, true, "penthouse_roof")

	_build_parapet_ring(out, Vector3(0.0, y_roof + 0.14, -3.5), 15.4, 7.4, PARAPET_HEIGHT)
	_build_parapet_ring(out, Vector3(4.0, y_roof + 0.14, 3.5), 7.4, 7.4, PARAPET_HEIGHT)

# ==============================================================================
# 9. ТЯЖЁЛЫЙ ЖЕЛЕЗОБЕТОННЫЙ ДОТ / БУНКЕР (10м х 8м х 3.6м)
# ==============================================================================
static func _build_bunker_pillbox(out: Array[Dictionary]) -> void:
	var w := 10.0
	var l := 8.0
	var h := 3.20
	var hw := w * 0.5
	var hl := l * 0.5
	var bth := 0.60 # Сверхтолстые противоснарядные стены ДОТа

	# Массивный фундамент
	_push(out, Vector3(0.0, 0.15, 0.0), Vector3(w + 0.8, 0.30, l + 0.8), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.32, 0.0), Vector3(w - 0.4, 0.04, l - 0.4), COLOR_SLAB_FLOOR, false, "floor")

	# Фронтальная стена (Z = -hl) с 2 узкими амбразурами
	# Левый глухой сектор
	_push_wall_segment(out, Vector3(0.0, 0.30, -hl), -3.8, h * 0.5, 2.4, h, bth, true, COLOR_CONCRETE_WALL)
	# Амбразура 1 (X = -2.6): подоконник 0.90м, узкая щель 0.50м, толстая перемычка 1.80м
	_push_wall_segment(out, Vector3(0.0, 0.30, -hl), -2.6, SILL_HEIGHT * 0.5, 1.2, SILL_HEIGHT, bth, true, COLOR_CONCRETE_WALL)
	_push_wall_segment(out, Vector3(0.0, 0.30, -hl), -2.6, SILL_HEIGHT + 0.50 + (h - SILL_HEIGHT - 0.50) * 0.5, 1.2, h - SILL_HEIGHT - 0.50, bth, true, COLOR_LINTEL)
	# Центральный пилон
	_push_wall_segment(out, Vector3(0.0, 0.30, -hl), 0.0, h * 0.5, 4.0, h, bth, true, COLOR_CONCRETE_WALL)
	# Амбразура 2 (X = +2.6)
	_push_wall_segment(out, Vector3(0.0, 0.30, -hl), 2.6, SILL_HEIGHT * 0.5, 1.2, SILL_HEIGHT, bth, true, COLOR_CONCRETE_WALL)
	_push_wall_segment(out, Vector3(0.0, 0.30, -hl), 2.6, SILL_HEIGHT + 0.50 + (h - SILL_HEIGHT - 0.50) * 0.5, 1.2, h - SILL_HEIGHT - 0.50, bth, true, COLOR_LINTEL)
	# Правый глухой сектор
	_push_wall_segment(out, Vector3(0.0, 0.30, -hl), 3.8, h * 0.5, 2.4, h, bth, true, COLOR_CONCRETE_WALL)

	# Боковые стены с фланговыми амбразурами
	_push_wall_segment(out, Vector3(-hw, 0.30, 0.0), -2.0, h * 0.5, 4.0, h, bth, false, COLOR_CONCRETE_WALL)
	_push_wall_segment(out, Vector3(-hw, 0.30, 0.0), 0.5, SILL_HEIGHT * 0.5, 1.2, SILL_HEIGHT, bth, false, COLOR_CONCRETE_WALL)
	_push_wall_segment(out, Vector3(-hw, 0.30, 0.0), 0.5, SILL_HEIGHT + 0.50 + (h - SILL_HEIGHT - 0.50) * 0.5, 1.2, h - SILL_HEIGHT - 0.50, bth, false, COLOR_LINTEL)
	_push_wall_segment(out, Vector3(-hw, 0.30, 0.0), 2.5, h * 0.5, 3.0, h, bth, false, COLOR_CONCRETE_WALL)

	_push_wall_segment(out, Vector3(hw, 0.30, 0.0), -2.0, h * 0.5, 4.0, h, bth, false, COLOR_CONCRETE_WALL)
	_push_wall_segment(out, Vector3(hw, 0.30, 0.0), 0.5, SILL_HEIGHT * 0.5, 1.2, SILL_HEIGHT, bth, false, COLOR_CONCRETE_WALL)
	_push_wall_segment(out, Vector3(hw, 0.30, 0.0), 0.5, SILL_HEIGHT + 0.50 + (h - SILL_HEIGHT - 0.50) * 0.5, 1.2, h - SILL_HEIGHT - 0.50, bth, false, COLOR_LINTEL)
	_push_wall_segment(out, Vector3(hw, 0.30, 0.0), 2.5, h * 0.5, 3.0, h, bth, false, COLOR_CONCRETE_WALL)

	# Задняя стена с дверью в зигзаг-тамбур
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.30, hl), w, h, true, [1.5], [])

	# ПРОТИВООСКОЛОЧНЫЙ ЗИГЗАГ-ТАМБУР (защита входа от прямых ракет и гранат)
	# Внешняя защитная стенка
	_push(out, Vector3(1.5, 0.30 + h * 0.5, hl + 1.4), Vector3(3.2, h, 0.45), COLOR_CONCRETE_WALL, true, "wall")
	# Боковой возвратный экран
	_push(out, Vector3(3.1, 0.30 + h * 0.5, hl + 0.7), Vector3(0.45, h, 1.4), COLOR_CONCRETE_WALL, true, "wall")

	# Тяжёлая монолитная крыша ДОТа
	var y_roof := 0.30 + h
	_push(out, Vector3(0.0, y_roof + 0.25, 0.0), Vector3(w + 1.2, 0.50, l + 1.2), COLOR_ROOF_GRAVEL, true, "roof_slab")

	# Бронированный перископ / башенка на крыше
	_push(out, Vector3(0.0, y_roof + 0.90, 0.0), Vector3(1.8, 0.80, 1.8), COLOR_STEEL, true, "bunker_cupola")

# ==============================================================================
# 10. СУПЕРМАРКЕТ / МАГАЗИН С ДЕБАРКАДЕРОМ (22м х 16м х 4.6м)
# ==============================================================================
static func _build_supermarket(out: Array[Dictionary]) -> void:
	var w := 22.0
	var l := 16.0
	var h := 4.40
	var hw := w * 0.5
	var hl := l * 0.5

	# Массивный фундамент и пол
	_push(out, Vector3(0.0, 0.15, 0.0), Vector3(w + 1.0, 0.30, l + 1.0), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.32, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor")

	# Фасадный вход (Z = hl = 8.0): главный двустворчатый портал в центре (X=0.0, ширина 3.2м), широкие витрины слева и справа
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.30, hl), w, h, true, [0.0], [-5.0, 5.0])

	# Задняя стена дебаркадера (Z = -hl = -8.0): погрузочные ворота склада (X=4.0, ширина 3.6м), дверь персонала (X=-6.0)
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.30, -hl), w, h, true, [-6.0, 4.0], [])
	# Бетонная разгрузочная рампа снаружи дебаркадера
	_push(out, Vector3(4.0, 0.45, -hl - 1.5), Vector3(4.6, 0.90, 3.0), COLOR_CONCRETE_WALL, true, "loading_dock")

	# Боковые стены с верхними световыми просветами
	_build_wall_with_doors_and_windows(out, Vector3(-hw, 0.30, 0.0), l, h, false, [], [-2.0, 3.0])
	_build_wall_with_doors_and_windows(out, Vector3(hw, 0.30, 0.0), l, h, false, [], [-2.0, 3.0])

	# Внутренняя несущая стена между торговым залом и складом (Z = -2.0) с широким проходом в центре (3.0м)
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.30, -2.0), w - 0.4, h, true, [0.0], [])

	# Кабинет администрации / охраны на складе (X от -hw до -5.0, Z от -hl до -2.0)
	_build_wall_with_doors_and_windows(out, Vector3(-5.0, 0.30, -5.0), 6.0, h, false, [1.0], [-1.0])

	# Металлическая внешняя пожарная лестница на крышу на восточной стене
	_build_stair_flight(out, Vector3(hw + 0.8, 0.30, 3.0), 1.4, h, 1)

	# Плоская крыша с защитным парапетом 0.98м
	var y_roof := 0.30 + h
	_push(out, Vector3(0.0, y_roof + 0.12, 0.0), Vector3(w + 0.6, 0.24, l + 0.6), COLOR_ROOF_GRAVEL, true, "roof_slab")
	_build_parapet_ring(out, Vector3(0.0, y_roof + 0.12, 0.0), w + 0.6, l + 0.6, PARAPET_HEIGHT)

	# 2 промышленные климатические установки (HVAC) на крыше (тактические укрытия)
	_push(out, Vector3(-5.0, y_roof + 0.95, 2.0), Vector3(2.6, 1.4, 1.8), COLOR_STEEL, true, "rooftop_hvac")
	_push(out, Vector3(4.0, y_roof + 0.95, -4.0), Vector3(2.8, 1.4, 2.0), COLOR_STEEL, true, "rooftop_hvac")

# ==============================================================================
# 11. 2-ЭТАЖНЫЙ ТОРГОВЫЙ ЦЕНТР С АТРИУМОМ (26м х 20м х 7.8м)
# ==============================================================================
static func _build_shopping_mall(out: Array[Dictionary]) -> void:
	var w := 26.0
	var l := 20.0
	var story_h := 3.60
	var hw := w * 0.5
	var hl := l * 0.5

	# Фундамент и пол 1 этажа
	_push(out, Vector3(0.0, 0.15, 0.0), Vector3(w + 1.0, 0.30, l + 1.0), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.32, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor_1")

	# 1-й ЭТАЖ:
	# Фасад (Z = hl = 10.0): парадные порталы атриума (X = -3.0 и X = 3.0), витрины
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.30, hl), w, story_h, true, [-3.0, 3.0], [-8.0, 8.0])
	# Задняя стена (Z = -hl = -10.0): аварийные выходы
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.30, -hl), w, story_h, true, [-6.0, 6.0], [])
	# Боковые стены 1 этажа с окнами
	_build_wall_with_doors_and_windows(out, Vector3(-hw, 0.30, 0.0), l, story_h, false, [], [-4.0, 4.0])
	_build_wall_with_doors_and_windows(out, Vector3(hw, 0.30, 0.0), l, story_h, false, [], [-4.0, 4.0])

	# Внутренние стены торговых бутиков 1 этажа:
	# Продольные фасады бутиков слева и справа от центрального прохода
	_build_wall_with_doors_and_windows(out, Vector3(-5.0, 0.30, 0.0), l - 4.0, story_h, false, [-3.0, 3.0], [])
	_build_wall_with_doors_and_windows(out, Vector3(5.0, 0.30, 0.0), l - 4.0, story_h, false, [-3.0, 3.0], [])
	# Поперечные перегородки между бутиками
	_build_wall_with_doors_and_windows(out, Vector3(-hw * 0.5 - 2.5, 0.30, 0.0), hw - 5.0, story_h, true, [], [])
	_build_wall_with_doors_and_windows(out, Vector3(hw * 0.5 + 2.5, 0.30, 0.0), hw - 5.0, story_h, true, [], [])

	# Главный лестничный/эскалаторный марш в атриуме (подъём от Z=3.5 к Z=-2.5 на высоту 3.6м)
	_build_stair_flight(out, Vector3(0.0, 0.30, 0.5), 2.4, story_h, -1)

	# Вспомогательная лестничная клетка в северо-восточном углу
	_build_stair_flight(out, Vector3(hw - 3.0, 0.30, -hl + 3.0), 1.6, story_h, 1)

	# ПЕРЕКРЫТИЕ 2 ЭТАЖА (Y = 0.30 + story_h = 3.90м)
	# Вырез под открытый центральный двухсветный атриум (размером 10.0м x 8.0м)
	var y2 := 0.30 + story_h
	_build_floor_slab_with_stair_opening(out, y2, w - 0.2, l - 0.2, Vector3(0.0, y2, 0.0), Vector3(10.0, 0.28, 8.0), COLOR_SLAB_FLOOR, "floor_2")

	# Ограждение-балюстрада вокруг проёма атриума на 2 этаже (высота 0.98м)
	_build_parapet_ring(out, Vector3(0.0, y2 + 0.14, 0.0), 10.2, 8.2, PARAPET_HEIGHT)

	# 2-й ЭТАЖ:
	# Стены 2 этажа по периметру
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, hl), w, story_h, true, [], [-7.0, 0.0, 7.0])
	_build_wall_with_doors_and_windows(out, Vector3(0.0, y2, -hl), w, story_h, true, [], [-7.0, 7.0])
	_build_wall_with_doors_and_windows(out, Vector3(-hw, y2, 0.0), l, story_h, false, [], [-4.0, 4.0])
	_build_wall_with_doors_and_windows(out, Vector3(hw, y2, 0.0), l, story_h, false, [], [-4.0, 4.0])

	# ПЛОСКАЯ КРЫША С ЗЕНИТНЫМ ФОНАРЁМ
	var y_roof := y2 + story_h
	_push(out, Vector3(0.0, y_roof + 0.14, 0.0), Vector3(w + 0.6, 0.28, l + 0.6), COLOR_ROOF_GRAVEL, true, "roof_slab")
	_build_parapet_ring(out, Vector3(0.0, y_roof + 0.14, 0.0), w + 0.6, l + 0.6, PARAPET_HEIGHT + 0.07)

	# Стеклянный зенитный купол-пирамида над атриумом
	_push(out, Vector3(0.0, y_roof + 0.85, 0.0), Vector3(10.4, 1.2, 8.4), COLOR_GLASS_TINT, true, "atrium_skylight")
	_push(out, Vector3(0.0, y_roof + 1.50, 0.0), Vector3(8.0, 0.10, 6.0), COLOR_STEEL, true, "skylight_frame")

# ==============================================================================
# 12. 3-ЭТАЖНЫЙ КЛИНИЧЕСКИЙ КОРПУС БОЛЬНИЦЫ (24м х 16м х 11.2м)
# ==============================================================================
static func _build_hospital(out: Array[Dictionary]) -> void:
	var w := 24.0
	var l := 16.0
	var story_h := 3.40
	var hw := w * 0.5
	var hl := l * 0.5

	# Фундамент и цоколь
	_push(out, Vector3(0.0, 0.15, 0.0), Vector3(w + 1.0, 0.30, l + 1.0), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.32, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor_1")

	# ЦИКЛ ПО 3 ЭТАЖАМ:
	for fl in range(3):
		var y_fl := 0.30 + float(fl) * story_h

		# Внешние стены этажа
		if fl == 0:
			# 1 этаж: центральный портал приёмного покоя скорой (ширина 3.2м), окна палат
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_fl, hl), w, story_h, true, [0.0], [-6.0, 6.0])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_fl, -hl), w, story_h, true, [-6.0], [0.0, 6.0])
		else:
			# 2 и 3 этажи: регулярные окна палат
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_fl, hl), w, story_h, true, [], [-6.0, 0.0, 6.0])
			_build_wall_with_doors_and_windows(out, Vector3(0.0, y_fl, -hl), w, story_h, true, [], [-6.0, 0.0, 6.0])

		# Торцевые стены
		_build_wall_with_doors_and_windows(out, Vector3(-hw, y_fl, 0.0), l, story_h, false, [], [0.0])
		_build_wall_with_doors_and_windows(out, Vector3(hw, y_fl, 0.0), l, story_h, false, [], [0.0])

		# Центральный коридор (Z в [-1.4, 1.4]): две продольные перегородки
		# Южная стена коридора (Z = -1.4)
		_build_wall_with_doors_and_windows(out, Vector3(0.0, y_fl, -1.4), w - 5.0, story_h, true, [-5.0, 0.0, 5.0], [])
		# Северная стена коридора (Z = 1.4)
		_build_wall_with_doors_and_windows(out, Vector3(0.0, y_fl, 1.4), w - 5.0, story_h, true, [-5.0, 0.0, 5.0], [])

		# Поперечные перегородки между палатами
		_push_wall_segment(out, Vector3(-5.0, y_fl, (hl + 1.4) * 0.5), 0.0, story_h * 0.5, hl - 1.4, story_h, WALL_THICKNESS, false, COLOR_INTERIOR_WALL)
		_push_wall_segment(out, Vector3(5.0, y_fl, (hl + 1.4) * 0.5), 0.0, story_h * 0.5, hl - 1.4, story_h, WALL_THICKNESS, false, COLOR_INTERIOR_WALL)
		_push_wall_segment(out, Vector3(-5.0, y_fl, -(hl + 1.4) * 0.5), 0.0, story_h * 0.5, hl - 1.4, story_h, WALL_THICKNESS, false, COLOR_INTERIOR_WALL)
		_push_wall_segment(out, Vector3(5.0, y_fl, -(hl + 1.4) * 0.5), 0.0, story_h * 0.5, hl - 1.4, story_h, WALL_THICKNESS, false, COLOR_INTERIOR_WALL)

		# Лестничные марши на западном и восточном крыльях
		if fl < 2:
			_build_stair_flight(out, Vector3(-hw + 2.5, y_fl, 0.0), 1.8, story_h, 1)
			_build_stair_flight(out, Vector3(hw - 2.5, y_fl, 0.0), 1.8, story_h, -1)

			# Плита перекрытия следующего этажа
			var y_slab := y_fl + story_h
			_build_floor_slab_with_stair_opening(out, y_slab, w - 0.2, l - 0.2, Vector3(-hw + 2.5, y_slab, 0.0), Vector3(2.4, 0.28, 4.0), COLOR_SLAB_FLOOR, "floor_%d" % (fl + 2))

	# Выход с 3 этажа на крышу
	var y3 := 0.30 + story_h * 2.0
	_build_stair_flight(out, Vector3(-hw + 2.5, y3, 0.0), 1.8, story_h, 1)

	# ПЛОСКАЯ КРЫША С ВЕРТОЛЁТНОЙ ПЛОЩАДКОЙ И ПАРАПЕТОМ
	var y_roof := 0.30 + story_h * 3.0
	_build_roof_with_penthouse(out, y_roof, w, l, Vector3(-hw + 2.5, y_roof, 0.0), Vector3(2.4, 0.28, 4.2))

	# Маркировка вертолётной площадки на крыше (Helipad)
	# Красный квадрат 8.0м х 8.0м
	_push(out, Vector3(1.0, y_roof + 0.15, 0.0), Vector3(8.0, 0.02, 8.0), COLOR_BRICK_BASE, false, "helipad")
	# Белый крест
	_push(out, Vector3(1.0, y_roof + 0.17, 0.0), Vector3(6.0, 0.02, 1.6), COLOR_CONCRETE_WALL, false, "helipad_mark")
	_push(out, Vector3(1.0, y_roof + 0.17, 0.0), Vector3(1.6, 0.02, 6.0), COLOR_CONCRETE_WALL, false, "helipad_mark")

# ==============================================================================
# 13. 2-ЭТАЖНАЯ ШКОЛА СО СПОРТИВНЫМ ЗАЛОМ (28м х 18м х 8.0м)
# ==============================================================================
static func _build_school(out: Array[Dictionary]) -> void:
	var w := 28.0
	var l := 18.0
	var story_h := 3.60
	var hw := w * 0.5
	var hl := l * 0.5

	# Фундамент и цоколь
	_push(out, Vector3(0.0, 0.15, 0.0), Vector3(w + 1.0, 0.30, l + 1.0), COLOR_BRICK_BASE, true, "building_base")
	_push(out, Vector3(0.0, 0.32, 0.0), Vector3(w - 0.2, 0.04, l - 0.2), COLOR_SLAB_FLOOR, false, "floor_1")

	# 1. СПОРТИВНЫЙ ЗАЛ (Западное крыло: X от -hw до 0.0, двойная высота 7.20м)
	var gym_w := hw
	var gym_c_x := -hw * 0.5

	# Внешние стены спортзала
	_build_wall_with_doors_and_windows(out, Vector3(gym_c_x, 0.30, hl), gym_w, story_h * 2.0, true, [], [-3.5, 3.5])
	_build_wall_with_doors_and_windows(out, Vector3(gym_c_x, 0.30, -hl), gym_w, story_h * 2.0, true, [-3.5], [3.5])
	_build_wall_with_doors_and_windows(out, Vector3(-hw, 0.30, 0.0), l, story_h * 2.0, false, [], [-4.0, 4.0])

	# 2. РАЗДЕЛИТЕЛЬНАЯ СТЕНА МЕЖДУ СПОРТЗАЛОМ И УЧЕБНЫМ КРЫЛОМ (X = 0.0)
	# 1 этаж: широкий двустворчатый проход в спортзал (Z = 0.0, ширина 2.6м)
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.30, 0.0), l, story_h, false, [0.0], [])
	# 2 этаж: смотровой балкон-галерея для зрителей спортзала
	_build_wall_with_doors_and_windows(out, Vector3(0.0, 0.30 + story_h, 0.0), l, story_h, false, [-3.0, 3.0], [])
	# Консольный балкон-подиум в сторону спортзала на 2 этаже (X = -1.2, ширина 12м)
	_push(out, Vector3(-1.2, 0.30 + story_h, 0.0), Vector3(2.4, 0.22, 12.0), COLOR_BALCONY_SLAB, true, "gym_balcony")
	_push(out, Vector3(-2.3, 0.30 + story_h + PARAPET_HEIGHT * 0.5, 0.0), Vector3(0.16, PARAPET_HEIGHT, 12.0), COLOR_PARAPET, true, "gym_railing")

	# 3. УЧЕБНОЕ КРЫЛО (Восточное крыло: X от 0.0 до hw, 2 этажа)
	var acad_w := hw
	var acad_c_x := hw * 0.5

	# Фасад учебного крыла (Z = hl = 9.0): парадный вход школы на 1 этаже
	_build_wall_with_doors_and_windows(out, Vector3(acad_c_x, 0.30, hl), acad_w, story_h, true, [0.0], [-4.0, 4.0])
	_build_wall_with_doors_and_windows(out, Vector3(acad_c_x, 0.30 + story_h, hl), acad_w, story_h, true, [], [-4.0, 0.0, 4.0])

	# Задняя стена учебного крыла (Z = -hl = -9.0)
	_build_wall_with_doors_and_windows(out, Vector3(acad_c_x, 0.30, -hl), acad_w, story_h, true, [], [-4.0, 4.0])
	_build_wall_with_doors_and_windows(out, Vector3(acad_c_x, 0.30 + story_h, -hl), acad_w, story_h, true, [], [-4.0, 4.0])

	# Восточный торец
	_build_wall_with_doors_and_windows(out, Vector3(hw, 0.30, 0.0), l, story_h, false, [], [-3.0, 3.0])
	_build_wall_with_doors_and_windows(out, Vector3(hw, 0.30 + story_h, 0.0), l, story_h, false, [], [-3.0, 3.0])

	# Коридор учебного крыла (Z в [-1.5, 1.5]) и классы
	_build_wall_with_doors_and_windows(out, Vector3(acad_c_x, 0.30, -1.5), acad_w - 2.0, story_h, true, [-2.5, 2.5], [])
	_build_wall_with_doors_and_windows(out, Vector3(acad_c_x, 0.30, 1.5), acad_w - 2.0, story_h, true, [-2.5, 2.5], [])
	_build_wall_with_doors_and_windows(out, Vector3(acad_c_x, 0.30 + story_h, -1.5), acad_w - 2.0, story_h, true, [-2.5, 2.5], [])
	_build_wall_with_doors_and_windows(out, Vector3(acad_c_x, 0.30 + story_h, 1.5), acad_w - 2.0, story_h, true, [-2.5, 2.5], [])

	# Лестничный марш на 2 этаж в учебном крыле
	_build_stair_flight(out, Vector3(acad_c_x + 3.0, 0.30, 0.0), 2.0, story_h, 1)

	# Плита перекрытия 2 этажа учебного крыла
	var y_acad2 := 0.30 + story_h
	_build_floor_slab_with_stair_opening(out, y_acad2, acad_w - 0.2, l - 0.2, Vector3(acad_c_x + 3.0, y_acad2, 0.0), Vector3(2.4, 0.28, 4.0), COLOR_SLAB_FLOOR, "floor_2")

	# ПЛОСКАЯ КРЫША НАД ВСЕЙ ШКОЛОЙ (Y = 0.30 + story_h * 2.0)
	var y_roof := 0.30 + story_h * 2.0
	_push(out, Vector3(0.0, y_roof + 0.14, 0.0), Vector3(w + 0.6, 0.28, l + 0.6), COLOR_ROOF_GRAVEL, true, "roof_slab")
	_build_parapet_ring(out, Vector3(0.0, y_roof + 0.14, 0.0), w + 0.6, l + 0.6, PARAPET_HEIGHT + 0.07)

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

		if cut_start > cur_pos + 0.05:
			var segment_len := cut_start - cur_pos
			var seg_c := cur_pos + segment_len * 0.5
			_push_wall_segment(out, center, seg_c, height * 0.5, segment_len, height, th, axis_x, COLOR_CONCRETE_WALL)

		if cut.type == "door":
			var lintel_h := height - door_h
			if lintel_h > 0.05:
				_push_wall_segment(out, center, cut_c, door_h + lintel_h * 0.5, cut_w, lintel_h, th, axis_x, COLOR_LINTEL)
		elif cut.type == "window":
			_push_wall_segment(out, center, cut_c, sill_h * 0.5, cut_w, sill_h, th, axis_x, COLOR_CONCRETE_WALL)
			_push_wall_segment(out, center, cut_c, sill_h, cut_w + 0.15, 0.06, th + 0.10, axis_x, COLOR_LINTEL, false)
			var lintel_bottom := sill_h + win_h
			var lintel_h := height - lintel_bottom
			if lintel_h > 0.05:
				_push_wall_segment(out, center, cut_c, lintel_bottom + lintel_h * 0.5, cut_w, lintel_h, th, axis_x, COLOR_LINTEL)

		cur_pos = cut_end

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
static func _build_floor_slab_with_stair_opening(out: Array[Dictionary], y: float, w: float, l: float, stair_pos: Vector3, stair_size: Vector3, slab_color: Color = COLOR_SLAB_FLOOR, slab_tag: String = "floor_slab") -> void:
	var th := 0.24
	var hw := w * 0.5
	var hl := l * 0.5
	var shw := stair_size.x * 0.5
	var shl := stair_size.z * 0.5

	var front_len := (stair_pos.z - shl) - (-hl)
	if front_len > 0.2:
		_push(out, Vector3(0.0, y, -hl + front_len * 0.5), Vector3(w, th, front_len), slab_color, true, slab_tag)

	var back_len := hl - (stair_pos.z + shl)
	if back_len > 0.2:
		_push(out, Vector3(0.0, y, hl - back_len * 0.5), Vector3(w, th, back_len), slab_color, true, slab_tag)

	var left_w := (stair_pos.x - shw) - (-hw)
	if left_w > 0.2:
		_push(out, Vector3(-hw + left_w * 0.5, y, stair_pos.z), Vector3(left_w, th, stair_size.z), slab_color, true, slab_tag)

	var right_w := hw - (stair_pos.x + shw)
	if right_w > 0.2:
		_push(out, Vector3(hw - right_w * 0.5, y, stair_pos.z), Vector3(right_w, th, stair_size.z), slab_color, true, slab_tag)

## Лестничный марш со ступенями высотой <= 0.20 м (идеальный подъем без застреваний персонажа).
static func _build_stair_flight(out: Array[Dictionary], center: Vector3, width: float, height: float, dir_z: int) -> void:
	var steps := 16 if height >= 3.0 else 8
	var step_h := height / float(steps)
	var flight_len := 3.52 if height >= 3.0 else 1.84
	var step_len := flight_len / float(steps)
	var z_sign := float(dir_z)

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
		_push(out, Vector3(center.x, center.y - slab_th * 0.5, center.z), Vector3(width, slab_th, depth), COLOR_BALCONY_SLAB, true, "balcony_slab")
		var outer_z := center.z + facing.z * (depth * 0.5 - pt * 0.5)
		_push(out, Vector3(center.x, py, outer_z), Vector3(width, parapet_h, pt), COLOR_PARAPET, true, "balcony_parapet")
		_push(out, Vector3(center.x - width * 0.5 + pt * 0.5, py, center.z), Vector3(pt, parapet_h, depth - pt), COLOR_PARAPET, true, "balcony_parapet")
		_push(out, Vector3(center.x + width * 0.5 - pt * 0.5, py, center.z), Vector3(pt, parapet_h, depth - pt), COLOR_PARAPET, true, "balcony_parapet")
	else:
		_push(out, Vector3(center.x, center.y - slab_th * 0.5, center.z), Vector3(depth, slab_th, width), COLOR_BALCONY_SLAB, true, "balcony_slab")
		var outer_x := center.x + facing.x * (depth * 0.5 - pt * 0.5)
		_push(out, Vector3(outer_x, py, center.z), Vector3(pt, parapet_h, width), COLOR_PARAPET, true, "balcony_parapet")
		_push(out, Vector3(center.x, py, center.z - width * 0.5 + pt * 0.5), Vector3(depth - pt, parapet_h, pt), COLOR_PARAPET, true, "balcony_parapet")
		_push(out, Vector3(center.x, py, center.z + width * 0.5 - pt * 0.5), Vector3(depth - pt, parapet_h, pt), COLOR_PARAPET, true, "balcony_parapet")

## Эксплуатируемая плоская крыша с надстройкой выхода (пентхаус) и периметральным парапетом.
static func _build_roof_with_penthouse(out: Array[Dictionary], y: float, w: float, l: float, stair_pos: Vector3, stair_size: Vector3 = Vector3(2.0, 0.28, 4.0)) -> void:
	var slab_th := 0.28
	# Основная плита крыши с вырезом под лестничный марш выхода на крышу
	_build_floor_slab_with_stair_opening(out, y, w + 0.6, l + 0.6, stair_pos, stair_size, COLOR_ROOF_GRAVEL, "roof_slab")
	_build_parapet_ring(out, Vector3(0.0, y + slab_th * 0.5, 0.0), w + 0.6, l + 0.6, PARAPET_HEIGHT + 0.07)

	var ph_w := 2.80
	var ph_l := 3.40
	var ph_h := 2.40
	var py := y + slab_th * 0.5
	_build_wall_with_doors_and_windows(out, Vector3(stair_pos.x, py, stair_pos.z - ph_l * 0.5), ph_w, ph_h, true, [0.0], [])
	_build_wall_with_doors_and_windows(out, Vector3(stair_pos.x, py, stair_pos.z + ph_l * 0.5), ph_w, ph_h, true, [], [])
	_build_wall_with_doors_and_windows(out, Vector3(stair_pos.x - ph_w * 0.5, py, stair_pos.z), ph_l, ph_h, false, [], [])
	_build_wall_with_doors_and_windows(out, Vector3(stair_pos.x + ph_w * 0.5, py, stair_pos.z), ph_l, ph_h, false, [], [])
	_push(out, Vector3(stair_pos.x, py + ph_h + 0.10, stair_pos.z), Vector3(ph_w + 0.3, 0.20, ph_l + 0.3), COLOR_CONCRETE_WALL, true, "penthouse_roof")

## Защитное кольцо парапета по периметру прямоугольника.
## Поддерживает опциональный разрыв (gap) на одной из сторон для удобного выхода с наружных лестниц.
static func _build_parapet_ring(out: Array[Dictionary], base: Vector3, w: float, l: float, height: float, gap_side: String = "", gap_c: float = 0.0, gap_w: float = 0.0) -> void:
	var pt := 0.20
	var py := base.y + height * 0.5
	var hw := w * 0.5
	var hl := l * 0.5
	_push(out, Vector3(base.x, py, base.z - hl + pt * 0.5), Vector3(w, height, pt), COLOR_PARAPET, true, "roof_parapet")
	_push(out, Vector3(base.x, py, base.z + hl - pt * 0.5), Vector3(w, height, pt), COLOR_PARAPET, true, "roof_parapet")

	if gap_side == "west" and gap_w > 0.1:
		var z_start := -hl + pt
		var z_end := hl - pt
		var cut_start := gap_c - gap_w * 0.5
		var cut_end := gap_c + gap_w * 0.5
		if cut_start > z_start + 0.1:
			var seg_len := cut_start - z_start
			_push(out, Vector3(base.x - hw + pt * 0.5, py, z_start + seg_len * 0.5), Vector3(pt, height, seg_len), COLOR_PARAPET, true, "roof_parapet")
		if z_end > cut_end + 0.1:
			var seg_len := z_end - cut_end
			_push(out, Vector3(base.x - hw + pt * 0.5, py, cut_end + seg_len * 0.5), Vector3(pt, height, seg_len), COLOR_PARAPET, true, "roof_parapet")
	else:
		_push(out, Vector3(base.x - hw + pt * 0.5, py, base.z), Vector3(pt, height, l - pt * 2.0), COLOR_PARAPET, true, "roof_parapet")

	_push(out, Vector3(base.x + hw - pt * 0.5, py, base.z), Vector3(pt, height, l - pt * 2.0), COLOR_PARAPET, true, "roof_parapet")

static func _push(arr: Array[Dictionary], pos: Vector3, size: Vector3, color: Color, coll: bool, tag: String, cast_shadow: Variant = null) -> void:
	var shadow_val: bool = coll
	if cast_shadow != null:
		shadow_val = bool(cast_shadow)
	else:
		# Оптимизация теней для мобильных GPU (GL Compatibility):
		if tag in ["stair_step", "window_sill_board", "floor", "floor_1", "building_base", "rubble", "catwalk", "catwalk_bridge"]:
			shadow_val = false
	arr.append({
		"pos": pos,
		"size": size,
		"color": color,
		"solid": coll,
		"kind": tag,
		"cast_shadow": shadow_val
	})
