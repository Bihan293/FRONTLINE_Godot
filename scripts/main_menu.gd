extends Control

const MAP_PREVIEW_SCRIPT = preload("res://scripts/map_preview.gd")
const BATTLEFIELD_PREVIEW_SCRIPT = preload("res://scripts/battlefield_map_preview.gd")
const VILLAGE_PREVIEW_SCRIPT = preload("res://scripts/village_map_preview.gd")
const LAYOUT = preload("res://scripts/map_layout.gd")
const BATTLEFIELD_LAYOUT = preload("res://scripts/battlefield_layout.gd")
const VILLAGE_LAYOUT = preload("res://scripts/village_layout.gd")

var map_selected := false
var selected_map := "BATTLEFIELD"
var selected_team := "IRON LEGION"
var selected_mode := "CONQUEST"

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
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _button(parent: Control, text: String, callback: Callable, min_size := Vector2(0, 54)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

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
	_label(root, "FRONTLINE     /     " + title, 30, Color(0.88,0.9,0.88))
	var line := ColorRect.new()
	line.custom_minimum_size.y = 2
	line.color = Color(0.48,0.52,0.48)
	root.add_child(line)
	return root

func _show_main() -> void:
	var root := _make_shell("MAIN MENU")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var center := VBoxContainer.new()
	center.custom_minimum_size = Vector2(430,0)
	center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_theme_constant_override("separation", 14)
	root.add_child(center)
	_label(center, "FRONTLINE", 54, Color(0.93,0.94,0.9), HORIZONTAL_ALIGNMENT_CENTER)
	_label(center, "TACTICAL WARFARE  •  DUMMY WAR STYLE  •  v0.4.0", 15, Color(0.62,0.68,0.67), HORIZONTAL_ALIGNMENT_CENTER)
	_button(center, "ИГРАТЬ", _show_maps, Vector2(0,62))
	_button(center, "НАСТРОЙКИ", _show_settings, Vector2(0,54))
	_button(center, "ВЫХОД", _quit, Vector2(0,54))
	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer2)
	_label(root, "ANDROID  •  GODOT 4  •  FRONTLINE COMBAT", 12, Color(0.5,0.56,0.55), HORIZONTAL_ALIGNMENT_CENTER)

