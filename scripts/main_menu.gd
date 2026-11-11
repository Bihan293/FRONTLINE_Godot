extends Control

## Главное меню: переключение экранов, карта, режим, сложность и настройки.
## Вся вёрстка — в scenes/MainMenu.tscn, скрипт только связывает события.

@onready var _header: Label = %Header
@onready var _main_screen: VBoxContainer = %MainScreen
@onready var _map_screen: HBoxContainer = %MapScreen
@onready var _settings_screen: VBoxContainer = %SettingsScreen
@onready var _play_button: Button = %PlayButton
@onready var _settings_button: Button = %SettingsButton
@onready var _exit_button: Button = %ExitButton
@onready var _mode_button: Button = %ModeButton
@onready var _difficulty_button: Button = %DifficultyButton
@onready var _squad_button: Button = %SquadButton
@onready var _battlefield_button: Button = %BattlefieldButton
@onready var _village_button: Button = %VillageButton
@onready var _countryside_button: Button = %CountrysideButton
@onready var _polygon_button: Button = %PolygonButton
@onready var _map_back_button: Button = %MapBackButton
@onready var _play_on_map_button: Button = %PlayOnMapButton
@onready var _settings_back_button: Button = %SettingsBackButton
@onready var _map_placeholder: CenterContainer = %MapPlaceholder
@onready var _map_details: VBoxContainer = %MapDetails
@onready var _polygon_preview: FRONTLINEMapPreview = %PolygonPreview
@onready var _battlefield_preview: FRONTLINEBattlefieldMapPreview = %BattlefieldPreview
@onready var _village_preview: FRONTLINEVillageMapPreview = %VillagePreview
@onready var _map_title: Label = %MapTitle
@onready var _map_desc: Label = %MapDesc
@onready var _settings_content: VBoxContainer = %SettingsContent

const HUD_CUSTOMIZER_SCENE = preload("res://scenes/HUDCustomizer.tscn")

const DIFFICULTY_NAMES := ["НОВИЧОК", "БОЕЦ", "ВЕТЕРАН"]
const SQUAD_OPTIONS := [7, 10, 14]
const SQUAD_LABELS := ["14 БОЙЦОВ (7x7)", "20 БОЙЦОВ (10x10)", "28 БОЙЦОВ (14x14)"]

func _ready() -> void:
	_play_button.pressed.connect(_show_maps)
	_settings_button.pressed.connect(_show_settings)
	_exit_button.pressed.connect(_quit)
	_mode_button.pressed.connect(_toggle_mode)
	_difficulty_button.pressed.connect(_cycle_difficulty)
	_squad_button.pressed.connect(_cycle_squad)
	_battlefield_button.pressed.connect(_select_battlefield)
	_village_button.pressed.connect(_select_village)
	_countryside_button.pressed.connect(_select_countryside)
	_polygon_button.pressed.connect(_select_polygon)
	_map_back_button.pressed.connect(_show_main)
	_settings_back_button.pressed.connect(_show_main)
	_play_on_map_button.pressed.connect(_launch_map_tactical)
	_show_main()

func _show_main() -> void:
	_header.text = "FRONTLINE     /     MAIN MENU"
	_main_screen.visible = true
	_map_screen.visible = false
	_settings_screen.visible = false

func _show_maps() -> void:
	_header.text = "FRONTLINE     /     ВЫБОР КАРТЫ"
	_main_screen.visible = false
	_settings_screen.visible = false
	_map_screen.visible = true
	_refresh_match_controls()
	_show_selected_map()

func _show_settings() -> void:
	_header.text = "FRONTLINE     /     НАСТРОЙКИ"
	_main_screen.visible = false
	_map_screen.visible = false
	_settings_screen.visible = true
	_rebuild_settings()

func _toggle_mode() -> void:
	MatchState.mode = "TDM" if MatchState.mode == "CONQUEST" else "CONQUEST"
	_refresh_match_controls()

