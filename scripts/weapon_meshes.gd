extends RefCounted

## Общие меши оружия. AK-47 из GLB склеивается в один меш с vertex colors:
## 1 draw call на автомат и одинаковый вид у игрока и ботов.

const AK_PATH := "res://assets/models/ak47/ak47_lowpoly.glb"
const MUZZLE_LOCAL := Vector3(0.0, 0.09, 0.501)

static var _ak_mesh: ArrayMesh
static var _ak_material: StandardMaterial3D
static var _weapon_materials: Dictionary = {}
# QA-optimization: каждый ствол запекается в ОДИН меш с vertex colors.
static var _baked_weapon_meshes: Dictionary = {}
static var _baked_weapon_muzzles: Dictionary = {}
static var _baked_weapon_material: StandardMaterial3D

## Builds a first-person model with its muzzle marker. AK-47 uses the imported GLB;
## the remaining weapons use compact low-poly parts so they need no extra assets.
static func make_weapon(weapon_id: String) -> Node3D:
	var root := Node3D.new()
	root.name = weapon_id.to_upper()
	if weapon_id == "ak47":
		root.rotation.y = PI
		var imported := ak_mesh()
		if imported != null:
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.name = "AK47Mesh"
			mesh_instance.mesh = imported
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mesh_instance)
			var imported_muzzle := Node3D.new()
			imported_muzzle.name = "Muzzle"
			imported_muzzle.position = MUZZLE_LOCAL
			root.add_child(imported_muzzle)
			return root
		root.free()
		return null

	var dark := _weapon_material("dark", Color(0.12, 0.13, 0.14), 0.52, 0.55)
	var steel := _weapon_material("steel", Color(0.24, 0.26, 0.28), 0.44, 0.70)
	var bright := _weapon_material("bright_steel", Color(0.55, 0.56, 0.58), 0.28, 0.85)
	var wood := _weapon_material("wood", Color(0.38, 0.22, 0.11), 0.72, 0.0)
	var wood_birch := _weapon_material("wood_birch", Color(0.44, 0.26, 0.13), 0.70, 0.0)
	var bakelite := _weapon_material("bakelite", Color(0.26, 0.15, 0.10), 0.50, 0.08)
	var brass := _weapon_material("brass", Color(0.85, 0.72, 0.25), 0.35, 0.85)
	var olive := _weapon_material("olive", Color(0.32, 0.36, 0.22), 0.68, 0.20)
	var parkerized := _weapon_material("parkerized", Color(0.20, 0.22, 0.23), 0.50, 0.60)

	var muzzle_z := -0.58
	var muzzle_y := 0.035

	match weapon_id:
		"mp40":
			# MP-40: Ствольная коробка - стальная трубка диаметром 3.8 см, а не гигантский блок 17 см!
			_add_cylinder_ex(root, "ReceiverTube", Vector3(0.0, 0.040, -0.06), 0.019, 0.019, 0.28, dark, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "ReceiverEndCap", Vector3(0.0, 0.040, 0.08), 0.020, 0.020, 0.020, dark, Vector3(PI * 0.5, 0.0, 0.0))
			_add_box(root, "LowerFrame", Vector3(0.0, 0.012, -0.02), Vector3(0.034, 0.036, 0.22), bakelite)

			# Тонкий ступенчатый ствол 9мм и прилив упора
			_add_cylinder_ex(root, "Barrel", Vector3(0.0, 0.040, -0.31), 0.010, 0.011, 0.24, steel, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "MuzzleNut", Vector3(0.0, 0.040, -0.42), 0.013, 0.013, 0.022, steel, Vector3(PI * 0.5, 0.0, 0.0))
			_add_box(root, "BarrelLug", Vector3(0.0, 0.020, -0.28), Vector3(0.009, 0.016, 0.14), dark)

			# Шахта и узкий коробчатый магазин на 32 патрона
			_add_box(root, "MagWell", Vector3(0.0, -0.018, -0.15), Vector3(0.032, 0.060, 0.048), steel)
			_add_box(root, "Magazine", Vector3(0.0, -0.145, -0.15), Vector3(0.024, 0.210, 0.040), dark)

			# Анатомическая бакелитовая рукоять и спусковая скоба
			_add_box(root, "PistolGrip", Vector3(0.0, -0.085, 0.050), Vector3(0.026, 0.120, 0.048), bakelite)
			_add_box(root, "TriggerGuard", Vector3(0.0, -0.042, -0.005), Vector3(0.020, 0.040, 0.055), steel)
			_add_box(root, "Trigger", Vector3(0.0, -0.038, 0.002), Vector3(0.006, 0.022, 0.010), bright)

			# Складной металлический плечевой упор
			_add_box(root, "StockStrutL", Vector3(-0.020, 0.015, 0.12), Vector3(0.005, 0.008, 0.22), steel)
			_add_box(root, "StockStrutR", Vector3(0.020, 0.015, 0.12), Vector3(0.005, 0.008, 0.22), steel)
			_add_box(root, "StockButt", Vector3(0.0, 0.015, 0.23), Vector3(0.044, 0.040, 0.010), steel)
			_add_cylinder_ex(root, "BoltHandle", Vector3(-0.024, 0.045, -0.04), 0.005, 0.005, 0.026, bright, Vector3(0.0, 0.0, PI * 0.5))

			# Реалистичные мушка и целик (Iron Sights, выравнивание строго на sight_y = 0.075)
			_add_iron_sights(root, -0.04, -0.40, 0.075, 0.0035, 0.0028, 0.010, true, steel)
			muzzle_y = 0.040
			muzzle_z = -0.44

		"mosin":
			# Винтовка Мосина: цельная берёзовая ложа с изящным прикладом
			_add_box(root, "Buttstock", Vector3(0.0, -0.025, 0.22), Vector3(0.034, 0.095, 0.30), wood_birch)
			_add_box(root, "Buttplate", Vector3(0.0, -0.025, 0.37), Vector3(0.036, 0.100, 0.010), steel)
			_add_box(root, "Wrist", Vector3(0.0, -0.008, 0.04), Vector3(0.030, 0.055, 0.16), wood_birch)
			_add_box(root, "Forend", Vector3(0.0, 0.005, -0.28), Vector3(0.032, 0.042, 0.48), wood_birch)
			_add_box(root, "Handguard", Vector3(0.0, 0.032, -0.28), Vector3(0.026, 0.018, 0.42), wood_birch)
			_add_box(root, "BandRear", Vector3(0.0, 0.020, -0.16), Vector3(0.034, 0.046, 0.015), steel)
			_add_box(root, "BandFront", Vector3(0.0, 0.020, -0.46), Vector3(0.034, 0.046, 0.015), steel)

			# Гранёная/круглая ствольная коробка, длинный ствол и шомпол
			_add_cylinder_ex(root, "Receiver", Vector3(0.0, 0.025, -0.06), 0.017, 0.017, 0.16, steel, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "Barrel", Vector3(0.0, 0.025, -0.46), 0.008, 0.009, 0.54, steel, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "CleaningRod", Vector3(0.0, -0.005, -0.46), 0.0025, 0.0025, 0.50, bright, Vector3(PI * 0.5, 0.0, 0.0))

			# Магазинная коробка, скоба и затвор с рукоятью
			_add_box(root, "MagazineBox", Vector3(0.0, -0.055, -0.06), Vector3(0.020, 0.070, 0.080), steel)
			_add_box(root, "TriggerGuard", Vector3(0.0, -0.048, 0.01), Vector3(0.018, 0.040, 0.055), steel)
			_add_cylinder_ex(root, "BoltHandle", Vector3(0.040, 0.025, -0.02), 0.005, 0.005, 0.055, bright, Vector3(0.0, 0.0, PI * 0.5))
			_add_box(root, "BoltKnob", Vector3(0.065, 0.025, -0.02), Vector3(0.014, 0.014, 0.014), bright)
			_add_cylinder_ex(root, "CockingPiece", Vector3(0.0, 0.025, 0.03), 0.012, 0.012, 0.025, bright, Vector3(PI * 0.5, 0.0, 0.0))

			# Планка Коновалова и цилиндрический намушник (sight_y = 0.060)
			_add_iron_sights(root, -0.16, -0.70, 0.060, 0.0035, 0.0026, 0.010, true, steel)
			muzzle_y = 0.025
			muzzle_z = -0.74

		"m1911":
			# Colt M1911A1: фрезерованный затвор, рамка и рифлёные накладки рукояти
			_add_box(root, "Slide", Vector3(0.0, 0.020, -0.08), Vector3(0.028, 0.036, 0.20), parkerized)
			_add_cylinder_ex(root, "Bushing", Vector3(0.0, 0.020, -0.18), 0.009, 0.009, 0.015, bright, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "Plug", Vector3(0.0, 0.008, -0.18), 0.006, 0.006, 0.015, steel, Vector3(PI * 0.5, 0.0, 0.0))
			_add_box(root, "Frame", Vector3(0.0, -0.006, -0.06), Vector3(0.024, 0.030, 0.17), steel)

			# Рукоять под углом 17 градусов и деревянные щёчки
			_add_box(root, "GripFrame", Vector3(0.0, -0.085, 0.012), Vector3(0.026, 0.125, 0.052), dark)
			_add_box(root, "GripL", Vector3(-0.015, -0.085, 0.012), Vector3(0.005, 0.110, 0.046), wood)
			_add_box(root, "GripR", Vector3(0.015, -0.085, 0.012), Vector3(0.005, 0.110, 0.046), wood)
			_add_box(root, "TriggerGuard", Vector3(0.0, -0.035, -0.03), Vector3(0.018, 0.035, 0.045), steel)
			_add_box(root, "Hammer", Vector3(0.0, 0.022, 0.025), Vector3(0.008, 0.018, 0.012), bright)

			# Тактические мушка и целик пистолета (sight_y = 0.048)
			_add_iron_sights(root, -0.01, -0.17, 0.048, 0.0032, 0.0025, 0.007, false, dark)
			muzzle_y = 0.020
			muzzle_z = -0.19

		"shotgun":
			# Окопный помповый дробовик: ореховый приклад, стальная коробка и подвижное цевьё
			_add_box(root, "Buttstock", Vector3(0.0, -0.025, 0.20), Vector3(0.034, 0.095, 0.28), wood)
			_add_box(root, "Receiver", Vector3(0.0, 0.015, -0.04), Vector3(0.036, 0.062, 0.20), steel)
			_add_box(root, "TriggerGuard", Vector3(0.0, -0.042, 0.02), Vector3(0.018, 0.038, 0.050), steel)

			# 12-калиберный ствол, магазин под стволом и рифлёное цевьё помпы
			_add_cylinder_ex(root, "Barrel", Vector3(0.0, 0.025, -0.36), 0.011, 0.011, 0.48, steel, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "MagTube", Vector3(0.0, -0.005, -0.34), 0.010, 0.010, 0.44, dark, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "PumpForend", Vector3(0.0, -0.005, -0.28), 0.018, 0.018, 0.15, wood, Vector3(PI * 0.5, 0.0, 0.0))
			_add_box(root, "HeatShield", Vector3(0.0, 0.028, -0.28), Vector3(0.026, 0.020, 0.28), dark)

			# Прицельная канавка и латунная мушка (sight_y = 0.054)
			_add_box(root, "SightGrooveL", Vector3(-0.006, 0.050, -0.04), Vector3(0.004, 0.008, 0.18), steel)
			_add_box(root, "SightGrooveR", Vector3(0.006, 0.050, -0.04), Vector3(0.004, 0.008, 0.18), steel)
			_add_cylinder_ex(root, "BrassBead", Vector3(0.0, 0.054, -0.58), 0.004, 0.004, 0.008, brass, Vector3.ZERO)
			muzzle_y = 0.025
			muzzle_z = -0.61

		"ppsh", "ppsh41":
			# ППШ-41: цельная деревянная ложа, перфорированный кожух и барабанный магазин
			_add_box(root, "Buttstock", Vector3(0.0, -0.025, 0.22), Vector3(0.036, 0.100, 0.30), wood_birch)
			_add_box(root, "Buttplate", Vector3(0.0, -0.025, 0.37), Vector3(0.038, 0.105, 0.010), steel)
			_add_box(root, "Wrist", Vector3(0.0, -0.008, 0.04), Vector3(0.032, 0.060, 0.16), wood_birch)
			_add_box(root, "Receiver", Vector3(0.0, 0.020, -0.06), Vector3(0.036, 0.046, 0.20), dark)

			# Перфорированный кожух ствола со скошенным компенсатором
			_add_box(root, "Shroud", Vector3(0.0, 0.022, -0.32), Vector3(0.032, 0.040, 0.36), steel)
			_add_box(root, "MuzzleBrake", Vector3(0.0, 0.022, -0.51), Vector3(0.034, 0.042, 0.025), steel)
			_add_cylinder_ex(root, "BoltHandle", Vector3(0.024, 0.024, -0.04), 0.005, 0.005, 0.026, bright, Vector3(0.0, 0.0, PI * 0.5))

			# 71-зарядный круглый барабан
			_add_cylinder_ex(root, "DrumMag", Vector3(0.0, -0.082, -0.08), 0.076, 0.076, 0.044, dark, Vector3(0.0, 0.0, PI * 0.5))
			_add_box(root, "DrumLatch", Vector3(0.0, -0.020, -0.10), Vector3(0.028, 0.035, 0.030), steel)

			# Перекидной целик и мушка с ушами (sight_y = 0.052)
			_add_iron_sights(root, -0.12, -0.49, 0.052, 0.0035, 0.0028, 0.009, true, steel)
			muzzle_y = 0.022
			muzzle_z = -0.53

		"kar98", "kar98k":
			# Mauser 98k: ореховая ложа, отогнутый вниз затвор и оптический снайперский прицел ZF-39
			_add_box(root, "Buttstock", Vector3(0.0, -0.025, 0.22), Vector3(0.034, 0.095, 0.30), wood)
			_add_box(root, "Buttplate", Vector3(0.0, -0.025, 0.37), Vector3(0.036, 0.100, 0.010), steel)
			_add_box(root, "Wrist", Vector3(0.0, -0.008, 0.04), Vector3(0.030, 0.055, 0.16), wood)
			_add_box(root, "Forend", Vector3(0.0, 0.005, -0.28), Vector3(0.032, 0.042, 0.48), wood)
			_add_box(root, "Handguard", Vector3(0.0, 0.032, -0.28), Vector3(0.026, 0.018, 0.42), wood)
			_add_box(root, "BandRear", Vector3(0.0, 0.020, -0.16), Vector3(0.034, 0.046, 0.015), steel)
			_add_box(root, "BandFront", Vector3(0.0, 0.020, -0.46), Vector3(0.034, 0.046, 0.015), steel)

			# Ствольная коробка, ствол и отогнутая затворная рукоять
			_add_cylinder_ex(root, "Receiver", Vector3(0.0, 0.025, -0.06), 0.017, 0.017, 0.16, steel, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "Barrel", Vector3(0.0, 0.025, -0.46), 0.008, 0.009, 0.54, steel, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "BoltStem", Vector3(0.022, 0.025, -0.02), 0.005, 0.005, 0.025, bright, Vector3(0.0, 0.0, PI * 0.5))
			_add_cylinder_ex(root, "BoltDrop", Vector3(0.034, 0.005, -0.02), 0.005, 0.005, 0.040, bright, Vector3.ZERO)
			_add_box(root, "BoltKnob", Vector3(0.034, -0.015, -0.02), Vector3(0.014, 0.014, 0.014), bright)

			# Оптический прицел ZF-39 (оптическая ось ровно по центру X = 0.0, Y = 0.075)
			_add_box(root, "ScopeRingF", Vector3(0.0, 0.050, -0.15), Vector3(0.022, 0.035, 0.018), steel)
			_add_box(root, "ScopeRingR", Vector3(0.0, 0.050, -0.01), Vector3(0.022, 0.035, 0.018), steel)
			_add_cylinder_ex(root, "ScopeTube", Vector3(0.0, 0.075, -0.08), 0.013, 0.013, 0.24, dark, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "ScopeObjective", Vector3(0.0, 0.075, -0.21), 0.018, 0.014, 0.04, dark, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "ScopeEyepiece", Vector3(0.0, 0.075, 0.05), 0.016, 0.014, 0.03, dark, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "ScopeTurretTop", Vector3(0.0, 0.092, -0.08), 0.007, 0.007, 0.015, dark, Vector3.ZERO)
			muzzle_y = 0.025
			muzzle_z = -0.74

		"panzerfaust":
			# Panzerfaust 60: пусковая труба, кумулятивная граната и откидная прицельная планка
			_add_cylinder_ex(root, "LaunchTube", Vector3(0.0, 0.0, -0.08), 0.025, 0.025, 0.82, olive, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "WarheadStem", Vector3(0.0, 0.0, -0.52), 0.016, 0.016, 0.14, dark, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "WarheadCone", Vector3(0.0, 0.0, -0.66), 0.024, 0.072, 0.16, olive, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "WarheadNose", Vector3(0.0, 0.0, -0.76), 0.072, 0.072, 0.06, olive, Vector3(PI * 0.5, 0.0, 0.0))

			# Прицельная стойка с прорезью (sight_y = 0.088) и клавиша спуска
			_add_box(root, "SightLeaf", Vector3(0.0, 0.055, -0.28), Vector3(0.018, 0.075, 0.006), dark)
			_add_box(root, "SightNotchL", Vector3(-0.005, 0.088, -0.28), Vector3(0.004, 0.012, 0.008), dark)
			_add_box(root, "SightNotchR", Vector3(0.005, 0.088, -0.28), Vector3(0.004, 0.012, 0.008), dark)
			_add_box(root, "TriggerLever", Vector3(0.0, 0.038, -0.15), Vector3(0.022, 0.035, 0.090), dark)
			muzzle_y = 0.0
			muzzle_z = -0.80
		"drone_controller":
			# Handheld FPV terminal with screen and dual joysticks
			_add_box(root, "ConsoleBody", Vector3(0.0, -0.05, -0.22), Vector3(0.28, 0.05, 0.18), dark)
			_add_box(root, "Screen", Vector3(0.0, -0.02, -0.23), Vector3(0.18, 0.015, 0.11), _weapon_material("screen", Color(0.15, 0.65, 0.25), 0.2, 0.0))
			_add_cylinder(root, "AntennaL", Vector3(-0.11, 0.04, -0.29), 0.008, 0.14, steel)
			_add_cylinder(root, "AntennaR", Vector3(0.11, 0.04, -0.29), 0.008, 0.14, steel)
			_add_cylinder(root, "StickL", Vector3(-0.09, -0.01, -0.16), 0.012, 0.035, dark)
			_add_cylinder(root, "StickR", Vector3(0.09, -0.01, -0.16), 0.012, 0.035, dark)
			muzzle_z = -0.32
		"entrenching_shovel":
			_add_cylinder_ex(root, "WoodShaft", Vector3(0.0, -0.055, -0.18), 0.017, 0.014, 0.62, wood, Vector3(PI * 0.5, 0.0, 0.0))
			_add_cylinder_ex(root, "GripCap", Vector3(0.0, -0.055, 0.15), 0.038, 0.038, 0.12, dark, Vector3(PI * 0.5, 0.0, 0.0))
			_add_box(root, "BladeSocket", Vector3(0.0, -0.055, -0.46), Vector3(0.07, 0.045, 0.10), steel)
			var blade := MeshInstance3D.new()
			blade.name = "SpadeBlade"
			var blade_mesh := CylinderMesh.new()
			blade_mesh.top_radius = 0.012
			blade_mesh.bottom_radius = 0.11
			blade_mesh.height = 0.24
			blade_mesh.radial_segments = 4
			blade_mesh.rings = 1
			blade.mesh = blade_mesh
			blade.rotation = Vector3(PI * 0.5, 0.0, PI * 0.25)
			blade.position = Vector3(0.0, -0.055, -0.61)
			blade.material_override = steel
			blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(blade)
		"grenade", "f1", "f1_grenade":
			root.free()
			return make_grenade_view_model()
		_:
			root.free()
			return null
	if weapon_id == "entrenching_shovel":
		return root
	# QA-optimization: собираем все части в один ArrayMesh (1 draw call).
	if not _baked_weapon_meshes.has(weapon_id):
		_baked_weapon_meshes[weapon_id] = _bake_weapon_parts(root)
		_baked_weapon_muzzles[weapon_id] = Vector3(0.0, muzzle_y, muzzle_z)
	for child in root.get_children():
		root.remove_child(child)
		child.free()
	var baked := MeshInstance3D.new()
	baked.name = "BakedBody"
	baked.mesh = _baked_weapon_meshes[weapon_id]
	baked.material_override = _baked_weapon_mat()
	baked.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(baked)
	var muzzle := Node3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = _baked_weapon_muzzles[weapon_id]
	root.add_child(muzzle)
	return root

