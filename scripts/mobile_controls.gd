extends Control
class_name MobileControls

## Полностью кастомное мобильное управление:
## - аналоговый джойстик слева
## - свайп-обзор по свободной части экрана
## - круглые кнопки огня / перезарядки / приседа / прыжка / гранаты / перевязки
## Всё считается в координатах экрана и не зависит от эмуляции мыши.

signal move_changed(value: Vector2)
signal look_delta(delta: Vector2)
signal fire_changed(pressed: bool)
signal aim_changed(pressed: bool)
signal reload_pressed
signal stance_down_pressed
signal stance_up_pressed
signal grenade_pressed
signal grenade_released
signal grenade_changed(pressed: bool)
signal smoke_pressed
signal heal_pressed
signal peek_left_changed(pressed: bool)
signal peek_right_changed(pressed: bool)
signal cycle_weapon_pressed
signal interact_pressed
signal drone_pressed
signal drone_vertical_changed(direction: float, pressed: bool)
signal sidearm_pressed
signal shovel_pressed

const JOY_RADIUS := 92.0
const JOY_DEADZONE := 0.12
const FIRE_RADIUS := 76.0
const SMALL_RADIUS := 42.0
const LOOK_REFERENCE_SIZE := Vector2(1280.0, 720.0)

var _joy_origin := Vector2.ZERO
var _joy_value := Vector2.ZERO
var _joy_touch := -1
var _look_touch := -1
var _button_touches: Dictionary = {}
var _active: Dictionary = {}
var _aim_on := false
var _interact_visible := false
var _drone_visible := false
var _drone_mode := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	resized.connect(queue_redraw)

func _layout() -> Dictionary:
	var s := size
	return {
		"joy": Vector2(150.0, s.y - 155.0),
		"fire": Vector2(s.x - 118.0, s.y - 122.0),
		"reload": Vector2(s.x - 118.0, s.y - 292.0),
		"aim": Vector2(s.x - 118.0, s.y - 402.0),
		"crouch": Vector2(s.x - 288.0, s.y - 120.0),
		"jump": Vector2(s.x - 288.0, s.y - 238.0),
		"grenade": Vector2(s.x - 288.0, s.y - 355.0),
		"smoke": Vector2(s.x - 378.0, s.y - 355.0),
		"heal": Vector2(s.x - 198.0, s.y - 355.0),
		"peek_left": Vector2(s.x - 386.0, s.y - 466.0),
		"peek_right": Vector2(s.x - 294.0, s.y - 466.0),
		"weapon": Vector2(s.x - 118.0, s.y - 512.0),
		"interact": Vector2(s.x - 195.0, s.y - 530.0),
		"drone": Vector2(s.x - 478.0, s.y - 355.0),
		"sidearm": Vector2(maxf(210.0, s.x - 478.0), s.y - 245.0),
		"shovel": Vector2(maxf(210.0, s.x - 478.0), s.y - 155.0),
	}

func set_interact_visible(is_visible: bool) -> void:
	if _interact_visible == is_visible:
		return
	_interact_visible = is_visible
	queue_redraw()

func set_drone_visible(is_visible: bool) -> void:
	if _drone_visible == is_visible:
		return
	_drone_visible = is_visible
	queue_redraw()

func set_drone_mode(enabled: bool) -> void:
	if _drone_mode == enabled:
		return
	_drone_mode = enabled
	queue_redraw()

func reset_aim() -> void:
	if _aim_on:
		_aim_on = false
		aim_changed.emit(false)
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag:
		_touch_drag(event.index, event.position, event.relative)

func _touch_down(index: int, pos: Vector2) -> void:
	if _button_touches.has(index):
		return
	var l := _layout()
	var ids := ["fire", "reload", "aim", "crouch", "jump", "grenade", "smoke", "heal", "peek_left", "peek_right", "weapon", "interact", "drone", "sidearm", "shovel"]
	if _drone_mode:
		ids = ["fire", "crouch", "jump", "drone"]
	for id in ids:
		if id == "interact" and not _interact_visible:
			continue
		if id == "drone" and not _drone_visible:
			continue
		var radius := FIRE_RADIUS if id == "fire" else SMALL_RADIUS
		if pos.distance_to(l[id]) <= radius * 1.15:
			_button_touches[index] = id
			_active[id] = true
			_press(id)
			queue_redraw()
			return
	if _joy_touch == -1 and pos.distance_to(l.joy) <= JOY_RADIUS * 1.7:
		_joy_touch = index
		_joy_origin = l.joy
		_set_joy(Vector2.ZERO)
		return
	if _look_touch == -1:
		_look_touch = index

