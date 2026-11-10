extends Control

## Главное меню: выбор карты, режима, сложности и размера боя.
## Вся конфигурация матча уходит в MatchState, а не в дерево сцены.

const MAP_PREVIEW_SCRIPT = preload("res://scripts/map_preview.gd")
const BATTLEFIELD_PREVIEW_SCRIPT = preload("res://scripts/battlefield_map_preview.gd")
const VILLAGE_PREVIEW_SCRIPT = preload("res://scripts/village_map_preview.gd")

var _map_details: VBoxContainer
var _map_placeholder: Control
var _polygon_preview: FRONTLINEMapPreview
var _battlefield_preview: FRONTLINEBattlefieldMapPreview
var _village_preview: FRONTLINEVillageMapPreview
var _title_label: Label
var _desc_label: Label

func _ready() -> void:
	_show_main()

func _clear() -> void:
	for child in get_children():
		child.queue_free()

func _background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.047, 0.052, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _label(parent: Control, text: String, size: int = 22, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Control, text: String, callback: Callable, min_size := Vector2(0, 54)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _make_shell(title: String) -> VBoxContainer:
	_clear()
	_background()
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 44
	root.offset_top = 28
	root.offset_right = -44
	root.offset_bottom = -28
	root.add_theme_constant_override("separation", 18)
	add_child(root)
	_label(root, "FRONTLINE     /     " + title, 30, Color(0.88, 0.9, 0.88))
	var line := ColorRect.new()
	line.custom_minimum_size.y = 2
	line.color = Color(0.48, 0.52, 0.48)
	root.add_child(line)
	return root

func _show_main() -> void:
	var root := _make_shell("MAIN MENU")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var center := VBoxContainer.new()
	center.custom_minimum_size = Vector2(430, 0)
	center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_theme_constant_override("separation", 14)
	root.add_child(center)
	_label(center, "FRONTLINE", 54, Color(0.93, 0.94, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	_label(center, "TACTICAL WARFARE  •  DUMMY WAR STYLE  •  v0.4.0", 15, Color(0.62, 0.68, 0.67), HORIZONTAL_ALIGNMENT_CENTER)
	_button(center, "ИГРАТЬ", _show_maps, Vector2(0, 62))
	_button(center, "НАСТРОЙКИ", _show_settings, Vector2(0, 54))
	_button(center, "ВЫХОД", _quit, Vector2(0, 54))
	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer2)
	_label(root, "ANDROID  •  GODOT 4  •  FRONTLINE COMBAT", 12, Color(0.5, 0.56, 0.55), HORIZONTAL_ALIGNMENT_CENTER)

func _show_maps() -> void:
	var root := _make_shell("ВЫБОР КАРТЫ")
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	root.add_child(body)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(320, 0)
	list.add_theme_constant_override("separation", 8)
	body.add_child(list)

	list.add_child(_mode_button())
	list.add_child(_difficulty_button())
	list.add_child(_squad_button())
	_label(list, "ДОСТУПНЫЕ КАРТЫ", 17, Color(0.68, 0.73, 0.7))

	_add_map_button(list, "BATTLEFIELD (ФРОНТ)\nОкопы и нейтральная полоса (240x180м)", _select_battlefield)
	_add_map_button(list, "VILLAGE (ДЕРЕВНЯ)\nУлицы, церковь, мельница (180x150м)", _select_village)
	_add_map_button(list, "COUNTRYSIDE (ПРИГОРОД)\nХолмы, поля, лесополосы, места под дома (216×168м)", _select_countryside)
	_add_map_button(list, "POLYGON (ПОЛИГОН)\nТренировочное стрельбище", _select_polygon)

	var hint := _label(list, "Выбери карту слева для просмотра обзора.", 14, Color(0.55, 0.61, 0.6))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(list, "НАЗАД", _show_main, Vector2(0, 50))

	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(preview_panel)

	var preview := VBoxContainer.new()
	preview.add_theme_constant_override("separation", 12)
	preview_panel.add_child(preview)

	_map_placeholder = CenterContainer.new()
	_map_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_child(_map_placeholder)
	_label(_map_placeholder, "ВЫБЕРИ КАРТУ СЛЕВА", 22, Color(0.58, 0.64, 0.62), HORIZONTAL_ALIGNMENT_CENTER)

	_map_details = VBoxContainer.new()
	_map_details.visible = false
	preview.add_child(_map_details)

	_polygon_preview = MAP_PREVIEW_SCRIPT.new()
	_polygon_preview.custom_minimum_size = Vector2(560, 260)
	_polygon_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_polygon_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_details.add_child(_polygon_preview)

	_battlefield_preview = BATTLEFIELD_PREVIEW_SCRIPT.new()
	_battlefield_preview.visible = false
	_battlefield_preview.custom_minimum_size = Vector2(560, 260)
	_battlefield_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battlefield_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_details.add_child(_battlefield_preview)

	_village_preview = VILLAGE_PREVIEW_SCRIPT.new()
	_village_preview.visible = false
	_village_preview.custom_minimum_size = Vector2(560, 260)
	_village_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_village_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_details.add_child(_village_preview)

	_title_label = _label(_map_details, "КАРТА", 24)
	_desc_label = _label(_map_details, "Описание", 16, Color(0.72, 0.77, 0.74))
	_button(_map_details, "ИГРАТЬ НА ЭТОЙ КАРТЕ", _launch_map_tactical, Vector2(0, 58))

	_show_selected_map()

func _mode_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(310, 44)
	button.add_theme_font_size_override("font_size", 14)
	var refresh := func() -> void:
		button.text = "РЕЖИМ: " + ("КОМАНДНЫЙ БОЙ (TDM)" if MatchState.mode == "TDM" else "ЗАХВАТ (CONQUEST)")
	refresh.call()
	button.pressed.connect(func() -> void:
		MatchState.mode = "TDM" if MatchState.mode == "CONQUEST" else "CONQUEST"
		refresh.call()
	)
	return button

func _difficulty_button() -> Button:
	var names := ["НОВИЧОК", "БОЕЦ", "ВЕТЕРАН"]
	var button := Button.new()
	button.custom_minimum_size = Vector2(310, 44)
	button.add_theme_font_size_override("font_size", 14)
	var refresh := func() -> void:
		button.text = "СЛОЖНОСТЬ: " + names[MatchState.difficulty]
	refresh.call()
	button.pressed.connect(func() -> void:
		MatchState.difficulty = (MatchState.difficulty + 1) % names.size()
		refresh.call()
	)
	return button

func _squad_button() -> Button:
	var options := [7, 10, 14]
	var labels := ["14 БОЙЦОВ (7x7)", "20 БОЙЦОВ (10x10)", "28 БОЙЦОВ (14x14)"]
	var button := Button.new()
	button.custom_minimum_size = Vector2(310, 44)
	button.add_theme_font_size_override("font_size", 14)
	var index_of := func() -> int:
		var index := options.find(MatchState.squad_size)
		return index if index >= 0 else 0
	var refresh := func() -> void:
		button.text = "СИЛЫ: " + labels[index_of.call()]
	refresh.call()
	button.pressed.connect(func() -> void:
		var next_index: int = (int(index_of.call()) + 1) % options.size()
		MatchState.squad_size = options[next_index]
		refresh.call()
	)
	return button

func _add_map_button(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(310, 75)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(callback)
	parent.add_child(button)

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
	_title_label.text = title
	_desc_label.text = description

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

func _show_settings() -> void:
	var root := _make_shell("НАСТРОЙКИ")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	_label(content, "УПРАВЛЕНИЕ", 20, Color(0.85, 0.88, 0.84))
	_settings_slider(content, "ЧУВСТВИТЕЛЬНОСТЬ", GameSettings.look_sensitivity, GameSettings.MIN_LOOK_SENSITIVITY, GameSettings.MAX_LOOK_SENSITIVITY, 0.05, 100.0, "%", GameSettings.set_look_sensitivity)
	_settings_slider(content, "ЧУВСТВ. ПРИЦЕЛА", GameSettings.aim_sensitivity, GameSettings.MIN_AIM_SENSITIVITY, GameSettings.MAX_AIM_SENSITIVITY, 0.05, 100.0, "%", GameSettings.set_aim_sensitivity)
	_label(content, "При прицеливании используется отдельная чувствительность.", 14, Color(0.66, 0.71, 0.68))

	var invert := CheckBox.new()
	invert.text = "ИНВЕРТИРОВАТЬ ОСЬ Y"
	invert.button_pressed = GameSettings.invert_y
	invert.add_theme_font_size_override("font_size", 16)
	invert.toggled.connect(func(value: bool): GameSettings.set_invert_y(value))
	content.add_child(invert)

	_button(content, "ИЗМЕНИТЬ РАСПОЛОЖЕНИЕ КНОПОК HUD", _open_hud_customizer, Vector2(0, 50))

	_label(content, "ГРАФИКА", 20, Color(0.85, 0.88, 0.84))
	_settings_slider(content, "УГОЛ ОБЗОРА (FOV)", GameSettings.fov, GameSettings.MIN_FOV, GameSettings.MAX_FOV, 1.0, 1.0, "°", GameSettings.set_fov)
	var quality_button := _button(content, "КАЧЕСТВО: " + GameSettings.quality_name(), func(): pass, Vector2(0, 52))
	quality_button.pressed.connect(func():
		GameSettings.cycle_quality()
		quality_button.text = "КАЧЕСТВО: " + GameSettings.quality_name()
	)
	_label(content, "НИЗКОЕ — максимум FPS. СРЕДНЕЕ — баланс. ВЫСОКОЕ — тени и сглаживание.", 14, Color(0.66, 0.71, 0.68))

	_label(content, "ЗВУК", 20, Color(0.85, 0.88, 0.84))
	_settings_slider(content, "ОБЩАЯ ГРОМКОСТЬ", GameSettings.master_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_master_volume)
	_settings_slider(content, "ЭФФЕКТЫ БОЯ (SFX)", GameSettings.sfx_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_sfx_volume)
	_settings_slider(content, "ОКРУЖЕНИЕ (AMBIENCE)", GameSettings.ambience_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_ambience_volume)

	_button(root, "НАЗАД", _show_main, Vector2(0, 52))

func _settings_slider(parent: Control, caption: String, value: float, min_value: float, max_value: float, step: float, display_scale: float, suffix: String, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	parent.add_child(row)

	var label := _label(row, "%s: %d%s" % [caption, int(round(value * display_scale)), suffix], 16)
	label.custom_minimum_size.x = 270

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
	var customizer_script: Script = load("res://scripts/hud_customizer.gd")
	if customizer_script != null:
		var customizer = customizer_script.new()
		add_child(customizer)

func _quit() -> void:
	get_tree().quit()