static func _bake_weapon_parts(root: Node3D) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for child in root.get_children():
		if not (child is MeshInstance3D):
			continue
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		var col := Color(0.5, 0.5, 0.5)
		var mat := mi.material_override
		if mat is StandardMaterial3D:
			col = (mat as StandardMaterial3D).albedo_color
		var xf := mi.transform
		for surface in range(mi.mesh.get_surface_count()):
			var arrays := mi.mesh.surface_get_arrays(surface)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var nn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var base := verts.size()
			for i in range(v.size()):
				verts.append(xf * v[i])
				normals.append((xf.basis * nn[i]).normalized())
				colors.append(col)
			var idx = arrays[Mesh.ARRAY_INDEX]
			if idx == null:
				for i in range(v.size()):
					indices.append(base + i)
			else:
				for i in idx:
					indices.append(base + i)
	var mesh := ArrayMesh.new()
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_COLOR] = colors
	out[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	return mesh

static func _baked_weapon_mat() -> StandardMaterial3D:
	if _baked_weapon_material == null:
		_baked_weapon_material = StandardMaterial3D.new()
		_baked_weapon_material.albedo_color = Color.WHITE
		_baked_weapon_material.vertex_color_use_as_albedo = true
		_baked_weapon_material.vertex_color_is_srgb = true
		_baked_weapon_material.roughness = 0.55
		_baked_weapon_material.metallic = 0.25
	return _baked_weapon_material

static var _f1_body_mesh_cache: ArrayMesh

## Builds procedural low-poly segmented mesh for classic Soviet F-1 fragmentation grenade ("Лимонка").
## 40 distinct facets arranged in 5 tiers x 8 sectors with indented fragmentation grooves and bevels.
static func f1_body_mesh() -> ArrayMesh:
	if _f1_body_mesh_cache != null:
		return _f1_body_mesh_cache

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	var num_rings := 5
	var num_sectors := 8
	var y_min := -0.040
	var y_max := 0.040
	var groove_depth := 0.0035
	var r_max := 0.0275
	var r_min := 0.0150

	for i in range(num_rings):
		var y0: float = y_min + (y_max - y_min) * (float(i) / float(num_rings))
		var y1: float = y_min + (y_max - y_min) * (float(i + 1) / float(num_rings))
		var ym: float = 0.5 * (y0 + y1)
		var dy: float = y1 - y0
		var yf0: float = y0 + dy * 0.12
		var yf1: float = y1 - dy * 0.12

		var t: float = clampf(ym / 0.045, -0.99, 0.99)
		var r_face: float = r_min + (r_max - r_min) * sqrt(1.0 - t * t)
		var r_groove: float = r_face - groove_depth

		for j in range(num_sectors):
			var p0: float = float(j) * (TAU / float(num_sectors))
			var p1: float = float(j + 1) * (TAU / float(num_sectors))
			var dp: float = p1 - p0
			var pm: float = 0.5 * (p0 + p1)
			var pf0: float = p0 + dp * 0.12
			var pf1: float = p1 - dp * 0.12

			var cos0 := cos(pf0)
			var sin0 := sin(pf0)
			var cos1 := cos(pf1)
			var sin1 := sin(pf1)
			var cosm := cos(pm)
			var sinm := sin(pm)

			var v0 := Vector3(r_face * cos0, yf0, r_face * sin0)
			var v1 := Vector3(r_face * cos1, yf0, r_face * sin1)
			var v2 := Vector3(r_face * cos1, yf1, r_face * sin1)
			var v3 := Vector3(r_face * cos0, yf1, r_face * sin0)
			var face_norm := Vector3(cosm, 0.0, sinm)

			var idx := verts.size()
			verts.append(v0)
			verts.append(v1)
			verts.append(v2)
			verts.append(v3)
			normals.append(face_norm)
			normals.append(face_norm)
			normals.append(face_norm)
			normals.append(face_norm)
			indices.append(idx)
			indices.append(idx + 1)
			indices.append(idx + 2)
			indices.append(idx)
			indices.append(idx + 2)
			indices.append(idx + 3)

			# Bevel bottom
			var vb0 := Vector3(r_groove * cos0, y0, r_groove * sin0)
			var vb1 := Vector3(r_groove * cos1, y0, r_groove * sin1)
			var b_norm := Vector3(cosm, -0.7, sinm).normalized()
			idx = verts.size()
			verts.append(vb0)
			verts.append(vb1)
			verts.append(v1)
			verts.append(v0)
			normals.append(b_norm)
			normals.append(b_norm)
			normals.append(b_norm)
			normals.append(b_norm)
			indices.append(idx)
			indices.append(idx + 1)
			indices.append(idx + 2)
			indices.append(idx)
			indices.append(idx + 2)
			indices.append(idx + 3)

			# Bevel top
			var vt0 := Vector3(r_groove * cos0, y1, r_groove * sin0)
			var vt1 := Vector3(r_groove * cos1, y1, r_groove * sin1)
			var t_norm := Vector3(cosm, 0.7, sinm).normalized()
			idx = verts.size()
			verts.append(v3)
			verts.append(v2)
			verts.append(vt1)
			verts.append(vt0)
			normals.append(t_norm)
			normals.append(t_norm)
			normals.append(t_norm)
			normals.append(t_norm)
			indices.append(idx)
			indices.append(idx + 1)
			indices.append(idx + 2)
			indices.append(idx)
			indices.append(idx + 2)
			indices.append(idx + 3)

			# Bevel left
			var c_p0 := cos(p0)
			var s_p0 := sin(p0)
			var vl0 := Vector3(r_groove * c_p0, yf0, r_groove * s_p0)
			var vl1 := Vector3(r_groove * c_p0, yf1, r_groove * s_p0)
			var l_norm := Vector3(c_p0, 0.0, s_p0)
			idx = verts.size()
			verts.append(vl0)
			verts.append(v0)
			verts.append(v3)
			verts.append(vl1)
			normals.append(l_norm)
			normals.append(l_norm)
			normals.append(l_norm)
			normals.append(l_norm)
			indices.append(idx)
			indices.append(idx + 1)
			indices.append(idx + 2)
			indices.append(idx)
			indices.append(idx + 2)
			indices.append(idx + 3)

			# Bevel right
			var c_p1 := cos(p1)
			var s_p1 := sin(p1)
			var vr0 := Vector3(r_groove * c_p1, yf0, r_groove * s_p1)
			var vr1 := Vector3(r_groove * c_p1, yf1, r_groove * s_p1)
			var r_norm := Vector3(c_p1, 0.0, s_p1)
			idx = verts.size()
			verts.append(v1)
			verts.append(vr0)
			verts.append(vr1)
			verts.append(v2)
			normals.append(r_norm)
			normals.append(r_norm)
			normals.append(r_norm)
			normals.append(r_norm)
			indices.append(idx)
			indices.append(idx + 1)
			indices.append(idx + 2)
			indices.append(idx)
			indices.append(idx + 2)
			indices.append(idx + 3)

	var mesh := ArrayMesh.new()
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	mesh.surface_set_material(0, _weapon_material("f1_olive", Color(0.24, 0.28, 0.18), 0.78, 0.30))
	_f1_body_mesh_cache = mesh
	return mesh

## Assembles the complete F-1 grenade with military materials:
## - Matte olive cast iron body with 40 fragmentation facets
## - Galvanized zinc UZRGM fuse (запал УЗРГМ)
## - Dark stamped sheet metal safety lever / spoon (предохранительная скоба)
## - Bright steel wire pull ring & cotter pin (чека с кольцом)
static func make_grenade_assembly(with_pin := true, with_lever := true) -> Node3D:
	var grenade := Node3D.new()
	grenade.name = "GrenadeAssembly"

	var olive := _weapon_material("f1_olive", Color(0.24, 0.28, 0.18), 0.78, 0.30)
	var zinc := _weapon_material("f1_zinc", Color(0.68, 0.70, 0.72), 0.40, 0.85)
	var lever_steel := _weapon_material("f1_lever", Color(0.19, 0.20, 0.22), 0.52, 0.75)
	var ring_wire := _weapon_material("f1_ring", Color(0.85, 0.86, 0.88), 0.25, 0.95)
	var dark_metal := _weapon_material("f1_dark", Color(0.12, 0.13, 0.14), 0.58, 0.45)

	# 1. Ribbed cast-iron body ("Лимонка")
	var body_inst := MeshInstance3D.new()
	body_inst.name = "BodyMesh"
	body_inst.mesh = f1_body_mesh()
	body_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grenade.add_child(body_inst)

	# Threaded neck boss (top) and base plug (bottom)
	_add_cylinder_ex(grenade, "BodyNeck", Vector3(0.0, 0.043, 0.0), 0.012, 0.014, 0.008, olive, Vector3.ZERO)
	_add_cylinder_ex(grenade, "BodyBase", Vector3(0.0, -0.042, 0.0), 0.012, 0.010, 0.006, olive, Vector3.ZERO)

	# 2. UZRGM Fuse assembly (Запал УЗРГМ)
	var fuse := Node3D.new()
	fuse.name = "Fuse"
	fuse.position = Vector3(0.0, 0.046, 0.0)
	grenade.add_child(fuse)

	# Hexagonal screw collar into body
	_add_cylinder_ex(fuse, "FuseHexNut", Vector3(0.0, 0.006, 0.0), 0.009, 0.010, 0.012, zinc, Vector3.ZERO)
	# Central primer guide tube
	_add_cylinder_ex(fuse, "FuseTube", Vector3(0.0, 0.020, 0.0), 0.0065, 0.0065, 0.020, zinc, Vector3.ZERO)
	# Striker mechanism housing with horizontal eyelet
	_add_box(fuse, "PrimerHousing", Vector3(0.0, 0.034, 0.0), Vector3(0.014, 0.012, 0.014), zinc)
	# Top striker guide dome
	_add_cylinder_ex(fuse, "StrikerCap", Vector3(0.0, 0.042, 0.0), 0.004, 0.0055, 0.005, dark_metal, Vector3.ZERO)

	# 3. Safety lever / Spoon (Предохранительная скоба)
	# Pivots from the top striker hinge so rotating/flying off works cleanly.
	if with_lever:
		var lever := Node3D.new()
		lever.name = "SafetyLever"
		lever.position = Vector3(0.0, 0.086, 0.0)
		_add_box(lever, "LeverHood", Vector3(0.0, 0.002, 0.005), Vector3(0.016, 0.004, 0.018), lever_steel)
		_add_box(lever, "LeverElbow", Vector3(0.0, -0.012, 0.016), Vector3(0.015, 0.022, 0.005), lever_steel)
		_add_box(lever, "LeverSpoon", Vector3(0.0, -0.058, 0.028), Vector3(0.014, 0.076, 0.004), lever_steel)
		_add_box(lever, "LeverTab", Vector3(0.0, -0.098, 0.031), Vector3(0.016, 0.009, 0.006), lever_steel)
		grenade.add_child(lever)

	# 4. Pull ring & cotter pin assembly (Чека с кольцом)
	if with_pin:
		var pin_node := Node3D.new()
		pin_node.name = "SafetyPinAssembly"
		pin_node.position = Vector3(0.0, 0.080, 0.0)

		# Horizontal pin shank passing through lever and fuse eyelet
		_add_cylinder_ex(pin_node, "PinShaft", Vector3(0.0, 0.0, 0.0), 0.0018, 0.0018, 0.028, ring_wire, Vector3(0.0, 0.0, PI * 0.5))
		# Split ends on +X side (spread cotter pin tips)
		_add_cylinder_ex(pin_node, "PinSplitTop", Vector3(0.015, 0.002, 0.0), 0.0012, 0.0012, 0.008, ring_wire, Vector3(0.0, 0.0, PI * 0.38))
		_add_cylinder_ex(pin_node, "PinSplitBtm", Vector3(0.015, -0.002, 0.0), 0.0012, 0.0012, 0.008, ring_wire, Vector3(0.0, 0.0, PI * 0.62))

		# Steel pull ring on -X side
		var pull_ring := Node3D.new()
		pull_ring.name = "PullRing"
		pull_ring.position = Vector3(-0.035, 0.0, 0.0)

		var ring_mesh_inst := MeshInstance3D.new()
		ring_mesh_inst.name = "RingMesh"
		var torus := TorusMesh.new()
		torus.inner_radius = 0.011
		torus.outer_radius = 0.014
		torus.rings = 16
		torus.ring_segments = 8
		ring_mesh_inst.mesh = torus
		ring_mesh_inst.rotation_degrees = Vector3(12.0, -8.0, 78.0)
		ring_mesh_inst.material_override = ring_wire
		ring_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pull_ring.add_child(ring_mesh_inst)

		# Grip marker for left hand IK / animation target
		var ring_grip := Marker3D.new()
		ring_grip.name = "RingGrip"
		ring_grip.position = Vector3.ZERO
		pull_ring.add_child(ring_grip)

		pin_node.add_child(pull_ring)
		grenade.add_child(pin_node)

	return grenade

## Builds a first-person grenade viewmodel with animated pin pull and spoon lever.
static func make_grenade_view_model() -> Node3D:
	var root := Node3D.new()
	root.name = "GrenadeViewModel"

	var glove := _weapon_material("combat_glove", Color(0.17, 0.14, 0.11), 0.92, 0.0)

	# Complete F-1 grenade assembly
	var grenade := make_grenade_assembly(true, true)
	root.add_child(grenade)

	# Right hand gripping the grenade body & holding the spoon lever down
	var hand_r := Node3D.new()
	hand_r.name = "HandRight"
	hand_r.position = Vector3(0.018, -0.01, -0.005)
	_add_box(hand_r, "PalmR", Vector3(0.032, -0.01, -0.01), Vector3(0.062, 0.075, 0.068), glove)
	_add_box(hand_r, "ThumbR", Vector3(-0.008, 0.038, 0.030), Vector3(0.030, 0.030, 0.042), glove)
	_add_box(hand_r, "FingersR", Vector3(-0.024, -0.01, -0.030), Vector3(0.038, 0.070, 0.034), glove)
	_add_cylinder_ex(hand_r, "ForearmR", Vector3(0.085, -0.07, -0.08), 0.042, 0.045, 0.18, glove, Vector3(deg_to_rad(45.0), deg_to_rad(-25.0), 0.0))
	root.add_child(hand_r)

	# Left hand positioned on the steel pull ring, ready to yank the pin
	var hand_l := Node3D.new()
	hand_l.name = "HandLeft"
	hand_l.position = Vector3(-0.065, 0.072, 0.004)
	_add_box(hand_l, "PalmL", Vector3(-0.035, 0.0, 0.0), Vector3(0.050, 0.048, 0.052), glove)
	_add_box(hand_l, "IndexFingerL", Vector3(0.024, 0.006, 0.0), Vector3(0.036, 0.020, 0.020), glove)
	_add_cylinder_ex(hand_l, "ForearmL", Vector3(-0.10, -0.07, -0.06), 0.042, 0.045, 0.16, glove, Vector3(deg_to_rad(45.0), deg_to_rad(35.0), 0.0))
	root.add_child(hand_l)

	# Throw/aim marker
	var muzzle := Node3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0.0, 0.08, -0.20)
	root.add_child(muzzle)

	return root

