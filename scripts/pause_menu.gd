extends CanvasLayer
class_name FRONTLINEPauseMenu

## Внутриигровое меню паузы: останавливает матч, даёт быстрые настройки
## управления/графики и выход в главное меню. Работает и на ПК, и на телефоне.
## Вёрстка живёт в scenes/PauseMenu.tscn, скрипт только связывает события.

signal resumed

@onready var _main_box: VBoxContainer = %MainBox
@onready var _settings_box: VBoxContainer = %SettingsBox
@onready var _settings_content: VBoxContainer = %SettingsContent
@onready var _continue_button: Button = %ContinueButton
@onready var _settings_button: Button = %SettingsButton
@onready var _menu_button: Button = %MenuButton
@onready var _back_button: Button = %SettingsBackButton

var _is_open := false
var _sliders: Array[HSlider] = []

func _ready() -> void:
	_continue_button.pressed.connect(close)
	_settings_button.pressed.connect(_show_settings)
	_menu_button.pressed.connect(_return_to_menu)
	_back_button.pressed.connect(_show_main)
	_build_settings_rows()

func _build_settings_rows() -> void:
	_add_slider(_settings_content, "ЧУВСТВИТЕЛЬНОСТЬ", GameSettings.look_sensitivity, GameSettings.MIN_LOOK_SENSITIVITY, GameSettings.MAX_LOOK_SENSITIVITY, 0.05, 100.0, "%", GameSettings.set_look_sensitivity)
	_add_slider(_settings_content, "ЧУВСТВ. ПРИЦЕЛА", GameSettings.aim_sensitivity, GameSettings.MIN_AIM_SENSITIVITY, GameSettings.MAX_AIM_SENSITIVITY, 0.05, 100.0, "%", GameSettings.set_aim_sensitivity)
	_add_slider(_settings_content, "УГОЛ ОБЗОРА (FOV)", GameSettings.fov, GameSettings.MIN_FOV, GameSettings.MAX_FOV, 1.0, 1.0, "°", GameSettings.set_fov)
	_add_slider(_settings_content, "ОБЩАЯ ГРОМКОСТЬ", GameSettings.master_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_master_volume)
	_add_slider(_settings_content, "ЭФФЕКТЫ (SFX)", GameSettings.sfx_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_sfx_volume)
	_add_slider(_settings_content, "ОКРУЖЕНИЕ", GameSettings.ambience_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_ambience_volume)

	var invert := CheckBox.new()
	invert.text = "ИНВЕРТИРОВАТЬ ОСЬ Y"
	invert.button_pressed = GameSettings.invert_y
	invert.add_theme_font_size_override("font_size", 16)
	invert.toggled.connect(func(value: bool): GameSettings.set_invert_y(value))
	_settings_content.add_child(invert)

	var quality := _add_button(_settings_content, "КАЧЕСТВО: " + GameSettings.quality_name(), func(): pass, 48)
	quality.pressed.connect(func():
		GameSettings.cycle_quality()
		quality.text = "КАЧЕСТВО: " + GameSettings.quality_name()
	)

	var hud_btn := _add_button(_settings_content, "ИЗМЕНИТЬ РАСПОЛОЖЕНИЕ КНОПОК HUD", _open_hud_customizer, 48)
	hud_btn.add_theme_font_size_override("font_size", 15)

	var reset := _add_button(_settings_content, "СБРОСИТЬ УПРАВЛЕНИЕ", _reset_controls, 44)
	reset.add_theme_font_size_override("font_size", 14)

func _open_hud_customizer() -> void:
	var customizer_script: Script = load("res://scripts/hud_customizer.gd")
	if customizer_script != null:
		var customizer = customizer_script.new()
		get_tree().root.add_child(customizer)
		customizer.closed.connect(func():
			var mc = get_tree().get_first_node_in_group("mobile_controls")
			if mc != null and mc.has_method("queue_redraw"):
				mc.call("queue_redraw")
		)

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
