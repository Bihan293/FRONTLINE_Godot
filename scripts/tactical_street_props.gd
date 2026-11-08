extends RefCounted
class_name FRONTLINETacticalStreetProps

## Пак уличных тактических ассетов и укрытий (Street Props & Battlefield Cover Pack).
## Процедурная low-poly 3D-геометрия для городских боев в стиле Dummy War / Bodycam.
##
## 27 тактических пропсов в 6 категориях:
## 1. Сожженная и разбитая техника:
##    - burnt_car_sedan: остов седана с капотом, крышей и колесными дисками
##    - burnt_car_van: сгоревший фургон / инкассатор с открытыми задними дверями
##    - burnt_car_truck_cab: обгоревшая кабина грузовика с решеткой и крыльями
## 2. Военная техника и обломки:
##    - military_truck_wreck: армейский грузовик ЗИС-5 / Студебеккер с кузовом для запрыгивания
##    - military_jeep_willys: разведывательный внедорожник с капотом, крыльями и запаской
##    - military_armored_car: бронеавтомобиль БА-64 с гранёным корпусом и башней
## 3. Песчаные баррикады и фортификации:
##    - sandbag_wall_straight: прямая баррикада 0.95м (идеальна для упора оружия и паркура)
##    - sandbag_wall_corner: Г-образная угловая позиция для обороны перекрёстков
##    - sandbag_firing_nest: стрелковое пулемётное гнездо с амбразурной щелью
##    - czech_hedgehog: противотанковый стальной ёж из трёх двутавров
##    - concrete_jersey_barrier: бетонный дорожный отбойник «Джерси»
## 4. Освещение и столбы:
##    - street_lantern_single: чугунный городской фонарь высотой 4.8м с кронштейном
##    - street_lantern_double: двухрожковый проспектный фонарь 5.2м
##    - wooden_utility_pole: деревянный телеграфный столб 7.2м с траверсой и изоляторами
## 5. Дорожные знаки и заграждения:
##    - road_sign_stop: восьмигранный красный знак STOP на стойке
##    - road_sign_yield: треугольный знак «Уступи дорогу»
##    - road_sign_direction: указатель направлений на двух стойках
##    - road_barrier_wooden: деревянный красно-белый шлагбаум/козлы контрольно-пропускного пункта
## 6. Мусорки, бочки, ящики, укрытия:
##    - metal_dumpster: массивный уличный мусорный контейнер с крышками
##    - street_trash_can: чугунная парковая урна с козырьком
##    - oil_barrel_single: 200-литровая стальная бочка с ребрами жесткости
##    - oil_barrel_cluster: группа из 4 бочек (стоячие и поваленная) для кругового укрытия
##    - ammo_crate_stack: штабель армейских ящиков с боеприпасами
##    - fire_hydrant: пожарный гидрант со штуцерами
##    - tire_stack: баррикада из 4 грузовых покрышек
##    - bus_stop_shelter: павильон автобусной остановки со скамьей и навесом
##    - concrete_pipe_segment: железобетонная водопропускная труба, проходимая ползком/пригнувшись

# Палитра материалов
const COLOR_BURNT_DARK := Color(0.15, 0.14, 0.14)
const COLOR_BURNT_RUST := Color(0.38, 0.22, 0.16)
const COLOR_RUST_LIGHT := Color(0.48, 0.26, 0.18)
const COLOR_MIL_OLIVE := Color(0.24, 0.28, 0.18)
const COLOR_MIL_DARK := Color(0.18, 0.20, 0.16)
const COLOR_SANDBAG := Color(0.58, 0.52, 0.36)
const COLOR_SANDBAG_DARK := Color(0.48, 0.42, 0.28)
const COLOR_CONCRETE := Color(0.56, 0.55, 0.52)
const COLOR_CONCRETE_DARK := Color(0.42, 0.41, 0.39)
const COLOR_STEEL := Color(0.32, 0.34, 0.36)
const COLOR_DARK_STEEL := Color(0.18, 0.19, 0.20)
const COLOR_WOOD := Color(0.38, 0.28, 0.18)
const COLOR_WOOD_DARK := Color(0.28, 0.20, 0.14)
const COLOR_SIGN_RED := Color(0.78, 0.14, 0.12)
const COLOR_SIGN_YELLOW := Color(0.88, 0.76, 0.18)
const COLOR_SIGN_WHITE := Color(0.86, 0.86, 0.86)
const COLOR_SIGN_BLUE := Color(0.14, 0.32, 0.65)
const COLOR_BARREL_BLUE := Color(0.18, 0.28, 0.45)
const COLOR_DUMPSTER_GREEN := Color(0.20, 0.32, 0.22)
const COLOR_RUBBER := Color(0.11, 0.11, 0.12)
const COLOR_LANTERN_GLOW := Color(0.96, 0.90, 0.65)

static func get_available_types() -> Array[String]:
	return [
		# 1. Сожженная техника
		"burnt_car_sedan",
		"burnt_car_van",
		"burnt_car_truck_cab",
		# 2. Военная техника
		"military_truck_wreck",
		"military_jeep_willys",
		"military_armored_car",
		# 3. Песчаные баррикады и фортификации
		"sandbag_wall_straight",
		"sandbag_wall_corner",
		"sandbag_firing_nest",
		"czech_hedgehog",
		"concrete_jersey_barrier",
		# 4. Освещение и столбы
		"street_lantern_single",
		"street_lantern_double",
		"wooden_utility_pole",
		# 5. Дорожные знаки и барьеры
		"road_sign_stop",
		"road_sign_yield",
		"road_sign_direction",
		"road_barrier_wooden",
		# 6. Мусорки, бочки, ящики, городские объекты
		"metal_dumpster",
		"street_trash_can",
		"oil_barrel_single",
		"oil_barrel_cluster",
		"ammo_crate_stack",
		"fire_hydrant",
		"tire_stack",
		"bus_stop_shelter",
		"concrete_pipe_segment"
	]

