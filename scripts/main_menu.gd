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
var selected_role := "ASSAULT"
var selected_loadout := "BALANCED"
var selected_primary := -1
var selected_grenades := -1
var selected_smoke := -1
var selected_medkits := -1
var selected_rockets := -1
var _editor_grenades := 0
var _editor_smoke := 0
var _editor_medkits := 0
var _editor_rockets := 0
var _editor_primary := 0

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
	list.add_theme_constant_override("separation", 8)
	body.add_child(list)

	# Селектор режима игры
	var mode_btn := Button.new()
	mode_btn.text = "РЕЖИМ: " + ("КОМАНДНЫЙ БОЙ (TDM)" if selected_mode == "TDM" else "ЗАХВАТ (CONQUEST)")
	mode_btn.custom_minimum_size = Vector2(310, 44)
	mode_btn.add_theme_font_size_override("font_size", 14)
	mode_btn.pressed.connect(func():
		if selected_mode == "CONQUEST":
			selected_mode = "TDM"
		else:
			selected_mode = "CONQUEST"
		get_tree().set_meta("selected_mode", selected_mode)
		mode_btn.text = "РЕЖИМ: " + ("КОМАНДНЫЙ БОЙ (TDM)" if selected_mode == "TDM" else "ЗАХВАТ (CONQUEST)")
	)
	list.add_child(mode_btn)

	# Селектор сложности ботов
	var diff_names := ["НОВИЧОК", "БОЕЦ", "ВЕТЕРАН"]
	var diff_btn := Button.new()
	var current_diff: int = clampi(int(get_tree().get_meta("match_difficulty", 1)), 0, 2)
	diff_btn.text = "СЛОЖНОСТЬ: " + diff_names[current_diff]
	diff_btn.custom_minimum_size = Vector2(310, 44)
	diff_btn.add_theme_font_size_override("font_size", 14)
	diff_btn.pressed.connect(func():
		var d: int = (clampi(int(get_tree().get_meta("match_difficulty", 1)), 0, 2) + 1) % 3
		get_tree().set_meta("match_difficulty", d)
		diff_btn.text = "СЛОЖНОСТЬ: " + diff_names[d]
	)
	list.add_child(diff_btn)

	# Селектор размера боя
	var squad_options := [7, 10, 14]
	var squad_labels := ["14 БОЙЦОВ (7x7)", "20 БОЙЦОВ (10x10)", "28 БОЙЦОВ (14x14)"]
	var squad_btn := Button.new()
	var current_sq: int = int(get_tree().get_meta("match_squad_size", 7))
	var sq_idx: int = squad_options.find(current_sq)
	if sq_idx < 0: sq_idx = 0
	squad_btn.text = "СИЛЫ: " + squad_labels[sq_idx]
	squad_btn.custom_minimum_size = Vector2(310, 44)
	squad_btn.add_theme_font_size_override("font_size", 14)
	squad_btn.pressed.connect(func():
		var cur: int = int(get_tree().get_meta("match_squad_size", 7))
		var idx: int = (squad_options.find(cur) + 1) % squad_options.size()
		if idx < 0: idx = 0
		get_tree().set_meta("match_squad_size", squad_options[idx])
		squad_btn.text = "СИЛЫ: " + squad_labels[idx]
	)
	list.add_child(squad_btn)

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
	var play_btn := _button(details, "ИГРАТЬ НА ЭТОЙ КАРТЕ", _show_deployment, Vector2(0,58))

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
	_show_roles()