func _cycle_difficulty() -> void:
	MatchState.difficulty = (MatchState.difficulty + 1) % DIFFICULTY_NAMES.size()
	_refresh_match_controls()

func _cycle_squad() -> void:
	var index := SQUAD_OPTIONS.find(MatchState.squad_size)
	if index < 0:
		index = 0
	MatchState.squad_size = SQUAD_OPTIONS[(index + 1) % SQUAD_OPTIONS.size()]
	_refresh_match_controls()

func _refresh_match_controls() -> void:
	_mode_button.text = "РЕЖИМ: " + ("КОМАНДНЫЙ БОЙ (TDM)" if MatchState.mode == "TDM" else "ЗАХВАТ (CONQUEST)")
	_difficulty_button.text = "СЛОЖНОСТЬ: " + DIFFICULTY_NAMES[MatchState.difficulty]
	var squad_index := SQUAD_OPTIONS.find(MatchState.squad_size)
	if squad_index < 0:
		squad_index = 0
	_squad_button.text = "СИЛЫ: " + SQUAD_LABELS[squad_index]

func _show_selected_map() -> void:
	match MatchState.map_name:
		"VILLAGE":
			_select_village()
		"COUNTRYSIDE":
			_select_countryside()
		"POLYGON":
			_select_polygon()
		_:
			_select_battlefield()

func _select_map(map_name: String, title: String, description: String, preview: Control) -> void:
	MatchState.map_name = map_name
	_map_details.visible = true
	_map_placeholder.visible = false
	for item in [_polygon_preview, _battlefield_preview, _village_preview]:
		item.visible = item == preview
	if preview == _battlefield_preview:
		_battlefield_preview.set_map(map_name)
	_map_title.text = title
	_map_desc.text = description

func _select_battlefield() -> void:
	_select_map(
		"BATTLEFIELD",
		"BATTLEFIELD  /  TRENCHES & NO MAN'S LAND (240×180м)",
		"Масштабная боевая карта: сеть окопов, траншеи, артиллерийские воронки, разрушенные руины, укреплённые базы Железного Легиона и Красного Фронта. Бои умных ботов, захват секторов A, B, C, рэгдолл и реалистичная баллистика.",
		_battlefield_preview
	)

func _select_village() -> void:
	_select_map(
		"VILLAGE",
		"VILLAGE  /  RURAL WARFARE (180×150м)",
		"Деревенская карта: узкие улочки, жилые дома с простреливаемыми комнатами, колокольня церкви святого Иуды, старая мельница с амбаром, каменные колодцы и стога сена. Бои на ближних и средних дистанциях, тактические обходы флангов.",
		_village_preview
	)

func _select_countryside() -> void:
	_select_map(
		"COUNTRYSIDE",
		"COUNTRYSIDE  /  ХОЛМИСТЫЙ ПРИГОРОД (216×168м)",
		"Основа новой карты: пологие холмы, открытая поляна, лесополосы, грунтовая уличная сетка и 16 пустых размеченных участков под будущие здания.",
		_battlefield_preview
	)

func _select_polygon() -> void:
	_select_map(
		"POLYGON",
		"POLYGON  /  TRAINING RANGE",
		"Тренировочный полигон: дистанционные мишени, укрытия, движущиеся и стреляющие бойцы с процедурными анимациями и физическим падением при попадании.",
		_polygon_preview
	)

func _launch_map_tactical() -> void:
	MatchState.configure(
		MatchState.map_name,
		MatchState.mode,
		MatchState.player_team,
		MatchState.player_role,
		MatchState.squad_size,
		MatchState.difficulty
	)
	if MatchState.map_name == "POLYGON":
		MatchState.request_deploy_screen(false, false)
		get_tree().change_scene_to_file("res://scenes/Polygon.tscn")
	else:
		MatchState.request_deploy_screen(true, false)
		get_tree().change_scene_to_file("res://scenes/Battlefield.tscn")

