extends Control
class_name FRONTLINEDeploymentMap

## Схематичная карта сверху для выбора точки высадки.
## Рисует footprint'ы карты, секторы и базовые спавны, отдаёт клик в мировых координатах.
## Не зависит от 3D-камеры и работает одинаково на ПК и Android.

signal position_picked(world_pos: Vector3)

const MAP_PADDING := 18.0

var boxes: Array = []
var sectors: Array = []
var spawns: Array = []
var map_bounds := Rect2(-120.0, -90.0, 240.0, 180.0)
var selected_position := Vector3.ZERO

var _map_rect := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(420.0, 300.0)
	resized.connect(_update_map_rect)

func configure(p_boxes: Array, p_sectors: Array, p_spawns: Array) -> void:
	boxes = p_boxes
	sectors = p_sectors
	spawns = p_spawns
	_compute_bounds()
	_update_map_rect()
	queue_redraw()

func set_selected(world_pos: Vector3) -> void:
	selected_position = world_pos
	queue_redraw()

func is_valid_spawn(world_pos: Vector3) -> bool:
	var point := Vector2(world_pos.x, world_pos.z)
	if not map_bounds.has_point(point):
		return false
	for box in boxes:
		if not bool(box.get("solid", false)):
			continue
		var center: Vector3 = box.pos
		var size: Vector3 = box.size
		if center.y + size.y * 0.5 <= 0.05 or center.y - size.y * 0.5 >= 1.8:
			continue
		if absf(world_pos.x - center.x) <= size.x * 0.5 + 0.4 and absf(world_pos.z - center.z) <= size.z * 0.5 + 0.4:
			return false
	return true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world := _screen_to_world(event.position)
		if is_valid_spawn(world):
			selected_position = world
			queue_redraw()
			position_picked.emit(world)

func _compute_bounds() -> void:
	var min_x := INF
	var min_z := INF
	var max_x := -INF
	var max_z := -INF
	for box in boxes:
		var center: Vector3 = box.pos
		var size: Vector3 = box.size
		min_x = minf(min_x, center.x - size.x * 0.5)
		max_x = maxf(max_x, center.x + size.x * 0.5)
		min_z = minf(min_z, center.z - size.z * 0.5)
		max_z = maxf(max_z, center.z + size.z * 0.5)
	for sec in sectors:
		var pos: Vector3 = sec.pos
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
		min_z = minf(min_z, pos.z)
		max_z = maxf(max_z, pos.z)
	for spawn in spawns:
		var pos: Vector3 = spawn
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
		min_z = minf(min_z, pos.z)
		max_z = maxf(max_z, pos.z)
	if not is_finite(min_x) or max_x - min_x < 1.0 or max_z - min_z < 1.0:
		map_bounds = Rect2(-120.0, -90.0, 240.0, 180.0)
		return
	map_bounds = Rect2(min_x - 6.0, min_z - 6.0, max_x - min_x + 12.0, max_z - min_z + 12.0)

func _update_map_rect() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var available := size - Vector2(MAP_PADDING, MAP_PADDING) * 2.0
	var scale := minf(available.x / map_bounds.size.x, available.y / map_bounds.size.y)
	var draw_size := map_bounds.size * scale
	_map_rect = Rect2((size - draw_size) * 0.5, draw_size)
	queue_redraw()

func _draw() -> void:
	if _map_rect.size.x <= 1.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.04, 0.0), true)
	draw_rect(_map_rect, Color(0.10, 0.14, 0.11, 0.95), true)
	draw_rect(_map_rect, Color(0.35, 0.48, 0.40, 0.85), false, 2.0)

	_draw_grid()
	_draw_boxes()
	_draw_sectors()
	_draw_spawns()
	_draw_selection()
	_draw_labels()

func _draw_grid() -> void:
	var step := 30.0
	var x := map_bounds.position.x
	while x <= map_bounds.position.x + map_bounds.size.x:
		var top := _world_to_screen(Vector3(x, 0.0, map_bounds.position.y))
		var bottom := _world_to_screen(Vector3(x, 0.0, map_bounds.position.y + map_bounds.size.y))
		draw_line(top, bottom, Color(0.35, 0.45, 0.38, 0.12), 1.0)
		x += step
	var z := map_bounds.position.y
	while z <= map_bounds.position.y + map_bounds.size.y:
		var left := _world_to_screen(Vector3(map_bounds.position.x, 0.0, z))
		var right := _world_to_screen(Vector3(map_bounds.position.x + map_bounds.size.x, 0.0, z))
		draw_line(left, right, Color(0.35, 0.45, 0.38, 0.12), 1.0)
		z += step

