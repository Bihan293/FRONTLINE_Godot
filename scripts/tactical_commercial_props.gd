extends RefCounted
class_name FRONTLINETacticalCommercialProps

## Пак тактических 3D-ассетов для крупных общественных и коммерческих зданий:
## Магазины / супермаркеты, торговые центры (ТЦ), больницы, школы и общественные холлы.
## Стиль: Dummy War / Bodycam / Tactical CQB.
## Все пропсы оптимизированы под мобильный рендер GL Compatibility:
## - Единая палитра материалов с кэшированием (StandardMaterial3D переиспользуются).
## - Мелкие детали имеют cast_shadow = false для экономии теневых проходов.
## - Укрытия высотой 0.85–1.05м поддерживают упор оружия и вольтинг (_try_vault).
## - Физические коллизии StaticBody3D на слое 1 с точными BoxShape3D.

# Палитра цветов (коммерческий металл, пластик, дерево, эмаль, стекло, ткань, картон)
const COLOR_STEEL_WHITE := Color(0.85, 0.86, 0.88)
const COLOR_STEEL_DARK := Color(0.24, 0.25, 0.27)
const COLOR_STEEL_CHROME := Color(0.68, 0.70, 0.72)
const COLOR_PLASTIC_GREY := Color(0.55, 0.57, 0.59)
const COLOR_PLASTIC_RED := Color(0.78, 0.18, 0.15)
const COLOR_PLASTIC_BLUE := Color(0.18, 0.38, 0.68)
const COLOR_PLASTIC_GREEN := Color(0.18, 0.52, 0.28)
const COLOR_WOOD_PALE := Color(0.62, 0.52, 0.40)
const COLOR_WOOD_VARNISH := Color(0.44, 0.30, 0.18)
const COLOR_GLASS_TINT := Color(0.65, 0.78, 0.82)
const COLOR_VINYL_BLACK := Color(0.14, 0.14, 0.15)
const COLOR_HOSPITAL_CYAN := Color(0.22, 0.58, 0.58)
const COLOR_HOSPITAL_WHITE := Color(0.92, 0.93, 0.94)
const COLOR_FABRIC_SCREEN := Color(0.80, 0.82, 0.78)
const COLOR_CARDBOARD := Color(0.64, 0.53, 0.38)
const COLOR_BLACKBOARD_GREEN := Color(0.15, 0.28, 0.20)
const COLOR_LEATHER_BROWN := Color(0.48, 0.28, 0.18)
const COLOR_FIRE_RED := Color(0.82, 0.14, 0.12)
const COLOR_BOTTLE_BLUE := Color(0.32, 0.58, 0.85)

static func get_available_types() -> Array[String]:
	return [
		# 1. Магазин / супермаркет (Store)
		"cash_register_counter",
		"supermarket_shelf_aisle",
		"supermarket_shelf_endcap",
		"commercial_refrigerator_drink",
		"commercial_freezer_horizontal",
		"shopping_cart_nest",
		"anti_theft_gate",
		"warehouse_pallet_stack",
		"pallet_jack",
		# 2. Торговый центр (Mall)
		"mall_bench_modern",
		"mall_planter_pot",
		"mall_advertising_pillar",
		"mall_escalator_segment",
		"mall_trash_recycling",
		# 3. Больница / клиника (Hospital)
		"hospital_gurney_bed",
		"iv_drip_stand",
		"operating_table",
		"medical_screen_divider",
		"medicine_glass_cabinet",
		"oxygen_tank_cart",
		"hospital_wheelchair",
		"hospital_reception_desk",
		# 4. Школа / учебные заведения (School)
		"school_desk_double",
		"school_teacher_desk",
		"school_blackboard",
		"school_hallway_lockers",
		"school_gym_vault_box",
		"school_gym_bench",
		# 5. Общественные холлы и безопасность (Public Safety)
		"fire_hose_cabinet",
		"water_dispenser_cooler"
	]