func _show_roles() -> void:
	var root := _make_shell("ВЫБОР БОЕВОГО КЛАССА  (" + selected_team + ")")
	_label(root, "Выбери специализацию бойца и экипировку перед высадкой.", 16, Color(0.72, 0.76, 0.74))

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	var screen_width := get_viewport_rect().size.x
	grid.columns = 3 if screen_width >= 1150.0 else (2 if screen_width >= 680.0 else 1)
	scroll.add_child(grid)

	var roles_data := [
		{
			"id": "ASSAULT",
			"title": "ШТУРМОВИК",
			"weapon": "AK-47 + M1911",
			"desc": "Универсальный передовой боец. 3 осколочные гранаты, 2 дыма, увеличенная скорость спринта.",
			"tint": Color(0.25, 0.35, 0.30)
		},
		{
			"id": "MEDIC",
			"title": "САНИТАР",
			"weapon": "MP-40 + M1911",
			"desc": "Полевой медик. 5 аптечек: лечение себя и перевязка союзников в радиусе 6.5м.",
			"tint": Color(0.20, 0.35, 0.40)
		},
		{
			"id": "SNIPER",
			"title": "СНАЙПЕР",
			"weapon": "KAR98K (2.6x ADS)",
			"desc": "Стрелок дальнего боя. Оптический прицел с мил-дот сеткой, радар видит врагов до 70м.",
			"tint": Color(0.35, 0.30, 0.20)
		},
		{
			"id": "ANTI_TANK",
			"title": "ПТ-СТРЕЛОК",
			"weapon": "PANZERFAUST + ППШ",
			"desc": "Тяжёлый гранатомётчик. Кумулятивные ракеты (220 урона, 10.5м радиус) против укрытий.",
			"tint": Color(0.40, 0.22, 0.20)
		},
		{
			"id": "RADIO_OPERATOR",
			"title": "РАДИСТ",
			"weapon": "ППШ-41 + FPV ДРОН",
			"desc": "Оператор проводного дрона-камикадзе (150м кабель, ручной FPV таран, 240 взрывного урона).",
			"tint": Color(0.32, 0.22, 0.38)
		}
	]

	for r in roles_data:
		_role_card(grid, r)

	_button(root, "НАЗАД К ВЫБОРУ СТОРОНЫ", _show_teams, Vector2(0, 48))

