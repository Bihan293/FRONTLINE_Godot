extends RefCounted
class_name FRONTLINETacticalGear

## Процедурная тактическая экипировка бойцов Dummy War & Bodycam.
## Добавляет нательным моделям:
## 1. Нательную бодикамеру на груди с активным светящимся красным индикатором записи (Bodycam Recording LED);
## 2. Разгрузочный жилет (Chest Rig) с тройными подсумками под автоматные магазины;
## 3. Наплечную тактическую радиостанцию с гибкой антенной и выносным микрофоном PTT;
## 4. Тактический пояс (Duty Belt) со стальной пряжкой, кобурой пистолета, двойным гранатным подсумком,
##    аптечкой первой помощи (IFAK) и флягой.
##
## Все части автоматически распределяются по костям скелета (Chest / Hips) через BLOCK_RIG_BUILDER
## и объединяются в ЕДИНЫЙ skinned-меш (1 draw call на бойца!).

const SOVIET_HELMET_PATH := "res://assets/models/equipment/Soviet_Helmet.glb"
const GERMAN_HELMET_PATH := "res://assets/models/equipment/German_Helmet.glb"
const SOVIET_VEST_PATH := "res://assets/models/equipment/Soviet_Vest.glb"
const GERMAN_VEST_PATH := "res://assets/models/equipment/German_Vest.glb"

static var _mesh_cache: Dictionary = {}

