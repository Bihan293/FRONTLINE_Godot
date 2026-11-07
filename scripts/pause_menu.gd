extends CanvasLayer
class_name FRONTLINEPauseMenu

## Внутриигровое меню паузы: останавливает матч, даёт быстрые настройки
## управления/графики и выход в главное меню. Работает и на ПК, и на телефоне.

signal resumed

const PANEL_SIZE := Vector2(600.0, 600.0)

var _is_open := false
var _main_box: VBoxContainer
var _settings_box: VBoxContainer
var _sliders: Array[HSlider] = []

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()

func _build() -> void:
	var root := Control.new()
	root.name = "PauseRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.02, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -PANEL_SIZE.x * 0.5
	panel.offset_right = PANEL_SIZE.x * 0.5
	panel.offset_top = -PANEL_SIZE.y * 0.5
	panel.offset_bottom = PANEL_SIZE.y * 0.5
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.88, 0.91, 0.84))
	column.add_child(title)

	var hint := Label.new()
	hint.text = "Бой остановлен. ESC или кнопка ниже — продолжить."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.64, 0.69, 0.63))
	column.add_child(hint)

	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 14)
	column.add_child(_main_box)

	_add_button(_main_box, "ПРОДОЛЖИТЬ", close, 58)
	_add_button(_main_box, "НАСТРОЙКИ", _show_settings, 54)
	_add_button(_main_box, "В ГЛАВНОЕ МЕНЮ", _return_to_menu, 54)

	_settings_box = VBoxContainer.new()
	_settings_box.add_theme_constant_override("separation", 10)
	_settings_box.visible = false
	column.add_child(_settings_box)
	_build_settings(_settings_box)

func _build_settings(parent: VBoxContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 340)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	_add_slider(content, "ЧУВСТВИТЕЛЬНОСТЬ", GameSettings.look_sensitivity, GameSettings.MIN_LOOK_SENSITIVITY, GameSettings.MAX_LOOK_SENSITIVITY, 0.05, 100.0, "%", GameSettings.set_look_sensitivity)
	_add_slider(content, "ЧУВСТВ. ПРИЦЕЛА", GameSettings.aim_sensitivity, GameSettings.MIN_AIM_SENSITIVITY, GameSettings.MAX_AIM_SENSITIVITY, 0.05, 100.0, "%", GameSettings.set_aim_sensitivity)
	_add_slider(content, "УГОЛ ОБЗОРА (FOV)", GameSettings.fov, GameSettings.MIN_FOV, GameSettings.MAX_FOV, 1.0, 1.0, "°", GameSettings.set_fov)
	_add_slider(content, "ОБЩАЯ ГРОМКОСТЬ", GameSettings.master_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_master_volume)
	_add_slider(content, "ЭФФЕКТЫ (SFX)", GameSettings.sfx_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_sfx_volume)
	_add_slider(content, "ОКРУЖЕНИЕ", GameSettings.ambience_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_ambience_volume)

	var invert := CheckBox.new()
	invert.text = "ИНВЕРТИРОВАТЬ ОСЬ Y"
	invert.button_pressed = GameSettings.invert_y
	invert.add_theme_font_size_override("font_size", 16)
	invert.toggled.connect(func(value: bool): GameSettings.set_invert_y(value))
	content.add_child(invert)

	var quality := _add_button(content, "КАЧЕСТВО: " + GameSettings.quality_name(), func(): pass, 48)
	quality.pressed.connect(func():
		GameSettings.cycle_quality()
		quality.text = "КАЧЕСТВО: " + GameSettings.quality_name()
	)

	var reset := _add_button(content, "СБРОСИТЬ УПРАВЛЕНИЕ", _reset_controls, 44)
	reset.add_theme_font_size_override("font_size", 14)

	var back := _add_button(parent, "НАЗАД", _show_main, 52)
	back.add_theme_font_size_override("font_size", 16)

func _add_button(parent: Control, text: String, callback: Callable, height: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _add_slider(parent: Control, caption: String, value: float, min_value: float, max_value: float, step: float, display_scale: float, suffix: String, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var label := Label.new()
	label.text = "%s: %d%s" % [caption, int(round(value * display_scale)), suffix]
	label.custom_minimum_size.x = 260
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.80))
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 40)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(new_value: float):
		setter.call(new_value)
		label.text = "%s: %d%s" % [caption, int(round(new_value * display_scale)), suffix]
	)
	row.add_child(slider)
	_sliders.append(slider)

func _reset_controls() -> void:
	GameSettings.reset_controls()
	var defaults := [GameSettings.look_sensitivity, GameSettings.aim_sensitivity, GameSettings.fov, GameSettings.master_volume]
	for i in range(mini(defaults.size(), _sliders.size())):
		_sliders[i].value = float(defaults[i])

func _show_settings() -> void:
	if _main_box != null:
		_main_box.visible = false
	if _settings_box != null:
		_settings_box.visible = true

func _show_main() -> void:
	if _settings_box != null:
		_settings_box.visible = false
	if _main_box != null:
		_main_box.visible = true

func open() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_show_main()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	get_tree().paused = false
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	resumed.emit()

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func _return_to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode != KEY_ESCAPE:
		return
	# Конец матча уже ставит дерево на паузу — не перекрываем экран победы.
	if not _is_open and get_tree().paused:
		return
	toggle()
	get_viewport().set_input_as_handled()