func _show_maps() -> void:
	map_selected = false
	var root := _make_shell("ВЫБОР КАРТЫ")
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	root.add_child(body)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(320,0)
	list.add_theme_constant_override("separation", 14)
	body.add_child(list)

	# Селектор режима игры
	var mode_btn := Button.new()
	mode_btn.text = "РЕЖИМ: " + ("КОМАНДНЫЙ БОЙ (TDM)" if selected_mode == "TDM" else "ЗАХВАТ (CONQUEST)")
	mode_btn.custom_minimum_size = Vector2(310, 48)
	mode_btn.add_theme_font_size_override("font_size", 15)
	mode_btn.pressed.connect(func():
		if selected_mode == "CONQUEST":
			selected_mode = "TDM"
		else:
			selected_mode = "CONQUEST"
		get_tree().set_meta("selected_mode", selected_mode)
		mode_btn.text = "РЕЖИМ: " + ("КОМАНДНЫЙ БОЙ (TDM)" if selected_mode == "TDM" else "ЗАХВАТ (CONQUEST)")
	)
	list.add_child(mode_btn)

	_label(list, "ДОСТУПНЫЕ КАРТЫ", 17, Color(0.68,0.73,0.7))

	# Карточка BATTLEFIELD (Окопная война)
	var card_bf := Button.new()
	card_bf.text = "BATTLEFIELD (ФРОНТ)\nОкопы и нейтральная полоса (240x180м)"
	card_bf.custom_minimum_size = Vector2(310, 75)
	card_bf.add_theme_font_size_override("font_size", 16)
	card_bf.pressed.connect(_select_battlefield)
	list.add_child(card_bf)

	# Карточка VILLAGE (Деревня)
	var card_vil := Button.new()
	card_vil.text = "VILLAGE (ДЕРЕВНЯ)\nУлицы, церковь, мельница (180x150м)"
	card_vil.custom_minimum_size = Vector2(310, 75)
	card_vil.add_theme_font_size_override("font_size", 16)
	card_vil.pressed.connect(_select_village)
	list.add_child(card_vil)

	# Карточка POLYGON (Полигон)
	var card_poly := Button.new()
	card_poly.text = "POLYGON (ПОЛИГОН)\nТренировочное стрельбище"
	card_poly.custom_minimum_size = Vector2(310, 65)
	card_poly.add_theme_font_size_override("font_size", 16)
	card_poly.pressed.connect(_select_polygon)
	list.add_child(card_poly)

	var hint := _label(list, "Выбери карту слева для просмотра обзора.", 14, Color(0.55,0.61,0.6))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(list, "НАЗАД", _show_main, Vector2(0,50))

	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(preview_panel)

	var preview := VBoxContainer.new()
	preview.add_theme_constant_override("separation", 12)
	preview_panel.add_child(preview)

	var placeholder := CenterContainer.new()
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.add_child(placeholder)
	_label(placeholder, "ВЫБЕРИ КАРТУ СЛЕВА", 22, Color(0.58,0.64,0.62), HORIZONTAL_ALIGNMENT_CENTER)

	var details := VBoxContainer.new()
	details.name = "MapDetails"
	details.visible = false
	preview.add_child(details)

	var image = MAP_PREVIEW_SCRIPT.new()
	image.name = "PolygonPreview"
	image.custom_minimum_size = Vector2(560, 260)
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(image)
	var battlefield_image = BATTLEFIELD_PREVIEW_SCRIPT.new()
	battlefield_image.name = "BattlefieldPreview"
	battlefield_image.visible = false
	battlefield_image.custom_minimum_size = Vector2(560, 260)
	battlefield_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	battlefield_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(battlefield_image)

	var village_image = VILLAGE_PREVIEW_SCRIPT.new()
	village_image.name = "VillagePreview"
	village_image.visible = false
	village_image.custom_minimum_size = Vector2(560, 260)
	village_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	village_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details.add_child(village_image)

	var title_lbl := _label(details, "КАРТА", 24)
	var desc_lbl := _label(details, "Описание", 16, Color(0.72,0.77,0.74))
	var play_btn := _button(details, "ИГРАТЬ НА ЭТОЙ КАРТЕ", _show_teams, Vector2(0,58))

	set_meta("map_details", details)
	set_meta("polygon_preview", image)
	set_meta("battlefield_preview", battlefield_image)
	set_meta("village_preview", village_image)
	set_meta("map_placeholder", placeholder)
	set_meta("title_lbl", title_lbl)
	set_meta("desc_lbl", desc_lbl)

	# По умолчанию сразу выбираем BATTLEFIELD
	_select_battlefield()

func _select_battlefield() -> void:
	selected_map = "BATTLEFIELD"
	get_tree().set_meta("selected_map", "BATTLEFIELD")
	var details = get_meta("map_details")
	var placeholder = get_meta("map_placeholder")
	var title_lbl: Label = get_meta("title_lbl")
	var desc_lbl: Label = get_meta("desc_lbl")
	details.visible = true
	placeholder.visible = false
	(get_meta("polygon_preview") as Control).visible = false
	(get_meta("village_preview") as Control).visible = false
	(get_meta("battlefield_preview") as Control).visible = true
	title_lbl.text = "BATTLEFIELD  /  TRENCHES & NO MAN'S LAND (240×180м)"
	desc_lbl.text = "Масштабная боевая карта: сеть окопов, траншеи, артиллерийские воронки, разрушенные руины, укреплённые базы Железного Легиона и Красного Фронта. Бои умных ботов, захват секторов A, B, C, рэгдолл и реалистичная баллистика."

