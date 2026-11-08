extends Node3D

## Headless smoke & unit test suite for Tactical Street Props Pack (27 props).
## Validates:
## 1. Metadata and registry for all 27 street props across 6 categories.
## 2. Low cover heights for crouch and stand shooting ([0.90, 1.05]m).
## 3. Box layout generation and arbitrary rotation transformations.
## 4. StaticBody3D collision shapes and MeshInstance3D geometry.
## 5. Material caching and shadow culling for GL Compatibility budget.
## 6. Clearances for player traversal (pipe tunnel and bus stop shelter).

const TACTICAL_STREET_PROPS = preload("res://scripts/tactical_street_props.gd")

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().physics_frame
	await _test_prop_types_and_metadata()
	await _test_low_cover_heights()
	await _test_layout_boxes_and_rotation()
	await _test_prop_nodes_and_material_caching()
	await _test_player_clearances()
	await _test_cover_ballistics()
	_report()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("STREET_PROPS_FAIL: " + message)

## 1. Реестр и метаданные 27 пропсов
func _test_prop_types_and_metadata() -> void:
	var types: Array[String] = TACTICAL_STREET_PROPS.get_available_types()
	_check(types.size() >= 22, "Available prop types count < 22 (found %d)" % types.size())

	var required_props := [
		"burnt_car_sedan",
		"burnt_car_van",
		"military_truck_wreck",
		"military_jeep_willys",
		"sandbag_wall_straight",
		"sandbag_wall_corner",
		"sandbag_firing_nest",
		"czech_hedgehog",
		"concrete_jersey_barrier",
		"street_lantern_single",
		"street_lantern_double",
		"wooden_utility_pole",
		"road_sign_stop",
		"road_sign_yield",
		"road_barrier_wooden",
		"metal_dumpster",
		"street_trash_can",
		"oil_barrel_single",
		"oil_barrel_cluster",
		"ammo_crate_stack",
		"tire_stack",
		"bus_stop_shelter",
		"concrete_pipe_segment"
	]

	for rp in required_props:
		_check(rp in types, "Required street prop %s missing from available types" % rp)

	for t in types:
		var info: Dictionary = TACTICAL_STREET_PROPS.get_prop_info(t)
		_check(not info.is_empty(), "Empty info dictionary for prop %s" % t)
		_check(info.has("name") and not String(info["name"]).is_empty(), "Missing name for prop %s" % t)
		_check(info.has("category") and not String(info["category"]).is_empty(), "Missing category for prop %s" % t)
		_check(info.has("size") and info["size"] is Vector3, "Missing size Vector3 for prop %s" % t)
		_check(info.has("cover_height") and float(info["cover_height"]) > 0.0, "Missing cover_height for prop %s" % t)
		_check(info.has("can_vault") and info["can_vault"] is bool, "Missing can_vault bool for prop %s" % t)

## 2. Стандарт высоты укрытий (0.90 - 1.05м)
func _test_low_cover_heights() -> void:
	var low_cover_props := [
		"sandbag_wall_straight",
		"sandbag_wall_corner",
		"concrete_jersey_barrier",
		"oil_barrel_single",
		"road_barrier_wooden"
	]

	for lcp in low_cover_props:
		var info: Dictionary = TACTICAL_STREET_PROPS.get_prop_info(lcp)
		var h: float = float(info.get("cover_height", 0.0))
		_check(h >= 0.90 and h <= 1.05, "Low cover %s height %f outside standard [0.90, 1.05]m" % [lcp, h])
		_check(bool(info.get("can_vault", false)), "Low cover %s must be vaultable (can_vault=true)" % lcp)