static func get_prop_info(type_name: String) -> Dictionary:
	match type_name:
		"burnt_car_sedan":
			return {
				"name": "Сожженный легковой седан",
				"category": "vehicles",
				"size": Vector3(4.4, 1.40, 1.8),
				"cover_height": 1.40,
				"can_vault": true,
				"description": "Сгоревший остов легкового автомобиля. Капот на высоте 0.85м пригоден для паркура/перемаха."
			}
		"burnt_car_van":
			return {
				"name": "Сгоревший фургон",
				"category": "vehicles",
				"size": Vector3(4.8, 2.05, 1.9),
				"cover_height": 2.05,
				"can_vault": false,
				"description": "Сгоревший грузовой фургон с распахнутыми дверями. Обеспечивает полное укрытие в полный рост."
			}
		"burnt_car_truck_cab":
			return {
				"name": "Обгоревшая кабина грузовика",
				"category": "vehicles",
				"size": Vector3(3.8, 2.25, 2.2),
				"cover_height": 2.25,
				"can_vault": false,
				"description": "Кабина грузовика без кузова с двигателем и крыльями. Отличное массивное укрытие."
			}
		"military_truck_wreck":
			return {
				"name": "Армейский грузовик (обломок)",
				"category": "vehicles",
				"size": Vector3(6.5, 2.45, 2.3),
				"cover_height": 2.45,
				"can_vault": false,
				"description": "Военный грузовик ЗИС/Студебеккер. Высокое укрытие для блокирования улиц."
			}
		"military_jeep_willys":
			return {
				"name": "Военный джип Виллис",
				"category": "vehicles",
				"size": Vector3(3.4, 1.45, 1.5),
				"cover_height": 1.45,
				"can_vault": true,
				"description": "Разведывательный армейский джип. Капот 0.85м позволяет перемахивать на бегу."
			}
		"military_armored_car":
			return {
				"name": "Бронеавтомобиль БА-64",
				"category": "vehicles",
				"size": Vector3(4.8, 2.20, 2.0),
				"cover_height": 2.20,
				"can_vault": false,
				"description": "Повреждённый броневик с наклонными стальными бронелистами и открытой башней."
			}
		"sandbag_wall_straight":
			return {
				"name": "Прямая песчаная баррикада",
				"category": "fortifications",
				"size": Vector3(3.0, 0.95, 0.8),
				"cover_height": 0.95,
				"can_vault": true,
				"description": "Песчаный бруствер высотой 0.95м. Идеален для стрельбы с упора и быстрого паркура."
			}
		"sandbag_wall_corner":
			return {
				"name": "Угловая песчаная баррикада",
				"category": "fortifications",
				"size": Vector3(2.4, 0.95, 2.4),
				"cover_height": 0.95,
				"can_vault": true,
				"description": "Г-образное укрепление из мешков с песком для обороны перекрёстков."
			}
		"sandbag_firing_nest":
			return {
				"name": "Пулемётное гнездо из мешков",
				"category": "fortifications",
				"size": Vector3(3.2, 1.25, 2.4),
				"cover_height": 1.25,
				"can_vault": false,
				"description": "Оборудованное пулеметное гнездо с защитной бойницей и боковыми брустверами."
			}
		"czech_hedgehog":
			return {
				"name": "Противотанковый ёж",
				"category": "fortifications",
				"size": Vector3(1.8, 1.40, 1.8),
				"cover_height": 1.40,
				"can_vault": true,
				"description": "Сварной стальной ёж из трёх двутавров. Задерживает технику, позволяет стрелять сквозь балки."
			}
		"concrete_jersey_barrier":
			return {
				"name": "Бетонный блок Джерси",
				"category": "fortifications",
				"size": Vector3(2.5, 0.95, 0.65),
				"cover_height": 0.95,
				"can_vault": true,
				"description": "Монолитный бетонный разделитель дорог с наклонным основанием. Высота 0.95м."
			}
		"street_lantern_single":
			return {
				"name": "Уличный фонарный столб (одиночный)",
				"category": "lighting",
				"size": Vector3(1.2, 4.80, 0.6),
				"cover_height": 4.80,
				"can_vault": false,
				"description": "Чугунный фонарный столб высотой 4.8м с декоративным кронштейном."
			}
		"street_lantern_double":
			return {
				"name": "Уличный фонарный столб (двойной)",
				"category": "lighting",
				"size": Vector3(1.8, 5.20, 0.6),
				"cover_height": 5.20,
				"can_vault": false,
				"description": "Проспектный фонарный столб с двумя симметричными рожками высотой 5.2м."
			}
		"wooden_utility_pole":
			return {
				"name": "Деревянный телеграфный столб",
				"category": "lighting",
				"size": Vector3(1.6, 7.20, 0.4),
				"cover_height": 7.20,
				"can_vault": false,
				"description": "Деревянный столб связи высотой 7.2м с поперечной траверсой и изоляторами."
			}
		"road_sign_stop":
			return {
				"name": "Дорожный знак STOP",
				"category": "signs",
				"size": Vector3(0.7, 2.40, 0.15),
				"cover_height": 2.40,
				"can_vault": false,
				"description": "Восьмигранный знак STOP на стальной трубчатой стойке."
			}
		"road_sign_yield":
			return {
				"name": "Дорожный знак «Уступи дорогу»",
				"category": "signs",
				"size": Vector3(0.7, 2.40, 0.15),
				"cover_height": 2.40,
				"can_vault": false,
				"description": "Треугольный дорожный знак приоритета на стойке."
			}
		"road_sign_direction":
			return {
				"name": "Дорожный указатель направлений",
				"category": "signs",
				"size": Vector3(1.4, 2.60, 0.2),
				"cover_height": 2.60,
				"can_vault": false,
				"description": "Прямоугольный синий указатель населенных пунктов на двух опорах."
			}
		"road_barrier_wooden":
			return {
				"name": "Деревянный дорожный барьер КПП",
				"category": "signs",
				"size": Vector3(2.4, 1.00, 0.6),
				"cover_height": 1.00,
				"can_vault": true,
				"description": "Контрольно-пропускное заграждение с красно-белыми диагональными полосами."
			}
		"metal_dumpster":
			return {
				"name": "Мусорный контейнер",
				"category": "urban_props",
				"size": Vector3(2.2, 1.35, 1.4),
				"cover_height": 1.35,
				"can_vault": true,
				"description": "Массивный стальной мусорный бак. Отличное пуленепробиваемое укрытие на улице."
			}
		"street_trash_can":
			return {
				"name": "Уличная урна",
				"category": "urban_props",
				"size": Vector3(0.6, 0.95, 0.6),
				"cover_height": 0.95,
				"can_vault": false,
				"description": "Металлическая городская урна с навесом на стойке."
			}
		"oil_barrel_single":
			return {
				"name": "Стальная бочка 200л",
				"category": "urban_props",
				"size": Vector3(0.65, 0.95, 0.65),
				"cover_height": 0.95,
				"can_vault": true,
				"description": "Стальная бочка для горюче-смазочных материалов с рёбрами жёсткости."
			}
		"oil_barrel_cluster":
			return {
				"name": "Группа бочек (4 шт)",
				"category": "urban_props",
				"size": Vector3(1.8, 1.05, 1.5),
				"cover_height": 1.05,
				"can_vault": true,
				"description": "Склад из 4 бочек (3 стоячие, 1 на боку). Укрытие для стрельбы с колена."
			}
		"ammo_crate_stack":
			return {
				"name": "Штабель ящиков с патронами",
				"category": "urban_props",
				"size": Vector3(1.6, 1.10, 1.2),
				"cover_height": 1.10,
				"can_vault": true,
				"description": "Штабель из трёх деревянных военных ящиков со стальными уголками и ручками."
			}
		"fire_hydrant":
			return {
				"name": "Пожарный гидрант",
				"category": "urban_props",
				"size": Vector3(0.5, 0.85, 0.5),
				"cover_height": 0.85,
				"can_vault": false,
				"description": "Чугунный красный гидрант с соединительными патрубками."
			}
		"tire_stack":
			return {
				"name": "Баррикада из покрышек",
				"category": "urban_props",
				"size": Vector3(1.2, 1.10, 1.2),
				"cover_height": 1.10,
				"can_vault": true,
				"description": "Стопка из четырёх резиновых грузовых покрышек, заполненных грунтом."
			}
		"bus_stop_shelter":
			return {
				"name": "Автобусная остановка",
				"category": "urban_props",
				"size": Vector3(3.8, 2.60, 1.8),
				"cover_height": 2.60,
				"can_vault": false,
				"description": "Уличный павильон остановки с металлической скамьёй, защитными стенками и козырьком."
			}
		"concrete_pipe_segment":
			return {
				"name": "Бетонная водопропускная труба",
				"category": "urban_props",
				"size": Vector3(2.4, 2.00, 2.0),
				"cover_height": 2.00,
				"can_vault": false,
				"description": "Большая дренажная бетонная труба. Позволяет передвигаться внутри ползком/на корточках."
			}
		_:
			return {}