static func get_prop_info(type_name: String) -> Dictionary:
	match type_name:
		# --- Store ---
		"cash_register_counter":
			return {
				"name": "Кассовый узел магазина",
				"category": "store",
				"size": Vector3(2.20, 1.15, 0.90),
				"cover_height": 0.95,
				"can_vault": true,
				"description": "Транспортёрная лента, монитор кассира, накопитель товаров и разделитель."
			}
		"supermarket_shelf_aisle":
			return {
				"name": "Двусторонний торговый стеллаж",
				"category": "store",
				"size": Vector3(2.40, 1.85, 1.10),
				"cover_height": 1.85,
				"can_vault": false,
				"description": "Массивный островной стеллаж с 4 ярусами полок для товаров и простенком."
			}
		"supermarket_shelf_endcap":
			return {
				"name": "Торцевой промо-стеллаж",
				"category": "store",
				"size": Vector3(1.20, 1.85, 0.60),
				"cover_height": 1.85,
				"can_vault": false,
				"description": "Торцевая стойка для акционных товаров в торце прохода."
			}
		"commercial_refrigerator_drink":
			return {
				"name": "Холодильная витрина для напитков",
				"category": "store",
				"size": Vector3(1.20, 2.10, 0.75),
				"cover_height": 2.10,
				"can_vault": false,
				"description": "Застеклённый вертикальный шкаф-холодильник с подсветкой и полками напитков."
			}
		"commercial_freezer_horizontal":
			return {
				"name": "Морозильная бонета / ларь",
				"category": "store",
				"size": Vector3(2.20, 0.92, 1.00),
				"cover_height": 0.92,
				"can_vault": true,
				"description": "Горизонтальная морозильная витрина с защитным стеклом и бамперами тележек."
			}
		"shopping_cart_nest":
			return {
				"name": "Стопка покупательских тележек",
				"category": "store",
				"size": Vector3(1.80, 0.98, 0.65),
				"cover_height": 0.95,
				"can_vault": true,
				"description": "Ряд из 4 сложенных одна в другую металлических тележек с красными ручками."
			}
		"anti_theft_gate":
			return {
				"name": "Антикражные радиочастотные ворота",
				"category": "store",
				"size": Vector3(1.60, 1.55, 0.20),
				"cover_height": 1.55,
				"can_vault": false,
				"description": "Пара сенсорных стоек на выходе из магазина со свободным проходом между ними."
			}
		"warehouse_pallet_stack":
			return {
				"name": "Штабель европоддонов",
				"category": "store",
				"size": Vector3(1.20, 0.75, 0.80),
				"cover_height": 0.75,
				"can_vault": true,
				"description": "Штабель из 5 деревянных складских поддонов для укрытия сидя."
			}
		"pallet_jack":
			return {
				"name": "Гидравлическая тележка (рохля)",
				"category": "store",
				"size": Vector3(1.60, 1.20, 0.68),
				"cover_height": 0.45,
				"can_vault": true,
				"description": "Складская тележка с вилами, рулевыми роликами и поворотным дышлом."
			}

		# --- Mall ---
		"mall_bench_modern":
			return {
				"name": "Скамья атриума ТЦ",
				"category": "mall",
				"size": Vector3(2.00, 0.48, 0.65),
				"cover_height": 0.48,
				"can_vault": true,
				"description": "Широкая деревянная скамья на стальных опорах для холлов торгового центра."
			}
		"mall_planter_pot":
			return {
				"name": "Декоративная клумба с кустом",
				"category": "mall",
				"size": Vector3(1.10, 1.45, 1.10),
				"cover_height": 0.95,
				"can_vault": true,
				"description": "Бетонная кадка 0.95м с декоративной растительностью (надёжное круговое укрытие)."
			}
		"mall_advertising_pillar":
			return {
				"name": "Рекламный пилон / лайтбокс",
				"category": "mall",
				"size": Vector3(0.90, 2.40, 0.35),
				"cover_height": 2.40,
				"can_vault": false,
				"description": "Вертикальная рекламная стойка с подсветкой и алюминиевым профилем."
			}
		"mall_escalator_segment":
			return {
				"name": "Секция эскалатора ТЦ",
				"category": "mall",
				"size": Vector3(3.40, 1.70, 1.20),
				"cover_height": 1.05,
				"can_vault": true,
				"description": "Наклонные ступени эскалатора со стеклянными балюстрадами и поручнями."
			}
		"mall_trash_recycling":
			return {
				"name": "Урна раздельного сбора отходов",
				"category": "mall",
				"size": Vector3(1.20, 0.92, 0.45),
				"cover_height": 0.92,
				"can_vault": true,
				"description": "Трёхсекционная стальная стойка для пластика, бумаги и смешанных отходов."
			}

		# --- Hospital ---
		"hospital_gurney_bed":
			return {
				"name": "Медицинская каталка / койка",
				"category": "hospital",
				"size": Vector3(2.10, 0.92, 0.85),
				"cover_height": 0.92,
				"can_vault": true,
				"description": "Функциональная кровать на поворотных колёсиках с матрасом и боковыми упорами."
			}
		"iv_drip_stand":
			return {
				"name": "Инфузионная стойка (капельница)",
				"category": "hospital",
				"size": Vector3(0.55, 1.85, 0.55),
				"cover_height": 1.85,
				"can_vault": false,
				"description": "Хромированная стойка на 5 лучевых колёсиках с флаконами физраствора."
			}
		"operating_table":
			return {
				"name": "Хирургический стол с лампой",
				"category": "hospital",
				"size": Vector3(2.20, 2.10, 0.90),
				"cover_height": 0.95,
				"can_vault": true,
				"description": "Тяжёлый операционный стол на массивной гидравлической колонне со светильником."
			}
		"medical_screen_divider":
			return {
				"name": "Медицинская ширма",
				"category": "hospital",
				"size": Vector3(2.10, 1.75, 0.35),
				"cover_height": 1.75,
				"can_vault": false,
				"description": "Трёхсекционная складная ширма с белыми полотнами (визуальное перекрытие)."
			}
		"medicine_glass_cabinet":
			return {
				"name": "Шкаф для медикаментов",
				"category": "hospital",
				"size": Vector3(0.95, 1.85, 0.45),
				"cover_height": 1.85,
				"can_vault": false,
				"description": "Стальной белый шкаф со стеклянными дверцами и полками для препаратов."
			}
		"oxygen_tank_cart":
			return {
				"name": "Тележка с кислородными баллонами",
				"category": "hospital",
				"size": Vector3(0.65, 1.45, 0.55),
				"cover_height": 1.45,
				"can_vault": false,
				"description": "Двухколёсная тележка с 2 баллонами сжатого медицинского кислорода и манометрами."
			}
		"hospital_wheelchair":
			return {
				"name": "Инвалидное кресло-коляска",
				"category": "hospital",
				"size": Vector3(0.85, 0.98, 0.72),
				"cover_height": 0.98,
				"can_vault": true,
				"description": "Коляска с большими спицованными колесами, подлокотниками и подножками."
			}
		"hospital_reception_desk":
			return {
				"name": "Стойка регистратуры / приёмного покоя",
				"category": "hospital",
				"size": Vector3(2.40, 1.15, 1.20),
				"cover_height": 1.15,
				"can_vault": true,
				"description": "Г-образная стойка медперсонала с высокой столешницей и внутренней тумбой."
			}

		# --- School ---
		"school_desk_double":
			return {
				"name": "Школьная парта со скамьей",
				"category": "school",
				"size": Vector3(1.20, 0.76, 0.85),
				"cover_height": 0.76,
				"can_vault": true,
				"description": "Классическая двухместная парта на металлокаркасе со встроенными сиденьями."
			}
		"school_teacher_desk":
			return {
				"name": "Учительский стол с тумбой",
				"category": "school",
				"size": Vector3(1.40, 0.78, 0.75),
				"cover_height": 0.78,
				"can_vault": true,
				"description": "Широкий деревянный стол с тумбой на 3 ящика и экраном под столешницей."
			}
		"school_blackboard":
			return {
				"name": "Школьная меловая доска",
				"category": "school",
				"size": Vector3(2.80, 1.40, 0.15),
				"cover_height": 1.40,
				"can_vault": false,
				"description": "Трёхстворчатая тёмно-зелёная классная доска с полочкой для мела."
			}
		"school_hallway_lockers":
			return {
				"name": "Шкафчики для коридора школы",
				"category": "school",
				"size": Vector3(1.40, 1.85, 0.55),
				"cover_height": 1.85,
				"can_vault": false,
				"description": "Блок из 4 металлических индивидуальных шкафчиков с вентиляционными прорезями."
			}
		"school_gym_vault_box":
			return {
				"name": "Гимнастический козёл / плинт",
				"category": "school",
				"size": Vector3(1.30, 1.05, 0.75),
				"cover_height": 1.05,
				"can_vault": true,
				"description": "Спортивный гимнастический снаряд с кожаным мягким верхом и деревянными секциями."
			}
		"school_gym_bench":
			return {
				"name": "Спортивная гимнастическая скамья",
				"category": "school",
				"size": Vector3(2.80, 0.42, 0.38),
				"cover_height": 0.42,
				"can_vault": true,
				"description": "Длинная деревянная скамья на стальных Т-образных ножках для спортзала."
			}

		# --- Public Safety ---
		"fire_hose_cabinet":
			return {
				"name": "Пожарный шкаф с гидрантом",
				"category": "public_safety",
				"size": Vector3(0.75, 0.95, 0.28),
				"cover_height": 0.95,
				"can_vault": false,
				"description": "Красный настенный стальной шкаф с рукавом, стволом и огнетушителем."
			}
		"water_dispenser_cooler":
			return {
				"name": "Кулер для питьевой воды",
				"category": "public_safety",
				"size": Vector3(0.42, 1.35, 0.42),
				"cover_height": 1.35,
				"can_vault": false,
				"description": "Напольный диспенсер с установленной синей 19-литровой бутылью и кранами."
			}
		_:
			return {}

