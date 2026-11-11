extends CanvasLayer
class_name FRONTLINEHUDCustomizer

## Интерактивный редактор расположения мобильных кнопок HUD.
## Позволяет игроку пальцем перетаскивать любые кнопки управления,
## выбирать пресеты (Стандарт / Компакт / Разреженный / Для левши)
## и настраивать масштаб кнопок. Вёрстка живёт в scenes/HUDCustomizer.tscn.

signal closed

const BUTTON_LABELS: Dictionary = {
	"joy": "ДЖОЙСТИК",
	"fire": "ОГОНЬ",
	"reload": "ПЕРЕЗАРЯДКА",
	"aim": "ПРИЦЕЛ",
	"crouch": "ПРИСЕД",
	"jump": "ПРЫЖОК",
	"grenade": "ГРАНАТА",
	"smoke": "ДЫМ",
	"heal": "БИНТ",
	"peek_left": "НАКЛОН Л.",
	"peek_right": "НАКЛОН П.",
	"weapon": "ОРУЖИЕ",
	"interact": "ВЗЯТЬ",
	"drone": "ДРОН",
	"sidearm": "ПИСТОЛЕТ",
	"shovel": "ЛОПАТА",
}

@onready var _preset_btn: Button = %PresetButton
@onready var _scale_btn: Button = %ScaleButton
@onready var _reset_btn: Button = %ResetButton
@onready var _save_btn: Button = %SaveButton
@onready var _canvas: Control = %Canvas

var _dragged_id: String = ""
var _drag_touch: int = -1
var _drag_touch_offset := Vector2.ZERO

func _ready() -> void:
	_preset_btn.pressed.connect(_cycle_preset)
	_scale_btn.pressed.connect(_cycle_scale)
	_reset_btn.pressed.connect(_reset_layout)
	_save_btn.pressed.connect(_save_and_exit)
	_canvas.draw.connect(_draw_canvas)
	_refresh_buttons()

func _refresh_buttons() -> void:
	_preset_btn.text = "ПРЕСЕТ: " + GameSettings.hud_preset_name()
	_scale_btn.text = "РАЗМЕР: %d%%" % int(round(GameSettings.hud_scale * 100.0))

func _cycle_preset() -> void:
	GameSettings.cycle_hud_preset()
	_refresh_buttons()
	_canvas.queue_redraw()

func _cycle_scale() -> void:
	var scales := [0.85, 1.0, 1.15, 1.30]
	var current_idx := 1
	for i in range(scales.size()):
		if is_equal_approx(GameSettings.hud_scale, scales[i]):
			current_idx = i
			break
	var next_idx: int = (current_idx + 1) % scales.size()
	GameSettings.set_hud_scale(scales[next_idx])
	_refresh_buttons()
	_canvas.queue_redraw()

func _reset_layout() -> void:
	GameSettings.reset_hud_layout()
	_refresh_buttons()
	_canvas.queue_redraw()

func _save_and_exit() -> void:
	GameSettings.save_settings()
	closed.emit()
	queue_free()

func _get_base_layout(s: Vector2, sc: float, preset: int) -> Dictionary:
	if preset == 3:
		# Левша: безопасные зоны без наложений
		return {
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
			"sidearm": Vector2(minf(s.x - 210.0, 520.0 * sc), s.y - 245.0 * sc),
			"shovel": Vector2(minf(s.x - 210.0, 520.0 * sc), s.y - 135.0 * sc),
		}
	if preset == 1:
		# Компактный
		return {
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
			"sidearm": Vector2(maxf(210.0, s.x - 385.0 * sc), s.y - 190.0 * sc),
			"shovel": Vector2(maxf(210.0, s.x - 385.0 * sc), s.y - 100.0 * sc),
		}
	if preset == 2:
		# Разреженный
		return {
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
			"sidearm": Vector2(maxf(210.0, s.x - 540.0 * sc), s.y - 275.0 * sc),
			"shovel": Vector2(maxf(210.0, s.x - 540.0 * sc), s.y - 175.0 * sc),
		}
	# Стандарт
	return {
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
		"sidearm": Vector2(maxf(210.0, s.x - 520.0 * sc), s.y - 245.0 * sc),
		"shovel": Vector2(maxf(210.0, s.x - 520.0 * sc), s.y - 135.0 * sc),
	}

