extends Control
class_name FRONTLINEMinimap

## Круговая тактическая мини-карта: игрок в центре, сектора, спавны,
## союзники и ближние враги. Север всегда сверху.

const MAP_RANGE := 100.0          # метров от центра до края
const ENEMY_VISIBLE_RANGE := 38.0 # врагов дальше этого радиуса не показываем
const SNIPER_VISIBLE_RANGE := 70.0 # расширенный радар снайпера (TASK-0008)

var player: Node3D
var bots: Array = []
var sectors: Array = []
var iron_spawns: Array = []
var red_spawns: Array = []
var _player_is_red := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func setup(p: Node3D, bot_list: Array, sector_list: Array, iron_points: Array, red_points: Array) -> void:
	player = p
	bots = bot_list
	sectors = sector_list
	iron_spawns = iron_points
	red_spawns = red_points
	var team := str(get_tree().get_meta("selected_team", "IRON LEGION"))
	_player_is_red = team.to_upper().contains("RED")
	queue_redraw()

func _get_enemy_visible_range() -> float:
	if player != null and is_instance_valid(player):
		var role: Variant = null
		if "player_role" in player:
			role = player.get("player_role")
		elif player.has_meta("player_role"):
			role = player.get_meta("player_role")
		elif player.has_meta("selected_role"):
			role = player.get_meta("selected_role")
		if str(role) == "SNIPER":
			return SNIPER_VISIBLE_RANGE
	return ENEMY_VISIBLE_RANGE

func _process(_delta: float) -> void:
	if player != null and is_instance_valid(player):
		queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 3.0
	if radius <= 8.0:
		return

	draw_circle(center, radius + 2.0, Color(0.0, 0.0, 0.0, 0.55))
	draw_circle(center, radius, Color(0.07, 0.10, 0.08, 0.82))
	draw_arc(center, radius * 0.5, 0.0, TAU, 48, Color(0.55, 0.65, 0.55, 0.16), 1.0, true)
	draw_arc(center, radius - 1.0, 0.0, TAU, 64, Color(0.72, 0.80, 0.66, 0.85), 2.0, true)

	var enemy_range := _get_enemy_visible_range()
	var scale := (radius - 7.0) / MAP_RANGE
	if enemy_range > ENEMY_VISIBLE_RANGE:
		var sniper_ring_r := enemy_range * scale
		if sniper_ring_r < radius - 2.0:
			draw_arc(center, sniper_ring_r, 0.0, TAU, 48, Color(0.95, 0.82, 0.35, 0.22), 1.0, true)

	_draw_cardinals(center, radius)

	if player == null or not is_instance_valid(player):
		var font := ThemeDB.fallback_font
		draw_string(font, center + Vector2(-34, 4), "НЕТ ДАННЫХ", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8, 0.8))
		return

	_draw_spawns(center, radius, scale)
	_draw_sectors(center, radius, scale)
	_draw_supply_crates(center, radius, scale)
	_draw_drones(center, radius, scale)
	_draw_bots(center, radius, scale)
	_draw_player(center)