func _role_card(parent: Control, data: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(250, 228)
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var swatch := ColorRect.new()
	swatch.color = data["tint"]
	swatch.custom_minimum_size = Vector2(0, 60)
	box.add_child(swatch)

	_label(box, str(data["title"]), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, str(data["weapon"]), 13, Color(0.95, 0.92, 0.6), HORIZONTAL_ALIGNMENT_CENTER)
	var desc := _label(box, str(data["desc"]), 12, Color(0.75, 0.79, 0.76), HORIZONTAL_ALIGNMENT_CENTER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var choose := _button(box, "ВЫБРАТЬ", _select_role.bind(str(data["id"])), Vector2(0, 48))
	choose.size_flags_vertical = Control.SIZE_SHRINK_END

func _select_role(role_id: String) -> void:
	get_tree().set_meta("selected_role", role_id)
	_show_deployment()

func _role_data() -> Array:
	return [
		{"id": "ASSAULT", "title": "ШТУРМОВИК", "primary": "AK-47", "primary_index": 0, "sidearm": "M1911", "ability": "Спринт и универсальный бой", "grenades": 3, "smoke": 2, "medkits": 2},
		{"id": "MEDIC", "title": "САНИТАР", "primary": "MP-40", "primary_index": 1, "sidearm": "M1911", "ability": "Лечение себя и союзников", "grenades": 2, "smoke": 2, "medkits": 5},
		{"id": "SNIPER", "title": "СНАЙПЕР", "primary": "KAR98K", "primary_index": 6, "sidearm": "M1911", "ability": "Оптика 2.6x, радар 70 м", "grenades": 1, "smoke": 2, "medkits": 2},
		{"id": "ANTI_TANK", "title": "ПТ-СТРЕЛОК", "primary": "PANZERFAUST", "primary_index": 7, "sidearm": "M1911", "ability": "Ракеты по укрытиям", "grenades": 1, "smoke": 1, "medkits": 2},
		{"id": "RADIO_OPERATOR", "title": "РАДИСТ", "primary": "ППШ-41", "primary_index": 5, "sidearm": "M1911", "ability": "FPV-дрон на кабеле", "grenades": 1, "smoke": 2, "medkits": 2},
	]

func _loadout_data() -> Array:
	return [
		{"id": "ASSAULT", "title": "ШТУРМ", "desc": "+1 граната"},
		{"id": "BALANCED", "title": "БАЛАНС", "desc": "Стандартный набор"},
		{"id": "SURVIVAL", "title": "ЖИВУЧЕСТЬ", "desc": "+1 бинт"},
	]

func _role_by_id(role_id: String) -> Dictionary:
	for role in _role_data():
		if str(role["id"]) == role_id:
			return role
	return _role_data()[0]

func _weapon_names() -> Array:
	return ["AK-47", "MP-40", "MOSIN-NAGANT", "M1911", "PUMP SHOTGUN", "PPSH-41", "KAR98K", "PANZERFAUST"]

func _weapon_name(index: int) -> String:
	var names := _weapon_names()
	return str(names[clampi(index, 0, names.size() - 1)])

func _primary_options(role_id: String) -> Array[int]:
	match role_id:
		"MEDIC":
			return [1, 4]
		"SNIPER":
			return [6, 2]
		"ANTI_TANK":
			return [7, 5]
		"RADIO_OPERATOR":
			return [5, 1]
		_:
			return [0, 5]

func _current_primary() -> int:
	var options := _primary_options(selected_role)
	if options.has(selected_primary):
		return selected_primary
	return int(_role_by_id(selected_role)["primary_index"])

func _current_counts() -> Dictionary:
	var role := _role_by_id(selected_role)
	var grenades := int(role["grenades"])
	var smoke := int(role["smoke"])
	var medkits := int(role["medkits"])
	match selected_loadout:
		"ASSAULT":
			grenades += 1
			medkits = maxi(1, medkits - 1)
		"SURVIVAL":
			grenades = maxi(0, grenades - 1)
			medkits += 1
	if selected_grenades >= 0:
		grenades = selected_grenades
	if selected_smoke >= 0:
		smoke = selected_smoke
	if selected_medkits >= 0:
		medkits = selected_medkits
	return {"grenades": grenades, "smoke": smoke, "medkits": medkits}

func _show_deployment() -> void:
	if get_tree().has_meta("selected_role"):
		selected_role = str(get_tree().get_meta("selected_role"))
	if get_tree().has_meta("selected_loadout"):
		selected_loadout = str(get_tree().get_meta("selected_loadout"))
	if get_tree().has_meta("selected_team"):
		selected_team = str(get_tree().get_meta("selected_team"))
	if get_tree().has_meta("selected_primary"):
		selected_primary = int(get_tree().get_meta("selected_primary"))
	if get_tree().has_meta("selected_grenades"):
		selected_grenades = int(get_tree().get_meta("selected_grenades"))
	if get_tree().has_meta("selected_smoke"):
		selected_smoke = int(get_tree().get_meta("selected_smoke"))
	if get_tree().has_meta("selected_medkits"):
		selected_medkits = int(get_tree().get_meta("selected_medkits"))
	if get_tree().has_meta("selected_rockets"):
		selected_rockets = int(get_tree().get_meta("selected_rockets"))
	get_tree().set_meta("selected_role", selected_role)
	get_tree().set_meta("selected_loadout", selected_loadout)
	get_tree().set_meta("selected_team", selected_team)
	get_tree().set_meta("selected_map", selected_map)

	var root := _make_shell("РАЗВЁРТЫВАНИЕ  /  " + selected_map)
	_label(root, "Выбери фракцию, класс, снаряжение и точку десанта прямо на карте.", 15, Color(0.72,0.77,0.74))
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)

	var map_holder := PanelContainer.new()
	map_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_holder.custom_minimum_size = Vector2(600, 400)
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
	image.custom_minimum_size = Vector2(580, 400)
	image.set_selected(0)
	image.spawn_selected.connect(_select_spawn)
	map_overlay.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var side_scroll := ScrollContainer.new()
	side_scroll.custom_minimum_size = Vector2(370, 0)
	side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(side_scroll)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 8)
	side_scroll.add_child(side)

	# Фракция
	_label(side, "ФРАКЦИЯ", 17, Color(0.85,0.88,0.84))
	var faction_group := ButtonGroup.new()
	var faction_row := HBoxContainer.new()
	faction_row.add_theme_constant_override("separation", 8)
	side.add_child(faction_row)
	for team in ["IRON LEGION", "RED FRONT"]:
		var faction_btn := _toggle_button(faction_row, team, faction_group, selected_team == team, _set_team_in_place.bind(team), Vector2(0, 40))
		faction_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		faction_btn.add_theme_font_size_override("font_size", 13)

	# Класс
	_label(side, "КЛАСС", 17, Color(0.85,0.88,0.84))
	var class_group := ButtonGroup.new()
	var class_grid := GridContainer.new()
	class_grid.columns = 2
	class_grid.add_theme_constant_override("h_separation", 6)
	class_grid.add_theme_constant_override("v_separation", 6)
	side.add_child(class_grid)
	for role in _role_data():
		var role_id := str(role["id"])
		var class_btn := _toggle_button(class_grid, str(role["title"]), class_group, selected_role == role_id, _set_role_in_place.bind(role_id), Vector2(0, 38))
		class_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		class_btn.add_theme_font_size_override("font_size", 12)

	# Основное оружие в рамках класса
	_label(side, "ОСНОВНОЕ ОРУЖИЕ", 15, Color(0.85,0.88,0.84))
	var primary_group := ButtonGroup.new()
	var primary_row := HBoxContainer.new()
	primary_row.add_theme_constant_override("separation", 6)
	side.add_child(primary_row)
	for weapon_index in _primary_options(selected_role):
		var primary_btn := _toggle_button(primary_row, _weapon_name(weapon_index), primary_group, _current_primary() == weapon_index, _set_primary_in_place.bind(weapon_index), Vector2(0, 36))
		primary_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		primary_btn.add_theme_font_size_override("font_size", 12)

	# Снаряжение
	_label(side, "СНАРЯЖЕНИЕ", 17, Color(0.85,0.88,0.84))
	var loadout_group := ButtonGroup.new()
	var loadout_row := HBoxContainer.new()
	loadout_row.add_theme_constant_override("separation", 6)
	side.add_child(loadout_row)
	for preset in _loadout_data():
		var preset_id := str(preset["id"])
		var preset_btn := _toggle_button(loadout_row, str(preset["title"]), loadout_group, selected_loadout == preset_id, _set_loadout_in_place.bind(preset_id), Vector2(0, 38))
		preset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		preset_btn.add_theme_font_size_override("font_size", 12)

	_label(side, "КОЛИЧЕСТВО", 15, Color(0.85,0.88,0.84))
	set_meta("counter_labels", {})
	_counter_row(side, "ГРАНАТЫ", "grenades", 0, 6)
	_counter_row(side, "ДЫМ", "smoke", 0, 5)
	_counter_row(side, "БИНТЫ", "medkits", 0, 6)
	if selected_role == "ANTI_TANK":
		_counter_row(side, "РАКЕТЫ", "rockets", 1, 6)
	elif selected_role == "RADIO_OPERATOR":
		_label(side, "FPV-ДРОН: 1 (фиксировано)", 12, Color(0.74,0.78,0.72))

	var summary := Label.new()
	summary.name = "LoadoutSummary"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 13)
	summary.add_theme_color_override("font_color", Color(0.82,0.86,0.80))
	summary.custom_minimum_size = Vector2(0, 80)
	side.add_child(summary)

	_label(side, "ТОЧКА ПОЯВЛЕНИЯ", 15, Color(0.85,0.88,0.84))
	_label(side, "Нажми на круг на карте, затем подтверди DEPLOY.", 12, Color(0.67,0.72,0.69))

	# Кнопки и статус всегда внизу экрана, вне прокрутки настроек.
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 14)
	root.add_child(bottom_row)
	var selected := Label.new()
	selected.name = "SpawnLabel"
	selected.text = "ТОЧКА 1  •  ГОТОВА"
	selected.custom_minimum_size = Vector2(190, 0)
	selected.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selected.add_theme_font_size_override("font_size", 16)
	selected.add_theme_color_override("font_color", Color(0.96,0.84,0.38))
	bottom_row.add_child(selected)
	var deploy := _button(bottom_row, "DEPLOY (В БОЙ)", _deploy, Vector2(0, 56))
	deploy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deploy.add_theme_font_size_override("font_size", 19)
	var back := _button(bottom_row, "НАЗАД К КАРТЕ", _show_maps, Vector2(220, 56))
	back.add_theme_font_size_override("font_size", 15)

	var spawn_index := clampi(int(get_meta("selected_spawn", 0)), 0, 4)
	set_meta("spawn_label", selected)
	set_meta("deploy_button", deploy)
	set_meta("map_preview", image)
	set_meta("loadout_summary", summary)
	set_meta("selected_spawn", spawn_index)
	_update_loadout_summary()
	_refresh_counter_labels()
	_select_spawn(spawn_index)