func _get_button_positions() -> Dictionary:
	var s := get_viewport().get_visible_rect().size
	var sc := GameSettings.hud_scale
	var preset := GameSettings.hud_preset
	var base := _get_base_layout(s, sc, preset)

	var result: Dictionary = {}
	for k in base.keys():
		var offset := GameSettings.get_hud_button_offset(k)
		var p: Vector2 = base[k] + offset
		result[k] = Vector2(clampf(p.x, 35.0, s.x - 35.0), clampf(p.y, 75.0, s.y - 35.0))
	return result

func _get_base_position(id: String, s: Vector2, sc: float, preset: int) -> Vector2:
	var base := _get_base_layout(s, sc, preset)
	return base.get(id, Vector2(s.x * 0.5, s.y * 0.5))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drag(event.position, event.index)
		else:
			if event.index == _drag_touch:
				_end_drag()
	elif event is InputEventScreenDrag:
		if event.index == _drag_touch and not _dragged_id.is_empty():
			_update_drag(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(event.position, 999)
			else:
				if _drag_touch == 999:
					_end_drag()
	elif event is InputEventMouseMotion:
		if _drag_touch == 999 and not _dragged_id.is_empty():
			_update_drag(event.position)

func _start_drag(pos: Vector2, touch_id: int) -> void:
	if pos.y < 75.0:
		return # Не перехватываем клики по верхней панели управления
	var buttons := _get_button_positions()
	var sc := GameSettings.hud_scale
	for id in buttons.keys():
		var r := 92.0 * sc if id == "joy" else (76.0 * sc if id == "fire" else 42.0 * sc)
		if pos.distance_to(buttons[id]) <= r * 1.25:
			_dragged_id = id
			_drag_touch = touch_id
			_drag_touch_offset = buttons[id] - pos
			_canvas.queue_redraw()
			return

func _update_drag(pos: Vector2) -> void:
	var s := get_viewport().get_visible_rect().size
	var sc := GameSettings.hud_scale
	var r := 92.0 * sc if _dragged_id == "joy" else (76.0 * sc if _dragged_id == "fire" else 42.0 * sc)
	var new_pos: Vector2 = pos + _drag_touch_offset
	new_pos.x = clampf(new_pos.x, r + 12.0, s.x - r - 12.0)
	new_pos.y = clampf(new_pos.y, 75.0 + r * 0.5, s.y - r - 12.0)
	var base_pos := _get_base_position(_dragged_id, s, sc, GameSettings.hud_preset)
	var offset := new_pos - base_pos
	GameSettings.set_hud_button_offset(_dragged_id, offset)
	_canvas.queue_redraw()

func _end_drag() -> void:
	if not _dragged_id.is_empty():
		# QA-optimization: сохранение один раз за перетаскивание, не за каждый пиксель.
		GameSettings.save_settings()
	_dragged_id = ""
	_drag_touch = -1
	_canvas.queue_redraw()

func _draw_canvas() -> void:
	var buttons := _get_button_positions()
	var font := ThemeDB.fallback_font
	var sc := GameSettings.hud_scale

	for id in buttons.keys():
		var pos: Vector2 = buttons[id]
		var r := 92.0 * sc if id == "joy" else (76.0 * sc if id == "fire" else 42.0 * sc)
		var is_dragged: bool = (id == _dragged_id)

		# Круг кнопки
		_canvas.draw_circle(pos, r, Color(0.12, 0.22, 0.16, 0.88 if is_dragged else 0.60))
		_canvas.draw_arc(pos, r, 0.0, TAU, 48, Color(0.95, 0.85, 0.35) if is_dragged else Color(0.85, 0.90, 0.85, 0.80), 2.5 if is_dragged else 1.5, true)

		# Текстовая метка названия
		var label_text: String = str(BUTTON_LABELS.get(id, id.to_upper()))
		var text_sz := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		_canvas.draw_string(font, pos + Vector2(-text_sz.x * 0.5, -r - 6.0), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 0.95, 0.60) if is_dragged else Color(0.85, 0.90, 0.85))
