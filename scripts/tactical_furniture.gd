extends RefCounted
class_name FRONTLINETacticalFurniture

## Отдельный процедурный пак мебели для домов FRONTLINE.
## Стиль: простые low-poly формы, потёртое дерево, выцветшая краска и эмаль.
## Набор автономный: он не меняет карты или сцены и может использоваться отдельно.
## Локальные координаты: перед мебели направлен по -Z, низ предмета стоит на Y=0.

const COLOR_WOOD_DARK := Color(0.24, 0.17, 0.12)
const COLOR_WOOD := Color(0.38, 0.27, 0.18)
const COLOR_WOOD_WORN := Color(0.48, 0.35, 0.23)
const COLOR_PAINT_GREEN := Color(0.28, 0.32, 0.25)
const COLOR_PAINT_BLUE := Color(0.30, 0.35, 0.37)
const COLOR_FABRIC := Color(0.35, 0.34, 0.29)
const COLOR_FABRIC_LIGHT := Color(0.49, 0.45, 0.37)
const COLOR_ENAMEL := Color(0.68, 0.66, 0.58)
const COLOR_PORCELAIN := Color(0.72, 0.70, 0.63)
const COLOR_METAL := Color(0.26, 0.28, 0.27)
const COLOR_METAL_WORN := Color(0.39, 0.37, 0.32)

static func get_available_types() -> Array[String]:
	return [
		"dining_table", "writing_desk", "dining_chair", "wooden_bench",
		"single_bed", "double_bed", "wardrobe", "bedside_cabinet",
		"dresser", "bookcase", "sofa", "kitchen_cabinet",
		"sink", "toilet", "wood_stove", "radiator"
	]

static func get_furniture_info(type_name: String) -> Dictionary:
	match type_name:
		"dining_table":
			return _info("Обеденный стол", "Стол из тёмных досок с четырьмя точёными ножками.", Vector3(1.40, 0.78, 0.80), "гостиная")
		"writing_desk":
			return _info("Письменный стол", "Потёртый рабочий стол с выдвижными ящиками.", Vector3(1.25, 0.78, 0.68), "кабинет")
		"dining_chair":
			return _info("Деревянный стул", "Простой кухонный стул с планочной спинкой.", Vector3(0.48, 0.92, 0.48), "гостиная")
		"wooden_bench":
			return _info("Лавка", "Грубая длинная лавка из широких досок.", Vector3(1.30, 0.48, 0.42), "гостиная")
		"single_bed":
			return _info("Односпальная кровать", "Кровать с деревянной рамой, матрасом и подушкой.", Vector3(0.96, 0.78, 2.05), "спальня")
		"double_bed":
			return _info("Двуспальная кровать", "Широкая кровать с парой подушек и простым изголовьем.", Vector3(1.56, 0.78, 2.05), "спальня")
		"wardrobe":
			return _info("Шкаф", "Двухдверный деревянный шкаф с ручками.", Vector3(1.25, 2.05, 0.58), "спальня")
		"bedside_cabinet":
			return _info("Прикроватная тумбочка", "Компактная тумба с двумя ящиками.", Vector3(0.54, 0.62, 0.45), "спальня")
		"dresser":
			return _info("Комод", "Низкий комод с тремя широкими ящиками.", Vector3(0.95, 0.90, 0.48), "спальня")
		"bookcase":
			return _info("Книжный шкаф", "Открытый шкаф с полками и несколькими старыми книгами.", Vector3(0.92, 1.75, 0.34), "кабинет")
		"sofa":
			return _info("Диван", "Потёртый двухместный диван с тканевыми подушками.", Vector3(1.90, 0.92, 0.78), "гостиная")
		"kitchen_cabinet":
			return _info("Кухонный шкаф", "Низкий кухонный шкаф с дверцами и столешницей.", Vector3(1.10, 0.88, 0.55), "кухня")
		"sink":
			return _info("Умывальник", "Эмалированная раковина на металлической стойке с краном.", Vector3(0.62, 0.88, 0.52), "санузел")
		"toilet":
			return _info("Туалет", "Старый напольный унитаз с бачком и сиденьем.", Vector3(0.42, 0.82, 0.68), "санузел")
		"wood_stove":
			return _info("Печь-буржуйка", "Небольшая чугунная печь с дверцей и дымоходом.", Vector3(0.72, 1.48, 0.66), "кухня")
		"radiator":
			return _info("Радиатор", "Старый секционный радиатор отопления.", Vector3(0.86, 0.62, 0.18), "любая комната")
		_:
			return {}

