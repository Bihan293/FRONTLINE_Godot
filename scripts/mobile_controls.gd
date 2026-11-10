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
signal heal_released
signal peek_left_changed(pressed: bool)
signal peek_right_changed(pressed: bool)
signal cycle_weapon_pressed
signal interact_pressed
signal drone_pressed
signal drone_vertical_changed(direction: float, pressed: bool)
signal sidearm_pressed
signal shovel_pressed
signal equip_prev_pressed
signal equip_next_pressed

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
var _vehicle_mode := false
var _vehicle_input := Vector2.ZERO
var _equip_icon_id := "rifle"
var _equip_label := "АВТОМАТ"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	resized.connect(queue_redraw)

func _joy_radius() -> float:
	var sc: float = GameSettings.hud_scale if ("hud_scale" in GameSettings) else 1.0
	return JOY_RADIUS * sc

func _fire_radius() -> float:
	var sc: float = GameSettings.hud_scale if ("hud_scale" in GameSettings) else 1.0
	return FIRE_RADIUS * sc

func _small_radius() -> float:
	var sc: float = GameSettings.hud_scale if ("hud_scale" in GameSettings) else 1.0
	return SMALL_RADIUS * sc

var _layout_cache: Dictionary = {}
var _layout_cache_key := ""

func _layout() -> Dictionary:
	var cache_key := "%s_%s_%s_%s" % [str(size), str(GameSettings.hud_scale), str(GameSettings.hud_preset), str(GameSettings.hud_layout_version)]
	if cache_key == _layout_cache_key and not _layout_cache.is_empty():
		return _layout_cache
	_layout_cache_key = cache_key
	var s := size
	var sc: float = GameSettings.hud_scale
	var preset: int = GameSettings.hud_preset

	var base: Dictionary = {}
	if preset == 3:
		# Левша: джойстик справа, кнопки действий слева (безопасные зоны без наложений)
		base = {
			"joy": Vector2(s.x - 170.0 * sc, s.y - 160.0 * sc),
			"fire": Vector2(130.0 * sc, s.y - 135.0 * sc),
			"reload": Vector2(120.0 * sc, s.y - 275.0 * sc),
			"aim": Vector2(120.0 * sc, s.y - 395.0 * sc),
			"crouch": Vector2(275.0 * sc, s.y - 125.0 * sc),
			"jump": Vector2(275.0 * sc, s.y - 235.0 * sc),
			"grenade": Vector2(310.0 * sc, s.y - 355.0 * sc),
			"smoke": Vector2(415.0 * sc, s.y - 355.0 * sc),
			"heal": Vector2(205.0 * sc, s.y - 340.0 * sc),
			"peek_left": Vector2(305.0 * sc, s.y - 475.0 * sc),
			"peek_right": Vector2(410.0 * sc, s.y - 475.0 * sc),
			"weapon": Vector2(115.0 * sc, s.y - 515.0 * sc),
			"interact": Vector2(235.0 * sc, s.y - 580.0 * sc),
			"drone": Vector2(520.0 * sc, s.y - 355.0 * sc),
		}
	elif preset == 1:
		# Компактный: кнопки сгруппированы плотнее к углам
		base = {
			"joy": Vector2(125.0 * sc, s.y - 130.0 * sc),
			"fire": Vector2(s.x - 95.0 * sc, s.y - 95.0 * sc),
			"reload": Vector2(s.x - 95.0 * sc, s.y - 230.0 * sc),
			"aim": Vector2(s.x - 95.0 * sc, s.y - 325.0 * sc),
			"crouch": Vector2(s.x - 225.0 * sc, s.y - 95.0 * sc),
			"jump": Vector2(s.x - 225.0 * sc, s.y - 190.0 * sc),
			"grenade": Vector2(s.x - 225.0 * sc, s.y - 285.0 * sc),
			"smoke": Vector2(s.x - 305.0 * sc, s.y - 285.0 * sc),
			"heal": Vector2(s.x - 160.0 * sc, s.y - 285.0 * sc),
			"peek_left": Vector2(s.x - 310.0 * sc, s.y - 380.0 * sc),
			"peek_right": Vector2(s.x - 230.0 * sc, s.y - 380.0 * sc),
			"weapon": Vector2(s.x - 95.0 * sc, s.y - 415.0 * sc),
			"interact": Vector2(s.x - 160.0 * sc, s.y - 430.0 * sc),
			"drone": Vector2(s.x - 385.0 * sc, s.y - 285.0 * sc),
		}
	elif preset == 2:
		# Разреженный: для больших планшетов
		base = {
			"joy": Vector2(175.0 * sc, s.y - 175.0 * sc),
			"fire": Vector2(s.x - 135.0 * sc, s.y - 135.0 * sc),
			"reload": Vector2(s.x - 135.0 * sc, s.y - 330.0 * sc),
			"aim": Vector2(s.x - 135.0 * sc, s.y - 450.0 * sc),
			"crouch": Vector2(s.x - 330.0 * sc, s.y - 135.0 * sc),
			"jump": Vector2(s.x - 330.0 * sc, s.y - 270.0 * sc),
			"grenade": Vector2(s.x - 330.0 * sc, s.y - 400.0 * sc),
			"smoke": Vector2(s.x - 435.0 * sc, s.y - 400.0 * sc),
			"heal": Vector2(s.x - 225.0 * sc, s.y - 400.0 * sc),
			"peek_left": Vector2(s.x - 440.0 * sc, s.y - 520.0 * sc),
			"peek_right": Vector2(s.x - 335.0 * sc, s.y - 520.0 * sc),
			"weapon": Vector2(s.x - 135.0 * sc, s.y - 570.0 * sc),
			"interact": Vector2(s.x - 225.0 * sc, s.y - 590.0 * sc),
			"drone": Vector2(s.x - 540.0 * sc, s.y - 400.0 * sc),
		}
	else:
		# Стандартный (проверенные безопасные зоны без перекрытия кнопок)
		base = {
			"joy": Vector2(170.0 * sc, s.y - 160.0 * sc),
			"fire": Vector2(s.x - 130.0 * sc, s.y - 135.0 * sc),
			"reload": Vector2(s.x - 120.0 * sc, s.y - 275.0 * sc),
			"aim": Vector2(s.x - 120.0 * sc, s.y - 395.0 * sc),
			"crouch": Vector2(s.x - 275.0 * sc, s.y - 125.0 * sc),
			"jump": Vector2(s.x - 275.0 * sc, s.y - 235.0 * sc),
			"grenade": Vector2(s.x - 310.0 * sc, s.y - 355.0 * sc),
			"smoke": Vector2(s.x - 415.0 * sc, s.y - 355.0 * sc),
			"heal": Vector2(s.x - 205.0 * sc, s.y - 340.0 * sc),
			"peek_left": Vector2(s.x - 410.0 * sc, s.y - 475.0 * sc),
			"peek_right": Vector2(s.x - 305.0 * sc, s.y - 475.0 * sc),
			"weapon": Vector2(s.x - 115.0 * sc, s.y - 515.0 * sc),
			"interact": Vector2(s.x - 235.0 * sc, s.y - 580.0 * sc),
			"drone": Vector2(s.x - 520.0 * sc, s.y - 355.0 * sc),
		}

	# Применяем пользовательские индивидуальные смещения с защитой от вылета за экран
	for k in base.keys():
		var offset := GameSettings.get_hud_button_offset(k) if ("get_hud_button_offset" in GameSettings) else Vector2.ZERO
		var target: Vector2 = base[k] + offset
		var r: float = _joy_radius() if k == "joy" else (_fire_radius() if k == "fire" else _small_radius())
		base[k] = Vector2(clampf(target.x, r + 8.0, s.x - r - 8.0), clampf(target.y, r + 8.0, s.y - r - 8.0))

	# Переключатель снаряжения: иконка в руке + стрелки влево/вправо (сверху справа).
	var er := _small_radius() * 0.80
	base["equip_icon"] = Vector2(s.x - 116.0 * sc, 58.0 * sc + 8.0)
	base["equip_prev"] = base["equip_icon"] + Vector2(-er * 2.35, 0.0)
	base["equip_next"] = base["equip_icon"] + Vector2(er * 2.35, 0.0)

	# Крестовина управления техникой (появляется только внутри джипа).
	var vp := Vector2(s.x - 210.0 * sc, s.y - 190.0 * sc)
	var vr := _fire_radius() * 0.92
	base["veh_up"] = vp + Vector2(0.0, -vr * 1.28)
	base["veh_down"] = vp + Vector2(0.0, vr * 1.28)
	base["veh_left"] = vp + Vector2(-vr * 1.28, 0.0)
	base["veh_right"] = vp + Vector2(vr * 1.28, 0.0)
	base["veh_exit"] = vp + Vector2(0.0, 0.0)
	base["veh_fire"] = Vector2(s.x - 95.0 * sc, s.y - 95.0 * sc)

	_layout_cache = base
	return base

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