func _select_village() -> void:
	selected_map = "VILLAGE"
	get_tree().set_meta("selected_map", "VILLAGE")
	var details = get_meta("map_details")
	var placeholder = get_meta("map_placeholder")
	var title_lbl: Label = get_meta("title_lbl")
	var desc_lbl: Label = get_meta("desc_lbl")
	details.visible = true
	placeholder.visible = false
	(get_meta("polygon_preview") as Control).visible = false
	(get_meta("battlefield_preview") as Control).visible = false
	(get_meta("village_preview") as Control).visible = true
	title_lbl.text = "VILLAGE  /  RURAL WARFARE (180×150м)"
	desc_lbl.text = "Деревенская карта: узкие улочки, жилые дома с простреливаемыми комнатами, колокольня церкви святого Иуды, старая мельница с амбаром, каменные колодцы и стога сена. Бои на ближних и средних дистанциях, тактические обходы флангов."

func _select_polygon() -> void:
	selected_map = "POLYGON"
	get_tree().set_meta("selected_map", "POLYGON")
	var details = get_meta("map_details")
	var placeholder = get_meta("map_placeholder")
	var title_lbl: Label = get_meta("title_lbl")
	var desc_lbl: Label = get_meta("desc_lbl")
	details.visible = true
	placeholder.visible = false
	(get_meta("polygon_preview") as Control).visible = true
	(get_meta("battlefield_preview") as Control).visible = false
	(get_meta("village_preview") as Control).visible = false
	title_lbl.text = "POLYGON  /  TRAINING RANGE"
	desc_lbl.text = "Тренировочный полигон: дистанционные мишени, укрытия, движущиеся и стреляющие бойцы с процедурными анимациями и физическим падением при попадании."

func _show_teams() -> void:
	var root := _make_shell("ВЫБОР СТОРОНЫ  (" + selected_map + ")")
	_label(root, "Выбери фракцию для высадки в бой.", 17, Color(0.68,0.73,0.7))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 28)
	root.add_child(row)
	_team_card(row, "IRON LEGION", "ЖЕЛЕЗНЫЙ ЛЕГИОН", Color(0.28,0.32,0.35), "Серо-графитовая тактическая форма и стальные каски. Оборона южного сектора.")
	_team_card(row, "RED FRONT", "КРАСНЫЙ ФРОНТ", Color(0.48,0.25,0.17), "Хаки и полевая форма советского стиля. Наступление с северного сектора.")
	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer2)
	_button(root, "НАЗАД К КАРТЕ", _show_maps, Vector2(0,48))

func _team_card(parent: Control, faction: String, subtitle: String, tint: Color, description: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var swatch := ColorRect.new()
	swatch.color = tint
	swatch.custom_minimum_size = Vector2(0,110)
	box.add_child(swatch)
	_label(box, faction, 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, subtitle, 16, tint.lightened(0.4), HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, description, 15, Color(0.7,0.74,0.72), HORIZONTAL_ALIGNMENT_CENTER)
	var choose := _button(box, "ВЫБРАТЬ", func(): _choose_team(faction), Vector2(0,58))
	choose.size_flags_vertical = Control.SIZE_SHRINK_END

func _choose_team(faction: String) -> void:
	selected_team = faction
	get_tree().set_meta("selected_team", faction)
	get_tree().set_meta("selected_map", selected_map)
	_show_deployment()

func _show_deployment() -> void:
	var root := _make_shell("DEPLOYMENT  /  " + selected_map)
	_label(root, "СТОРОНА: " + selected_team + "     •     Выбери рубеж появления", 16, Color(0.75,0.79,0.76))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)
	var map_holder := PanelContainer.new()
	map_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_holder.custom_minimum_size = Vector2(480, 300)
	body.add_child(map_holder)
	var map_overlay := Control.new()
	map_holder.add_child(map_overlay)
	map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var image: Control
	if selected_map == "VILLAGE":
		var vil_prev = VILLAGE_PREVIEW_SCRIPT.new()
		vil_prev.team_name = selected_team
		image = vil_prev
	elif selected_map == "BATTLEFIELD":
		var bf_prev = BATTLEFIELD_PREVIEW_SCRIPT.new()
		bf_prev.team_name = selected_team
		image = bf_prev
	else:
		image = MAP_PREVIEW_SCRIPT.new()
	image.show_spawns = true
	image.interactive = true
	image.custom_minimum_size = Vector2(460, 300)
	image.set_selected(0)
	image.spawn_selected.connect(_select_spawn)
	map_overlay.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(250,0)
	side.add_theme_constant_override("separation", 12)
	body.add_child(side)
	_label(side, "ТОЧКА ПОЯВЛЕНИЯ", 19)
	var selected := Label.new()
	selected.name = "SpawnLabel"
	selected.text = "ТОЧКА 1  •  ГОТОВА"
	selected.add_theme_font_size_override("font_size", 18)
	side.add_child(selected)
	_label(side, "Нажми на рубеж на схеме и подтверди DEPLOY.", 14, Color(0.67,0.72,0.69))
	var deploy := _button(side, "DEPLOY (В БОЙ)", _deploy, Vector2(0,66))
	set_meta("spawn_label", selected)
	set_meta("deploy_button", deploy)
	set_meta("map_preview", image)
	set_meta("selected_spawn", 0)
	_button(side, "НАЗАД", _show_teams, Vector2(0,48))