## Builds an authentic F-1 world model for thrown physics projectiles or field pickups.
## In flight: with_pin=false, with_lever=false (lever flew off, sparks emitting).
## In pickup: with_pin=true, with_lever=true (ready in arsenal).
static func make_grenade_world_model(with_pin := false, with_lever := false) -> Node3D:
	return make_grenade_assembly(with_pin, with_lever)

static func _weapon_material(key: String, color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	if _weapon_materials.has(key):
		return _weapon_materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	_weapon_materials[key] = mat
	return mat

static func _add_box(parent: Node3D, node_name: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)

## Добавляет реалистичные мушку и целик, выровненные строго по оси X = 0 на высоте sight_y.
static func _add_iron_sights(parent: Node3D, rear_z: float, front_z: float, sight_y: float, notch_w := 0.0035, post_w := 0.0028, post_h := 0.010, hood := false, steel_mat: Material = null) -> void:
	# 1. Целик (Rear Sight Notch) на Z = rear_z
	_add_box(parent, "SightRearBase", Vector3(0.0, sight_y - post_h * 0.70, rear_z), Vector3(0.022, 0.006, 0.016), steel_mat)
	_add_box(parent, "SightRearL", Vector3(-notch_w - 0.004, sight_y - post_h * 0.45, rear_z), Vector3(0.008, post_h * 0.90, 0.006), steel_mat)
	_add_box(parent, "SightRearR", Vector3(notch_w + 0.004, sight_y - post_h * 0.45, rear_z), Vector3(0.008, post_h * 0.90, 0.006), steel_mat)

	# 2. Мушка (Front Sight Post) на Z = front_z (вершина строго на высоте sight_y)
	_add_box(parent, "SightFrontPost", Vector3(0.0, sight_y - post_h * 0.48, front_z), Vector3(post_w, post_h * 0.96, 0.005), steel_mat)
	_add_box(parent, "SightFrontBase", Vector3(0.0, sight_y - post_h * 0.90, front_z), Vector3(0.016, 0.006, 0.014), steel_mat)

	# 3. Круглый защитный намушник (hood)
	if hood:
		_add_box(parent, "SightHoodL", Vector3(-0.010, sight_y - post_h * 0.15, front_z), Vector3(0.0025, post_h * 1.5, 0.014), steel_mat)
		_add_box(parent, "SightHoodR", Vector3(0.010, sight_y - post_h * 0.15, front_z), Vector3(0.0025, post_h * 1.5, 0.014), steel_mat)
		_add_box(parent, "SightHoodTop", Vector3(0.0, sight_y + post_h * 0.55, front_z), Vector3(0.022, 0.0025, 0.014), steel_mat)

static func _add_cylinder(parent: Node3D, node_name: String, pos: Vector3, radius: float, length: float, material: Material) -> void:
	_add_cylinder_ex(parent, node_name, pos, radius, radius, length, material, Vector3(PI * 0.5, 0.0, 0.0))

static func _add_cylinder_ex(parent: Node3D, node_name: String, pos: Vector3, radius_top: float, radius_bottom: float, length: float, material: Material, rot: Vector3 = Vector3(PI * 0.5, 0.0, 0.0)) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_top
	mesh.bottom_radius = radius_bottom
	mesh.height = length
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = pos
	mesh_instance.rotation = rot
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh_instance)