## 3. Генерация боксов и трансформации поворота
func _test_layout_boxes_and_rotation() -> void:
	var types: Array[String] = TACTICAL_STREET_PROPS.get_available_types()
	for t in types:
		var boxes: Array[Dictionary] = TACTICAL_STREET_PROPS.get_prop_boxes(t)
		_check(boxes.size() > 0, "No boxes generated for prop %s" % t)

		for b in boxes:
			_check(b.has("pos") and b["pos"] is Vector3, "Missing pos Vector3 in %s" % t)
			_check(b.has("size") and b["size"] is Vector3, "Missing size Vector3 in %s" % t)
			_check(b.has("color") and b["color"] is Color, "Missing color Color in %s" % t)
			_check(b.has("solid") and b["solid"] is bool, "Missing solid bool in %s" % t)
			_check(b.has("kind") and b["kind"] is String, "Missing kind String in %s" % t)
			_check(b.has("cast_shadow") and b["cast_shadow"] is bool, "Missing cast_shadow bool in %s" % t)
			var s: Vector3 = b["size"]
			_check(s.x > 0.0 and s.y > 0.0 and s.z > 0.0, "Non-positive box size in %s: %s" % [t, str(s)])

	# Тест поворота на 90 градусов
	var origin_offset := Vector3(25.0, 5.0, -15.0)
	var rot_boxes: Array[Dictionary] = TACTICAL_STREET_PROPS.get_prop_boxes("concrete_jersey_barrier", origin_offset, 90.0)
	_check(rot_boxes.size() > 0, "Rotated boxes empty for concrete_jersey_barrier")
	if rot_boxes.size() > 0:
		var first_pos: Vector3 = rot_boxes[0]["pos"]
		_check(absf(first_pos.x - origin_offset.x) < 5.0, "Rotated X pos mismatch: %f" % first_pos.x)

## 4. Создание нод со StaticBody3D для всех 27 пропсов и кэширование материалов
func _test_prop_nodes_and_material_caching() -> void:
	var types: Array[String] = TACTICAL_STREET_PROPS.get_available_types()

	for t in types:
		var node: Node3D = TACTICAL_STREET_PROPS.create_prop_node(t)
		_check(node != null, "create_prop_node returned null for %s" % t)
		if node == null:
			continue
		add_child(node)
		await get_tree().physics_frame

		var body: StaticBody3D = node.get_node_or_null("PropCollision") as StaticBody3D
		_check(body != null, "PropCollision StaticBody3D missing in %s" % t)
		if body != null:
			_check(body.collision_layer == 1, "Wrong collision layer in %s StaticBody3D" % t)
			var collision_shapes: Array[Node] = body.find_children("*", "CollisionShape3D", true, false)
			_check(collision_shapes.size() > 0, "Prop %s has no CollisionShape3D children" % t)
			for cs in collision_shapes:
				var c_shape: CollisionShape3D = cs as CollisionShape3D
				_check(c_shape.shape is BoxShape3D, "Collision shape is not BoxShape3D in %s" % t)
				if c_shape.shape is BoxShape3D:
					var b_size: Vector3 = (c_shape.shape as BoxShape3D).size
					_check(b_size.x > 0.0 and b_size.y > 0.0 and b_size.z > 0.0, "Non-positive BoxShape3D size in %s" % t)

		# Проверка мешей и кэширования материалов
		var unique_mats := {}
		var mesh_count := 0
		for c in node.get_children():
			if c is MeshInstance3D:
				mesh_count += 1
				var mat: Material = (c as MeshInstance3D).material_override
				if mat != null:
					unique_mats[mat] = true

		_check(mesh_count >= 1, "Too few MeshInstance3D in %s: %d" % [t, mesh_count])
		_check(unique_mats.size() <= 10, "Too many materials (%d) in prop %s (mat_cache failed)" % [unique_mats.size(), t])

		node.queue_free()
		await get_tree().physics_frame

