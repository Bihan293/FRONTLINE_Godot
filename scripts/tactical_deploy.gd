extends CanvasLayer
class_name FRONTLINETacticalDeploy

## Экран высадки: кликабельная карта сверху, отдельная панель LOADOUT,
## одна кнопка «В БОЙ». Роль и основное оружие сохраняются между смертями.

signal deployed(spawn_pos: Vector3, role_name: String, primary_index: int)

const DEPLOY_MAP = preload("res://scripts/ui/deployment_map.gd")

const CLASSES := [
	{
		"role": "ASSAULT",
		"name": "ШТУРМОВИК",
		"primaries": [0, 1, 4],
		"desc": "Универсальный боец: автомат, гранаты Ф-1, дымовая шашка."
	},
	{
		"role": "SNIPER",
		"name": "СНАЙПЕР",
		"primaries": [6, 2],
		"desc": "Дальний бой и оптика; запасной M1911."
	},
	{
		"role": "MEDIC",
		"name": "САНИТАР",
		"primaries": [1, 0],
		"desc": "Пистолет-пулемёт и 5 полевых аптечек для себя и союзников."
	},
	{
		"role": "ANTI_TANK",
		"name": "БРОНЕБОЙЩИК",
		"primaries": [7, 4],
		"desc": "Панцерфауст против техники и укреплений, дробовик в запас."
	},
	{
		"role": "RADIO_OPERATOR",
		"name": "РАДИСТ",
		"primaries": [5, 1],
		"desc": "ППШ-41 и кабельный FPV-дрон для разведки и подрыва."
	}
]

const WEAPON_NAMES := {
	0: "AK-47", 1: "MP-40", 2: "MOSIN-NAGANT", 3: "M1911",
	4: "PUMP SHOTGUN", 5: "PPSh-41", 6: "KAR98K", 7: "PANZERFAUST"
}

var team_name: String = "IRON LEGION"
var sector_data: Array = []
var base_spawns: Array = []
var selected_spawn := Vector3.ZERO
var selected_spawn_name := "ГЛАВНАЯ БАЗА"
var selected_role := "ASSAULT"
var selected_primary := 0

var _map: FRONTLINEDeploymentMap
var _layout_boxes: Array = []
var _height_sampler := Callable()
var _role_buttons: Dictionary = {}
var _primary_buttons: Dictionary = {}
var _spawn_label: Label
var _loadout_summary: Label
var _loadout_overlay: Control
var _primary_grid: GridContainer
var _deploy_btn: Button
var _root: Control

