extends CanvasLayer
class_name FRONTLINETacticalDeploy

## Тактический экран деплоя и выбора спавнов (Overhead Tactical Spawn & Loadout Selector).
## Позволяет игроку:
## 1. Выбрать точку спавна (База или любой захваченный дружественный сектор A, B, C);
## 2. Выбрать класс бойца (Штурмовик, Снайпер, Санитар, Бронебойщик, Пулеметчик);
## 3. Выбрать снаряжение и деплоиться с плавной кинематографичной анимацией спуска камеры в бой.

signal deployed(spawn_pos: Vector3, role_name: String, primary_index: int)

var team_name: String = "IRON LEGION"
var sector_data: Array = []
var base_spawns: Array = []
var selected_spawn: Vector3 = Vector3.ZERO
var selected_spawn_name: String = "БАЗА"
var selected_role: String = "ASSAULT"
var selected_primary: int = 0

var _spawn_buttons: Array[Button] = []
var _role_buttons: Dictionary = {}
var _status_label: Label
var _deploy_btn: Button
var _next_btn: Button
var _back_btn: Button
var _spawn_panel: PanelContainer
var _class_panel: PanelContainer
var _top_label: Label
var _step := 0
var _root_container: Control

const CLASSES = [
	{
		"role": "ASSAULT",
		"name": "ШТУРМОВИК",
		"primary": 0, # AK-47
		"primary_name": "Автомат АК-47",
		"desc": "Универсальный штурмовой боец: скорострельный автомат, гранаты Ф-1, дымовая шашка."
	},
	{
		"role": "SNIPER",
		"name": "СНАЙПЕР",
		"primary": 6, # Kar98k ZF-39 / Mosin
		"primary_name": "Снайперская винтовка (ZF-39 / Мосина)",
		"desc": "Точечное уничтожение целей на дальних дистанциях, оптический прицел, запасной пистолет M1911."
	},
	{
		"role": "MEDIC",
		"name": "САНИТАР",
		"primary": 1, # MP-40 / PPSh
		"primary_name": "Пистолет-пулемет (MP-40 / ППШ-41)",
		"desc": "Быстрая маневренность, 5 полевых аптечек первой помощи для лечения себя и союзников."
	},
	{
		"role": "ANTI_TANK",
		"name": "БРОНЕБОЙЩИК",
		"primary": 7, # Panzerfaust
		"primary_name": "Панцерфауст / Дробовик",
		"desc": "Тяжелая огневая мощь против техники, укреплений и скоплений пехоты."
	},
	{
		"role": "RADIO_OPERATOR",
		"name": "РАДИСТ",
		"primary": 5, # PPSh-41
		"primary_name": "ППШ-41 + FPV-дрон",
		"desc": "Разведка и подрыв с кабельного FPV-дрона, дымовая завеса."
	},
	{
		"role": "SUPPORT",
		"name": "ПУЛЕМЕТЧИК",
		"primary": 5, # PPSh-41 Drum
		"primary_name": "ППШ-41 (71 патрон) / Станковый MG",
		"desc": "Шквальный огонь на подавление, увеличенный боезапас, поддержка наступления."
	}
]

func setup(p_team: String, p_sectors: Array, p_base_spawns: Array) -> void:
	team_name = p_team
	sector_data = p_sectors
	base_spawns = p_base_spawns
	if not base_spawns.is_empty():
		selected_spawn = base_spawns[0]
	layer = 15
	_build_ui()

