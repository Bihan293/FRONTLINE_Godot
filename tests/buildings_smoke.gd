extends Node3D

## Headless smoke & unit test suite for Tactical Buildings Pack (1, 2, 3, 5 stories & expanded tactical structures).
## Validates:
## 1. Creation and metadata for all available tactical building types (up to 9 types: 1, 2, 3, 5-story, barn/hangar, ruin, checkpoint tower, L-shaped villa, bunker/pillbox).
## 2. StaticBody3D collision geometry for walls, slabs, stairs, balconies, roofs, and bunkers.
## 3. Physics raycast bullet penetration through window, door, and embrasure openings (no blocking colliders).
## 4. Continuity of stair flights, opening cutouts in floor slabs, and access to top floors and roof arena (up to 5th floor + roof).
## 5. Architectural fidelity of specialized tactical structures (tower height, bunker armor, barn clearance, ruin traversability).

const TACTICAL_BUILDINGS = preload("res://scripts/tactical_buildings.gd")
const TACTICAL_FURNITURE = preload("res://scripts/tactical_furniture.gd")

const BASE_TYPES: Array[String] = [
	"house_1story",
	"house_2story",
	"house_3story",
	"house_5story"
]

const EXPANDED_TYPES: Array[String] = [
	"house_barn_hangar",
	"house_ruin_destroyed",
	"house_checkpoint_tower",
	"house_l_shaped_villa",
	"house_bunker_pillbox"
]

const ALL_9_TYPES: Array[String] = [
	"house_1story",
	"house_2story",
	"house_3story",
	"house_5story",
	"house_barn_hangar",
	"house_ruin_destroyed",
	"house_checkpoint_tower",
	"house_l_shaped_villa",
	"house_bunker_pillbox"
]

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().physics_frame
	await _test_building_types_and_metadata()
	await _test_layout_boxes_generation()
	await _test_building_node_and_static_bodies()
	await _test_window_and_door_bullet_penetration()
	await _test_stairs_continuity_and_floor_access()
	await _test_multistory_5story_vertical_traversal()
	await _test_expanded_tactical_building_types()
	await _test_furniture_pack()
	_report()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("BUILDINGS_SMOKE_FAIL: " + message)

## 1. Проверка доступных типов зданий и метаданных
func _test_building_types_and_metadata() -> void:
	var available: Array[String] = TACTICAL_BUILDINGS.get_available_types()
	_check(available.size() >= 4, "Available types count < 4 (found %d)" % available.size())

	for bt in BASE_TYPES:
		_check(bt in available, "Base building type %s missing from available types" % bt)

	if available.size() >= 9:
		for et in EXPANDED_TYPES:
			_check(et in available, "Expanded building type %s missing from available types" % et)

	var expected_floors := {
		"house_1story": 1,
		"house_2story": 2,
		"house_3story": 3,
		"house_5story": 5,
	}

	for t in available:
		var info: Dictionary = TACTICAL_BUILDINGS.get_building_info(t)
		_check(not info.is_empty(), "Empty info for building type %s" % t)
		_check(info.has("floors") and int(info["floors"]) >= 1, "Floor count invalid for %s: %s" % [t, str(info.get("floors"))])
		if expected_floors.has(t):
			_check(info["floors"] == expected_floors[t], "Floor count mismatch for %s: %s" % [t, str(info.get("floors"))])
		_check(info.has("width") and float(info["width"]) >= 6.0, "Building width too small for %s: %s" % [t, str(info.get("width"))])
		_check(info.has("length") and float(info["length"]) >= 6.0, "Building length too small for %s: %s" % [t, str(info.get("length"))])
		_check(info.has("height") and float(info["height"]) >= 2.5, "Building height too small for %s: %s" % [t, str(info.get("height"))])
		if int(info.get("floors", 1)) > 1 and t in BASE_TYPES:
			_check(bool(info.get("roof_access", false)), "%s must have roof access" % t)
			_check(int(info.get("balconies", 0)) > 0, "%s must have balconies" % t)