func _draw_boxes() -> void:
	for box in boxes:
		var kind := str(box.get("kind", ""))
		if kind == "terrain" or kind == "ground":
			continue
		var center: Vector3 = box.pos
		var box_size: Vector3 = box.size
		if center.y + box_size.y * 0.5 <= 0.05 or center.y - box_size.y * 0.5 >= 1.8:
			continue
		if not bool(box.get("solid", false)) and kind.is_empty():
			continue
		var a := _world_to_screen(Vector3(center.x - box_size.x * 0.5, 0.0, center.z - box_size.z * 0.5))
		var b := _world_to_screen(Vector3(center.x + box_size.x * 0.5, 0.0, center.z + box_size.z * 0.5))
		var rect := Rect2(a, b - a).abs()
		rect.size.x = maxf(rect.size.x, 1.0)
		rect.size.y = maxf(rect.size.y, 1.0)
		var color := Color(0.30, 0.36, 0.32, 0.95)
		if kind.contains("building") or kind.contains("house") or kind.contains("village_asset"):
			color = Color(0.42, 0.42, 0.38, 0.95)
		elif kind.contains("cover") or kind.contains("sandbag") or kind.contains("crate"):
			color = Color(0.26, 0.34, 0.27, 0.95)
		draw_rect(rect, color, true)
		draw_rect(rect, Color(0.05, 0.07, 0.05, 0.55), false, 1.0)

func _draw_sectors() -> void:
	var font := ThemeDB.fallback_font
	for sec in sectors:
		var pos: Vector3 = sec.pos
		var screen := _world_to_screen(pos)
		var owner := str(sec.get("owner", "NEUTRAL"))
		var color := Color(0.75, 0.75, 0.75)
		if owner.contains("RED"):
			color = Color(1.0, 0.35, 0.30)
		elif owner.contains("IRON"):
			color = Color(0.40, 0.68, 1.0)
		draw_circle(screen, 13.0, Color(0.05, 0.06, 0.05, 0.85))
		draw_arc(screen, 13.0, 0.0, TAU, 32, color, 2.0, true)
		var text := str(sec.get("name", "?"))
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		draw_string(font, screen + Vector2(-text_size.x * 0.5, text_size.y * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)

func _draw_spawns() -> void:
	for spawn in spawns:
		var screen := _world_to_screen(spawn)
		draw_rect(Rect2(screen - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Color(0.55, 0.85, 1.0, 0.9), true)
		draw_rect(Rect2(screen - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Color(0.02, 0.05, 0.08, 0.9), false, 1.0)

func _draw_selection() -> void:
	if selected_position.is_zero_approx():
		return
	var screen := _world_to_screen(selected_position)
	draw_circle(screen, 16.0, Color(1.0, 0.85, 0.25, 0.18))
	draw_arc(screen, 16.0, 0.0, TAU, 32, Color(1.0, 0.88, 0.35), 2.5, true)
	draw_line(screen + Vector2(-24.0, 0.0), screen + Vector2(-8.0, 0.0), Color(1.0, 0.88, 0.35), 2.0)
	draw_line(screen + Vector2(8.0, 0.0), screen + Vector2(24.0, 0.0), Color(1.0, 0.88, 0.35), 2.0)
	draw_line(screen + Vector2(0.0, -24.0), screen + Vector2(0.0, -8.0), Color(1.0, 0.88, 0.35), 2.0)
	draw_line(screen + Vector2(0.0, 8.0), screen + Vector2(0.0, 24.0), Color(1.0, 0.88, 0.35), 2.0)

func _draw_labels() -> void:
	var font := ThemeDB.fallback_font
	var top := _map_rect.position + Vector2(8.0, 18.0)
	var bottom := _map_rect.position + Vector2(8.0, _map_rect.size.y - 8.0)
	draw_string(font, top, "СЕВЕР", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.82, 0.78, 0.75))
	draw_string(font, bottom, "ЮГ", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.82, 0.78, 0.75))

func _world_to_screen(world_pos: Vector3) -> Vector2:
	var normalized := Vector2(
		(world_pos.x - map_bounds.position.x) / map_bounds.size.x,
		(world_pos.z - map_bounds.position.y) / map_bounds.size.y
	)
	return _map_rect.position + normalized * _map_rect.size

func _screen_to_world(screen_pos: Vector2) -> Vector3:
	var normalized := (screen_pos - _map_rect.position) / _map_rect.size
	return Vector3(
		map_bounds.position.x + normalized.x * map_bounds.size.x,
		0.0,
		map_bounds.position.y + normalized.y * map_bounds.size.y
	)