## Возвращает составные части предмета в формате, близком к tactical_buildings.gd.
## Каждая часть содержит центр, габариты, материал, тип меша и флаг коллизии.
static func get_furniture_boxes(type_name: String, origin: Vector3 = Vector3.ZERO, rot_deg: float = 0.0) -> Array[Dictionary]:
	var local_parts: Array[Dictionary] = []
	match type_name:
		"dining_table":
			_build_table(local_parts, false)
		"writing_desk":
			_build_table(local_parts, true)
		"dining_chair":
			_build_chair(local_parts)
		"wooden_bench":
			_build_bench(local_parts)
		"single_bed":
			_build_bed(local_parts, 0.96)
		"double_bed":
			_build_bed(local_parts, 1.56)
		"wardrobe":
			_build_wardrobe(local_parts)
		"bedside_cabinet":
			_build_drawer_unit(local_parts, 0.54, 0.62, true)
		"dresser":
			_build_drawer_unit(local_parts, 0.95, 0.90, false)
		"bookcase":
			_build_bookcase(local_parts)
		"sofa":
			_build_sofa(local_parts)
		"kitchen_cabinet":
			_build_kitchen_cabinet(local_parts)
		"sink":
			_build_sink(local_parts)
		"toilet":
			_build_toilet(local_parts)
		"wood_stove":
			_build_stove(local_parts)
		"radiator":
			_build_radiator(local_parts)
		_:
			return []

	var out: Array[Dictionary] = []
	var rad := deg_to_rad(rot_deg)
	var cos_a := cos(rad)
	var sin_a := sin(rad)
	var quarter_turn := is_equal_approx(absf(sin_a), 1.0)
	for part in local_parts:
		var local_pos: Vector3 = part.pos
		var size: Vector3 = part.size
		var world_pos := Vector3(
			origin.x + local_pos.x * cos_a - local_pos.z * sin_a,
			origin.y + local_pos.y,
			origin.z + local_pos.x * sin_a + local_pos.z * cos_a
		)
		if quarter_turn and part.shape == "box":
			size = Vector3(size.z, size.y, size.x)
		var transformed := part.duplicate()
		transformed.pos = world_pos
		transformed.size = size
		out.append(transformed)
	return out

## Создаёт готовую отдельную Node3D с простой статической коллизией.
## Предмет можно поставить в сцену и повернуть вокруг вертикальной оси.
static func create_furniture_node(type_name: String, rot_deg: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = type_name.capitalize().replace("_", "")
	var parts := get_furniture_boxes(type_name)
	if parts.is_empty():
		return root

	var body := StaticBody3D.new()
	body.name = "FurnitureCollision"
	root.add_child(body)
	var materials: Dictionary = {}
	for part in parts:
		var pos: Vector3 = part.pos
		var size: Vector3 = part.size
		var color: Color = part.color
		if not materials.has(color):
			var material := StandardMaterial3D.new()
			material.albedo_color = color
			material.roughness = 0.92
			materials[color] = material

		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = _make_mesh(part.shape, size)
		mesh_instance.material_override = materials[color]
		mesh_instance.position = pos
		if not bool(part.get("cast_shadow", true)):
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mesh_instance)

		if bool(part.get("solid", true)):
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = size
			collision.shape = shape
			collision.position = pos
			body.add_child(collision)

	root.rotation_degrees.y = rot_deg
	return root