## 2. Проверка генерации массивов словарей-боксов для карт
func _test_layout_boxes_generation() -> void:
	var available := TACTICAL_BUILDINGS.get_available_types()
	for t in available:
		var boxes: Array[Dictionary] = TACTICAL_BUILDINGS.get_building_boxes(t)
		_check(boxes.size() > 5, "Building %s generated too few boxes: %d" % [t, boxes.size()])

		for b in boxes:
			_check(b.has("pos") and b["pos"] is Vector3, "Box missing pos Vector3 in %s" % t)
			_check(b.has("size") and b["size"] is Vector3, "Box missing size Vector3 in %s" % t)
			_check(b.has("color") and b["color"] is Color, "Box missing color Color in %s" % t)
			_check(b.has("solid") and b["solid"] is bool, "Box missing solid bool in %s" % t)
			_check(b.has("kind") and b["kind"] is String, "Box missing kind String in %s" % t)
			var s: Vector3 = b["size"]
			_check(s.x > 0.0 and s.y > 0.0 and s.z > 0.0, "Non-positive box size in %s: %s" % [t, str(s)])

	# Тест поворота и смещения
	var origin_offset := Vector3(50.0, 10.0, -30.0)
	var rotated_boxes: Array[Dictionary] = TACTICAL_BUILDINGS.get_building_boxes("house_1story", origin_offset, 90.0)
	_check(rotated_boxes.size() > 0, "Rotated boxes array is empty")
	if rotated_boxes.size() > 0:
		var first_pos: Vector3 = rotated_boxes[0]["pos"]
		_check(absf(first_pos.x - origin_offset.x) < 25.0, "Rotated box X position out of bounds: %f" % first_pos.x)
		_check(first_pos.y >= origin_offset.y, "Rotated box Y position below origin: %f" % first_pos.y)

## 3. Проверка создания нод Node3D со StaticBody3D и коллизиями
func _test_building_node_and_static_bodies() -> void:
	var available := TACTICAL_BUILDINGS.get_available_types()
	for t in available:
		var node: Node3D = TACTICAL_BUILDINGS.create_building_node(t)
		_check(node != null, "create_building_node returned null for %s" % t)
		if node == null:
			continue
		add_child(node)
		await get_tree().physics_frame

		var body: StaticBody3D = node.get_node_or_null("BuildingCollisions") as StaticBody3D
		_check(body != null, "BuildingCollisions StaticBody3D missing in %s" % t)
		if body != null:
			var shape_count := 0
			for c in body.get_children():
				if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
					shape_count += 1
			_check(shape_count >= 5, "Too few CollisionShape3D in %s StaticBody: %d" % [t, shape_count])

		# Проверка наличия визуальных мешей
		var mesh_count := 0
		for c in node.get_children():
			if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
				mesh_count += 1
		_check(mesh_count >= 5, "Too few MeshInstance3D in %s: %d" % [t, mesh_count])

		# Проверка конкретных категорий коллизий
		var boxes := TACTICAL_BUILDINGS.get_building_boxes(t)
		var kinds := {}
		for b in boxes:
			if bool(b.get("solid", true)):
				kinds[b["kind"]] = true

		_check(kinds.has("wall"), "Building %s missing solid walls" % t)
		_check(kinds.has("building_base") or kinds.has("floor_slab") or kinds.has("floor"), "Building %s missing solid floor/base" % t)

		if t in ["house_2story", "house_3story", "house_5story"]:
			_check(kinds.has("stair_step"), "Building %s missing solid stair steps" % t)
			_check(kinds.has("balcony_slab") or kinds.has("balcony_parapet"), "Building %s missing solid balcony" % t)
			_check(kinds.has("roof_slab") or kinds.has("roof_parapet"), "Building %s missing solid roof" % t)

		node.queue_free()
		await get_tree().physics_frame

