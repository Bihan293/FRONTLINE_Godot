extends Node3D

## Headless smoke & unit test suite for Tactical Commercial Props Pack (30 props).
## Validates:
## 1. Registry and metadata for 30 props across 5 categories (store, mall, hospital, school, safety).
## 2. Tactical cover heights and vaultability flags.
## 3. Box layout generation and arbitrary 90° rotation transformations.
## 4. StaticBody3D collision geometry (layer 1) and BoxShape3D bounding boxes.
## 5. Material caching and shadow culling flags for mobile GL Compatibility budget.
## 6. Physics clearances (anti-theft gate walk-through) and bullet cover ballistics.

const COMMERCIAL_PROPS = preload("res://scripts/tactical_commercial_props.gd")

var _failures: Array[String] = []

func _ready() -> void:
	await get_tree().physics_frame
	await _test_prop_types_and_metadata()
	await _test_tactical_cover_heights()
	await _test_layout_boxes_and_rotation()
	await _test_prop_nodes_and_material_caching()
	await _test_anti_theft_gate_clearance()
	await _test_cover_ballistics()
	_report()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("COMMERCIAL_PROPS_FAIL: " + message)

## 1. Реестр и метаданные 30 коммерческих пропсов
func _test_prop_types_and_metadata() -> void:
	var types: Array[String] = COMMERCIAL_PROPS.get_available_types()
	_check(types.size() >= 30, "Available prop types count < 30 (found %d)" % types.size())

	var required_props := [
		# Store
		"cash_register_counter",
		"supermarket_shelf_aisle",
		"supermarket_shelf_endcap",
		"commercial_refrigerator_drink",
		"commercial_freezer_horizontal",
		"shopping_cart_nest",
		"anti_theft_gate",
		"warehouse_pallet_stack",
		"pallet_jack",
		# Mall
		"mall_bench_modern",
		"mall_planter_pot",
		"mall_advertising_pillar",
		"mall_escalator_segment",
		"mall_trash_recycling",
		# Hospital
		"hospital_gurney_bed",
		"iv_drip_stand",
		"operating_table",
		"medical_screen_divider",
		"medicine_glass_cabinet",
		"oxygen_tank_cart",
		"hospital_wheelchair",
		"hospital_reception_desk",
		# School
		"school_desk_double",
		"school_teacher_desk",
		"school_blackboard",
		"school_hallway_lockers",
		"school_gym_vault_box",
		"school_gym_bench",
		# Public Safety
		"fire_hose_cabinet",
		"water_dispenser_cooler"
	]

	for rp in required_props:
		_check(rp in types, "Required prop %s missing from available types" % rp)

	for t in types:
		var info: Dictionary = COMMERCIAL_PROPS.get_prop_info(t)
		_check(not info.is_empty(), "Empty info dictionary for prop %s" % t)
		_check(info.has("name") and not String(info["name"]).is_empty(), "Missing name for prop %s" % t)
		_check(info.has("category") and not String(info["category"]).is_empty(), "Missing category for prop %s" % t)
		_check(info.has("size") and info["size"] is Vector3, "Missing size Vector3 for prop %s" % t)
		_check(info.has("cover_height") and float(info["cover_height"]) > 0.0, "Missing cover_height for prop %s" % t)
		_check(info.has("can_vault") and info["can_vault"] is bool, "Missing can_vault bool for prop %s" % t)

## 2. Тактические укрытия и вольтинг
func _test_tactical_cover_heights() -> void:
	var vaultable_props := [
		"cash_register_counter",
		"commercial_freezer_horizontal",
		"shopping_cart_nest",
		"warehouse_pallet_stack",
		"pallet_jack",
		"mall_bench_modern",
		"mall_planter_pot",
		"mall_trash_recycling",
		"hospital_gurney_bed",
		"operating_table",
		"hospital_wheelchair",
		"school_desk_double",
		"school_teacher_desk",
		"school_gym_vault_box",
		"school_gym_bench"
	]

	for vp in vaultable_props:
		var info: Dictionary = COMMERCIAL_PROPS.get_prop_info(vp)
		var h: float = float(info.get("cover_height", 0.0))
		_check(h >= 0.40 and h <= 1.15, "Vaultable prop %s cover_height %f outside [0.40, 1.15]m" % [vp, h])
		_check(bool(info.get("can_vault", false)), "Vaultable prop %s must have can_vault=true" % vp)

## 3. Генерация боксов и поворот на 90 градусов
func _test_layout_boxes_and_rotation() -> void:
	var types: Array[String] = COMMERCIAL_PROPS.get_available_types()
	for t in types:
		var boxes: Array[Dictionary] = COMMERCIAL_PROPS.get_prop_boxes(t)
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

	# Тест поворота
	var rot_boxes: Array[Dictionary] = COMMERCIAL_PROPS.get_prop_boxes("cash_register_counter", Vector3(15, 0, 20), 90.0)
	_check(rot_boxes.size() > 0, "Rotated boxes empty for cash_register_counter")