## Добавляет полную тактическую выкладку к корневому узлу солдата перед риггингом.
static func add_tactical_loadout(root: Node3D, is_red: bool, include_helmet_and_vest: bool = true) -> void:
	# Цветовая палитра фракций (Красные / Железный легион)
	var camo_color := Color(0.24, 0.28, 0.18) if is_red else Color(0.25, 0.26, 0.24)
	var pouch_color := Color(0.22, 0.26, 0.16) if is_red else Color(0.23, 0.24, 0.22)
	var dark_poly := Color(0.11, 0.11, 0.12)
	var steel_color := Color(0.28, 0.30, 0.32)
	var mag_top_color := Color(0.32, 0.16, 0.10) if is_red else Color(0.16, 0.17, 0.18) # Бакелит АК / Сталь MP-40
	var ifak_color := Color(0.35, 0.31, 0.24)
	var led_red := Color(1.0, 0.08, 0.05) # Активный яркий индикатор записи Bodycam

	# 1. Базовый шлем и бронежилет (если ещё не добавлены)
	if include_helmet_and_vest:
		var helmet_path := SOVIET_HELMET_PATH if is_red else GERMAN_HELMET_PATH
		var vest_path := SOVIET_VEST_PATH if is_red else GERMAN_VEST_PATH
		var helmet_res = load(helmet_path)
		if helmet_res != null:
			var h: Node3D = helmet_res.instantiate()
			h.name = "Helmet"
			h.position = Vector3(0.0, 1.78, 0.0)
			root.add_child(h)
		var vest_res = load(vest_path)
		if vest_res != null:
			var v: Node3D = vest_res.instantiate()
			v.name = "Body_Armor_Vest"
			v.position = Vector3(0.0, 1.345, 0.0)
			v.scale = Vector3(1.12, 1.03, 1.18)
			root.add_child(v)

	# ==========================================================================
	# 2. НАТЕЛЬНАЯ БОДИКАМЕРА (BODYCAM С КРАСНЫМ ИНДИКАТОРОМ ЗАПИСИ)
	# ==========================================================================
	# Крепится на правый верхний угол грудной пластины (высота 1.48 м, Z ~ 0.22 м)
	_add_box(root, "Body_Camera_Mount", Vector3(0.095, 1.485, 0.210), Vector3(0.060, 0.070, 0.012), dark_poly)
	_add_box(root, "Body_Camera_Body", Vector3(0.095, 1.485, 0.224), Vector3(0.056, 0.068, 0.024), dark_poly)
	# Объектив камеры
	_add_cylinder(root, "Body_Camera_Lens", Vector3(0.095, 1.490, 0.238), 0.016, 0.016, 0.012, Color(0.05, 0.06, 0.07), Vector3(PI * 0.5, 0.0, 0.0))
	# Яркий красный светодиодный индикатор активной видеозаписи (Bodycam Rec LED)
	_add_box(root, "Body_Camera_LED", Vector3(0.114, 1.508, 0.238), Vector3(0.009, 0.009, 0.006), led_red)

	# ==========================================================================
	# 3. ТАКТИЧЕСКИЙ CHEST RIG С ПОДСУМКАМИ ДЛЯ МАГАЗИНОВ
	# ==========================================================================
	# Панель разгрузки по нижней части груди (MOLLE-основание)
	_add_box(root, "Chest_Rig_Backing", Vector3(0.0, 1.25, 0.208), Vector3(0.34, 0.16, 0.014), camo_color)

	# Три автоматных подсумка по центру груди
	var pouch_xs := [-0.11, 0.0, 0.11]
	for i in range(3):
		var px: float = pouch_xs[i]
		var idx_str := str(i + 1)
		# Тело подсумка
		_add_box(root, "Chest_Mag_Pouch_" + idx_str, Vector3(px, 1.25, 0.226), Vector3(0.068, 0.145, 0.042), pouch_color)
		# Верхний клапан/стяжка
		_add_box(root, "Chest_Mag_Tab_" + idx_str, Vector3(px, 1.33, 0.228), Vector3(0.064, 0.022, 0.044), dark_poly)
		# Выступающая верхняя часть магазина
		_add_box(root, "Chest_Mag_Top_" + idx_str, Vector3(px, 1.35, 0.226), Vector3(0.048, 0.035, 0.028), mag_top_color)

	# ==========================================================================
	# 4. НАПЛЕЧНАЯ ТАКТИЧЕСКАЯ РАДИОСТАНЦИЯ С АНТЕННОЙ
	# ==========================================================================
	# Корпус рации на левой плечевой лямке
	_add_box(root, "Tactical_Radio_Base", Vector3(-0.145, 1.52, 0.160), Vector3(0.052, 0.110, 0.038), dark_poly)
	# Гибкая штыревая антенна
	_add_cylinder(root, "Tactical_Radio_Antenna", Vector3(-0.145, 1.66, 0.160), 0.004, 0.004, 0.18, Color(0.09, 0.09, 0.10), Vector3.ZERO)
	# Выносной микрофон / тангента PTT на груди
	_add_box(root, "Tactical_Radio_PTT", Vector3(-0.065, 1.48, 0.210), Vector3(0.030, 0.030, 0.018), dark_poly)

	# ==========================================================================
	# 5. ТАКТИЧЕСКИЙ РЕМЕНЬ И ПОЯСНАЯ ВЫКЛАДКА (HIPS)
	# ==========================================================================
	# Тактический ремень вокруг талии (высота 0.90 м)
	_add_box(root, "Duty_Belt_Front", Vector3(0.0, 0.90, 0.145), Vector3(0.38, 0.055, 0.016), dark_poly)
	_add_box(root, "Duty_Belt_Back", Vector3(0.0, 0.90, -0.145), Vector3(0.38, 0.055, 0.016), dark_poly)
	_add_box(root, "Duty_Belt_L", Vector3(-0.19, 0.90, 0.0), Vector3(0.016, 0.055, 0.29), dark_poly)
	_add_box(root, "Duty_Belt_R", Vector3(0.19, 0.90, 0.0), Vector3(0.016, 0.055, 0.29), dark_poly)
	# Быстроразъёмная пряжка типа Cobra
	_add_box(root, "Duty_Belt_Buckle", Vector3(0.0, 0.90, 0.155), Vector3(0.065, 0.060, 0.020), steel_color)

	# Кобура с пистолетом на правом бедре
	_add_box(root, "Side_Holster_Body", Vector3(0.215, 0.82, 0.025), Vector3(0.060, 0.155, 0.070), dark_poly)
	_add_box(root, "Side_Holster_Grip", Vector3(0.215, 0.91, -0.010), Vector3(0.030, 0.050, 0.075), Color(0.15, 0.15, 0.16))

	# Двойной подсумок для гранат на левом переднем боку
	_add_box(root, "Grenade_Pouch_Body", Vector3(-0.175, 0.88, 0.135), Vector3(0.072, 0.095, 0.060), pouch_color)
	_add_box(root, "Grenade_Pouch_Flap", Vector3(-0.175, 0.93, 0.138), Vector3(0.070, 0.020, 0.062), dark_poly)

	# Индивидуальная аптечка IFAK на пояснице сзади
	_add_box(root, "Tactical_IFAK_Body", Vector3(0.0, 0.90, -0.165), Vector3(0.145, 0.105, 0.060), ifak_color)
	_add_box(root, "Tactical_IFAK_CrossH", Vector3(0.0, 0.90, -0.196), Vector3(0.050, 0.014, 0.004), Color(0.85, 0.85, 0.82))
	_add_box(root, "Tactical_IFAK_CrossV", Vector3(0.0, 0.90, -0.196), Vector3(0.014, 0.050, 0.004), Color(0.85, 0.85, 0.82))

	# Армейская фляга на правом заднем боку
	_add_box(root, "Canteen_Flask", Vector3(0.165, 0.88, -0.135), Vector3(0.080, 0.115, 0.055), camo_color)
	_add_cylinder(root, "Canteen_Cap", Vector3(0.165, 0.945, -0.135), 0.014, 0.014, 0.020, steel_color, Vector3.ZERO)