func set_vehicle_mode(enabled: bool) -> void:
	if _vehicle_mode == enabled:
		return
	_vehicle_mode = enabled
	_vehicle_input = Vector2.ZERO
	_button_touches.clear()
	_active.clear()
	_set_joy(Vector2.ZERO)
	queue_redraw()

func set_equipment_info(icon_id: String, label: String) -> void:
	_equip_icon_id = icon_id
	_equip_label = label
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
	if _vehicle_mode:
		var vehicle_ids := ["veh_up", "veh_down", "veh_left", "veh_right", "veh_exit", "veh_fire"]
		for id in vehicle_ids:
			var radius := _fire_radius() if id == "veh_fire" else _fire_radius() * 0.92
			if pos.distance_to(l[id]) <= radius * 1.05:
				_button_touches[index] = id
				_active[id] = true
				_apply_vehicle_button(id, true)
				queue_redraw()
				return
		if _look_touch == -1:
			_look_touch = index
		return
	var ids := ["fire", "reload", "aim", "crouch", "jump", "grenade", "smoke", "heal", "peek_left", "peek_right", "weapon", "interact", "drone", "equip_prev", "equip_next"]
	if _drone_mode:
		ids = ["fire", "crouch", "jump", "drone"]
	for id in ids:
		if id == "interact" and not _interact_visible:
			continue
		if id == "drone" and not _drone_visible:
			continue
		var radius := _fire_radius() if id == "fire" else _small_radius()
		if pos.distance_to(l[id]) <= radius * 1.15:
			_button_touches[index] = id
			_active[id] = true
			_press(id)
			queue_redraw()
			return
	if _joy_touch == -1 and pos.distance_to(l.joy) <= _joy_radius() * 1.7:
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
		if _vehicle_mode and id.begins_with("veh_"):
			_apply_vehicle_button(id, false)
			queue_redraw()
			return
		if id == "fire":
			fire_changed.emit(false)
		elif id == "grenade":
			grenade_released.emit()
			grenade_changed.emit(false)
		elif _drone_mode and id == "jump":
			drone_vertical_changed.emit(1.0, false)
		elif _drone_mode and id == "crouch":
			drone_vertical_changed.emit(-1.0, false)
		elif id == "heal":
			heal_released.emit()
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
		var jr := _joy_radius()
		if d.length() > jr:
			d = d.normalized() * jr
		_set_joy(d / jr)
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
		"equip_prev":
			equip_prev_pressed.emit()
		"equip_next":
			equip_next_pressed.emit()