## 4. Проверка оконных и дверных проёмов (отсутствие коллизий для пролёта пуль)
func _test_window_and_door_bullet_penetration() -> void:
	var node: Node3D = TACTICAL_BUILDINGS.create_building_node("house_1story")
	add_child(node)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space_state := get_world_3d().direct_space_state
	var info: Dictionary = TACTICAL_BUILDINGS.get_building_info("house_1story")
	var half_len: float = float(info["length"]) * 0.5 # 4.5m

	# Параметры окна в house_1story:
	# Фасадное окно расположено при x = -3.2, z = -half_len = -4.5
	# Подоконник SILL_HEIGHT = 0.88, окно WINDOW_HEIGHT = 1.25, пол Y = 0.20
	# Центр окна по Y = 0.20 + 0.88 + 1.25 * 0.5 = 1.705
	var win_center := Vector3(-3.2, 1.705, -half_len)

	# 1. ТЕСТ: Пролёт пули через центр окна (снаружи внутрь) -> НЕ ДОЛЖЕН встречать коллизию
	var bullet_ray_start := win_center + Vector3(0.0, 0.0, -2.5) # Снаружи (z = -7.0)
	var bullet_ray_end := win_center + Vector3(0.0, 0.0, 2.5)   # Внутри (z = -2.0)
	var query := PhysicsRayQueryParameters3D.create(bullet_ray_start, bullet_ray_end)
	query.collide_with_bodies = true
	var hit := space_state.intersect_ray(query)
	_check(hit.is_empty(), "Window opening is blocked! Bullet hit collider at: %s" % (hit.get("position", Vector3.ZERO) if not hit.is_empty() else ""))

	# 2. ТЕСТ: Выстрел в подоконник под окном (Y = 0.20 + 0.44 = 0.64) -> ДОЛЖЕН попасть в коллизию
	var sill_ray_start := Vector3(-3.2, 0.64, -half_len - 2.5)
	var sill_ray_end := Vector3(-3.2, 0.64, -half_len + 2.5)
	var sill_query := PhysicsRayQueryParameters3D.create(sill_ray_start, sill_ray_end)
	sill_query.collide_with_bodies = true
	var sill_hit := space_state.intersect_ray(sill_query)
	_check(not sill_hit.is_empty(), "Window sill has no collision! Bullets pass through solid wall under window.")

	# 3. ТЕСТ: Выстрел в оконную перемычку сверху (Y = 0.20 + 0.88 + 1.25 + 0.4 = 2.73) -> ДОЛЖЕН попасть в коллизию
	var lintel_ray_start := Vector3(-3.2, 2.73, -half_len - 2.5)
	var lintel_ray_end := Vector3(-3.2, 2.73, -half_len + 2.5)
	var lintel_query := PhysicsRayQueryParameters3D.create(lintel_ray_start, lintel_ray_end)
	lintel_query.collide_with_bodies = true
	var lintel_hit := space_state.intersect_ray(lintel_query)
	_check(not lintel_hit.is_empty(), "Window lintel has no collision! Bullets pass through wall above window.")

	# 4. ТЕСТ: Проход и прострел через дверной проём (x = 0.0, y = 1.20) -> НЕ ДОЛЖЕН встречать коллизию
	var door_ray_start := Vector3(0.0, 1.20, -half_len - 2.5)
	var door_ray_end := Vector3(0.0, 1.20, -half_len + 2.5)
	var door_query := PhysicsRayQueryParameters3D.create(door_ray_start, door_ray_end)
	door_query.collide_with_bodies = true
	var door_hit := space_state.intersect_ray(door_query)
	_check(door_hit.is_empty(), "Door opening is blocked! Hit collider at: %s" % (door_hit.get("position", Vector3.ZERO) if not door_hit.is_empty() else ""))

	node.queue_free()
	await get_tree().physics_frame