static func get_prop_boxes(type_name: String, origin: Vector3 = Vector3.ZERO, rot_deg: float = 0.0) -> Array[Dictionary]:
	var local_boxes: Array[Dictionary] = []
	match type_name:
		# Store
		"cash_register_counter":
			_build_cash_register_counter(local_boxes)
		"supermarket_shelf_aisle":
			_build_supermarket_shelf_aisle(local_boxes)
		"supermarket_shelf_endcap":
			_build_supermarket_shelf_endcap(local_boxes)
		"commercial_refrigerator_drink":
			_build_commercial_refrigerator_drink(local_boxes)
		"commercial_freezer_horizontal":
			_build_commercial_freezer_horizontal(local_boxes)
		"shopping_cart_nest":
			_build_shopping_cart_nest(local_boxes)
		"anti_theft_gate":
			_build_anti_theft_gate(local_boxes)
		"warehouse_pallet_stack":
			_build_warehouse_pallet_stack(local_boxes)
		"pallet_jack":
			_build_pallet_jack(local_boxes)
		# Mall
		"mall_bench_modern":
			_build_mall_bench_modern(local_boxes)
		"mall_planter_pot":
			_build_mall_planter_pot(local_boxes)
		"mall_advertising_pillar":
			_build_mall_advertising_pillar(local_boxes)
		"mall_escalator_segment":
			_build_mall_escalator_segment(local_boxes)
		"mall_trash_recycling":
			_build_mall_trash_recycling(local_boxes)
		# Hospital
		"hospital_gurney_bed":
			_build_hospital_gurney_bed(local_boxes)
		"iv_drip_stand":
			_build_iv_drip_stand(local_boxes)
		"operating_table":
			_build_operating_table(local_boxes)
		"medical_screen_divider":
			_build_medical_screen_divider(local_boxes)
		"medicine_glass_cabinet":
			_build_medicine_glass_cabinet(local_boxes)
		"oxygen_tank_cart":
			_build_oxygen_tank_cart(local_boxes)
		"hospital_wheelchair":
			_build_hospital_wheelchair(local_boxes)
		"hospital_reception_desk":
			_build_hospital_reception_desk(local_boxes)
		# School
		"school_desk_double":
			_build_school_desk_double(local_boxes)
		"school_teacher_desk":
			_build_school_teacher_desk(local_boxes)
		"school_blackboard":
			_build_school_blackboard(local_boxes)
		"school_hallway_lockers":
			_build_school_hallway_lockers(local_boxes)
		"school_gym_vault_box":
			_build_school_gym_vault_box(local_boxes)
		"school_gym_bench":
			_build_school_gym_bench(local_boxes)
		# Safety
		"fire_hose_cabinet":
			_build_fire_hose_cabinet(local_boxes)
		"water_dispenser_cooler":
			_build_water_dispenser_cooler(local_boxes)
		_:
			_build_cash_register_counter(local_boxes)

	var out: Array[Dictionary] = []
	var rad := deg_to_rad(rot_deg)
	var cos_a := cos(rad)
	var sin_a := sin(rad)

	for b in local_boxes:
		var lp: Vector3 = b.pos
		var ls: Vector3 = b.size
		var wp := Vector3(
			origin.x + (lp.x * cos_a + lp.z * sin_a),
			origin.y + lp.y,
			origin.z + (-lp.x * sin_a + lp.z * cos_a)
		)
		var ws := ls
		if absf(sin_a) > 0.707:
			ws = Vector3(ls.z, ls.y, ls.x)

		out.append({
			"pos": wp,
			"size": ws,
			"color": b.color,
			"solid": b.solid,
			"kind": b.kind,
			"cast_shadow": b.get("cast_shadow", true)
		})

	return out

static func create_prop_node(type_name: String, rot_deg: float = 0.0) -> Node3D:
	var boxes := get_prop_boxes(type_name, Vector3.ZERO, rot_deg)
	if boxes.is_empty():
		return null

	var root := Node3D.new()
	root.name = "Prop_" + type_name

	var static_body := StaticBody3D.new()
	static_body.name = "PropCollision"
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	root.add_child(static_body)

	var mat_cache: Dictionary = {}

	for i in range(boxes.size()):
		var b: Dictionary = boxes[i]
		var pos: Vector3 = b.pos
		var size: Vector3 = b.size
		var col: Color = b.color
		var solid: bool = b.solid
		var cast_shadow: bool = b.get("cast_shadow", true)

		# 3D Mesh
		var mi := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = size
		mi.mesh = box_mesh
		mi.position = pos

		var mat_key: int = col.to_rgba32()
		var mat: StandardMaterial3D
		if mat_cache.has(mat_key):
			mat = mat_cache[mat_key]
		else:
			mat = StandardMaterial3D.new()
			mat.albedo_color = col
			mat.roughness = 0.75
			mat_cache[mat_key] = mat
		mi.material_override = mat

		if not cast_shadow:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		root.add_child(mi)

		# Collision shape
		if solid:
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = size
			cs.shape = bs
			cs.position = pos
			static_body.add_child(cs)

	return root

static func _add_box(boxes: Array[Dictionary], pos: Vector3, size: Vector3, color: Color, solid: bool = true, kind: String = "prop", cast_shadow: bool = true) -> void:
	boxes.append({
		"pos": pos,
		"size": size,
		"color": color,
		"solid": solid,
		"kind": kind,
		"cast_shadow": cast_shadow
	})

# ==============================================================================
# 1. STORE (Магазин и супермаркет)
# ==============================================================================

static func _build_cash_register_counter(b: Array[Dictionary]) -> void:
	# Основание стола
	_add_box(b, Vector3(0.0, 0.45, 0.0), Vector3(2.20, 0.90, 0.85), COLOR_STEEL_WHITE, true, "cover")
	# Чёрная лента транспортера
	_add_box(b, Vector3(-0.35, 0.91, 0.0), Vector3(1.30, 0.02, 0.65), COLOR_VINYL_BLACK, false, "decor")
	# Разделитель покупок
	_add_box(b, Vector3(-0.35, 0.93, 0.25), Vector3(0.40, 0.04, 0.04), COLOR_PLASTIC_RED, false, "detail", false)
	# Сканер / экран кассира на стойке
	_add_box(b, Vector3(0.65, 1.05, 0.20), Vector3(0.35, 0.28, 0.25), COLOR_STEEL_DARK, true, "cover")
	_add_box(b, Vector3(0.65, 1.05, 0.07), Vector3(0.28, 0.20, 0.02), COLOR_GLASS_TINT, false, "detail", false)
	# Защитный прозрачный акриловый экран
	_add_box(b, Vector3(0.65, 1.35, -0.25), Vector3(0.60, 0.50, 0.02), COLOR_GLASS_TINT, false, "detail", false)
	# Накопитель покупок на выходе
	_add_box(b, Vector3(0.95, 0.88, 0.0), Vector3(0.25, 0.04, 0.80), COLOR_STEEL_CHROME, false, "detail")

