extends RefCounted

## FRONTLINE Vehicle & Emplacement Mesh Generator.
## Процедурная low-poly 3D-геометрия для военной техники и турелей (GL Compatibility).
## Оптимизировано для мобильных GPU:
## - Минимальное число треугольников, переиспользование материалов;
## - Разделение на динамические узлы (колёса, турель, орудие, маркеры посадки);
## - Теневая оптимизация: только крупные несущие формы отбрасывают тень.

static var _materials: Dictionary = {}

static func _get_mat(key: String, color: Color, roughness: float = 0.7, metallic: float = 0.1, alpha: float = 1.0) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = alpha
	_materials[key] = mat
	return mat

# ==============================================================================
# 1. ВОЕННЫЙ РАЗВЕДЫВАТЕЛЬНЫЙ ДЖИП (WILLYS MB / ГАЗ-67 СТИЛЬ)
# ==============================================================================

## Создаёт полноценный военный джип с отдельными вращающимися колёсами,
## турельным пулемётом в кузове и посадочными местами (Driver, Passenger, Gunner).
static func build_jeep() -> Node3D:
	var jeep := Node3D.new()
	jeep.name = "JeepModel"

	var olive := _get_mat("veh_olive", Color(0.24, 0.28, 0.18), 0.78, 0.20)
	var dark_steel := _get_mat("veh_steel", Color(0.12, 0.13, 0.14), 0.55, 0.65)
	var rubber := _get_mat("veh_rubber", Color(0.10, 0.10, 0.11), 0.90, 0.05)
	var canvas := _get_mat("veh_canvas", Color(0.40, 0.36, 0.26), 0.85, 0.0)
	var glass := _get_mat("veh_glass", Color(0.65, 0.75, 0.80), 0.20, 0.30, 0.55)
	var light := _get_mat("veh_light", Color(0.95, 0.95, 0.85), 0.30, 0.10)
	var can_red := _get_mat("veh_can", Color(0.45, 0.18, 0.14), 0.70, 0.20)

	# 1. Несущая рама шасси и бамперы
	_add_box(jeep, "ChassisFrame", Vector3(0.0, 0.32, 0.0), Vector3(0.95, 0.12, 3.10), dark_steel, true)
	_add_box(jeep, "BumperFront", Vector3(0.0, 0.34, -1.62), Vector3(1.48, 0.10, 0.12), dark_steel, false)
	_add_box(jeep, "BumperRear", Vector3(0.0, 0.38, 1.58), Vector3(1.48, 0.10, 0.12), dark_steel, false)

	# 2. Капот и моторный отсек с радиаторной решёткой
	_add_box(jeep, "Hood", Vector3(0.0, 0.68, -0.92), Vector3(0.96, 0.44, 1.25), olive, true)
	_add_box(jeep, "RadiatorGrill", Vector3(0.0, 0.64, -1.56), Vector3(0.86, 0.40, 0.06), dark_steel, false)

	# Передние фары
	_add_cylinder_ex(jeep, "HeadlightL", Vector3(-0.34, 0.70, -1.58), 0.07, 0.07, 0.05, light, Vector3(PI * 0.5, 0.0, 0.0), false)
	_add_cylinder_ex(jeep, "HeadlightR", Vector3(0.34, 0.70, -1.58), 0.07, 0.07, 0.05, light, Vector3(PI * 0.5, 0.0, 0.0), false)

	# 3. Передние плоские военные крылья
	_add_box(jeep, "FenderFL", Vector3(-0.64, 0.60, -0.98), Vector3(0.32, 0.10, 1.15), olive, true)
	_add_box(jeep, "FenderFR", Vector3(0.64, 0.60, -0.98), Vector3(0.32, 0.10, 1.15), olive, true)

	# 4. Основной открытый кузов (ванна кабины)
	_add_box(jeep, "TubFloor", Vector3(0.0, 0.42, 0.45), Vector3(1.44, 0.10, 1.70), olive, true)
	_add_box(jeep, "TubWallL", Vector3(-0.70, 0.65, 0.60), Vector3(0.08, 0.38, 1.40), olive, true)
	_add_box(jeep, "TubWallR", Vector3(0.70, 0.65, 0.60), Vector3(0.08, 0.38, 1.40), olive, true)
	_add_box(jeep, "TubTailgate", Vector3(0.0, 0.65, 1.30), Vector3(1.44, 0.38, 0.08), olive, true)
	_add_box(jeep, "WheelWellL", Vector3(-0.60, 0.54, 0.95), Vector3(0.24, 0.22, 0.72), olive, false)
	_add_box(jeep, "WheelWellR", Vector3(0.60, 0.54, 0.95), Vector3(0.24, 0.22, 0.72), olive, false)

	# 5. Лобовое стекло (складная армейская рамка)
	var windshield := Node3D.new()
	windshield.name = "Windshield"
	windshield.position = Vector3(0.0, 0.90, -0.32)
	# Рамка
	_add_box(windshield, "FrameTop", Vector3(0.0, 0.48, 0.0), Vector3(1.36, 0.05, 0.04), olive, false)
	_add_box(windshield, "FrameBtm", Vector3(0.0, 0.02, 0.0), Vector3(1.36, 0.05, 0.04), olive, false)
	_add_box(windshield, "FrameL", Vector3(-0.66, 0.25, 0.0), Vector3(0.05, 0.46, 0.04), olive, false)
	_add_box(windshield, "FrameR", Vector3(0.66, 0.25, 0.0), Vector3(0.05, 0.46, 0.04), olive, false)
	_add_box(windshield, "FrameCenter", Vector3(0.0, 0.25, 0.0), Vector3(0.04, 0.46, 0.04), olive, false)
	# Стёкла (два раздельных бронестекла)
	_add_box(windshield, "GlassL", Vector3(-0.33, 0.25, 0.0), Vector3(0.62, 0.42, 0.015), glass, false)
	_add_box(windshield, "GlassR", Vector3(0.33, 0.25, 0.0), Vector3(0.62, 0.42, 0.015), glass, false)
	jeep.add_child(windshield)

	# 6. Приборная панель и руль
	_add_box(jeep, "Dashboard", Vector3(0.0, 0.78, -0.28), Vector3(1.32, 0.22, 0.12), dark_steel, false)
	_add_cylinder_ex(jeep, "SteeringColumn", Vector3(-0.35, 0.74, -0.16), 0.02, 0.02, 0.28, dark_steel, Vector3(deg_to_rad(45.0), 0.0, 0.0), false)
	_add_cylinder_ex(jeep, "SteeringWheel", Vector3(-0.35, 0.84, -0.06), 0.18, 0.18, 0.03, dark_steel, Vector3(deg_to_rad(45.0), 0.0, 0.0), false)

	# 7. Сиденья водителя и пассажира
	_build_seat(jeep, "SeatDriverMesh", Vector3(-0.35, 0.58, 0.06), canvas, dark_steel)
	_build_seat(jeep, "SeatPassengerMesh", Vector3(0.35, 0.58, 0.06), canvas, dark_steel)

	# 8. Заднее запасное колесо и военная канистра
	var spare := _build_wheel_node("SpareTire", rubber, olive)
	spare.position = Vector3(0.32, 0.68, 1.42)
	spare.rotation = Vector3(0.0, PI * 0.5, 0.0)
	spare.scale = Vector3.ONE * 0.85
	jeep.add_child(spare)

	_add_box(jeep, "JerryCan", Vector3(-0.42, 0.65, 1.40), Vector3(0.24, 0.38, 0.16), can_red, false)
	_add_box(jeep, "JerryCanHandle", Vector3(-0.42, 0.86, 1.40), Vector3(0.12, 0.04, 0.10), dark_steel, false)

	# 9. Четыре динамических колеса (WheelFL, WheelFR, WheelRL, WheelRR)
	# Вынесены в отдельные узлы для раздельного вращения и поворота передней оси.
	var w_fl := _build_wheel_node("WheelFL", rubber, olive)
	w_fl.position = Vector3(-0.68, 0.34, -0.98)
	jeep.add_child(w_fl)

	var w_fr := _build_wheel_node("WheelFR", rubber, olive)
	w_fr.position = Vector3(0.68, 0.34, -0.98)
	jeep.add_child(w_fr)

	var w_rl := _build_wheel_node("WheelRL", rubber, olive)
	w_rl.position = Vector3(-0.68, 0.34, 0.98)
	jeep.add_child(w_rl)

	var w_rr := _build_wheel_node("WheelRR", rubber, olive)
	w_rr.position = Vector3(0.68, 0.34, 0.98)
	jeep.add_child(w_rr)

	# 10. Турельная стойка в кузове с пулемётом
	var turret_mount := Node3D.new()
	turret_mount.name = "TurretMount"
	turret_mount.position = Vector3(0.0, 0.46, 0.65)

	# Вертикальная стальная опора-тумба
	_add_cylinder_ex(turret_mount, "PintlePedestal", Vector3(0.0, 0.36, 0.0), 0.05, 0.065, 0.72, dark_steel, Vector3.ZERO, false)
	# Опорные растяжки тумбы
	_add_box(turret_mount, "BraceF", Vector3(0.0, 0.15, -0.22), Vector3(0.05, 0.05, 0.45), dark_steel, false)
	_add_box(turret_mount, "BraceL", Vector3(-0.25, 0.15, 0.12), Vector3(0.48, 0.05, 0.05), dark_steel, false)
	_add_box(turret_mount, "BraceR", Vector3(0.25, 0.15, 0.12), Vector3(0.48, 0.05, 0.05), dark_steel, false)

	# Поворотная голова турели (Yaw)
	var turret_yaw := Node3D.new()
	turret_yaw.name = "TurretYaw"
	turret_yaw.position = Vector3(0.0, 0.74, 0.0)

	_add_box(turret_yaw, "CradleForkL", Vector3(-0.08, 0.12, 0.0), Vector3(0.04, 0.22, 0.08), dark_steel, false)
	_add_box(turret_yaw, "CradleForkR", Vector3(0.08, 0.12, 0.0), Vector3(0.04, 0.22, 0.08), dark_steel, false)

	# Качающаяся часть пулемёта (Pitch)
	var turret_pitch := Node3D.new()
	turret_pitch.name = "TurretPitch"
	turret_pitch.position = Vector3(0.0, 0.18, 0.0)

	_build_machine_gun_visuals(turret_pitch, dark_steel, olive)
	turret_yaw.add_child(turret_pitch)
	turret_mount.add_child(turret_yaw)
	jeep.add_child(turret_mount)

	# 11. Маркеры посадки игроков (Sockets)
	_add_socket(jeep, "DriverSeat", Vector3(-0.35, 0.55, 0.06))
	_add_socket(jeep, "PassengerSeat", Vector3(0.35, 0.55, 0.06))
	_add_socket(jeep, "GunnerSeat", Vector3(0.0, 0.50, 0.38))

	return jeep