func _apply_vehicle_button(id: String, pressed: bool) -> void:
	var dir := Vector2.ZERO
	match id:
		"veh_up":
			dir = Vector2(0.0, -1.0)
		"veh_down":
			dir = Vector2(0.0, 1.0)
		"veh_left":
			dir = Vector2(-1.0, 0.0)
		"veh_right":
			dir = Vector2(1.0, 0.0)
		"veh_exit":
			if pressed:
				interact_pressed.emit()
			return
		"veh_fire":
			fire_changed.emit(pressed)
			return
	if pressed:
		var axes := Vector2(_vehicle_input.x, _vehicle_input.y)
		if dir.x != 0.0:
			axes.x = dir.x
		else:
			axes.y = dir.y
		_vehicle_input = axes
	else:
		if dir.x != 0.0 and is_equal_approx(_vehicle_input.x, dir.x):
			_vehicle_input.x = 0.0
		if dir.y != 0.0 and is_equal_approx(_vehicle_input.y, dir.y):
			_vehicle_input.y = 0.0
	_set_joy(_vehicle_input.limit_length(1.0))

func _set_joy(value: Vector2) -> void:
	var v := value
	var length := v.length()
	if length < JOY_DEADZONE:
		v = Vector2.ZERO
	else:
		v = v.normalized() * ((length - JOY_DEADZONE) / (1.0 - JOY_DEADZONE))
	var changed := _joy_value.distance_squared_to(v) > 0.0004
	_joy_value = v
	move_changed.emit(v)
	if changed:
		queue_redraw()