static func _build_supermarket_shelf_aisle(b: Array[Dictionary]) -> void:
	# Центральная разделительная перегородка
	_add_box(b, Vector3(0.0, 0.925, 0.0), Vector3(2.40, 1.85, 0.06), COLOR_STEEL_WHITE, true, "cover")
	# Опорные боковые стойки
	_add_box(b, Vector3(-1.18, 0.925, 0.0), Vector3(0.06, 1.85, 1.05), COLOR_STEEL_DARK, true, "cover")
	_add_box(b, Vector3(1.18, 0.925, 0.0), Vector3(0.06, 1.85, 1.05), COLOR_STEEL_DARK, true, "cover")
	# Нижние цокольные полки (глубокие)
	_add_box(b, Vector3(0.0, 0.15, 0.0), Vector3(2.35, 0.18, 1.05), COLOR_STEEL_WHITE, true, "cover")
	# Полка 1 (Y=0.65)
	_add_box(b, Vector3(0.0, 0.65, 0.0), Vector3(2.35, 0.04, 0.95), COLOR_STEEL_WHITE, false, "shelf")
	# Полка 2 (Y=1.15)
	_add_box(b, Vector3(0.0, 1.15, 0.0), Vector3(2.35, 0.04, 0.95), COLOR_STEEL_WHITE, false, "shelf")
	# Полка 3 (Y=1.65)
	_add_box(b, Vector3(0.0, 1.65, 0.0), Vector3(2.35, 0.04, 0.90), COLOR_STEEL_WHITE, false, "shelf")
	# Товары на полках (коробки/консервы разных цветов)
	_add_box(b, Vector3(-0.60, 0.80, 0.32), Vector3(0.80, 0.26, 0.28), COLOR_PLASTIC_RED, false, "goods", false)
	_add_box(b, Vector3(0.50, 0.80, 0.32), Vector3(0.70, 0.24, 0.28), COLOR_PLASTIC_BLUE, false, "goods", false)
	_add_box(b, Vector3(-0.40, 1.30, -0.32), Vector3(0.90, 0.24, 0.26), COLOR_PLASTIC_GREEN, false, "goods", false)
	_add_box(b, Vector3(0.60, 1.30, -0.32), Vector3(0.60, 0.24, 0.26), COLOR_CARDBOARD, false, "goods", false)

static func _build_supermarket_shelf_endcap(b: Array[Dictionary]) -> void:
	# Задняя панель
	_add_box(b, Vector3(0.0, 0.925, -0.27), Vector3(1.20, 1.85, 0.06), COLOR_PLASTIC_RED, true, "cover")
	# Нижняя база
	_add_box(b, Vector3(0.0, 0.15, 0.0), Vector3(1.20, 0.20, 0.58), COLOR_STEEL_DARK, true, "cover")
	# 3 консольные полки
	_add_box(b, Vector3(0.0, 0.65, 0.0), Vector3(1.15, 0.04, 0.52), COLOR_STEEL_WHITE, false, "shelf")
	_add_box(b, Vector3(0.0, 1.15, 0.0), Vector3(1.15, 0.04, 0.52), COLOR_STEEL_WHITE, false, "shelf")
	_add_box(b, Vector3(0.0, 1.65, 0.0), Vector3(1.15, 0.04, 0.48), COLOR_STEEL_WHITE, false, "shelf")
	# Верхний рекламный топпер
	_add_box(b, Vector3(0.0, 1.95, -0.20), Vector3(1.20, 0.22, 0.10), COLOR_PLASTIC_RED, false, "detail")
	# Товары
	_add_box(b, Vector3(0.0, 0.80, 0.05), Vector3(0.90, 0.25, 0.35), COLOR_CARDBOARD, false, "goods", false)

static func _build_commercial_refrigerator_drink(b: Array[Dictionary]) -> void:
	# Массивный теплоизолированный корпус
	_add_box(b, Vector3(0.0, 1.05, 0.0), Vector3(1.20, 2.10, 0.75), COLOR_STEEL_DARK, true, "cover")
	# Внутренняя ниша (визуально углубленная)
	_add_box(b, Vector3(0.0, 1.05, 0.36), Vector3(1.08, 1.60, 0.04), COLOR_GLASS_TINT, false, "glass")
	# Рамы двух раздвижных стеклянных дверей
	_add_box(b, Vector3(-0.28, 1.05, 0.37), Vector3(0.52, 1.62, 0.03), COLOR_STEEL_WHITE, false, "detail", false)
	_add_box(b, Vector3(0.28, 1.05, 0.37), Vector3(0.52, 1.62, 0.03), COLOR_STEEL_WHITE, false, "detail", false)
	# Верхний световой лайтбокс с брендом
	_add_box(b, Vector3(0.0, 1.98, 0.34), Vector3(1.14, 0.20, 0.06), COLOR_PLASTIC_BLUE, false, "detail")
	# Нижняя решётка компрессора
	_add_box(b, Vector3(0.0, 0.15, 0.35), Vector3(1.14, 0.26, 0.05), COLOR_STEEL_DARK, false, "detail", false)

static func _build_commercial_freezer_horizontal(b: Array[Dictionary]) -> void:
	# Основной корпус ларя
	_add_box(b, Vector3(0.0, 0.44, 0.0), Vector3(2.20, 0.88, 1.00), COLOR_STEEL_WHITE, true, "cover")
	# Защитный бампер по периметру
	_add_box(b, Vector3(0.0, 0.20, 0.0), Vector3(2.24, 0.12, 1.04), COLOR_PLASTIC_GREY, false, "detail", false)
	# Рама раздвижных стеклянных шторок
	_add_box(b, Vector3(0.0, 0.90, 0.0), Vector3(2.10, 0.05, 0.92), COLOR_PLASTIC_BLUE, true, "cover")
	# Стеклянная створка 1 и 2
	_add_box(b, Vector3(-0.52, 0.92, 0.0), Vector3(1.00, 0.02, 0.84), COLOR_GLASS_TINT, false, "detail", false)
	_add_box(b, Vector3(0.52, 0.92, 0.0), Vector3(1.00, 0.02, 0.84), COLOR_GLASS_TINT, false, "detail", false)
	# Ручки створок
	_add_box(b, Vector3(-0.06, 0.94, 0.0), Vector3(0.04, 0.03, 0.40), COLOR_STEEL_DARK, false, "detail", false)

static func _build_shopping_cart_nest(b: Array[Dictionary]) -> void:
	# Коллизия блока тележек
	_add_box(b, Vector3(0.0, 0.48, 0.0), Vector3(1.80, 0.96, 0.65), COLOR_STEEL_CHROME, true, "cover")
	# Красная пластиковая ручка ведущей тележки
	_add_box(b, Vector3(0.85, 0.94, 0.0), Vector3(0.08, 0.06, 0.60), COLOR_PLASTIC_RED, false, "detail")
	# Ручка второй тележки
	_add_box(b, Vector3(0.45, 0.94, 0.0), Vector3(0.08, 0.06, 0.60), COLOR_PLASTIC_RED, false, "detail", false)
	# Ручка третьей тележки
	_add_box(b, Vector3(0.05, 0.94, 0.0), Vector3(0.08, 0.06, 0.60), COLOR_PLASTIC_RED, false, "detail", false)
	# Колёсики снизу
	_add_box(b, Vector3(0.75, 0.06, 0.26), Vector3(0.12, 0.12, 0.06), COLOR_STEEL_DARK, false, "detail", false)
	_add_box(b, Vector3(0.75, 0.06, -0.26), Vector3(0.12, 0.12, 0.06), COLOR_STEEL_DARK, false, "detail", false)
	_add_box(b, Vector3(-0.75, 0.06, 0.26), Vector3(0.12, 0.12, 0.06), COLOR_STEEL_DARK, false, "detail", false)
	_add_box(b, Vector3(-0.75, 0.06, -0.26), Vector3(0.12, 0.12, 0.06), COLOR_STEEL_DARK, false, "detail", false)