# ==============================================================================
# 2. СТАЦИОНАРНЫЙ СТАНКОВЫЙ ПУЛЕМЁТ (ДШК / BROWNING M2 / МАКСИМ)
# ==============================================================================

## Создаёт стационарную пулемётную огневую точку со станком-треногой,
## бронещитком, коробкой патронов и рукоятками управления.
static func build_stationary_mg() -> Node3D:
	var mg_root := Node3D.new()
	mg_root.name = "StationaryMG"

	var dark_steel := _get_mat("mg_steel", Color(0.12, 0.13, 0.14), 0.55, 0.65)
	var olive := _get_mat("mg_shield", Color(0.24, 0.28, 0.18), 0.78, 0.20)

	# 1. Основание треноги (Tripod)
	var tripod := Node3D.new()
	tripod.name = "Tripod"

	_add_cylinder_ex(tripod, "CenterColumn", Vector3(0.0, 0.42, 0.0), 0.045, 0.055, 0.80, dark_steel, Vector3.ZERO, true)
	# Передняя нога треноги (направлена вперёд по -Z)
	_add_cylinder_ex(tripod, "LegFront", Vector3(0.0, 0.22, -0.45), 0.025, 0.025, 0.85, dark_steel, Vector3(deg_to_rad(60.0), 0.0, 0.0), false)
	# Левая нога треноги (направлена назад-влево)
	_add_cylinder_ex(tripod, "LegRearL", Vector3(-0.42, 0.22, 0.35), 0.025, 0.025, 0.85, dark_steel, Vector3(deg_to_rad(-55.0), deg_to_rad(-40.0), deg_to_rad(28.0)), false)
	# Правая нога треноги (направлена назад-вправо)
	_add_cylinder_ex(tripod, "LegRearR", Vector3(0.42, 0.22, 0.35), 0.025, 0.025, 0.85, dark_steel, Vector3(deg_to_rad(-55.0), deg_to_rad(40.0), deg_to_rad(-28.0)), false)
	# Опорные плунжеры ног
	_add_box(tripod, "FootF", Vector3(0.0, 0.03, -0.78), Vector3(0.12, 0.06, 0.12), dark_steel, false)
	_add_box(tripod, "FootL", Vector3(-0.66, 0.03, 0.56), Vector3(0.12, 0.06, 0.12), dark_steel, false)
	_add_box(tripod, "FootR", Vector3(0.66, 0.03, 0.56), Vector3(0.12, 0.06, 0.12), dark_steel, false)
	mg_root.add_child(tripod)

	# 2. Поворотный механизм по горизонтали (SwivelYaw)
	var swivel := Node3D.new()
	swivel.name = "SwivelYaw"
	swivel.position = Vector3(0.0, 0.80, 0.0)

	_add_cylinder_ex(swivel, "SwivelPin", Vector3(0.0, 0.05, 0.0), 0.04, 0.04, 0.14, dark_steel, Vector3.ZERO, false)
	_add_box(swivel, "CradleL", Vector3(-0.09, 0.14, 0.0), Vector3(0.035, 0.22, 0.08), dark_steel, false)
	_add_box(swivel, "CradleR", Vector3(0.09, 0.14, 0.0), Vector3(0.035, 0.22, 0.08), dark_steel, false)

	# 3. Качающаяся часть ствола по вертикали (GunPitch)
	var gun := Node3D.new()
	gun.name = "GunPitch"
	gun.position = Vector3(0.0, 0.20, 0.0)

	_build_machine_gun_visuals(gun, dark_steel, olive)
	swivel.add_child(gun)
	mg_root.add_child(swivel)

	# 4. Маркер позиции стрелка (за пулемётом)
	_add_socket(mg_root, "GunnerStand", Vector3(0.0, 0.0, 0.70))

	return mg_root