func _build_ui() -> void:
	_root_container = Control.new()
	_root_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root_container)

	# Полупрозрачная тактическая виньетка фона
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.08, 0.68)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_container.add_child(bg)

	# Верхняя плашка
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 60.0
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.08, 0.10, 0.13, 0.90)
	top_style.border_width_bottom = 2
	top_style.border_color = Color(0.85, 0.65, 0.20, 0.90)
	top_bar.add_theme_stylebox_override("panel", top_style)
	_root_container.add_child(top_bar)

	var top_label := Label.new()
	top_label.text = "ТАКТИЧЕСКИЙ ДЕПЛОЙ • ВЫБОР ТОЧКИ И КЛАССА • " + team_name.to_upper()
	top_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_label.add_theme_font_size_override("font_size", 20)
	top_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	top_bar.add_child(top_label)
	_top_label = top_label

	# Главный контейнер (Слева спавны, справа классы)
	var main_h := HBoxContainer.new()
	main_h.anchor_left = 0.05
	main_h.anchor_right = 0.95
	main_h.anchor_top = 0.12
	main_h.anchor_bottom = 0.82
	main_h.add_theme_constant_override("separation", 24)
	_root_container.add_child(main_h)

	# --- ЛЕВАЯ КОЛОНКА: ТОЧКИ СПАВНА ---
	var spawn_panel := PanelContainer.new()
	spawn_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spawn_panel.size_flags_stretch_ratio = 1.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.08, 0.10, 0.82)
	panel_style.set_corner_radius_all(6)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.25, 0.35, 0.42, 0.60)
	spawn_panel.add_theme_stylebox_override("panel", panel_style)
	main_h.add_child(spawn_panel)
	_spawn_panel = spawn_panel

	var spawn_vbox := VBoxContainer.new()
	spawn_vbox.add_theme_constant_override("separation", 10)
	spawn_panel.add_child(spawn_vbox)

	var spawn_header := Label.new()
	spawn_header.text = "ТОЧКИ ВЫСАДКИ (SPAWN POINTS)"
	spawn_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spawn_header.add_theme_font_size_override("font_size", 17)
	spawn_header.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	spawn_vbox.add_child(spawn_header)

	# 1. Базовый спавн (всегда доступен)
	var base_btn := Button.new()
	base_btn.text = "[БАЗА] ГЛАВНАЯ БАЗА (%s)" % ("СЕВЕР" if team_name.contains("RED") else "ЮГ")
	base_btn.custom_minimum_size = Vector2(0, 48)
	base_btn.add_theme_font_size_override("font_size", 16)
	base_btn.pressed.connect(func():
		_select_spawn(base_spawns[0] if not base_spawns.is_empty() else Vector3.ZERO, "ГЛАВНАЯ БАЗА", base_btn)
	)
	spawn_vbox.add_child(base_btn)
	_spawn_buttons.append(base_btn)

	# 2. Секторы карты A, B, C
	for sec in sector_data:
		var sec_name: String = str(sec.name)
		var sec_pos: Vector3 = sec.pos
		var sec_owner: String = str(sec.owner)
		var is_friendly := (sec_owner == team_name)

		var btn := Button.new()
		if is_friendly:
			btn.text = "[СЕКТОР] %s • ЗАХВАЧЕН (ДОСТУПЕН)" % sec_name
			btn.add_theme_color_override("font_color", Color(0.45, 1.0, 0.45))
			btn.pressed.connect(func():
				_select_spawn(sec_pos + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0)), "СЕКТОР " + sec_name, btn)
			)
		else:
			var status_str := "ВРАГ" if sec_owner != "" else "НЕЙТРАЛЕН"
			btn.text = "[СЕКТОР] %s • %s (НЕДОСТУПЕН)" % [sec_name, status_str]
			btn.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
			btn.disabled = true
		btn.custom_minimum_size = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 15)
		spawn_vbox.add_child(btn)
		_spawn_buttons.append(btn)

	# --- ПРАВАЯ КОЛОНКА: КЛАССЫ И СНАРЯЖЕНИЕ ---
	var class_panel := PanelContainer.new()
	class_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	class_panel.size_flags_stretch_ratio = 1.2
	class_panel.add_theme_stylebox_override("panel", panel_style)
	main_h.add_child(class_panel)
	_class_panel = class_panel

	var class_vbox := VBoxContainer.new()
	class_vbox.add_theme_constant_override("separation", 8)
	class_panel.add_child(class_vbox)

	var class_header := Label.new()
	class_header.text = "КЛАСС И СНАРЯЖЕНИЕ (LOADOUT)"
	class_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	class_header.add_theme_font_size_override("font_size", 17)
	class_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	class_vbox.add_child(class_header)

	for c in CLASSES:
		var role: String = str(c.role)
		var c_name: String = str(c.name)
		var c_gun: String = str(c.primary_name)
		var prim_idx: int = int(c.primary)

		var c_btn := Button.new()
		c_btn.text = "%s  •  %s" % [c_name, c_gun]
		c_btn.custom_minimum_size = Vector2(0, 44)
		c_btn.add_theme_font_size_override("font_size", 15)
		c_btn.pressed.connect(func():
			_select_class(role, prim_idx)
		)
		class_vbox.add_child(c_btn)
		_role_buttons[role] = c_btn

	# Информационная плашка выбранного класса
	_status_label = Label.new()
	_status_label.text = "Выбран штурмовик: автомат АК-47, гранаты Ф-1, дым."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95))
	class_vbox.add_child(_status_label)

	# --- НИЖНЯЯ КНОПКА: ДЕПЛОЙ ---
	var bottom_bar := HBoxContainer.new()
	bottom_bar.anchor_left = 0.25
	bottom_bar.anchor_right = 0.75
	bottom_bar.anchor_top = 0.86
	bottom_bar.anchor_bottom = 0.96
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_root_container.add_child(bottom_bar)

	_deploy_btn = Button.new()
	_deploy_btn.text = "В БОЙ / ДЕПЛОЙ (DEPLOY)"
	_deploy_btn.custom_minimum_size = Vector2(420, 56)
	_deploy_btn.add_theme_font_size_override("font_size", 22)
	_deploy_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.40))
	var deploy_style := StyleBoxFlat.new()
	deploy_style.bg_color = Color(0.18, 0.45, 0.22, 0.95)
	deploy_style.set_corner_radius_all(8)
	deploy_style.border_width_left = 2
	deploy_style.border_width_top = 2
	deploy_style.border_width_right = 2
	deploy_style.border_width_bottom = 2
	deploy_style.border_color = Color(0.40, 0.90, 0.45)
	_deploy_btn.add_theme_stylebox_override("normal", deploy_style)
	_deploy_btn.pressed.connect(_on_deploy_clicked)
	bottom_bar.add_child(_deploy_btn)

	# QA-fix TASK-0022: два шага — сначала точка высадки, потом снаряжение.
	_next_btn = Button.new()
	_next_btn.text = "ДАЛЕЕ → СНАРЯЖЕНИЕ"
	_next_btn.custom_minimum_size = Vector2(260, 52)
	_next_btn.add_theme_font_size_override("font_size", 18)
	_next_btn.pressed.connect(func(): _show_step(1))
	bottom_bar.add_child(_next_btn)

	_back_btn = Button.new()
	_back_btn.text = "← ТОЧКА ВЫСАДКИ"
	_back_btn.custom_minimum_size = Vector2(220, 52)
	_back_btn.add_theme_font_size_override("font_size", 17)
	_back_btn.pressed.connect(func(): _show_step(0))
	bottom_bar.add_child(_back_btn)

	# Инициализация выбора
	if not _spawn_buttons.is_empty():
		_select_spawn(selected_spawn, "ГЛАВНАЯ БАЗА", _spawn_buttons[0])
	_select_class(selected_role, selected_primary)
	_show_step(0)