static func _build_anti_theft_gate(b: Array[Dictionary]) -> void:
	# Левая антенна-стойка
	_add_box(b, Vector3(-0.70, 0.775, 0.0), Vector3(0.14, 1.55, 0.08), COLOR_PLASTIC_GREY, true, "cover")
	_add_box(b, Vector3(-0.70, 0.04, 0.0), Vector3(0.24, 0.08, 0.20), COLOR_STEEL_DARK, true, "cover")
	_add_box(b, Vector3(-0.70, 0.775, 0.0), Vector3(0.08, 1.30, 0.04), COLOR_GLASS_TINT, false, "detail", false)
	# Правая антенна-стойка
	_add_box(b, Vector3(0.70, 0.775, 0.0), Vector3(0.14, 1.55, 0.08), COLOR_PLASTIC_GREY, true, "cover")
	_add_box(b, Vector3(0.70, 0.04, 0.0), Vector3(0.24, 0.08, 0.20), COLOR_STEEL_DARK, true, "cover")
	_add_box(b, Vector3(0.70, 0.775, 0.0), Vector3(0.08, 1.30, 0.04), COLOR_GLASS_TINT, false, "detail", false)
	# Проход между антеннами свободен от коллизий!

static func _build_warehouse_pallet_stack(b: Array[Dictionary]) -> void:
	# 5 деревянных поддонов по 0.15м высотой
	for i in range(5):
		var y := 0.075 + float(i) * 0.15
		_add_box(b, Vector3(0.0, y, 0.0), Vector3(1.20, 0.14, 0.80), COLOR_WOOD_PALE, true, "cover")
		_add_box(b, Vector3(0.0, y + 0.06, 0.0), Vector3(1.18, 0.02, 0.78), COLOR_WOOD_VARNISH, false, "detail", false)

static func _build_pallet_jack(b: Array[Dictionary]) -> void:
	# Пара вил
	_add_box(b, Vector3(0.25, 0.10, 0.18), Vector3(1.15, 0.12, 0.16), COLOR_PLASTIC_RED, true, "cover")
	_add_box(b, Vector3(0.25, 0.10, -0.18), Vector3(1.15, 0.12, 0.16), COLOR_PLASTIC_RED, true, "cover")
	# Задний гидравлический узел
	_add_box(b, Vector3(-0.42, 0.28, 0.0), Vector3(0.35, 0.45, 0.42), COLOR_STEEL_DARK, true, "cover")
	# Вертикальное дышло / ручка управления
	_add_box(b, Vector3(-0.52, 0.72, 0.0), Vector3(0.08, 0.85, 0.08), COLOR_PLASTIC_RED, true, "cover")
	_add_box(b, Vector3(-0.52, 1.15, 0.0), Vector3(0.06, 0.06, 0.36), COLOR_STEEL_DARK, false, "detail")
	# Передние ролики
	_add_box(b, Vector3(0.75, 0.05, 0.18), Vector3(0.10, 0.10, 0.08), COLOR_STEEL_DARK, false, "detail", false)
	_add_box(b, Vector3(0.75, 0.05, -0.18), Vector3(0.10, 0.10, 0.08), COLOR_STEEL_DARK, false, "detail", false)

# ==============================================================================
# 2. MALL (Торговый центр)
# ==============================================================================

static func _build_mall_bench_modern(b: Array[Dictionary]) -> void:
	# Деревянный массив сиденья
	_add_box(b, Vector3(0.0, 0.42, 0.0), Vector3(2.00, 0.08, 0.65), COLOR_WOOD_VARNISH, true, "cover")
	# Стальные ножки
	_add_box(b, Vector3(-0.85, 0.19, 0.0), Vector3(0.10, 0.38, 0.60), COLOR_STEEL_DARK, true, "cover")
	_add_box(b, Vector3(0.85, 0.19, 0.0), Vector3(0.10, 0.38, 0.60), COLOR_STEEL_DARK, true, "cover")

static func _build_mall_planter_pot(b: Array[Dictionary]) -> void:
	# Бетонный вазон (круглосуточное прочное укрытие)
	_add_box(b, Vector3(0.0, 0.45, 0.0), Vector3(1.10, 0.90, 1.10), COLOR_STEEL_WHITE, true, "cover")
	_add_box(b, Vector3(0.0, 0.88, 0.0), Vector3(1.16, 0.06, 1.16), COLOR_PLASTIC_GREY, false, "detail")
	# Грунт
	_add_box(b, Vector3(0.0, 0.91, 0.0), Vector3(0.96, 0.04, 0.96), COLOR_STEEL_DARK, false, "detail", false)
	# Густой куст
	_add_box(b, Vector3(0.0, 1.20, 0.0), Vector3(0.95, 0.55, 0.95), COLOR_PLASTIC_GREEN, false, "foliage")

static func _build_mall_advertising_pillar(b: Array[Dictionary]) -> void:
	# Массивная база
	_add_box(b, Vector3(0.0, 0.08, 0.0), Vector3(0.92, 0.16, 0.38), COLOR_STEEL_DARK, true, "cover")
	# Вертикальный алюминиевый пилон
	_add_box(b, Vector3(0.0, 1.20, 0.0), Vector3(0.85, 2.20, 0.30), COLOR_STEEL_DARK, true, "cover")
	# Световые рекламные панели с обеих сторон
	_add_box(b, Vector3(0.0, 1.25, 0.16), Vector3(0.75, 1.75, 0.02), COLOR_GLASS_TINT, false, "detail")
	_add_box(b, Vector3(0.0, 1.25, -0.16), Vector3(0.75, 1.75, 0.02), COLOR_PLASTIC_RED, false, "detail")

static func _build_mall_escalator_segment(b: Array[Dictionary]) -> void:
	# Наклонная стальная рама эскалатора
	_add_box(b, Vector3(0.0, 0.65, 0.0), Vector3(3.40, 0.50, 1.15), COLOR_STEEL_DARK, true, "cover")
	# Ступени (наклонная ходовая часть)
	for s in range(5):
		var sx := -1.30 + float(s) * 0.65
		var sy := 0.35 + float(s) * 0.24
		_add_box(b, Vector3(sx, sy, 0.0), Vector3(0.60, 0.20, 0.85), COLOR_STEEL_CHROME, true, "stair")
	# Стеклянная балюстрада слева и справа
	_add_box(b, Vector3(0.0, 1.15, 0.52), Vector3(3.35, 0.75, 0.04), COLOR_GLASS_TINT, false, "glass")
	_add_box(b, Vector3(0.0, 1.15, -0.52), Vector3(3.35, 0.75, 0.04), COLOR_GLASS_TINT, false, "glass")
	# Чёрный резиновый поручень
	_add_box(b, Vector3(0.0, 1.55, 0.52), Vector3(3.40, 0.06, 0.08), COLOR_VINYL_BLACK, true, "handrail")
	_add_box(b, Vector3(0.0, 1.55, -0.52), Vector3(3.40, 0.06, 0.08), COLOR_VINYL_BLACK, true, "handrail")