func _touch_up(index: int) -> void:
	if _button_touches.has(index):
		var id: String = _button_touches[index]
		_button_touches.erase(index)
		_active.erase(id)
		if id == "fire":
			fire_changed.emit(false)
		elif id == "grenade":
			grenade_released.emit()
			grenade_changed.emit(false)
		elif _drone_mode and id == "jump":
			drone_vertical_changed.emit(1.0, false)
		elif _drone_mode and id == "crouch":
			drone_vertical_changed.emit(-1.0, false)
		elif id == "peek_left":
			peek_left_changed.emit(false)
		elif id == "peek_right":
			peek_right_changed.emit(false)
		queue_redraw()
		return
	if index == _joy_touch:
		_joy_touch = -1
		_set_joy(Vector2.ZERO)
	elif index == _look_touch:
		_look_touch = -1

func _touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
	if index == _joy_touch:
		var d := pos - _joy_origin
		if d.length() > JOY_RADIUS:
			d = d.normalized() * JOY_RADIUS
		_set_joy(d / JOY_RADIUS)
	elif index == _look_touch:
		var normalized_relative := Vector2(
			relative.x * LOOK_REFERENCE_SIZE.x / maxf(size.x, 1.0),
			relative.y * LOOK_REFERENCE_SIZE.y / maxf(size.y, 1.0)
		)
		look_delta.emit(normalized_relative)

func _press(id: String) -> void:
	match id:
		"fire":
			fire_changed.emit(true)
		"aim":
			_aim_on = not _aim_on
			aim_changed.emit(_aim_on)
		"reload":
			reload_pressed.emit()
		"crouch":
			if _drone_mode:
				drone_vertical_changed.emit(-1.0, true)
			else:
				stance_down_pressed.emit()
		"jump":
			if _drone_mode:
				drone_vertical_changed.emit(1.0, true)
			else:
				stance_up_pressed.emit()
		"grenade":
			grenade_pressed.emit()
			grenade_changed.emit(true)
		"smoke":
			smoke_pressed.emit()
		"heal":
			heal_pressed.emit()
		"peek_left":
			peek_left_changed.emit(true)
		"peek_right":
			peek_right_changed.emit(true)
		"weapon":
			cycle_weapon_pressed.emit()
		"interact":
			interact_pressed.emit()
		"drone":
			drone_pressed.emit()
		"sidearm":
			sidearm_pressed.emit()
		"shovel":
			shovel_pressed.emit()

func _set_joy(value: Vector2) -> void:
	var v := value
	var length := v.length()
	if length < JOY_DEADZONE:
		v = Vector2.ZERO
	else:
		v = v.normalized() * ((length - JOY_DEADZONE) / (1.0 - JOY_DEADZONE))
	_joy_value = v
	move_changed.emit(v)
	queue_redraw()

func _draw() -> void:
	var l := _layout()
	var font := ThemeDB.fallback_font

	# Джойстик
	draw_circle(l.joy, JOY_RADIUS, Color(0.012, 0.016, 0.019, 0.70))
	draw_arc(l.joy, JOY_RADIUS, 0.0, TAU, 64, Color(0.88, 0.92, 0.93, 0.50), 2.0, true)
	var knob: Vector2 = l.joy + _joy_value * JOY_RADIUS
	draw_circle(knob, JOY_RADIUS * 0.40, Color(0.035, 0.045, 0.05, 0.92))
	draw_arc(knob, JOY_RADIUS * 0.40, 0.0, TAU, 48, Color(0.96, 0.97, 0.97, 0.76), 1.8, true)
	if _drone_mode:
		_draw_button(l.fire, FIRE_RADIUS, "", "detonate", Color.BLACK, font, 16)
		_draw_button(l.jump, SMALL_RADIUS, "", "drone_up", Color.BLACK, font, 11)
		_draw_button(l.crouch, SMALL_RADIUS, "", "drone_down", Color.BLACK, font, 12)
		_draw_button(l.drone, SMALL_RADIUS, "", "return", Color.BLACK, font, 10)
		return

	_draw_button(l.fire, FIRE_RADIUS, "", "fire", Color.BLACK, font, 18)
	_draw_button(l.reload, SMALL_RADIUS, "", "reload", Color.BLACK, font, 12)
	_draw_button(l.aim, SMALL_RADIUS, "", "aim", Color.BLACK, font, 12)
	_draw_button(l.crouch, SMALL_RADIUS, "", "crouch", Color.BLACK, font, 11)
	_draw_button(l.jump, SMALL_RADIUS, "", "jump", Color.BLACK, font, 12)
	_draw_button(l.grenade, SMALL_RADIUS, "", "grenade", Color.BLACK, font, 11)
	_draw_button(l.smoke, SMALL_RADIUS, "", "smoke", Color.BLACK, font, 12)
	_draw_button(l.heal, SMALL_RADIUS, "", "heal", Color.BLACK, font, 12)
	_draw_button(l.peek_left, SMALL_RADIUS, "", "peek_left", Color.BLACK, font, 10)
	_draw_button(l.peek_right, SMALL_RADIUS, "", "peek_right", Color.BLACK, font, 9)
	_draw_button(l.weapon, SMALL_RADIUS, "", "weapon", Color.BLACK, font, 10)
	if _interact_visible:
		_draw_button(l.interact, SMALL_RADIUS, "", "interact", Color.BLACK, font, 11)
	if _drone_visible:
		_draw_button(l.drone, SMALL_RADIUS, "", "drone", Color.BLACK, font, 11)
	_draw_button(l.sidearm, SMALL_RADIUS, "", "sidearm", Color.BLACK, font, 11)
	_draw_button(l.shovel, SMALL_RADIUS, "", "shovel", Color.BLACK, font, 11)