func _draw() -> void:
	var l := _layout()
	var font := ThemeDB.fallback_font

	# Джойстик
	var jr := _joy_radius()
	var fr := _fire_radius()
	var sr := _small_radius()
	draw_circle(l.joy, jr, Color(0.012, 0.016, 0.019, 0.70))
	draw_arc(l.joy, jr, 0.0, TAU, 64, Color(0.88, 0.92, 0.93, 0.50), 2.0, true)
	var knob: Vector2 = l.joy + _joy_value * jr
	draw_circle(knob, jr * 0.40, Color(0.035, 0.045, 0.05, 0.92))
	draw_arc(knob, jr * 0.40, 0.0, TAU, 48, Color(0.96, 0.97, 0.97, 0.76), 1.8, true)
	if _vehicle_mode:
		var vr := _fire_radius() * 0.92
		_draw_button(l.veh_up, vr, "", "veh_up", Color.BLACK, font, 12)
		_draw_button(l.veh_down, vr, "", "veh_down", Color.BLACK, font, 12)
		_draw_button(l.veh_left, vr, "", "veh_left", Color.BLACK, font, 12)
		_draw_button(l.veh_right, vr, "", "veh_right", Color.BLACK, font, 12)
		_draw_button(l.veh_exit, vr * 0.80, "", "exit_vehicle", Color.BLACK, font, 9)
		_draw_button(l.veh_fire, fr, "", "fire", Color.BLACK, font, 18)
		return
	if _drone_mode:
		_draw_button(l.fire, fr, "", "detonate", Color.BLACK, font, 16)
		_draw_button(l.jump, sr, "", "drone_up", Color.BLACK, font, 11)
		_draw_button(l.crouch, sr, "", "drone_down", Color.BLACK, font, 12)
		_draw_button(l.drone, sr, "", "return", Color.BLACK, font, 10)
		return

	_draw_button(l.fire, fr, "", "fire", Color.BLACK, font, 18)
	_draw_button(l.reload, sr, "", "reload", Color.BLACK, font, 12)
	_draw_button(l.aim, sr, "", "aim", Color.BLACK, font, 12)
	_draw_button(l.crouch, sr, "", "crouch", Color.BLACK, font, 11)
	_draw_button(l.jump, sr, "", "jump", Color.BLACK, font, 12)
	_draw_button(l.grenade, sr, "", "grenade", Color.BLACK, font, 11)
	_draw_button(l.smoke, sr, "", "smoke", Color.BLACK, font, 12)
	_draw_button(l.heal, sr, "", "heal", Color.BLACK, font, 12)
	_draw_button(l.peek_left, sr, "", "peek_left", Color.BLACK, font, 10)
	_draw_button(l.peek_right, sr, "", "peek_right", Color.BLACK, font, 9)
	_draw_button(l.weapon, sr, "", "weapon", Color.BLACK, font, 10)
	if _interact_visible:
		_draw_button(l.interact, sr, "", "interact", Color.BLACK, font, 11)
	if _drone_visible:
		_draw_button(l.drone, sr, "", "drone", Color.BLACK, font, 11)
	# Снаряжение в руке: иконка + стрелки переключения (сверху справа).
	var er := sr * 0.80
	_draw_equip_slot(l.equip_icon, er)
	_draw_button(l.equip_prev, er, "", "equip_prev", Color.BLACK, font, 12)
	_draw_button(l.equip_next, er, "", "equip_next", Color.BLACK, font, 12)