static func _build_mall_trash_recycling(b: Array[Dictionary]) -> void:
	# Трёхсекционный корпус
	_add_box(b, Vector3(0.0, 0.46, 0.0), Vector3(1.20, 0.92, 0.45), COLOR_STEEL_DARK, true, "cover")
	# 3 верхних цветных кольца приёма отходов
	_add_box(b, Vector3(-0.38, 0.93, 0.0), Vector3(0.28, 0.04, 0.32), COLOR_PLASTIC_BLUE, false, "detail")
	_add_box(b, Vector3(0.0, 0.93, 0.0), Vector3(0.28, 0.04, 0.32), COLOR_PLASTIC_GREEN, false, "detail")
	_add_box(b, Vector3(0.38, 0.93, 0.0), Vector3(0.28, 0.04, 0.32), COLOR_PLASTIC_RED, false, "detail")

# ==============================================================================
# 3. HOSPITAL (Больница и клиника)
# ==============================================================================

static func _build_hospital_gurney_bed(b: Array[Dictionary]) -> void:
	# Металлическая рама каталки
	_add_box(b, Vector3(0.0, 0.40, 0.0), Vector3(1.95, 0.35, 0.75), COLOR_STEEL_CHROME, true, "cover")
	# Матрас из водостойкого медицинского винила
	_add_box(b, Vector3(-0.10, 0.68, 0.0), Vector3(1.50, 0.16, 0.80), COLOR_HOSPITAL_CYAN, true, "cover")
	# Приподнятый подголовник
	_add_box(b, Vector3(0.80, 0.76, 0.0), Vector3(0.45, 0.22, 0.80), COLOR_HOSPITAL_CYAN, true, "cover")
	# Защитные откидные боковые поручни
	_add_box(b, Vector3(0.0, 0.82, 0.42), Vector3(1.40, 0.18, 0.04), COLOR_STEEL_CHROME, false, "detail")
	_add_box(b, Vector3(0.0, 0.82, -0.42), Vector3(1.40, 0.18, 0.04), COLOR_STEEL_CHROME, false, "detail")
	# 4 медицинских колеса с тормозами
	_add_box(b, Vector3(0.80, 0.10, 0.32), Vector3(0.12, 0.20, 0.08), COLOR_STEEL_DARK, false, "wheel", false)
	_add_box(b, Vector3(0.80, 0.10, -0.32), Vector3(0.12, 0.20, 0.08), COLOR_STEEL_DARK, false, "wheel", false)
	_add_box(b, Vector3(-0.80, 0.10, 0.32), Vector3(0.12, 0.20, 0.08), COLOR_STEEL_DARK, false, "wheel", false)
	_add_box(b, Vector3(-0.80, 0.10, -0.32), Vector3(0.12, 0.20, 0.08), COLOR_STEEL_DARK, false, "wheel", false)

static func _build_iv_drip_stand(b: Array[Dictionary]) -> void:
	# 5-лучевая крестовина на полу
	_add_box(b, Vector3(0.0, 0.06, 0.0), Vector3(0.55, 0.06, 0.55), COLOR_STEEL_CHROME, true, "cover")
	# Тонкая хромированная телескопическая стойка
	_add_box(b, Vector3(0.0, 0.95, 0.0), Vector3(0.06, 1.80, 0.06), COLOR_STEEL_CHROME, true, "cover")
	# Рожки-крючки наверху
	_add_box(b, Vector3(0.0, 1.82, 0.0), Vector3(0.32, 0.04, 0.04), COLOR_STEEL_CHROME, false, "detail", false)
	# 2 флакона с физраствором
	_add_box(b, Vector3(0.12, 1.70, 0.0), Vector3(0.10, 0.22, 0.10), COLOR_GLASS_TINT, false, "detail", false)
	_add_box(b, Vector3(-0.12, 1.70, 0.0), Vector3(0.10, 0.22, 0.10), COLOR_GLASS_TINT, false, "detail", false)

static func _build_operating_table(b: Array[Dictionary]) -> void:
	# Тяжёлая центральная гидравлическая колонна
	_add_box(b, Vector3(0.0, 0.38, 0.0), Vector3(0.65, 0.76, 0.55), COLOR_STEEL_DARK, true, "cover")
	_add_box(b, Vector3(0.0, 0.04, 0.0), Vector3(1.10, 0.08, 0.75), COLOR_STEEL_CHROME, true, "cover")
	# Секционная столешница хирургического стола
	_add_box(b, Vector3(0.0, 0.86, 0.0), Vector3(2.15, 0.16, 0.85), COLOR_VINYL_BLACK, true, "cover")
	# Подлокотники
	_add_box(b, Vector3(0.15, 0.84, 0.52), Vector3(0.65, 0.08, 0.18), COLOR_VINYL_BLACK, false, "detail")
	_add_box(b, Vector3(0.15, 0.84, -0.52), Vector3(0.65, 0.08, 0.18), COLOR_VINYL_BLACK, false, "detail")
	# Стойка бестеневой хирургической лампы
	_add_box(b, Vector3(-0.85, 1.45, -0.42), Vector3(0.06, 1.15, 0.06), COLOR_STEEL_WHITE, false, "lamp_pole")
	# Купол лампы
	_add_box(b, Vector3(-0.35, 1.95, -0.15), Vector3(0.65, 0.15, 0.65), COLOR_STEEL_WHITE, false, "lamp_dome")
	_add_box(b, Vector3(-0.35, 1.86, -0.15), Vector3(0.55, 0.04, 0.55), COLOR_GLASS_TINT, false, "lamp_bulb", false)

static func _build_medical_screen_divider(b: Array[Dictionary]) -> void:
	# 3 секции ширмы, слегка сложенные зигзагом
	# Секция 1 (центр)
	_add_box(b, Vector3(0.0, 0.88, 0.0), Vector3(0.68, 1.65, 0.04), COLOR_FABRIC_SCREEN, true, "cover")
	_add_box(b, Vector3(0.0, 0.04, 0.0), Vector3(0.10, 0.08, 0.32), COLOR_STEEL_WHITE, true, "cover")
	# Секция 2 (слева, под углом)
	_add_box(b, Vector3(-0.65, 0.88, 0.12), Vector3(0.65, 1.65, 0.04), COLOR_FABRIC_SCREEN, true, "cover")
	_add_box(b, Vector3(-0.95, 0.04, 0.18), Vector3(0.10, 0.08, 0.32), COLOR_STEEL_WHITE, true, "cover")
	# Секция 3 (справа, под углом)
	_add_box(b, Vector3(0.65, 0.88, -0.12), Vector3(0.65, 1.65, 0.04), COLOR_FABRIC_SCREEN, true, "cover")
	_add_box(b, Vector3(0.95, 0.04, -0.18), Vector3(0.10, 0.08, 0.32), COLOR_STEEL_WHITE, true, "cover")

