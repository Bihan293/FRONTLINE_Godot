extends Node
class_name FRONTLINEBotNavigation

## Общая сетка путей для пехоты. Граф строится один раз по твёрдой геометрии карты.

const BATTLEFIELD_LAYOUT = preload("res://scripts/battlefield_layout.gd")
const VILLAGE_LAYOUT = preload("res://scripts/village_layout.gd")
const COUNTRYSIDE_LAYOUT = preload("res://scripts/countryside_layout.gd")
const CELL_SIZE := 3.0
const MIN_X := -108.0
const MIN_Z := -84.0
const GRID_WIDTH := 73
const GRID_HEIGHT := 57
const AGENT_CLEARANCE := 0.45
const AGENT_HEIGHT := 1.8

var _astar := AStar2D.new()
var _ready_to_use := false
var _built_map := ""

func _current_map_name() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.has_meta("selected_map"):
		return str(tree.get_meta("selected_map"))
	return "BATTLEFIELD"

func _get_layout():
	if _current_map_name() == "VILLAGE":
		return VILLAGE_LAYOUT
	if _current_map_name() == "COUNTRYSIDE":
		return COUNTRYSIDE_LAYOUT
	return BATTLEFIELD_LAYOUT

func _ready() -> void:
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

	var start_id := _nearest_walkable_id(from_world)
	var goal_id := _nearest_walkable_id(to_world)
	if start_id < 0 or goal_id < 0:
		return path

	var ids := _astar.get_id_path(start_id, goal_id)
	for id in ids:
		var grid_x := int(id) % GRID_WIDTH
		var grid_z := floori(float(id) / float(GRID_WIDTH))
		path.append(Vector3(MIN_X + float(grid_x) * CELL_SIZE, 0.0, MIN_Z + float(grid_z) * CELL_SIZE))
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

		var min_x := clampi(ceili((b_min_x - MIN_X) / CELL_SIZE - 0.5), 0, GRID_WIDTH - 1)
		var max_x := clampi(floori((b_max_x - MIN_X) / CELL_SIZE + 0.5), 0, GRID_WIDTH - 1)
		var min_z := clampi(ceili((b_min_z - MIN_Z) / CELL_SIZE - 0.5), 0, GRID_HEIGHT - 1)
		var max_z := clampi(floori((b_max_z - MIN_Z) / CELL_SIZE + 0.5), 0, GRID_HEIGHT - 1)
		for z in range(min_z, max_z + 1):
			for x in range(min_x, max_x + 1):
				blocked[_cell_id(x, z)] = 1

	for z in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var id := _cell_id(x, z)
			if blocked[id] == 0:
				_astar.add_point(id, Vector2(float(x), float(z)))

	# Добавляем только четыре направления: AStar2D связывает каждую пару в обе стороны.
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
				# Запрещаем срезать диагональ через угол двух препятствий.
				if step.x != 0 and step.y != 0:
					if not _astar.has_point(_cell_id(x + step.x, z)) or not _astar.has_point(_cell_id(x, z + step.y)):
						continue
				_astar.connect_points(id, next_id, true)

	_ready_to_use = _astar.get_point_count() > 0

func _nearest_walkable_id(world_pos: Vector3) -> int:
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
				var cell_world := Vector2(MIN_X + float(x) * CELL_SIZE, MIN_Z + float(z) * CELL_SIZE)
				var distance := cell_world.distance_squared_to(Vector2(world_pos.x, world_pos.z))
				if distance < best_distance:
					best_distance = distance
					best_id = id
		if best_id >= 0:
			return best_id
	return -1

func _cell_id(x: int, z: int) -> int:
	return z * GRID_WIDTH + x