## Возвращает массив словарей-боксов для добавления в layout карт.
## Поддерживает смещение origin и поворот rot_deg вокруг оси Y.
static func get_prop_boxes(type_name: String, origin: Vector3 = Vector3.ZERO, rot_deg: float = 0.0) -> Array[Dictionary]:
	var local_boxes: Array[Dictionary] = []
	match type_name:
		"burnt_car_sedan":
			_build_burnt_car_sedan(local_boxes)
		"burnt_car_van":
			_build_burnt_car_van(local_boxes)
		"burnt_car_truck_cab":
			_build_burnt_car_truck_cab(local_boxes)
		"military_truck_wreck":
			_build_military_truck_wreck(local_boxes)
		"military_jeep_willys":
			_build_military_jeep_willys(local_boxes)
		"military_armored_car":
			_build_military_armored_car(local_boxes)
		"sandbag_wall_straight":
			_build_sandbag_wall_straight(local_boxes)
		"sandbag_wall_corner":
			_build_sandbag_wall_corner(local_boxes)
		"sandbag_firing_nest":
			_build_sandbag_firing_nest(local_boxes)
		"czech_hedgehog":
			_build_czech_hedgehog(local_boxes)
		"concrete_jersey_barrier":
			_build_concrete_jersey_barrier(local_boxes)
		"street_lantern_single":
			_build_street_lantern_single(local_boxes)
		"street_lantern_double":
			_build_street_lantern_double(local_boxes)
		"wooden_utility_pole":
			_build_wooden_utility_pole(local_boxes)
		"road_sign_stop":
			_build_road_sign_stop(local_boxes)
		"road_sign_yield":
			_build_road_sign_yield(local_boxes)
		"road_sign_direction":
			_build_road_sign_direction(local_boxes)
		"road_barrier_wooden":
			_build_road_barrier_wooden(local_boxes)
		"metal_dumpster":
			_build_metal_dumpster(local_boxes)
		"street_trash_can":
			_build_street_trash_can(local_boxes)
		"oil_barrel_single":
			_build_oil_barrel_single(local_boxes)
		"oil_barrel_cluster":
			_build_oil_barrel_cluster(local_boxes)
		"ammo_crate_stack":
			_build_ammo_crate_stack(local_boxes)
		"fire_hydrant":
			_build_fire_hydrant(local_boxes)
		"tire_stack":
			_build_tire_stack(local_boxes)
		"bus_stop_shelter":
			_build_bus_stop_shelter(local_boxes)
		"concrete_pipe_segment":
			_build_concrete_pipe_segment(local_boxes)
		_:
			_build_sandbag_wall_straight(local_boxes)

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
			if is_equal_approx(absf(sin_a), 1.0):
				ws = Vector3(ls.z, ls.y, ls.x)
		out.append({
			"pos": wp,
			"size": ws,
			"color": b.color,
			"solid": b.get("solid", true),
			"kind": b.get("kind", "street_prop"),
			"cast_shadow": b.get("cast_shadow", true)
		})
	return out

## Создаёт отдельную ноду Node3D со StaticBody3D (PropCollision) и мешами.
static func create_prop_node(type_name: String, rot_deg: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = type_name.capitalize().replace(" ", "")

	var boxes := get_prop_boxes(type_name, Vector3.ZERO, rot_deg)
	var body := StaticBody3D.new()
	body.name = "PropCollision"
	root.add_child(body)

	# Кэшируем StandardMaterial3D по цвету палитры для оптимизации GPU draw calls
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
			mat.roughness = 0.82
			mat_cache[color] = mat
		mesh_instance.material_override = mat
		mesh_instance.position = pos
		if not bool(b.get("cast_shadow", true)):
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mesh_instance)

	return root

# ==============================================================================
# 1. СОЖЖЕННАЯ И РАЗБИТАЯ ТЕХНИКА
# ==============================================================================