func _toggle_button(parent: Control, text: String, group: ButtonGroup, is_selected: bool, callback: Callable, min_size := Vector2(0, 40)) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.button_pressed = is_selected
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 14)
	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = Color(0.20, 0.30, 0.25, 1.0)
	selected_style.border_width_left = 2
	selected_style.border_width_right = 2
	selected_style.border_width_top = 2
	selected_style.border_width_bottom = 2
	selected_style.border_color = Color(0.92, 0.78, 0.34, 1.0)
	selected_style.corner_radius_top_left = 4
	selected_style.corner_radius_top_right = 4
	selected_style.corner_radius_bottom_left = 4
	selected_style.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("pressed", selected_style)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.96, 0.78))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _set_team_in_place(team: String) -> void:
	selected_team = team
	get_tree().set_meta("selected_team", team)
	var preview = get_meta("map_preview", null)
	if preview != null and preview.has_method("set_team"):
		preview.call("set_team", team)
	set_meta("selected_spawn", 0)
	_select_spawn(0)

func _set_role_in_place(role_id: String) -> void:
	selected_role = role_id
	selected_primary = -1
	get_tree().set_meta("selected_role", role_id)
	get_tree().set_meta("selected_primary", -1)
	_show_deployment()

func _set_loadout_in_place(loadout_id: String) -> void:
	selected_loadout = loadout_id
	get_tree().set_meta("selected_loadout", loadout_id)
	_update_loadout_summary()
	_refresh_counter_labels()