static func _info(display_name: String, description: String, dimensions: Vector3, room: String) -> Dictionary:
	return {
		"name": display_name,
		"description": description,
		"size": dimensions,
		"room": room,
		"style": "FRONTLINE low-poly / worn interior"
	}

static func _make_mesh(shape_name: String, size: Vector3) -> Mesh:
	match shape_name:
		"cylinder":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = minf(size.x, size.z) * 0.5
			cylinder.bottom_radius = minf(size.x, size.z) * 0.5
			cylinder.height = size.y
			cylinder.radial_segments = 8
			return cylinder
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 10
			sphere.rings = 5
			return sphere
		_:
			var box := BoxMesh.new()
			box.size = size
			return box

static func _piece(out: Array[Dictionary], pos: Vector3, size: Vector3, color: Color, kind: String, shape: String = "box", solid: bool = true, cast_shadow: bool = true) -> void:
	out.append({
		"pos": pos,
		"size": size,
		"color": color,
		"kind": kind,
		"shape": shape,
		"solid": solid,
		"cast_shadow": cast_shadow
	})

static func _build_table(out: Array[Dictionary], with_drawers: bool) -> void:
	var top_size := Vector3(1.25, 0.07, 0.68) if with_drawers else Vector3(1.40, 0.07, 0.80)
	var leg_x := 0.55 if with_drawers else 0.62
	var leg_z := 0.27 if with_drawers else 0.32
	_piece(out, Vector3(0, 0.745, 0), top_size, COLOR_WOOD_WORN, "table_top")
	for x in [-leg_x, leg_x]:
		for z in [-leg_z, leg_z]:
			_piece(out, Vector3(x, 0.36, z), Vector3(0.085, 0.70, 0.085), COLOR_WOOD_DARK, "table_leg", "cylinder")
	_piece(out, Vector3(0, 0.60, -leg_z), Vector3(leg_x * 1.8, 0.14, 0.06), COLOR_WOOD, "table_apron")
	_piece(out, Vector3(0, 0.60, leg_z), Vector3(leg_x * 1.8, 0.14, 0.06), COLOR_WOOD, "table_apron")
	_piece(out, Vector3(-leg_x, 0.60, 0), Vector3(0.06, 0.14, leg_z * 1.8), COLOR_WOOD, "table_apron")
	_piece(out, Vector3(leg_x, 0.60, 0), Vector3(0.06, 0.14, leg_z * 1.8), COLOR_WOOD, "table_apron")
	if with_drawers:
		_piece(out, Vector3(0, 0.54, -0.29), Vector3(0.46, 0.18, 0.045), COLOR_WOOD_WORN, "desk_drawer")
		_piece(out, Vector3(0, 0.54, -0.315), Vector3(0.055, 0.025, 0.025), COLOR_METAL_WORN, "drawer_handle", "box", false, false)

static func _build_chair(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(0, 0.47, 0.02), Vector3(0.48, 0.08, 0.44), COLOR_WOOD_WORN, "chair_seat")
	for x in [-0.18, 0.18]:
		for z in [-0.15, 0.18]:
			_piece(out, Vector3(x, 0.23, z), Vector3(0.065, 0.44, 0.065), COLOR_WOOD_DARK, "chair_leg")
	for x in [-0.18, 0.18]:
		_piece(out, Vector3(x, 0.78, 0.20), Vector3(0.07, 0.82, 0.07), COLOR_WOOD_DARK, "chair_back_post")
	for y in [0.62, 0.79, 0.96]:
		_piece(out, Vector3(0, y, 0.20), Vector3(0.39, 0.09, 0.065), COLOR_WOOD_WORN, "chair_back_slats")

static func _build_bench(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(0, 0.43, 0), Vector3(1.30, 0.09, 0.42), COLOR_WOOD_WORN, "bench_seat")
	for x in [-0.48, 0.48]:
		_piece(out, Vector3(x, 0.22, 0), Vector3(0.09, 0.40, 0.38), COLOR_WOOD_DARK, "bench_support")
	_piece(out, Vector3(0, 0.19, 0), Vector3(1.05, 0.07, 0.07), COLOR_WOOD_DARK, "bench_brace")