static func _build_burnt_car_sedan(out: Array[Dictionary]) -> void:
	# Шасси и рама
	_push(out, Vector3(0.0, 0.20, 0.0), Vector3(1.70, 0.16, 4.20), COLOR_BURNT_DARK, true, "wreck_chassis")
	# Моторный отсек и обгоревший капот (высота 0.85м под паркур)
	_push(out, Vector3(0.0, 0.55, -1.35), Vector3(1.60, 0.54, 1.40), COLOR_BURNT_RUST, true, "wreck_hood")
	_push(out, Vector3(0.0, 0.52, -0.65), Vector3(1.40, 0.35, 0.60), COLOR_BURNT_DARK, true, "wreck_engine", false)
	# Салон / ванна кузова
	_push(out, Vector3(-0.75, 0.68, 0.25), Vector3(0.12, 0.70, 1.90), COLOR_BURNT_RUST, true, "wreck_door_l")
	_push(out, Vector3(0.75, 0.68, 0.25), Vector3(0.12, 0.70, 1.90), COLOR_BURNT_RUST, true, "wreck_door_r")
	# Крыша и стойки (высота 1.38м)
	_push(out, Vector3(0.0, 1.34, 0.15), Vector3(1.45, 0.08, 1.55), COLOR_BURNT_DARK, true, "wreck_roof")
	_push(out, Vector3(-0.68, 1.05, -0.55), Vector3(0.08, 0.50, 0.08), COLOR_BURNT_DARK, true, "wreck_pillar", false)
	_push(out, Vector3(0.68, 1.05, -0.55), Vector3(0.08, 0.50, 0.08), COLOR_BURNT_DARK, true, "wreck_pillar", false)
	_push(out, Vector3(-0.68, 1.05, 0.85), Vector3(0.08, 0.50, 0.08), COLOR_BURNT_DARK, true, "wreck_pillar", false)
	_push(out, Vector3(0.68, 1.05, 0.85), Vector3(0.08, 0.50, 0.08), COLOR_BURNT_DARK, true, "wreck_pillar", false)
	# Багажник
	_push(out, Vector3(0.0, 0.55, 1.55), Vector3(1.55, 0.52, 1.00), COLOR_BURNT_RUST, true, "wreck_trunk")
	# Сгоревшие колесные диски
	for z in [-1.25, 1.35]:
		_push(out, Vector3(-0.84, 0.28, z), Vector3(0.20, 0.55, 0.55), COLOR_DARK_STEEL, true, "wheel_rim", false)
		_push(out, Vector3(0.84, 0.28, z), Vector3(0.20, 0.55, 0.55), COLOR_DARK_STEEL, true, "wheel_rim", false)

static func _build_burnt_car_van(out: Array[Dictionary]) -> void:
	# Шасси
	_push(out, Vector3(0.0, 0.24, 0.0), Vector3(1.85, 0.20, 4.60), COLOR_BURNT_DARK, true, "wreck_chassis")
	# Капот
	_push(out, Vector3(0.0, 0.65, -1.60), Vector3(1.70, 0.60, 1.10), COLOR_BURNT_RUST, true, "wreck_hood")
	# Кабина водителя
	_push(out, Vector3(0.0, 1.30, -0.75), Vector3(1.80, 0.90, 1.10), COLOR_BURNT_DARK, true, "wreck_cab")
	# Грузовой закрытый кузов (высота 2.05м)
	_push(out, Vector3(-0.85, 1.15, 0.85), Vector3(0.14, 1.60, 2.70), COLOR_BURNT_RUST, true, "van_wall_l")
	_push(out, Vector3(0.85, 1.15, 0.85), Vector3(0.14, 1.60, 2.70), COLOR_BURNT_RUST, true, "van_wall_r")
	_push(out, Vector3(0.0, 1.95, 0.85), Vector3(1.80, 0.12, 2.70), COLOR_BURNT_DARK, true, "van_roof")
	# Распахнутые задние двери
	_push(out, Vector3(-0.95, 1.15, 2.45), Vector3(0.08, 1.50, 0.65), COLOR_BURNT_RUST, true, "van_door_open")
	_push(out, Vector3(0.95, 1.15, 2.45), Vector3(0.08, 1.50, 0.65), COLOR_BURNT_RUST, true, "van_door_open")
	# Колёса
	for z in [-1.35, 1.45]:
		_push(out, Vector3(-0.90, 0.32, z), Vector3(0.22, 0.64, 0.64), COLOR_DARK_STEEL, true, "wheel_rim", false)
		_push(out, Vector3(0.90, 0.32, z), Vector3(0.22, 0.64, 0.64), COLOR_DARK_STEEL, true, "wheel_rim", false)

static func _build_burnt_car_truck_cab(out: Array[Dictionary]) -> void:
	# Рама
	_push(out, Vector3(0.0, 0.30, 0.0), Vector3(1.90, 0.24, 3.60), COLOR_BURNT_DARK, true, "wreck_chassis")
	# Массивный двигатель и капот
	_push(out, Vector3(0.0, 0.85, -0.90), Vector3(1.30, 0.75, 1.60), COLOR_BURNT_RUST, true, "wreck_hood")
	_push(out, Vector3(0.0, 0.80, -1.72), Vector3(1.10, 0.65, 0.12), COLOR_BURNT_DARK, true, "radiator_grill", false)
	# Крылья
	_push(out, Vector3(-0.85, 0.70, -0.90), Vector3(0.40, 0.30, 1.50), COLOR_BURNT_RUST, true, "fender_l")
	_push(out, Vector3(0.85, 0.70, -0.90), Vector3(0.40, 0.30, 1.50), COLOR_BURNT_RUST, true, "fender_r")
	# Кабина (высота 2.25м)
	_push(out, Vector3(0.0, 1.45, 0.60), Vector3(2.00, 1.35, 1.50), COLOR_BURNT_RUST, true, "truck_cab")
	# Передние колеса
	_push(out, Vector3(-0.95, 0.42, -0.90), Vector3(0.26, 0.84, 0.84), COLOR_RUBBER, true, "truck_wheel")
	_push(out, Vector3(0.95, 0.42, -0.90), Vector3(0.26, 0.84, 0.84), COLOR_RUBBER, true, "truck_wheel")

# ==============================================================================
# 2. ВОЕННАЯ ТЕХНИКА И ОБЛОМКИ
# ==============================================================================