# ==============================================================================
# ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ПОСТРОЕНИЯ
# ==============================================================================

static func _build_machine_gun_visuals(parent: Node3D, dark_steel: Material, shield_mat: Material) -> void:
	# Ствольная коробка
	_add_box(parent, "Receiver", Vector3(0.0, 0.0, -0.10), Vector3(0.12, 0.14, 0.44), dark_steel, false)
	# Крышка ствольной коробки
	_add_box(parent, "TopCover", Vector3(0.0, 0.08, -0.10), Vector3(0.10, 0.03, 0.42), dark_steel, false)
	# Тяжёлый перфорированный ствол
	_add_cylinder_ex(parent, "BarrelShroud", Vector3(0.0, 0.02, -0.58), 0.032, 0.032, 0.56, dark_steel, Vector3(PI * 0.5, 0.0, 0.0), false)
	_add_cylinder_ex(parent, "BarrelTip", Vector3(0.0, 0.02, -0.92), 0.022, 0.022, 0.18, dark_steel, Vector3(PI * 0.5, 0.0, 0.0), false)
	# Конический пламегаситель
	_add_cylinder_ex(parent, "FlashHider", Vector3(0.0, 0.02, -1.04), 0.045, 0.022, 0.09, dark_steel, Vector3(PI * 0.5, 0.0, 0.0), false)

	# Бронещиток (наклонный щит с амбразурой)
	var shield := Node3D.new()
	shield.name = "ArmorShield"
	shield.position = Vector3(0.0, 0.04, -0.32)
	shield.rotation = Vector3(deg_to_rad(12.0), 0.0, 0.0)
	# Левое крыло щита
	_add_box(shield, "ShieldL", Vector3(-0.25, 0.05, 0.0), Vector3(0.36, 0.46, 0.015), shield_mat, false)
	# Правое крыло щита
	_add_box(shield, "ShieldR", Vector3(0.25, 0.05, 0.0), Vector3(0.36, 0.46, 0.015), shield_mat, false)
	# Верхняя перемычка над стволом
	_add_box(shield, "ShieldTop", Vector3(0.0, 0.22, 0.0), Vector3(0.18, 0.12, 0.015), shield_mat, false)
	parent.add_child(shield)

	# Патронный короб (Ammo Can) с левой стороны
	_add_box(parent, "AmmoBox", Vector3(-0.16, -0.02, -0.06), Vector3(0.14, 0.18, 0.26), shield_mat, false)
	# Патронная металлическая лента, входящая в приёмник
	_add_box(parent, "AmmoBelt", Vector3(-0.08, 0.04, -0.08), Vector3(0.06, 0.04, 0.08), dark_steel, false)

	# Задняя рукоять со сдвоенными гашетками (Spade Grips)
	_add_box(parent, "GripFrame", Vector3(0.0, 0.0, 0.15), Vector3(0.18, 0.02, 0.04), dark_steel, false)
	_add_cylinder_ex(parent, "GripHandleL", Vector3(-0.09, 0.0, 0.21), 0.014, 0.014, 0.12, dark_steel, Vector3.ZERO, false)
	_add_cylinder_ex(parent, "GripHandleR", Vector3(0.09, 0.0, 0.21), 0.014, 0.014, 0.12, dark_steel, Vector3.ZERO, false)
	_add_box(parent, "TriggerThumb", Vector3(0.0, 0.0, 0.17), Vector3(0.03, 0.02, 0.02), dark_steel, false)

	# Ствольный маркер выстрела (Muzzle)
	_add_socket(parent, "Muzzle", Vector3(0.0, 0.02, -1.12))
	# Маркер выброса гильз
	_add_socket(parent, "CasingEject", Vector3(0.08, -0.06, -0.08))
	# Маркеры рук стрелка
	_add_socket(parent, "HandL", Vector3(-0.09, 0.0, 0.21))
	_add_socket(parent, "HandR", Vector3(0.09, 0.0, 0.21))

