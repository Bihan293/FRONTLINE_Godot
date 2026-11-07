extends Control
class_name FRONTLINECompassBar

## Тактический компас и система целеуказания в стиле Dummy War / Battlefield.
## Отображает азимут взгляда, метки ключевых секторов [A], [B], [C] с расстоянием
## и маркеры источников стрельбы противника.

const COMPASS_WIDTH := 380.0
const COMPASS_HEIGHT := 36.0
const FOV_ANGLE := deg_to_rad(90.0)

var player_camera: Camera3D
var sectors: Array[Dictionary] = []
var _gunfire_pings: Array[Dictionary] = []

func _ready() -> void:
	custom_minimum_size = Vector2(COMPASS_WIDTH, COMPASS_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(camera: Camera3D, sector_list: Array[Dictionary]) -> void:
	player_camera = camera
	sectors = sector_list

func add_gunfire_ping(world_pos: Vector3) -> void:
	_gunfire_pings.append({
		"pos": world_pos,
		"time": 2.2
	})

func _process(delta: float) -> void:
	# Очистка старых меток выстрелов
	var i := _gunfire_pings.size() - 1
	while i >= 0:
		_gunfire_pings[i].time -= delta
		if _gunfire_pings[i].time <= 0.0:
			_gunfire_pings.remove_at(i)
		i -= 1
	queue_redraw()

func _draw() -> void:
	if player_camera == null or not is_instance_valid(player_camera):
		return

	var center := size.x * 0.5
	var half_w := COMPASS_WIDTH * 0.5

	# Подложка компаса
	draw_rect(Rect2(center - half_w, 0, COMPASS_WIDTH, COMPASS_HEIGHT), Color(0.04, 0.06, 0.08, 0.55), true)
	draw_line(Vector2(center - half_w, COMPASS_HEIGHT), Vector2(center + half_w, COMPASS_HEIGHT), Color(0.4, 0.45, 0.5, 0.5), 1.5)

	# Центральная риска прицеливания
	draw_line(Vector2(center, 0), Vector2(center, 12), Color(1.0, 0.85, 0.25, 0.9), 2.0)

	var cam_yaw: float = -player_camera.global_rotation.y
	var font := ThemeDB.fallback_font

	# Деления сторон света
	var directions := [
		["N", 0.0], ["NE", 45.0], ["E", 90.0], ["SE", 135.0],
		["S", 180.0], ["SW", 225.0], ["W", 270.0], ["NW", 315.0]
	]

	for d in directions:
		var name: String = d[0]
		var deg: float = d[1]
		var rad: float = deg_to_rad(deg)
		var diff := fposmod(rad - cam_yaw + PI, TAU) - PI
		if absf(diff) < FOV_ANGLE * 0.5:
			var x := center + (diff / (FOV_ANGLE * 0.5)) * half_w
			draw_line(Vector2(x, 4), Vector2(x, 14), Color(0.8, 0.85, 0.9, 0.7), 1.0)
			var sz := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
			draw_string(font, Vector2(x - sz.x * 0.5, 28), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))

	# Метки секторов [A], [B], [C]
	for sec in sectors:
		var sec_pos: Vector3 = sec.pos
		var to_sec := sec_pos - player_camera.global_position
		var dist := int(round(Vector2(to_sec.x, to_sec.z).length()))
		var angle_to_sec := atan2(-to_sec.x, -to_sec.z)
		var diff := fposmod(angle_to_sec - cam_yaw + PI, TAU) - PI

		if absf(diff) < FOV_ANGLE * 0.5:
			var x := center + (diff / (FOV_ANGLE * 0.5)) * half_w
			var label_text := "[%s] %dm" % [sec.name, dist]
			var owner: String = str(sec.get("owner", "NEUTRAL"))
			var col := Color(0.85, 0.85, 0.85)
			if owner.contains("RED"):
				col = Color(1.0, 0.35, 0.30)
			elif owner.contains("IRON"):
				col = Color(0.40, 0.65, 1.0)
			var sz := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
			draw_string(font, Vector2(x - sz.x * 0.5, COMPASS_HEIGHT + 16), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)

	# Метки вражеской стрельбы
	for ping in _gunfire_pings:
		var to_ping: Vector3 = ping.pos - player_camera.global_position
		var angle_ping := atan2(-to_ping.x, -to_ping.z)
		var diff := fposmod(angle_ping - cam_yaw + PI, TAU) - PI
		if absf(diff) < FOV_ANGLE * 0.5:
			var x := center + (diff / (FOV_ANGLE * 0.5)) * half_w
			var alpha: float = clampf(ping.time / 1.5, 0.0, 1.0)
			draw_circle(Vector2(x, COMPASS_HEIGHT - 4), 4.5, Color(1.0, 0.15, 0.1, alpha))