static func _build_military_truck_wreck(out: Array[Dictionary]) -> void:
	# Длинное армейское шасси
	_push(out, Vector3(0.0, 0.38, 0.0), Vector3(2.10, 0.26, 6.20), COLOR_MIL_DARK, true, "truck_frame")
	# Капот и решетка
	_push(out, Vector3(0.0, 0.95, -2.10), Vector3(1.30, 0.80, 1.60), COLOR_MIL_OLIVE, true, "truck_hood")
	_push(out, Vector3(0.0, 0.90, -2.92), Vector3(1.15, 0.70, 0.10), COLOR_DARK_STEEL, true, "truck_grill", false)
	# Кабина
	_push(out, Vector3(0.0, 1.55, -0.70), Vector3(2.10, 1.30, 1.40), COLOR_MIL_OLIVE, true, "truck_cab")
	_push(out, Vector3(0.0, 2.25, -0.70), Vector3(2.00, 0.15, 1.35), COLOR_MIL_DARK, true, "truck_roof")
	# Деревянный грузовой кузов с бортами (высота борта 1.15м — в кузов можно запрыгнуть!)
	_push(out, Vector3(0.0, 0.90, 1.50), Vector3(2.20, 0.14, 3.20), COLOR_WOOD, true, "bed_floor")
	_push(out, Vector3(-1.08, 1.30, 1.50), Vector3(0.08, 0.70, 3.20), COLOR_WOOD_DARK, true, "bed_side_l")
	_push(out, Vector3(1.08, 1.30, 1.50), Vector3(0.08, 0.70, 3.20), COLOR_WOOD_DARK, true, "bed_side_r")
	_push(out, Vector3(0.0, 1.30, 3.08), Vector3(2.20, 0.70, 0.08), COLOR_WOOD_DARK, true, "bed_tailgate")
	# 6 колес
	for z in [-2.10, 1.10, 2.20]:
		_push(out, Vector3(-1.05, 0.45, z), Vector3(0.28, 0.90, 0.90), COLOR_RUBBER, true, "mil_wheel")
		_push(out, Vector3(1.05, 0.45, z), Vector3(0.28, 0.90, 0.90), COLOR_RUBBER, true, "mil_wheel")

static func _build_military_jeep_willys(out: Array[Dictionary]) -> void:
	# Рама
	_push(out, Vector3(0.0, 0.28, 0.0), Vector3(1.30, 0.16, 3.20), COLOR_MIL_DARK, true, "jeep_frame")
	# Капот (0.85м высота — идеальный паркур)
	_push(out, Vector3(0.0, 0.65, -0.90), Vector3(1.00, 0.45, 1.25), COLOR_MIL_OLIVE, true, "jeep_hood")
	_push(out, Vector3(0.0, 0.62, -1.54), Vector3(0.90, 0.40, 0.08), COLOR_DARK_STEEL, true, "jeep_grill", false)
	# Крылья
	_push(out, Vector3(-0.62, 0.58, -0.90), Vector3(0.26, 0.08, 1.20), COLOR_MIL_OLIVE, true, "jeep_fender_l")
	_push(out, Vector3(0.62, 0.58, -0.90), Vector3(0.26, 0.08, 1.20), COLOR_MIL_OLIVE, true, "jeep_fender_r")
	# Кузов и сиденья
	_push(out, Vector3(0.0, 0.60, 0.45), Vector3(1.40, 0.45, 1.45), COLOR_MIL_OLIVE, true, "jeep_tub")
	_push(out, Vector3(0.0, 1.05, -0.22), Vector3(1.20, 0.45, 0.06), COLOR_DARK_STEEL, true, "jeep_windshield", false)
	# Запасное колесо сзади
	_push(out, Vector3(0.0, 0.65, 1.25), Vector3(0.22, 0.65, 0.65), COLOR_RUBBER, true, "jeep_spare")
	# 4 колеса
	for z in [-0.95, 0.95]:
		_push(out, Vector3(-0.68, 0.34, z), Vector3(0.22, 0.68, 0.68), COLOR_RUBBER, true, "jeep_wheel")
		_push(out, Vector3(0.68, 0.34, z), Vector3(0.22, 0.68, 0.68), COLOR_RUBBER, true, "jeep_wheel")

static func _build_military_armored_car(out: Array[Dictionary]) -> void:
	# Нижнее бронешасси
	_push(out, Vector3(0.0, 0.45, 0.0), Vector3(1.80, 0.35, 4.50), COLOR_MIL_DARK, true, "armor_hull_bottom")
	# Склонные бронелисты корпуса
	_push(out, Vector3(0.0, 0.95, -1.20), Vector3(1.60, 0.65, 1.60), COLOR_MIL_OLIVE, true, "armor_glacis")
	_push(out, Vector3(0.0, 1.15, 0.45), Vector3(1.75, 0.85, 1.90), COLOR_MIL_OLIVE, true, "armor_mid_hull")
	# Открытая восьмигранная бронебашня (высота 2.20м)
	_push(out, Vector3(0.0, 1.85, 0.30), Vector3(1.20, 0.60, 1.20), COLOR_MIL_DARK, true, "armor_turret")
	_push(out, Vector3(0.0, 1.90, -0.70), Vector3(0.10, 0.10, 1.10), COLOR_DARK_STEEL, true, "armor_cannon", false)
	# 4 бронеколеса
	for z in [-1.30, 1.30]:
		_push(out, Vector3(-0.95, 0.45, z), Vector3(0.26, 0.90, 0.90), COLOR_RUBBER, true, "armor_wheel")
		_push(out, Vector3(0.95, 0.45, z), Vector3(0.26, 0.90, 0.90), COLOR_RUBBER, true, "armor_wheel")

# ==============================================================================
# 3. ПЕСЧАНЫЕ БАРРИКАДЫ И ФОРТИФИКАЦИИ
# ==============================================================================

static func _build_sandbag_wall_straight(out: Array[Dictionary]) -> void:
	# Длина 3.0м, высота 0.95м, глубина 0.80м (3 яруса мешков)
	_push(out, Vector3(0.0, 0.18, 0.0), Vector3(3.00, 0.36, 0.80), COLOR_SANDBAG, true, "sandbag_tier_1")
	_push(out, Vector3(0.0, 0.52, 0.0), Vector3(2.90, 0.32, 0.70), COLOR_SANDBAG_DARK, true, "sandbag_tier_2")
	_push(out, Vector3(0.0, 0.82, 0.0), Vector3(2.80, 0.28, 0.60), COLOR_SANDBAG, true, "sandbag_tier_3")

static func _build_sandbag_wall_corner(out: Array[Dictionary]) -> void:
	# Г-образная баррикада 2.4м х 2.4м, высота 0.95м
	# Сектор 1 (вдоль оси X)
	_push(out, Vector3(0.0, 0.47, -0.80), Vector3(2.40, 0.95, 0.70), COLOR_SANDBAG, true, "sandbag_corner_x")
	# Сектор 2 (вдоль оси Z)
	_push(out, Vector3(0.80, 0.47, 0.35), Vector3(0.70, 0.95, 1.60), COLOR_SANDBAG_DARK, true, "sandbag_corner_z")