## 5. Проверка высоты лестничных пролётов и проёмов в перекрытиях
func _test_stairs_continuity_and_floor_access() -> void:
	var node: Node3D = TACTICAL_BUILDINGS.create_building_node("house_2story")
	add_child(node)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var boxes := TACTICAL_BUILDINGS.get_building_boxes("house_2story")
	var stair_boxes: Array[Dictionary] = []
	for b in boxes:
		if b["kind"] == "stair_step":
			stair_boxes.append(b)

	_check(stair_boxes.size() >= 20, "2-story house must have at least 20 stair steps (2 flights), found: %d" % stair_boxes.size())

	# Проверяем диапазон высот ступеней (от 1-го этажа Y ~ 0.35 до крыши Y ~ 6.8)
	var min_y := 999.0
	var max_y := -999.0
	for sb in stair_boxes:
		var py: float = sb["pos"].y
		min_y = minf(min_y, py)
		max_y = maxf(max_y, py)

	_check(min_y <= 0.60, "First stair step starts too high: %f" % min_y)
	_check(max_y >= 6.0, "Top stair step does not reach upper level: %f" % max_y)

	# Физический тест: Проверка проёма в межэтажном перекрытии над лестницей
	# В точке лестничной шахты луч через высоту перекрытия (3.7м -> 3.2м)
	# НЕ ДОЛЖЕН упираться в сплошную плиту перекрытия (игрок свободно поднимается по лестнице)
	var space_state := get_world_3d().direct_space_state
	# Лестница расположена в левом заднем крыле: x = -12/2 + 1.30 = -4.70, z = 10/2 - 2.80 = 2.20
	var stair_ray_start := Vector3(-4.70, 3.7, 2.20)
	var stair_ray_end := Vector3(-4.70, 3.2, 2.20)
	var query := PhysicsRayQueryParameters3D.create(stair_ray_start, stair_ray_end)
	query.collide_with_bodies = true
	var hit := space_state.intersect_ray(query)
	_check(hit.is_empty(), "Stairwell ceiling opening is blocked by floor slab! Hit: %s" % (hit.get("position", Vector3.ZERO) if not hit.is_empty() else ""))

	# Физический тест: Проверка проёма в крыше для выхода лестницы в пентхаус (Y = 7.1м -> 6.6м)
	# НЕ ДОЛЖЕН упираться в крышу (игрок свободно выходит из лестницы на крышу через пентхаус)
	var roof_stair_ray_start := Vector3(-4.70, 7.3, 2.20)
	var roof_stair_ray_end := Vector3(-4.70, 6.7, 2.20)
	var roof_query := PhysicsRayQueryParameters3D.create(roof_stair_ray_start, roof_stair_ray_end)
	roof_query.collide_with_bodies = true
	var roof_hit := space_state.intersect_ray(roof_query)
	_check(roof_hit.is_empty(), "Roof stairwell opening is blocked by roof slab! Hit: %s" % (roof_hit.get("position", Vector3.ZERO) if not roof_hit.is_empty() else ""))

	# В жилой комнате (x = 0, z = -2.0) на той же высоте перекрытие ДОЛЖНО быть сплошным
	var floor_ray_start := Vector3(0.0, 4.2, -2.0)
	var floor_ray_end := Vector3(0.0, 3.0, -2.0)
	var f_query := PhysicsRayQueryParameters3D.create(floor_ray_start, floor_ray_end)
	f_query.collide_with_bodies = true
	var f_hit := space_state.intersect_ray(f_query)
	_check(not f_hit.is_empty(), "Living room floor slab missing! Players would fall through.")

	node.queue_free()
	await get_tree().physics_frame

## 6. Проверка 5-этажного здания (многоэтажка 17+ метров, вертикальное перемещение)
func _test_multistory_5story_vertical_traversal() -> void:
	var node: Node3D = TACTICAL_BUILDINGS.create_building_node("house_5story")
	add_child(node)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var boxes := TACTICAL_BUILDINGS.get_building_boxes("house_5story")
	var stair_boxes: Array[Dictionary] = []
	var balcony_boxes: Array[Dictionary] = []
	var roof_parapets: Array[Dictionary] = []

	var highest_step_y := 0.0
	var highest_slab_y := 0.0

	for b in boxes:
		var kind: String = b["kind"]
		var py: float = b["pos"].y
		if kind == "stair_step":
			stair_boxes.append(b)
			highest_step_y = maxf(highest_step_y, py)
		elif kind in ["balcony_slab", "balcony_parapet"]:
			balcony_boxes.append(b)
		elif kind == "roof_parapet":
			roof_parapets.append(b)
		elif kind == "roof_slab":
			highest_slab_y = maxf(highest_slab_y, py)

	# В 5-этажном здании 5 межэтажных маршей (минимум 50 ступеней)
	_check(stair_boxes.size() >= 50, "5-story house must have at least 50 stair steps, found %d" % stair_boxes.size())
	_check(highest_step_y >= 16.0, "5-story stairs do not reach the 5th floor / roof! Top step Y: %f" % highest_step_y)
	_check(highest_slab_y >= 17.0, "5-story roof slab too low! Roof Y: %f" % highest_slab_y)
	_check(balcony_boxes.size() >= 12, "5-story house missing multi-floor balconies! Found %d" % balcony_boxes.size())
	_check(roof_parapets.size() >= 4, "5-story roof missing perimeter parapets! Found %d" % roof_parapets.size())

	# Физический тест: крыша надёжно держит игрока (коллизия на высоте 17.5м)
	var space_state := get_world_3d().direct_space_state
	var roof_ray_start := Vector3(3.0, 19.0, 3.0)
	var roof_ray_end := Vector3(3.0, 16.5, 3.0)
	var r_query := PhysicsRayQueryParameters3D.create(roof_ray_start, roof_ray_end)
	r_query.collide_with_bodies = true
	var r_hit := space_state.intersect_ray(r_query)
	_check(not r_hit.is_empty(), "5-story roof has no collision! Players falling through roof.")
	if not r_hit.is_empty():
		var hit_y: float = r_hit.position.y
		_check(hit_y >= 17.0, "Roof collision height too low: %f (expected >= 17.0)" % hit_y)

	node.queue_free()
	await get_tree().physics_frame