# ==============================================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ГЕНЕРАЦИИ ГЕОМЕТРИИ С ВЕРТЕКСНЫМИ ЦВЕТАМИ
# ==============================================================================

static func _add_box(parent: Node3D, node_name: String, pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.position = pos
	inst.mesh = _get_or_create_box_mesh(dimensions, color)
	parent.add_child(inst)

static func _add_cylinder(parent: Node3D, node_name: String, pos: Vector3, top_r: float, btm_r: float, height: float, color: Color, rot: Vector3) -> void:
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.position = pos
	inst.mesh = _get_or_create_cylinder_mesh(top_r, btm_r, height, color, rot)
	parent.add_child(inst)

static func _get_or_create_box_mesh(dim: Vector3, col: Color) -> ArrayMesh:
	var key := "box_%0.3f_%0.3f_%0.3f_%0.2f_%0.2f_%0.2f" % [dim.x, dim.y, dim.z, col.r, col.g, col.b]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var bm := BoxMesh.new()
	bm.size = dim
	var st := SurfaceTool.new()
	st.create_from(bm, 0)
	var arr := st.commit_to_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var colors := PackedColorArray()
	colors.resize(verts.size())
	colors.fill(col)
	arr[Mesh.ARRAY_COLOR] = colors
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_mesh_cache[key] = am
	return am

static func _get_or_create_cylinder_mesh(top_r: float, btm_r: float, height: float, col: Color, rot: Vector3) -> ArrayMesh:
	var key := "cyl_%0.3f_%0.3f_%0.3f_%0.2f_%0.2f_%0.2f_%0.2f" % [top_r, btm_r, height, col.r, col.g, col.b, rot.x]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = btm_r
	cm.height = height
	cm.radial_segments = 8
	var st := SurfaceTool.new()
	st.create_from(cm, 0)
	var arr := st.commit_to_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	if rot != Vector3.ZERO:
		var b := Basis.from_euler(rot)
		for i in range(verts.size()):
			verts[i] = b * verts[i]
			normals[i] = (b * normals[i]).normalized()
		arr[Mesh.ARRAY_VERTEX] = verts
		arr[Mesh.ARRAY_NORMAL] = normals
	var colors := PackedColorArray()
	colors.resize(verts.size())
	colors.fill(col)
	arr[Mesh.ARRAY_COLOR] = colors
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_mesh_cache[key] = am
	return am