func _set_primary_in_place(weapon_index: int) -> void:
	selected_primary = weapon_index
	get_tree().set_meta("selected_primary", weapon_index)
	_update_loadout_summary()

func _counter_value(key: String) -> int:
	if key == "rockets":
		return selected_rockets if selected_rockets >= 0 else 5
	var counts := _current_counts()
	return int(counts.get(key, 0))

func _adjust_stat(key: String, delta: int) -> void:
	var value := _counter_value(key)
	var min_value := 0
	var max_value := 6
	match key:
		"grenades":
			max_value = 6
		"smoke":
			max_value = 5
		"medkits":
			max_value = 6
		"rockets":
			min_value = 1
			max_value = 6
	value = clampi(value + delta, min_value, max_value)
	match key:
		"grenades":
			selected_grenades = value
			get_tree().set_meta("selected_grenades", value)
		"smoke":
			selected_smoke = value
			get_tree().set_meta("selected_smoke", value)
		"medkits":
			selected_medkits = value
			get_tree().set_meta("selected_medkits", value)
		"rockets":
			selected_rockets = value
			get_tree().set_meta("selected_rockets", value)
	_refresh_counter_labels()
	_update_loadout_summary()

func _counter_row(parent: Control, caption: String, key: String, _min_value: int, _max_value: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var label := _label(row, caption, 12, Color(0.78,0.82,0.76))
	label.custom_minimum_size.x = 92
	var minus := Button.new()
	minus.text = "−"
	minus.custom_minimum_size = Vector2(30, 30)
	minus.add_theme_font_size_override("font_size", 16)
	minus.pressed.connect(_adjust_stat.bind(key, -1))
	row.add_child(minus)
	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(26, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 15)
	value_label.text = str(_counter_value(key))
	row.add_child(value_label)
	var plus := Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(30, 30)
	plus.add_theme_font_size_override("font_size", 16)
	plus.pressed.connect(_adjust_stat.bind(key, 1))
	row.add_child(plus)
	var labels: Dictionary = get_meta("counter_labels", {})
	labels[key] = value_label
	set_meta("counter_labels", labels)

func _refresh_counter_labels() -> void:
	var labels: Dictionary = get_meta("counter_labels", {})
	for key in labels.keys():
		var label := labels[key] as Label
		if label != null:
			label.text = str(_counter_value(str(key)))

func _update_loadout_summary() -> void:
	var role := _role_by_id(selected_role)
	var counts := _current_counts()
	var primary_name := _weapon_name(_current_primary())
	var summary: Label = get_meta("loadout_summary", null)
	if summary != null:
		var extra := ""
		if selected_role == "ANTI_TANK":
			extra = "  •  РАКЕТЫ: %d" % _counter_value("rockets")
		elif selected_role == "RADIO_OPERATOR":
			extra = "  •  ДРОН: 1"
		summary.text = "ОСНОВНОЕ: %s\nПИСТОЛЕТ: %s\nГРАНАТЫ: %d  •  ДЫМ: %d  •  БИНТЫ: %d%s\n%s" % [
			primary_name, str(role["sidearm"]), int(counts["grenades"]), int(counts["smoke"]), int(counts["medkits"]), extra, str(role["ability"])
		]

func _select_spawn(index: int) -> void:
	set_meta("selected_spawn", index)
	var label: Label = get_meta("spawn_label")
	label.text = "ТОЧКА %d  •  ГОТОВА" % (index + 1)
	var preview = get_meta("map_preview", null)
	if preview != null:
		preview.set_selected(index)

func _deploy() -> void:
	get_tree().set_meta("selected_role", selected_role)
	get_tree().set_meta("selected_loadout", selected_loadout)
	get_tree().set_meta("selected_team", selected_team)
	get_tree().set_meta("selected_primary", selected_primary)
	get_tree().set_meta("selected_grenades", selected_grenades)
	get_tree().set_meta("selected_smoke", selected_smoke)
	get_tree().set_meta("selected_medkits", selected_medkits)
	get_tree().set_meta("selected_rockets", selected_rockets)
	get_tree().set_meta("deploy_intro", true)
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