static func _build_medicine_glass_cabinet(b: Array[Dictionary]) -> void:
	# Белый стальной шкаф
	_add_box(b, Vector3(0.0, 0.925, 0.0), Vector3(0.95, 1.85, 0.45), COLOR_HOSPITAL_WHITE, true, "cover")
	# Стеклянные фасады
	_add_box(b, Vector3(0.0, 1.15, 0.23), Vector3(0.85, 1.15, 0.02), COLOR_GLASS_TINT, false, "glass")
	# 3 стеклянные полки внутри
	_add_box(b, Vector3(0.0, 0.85, 0.0), Vector3(0.88, 0.02, 0.38), COLOR_GLASS_TINT, false, "shelf", false)
	_add_box(b, Vector3(0.0, 1.20, 0.0), Vector3(0.88, 0.02, 0.38), COLOR_GLASS_TINT, false, "shelf", false)
	_add_box(b, Vector3(0.0, 1.55, 0.0), Vector3(0.88, 0.02, 0.38), COLOR_GLASS_TINT, false, "shelf", false)
	# Упаковки медикаментов
	_add_box(b, Vector3(-0.25, 0.92, 0.05), Vector3(0.30, 0.12, 0.22), COLOR_PLASTIC_BLUE, false, "detail", false)
	_add_box(b, Vector3(0.25, 1.28, 0.05), Vector3(0.28, 0.14, 0.20), COLOR_PLASTIC_RED, false, "detail", false)

static func _build_oxygen_tank_cart(b: Array[Dictionary]) -> void:
	# Рама тележки
	_add_box(b, Vector3(0.0, 0.55, 0.0), Vector3(0.60, 0.90, 0.45), COLOR_STEEL_DARK, true, "cover")
	# 2 высоких зелёных кислородных баллона
	_add_box(b, Vector3(-0.16, 0.72, 0.0), Vector3(0.24, 1.35, 0.24), COLOR_PLASTIC_GREEN, true, "cover")
	_add_box(b, Vector3(0.16, 0.72, 0.0), Vector3(0.24, 1.35, 0.24), COLOR_PLASTIC_GREEN, true, "cover")
	# Латунные редукторы и манометры
	_add_box(b, Vector3(-0.16, 1.45, 0.0), Vector3(0.10, 0.12, 0.12), COLOR_STEEL_CHROME, false, "detail", false)
	_add_box(b, Vector3(0.16, 1.45, 0.0), Vector3(0.10, 0.12, 0.12), COLOR_STEEL_CHROME, false, "detail", false)
	# Колёса
	_add_box(b, Vector3(-0.28, 0.10, 0.15), Vector3(0.08, 0.20, 0.20), COLOR_STEEL_DARK, false, "wheel", false)
	_add_box(b, Vector3(0.28, 0.10, 0.15), Vector3(0.08, 0.20, 0.20), COLOR_STEEL_DARK, false, "wheel", false)

static func _build_hospital_wheelchair(b: Array[Dictionary]) -> void:
	# Сиденье и спинка из синего/серого винила
	_add_box(b, Vector3(0.0, 0.48, -0.05), Vector3(0.55, 0.08, 0.50), COLOR_HOSPITAL_CYAN, true, "cover")
	_add_box(b, Vector3(0.0, 0.75, -0.28), Vector3(0.55, 0.48, 0.06), COLOR_HOSPITAL_CYAN, true, "cover")
	# Большие боковые колёса
	_add_box(b, Vector3(0.33, 0.35, -0.10), Vector3(0.06, 0.70, 0.70), COLOR_STEEL_CHROME, true, "cover")
	_add_box(b, Vector3(-0.33, 0.35, -0.10), Vector3(0.06, 0.70, 0.70), COLOR_STEEL_CHROME, true, "cover")
	# Подлокотники
	_add_box(b, Vector3(0.30, 0.65, -0.05), Vector3(0.06, 0.06, 0.42), COLOR_STEEL_DARK, false, "detail")
	_add_box(b, Vector3(-0.30, 0.65, -0.05), Vector3(0.06, 0.06, 0.42), COLOR_STEEL_DARK, false, "detail")
	# Подножки
	_add_box(b, Vector3(0.0, 0.15, 0.32), Vector3(0.48, 0.04, 0.20), COLOR_STEEL_DARK, false, "detail", false)

static func _build_hospital_reception_desk(b: Array[Dictionary]) -> void:
	# Главный фронтальный прилавок
	_add_box(b, Vector3(0.0, 0.575, 0.0), Vector3(2.40, 1.15, 0.70), COLOR_HOSPITAL_WHITE, true, "cover")
	# Столешница верхняя (полка для документов)
	_add_box(b, Vector3(0.0, 1.16, 0.0), Vector3(2.44, 0.05, 0.74), COLOR_HOSPITAL_CYAN, true, "cover")
	# Рабочая столешница для медсестры (пониженная изнутри Y=0.76)
	_add_box(b, Vector3(0.0, 0.76, -0.35), Vector3(2.20, 0.04, 0.50), COLOR_WOOD_PALE, false, "desk")
	# Монитор компьютера
	_add_box(b, Vector3(0.40, 0.95, -0.30), Vector3(0.35, 0.28, 0.08), COLOR_STEEL_DARK, false, "detail")

# ==============================================================================
# 4. SCHOOL (Школа и гимнастический зал)
# ==============================================================================

static func _build_school_desk_double(b: Array[Dictionary]) -> void:
	# Столешница парты с лёгким наклоном
	_add_box(b, Vector3(0.0, 0.74, 0.0), Vector3(1.20, 0.04, 0.55), COLOR_WOOD_PALE, true, "cover")
	# Металлокаркас ножек стола
	_add_box(b, Vector3(-0.55, 0.36, 0.0), Vector3(0.06, 0.70, 0.48), COLOR_PLASTIC_GREEN, true, "cover")
	_add_box(b, Vector3(0.55, 0.36, 0.0), Vector3(0.06, 0.70, 0.48), COLOR_PLASTIC_GREEN, true, "cover")
	# Передний защитный экран
	_add_box(b, Vector3(0.0, 0.52, -0.24), Vector3(1.10, 0.35, 0.03), COLOR_WOOD_PALE, false, "detail")
	# Две присоединённые скамьи/стула
	_add_box(b, Vector3(-0.32, 0.44, 0.52), Vector3(0.42, 0.04, 0.38), COLOR_WOOD_PALE, true, "cover")
	_add_box(b, Vector3(-0.32, 0.68, 0.70), Vector3(0.42, 0.20, 0.04), COLOR_WOOD_PALE, false, "detail")
	_add_box(b, Vector3(0.32, 0.44, 0.52), Vector3(0.42, 0.04, 0.38), COLOR_WOOD_PALE, true, "cover")
	_add_box(b, Vector3(0.32, 0.68, 0.70), Vector3(0.42, 0.20, 0.04), COLOR_WOOD_PALE, false, "detail")

