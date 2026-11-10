extends Node
class_name FRONTLINEBotNavigation

## Общая сетка путей для пехоты. Граф строится один раз по твёрдой геометрии карты.
## Ячейка 1.5 м: улицы, окопы и проходы шириной от ~2.2 м остаются проходимыми,
## а не только «широкие» коридоры, как было при шаге 3 м.

const BATTLEFIELD_LAYOUT = preload("res://scripts/battlefield_layout.gd")
const VILLAGE_LAYOUT = preload("res://scripts/village_layout.gd")
const COUNTRYSIDE_LAYOUT = preload("res://scripts/countryside_layout.gd")

const CELL_SIZE := 1.5
const MIN_X := -108.0
const MIN_Z := -84.0
const GRID_WIDTH := 144
const GRID_HEIGHT := 112
const AGENT_CLEARANCE := 0.40
const AGENT_HEIGHT := 1.8
const WALK_RAY_HEIGHT := 0.9

var _astar := AStar2D.new()
var _ready_to_use := false
var _built_map := ""
var _walk_query := PhysicsRayQueryParameters3D.new()

func _current_map_name() -> String:
	return MatchState.map_name

func _get_layout():
	if _current_map_name() == "VILLAGE":
		return VILLAGE_LAYOUT
	if _current_map_name() == "COUNTRYSIDE":
		return COUNTRYSIDE_LAYOUT
	return BATTLEFIELD_LAYOUT

func _ready() -> void:
	_walk_query.collision_mask = 1 << 0
	_walk_query.collide_with_areas = false
	_walk_query.collide_with_bodies = true
	ensure_for_current_map()

## Перестраивает граф, если сменилась карта. Autoload создаётся до выбора карты,
## поэтому без этой проверки Village продолжал бы ходить по графу Battlefield.
func ensure_for_current_map() -> void:
	var map_name := _current_map_name()
	if map_name == _built_map and _ready_to_use:
		return
	_built_map = map_name
	_build_graph()

func find_path(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	ensure_for_current_map()
	var path := PackedVector3Array()
	if not _ready_to_use:
		return path

	var start_id := _nearest_walkable_id(from_world, true)
	var goal_id := _nearest_walkable_id(to_world, false)
	if start_id < 0 or goal_id < 0:
		return path

	for id in _astar.get_id_path(start_id, goal_id):
		path.append(_cell_world(id))
	return path

func _build_graph() -> void:
	_astar = AStar2D.new()
	_ready_to_use = false
	var blocked := PackedByteArray()
	blocked.resize(GRID_WIDTH * GRID_HEIGHT)

	var layout = _get_layout()
	for box_data in layout.boxes():
		if not bool(box_data.get("solid", false)):
			continue
		var center: Vector3 = box_data.pos
		var size: Vector3 = box_data.size
		var bottom := center.y - size.y * 0.5
		var top := center.y + size.y * 0.5
		# Не считаем поверхность земли препятствием; учитываем стены, насыпи и обломки.
		if top <= 0.05 or bottom >= AGENT_HEIGHT:
			continue

		var b_min_x := center.x - size.x * 0.5 - AGENT_CLEARANCE
		var b_max_x := center.x + size.x * 0.5 + AGENT_CLEARANCE
		var b_min_z := center.z - size.z * 0.5 - AGENT_CLEARANCE
		var b_max_z := center.z + size.z * 0.5 + AGENT_CLEARANCE

		# Блокируем все ячейки, чья площадь пересекается с препятствием.
		var min_x := clampi(floori((b_min_x - MIN_X) / CELL_SIZE), 0, GRID_WIDTH - 1)
		var max_x := clampi(ceili((b_max_x - MIN_X) / CELL_SIZE) - 1, 0, GRID_WIDTH - 1)
		var min_z := clampi(floori((b_min_z - MIN_Z) / CELL_SIZE), 0, GRID_HEIGHT - 1)
		var max_z := clampi(ceili((b_max_z - MIN_Z) / CELL_SIZE) - 1, 0, GRID_HEIGHT - 1)
		for z in range(min_z, max_z + 1):
			for x in range(min_x, max_x + 1):
				blocked[_cell_id(x, z)] = 1

	for z in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var id := _cell_id(x, z)
			if blocked[id] == 0:
				_astar.add_point(id, Vector2(float(x), float(z)))

	# Восемь направлений; диагональ запрещена, если оба угла заняты.
	var forward_steps: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 1)
	]
	for z in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var id := _cell_id(x, z)
			if not _astar.has_point(id):
				continue
			for step in forward_steps:
				var next_x := x + step.x
				var next_z := z + step.y
				if next_x < 0 or next_x >= GRID_WIDTH or next_z < 0 or next_z >= GRID_HEIGHT:
					continue
				var next_id := _cell_id(next_x, next_z)
				if not _astar.has_point(next_id):
					continue
				if step.x != 0 and step.y != 0:
					if not _astar.has_point(_cell_id(x + step.x, z)) or not _astar.has_point(_cell_id(x, z + step.y)):
						continue
				_astar.connect_points(id, next_id, true)

	_ready_to_use = _astar.get_point_count() > 0