## 7. Проверка специализированных тактических построек (ангар, руина, вышка, вилла, бункер)
func _test_expanded_tactical_building_types() -> void:
	var available: Array[String] = TACTICAL_BUILDINGS.get_available_types()
	for et in EXPANDED_TYPES:
		if not et in available:
			continue

		var info: Dictionary = TACTICAL_BUILDINGS.get_building_info(et)
		var boxes: Array[Dictionary] = TACTICAL_BUILDINGS.get_building_boxes(et)
		var kinds := {}
		for b in boxes:
			if bool(b.get("solid", true)):
				kinds[b["kind"]] = true

		match et:
			"house_barn_hangar":
				_check(float(info.get("width", 0)) >= 12.0 and float(info.get("length", 0)) >= 10.0, "Barn/hangar dimensions too small")
				_check(kinds.has("wall"), "Barn missing walls")
				_check(kinds.has("floor") or kinds.has("building_base") or kinds.has("floor_slab"), "Barn missing floor")
			"house_ruin_destroyed":
				_check(kinds.has("wall"), "Ruin missing walls")
				_check(kinds.has("rubble") or kinds.has("stair_step") or kinds.has("floor_slab") or kinds.has("building_base"), "Ruin missing rubble or slabs")
			"house_checkpoint_tower":
				_check(float(info.get("height", 0)) >= 8.0, "Checkpoint tower height too low: %s" % str(info.get("height")))
				_check(kinds.has("stair_step") or kinds.has("ladder_rung") or kinds.has("floor_slab"), "Tower missing vertical traversal elements")
			"house_l_shaped_villa":
				_check(float(info.get("width", 0)) >= 10.0 and float(info.get("length", 0)) >= 10.0, "L-shaped villa too small")
				_check(kinds.has("wall"), "Villa missing walls")
			"house_bunker_pillbox":
				_check(kinds.has("wall"), "Bunker missing reinforced walls")
				_check(kinds.has("roof_slab") or kinds.has("building_base") or kinds.has("floor"), "Bunker missing heavy slab/base")

## 8. Проверка процедурного пака мебели (16 типов)
func _test_furniture_pack() -> void:
	var types: Array[String] = TACTICAL_FURNITURE.get_available_types()
	_check(types.size() == 16, "Expected 16 furniture types, got %d" % types.size())

	for f_type in types:
		var info: Dictionary = TACTICAL_FURNITURE.get_furniture_info(f_type)
		_check(not info.is_empty(), "Empty info for furniture %s" % f_type)
		_check(info.has("size") and info["size"] is Vector3, "Invalid size for furniture %s" % f_type)

		var boxes: Array[Dictionary] = TACTICAL_FURNITURE.get_furniture_boxes(f_type, Vector3(10, 0, 10), 90.0)
		_check(boxes.size() > 0, "No boxes generated for furniture %s" % f_type)

		var node: Node3D = TACTICAL_FURNITURE.create_furniture_node(f_type)
		_check(node != null, "create_furniture_node returned null for %s" % f_type)
		if node != null:
			add_child(node)
			var sb: StaticBody3D = node.get_node_or_null("FurnitureCollision") as StaticBody3D
			_check(sb != null, "FurnitureCollision missing for %s" % f_type)
			node.queue_free()

	await get_tree().physics_frame

func _report() -> void:
	if _failures.is_empty():
		print("BUILDINGS_SMOKE_OK")
	else:
		for failure in _failures:
			push_error("BUILDINGS_SMOKE_FAIL: " + failure)
		print("BUILDINGS_SMOKE_FAILED: %d" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)