static func _build_bed(out: Array[Dictionary], width: float) -> void:
	var half_w := width * 0.5
	var mattress_z := 0.18
	_piece(out, Vector3(0, 0.43, 0.10), Vector3(width - 0.10, 0.18, 1.86), COLOR_FABRIC, "mattress")
	_piece(out, Vector3(0, 0.535, -0.48), Vector3(width * 0.34, 0.10, 0.36), COLOR_FABRIC_LIGHT, "pillow")
	if width > 1.0:
		_piece(out, Vector3(-width * 0.22, 0.535, -0.48), Vector3(width * 0.28, 0.10, 0.34), COLOR_FABRIC_LIGHT, "pillow")
	_piece(out, Vector3(0, 0.31, mattress_z), Vector3(width + 0.10, 0.12, 1.98), COLOR_WOOD, "bed_frame")
	for x in [-half_w + 0.06, half_w - 0.06]:
		for z in [-0.78, 0.88]:
			_piece(out, Vector3(x, 0.15, z), Vector3(0.09, 0.30, 0.09), COLOR_WOOD_DARK, "bed_leg")
	_piece(out, Vector3(0, 0.61, -0.92), Vector3(width + 0.10, 0.72, 0.10), COLOR_WOOD_WORN, "bed_headboard")
	_piece(out, Vector3(0, 0.47, 1.10), Vector3(width + 0.10, 0.40, 0.10), COLOR_WOOD, "bed_footboard")

static func _build_wardrobe(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(-0.60, 1.02, 0), Vector3(0.06, 2.00, 0.56), COLOR_WOOD_DARK, "wardrobe_side")
	_piece(out, Vector3(0.60, 1.02, 0), Vector3(0.06, 2.00, 0.56), COLOR_WOOD_DARK, "wardrobe_side")
	_piece(out, Vector3(0, 1.02, 0.25), Vector3(1.16, 2.00, 0.06), COLOR_WOOD, "wardrobe_back")
	_piece(out, Vector3(0, 2.02, 0), Vector3(1.25, 0.08, 0.58), COLOR_WOOD_WORN, "wardrobe_top")
	_piece(out, Vector3(0, 0.07, 0), Vector3(1.20, 0.12, 0.56), COLOR_WOOD_DARK, "wardrobe_base")
	_piece(out, Vector3(-0.29, 1.03, -0.285), Vector3(0.56, 1.82, 0.055), COLOR_WOOD_WORN, "wardrobe_door")
	_piece(out, Vector3(0.29, 1.03, -0.285), Vector3(0.56, 1.82, 0.055), COLOR_WOOD_WORN, "wardrobe_door")
	for x in [-0.07, 0.07]:
		_piece(out, Vector3(x, 1.03, -0.326), Vector3(0.035, 0.13, 0.035), COLOR_METAL_WORN, "wardrobe_handle", "cylinder", false, false)

static func _build_drawer_unit(out: Array[Dictionary], width: float, height: float, bedside: bool) -> void:
	var depth := 0.45 if bedside else 0.48
	_piece(out, Vector3(0, height * 0.5, 0), Vector3(width - 0.08, height - 0.08, depth - 0.06), COLOR_WOOD_DARK, "cabinet_body")
	_piece(out, Vector3(0, height - 0.03, 0), Vector3(width, 0.06, depth), COLOR_WOOD_WORN, "cabinet_top")
	var drawer_count := 2 if bedside else 3
	for index in range(drawer_count):
		var drawer_y := height * (float(index) + 0.5) / float(drawer_count)
		var drawer_h := height / float(drawer_count) - 0.035
		_piece(out, Vector3(0, drawer_y, -depth * 0.5 - 0.006), Vector3(width - 0.12, drawer_h, 0.045), COLOR_WOOD_WORN, "drawer_front")
		_piece(out, Vector3(0, drawer_y, -depth * 0.5 - 0.034), Vector3(0.11, 0.035, 0.035), COLOR_METAL_WORN, "drawer_handle", "cylinder", false, false)
	for x in [-width * 0.37, width * 0.37]:
		_piece(out, Vector3(x, 0.08, 0), Vector3(0.07, 0.16, 0.08), COLOR_WOOD_DARK, "cabinet_foot")