func _rebuild_settings() -> void:
	for child in _settings_content.get_children():
		_settings_content.remove_child(child)
		child.queue_free()

	_add_settings_label("УПРАВЛЕНИЕ", 20, Color(0.85, 0.88, 0.84))
	_add_slider("ЧУВСТВИТЕЛЬНОСТЬ", GameSettings.look_sensitivity, GameSettings.MIN_LOOK_SENSITIVITY, GameSettings.MAX_LOOK_SENSITIVITY, 0.05, 100.0, "%", GameSettings.set_look_sensitivity)
	_add_slider("ЧУВСТВ. ПРИЦЕЛА", GameSettings.aim_sensitivity, GameSettings.MIN_AIM_SENSITIVITY, GameSettings.MAX_AIM_SENSITIVITY, 0.05, 100.0, "%", GameSettings.set_aim_sensitivity)
	_add_settings_label("При прицеливании используется отдельная чувствительность.", 14, Color(0.66, 0.71, 0.68))

	var invert := CheckBox.new()
	invert.text = "ИНВЕРТИРОВАТЬ ОСЬ Y"
	invert.button_pressed = GameSettings.invert_y
	invert.add_theme_font_size_override("font_size", 16)
	invert.toggled.connect(func(value: bool): GameSettings.set_invert_y(value))
	_settings_content.add_child(invert)

	var hud_button := Button.new()
	hud_button.text = "ИЗМЕНИТЬ РАСПОЛОЖЕНИЕ КНОПОК HUD"
	hud_button.custom_minimum_size = Vector2(0, 50)
	hud_button.add_theme_font_size_override("font_size", 20)
	hud_button.pressed.connect(_open_hud_customizer)
	_settings_content.add_child(hud_button)

	_add_settings_label("ГРАФИКА", 20, Color(0.85, 0.88, 0.84))
	_add_slider("УГОЛ ОБЗОРА (FOV)", GameSettings.fov, GameSettings.MIN_FOV, GameSettings.MAX_FOV, 1.0, 1.0, "°", GameSettings.set_fov)
	var quality_button := Button.new()
	quality_button.text = "КАЧЕСТВО: " + GameSettings.quality_name()
	quality_button.custom_minimum_size = Vector2(0, 52)
	quality_button.add_theme_font_size_override("font_size", 20)
	quality_button.pressed.connect(func():
		GameSettings.cycle_quality()
		quality_button.text = "КАЧЕСТВО: " + GameSettings.quality_name()
	)
	_settings_content.add_child(quality_button)
	_add_settings_label("НИЗКОЕ — максимум FPS. СРЕДНЕЕ — баланс. ВЫСОКОЕ — тени и сглаживание.", 14, Color(0.66, 0.71, 0.68))

	_add_settings_label("ЗВУК", 20, Color(0.85, 0.88, 0.84))
	_add_slider("ОБЩАЯ ГРОМКОСТЬ", GameSettings.master_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_master_volume)
	_add_slider("ЭФФЕКТЫ БОЯ (SFX)", GameSettings.sfx_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_sfx_volume)
	_add_slider("ОКРУЖЕНИЕ (AMBIENCE)", GameSettings.ambience_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_ambience_volume)

func _add_settings_label(text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settings_content.add_child(label)

func _add_slider(caption: String, value: float, min_value: float, max_value: float, step: float, display_scale: float, suffix: String, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_settings_content.add_child(row)
	var label := Label.new()
	label.text = "%s: %d%s" % [caption, int(round(value * display_scale)), suffix]
	label.custom_minimum_size.x = 270
	label.add_theme_font_size_override("font_size", 16)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(360, 44)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(new_value: float):
		setter.call(new_value)
		label.text = "%s: %d%s" % [caption, int(round(new_value * display_scale)), suffix]
	)
	row.add_child(slider)

func _open_hud_customizer() -> void:
	add_child(HUD_CUSTOMIZER_SCENE.instantiate())

func _quit() -> void:
	get_tree().quit()