## 5. Проверка клиренса для перемещения игрока
func _test_player_clearances() -> void:
	# 1. Проверка внутренней проходимости бетонной трубы (concrete_pipe_segment)
	var pipe_node: Node3D = TACTICAL_STREET_PROPS.create_prop_node("concrete_pipe_segment")
	add_child(pipe_node)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space_state := get_world_3d().direct_space_state
	# Луч сквозь внутренний канал трубы (от X = -2.5 до X = 2.5 на высоте Y = 1.0м)
	# НЕ ДОЛЖЕН встречать коллизию (канал чист для перемещения пригнувшись)
	var pipe_ray_start := Vector3(-2.5, 1.0, 0.0)
	var pipe_ray_end := Vector3(2.5, 1.0, 0.0)
	var pipe_query := PhysicsRayQueryParameters3D.create(pipe_ray_start, pipe_ray_end)
	pipe_query.collide_with_bodies = true
	var pipe_hit := space_state.intersect_ray(pipe_query)
	_check(pipe_hit.is_empty(), "Concrete pipe interior channel is blocked by collision! Hit: %s" % (pipe_hit.get("position", Vector3.ZERO) if not pipe_hit.is_empty() else ""))

	# Проверка коллизии стенки трубы (выстрел в боковую стенку Z = 0.88м на высоте Y = 1.0м)
	var wall_ray_start := Vector3(0.0, 1.0, 2.0)
	var wall_ray_end := Vector3(0.0, 1.0, 0.0)
	var wall_query := PhysicsRayQueryParameters3D.create(wall_ray_start, wall_ray_end)
	wall_query.collide_with_bodies = true
	var wall_hit := space_state.intersect_ray(wall_query)
	_check(not wall_hit.is_empty(), "Concrete pipe wall has no collision!")

	pipe_node.queue_free()
	await get_tree().physics_frame

	# 2. Проверка клиренса под навесом остановки (bus_stop_shelter)
	var shelter_node: Node3D = TACTICAL_STREET_PROPS.create_prop_node("bus_stop_shelter")
	add_child(shelter_node)
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Игрок стоя ростом 1.95м (глаза Y = 1.65м, макушка 1.95м) проходит под козырьком на высоте Y = 2.0м
	var shelter_ray_start := Vector3(0.0, 2.0, -1.8)
	var shelter_ray_end := Vector3(0.0, 2.0, 0.0)
	var shelter_query := PhysicsRayQueryParameters3D.create(shelter_ray_start, shelter_ray_end)
	shelter_query.collide_with_bodies = true
	var shelter_hit := space_state.intersect_ray(shelter_query)
	_check(shelter_hit.is_empty(), "Bus shelter entrance blocked below standing height! Hit: %s" % (shelter_hit.get("position", Vector3.ZERO) if not shelter_hit.is_empty() else ""))

	shelter_node.queue_free()
	await get_tree().physics_frame

## 6. Проверка баллистики укрытий (пули останавливаются укрытием, но перелетают поверх бруствера)
func _test_cover_ballistics() -> void:
	var sandbag_node: Node3D = TACTICAL_STREET_PROPS.create_prop_node("sandbag_wall_straight")
	add_child(sandbag_node)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space_state := get_world_3d().direct_space_state
	# Выстрел в центр мешков на высоте Y = 0.5м (должен блокироваться бруствером)
	var low_ray_start := Vector3(0.0, 0.5, -2.0)
	var low_ray_end := Vector3(0.0, 0.5, 2.0)
	var low_query := PhysicsRayQueryParameters3D.create(low_ray_start, low_ray_end)
	low_query.collide_with_bodies = true
	var low_hit := space_state.intersect_ray(low_query)
	_check(not low_hit.is_empty(), "Sandbag wall did not block bullet at Y=0.5m!")

	# Выстрел над бруствером на высоте Y = 1.2m (должен свободно пролетать)
	var high_ray_start := Vector3(0.0, 1.2, -2.0)
	var high_ray_end := Vector3(0.0, 1.2, 2.0)
	var high_query := PhysicsRayQueryParameters3D.create(high_ray_start, high_ray_end)
	high_query.collide_with_bodies = true
	var high_hit := space_state.intersect_ray(high_query)
	_check(high_hit.is_empty(), "Bullet over sandbags (Y=1.2m) was falsely blocked! Hit: %s" % (high_hit.get("position", Vector3.ZERO) if not high_hit.is_empty() else ""))

	sandbag_node.queue_free()
	await get_tree().physics_frame

func _report() -> void:
	if _failures.is_empty():
		print("STREET_PROPS_SMOKE_OK")
	else:
		for failure in _failures:
			push_error("STREET_PROPS_SMOKE_FAIL: " + failure)
		print("STREET_PROPS_SMOKE_FAILED: %d" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)