static func _build_bookcase(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(-0.43, 0.87, 0), Vector3(0.07, 1.72, 0.32), COLOR_WOOD_DARK, "bookcase_side")
	_piece(out, Vector3(0.43, 0.87, 0), Vector3(0.07, 1.72, 0.32), COLOR_WOOD_DARK, "bookcase_side")
	_piece(out, Vector3(0, 0.87, 0.14), Vector3(0.80, 1.72, 0.05), COLOR_WOOD, "bookcase_back")
	for y in [0.06, 0.48, 0.90, 1.32, 1.72]:
		_piece(out, Vector3(0, y, -0.01), Vector3(0.86, 0.06, 0.32), COLOR_WOOD_WORN, "bookcase_shelf")
	for shelf_y in [0.30, 0.72, 1.14, 1.54]:
		_piece(out, Vector3(-0.20, shelf_y, -0.07), Vector3(0.12, 0.25, 0.17), COLOR_PAINT_GREEN, "book", "box", false, false)
		_piece(out, Vector3(-0.05, shelf_y + 0.015, -0.07), Vector3(0.12, 0.28, 0.17), COLOR_WOOD_WORN, "book", "box", false, false)
		_piece(out, Vector3(0.17, shelf_y, -0.07), Vector3(0.18, 0.23, 0.17), COLOR_PAINT_BLUE, "book", "box", false, false)

static func _build_sofa(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(0, 0.34, 0.04), Vector3(1.68, 0.42, 0.66), COLOR_WOOD_DARK, "sofa_base")
	_piece(out, Vector3(0, 0.77, 0.29), Vector3(1.72, 0.48, 0.16), COLOR_FABRIC, "sofa_back")
	_piece(out, Vector3(-0.87, 0.55, 0), Vector3(0.16, 0.58, 0.78), COLOR_FABRIC, "sofa_arm")
	_piece(out, Vector3(0.87, 0.55, 0), Vector3(0.16, 0.58, 0.78), COLOR_FABRIC, "sofa_arm")
	_piece(out, Vector3(-0.43, 0.57, -0.04), Vector3(0.78, 0.18, 0.56), COLOR_FABRIC_LIGHT, "sofa_cushion")
	_piece(out, Vector3(0.43, 0.57, -0.04), Vector3(0.78, 0.18, 0.56), COLOR_FABRIC_LIGHT, "sofa_cushion")
	for x in [-0.72, 0.72]:
		_piece(out, Vector3(x, 0.10, 0.22), Vector3(0.10, 0.20, 0.10), COLOR_WOOD_DARK, "sofa_leg")

static func _build_kitchen_cabinet(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(0, 0.41, 0), Vector3(1.02, 0.76, 0.50), COLOR_PAINT_GREEN, "kitchen_cabinet_body")
	_piece(out, Vector3(0, 0.84, 0), Vector3(1.10, 0.08, 0.55), COLOR_WOOD_WORN, "kitchen_counter")
	for x in [-0.26, 0.26]:
		_piece(out, Vector3(x, 0.43, -0.257), Vector3(0.46, 0.66, 0.045), COLOR_PAINT_BLUE, "kitchen_door")
		_piece(out, Vector3(x + 0.16, 0.43, -0.29), Vector3(0.025, 0.11, 0.025), COLOR_METAL_WORN, "kitchen_handle", "cylinder", false, false)
	for x in [-0.42, 0.42]:
		_piece(out, Vector3(x, 0.08, 0.18), Vector3(0.08, 0.16, 0.08), COLOR_WOOD_DARK, "kitchen_foot")