## Ближайшая проходимая ячейка. Для старта дополнительно требуем прямую
## видимость: иначе бот, стоящий вплотную к стене, получал первый waypoint
## по ту сторону стены и бесконечно давил в неё.
func _nearest_walkable_id(world_pos: Vector3, require_line: bool) -> int:
	var origin := Vector2i(
		clampi(roundi((world_pos.x - MIN_X) / CELL_SIZE), 0, GRID_WIDTH - 1),
		clampi(roundi((world_pos.z - MIN_Z) / CELL_SIZE), 0, GRID_HEIGHT - 1)
	)
	var max_radius := maxi(GRID_WIDTH, GRID_HEIGHT)
	for radius in range(max_radius + 1):
		var best_id := -1
		var best_distance := INF
		var min_x := maxi(0, origin.x - radius)
		var max_x := mini(GRID_WIDTH - 1, origin.x + radius)
		var min_z := maxi(0, origin.y - radius)
		var max_z := mini(GRID_HEIGHT - 1, origin.y + radius)
		for z in range(min_z, max_z + 1):
			for x in range(min_x, max_x + 1):
				if maxi(absi(x - origin.x), absi(z - origin.y)) != radius:
					continue
				var id := _cell_id(x, z)
				if not _astar.has_point(id):
					continue
				var cell_world := _cell_world(id)
				var distance := Vector2(cell_world.x, cell_world.z).distance_squared_to(Vector2(world_pos.x, world_pos.z))
				if distance >= best_distance:
					continue
				if require_line and not _has_clear_walk_line(world_pos, cell_world):
					continue
				best_distance = distance
				best_id = id
		if best_id >= 0:
			return best_id
	return -1

func _has_clear_walk_line(from_world: Vector3, to_world: Vector3) -> bool:
	if not is_inside_tree():
		return true
	var viewport := get_viewport()
	if viewport == null:
		return true
	var world := viewport.find_world_3d()
	if world == null:
		return true
	_walk_query.from = from_world + Vector3.UP * WALK_RAY_HEIGHT
	_walk_query.to = to_world + Vector3.UP * WALK_RAY_HEIGHT
	_walk_query.exclude = []
	return world.direct_space_state.intersect_ray(_walk_query).is_empty()

func _cell_world(id: int) -> Vector3:
	var grid_x := id % GRID_WIDTH
	var grid_z := floori(float(id) / float(GRID_WIDTH))
	return Vector3(MIN_X + float(grid_x) * CELL_SIZE, 0.0, MIN_Z + float(grid_z) * CELL_SIZE)

func _cell_id(x: int, z: int) -> int:
	return z * GRID_WIDTH + x