func _draw_button(center: Vector2, radius: float, label: String, id: String, color: Color, font: Font, font_size: int) -> void:
	var state_id := id
	match id:
		"detonate": state_id = "fire"
		"drone_up": state_id = "jump"
		"drone_down": state_id = "crouch"
		"return": state_id = "drone"
	var active: bool = _aim_on if state_id == "aim" else bool(_active.get(state_id, false))
	draw_circle(center, radius, Color(0.012, 0.016, 0.019, 0.82))
	draw_arc(center, radius - 1.0, 0.0, TAU, 56, Color(0.88, 0.92, 0.93, 0.92 if active else 0.56), 2.5 if active else 1.6, true)
	_draw_icon(center, radius * 0.48, id)

func _draw_icon(center: Vector2, size: float, id: String) -> void:
	var white := Color(0.94, 0.96, 0.96, 0.98)
	var thin := maxf(1.8, size * 0.10)
	match id:
		"fire", "detonate":
			draw_circle(center, size * 0.18, white)
			for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
				var direction := Vector2.RIGHT.rotated(angle)
				draw_line(center + direction * size * 0.42, center + direction * size * 0.78, white, thin, true)
		"aim":
			draw_arc(center, size * 0.32, 0.0, TAU, 32, white, thin, true)
			draw_line(center + Vector2(-size * 0.8, 0), center + Vector2(-size * 0.38, 0), white, thin, true)
			draw_line(center + Vector2(size * 0.38, 0), center + Vector2(size * 0.8, 0), white, thin, true)
			draw_line(center + Vector2(0, -size * 0.8), center + Vector2(0, -size * 0.38), white, thin, true)
			draw_line(center + Vector2(0, size * 0.38), center + Vector2(0, size * 0.8), white, thin, true)
		"reload":
			draw_rect(Rect2(center + Vector2(-size * 0.35, -size * 0.58), Vector2(size * 0.7, size * 1.08)), white, false, thin)
			draw_line(center + Vector2(-size * 0.2, -size * 0.28), center + Vector2(size * 0.2, -size * 0.28), white, thin, true)
			draw_line(center + Vector2(-size * 0.2, size * 0.02), center + Vector2(size * 0.2, size * 0.02), white, thin, true)
		"jump", "drone_up":
			_draw_arrow(center, Vector2.UP, size, white, thin)
		"drone_down":
			_draw_arrow(center, Vector2.DOWN, size, white, thin)
		"crouch":
			draw_circle(center + Vector2(-size * 0.18, -size * 0.42), size * 0.17, white)
			draw_line(center + Vector2(-size * 0.08, -size * 0.22), center + Vector2(size * 0.32, size * 0.06), white, thin, true)
			draw_line(center + Vector2(size * 0.16, -size * 0.02), center + Vector2(-size * 0.12, size * 0.42), white, thin, true)
			draw_line(center + Vector2(size * 0.22, size * 0.02), center + Vector2(size * 0.54, size * 0.40), white, thin, true)
		"grenade":
			draw_circle(center, size * 0.38, white, false, thin)
			draw_rect(Rect2(center + Vector2(-size * 0.1, -size * 0.62), Vector2(size * 0.22, size * 0.18)), white, true)
			draw_line(center + Vector2(size * 0.1, -size * 0.56), center + Vector2(size * 0.42, -size * 0.72), white, thin, true)
		"smoke":
			draw_circle(center + Vector2(-size * 0.27, 0), size * 0.22, white, false, thin)
			draw_circle(center, size * 0.32, white, false, thin)
			draw_circle(center + Vector2(size * 0.28, size * 0.05), size * 0.2, white, false, thin)
			draw_line(center + Vector2(-size * 0.34, size * 0.26), center + Vector2(size * 0.38, size * 0.26), white, thin, true)
		"heal":
			draw_rect(Rect2(center + Vector2(-size * 0.16, -size * 0.62), Vector2(size * 0.32, size * 1.24)), white, true)
			draw_rect(Rect2(center + Vector2(-size * 0.62, -size * 0.16), Vector2(size * 1.24, size * 0.32)), white, true)
		"peek_left":
			_draw_arrow(center, Vector2.LEFT, size, white, thin)
		"peek_right":
			_draw_arrow(center, Vector2.RIGHT, size, white, thin)
		"weapon":
			draw_line(center + Vector2(-size * 0.62, size * 0.02), center + Vector2(size * 0.52, size * 0.02), white, thin * 1.4, true)
			draw_line(center + Vector2(-size * 0.42, -size * 0.20), center + Vector2(size * 0.48, -size * 0.20), white, thin, true)
			draw_line(center + Vector2(size * 0.12, size * 0.04), center + Vector2(-size * 0.02, size * 0.5), white, thin, true)
			draw_line(center + Vector2(-size * 0.62, -size * 0.05), center + Vector2(-size * 0.62, size * 0.16), white, thin, true)
		"sidearm":
			var slide := PackedVector2Array([
				center + Vector2(-size * 0.56, -size * 0.28),
				center + Vector2(size * 0.48, -size * 0.28),
				center + Vector2(size * 0.62, -size * 0.08),
				center + Vector2(-size * 0.48, -size * 0.08),
			])
			draw_colored_polygon(slide, white)
			draw_line(center + Vector2(-size * 0.30, -size * 0.05), center + Vector2(-size * 0.18, size * 0.56), white, thin * 1.8, true)
			draw_line(center + Vector2(-size * 0.18, size * 0.56), center + Vector2(size * 0.12, size * 0.56), white, thin * 1.8, true)
			draw_line(center + Vector2(size * 0.12, size * 0.56), center + Vector2(size * 0.22, -size * 0.05), white, thin * 1.8, true)
			draw_line(center + Vector2(-size * 0.08, -size * 0.38), center + Vector2(size * 0.18, -size * 0.38), white, thin, true)
		"interact":
			draw_rect(Rect2(center + Vector2(-size * 0.45, size * 0.02), Vector2(size * 0.9, size * 0.45)), white, false, thin)
			_draw_arrow(center + Vector2(0, -size * 0.12), Vector2.DOWN, size * 0.48, white, thin)
		"drone", "return":
			for offset in [Vector2(-0.42, -0.42), Vector2(0.42, -0.42), Vector2(-0.42, 0.42), Vector2(0.42, 0.42)]:
				draw_line(center, center + offset * size, white, thin, true)
				draw_circle(center + offset * size, size * 0.20, white, false, thin)
			draw_rect(Rect2(center - Vector2(size * 0.18, size * 0.18), Vector2(size * 0.36, size * 0.36)), white, true)
		"shovel":
			draw_line(center + Vector2(-size * 0.1, size * 0.52), center + Vector2(size * 0.2, -size * 0.24), white, thin * 1.4, true)
			draw_line(center + Vector2(size * 0.2, -size * 0.24), center + Vector2(size * 0.42, -size * 0.62), white, thin * 1.4, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -size * 0.72), center + Vector2(size * 0.46, -size * 0.58), center + Vector2(size * 0.30, -size * 0.30)]), white)

func _draw_arrow(center: Vector2, direction: Vector2, size: float, color: Color, width: float) -> void:
	var tip := center + direction * size * 0.62
	var tail := center - direction * size * 0.50
	draw_line(tail, tip, color, width * 1.4, true)
	var side := Vector2(-direction.y, direction.x) * size * 0.34
	draw_line(tip, tip - direction * size * 0.33 + side, color, width * 1.4, true)
	draw_line(tip, tip - direction * size * 0.33 - side, color, width * 1.4, true)