static func _build_wheel_node(node_name: String, rubber_mat: Material, rim_mat: Material) -> Node3D:
	var root := Node3D.new()
	root.name = node_name

	# Шина (CylinderMesh ориентированный по X - радиус 0.34, ширина 0.22)
	var tire := MeshInstance3D.new()
	tire.name = "Tire"
	var t_mesh := CylinderMesh.new()
	t_mesh.top_radius = 0.34
	t_mesh.bottom_radius = 0.34
	t_mesh.height = 0.22
	t_mesh.radial_segments = 12
	tire.mesh = t_mesh
	tire.material_override = rubber_mat
	tire.rotation = Vector3(0.0, 0.0, PI * 0.5)
	tire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(tire)

	# Диск колеса со ступицей
	var rim := MeshInstance3D.new()
	rim.name = "Rim"
	var r_mesh := CylinderMesh.new()
	r_mesh.top_radius = 0.22
	r_mesh.bottom_radius = 0.22
	r_mesh.height = 0.23
	r_mesh.radial_segments = 8
	rim.mesh = r_mesh
	rim.material_override = rim_mat
	rim.rotation = Vector3(0.0, 0.0, PI * 0.5)
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(rim)

	return root

static func _build_seat(parent: Node3D, seat_name: String, pos: Vector3, canvas_mat: Material, steel_mat: Material) -> void:
	var seat := Node3D.new()
	seat.name = seat_name
	seat.position = pos

	# Подушка сиденья
	_add_box(seat, "Cushion", Vector3(0.0, 0.0, 0.0), Vector3(0.42, 0.10, 0.40), canvas_mat, false)
	# Спинка сиденья
	_add_box(seat, "Backrest", Vector3(0.0, 0.22, 0.18), Vector3(0.42, 0.36, 0.08), canvas_mat, false)
	# Опорные трубчатые ножки
	_add_cylinder_ex(seat, "LegL", Vector3(-0.18, -0.14, 0.0), 0.012, 0.012, 0.20, steel_mat, Vector3.ZERO, false)
	_add_cylinder_ex(seat, "LegR", Vector3(0.18, -0.14, 0.0), 0.012, 0.012, 0.20, steel_mat, Vector3.ZERO, false)
	parent.add_child(seat)

static func _add_box(parent: Node3D, node_name: String, pos: Vector3, dimensions: Vector3, material: Material, cast_shadow := false) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = node_name
	var box := BoxMesh.new()
	box.size = dimensions
	mesh_inst.mesh = box
	mesh_inst.material_override = material
	mesh_inst.position = pos
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_inst)

static func _add_cylinder_ex(parent: Node3D, node_name: String, pos: Vector3, top_radius: float, bottom_radius: float, length: float, material: Material, rot: Vector3, cast_shadow := false) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = node_name
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_radius
	cyl.bottom_radius = bottom_radius
	cyl.height = length
	cyl.radial_segments = 8
	mesh_inst.mesh = cyl
	mesh_inst.material_override = material
	mesh_inst.position = pos
	mesh_inst.rotation = rot
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_inst)

static func _add_socket(parent: Node3D, socket_name: String, pos: Vector3) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = socket_name
	marker.position = pos
	parent.add_child(marker)
	return marker