static func _build_sandbag_firing_nest(out: Array[Dictionary]) -> void:
	# П-образное укрепление с амбразурой
	# Фронтальный подоконник (0.90м)
	_push(out, Vector3(0.0, 0.45, -0.90), Vector3(1.40, 0.90, 0.70), COLOR_SANDBAG, true, "sandbag_front_sill")
	# Левый щечный бруствер (высота 1.25м)
	_push(out, Vector3(-1.15, 0.62, -0.90), Vector3(0.90, 1.25, 0.70), COLOR_SANDBAG_DARK, true, "sandbag_cheek_l")
	# Правый щечный бруствер (высота 1.25м)
	_push(out, Vector3(1.15, 0.62, -0.90), Vector3(0.90, 1.25, 0.70), COLOR_SANDBAG_DARK, true, "sandbag_cheek_r")
	# Боковые фланговые стенки (высота 1.05м)
	_push(out, Vector3(-1.25, 0.52, 0.15), Vector3(0.70, 1.05, 1.40), COLOR_SANDBAG, true, "sandbag_flank_l")
	_push(out, Vector3(1.25, 0.52, 0.15), Vector3(0.70, 1.05, 1.40), COLOR_SANDBAG, true, "sandbag_flank_r")

static func _build_czech_hedgehog(out: Array[Dictionary]) -> void:
	# Три скрещенных стальных двутавровых балки (длина 1.8м)
	_push(out, Vector3(0.0, 0.60, 0.0), Vector3(0.18, 1.20, 1.80), COLOR_DARK_STEEL, true, "hedgehog_beam_a")
	_push(out, Vector3(0.0, 0.60, 0.0), Vector3(1.80, 1.20, 0.18), COLOR_DARK_STEEL, true, "hedgehog_beam_b")
	_push(out, Vector3(0.0, 0.60, 0.0), Vector3(1.25, 1.40, 1.25), COLOR_STEEL, true, "hedgehog_beam_c")
	_push(out, Vector3(0.0, 0.60, 0.0), Vector3(0.35, 0.35, 0.35), COLOR_RUST_LIGHT, true, "hedgehog_plate", false)

static func _build_concrete_jersey_barrier(out: Array[Dictionary]) -> void:
	# Бетонный блок Джерси: широкая база 0.65м, высота 0.95м, длина 2.5м
	_push(out, Vector3(0.0, 0.15, 0.0), Vector3(2.50, 0.30, 0.65), COLOR_CONCRETE_DARK, true, "jersey_base")
	_push(out, Vector3(0.0, 0.55, 0.0), Vector3(2.50, 0.50, 0.40), COLOR_CONCRETE, true, "jersey_mid")
	_push(out, Vector3(0.0, 0.88, 0.0), Vector3(2.50, 0.16, 0.22), COLOR_CONCRETE, true, "jersey_top")

# ==============================================================================
# 4. ОСВЕЩЕНИЕ И СТОЛБЫ
# ==============================================================================

static func _build_street_lantern_single(out: Array[Dictionary]) -> void:
	# Чугунное основание и ствол (высота 4.8м)
	_push(out, Vector3(0.0, 0.35, 0.0), Vector3(0.45, 0.70, 0.45), COLOR_DARK_STEEL, true, "pole_base")
	_push(out, Vector3(0.0, 2.50, 0.0), Vector3(0.18, 3.60, 0.18), COLOR_DARK_STEEL, true, "pole_shaft")
	# Кронштейн
	_push(out, Vector3(0.35, 4.45, 0.0), Vector3(0.70, 0.12, 0.12), COLOR_DARK_STEEL, true, "pole_arm", false)
	# Фонарь
	_push(out, Vector3(0.65, 4.30, 0.0), Vector3(0.30, 0.40, 0.30), COLOR_LANTERN_GLOW, true, "lamp_head", false)
	_push(out, Vector3(0.65, 4.54, 0.0), Vector3(0.36, 0.08, 0.36), COLOR_DARK_STEEL, true, "lamp_cap", false)

static func _build_street_lantern_double(out: Array[Dictionary]) -> void:
	_push(out, Vector3(0.0, 0.40, 0.0), Vector3(0.50, 0.80, 0.50), COLOR_DARK_STEEL, true, "pole_base")
	_push(out, Vector3(0.0, 2.70, 0.0), Vector3(0.20, 3.80, 0.20), COLOR_DARK_STEEL, true, "pole_shaft")
	# Двойная поперечина
	_push(out, Vector3(0.0, 4.80, 0.0), Vector3(1.60, 0.12, 0.12), COLOR_DARK_STEEL, true, "pole_crossarm", false)
	# 2 фонаря
	_push(out, Vector3(-0.70, 4.60, 0.0), Vector3(0.30, 0.38, 0.30), COLOR_LANTERN_GLOW, true, "lamp_head_l", false)
	_push(out, Vector3(0.70, 4.60, 0.0), Vector3(0.30, 0.38, 0.30), COLOR_LANTERN_GLOW, true, "lamp_head_r", false)

static func _build_wooden_utility_pole(out: Array[Dictionary]) -> void:
	# Деревянный телеграфный столб (высота 7.2м)
	_push(out, Vector3(0.0, 3.50, 0.0), Vector3(0.28, 7.00, 0.28), COLOR_WOOD_DARK, true, "wood_pole")
	# Траверса с изоляторами
	_push(out, Vector3(0.0, 6.60, 0.0), Vector3(1.60, 0.12, 0.12), COLOR_WOOD, true, "crossarm", false)
	_push(out, Vector3(-0.65, 6.75, 0.0), Vector3(0.08, 0.18, 0.08), COLOR_CONCRETE, true, "insulator_l", false)
	_push(out, Vector3(0.65, 6.75, 0.0), Vector3(0.08, 0.18, 0.08), COLOR_CONCRETE, true, "insulator_r", false)
	# Трансформаторный ящик на столбе
	_push(out, Vector3(0.20, 4.50, 0.0), Vector3(0.35, 0.70, 0.40), COLOR_DARK_STEEL, true, "transformer_box", false)

# ==============================================================================
# 5. ДОРОЖНЫЕ ЗНАКИ И БАРЬЕРЫ
# ==============================================================================