func _select_spawn(index: int) -> void:
	set_meta("selected_spawn", index)
	var label: Label = get_meta("spawn_label")
	label.text = "ТОЧКА %d  •  ГОТОВА" % (index + 1)
	var preview = get_meta("map_preview", null)
	if preview != null:
		preview.set_selected(index)

func _deploy() -> void:
	var index: int = int(get_meta("selected_spawn", 0))
	if index < 0:
		index = 0
	var map: String = str(get_tree().get_meta("selected_map", "BATTLEFIELD"))
	if map == "VILLAGE":
		var spawns: Array = VILLAGE_LAYOUT.spawns_red() if selected_team.contains("RED") else VILLAGE_LAYOUT.spawns_iron()
		var sp: Vector3 = spawns[index % spawns.size()]
		get_tree().set_meta("spawn_position", sp)
		get_tree().set_meta("selected_mode", selected_mode)
		get_tree().change_scene_to_file("res://scenes/Battlefield.tscn")
	elif map == "BATTLEFIELD":
		var spawns: Array = BATTLEFIELD_LAYOUT.spawns_red() if selected_team.contains("RED") else BATTLEFIELD_LAYOUT.spawns_iron()
		var sp: Vector3 = spawns[index % spawns.size()]
		get_tree().set_meta("spawn_position", sp)
		get_tree().set_meta("selected_mode", selected_mode)
		get_tree().change_scene_to_file("res://scenes/Battlefield.tscn")
	else:
		var spawn_positions: Array = LAYOUT.spawns()
		get_tree().set_meta("spawn_position", spawn_positions[index % spawn_positions.size()])
		get_tree().change_scene_to_file("res://scenes/Polygon.tscn")

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

	_label(content, "ГРАФИКА", 20, Color(0.85, 0.88, 0.84))
	_settings_slider(content, "УГОЛ ОБЗОРА (FOV)", GameSettings.fov, GameSettings.MIN_FOV, GameSettings.MAX_FOV, 1.0, 1.0, "°", GameSettings.set_fov)
	var quality_button := _button(content, "КАЧЕСТВО: " + GameSettings.quality_name(), func(): pass, Vector2(0, 52))
	quality_button.pressed.connect(func():
		GameSettings.cycle_quality()
		quality_button.text = "КАЧЕСТВО: " + GameSettings.quality_name()
	)
	_label(content, "НИЗКОЕ — максимум FPS. СРЕДНЕЕ — баланс. ВЫСОКОЕ — тени и сглаживание.", 14, Color(0.66, 0.71, 0.68))

	_label(content, "ЗВУК", 20, Color(0.85, 0.88, 0.84))
	_settings_slider(content, "ГРОМКОСТЬ", GameSettings.master_volume, 0.0, 1.0, 0.05, 100.0, "%", GameSettings.set_master_volume)

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

func _quit() -> void:
	get_tree().quit()