static func _build_school_teacher_desk(b: Array[Dictionary]) -> void:
	# Столешница
	_add_box(b, Vector3(0.0, 0.76, 0.0), Vector3(1.40, 0.05, 0.75), COLOR_WOOD_VARNISH, true, "cover")
	# Правая тумба с 3 ящиками
	_add_box(b, Vector3(0.45, 0.37, 0.0), Vector3(0.42, 0.72, 0.68), COLOR_WOOD_VARNISH, true, "cover")
	# Левая боковая опора
	_add_box(b, Vector3(-0.64, 0.37, 0.0), Vector3(0.06, 0.72, 0.68), COLOR_WOOD_VARNISH, true, "cover")
	# Задний экран под столом
	_add_box(b, Vector3(-0.10, 0.45, -0.32), Vector3(1.05, 0.50, 0.04), COLOR_WOOD_VARNISH, false, "detail")

static func _build_school_blackboard(b: Array[Dictionary]) -> void:
	# Центральная часть меловой доски
	_add_box(b, Vector3(0.0, 0.70, 0.0), Vector3(1.60, 1.20, 0.04), COLOR_BLACKBOARD_GREEN, true, "cover")
	# Левая раскрывающаяся створка
	_add_box(b, Vector3(-1.10, 0.70, 0.04), Vector3(0.60, 1.20, 0.03), COLOR_BLACKBOARD_GREEN, true, "cover")
	# Правая раскрывающаяся створка
	_add_box(b, Vector3(1.10, 0.70, 0.04), Vector3(0.60, 1.20, 0.03), COLOR_BLACKBOARD_GREEN, true, "cover")
	# Деревянная рамка и лоток для мела
	_add_box(b, Vector3(0.0, 0.06, 0.03), Vector3(2.80, 0.04, 0.08), COLOR_WOOD_VARNISH, false, "detail")

static func _build_school_hallway_lockers(b: Array[Dictionary]) -> void:
	# Блок из 4 металлических шкафчиков
	_add_box(b, Vector3(0.0, 0.925, 0.0), Vector3(1.40, 1.85, 0.55), COLOR_PLASTIC_BLUE, true, "cover")
	# Цоколь
	_add_box(b, Vector3(0.0, 0.05, 0.0), Vector3(1.40, 0.10, 0.55), COLOR_STEEL_DARK, true, "cover")
	# 4 дверцы с вентиляционными жалюзи
	for d in range(4):
		var dx := -0.525 + float(d) * 0.35
		_add_box(b, Vector3(dx, 0.95, 0.28), Vector3(0.33, 1.65, 0.02), COLOR_STEEL_WHITE, false, "detail", false)
		_add_box(b, Vector3(dx, 1.60, 0.29), Vector3(0.24, 0.12, 0.01), COLOR_STEEL_DARK, false, "detail", false)
		_add_box(b, Vector3(dx + 0.12, 1.05, 0.30), Vector3(0.04, 0.06, 0.02), COLOR_STEEL_CHROME, false, "handle", false)

static func _build_school_gym_vault_box(b: Array[Dictionary]) -> void:
	# Деревянное трапециевидное основание (3 яруса)
	_add_box(b, Vector3(0.0, 0.18, 0.0), Vector3(1.30, 0.34, 0.75), COLOR_WOOD_VARNISH, true, "cover")
	_add_box(b, Vector3(0.0, 0.50, 0.0), Vector3(1.24, 0.32, 0.68), COLOR_WOOD_VARNISH, true, "cover")
	_add_box(b, Vector3(0.0, 0.80, 0.0), Vector3(1.18, 0.30, 0.62), COLOR_WOOD_VARNISH, true, "cover")
	# Верхняя подушка из толстой коричневой кожи
	_add_box(b, Vector3(0.0, 1.00, 0.0), Vector3(1.22, 0.14, 0.64), COLOR_LEATHER_BROWN, true, "cover")

static func _build_school_gym_bench(b: Array[Dictionary]) -> void:
	# Длинная деревянная пласть
	_add_box(b, Vector3(0.0, 0.40, 0.0), Vector3(2.80, 0.05, 0.38), COLOR_WOOD_VARNISH, true, "cover")
	# 3 Т-образные ножки со связью
	_add_box(b, Vector3(-1.15, 0.18, 0.0), Vector3(0.08, 0.36, 0.36), COLOR_PLASTIC_GREEN, true, "cover")
	_add_box(b, Vector3(0.0, 0.18, 0.0), Vector3(0.08, 0.36, 0.36), COLOR_PLASTIC_GREEN, true, "cover")
	_add_box(b, Vector3(1.15, 0.18, 0.0), Vector3(0.08, 0.36, 0.36), COLOR_PLASTIC_GREEN, true, "cover")
	# Продольный деревянный брус снизу (перекладина для гимнастических упражнений)
	_add_box(b, Vector3(0.0, 0.12, 0.0), Vector3(2.70, 0.08, 0.08), COLOR_WOOD_PALE, false, "detail", false)

# ==============================================================================
# 5. PUBLIC SAFETY (Безопасность и общие холлы)
# ==============================================================================

static func _build_fire_hose_cabinet(b: Array[Dictionary]) -> void:
	# Настенный красный металлический шкаф
	_add_box(b, Vector3(0.0, 0.475, 0.0), Vector3(0.75, 0.95, 0.28), COLOR_FIRE_RED, true, "cover")
	# Смотровое окошко
	_add_box(b, Vector3(0.0, 0.55, 0.15), Vector3(0.55, 0.55, 0.02), COLOR_GLASS_TINT, false, "glass")
	# Свернутый пожарный рукав
	_add_box(b, Vector3(0.0, 0.55, 0.05), Vector3(0.42, 0.42, 0.12), COLOR_STEEL_WHITE, false, "hose", false)
	# Углекислотный огнетушитель
	_add_box(b, Vector3(0.20, 0.40, 0.05), Vector3(0.12, 0.40, 0.12), COLOR_FIRE_RED, false, "detail", false)

static func _build_water_dispenser_cooler(b: Array[Dictionary]) -> void:
	# Корпус кулера
	_add_box(b, Vector3(0.0, 0.48, 0.0), Vector3(0.40, 0.96, 0.40), COLOR_STEEL_WHITE, true, "cover")
	# Ниша для стаканчиков с кранами
	_add_box(b, Vector3(0.0, 0.65, 0.12), Vector3(0.28, 0.30, 0.18), COLOR_STEEL_DARK, false, "niche")
	# Красный и синий краники
	_add_box(b, Vector3(-0.06, 0.72, 0.14), Vector3(0.04, 0.06, 0.04), COLOR_PLASTIC_RED, false, "detail", false)
	_add_box(b, Vector3(0.06, 0.72, 0.14), Vector3(0.04, 0.06, 0.04), COLOR_PLASTIC_BLUE, false, "detail", false)
	# 19-литровая полупрозрачная бутыль сверху
	_add_box(b, Vector3(0.0, 1.15, 0.0), Vector3(0.32, 0.40, 0.32), COLOR_BOTTLE_BLUE, true, "cover")