static func _build_road_sign_stop(out: Array[Dictionary]) -> void:
	# Металлическая стойка (высота 2.4м)
	_push(out, Vector3(0.0, 1.10, 0.0), Vector3(0.08, 2.20, 0.08), COLOR_STEEL, true, "sign_post")
	# Восьмигранный щит STOP
	_push(out, Vector3(0.0, 2.05, 0.06), Vector3(0.65, 0.65, 0.03), COLOR_SIGN_RED, true, "sign_plate")
	_push(out, Vector3(0.0, 2.05, 0.08), Vector3(0.40, 0.14, 0.01), COLOR_SIGN_WHITE, false, "sign_text", false)

static func _build_road_sign_yield(out: Array[Dictionary]) -> void:
	_push(out, Vector3(0.0, 1.10, 0.0), Vector3(0.08, 2.20, 0.08), COLOR_STEEL, true, "sign_post")
	_push(out, Vector3(0.0, 2.05, 0.06), Vector3(0.65, 0.60, 0.03), COLOR_SIGN_RED, true, "sign_plate")
	_push(out, Vector3(0.0, 2.05, 0.08), Vector3(0.45, 0.40, 0.01), COLOR_SIGN_WHITE, false, "sign_inner", false)

static func _build_road_sign_direction(out: Array[Dictionary]) -> void:
	# Две стойки
	_push(out, Vector3(-0.55, 1.20, 0.0), Vector3(0.08, 2.40, 0.08), COLOR_STEEL, true, "sign_post_l")
	_push(out, Vector3(0.55, 1.20, 0.0), Vector3(0.08, 2.40, 0.08), COLOR_STEEL, true, "sign_post_r")
	# Синий прямоугольный указатель
	_push(out, Vector3(0.0, 2.00, 0.06), Vector3(1.40, 0.70, 0.04), COLOR_SIGN_BLUE, true, "sign_board")
	_push(out, Vector3(0.0, 2.00, 0.09), Vector3(1.10, 0.12, 0.01), COLOR_SIGN_WHITE, false, "sign_text", false)

static func _build_road_barrier_wooden(out: Array[Dictionary]) -> void:
	# Опоры-козлы
	_push(out, Vector3(-0.95, 0.45, 0.0), Vector3(0.12, 0.90, 0.55), COLOR_WOOD_DARK, true, "barrier_leg_l")
	_push(out, Vector3(0.95, 0.45, 0.0), Vector3(0.12, 0.90, 0.55), COLOR_WOOD_DARK, true, "barrier_leg_r")
	# Горизонтальная балка с полосами (высота 0.95м — паркур)
	_push(out, Vector3(0.0, 0.85, 0.0), Vector3(2.40, 0.22, 0.08), COLOR_SIGN_WHITE, true, "barrier_beam")
	_push(out, Vector3(-0.50, 0.85, 0.05), Vector3(0.30, 0.22, 0.01), COLOR_SIGN_RED, false, "stripe_1", false)
	_push(out, Vector3(0.50, 0.85, 0.05), Vector3(0.30, 0.22, 0.01), COLOR_SIGN_RED, false, "stripe_2", false)

# ==============================================================================
# 6. МУСОРКИ, БОЧКИ, ЯЩИКИ, ГОРОДСКИЕ ОБЪЕКТЫ
# ==============================================================================

static func _build_metal_dumpster(out: Array[Dictionary]) -> void:
	# Металлический мусорный контейнер (высота 1.35м)
	_push(out, Vector3(0.0, 0.12, 0.0), Vector3(2.00, 0.14, 1.25), COLOR_DARK_STEEL, true, "dumpster_bottom")
	_push(out, Vector3(0.0, 0.72, -0.60), Vector3(2.10, 1.10, 0.10), COLOR_DUMPSTER_GREEN, true, "dumpster_wall_f")
	_push(out, Vector3(0.0, 0.72, 0.60), Vector3(2.10, 1.10, 0.10), COLOR_DUMPSTER_GREEN, true, "dumpster_wall_b")
	_push(out, Vector3(-1.00, 0.72, 0.0), Vector3(0.10, 1.10, 1.25), COLOR_DUMPSTER_GREEN, true, "dumpster_wall_l")
	_push(out, Vector3(1.00, 0.72, 0.0), Vector3(0.10, 1.10, 1.25), COLOR_DUMPSTER_GREEN, true, "dumpster_wall_r")
	# Откидные крышки
	_push(out, Vector3(-0.50, 1.30, 0.0), Vector3(0.95, 0.08, 1.30), COLOR_DARK_STEEL, true, "dumpster_lid_l")
	_push(out, Vector3(0.50, 1.30, 0.0), Vector3(0.95, 0.08, 1.30), COLOR_DARK_STEEL, true, "dumpster_lid_r")

static func _build_street_trash_can(out: Array[Dictionary]) -> void:
	_push(out, Vector3(0.0, 0.40, 0.0), Vector3(0.48, 0.80, 0.48), COLOR_DARK_STEEL, true, "trash_body")
	_push(out, Vector3(0.0, 0.88, 0.0), Vector3(0.56, 0.12, 0.56), COLOR_STEEL, true, "trash_hood", false)

static func _build_oil_barrel_single(out: Array[Dictionary]) -> void:
	# Бочка высотой 0.95м, диаметр 0.65м
	_push(out, Vector3(0.0, 0.48, 0.0), Vector3(0.65, 0.95, 0.65), COLOR_BARREL_BLUE, true, "barrel_body")
	_push(out, Vector3(0.0, 0.28, 0.0), Vector3(0.68, 0.05, 0.68), COLOR_DARK_STEEL, true, "barrel_rib_1", false)
	_push(out, Vector3(0.0, 0.68, 0.0), Vector3(0.68, 0.05, 0.68), COLOR_DARK_STEEL, true, "barrel_rib_2", false)

static func _build_oil_barrel_cluster(out: Array[Dictionary]) -> void:
	# Склад из 4 бочек (3 стоячие в треугольник, 1 упавшая)
	# Бочка 1
	_push(out, Vector3(-0.45, 0.48, -0.35), Vector3(0.65, 0.95, 0.65), COLOR_BARREL_BLUE, true, "barrel_1")
	# Бочка 2
	_push(out, Vector3(0.45, 0.48, -0.35), Vector3(0.65, 0.95, 0.65), COLOR_BURNT_RUST, true, "barrel_2")
	# Бочка 3
	_push(out, Vector3(0.0, 0.48, 0.45), Vector3(0.65, 0.95, 0.65), COLOR_BARREL_BLUE, true, "barrel_3")
	# Бочка 4 (поваленная)
	_push(out, Vector3(0.65, 0.35, 0.45), Vector3(0.95, 0.65, 0.65), COLOR_DARK_STEEL, true, "barrel_4_fallen")