func _show_step(step: int) -> void:
	_step = step
	var spawn_step := step == 0
	if _spawn_panel != null:
		_spawn_panel.visible = spawn_step
	if _class_panel != null:
		_class_panel.visible = not spawn_step
	if _next_btn != null:
		_next_btn.visible = spawn_step
	if _deploy_btn != null:
		_deploy_btn.visible = not spawn_step
	if _back_btn != null:
		_back_btn.visible = not spawn_step
	if _top_label != null:
		_top_label.text = ("ШАГ 1/2 • ВЫБОР ТОЧКИ ВЫСАДКИ • " if spawn_step else "ШАГ 2/2 • КЛАСС И СНАРЯЖЕНИЕ • ") + team_name.to_upper()

func _select_spawn(pos: Vector3, spawn_name: String, active_btn: Button) -> void:
	selected_spawn = pos
	selected_spawn_name = spawn_name
	for btn in _spawn_buttons:
		if is_instance_valid(btn):
			btn.modulate = Color(1.0, 1.0, 1.0)
	if is_instance_valid(active_btn):
		active_btn.modulate = Color(1.2, 1.2, 0.7)

func _select_class(role: String, prim_idx: int) -> void:
	selected_role = role
	selected_primary = prim_idx
	for r in _role_buttons:
		var btn: Button = _role_buttons[r]
		if is_instance_valid(btn):
			btn.modulate = Color(1.2, 1.2, 0.6) if r == role else Color(1.0, 1.0, 1.0)

	for c in CLASSES:
		if c.role == role:
			if _status_label != null:
				_status_label.text = "Класс: %s\nОсновное: %s\n%s" % [c.name, c.primary_name, c.desc]
			break

func _on_deploy_clicked() -> void:
	_deploy_btn.disabled = true
	var tw := create_tween()
	tw.tween_property(_root_container, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(func():
		deployed.emit(selected_spawn, selected_role, selected_primary)
		queue_free()
	)