static func ak_mesh() -> ArrayMesh:
	if _ak_mesh != null:
		return _ak_mesh
	var packed = load(AK_PATH)
	if packed == null:
		return null
	var root: Node3D = packed.instantiate()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for surf in range(mesh.get_surface_count()):
			var arrays := mesh.surface_get_arrays(surf)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var bi = arrays[Mesh.ARRAY_INDEX]
			if v == null:
				continue
			var base := verts.size()
			var color := Color(0.18, 0.18, 0.19)
			var mat = mesh.surface_get_material(surf)
			if mat is StandardMaterial3D:
				color = (mat as StandardMaterial3D).albedo_color
			for i in range(v.size()):
				verts.append(v[i])
				normals.append(n[i] if n != null and n.size() == v.size() else Vector3.UP)
				colors.append(color)
			if bi == null or bi.is_empty():
				for i in range(v.size()):
					indices.append(base + i)
			else:
				for idx in bi:
					indices.append(base + idx)
	root.free()
	if verts.is_empty():
		return null
	# Приводим палитру к более реалистичному оружию: тёмное дерево и сталь.
	for i in range(colors.size()):
		var c := colors[i]
		if c.r > c.b + 0.08 and c.get_luminance() > 0.35:
			colors[i] = Color(0.38, 0.22, 0.10)
		elif c.get_luminance() < 0.35:
			colors[i] = Color(0.13, 0.14, 0.15)
		else:
			colors[i] = Color(0.55, 0.56, 0.58)
	var mesh := ArrayMesh.new()
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_COLOR] = colors
	out[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	mesh.surface_set_material(0, ak_material())
	_ak_mesh = mesh
	return mesh

static func ak_material() -> StandardMaterial3D:
	if _ak_material != null:
		return _ak_material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 0.58
	mat.metallic = 0.22
	_ak_material = mat
	return mat