func setup(p_team: String, p_sectors: Array, p_spawns: Array, p_boxes: Array = [], p_height_sampler := Callable(), p_role: String = "ASSAULT", p_primary: int = -1) -> void:
	team_name = p_team
	sector_data = p_sectors
	base_spawns = p_spawns
	_layout_boxes = p_boxes
	_height_sampler = p_height_sampler
	layer = 15
	name = "TacticalDeploy"
	selected_role = _known_role(p_role)
	var choices := _primaries_for(selected_role)
	selected_primary = p_primary if choices.has(p_primary) else int(choices[0])
	if not base_spawns.is_empty():
		selected_spawn = base_spawns[0]
	_build_ui()
	_map.configure(_layout_boxes, sector_data, base_spawns)
	_map.set_selected(selected_spawn)
	_update_texts()

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.05, 0.06, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 64.0
	top.add_theme_stylebox_override("panel", _style(Color(0.07, 0.09, 0.11, 0.96), Color(0.85, 0.65, 0.20, 0.9)))
	_root.add_child(top)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	top.add_child(top_row)

	var title := Label.new()
	title.text = "ТАКТИЧЕСКИЙ ДЕПЛОЙ"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	top_row.add_child(title)

	var team := Label.new()
	team.text = team_name.to_upper()
	team.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	team.add_theme_font_size_override("font_size", 16)
	team.add_theme_color_override("font_color", Color(0.55, 0.80, 1.0))
	top_row.add_child(team)

	var loadout_btn := Button.new()
	loadout_btn.text = "LOADOUT / СНАРЯЖЕНИЕ"
	loadout_btn.custom_minimum_size = Vector2(240, 44)
	loadout_btn.add_theme_font_size_override("font_size", 16)
	loadout_btn.pressed.connect(_open_loadout)
	top_row.add_child(loadout_btn)

	var main := HBoxContainer.new()
	main.anchor_left = 0.03
	main.anchor_right = 0.97
	main.anchor_top = 0.13
	main.anchor_bottom = 0.84
	main.add_theme_constant_override("separation", 18)
	_root.add_child(main)

	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_stretch_ratio = 1.9
	map_panel.add_theme_stylebox_override("panel", _style(Color(0.05, 0.08, 0.07, 0.92), Color(0.28, 0.40, 0.34, 0.8)))
	main.add_child(map_panel)

	var map_vbox := VBoxContainer.new()
	map_vbox.add_theme_constant_override("separation", 6)
	map_panel.add_child(map_vbox)

	var map_header := Label.new()
	map_header.text = "ВЫБЕРИ ТОЧКУ ВЫСАДКИ НА КАРТЕ"
	map_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_header.add_theme_font_size_override("font_size", 16)
	map_header.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	map_vbox.add_child(map_header)

	_map = DEPLOY_MAP.new()
	_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map.position_picked.connect(_on_map_picked)
	map_vbox.add_child(_map)

	var side_panel := PanelContainer.new()
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_panel.custom_minimum_size = Vector2(300, 0)
	side_panel.add_theme_stylebox_override("panel", _style(Color(0.06, 0.08, 0.10, 0.92), Color(0.28, 0.40, 0.34, 0.8)))
	main.add_child(side_panel)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 12)
	side_panel.add_child(side)

	var side_header := Label.new()
	side_header.text = "ТОЧКА ВЫСАДКИ"
	side_header.add_theme_font_size_override("font_size", 16)
	side_header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	side.add_child(side_header)

	_spawn_label = Label.new()
	_spawn_label.text = "ГЛАВНАЯ БАЗА"
	_spawn_label.add_theme_font_size_override("font_size", 20)
	_spawn_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	side.add_child(_spawn_label)

	var hint := Label.new()
	hint.text = "Нажми на карту, чтобы поставить маркер высадки. Серые здания и стены недоступны."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.68, 0.74, 0.70))
	side.add_child(hint)

	var separator := HSeparator.new()
	side.add_child(separator)

	_loadout_summary = Label.new()
	_loadout_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loadout_summary.add_theme_font_size_override("font_size", 14)
	_loadout_summary.add_theme_color_override("font_color", Color(0.85, 0.90, 0.95))
	side.add_child(_loadout_summary)

	var change_btn := Button.new()
	change_btn.text = "СМЕНИТЬ КЛАСС И ОРУЖИЕ"
	change_btn.custom_minimum_size = Vector2(0, 42)
	change_btn.pressed.connect(_open_loadout)
	side.add_child(change_btn)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(spacer)

	var bottom := HBoxContainer.new()
	bottom.anchor_left = 0.25
	bottom.anchor_right = 0.75
	bottom.anchor_top = 0.87
	bottom.anchor_bottom = 0.97
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	_root.add_child(bottom)

	_deploy_btn = Button.new()
	_deploy_btn.text = "В БОЙ / DEPLOY"
	_deploy_btn.custom_minimum_size = Vector2(460, 58)
	_deploy_btn.add_theme_font_size_override("font_size", 24)
	_deploy_btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.40))
	_deploy_btn.add_theme_stylebox_override("normal", _style(Color(0.16, 0.40, 0.20, 0.97), Color(0.40, 0.90, 0.45), 8))
	_deploy_btn.add_theme_stylebox_override("hover", _style(Color(0.20, 0.50, 0.25, 0.97), Color(0.55, 1.0, 0.55), 8))
	_deploy_btn.pressed.connect(_on_deploy_clicked)
	bottom.add_child(_deploy_btn)

	_build_loadout_overlay()

