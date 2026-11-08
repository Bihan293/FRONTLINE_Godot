extends CanvasLayer
class_name FRONTLINEHUDCustomizer

## Интерактивный редактор расположения мобильных кнопок HUD.
## Позволяет игроку пальцем перетаскивать любые кнопки управления,
## выбирать пресеты (Стандарт / Компакт / Разреженный / Для левши)
## и настраивать масштаб кнопок.

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

var _dragged_id: String = ""
var _drag_touch: int = -1
var _drag_touch_offset := Vector2.ZERO
var _preset_btn: Button
var _scale_btn: Button

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.name = "CustomizerRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	# Затемняющий фон
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.03, 0.85)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# Верхняя панель управления
	var top_panel := PanelContainer.new()
	top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 16.0
	top_panel.offset_right = -16.0
	top_panel.offset_top = 12.0
	top_panel.offset_bottom = 68.0
	root.add_child(top_panel)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	top_panel.add_child(hbox)

	var title := Label.new()
	title.text = "НАСТРОЙКА КНОПОК: Перетащите кнопки пальцем"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.85, 0.90, 0.82))
	hbox.add_child(title)

	_preset_btn = Button.new()
	_preset_btn.text = "ПРЕСЕТ: " + GameSettings.hud_preset_name()
	_preset_btn.custom_minimum_size = Vector2(170, 42)
	_preset_btn.pressed.connect(_cycle_preset)
	hbox.add_child(_preset_btn)

	_scale_btn = Button.new()
	_scale_btn.text = "РАЗМЕР: %d%%" % int(round(GameSettings.hud_scale * 100.0))
	_scale_btn.custom_minimum_size = Vector2(125, 42)
	_scale_btn.pressed.connect(_cycle_scale)
	hbox.add_child(_scale_btn)

	var reset_btn := Button.new()
	reset_btn.text = "СБРОС"
	reset_btn.custom_minimum_size = Vector2(90, 42)
	reset_btn.pressed.connect(_reset_layout)
	hbox.add_child(reset_btn)

	var save_btn := Button.new()
	save_btn.text = "СОХРАНИТЬ И ВЫЙТИ"
	save_btn.custom_minimum_size = Vector2(180, 42)
	save_btn.pressed.connect(_save_and_exit)
	hbox.add_child(save_btn)

	# Слой отрисовки кнопок
	var canvas := Control.new()
	canvas.name = "Canvas"
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# QA-fix TASK-0022: MOUSE_FILTER_PASS на полноэкранном Canvas съедал клики
	# по верхней панели — кнопки «СОХРАНИТЬ»/«СБРОС»/пресеты не работали.
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_canvas)
	root.add_child(canvas)

func _cycle_preset() -> void:
	GameSettings.cycle_hud_preset()
	if _preset_btn != null:
		_preset_btn.text = "ПРЕСЕТ: " + GameSettings.hud_preset_name()
	var canvas = find_child("Canvas", true, false)
	if canvas != null:
		canvas.queue_redraw()

func _cycle_scale() -> void:
	var scales := [0.85, 1.0, 1.15, 1.30]
	var current_idx := 1
	for i in range(scales.size()):
		if is_equal_approx(GameSettings.hud_scale, scales[i]):
			current_idx = i
			break
	var next_idx: int = (current_idx + 1) % scales.size()
	GameSettings.set_hud_scale(scales[next_idx])
	if _scale_btn != null:
		_scale_btn.text = "РАЗМЕР: %d%%" % int(round(GameSettings.hud_scale * 100.0))
	var canvas = find_child("Canvas", true, false)
	if canvas != null:
		canvas.queue_redraw()

func _reset_layout() -> void:
	GameSettings.reset_hud_layout()
	if _preset_btn != null:
		_preset_btn.text = "ПРЕСЕТ: " + GameSettings.hud_preset_name()
	if _scale_btn != null:
		_scale_btn.text = "РАЗМЕР: %d%%" % int(round(GameSettings.hud_scale * 100.0))
	var canvas = find_child("Canvas", true, false)
	if canvas != null:
		canvas.queue_redraw()

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
	elif preset == 1:
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
	elif preset == 2:
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
			var canvas = find_child("Canvas", true, false)
			if canvas != null:
				canvas.queue_redraw()
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
	var canvas = find_child("Canvas", true, false)
	if canvas != null:
		canvas.queue_redraw()

func _end_drag() -> void:
	_dragged_id = ""
	_drag_touch = -1
	var canvas = find_child("Canvas", true, false)
	if canvas != null:
		canvas.queue_redraw()

func _draw_canvas() -> void:
	var canvas = find_child("Canvas", true, false)
	if canvas == null:
		return
	var buttons := _get_button_positions()
	var font := ThemeDB.fallback_font
	var sc := GameSettings.hud_scale

	for id in buttons.keys():
		var pos: Vector2 = buttons[id]
		var r := 92.0 * sc if id == "joy" else (76.0 * sc if id == "fire" else 42.0 * sc)
		var is_dragged: bool = (id == _dragged_id)

		# Круг кнопки
		canvas.draw_circle(pos, r, Color(0.12, 0.22, 0.16, 0.88 if is_dragged else 0.60))
		canvas.draw_arc(pos, r, 0.0, TAU, 48, Color(0.95, 0.85, 0.35) if is_dragged else Color(0.85, 0.90, 0.85, 0.80), 2.5 if is_dragged else 1.5, true)

		# Текстовая метка названия
		var label_text: String = str(BUTTON_LABELS.get(id, id.to_upper()))
		var text_sz := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		canvas.draw_string(font, pos + Vector2(-text_sz.x * 0.5, -r - 6.0), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 0.95, 0.60) if is_dragged else Color(0.85, 0.90, 0.85))