## Иконка предмета в руке (автомат/пистолет/лопата/РПГ) с подписью.
func _draw_equip_slot(center: Vector2, radius: float) -> void:
	var font := ThemeDB.fallback_font
	draw_circle(center, radius, Color(0.012, 0.016, 0.019, 0.72))
	draw_arc(center, radius - 1.0, 0.0, TAU, 24, Color(0.85, 0.90, 0.85, 0.70), 2.0, true)
	_draw_icon(center, radius * 0.55, _equip_icon_id)
	var text_sz := font.get_string_size(_equip_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
	draw_string(font, center + Vector2(-text_sz.x * 0.5, radius + 13.0), _equip_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.92, 0.95, 0.90, 0.85))

func _draw_button(center: Vector2, radius: float, label: String, id: String, color: Color, font: Font, font_size: int) -> void:
	var state_id := id
	match id:
		"detonate": state_id = "fire"
		"drone_up": state_id = "jump"
		"drone_down": state_id = "crouch"
		"return": state_id = "drone"
	var active: bool = _aim_on if state_id == "aim" else bool(_active.get(state_id, false))
	draw_circle(center, radius, Color(0.012, 0.016, 0.019, 0.82))
	draw_arc(center, radius - 1.0, 0.0, TAU, 24, Color(0.88, 0.92, 0.93, 0.92 if active else 0.56), 2.5 if active else 1.6, true)
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
		"equip_prev", "veh_left":
			_draw_arrow(center, Vector2.LEFT, size, white, thin)
		"equip_next", "veh_right":
			_draw_arrow(center, Vector2.RIGHT, size, white, thin)
		"veh_up":
			_draw_arrow(center, Vector2.UP, size, white, thin)
		"veh_down":
			_draw_arrow(center, Vector2.DOWN, size, white, thin)
		"exit_vehicle":
			draw_rect(Rect2(center + Vector2(-size * 0.36, -size * 0.55), Vector2(size * 0.5, size * 1.1)), white, false, thin)
			_draw_arrow(center + Vector2(size * 0.36, 0), Vector2.RIGHT, size * 0.52, white, thin)
		"rifle":
			draw_line(center + Vector2(-size * 0.75, size * 0.06), center + Vector2(size * 0.60, size * 0.06), white, thin * 1.5, true)
			draw_line(center + Vector2(-size * 0.25, size * 0.04), center + Vector2(-size * 0.05, size * 0.46), white, thin, true)
			draw_line(center + Vector2(size * 0.34, size * 0.06), center + Vector2(size * 0.46, -size * 0.26), white, thin, true)
			draw_line(center + Vector2(size * 0.60, -size * 0.09), center + Vector2(size * 0.60, size * 0.20), white, thin, true)
		"rpg":
			draw_line(center + Vector2(-size * 0.72, 0), center + Vector2(size * 0.72, 0), white, thin * 2.0, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(size * 0.72, 0), center + Vector2(size * 0.36, -size * 0.28), center + Vector2(size * 0.36, size * 0.28)]), white)
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