func _build_loadout_overlay() -> void:
	_loadout_overlay = Control.new()
	_loadout_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loadout_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_loadout_overlay.visible = false
	_root.add_child(_loadout_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.03, 0.82)
	_loadout_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.anchor_left = 0.16
	panel.anchor_right = 0.84
	panel.anchor_top = 0.08
	panel.anchor_bottom = 0.92
	panel.add_theme_stylebox_override("panel", _style(Color(0.07, 0.09, 0.11, 0.98), Color(0.85, 0.65, 0.20, 0.9)))
	_loadout_overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "LOADOUT / КЛАСС И ОРУЖИЕ"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 22)
	header.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	vbox.add_child(header)

	var role_label := Label.new()
	role_label.text = "КЛАСС"
	role_label.add_theme_font_size_override("font_size", 14)
	role_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	vbox.add_child(role_label)

	var role_grid := GridContainer.new()
	role_grid.columns = 2
	role_grid.add_theme_constant_override("h_separation", 8)
	role_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(role_grid)
	for cls in CLASSES:
		var role := str(cls.role)
		var btn := Button.new()
		btn.text = str(cls.name)
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(func(): _choose_role(role))
		role_grid.add_child(btn)
		_role_buttons[role] = btn

	var gun_label := Label.new()
	gun_label.text = "ОСНОВНОЕ ОРУЖИЕ"
	gun_label.add_theme_font_size_override("font_size", 14)
	gun_label.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	vbox.add_child(gun_label)

	_primary_grid = GridContainer.new()
	_primary_grid.columns = 2
	_primary_grid.add_theme_constant_override("h_separation", 8)
	_primary_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(_primary_grid)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var close_btn := Button.new()
	close_btn.text = "ГОТОВО"
	close_btn.custom_minimum_size = Vector2(0, 46)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func(): _loadout_overlay.visible = false)
	vbox.add_child(close_btn)

func _open_loadout() -> void:
	_rebuild_primary_buttons()
	_update_texts()
	_loadout_overlay.visible = true

func _choose_role(role: String) -> void:
	selected_role = _known_role(role)
	var choices := _primaries_for(selected_role)
	if not choices.has(selected_primary):
		selected_primary = int(choices[0])
	_rebuild_primary_buttons()
	_update_texts()

func _choose_primary(index: int) -> void:
	selected_primary = index
	_update_texts()

func _rebuild_primary_buttons() -> void:
	for child in _primary_grid.get_children():
		child.queue_free()
	_primary_buttons.clear()
	for index in _primaries_for(selected_role):
		var idx := int(index)
		var btn := Button.new()
		btn.text = str(WEAPON_NAMES.get(idx, "ОРУЖИЕ %d" % idx))
		btn.custom_minimum_size = Vector2(0, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _choose_primary(idx))
		_primary_grid.add_child(btn)
		_primary_buttons[idx] = btn

func _on_map_picked(world_pos: Vector3) -> void:
	var y := 0.0
	if _height_sampler.is_valid():
		y = float(_height_sampler.call(world_pos.x, world_pos.z))
	selected_spawn = Vector3(world_pos.x, y, world_pos.z)
	selected_spawn_name = "ТОЧКА НА КАРТЕ"
	_update_texts()

func _update_texts() -> void:
	if _spawn_label != null:
		_spawn_label.text = selected_spawn_name
	if _loadout_summary != null:
		var cls := _class_data(selected_role)
		_loadout_summary.text = "КЛАСС: %s\nОРУЖИЕ: %s\n\n%s" % [
			str(cls.get("name", selected_role)),
			str(WEAPON_NAMES.get(selected_primary, "—")),
			str(cls.get("desc", ""))
		]
	for role in _role_buttons:
		var btn: Button = _role_buttons[role]
		if is_instance_valid(btn):
			btn.modulate = Color(1.15, 1.15, 0.65) if role == selected_role else Color.WHITE
	for index in _primary_buttons:
		var btn: Button = _primary_buttons[index]
		if is_instance_valid(btn):
			btn.modulate = Color(1.15, 1.15, 0.65) if index == selected_primary else Color.WHITE

func _on_deploy_clicked() -> void:
	if _deploy_btn != null:
		_deploy_btn.disabled = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(func():
		deployed.emit(selected_spawn, selected_role, selected_primary)
		queue_free()
	)

func _known_role(role: String) -> String:
	for cls in CLASSES:
		if str(cls.role) == role:
			return role
	return "ASSAULT"

func _class_data(role: String) -> Dictionary:
	for cls in CLASSES:
		if str(cls.role) == role:
			return cls
	return CLASSES[0]

func _primaries_for(role: String) -> Array:
	for cls in CLASSES:
		if str(cls.role) == role:
			return cls.primaries
	return CLASSES[0].primaries

func _style(bg: Color, border: Color, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style