func _draw_cardinals(center: Vector2, radius: float) -> void:
	var font := ThemeDB.fallback_font
	var color := Color(0.80, 0.86, 0.76, 0.85)
	draw_string(font, center + Vector2(-4.0, -radius + 15.0), "С", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	draw_string(font, center + Vector2(radius - 13.0, 4.0), "В", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	draw_string(font, center + Vector2(-4.0, radius - 5.0), "Ю", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	draw_string(font, center + Vector2(-radius + 6.0, 4.0), "З", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)

func _world_to_map(world: Vector3, center: Vector2, scale: float) -> Vector2:
	var origin := player.global_position
	return center + Vector2(world.x - origin.x, world.z - origin.z) * scale

func _draw_spawns(center: Vector2, radius: float, scale: float) -> void:
	var iron_color := Color(0.45, 0.66, 1.0, 0.85)
	var red_color := Color(1.0, 0.38, 0.32, 0.85)
	for point in iron_spawns:
		_draw_square_marker(point, center, radius, scale, iron_color)
	for point in red_spawns:
		_draw_square_marker(point, center, radius, scale, red_color)

func _draw_square_marker(point: Vector3, center: Vector2, radius: float, scale: float, color: Color) -> void:
	var p := _world_to_map(point, center, scale)
	if (p - center).length() > radius - 7.0:
		return
	draw_rect(Rect2(p - Vector2(2.5, 2.5), Vector2(5.0, 5.0)), color)

func _draw_sectors(center: Vector2, radius: float, scale: float) -> void:
	var font := ThemeDB.fallback_font
	for sector in sectors:
		var pos: Vector3 = sector["pos"]
		var owner := str(sector.get("owner", "NEUTRAL"))
		var color := Color(0.78, 0.80, 0.76, 0.85)
		if owner.contains("IRON"):
			color = Color(0.45, 0.66, 1.0, 0.95)
		elif owner.contains("RED"):
			color = Color(1.0, 0.38, 0.32, 0.95)

		var p := _world_to_map(pos, center, scale)
		var offset := p - center
		if offset.length() > radius - 11.0:
			p = center + offset.normalized() * (radius - 11.0)

		draw_circle(p, 7.0, Color(color.r, color.g, color.b, 0.22))
		draw_arc(p, 7.0, 0.0, TAU, 24, color, 1.5, true)
		var letter := str(sector.get("name", "?")).substr(0, 1)
		draw_string(font, p + Vector2(-4.0, 4.0), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)

func _draw_supply_crates(center: Vector2, radius: float, scale: float) -> void:
	var crates := get_tree().get_nodes_in_group("field_supply_crates")
	for crate in crates:
		if not is_instance_valid(crate) or not (crate is Node3D):
			continue
		var crate_3d := crate as Node3D
		var pos: Vector3 = crate_3d.global_position
		var p := _world_to_map(pos, center, scale)
		if (p - center).length() > radius - 7.0:
			continue
		var is_ready: bool = crate_3d.visible and not bool(crate_3d.get("_hidden_for_respawn"))
		var box_col := Color(0.96, 0.82, 0.24, 0.92) if is_ready else Color(0.50, 0.52, 0.48, 0.45)
		var center_col := Color(0.22, 0.18, 0.06, 0.92) if is_ready else Color(0.18, 0.18, 0.18, 0.45)

		draw_rect(Rect2(p - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), box_col)
		draw_rect(Rect2(p - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), center_col)
		draw_line(Vector2(p.x, p.y - 1.5), Vector2(p.x, p.y + 1.5), box_col, 1.0)
		draw_line(Vector2(p.x - 1.5, p.y), Vector2(p.x + 1.5, p.y), box_col, 1.0)

func _draw_drones(center: Vector2, radius: float, scale: float) -> void:
	var drones := get_tree().get_nodes_in_group("radio_drones")
	for d in drones:
		if not is_instance_valid(d) or not (d is Node3D):
			continue
		var drone := d as Node3D
		if bool(drone.get("is_exploding")):
			continue
		var drone_pos: Vector3 = drone.global_position
		var p := _world_to_map(drone_pos, center, scale)
		var offset := p - center
		if offset.length() > radius - 6.0:
			p = center + offset.normalized() * (radius - 6.0)

		var op = drone.get("operator")
		var is_my_drone: bool = (op == player)
		var drone_col := Color(0.85, 0.45, 1.0, 0.95) if is_my_drone else Color(0.65, 0.30, 0.85, 0.85)

		# Линия кабеля от оператора к дрону
		if is_my_drone:
			draw_line(center, p, Color(0.85, 0.45, 1.0, 0.40), 1.2)

		# Тактический маркер квадрокоптера
		var s := 4.5
		var poly := PackedVector2Array([
			p + Vector2(0, -s), p + Vector2(s, 0),
			p + Vector2(0, s), p + Vector2(-s, 0)
		])
		draw_colored_polygon(poly, drone_col)
		draw_polyline(PackedVector2Array([
			p + Vector2(0, -s), p + Vector2(s, 0),
			p + Vector2(0, s), p + Vector2(-s, 0), p + Vector2(0, -s)
		]), Color(1, 1, 1, 0.85), 1.0, true)

		# Точки пропеллеров по углам
		var d_dist := 3.2
		draw_circle(p + Vector2(-d_dist, -d_dist), 1.1, Color.WHITE)
		draw_circle(p + Vector2(d_dist, -d_dist), 1.1, Color.WHITE)
		draw_circle(p + Vector2(-d_dist, d_dist), 1.1, Color.WHITE)
		draw_circle(p + Vector2(d_dist, d_dist), 1.1, Color.WHITE)

func _draw_bots(center: Vector2, radius: float, scale: float) -> void:
	var origin := player.global_position
	var max_enemy_dist := _get_enemy_visible_range()

	for bot in bots:
		if not is_instance_valid(bot):
			continue
		if bool(bot.get("is_dead")):
			continue
		var team_value = bot.get("team_name")
		var team := str(team_value) if team_value != null else ""
		var is_red := team.to_upper().contains("RED")
		var ally := is_red == _player_is_red
		var bot_pos: Vector3 = bot.get("global_position")
		var distance := origin.distance_to(bot_pos)

		if not ally and distance > max_enemy_dist:
			continue
		var p := _world_to_map(bot_pos, center, scale)
		if (p - center).length() > radius - 6.0:
			continue
		if ally:
			draw_circle(p, 3.0, Color(0.38, 0.86, 1.0, 0.95))
		else:
			draw_circle(p, 2.7, Color(1.0, 0.30, 0.24, 0.92))

func _draw_player(center: Vector2) -> void:
	var yaw_value = player.get("yaw")
	var yaw := float(yaw_value) if yaw_value != null else 0.0
	# В Godot вперёд — это -Z. На мини-карте север (-Z) смотрит вверх.
	var forward := Vector2(-sin(yaw), -cos(yaw))
	var right := Vector2(-forward.y, forward.x)

	var tip := center + forward * 9.5
	var back := center - forward * 4.5
	var left := back - right * 5.0
	var right_point := back + right * 5.0
	var points := PackedVector2Array([tip, left, right_point])
	draw_colored_polygon(points, Color(1.0, 0.96, 0.72, 0.98))
	draw_polyline(PackedVector2Array([tip, left, right_point, tip]), Color(0.12, 0.10, 0.05, 0.9), 1.2, true)