static func _build_ammo_crate_stack(out: Array[Dictionary]) -> void:
	# 3 армейских деревянных ящика
	_push(out, Vector3(-0.40, 0.28, 0.0), Vector3(0.75, 0.55, 1.10), COLOR_WOOD, true, "crate_1")
	_push(out, Vector3(0.40, 0.28, 0.0), Vector3(0.75, 0.55, 1.10), COLOR_WOOD_DARK, true, "crate_2")
	_push(out, Vector3(0.0, 0.82, 0.0), Vector3(0.75, 0.55, 1.10), COLOR_WOOD, true, "crate_3_top")

static func _build_fire_hydrant(out: Array[Dictionary]) -> void:
	_push(out, Vector3(0.0, 0.38, 0.0), Vector3(0.35, 0.75, 0.35), COLOR_SIGN_RED, true, "hydrant_body")
	_push(out, Vector3(0.0, 0.78, 0.0), Vector3(0.42, 0.14, 0.42), COLOR_DARK_STEEL, true, "hydrant_cap", false)
	_push(out, Vector3(-0.22, 0.45, 0.0), Vector3(0.14, 0.14, 0.14), COLOR_DARK_STEEL, true, "hydrant_nozzle_l", false)
	_push(out, Vector3(0.22, 0.45, 0.0), Vector3(0.14, 0.14, 0.14), COLOR_DARK_STEEL, true, "hydrant_nozzle_r", false)

static func _build_tire_stack(out: Array[Dictionary]) -> void:
	# Баррикада из 4 покрышек (высота 1.10м)
	_push(out, Vector3(0.0, 0.14, 0.0), Vector3(1.10, 0.28, 1.10), COLOR_RUBBER, true, "tire_1")
	_push(out, Vector3(0.0, 0.42, 0.0), Vector3(1.10, 0.28, 1.10), COLOR_RUBBER, true, "tire_2")
	_push(out, Vector3(0.0, 0.70, 0.0), Vector3(1.10, 0.28, 1.10), COLOR_RUBBER, true, "tire_3")
	_push(out, Vector3(0.0, 0.98, 0.0), Vector3(1.10, 0.28, 1.10), COLOR_RUBBER, true, "tire_4")

static func _build_bus_stop_shelter(out: Array[Dictionary]) -> void:
	# Павильон остановки (3.8м х 1.8м х 2.6м)
	# Опоры
	_push(out, Vector3(-1.80, 1.25, -0.80), Vector3(0.12, 2.50, 0.12), COLOR_DARK_STEEL, true, "shelter_post_fl")
	_push(out, Vector3(1.80, 1.25, -0.80), Vector3(0.12, 2.50, 0.12), COLOR_DARK_STEEL, true, "shelter_post_fr")
	_push(out, Vector3(-1.80, 1.25, 0.80), Vector3(0.12, 2.50, 0.12), COLOR_DARK_STEEL, true, "shelter_post_bl")
	_push(out, Vector3(1.80, 1.25, 0.80), Vector3(0.12, 2.50, 0.12), COLOR_DARK_STEEL, true, "shelter_post_br")
	# Задняя защитная стенка
	_push(out, Vector3(0.0, 1.20, 0.80), Vector3(3.60, 2.20, 0.06), COLOR_STEEL, true, "shelter_back_wall")
	# Левая боковая стенка
	_push(out, Vector3(-1.80, 1.20, 0.0), Vector3(0.06, 2.20, 1.60), COLOR_STEEL, true, "shelter_side_wall")
	# Скамья внутри
	_push(out, Vector3(0.0, 0.45, 0.45), Vector3(3.00, 0.08, 0.45), COLOR_WOOD, true, "shelter_bench")
	# Навес крыши
	_push(out, Vector3(0.0, 2.55, 0.0), Vector3(4.00, 0.12, 2.10), COLOR_DARK_STEEL, true, "shelter_roof")

static func _build_concrete_pipe_segment(out: Array[Dictionary]) -> void:
	# Железобетонная водопропускная труба (2.4м х 2.0м х 2.0м) с проходом внутри!
	# Основание
	_push(out, Vector3(0.0, 0.12, 0.0), Vector3(2.40, 0.24, 1.80), COLOR_CONCRETE_DARK, true, "pipe_bottom")
	# Левая стенка
	_push(out, Vector3(0.0, 1.00, -0.88), Vector3(2.40, 1.60, 0.24), COLOR_CONCRETE, true, "pipe_wall_l")
	# Правая стенка
	_push(out, Vector3(0.0, 1.00, 0.88), Vector3(2.40, 1.60, 0.24), COLOR_CONCRETE, true, "pipe_wall_r")
	# Верхняя сводчатая плита
	_push(out, Vector3(0.0, 1.88, 0.0), Vector3(2.40, 0.24, 1.80), COLOR_CONCRETE, true, "pipe_top")

static func _push(arr: Array[Dictionary], pos: Vector3, size: Vector3, color: Color, coll: bool, tag: String, cast_shadow: Variant = null) -> void:
	var shadow_val: bool = coll
	if cast_shadow != null:
		shadow_val = bool(cast_shadow)
	else:
		# Оптимизация теней для мобильных GPU (GL Compatibility):
		# Мелкие детали (лампы, ребра бочек, надписи знаков, штуцеры) не отбрасывают тень
		if tag in ["wheel_rim", "wreck_pillar", "radiator_grill", "lamp_head", "lamp_head_l", "lamp_head_r", "lamp_cap", "pole_arm", "pole_crossarm", "insulator_l", "insulator_r", "transformer_box", "sign_text", "sign_inner", "stripe_1", "stripe_2", "trash_hood", "barrel_rib_1", "barrel_rib_2", "hydrant_cap", "hydrant_nozzle_l", "hydrant_nozzle_r", "hedgehog_plate"]:
			shadow_val = false
	arr.append({
		"pos": pos,
		"size": size,
		"color": color,
		"solid": coll,
		"kind": tag,
		"cast_shadow": shadow_val
	})
