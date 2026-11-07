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
signal smoke_pressed
signal heal_pressed
signal peek_left_changed(pressed: bool)
signal peek_right_changed(pressed: bool)
signal cycle_weapon_pressed
signal interact_pressed

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
	}

func set_interact_visible(is_visible: bool) -> void:
	if _interact_visible == is_visible:
		return
	_interact_visible = is_visible
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
	for id in ["fire", "reload", "aim", "crouch", "jump", "grenade", "smoke", "heal", "peek_left", "peek_right", "weapon", "interact"]:
		if id == "interact" and not _interact_visible:
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
			stance_down_pressed.emit()
		"jump":
			stance_up_pressed.emit()
		"grenade":
			grenade_pressed.emit()
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
	draw_circle(l.joy, JOY_RADIUS, Color(0.04, 0.06, 0.07, 0.38))
	draw_arc(l.joy, JOY_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.28), 3.0, true)
	var knob: Vector2 = l.joy + _joy_value * JOY_RADIUS
	draw_circle(knob, JOY_RADIUS * 0.40, Color(0.85, 0.92, 1.0, 0.50))
	draw_arc(knob, JOY_RADIUS * 0.40, 0.0, TAU, 48, Color(1, 1, 1, 0.45), 2.0, true)

	_draw_button(l.fire, FIRE_RADIUS, "ОГОНЬ", "fire", Color(0.80, 0.18, 0.12, 0.50), font, 18)
	_draw_button(l.reload, SMALL_RADIUS, "ПЕРЕЗАР.", "reload", Color(0.12, 0.32, 0.55, 0.48), font, 12)
	_draw_button(l.aim, SMALL_RADIUS, "ПРИЦЕЛ", "aim", Color(0.22, 0.38, 0.28, 0.48), font, 12)
	_draw_button(l.crouch, SMALL_RADIUS, "ПРИСЕСТЬ", "crouch", Color(0.20, 0.34, 0.20, 0.48), font, 11)
	_draw_button(l.jump, SMALL_RADIUS, "ПРЫЖОК", "jump", Color(0.34, 0.30, 0.12, 0.48), font, 12)
	_draw_button(l.grenade, SMALL_RADIUS, "ГРАНАТА", "grenade", Color(0.55, 0.35, 0.12, 0.48), font, 11)
	_draw_button(l.smoke, SMALL_RADIUS, "ДЫМ", "smoke", Color(0.35, 0.38, 0.42, 0.48), font, 12)
	_draw_button(l.heal, SMALL_RADIUS, "БИНТ", "heal", Color(0.18, 0.45, 0.45, 0.48), font, 12)
	_draw_button(l.peek_left, SMALL_RADIUS, "ВЛЕВО", "peek_left", Color(0.24, 0.34, 0.45, 0.50), font, 10)
	_draw_button(l.peek_right, SMALL_RADIUS, "ВПРАВО", "peek_right", Color(0.24, 0.34, 0.45, 0.50), font, 9)
	_draw_button(l.weapon, SMALL_RADIUS, "ОРУЖИЕ", "weapon", Color(0.50, 0.36, 0.14, 0.52), font, 10)
	if _interact_visible:
		_draw_button(l.interact, SMALL_RADIUS, "ВЗЯТЬ", "interact", Color(0.20, 0.48, 0.30, 0.62), font, 11)

func _draw_button(center: Vector2, radius: float, label: String, id: String, color: Color, font: Font, font_size: int) -> void:
	var active: bool = _aim_on if id == "aim" else bool(_active.get(id, false))
	var fill := color.lightened(0.25) if active else color
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.40 if active else 0.28), 2.5, true)
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(
		font,
		center + Vector2(-text_size.x * 0.5, font_size * 0.35),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(1, 1, 1, 0.95)
	)