## 4. Создание нод, StaticBody3D и кэширование материалов
func _test_prop_nodes_and_material_caching() -> void:
	var types: Array[String] = COMMERCIAL_PROPS.get_available_types()
	for t in types:
		var node: Node3D = COMMERCIAL_PROPS.create_prop_node(t)
		_check(node != null, "create_prop_node returned null for %s" % t)
		if node == null:
			continue
		add_child(node)
		await get_tree().physics_frame

		var body: StaticBody3D = node.get_node_or_null("PropCollision") as StaticBody3D
		_check(body != null, "PropCollision StaticBody3D missing in %s" % t)
		if body != null:
			_check(body.collision_layer == 1, "Wrong collision layer in %s" % t)
			var shapes: Array[Node] = body.find_children("*", "CollisionShape3D", true, false)
			_check(shapes.size() > 0, "Prop %s has no CollisionShape3D children" % t)
			for cs in shapes:
				var c_shape: CollisionShape3D = cs as CollisionShape3D
				_check(c_shape.shape is BoxShape3D, "Collision shape is not BoxShape3D in %s" % t)

		# Проверка уникальности материалов (кэш материалов не должен плодить сотни инстансов)
		var unique_mats := {}
		var mesh_count := 0
		for c in node.get_children():
			if c is MeshInstance3D:
				mesh_count += 1
				var mat: Material = (c as MeshInstance3D).material_override
				if mat != null:
					unique_mats[mat] = true

		_check(mesh_count >= 1, "Too few MeshInstance3D in %s: %d" % [t, mesh_count])
		_check(unique_mats.size() <= 8, "Too many materials (%d) in prop %s (mat_cache issue)" % [unique_mats.size(), t])

		node.queue_free()
		await get_tree().physics_frame

## 5. Проверка клиренса прохода антикражных ворот (anti_theft_gate)
func _test_anti_theft_gate_clearance() -> void:
	var gate_node: Node3D = COMMERCIAL_PROPS.create_prop_node("anti_theft_gate")
	add_child(gate_node)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space_state := get_world_3d().direct_space_state
	# Проход по центру ворот между стойками на высоте Y = 1.0м должен быть свободен
	var center_start := Vector3(0.0, 1.0, -1.0)
	var center_end := Vector3(0.0, 1.0, 1.0)
	var center_query := PhysicsRayQueryParameters3D.create(center_start, center_end)
	center_query.collide_with_bodies = true
	var center_hit := space_state.intersect_ray(center_query)
	_check(center_hit.is_empty(), "Anti-theft gate center walk passage is blocked by collision!")

	# Выстрел в левую стойку на X = -0.7м должен заблокироваться
	var post_start := Vector3(-0.7, 1.0, -1.0)
	var post_end := Vector3(-0.7, 1.0, 1.0)
	var post_query := PhysicsRayQueryParameters3D.create(post_start, post_end)
	post_query.collide_with_bodies = true
	var post_hit := space_state.intersect_ray(post_query)
	_check(not post_hit.is_empty(), "Anti-theft gate post has no collision!")

	gate_node.queue_free()
	await get_tree().physics_frame

## 6. Проверка баллистики укрытий (пули останавливаются укрытием, но перелетают поверх)
func _test_cover_ballistics() -> void:
	var counter_node: Node3D = COMMERCIAL_PROPS.create_prop_node("cash_register_counter")
	add_child(counter_node)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space_state := get_world_3d().direct_space_state
	# Выстрел в тело кассы на высоте Y = 0.5м (должен блокироваться)
	var low_start := Vector3(-0.5, 0.5, -1.5)
	var low_end := Vector3(-0.5, 0.5, 1.5)
	var low_query := PhysicsRayQueryParameters3D.create(low_start, low_end)
	low_query.collide_with_bodies = true
	var low_hit := space_state.intersect_ray(low_query)
	_check(not low_hit.is_empty(), "Cash register counter did not block bullet at Y=0.5m!")

	# Выстрел над кассой на высоте Y = 1.35м (должен свободно пролетать)
	var high_start := Vector3(-0.5, 1.35, -1.5)
	var high_end := Vector3(-0.5, 1.35, 1.5)
	var high_query := PhysicsRayQueryParameters3D.create(high_start, high_end)
	high_query.collide_with_bodies = true
	var high_hit := space_state.intersect_ray(high_query)
	_check(high_hit.is_empty(), "Bullet over counter at Y=1.35m was falsely blocked!")

	counter_node.queue_free()
	await get_tree().physics_frame

func _report() -> void:
	if _failures.is_empty():
		print("COMMERCIAL_PROPS_SMOKE_OK")
	else:
		for failure in _failures:
			push_error("COMMERCIAL_PROPS_SMOKE_FAIL: " + failure)
		print("COMMERCIAL_PROPS_SMOKE_FAILED: %d" % _failures.size())
	get_tree().quit(0 if _failures.is_empty() else 1)