static func _build_sink(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(0, 0.47, 0), Vector3(0.52, 0.72, 0.42), COLOR_METAL_WORN, "sink_pedestal")
	_piece(out, Vector3(0, 0.83, 0), Vector3(0.62, 0.10, 0.52), COLOR_PORCELAIN, "sink_rim")
	_piece(out, Vector3(0, 0.82, 0.035), Vector3(0.42, 0.12, 0.32), COLOR_ENAMEL, "sink_basin", "sphere")
	_piece(out, Vector3(0.15, 0.99, 0.15), Vector3(0.045, 0.25, 0.045), COLOR_METAL, "faucet", "cylinder", false, false)
	_piece(out, Vector3(0.08, 1.10, 0.15), Vector3(0.18, 0.045, 0.045), COLOR_METAL, "faucet_spout", "cylinder", false, false)

static func _build_toilet(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(0, 0.20, 0.10), Vector3(0.32, 0.40, 0.40), COLOR_PORCELAIN, "toilet_pedestal", "cylinder")
	_piece(out, Vector3(0, 0.42, -0.02), Vector3(0.42, 0.18, 0.56), COLOR_PORCELAIN, "toilet_bowl", "sphere")
	_piece(out, Vector3(0, 0.52, -0.035), Vector3(0.37, 0.045, 0.49), COLOR_ENAMEL, "toilet_seat", "sphere", false, false)
	_piece(out, Vector3(0, 0.67, 0.34), Vector3(0.40, 0.37, 0.20), COLOR_PORCELAIN, "toilet_tank")
	_piece(out, Vector3(0, 0.87, 0.34), Vector3(0.44, 0.05, 0.24), COLOR_ENAMEL, "toilet_tank_lid")
	_piece(out, Vector3(0.18, 0.68, 0.225), Vector3(0.05, 0.025, 0.03), COLOR_METAL_WORN, "toilet_flush", "cylinder", false, false)

static func _build_stove(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(0, 0.40, 0), Vector3(0.72, 0.80, 0.66), COLOR_METAL, "stove_body")
	_piece(out, Vector3(0, 0.39, -0.337), Vector3(0.42, 0.40, 0.045), COLOR_METAL_WORN, "stove_door")
	_piece(out, Vector3(0, 0.60, -0.37), Vector3(0.12, 0.035, 0.025), COLOR_METAL, "stove_handle", "cylinder", false, false)
	for x in [-0.18, 0.18]:
		_piece(out, Vector3(x, 0.84, -0.12), Vector3(0.20, 0.025, 0.20), COLOR_METAL_WORN, "stove_burner", "cylinder", false, false)
	_piece(out, Vector3(0.22, 1.32, 0.16), Vector3(0.15, 0.96, 0.15), COLOR_METAL, "stove_pipe", "cylinder")
	_piece(out, Vector3(0.22, 1.79, 0.16), Vector3(0.25, 0.08, 0.25), COLOR_METAL_WORN, "stove_pipe_cap", "cylinder")

static func _build_radiator(out: Array[Dictionary]) -> void:
	_piece(out, Vector3(0, 0.31, 0), Vector3(0.78, 0.48, 0.13), COLOR_ENAMEL, "radiator_header")
	for index in range(9):
		var x := -0.36 + float(index) * 0.09
		_piece(out, Vector3(x, 0.31, 0), Vector3(0.065, 0.58, 0.18), COLOR_PORCELAIN, "radiator_fin", "box", true, false)
	_piece(out, Vector3(0, 0.07, 0), Vector3(0.70, 0.07, 0.16), COLOR_METAL_WORN, "radiator_feet")
	_piece(out, Vector3(-0.50, 0.24, 0), Vector3(0.22, 0.045, 0.045), COLOR_METAL, "radiator_pipe", "cylinder", false, false)
