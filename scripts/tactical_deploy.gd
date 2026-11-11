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

@onready var _map: FRONTLINEDeploymentMap = %DeploymentMap
@onready var _root: Control = %Root
@onready var _spawn_label: Label = %SpawnLabel
@onready var _loadout_summary: Label = %LoadoutSummary
@onready var _loadout_overlay: Control = %LoadoutOverlay
@onready var _role_grid: GridContainer = %RoleGrid
@onready var _primary_grid: GridContainer = %PrimaryGrid
@onready var _deploy_btn: Button = %DeployButton
@onready var _loadout_btn: Button = %LoadoutButton
@onready var _change_btn: Button = %ChangeLoadoutButton
@onready var _close_btn: Button = %CloseLoadoutButton

var _layout_boxes: Array = []
var _height_sampler := Callable()
var _role_buttons: Dictionary = {}
var _primary_buttons: Dictionary = {}

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
	_build_role_buttons()
	_rebuild_primary_buttons()
	if not _map.position_picked.is_connected(_on_map_picked):
		_map.position_picked.connect(_on_map_picked)
	if not _deploy_btn.pressed.is_connected(_on_deploy_clicked):
		_deploy_btn.pressed.connect(_on_deploy_clicked)
	if not _loadout_btn.pressed.is_connected(_open_loadout):
		_loadout_btn.pressed.connect(_open_loadout)
	if not _change_btn.pressed.is_connected(_open_loadout):
		_change_btn.pressed.connect(_open_loadout)
	if not _close_btn.pressed.is_connected(_close_loadout):
		_close_btn.pressed.connect(_close_loadout)
	_deploy_btn.disabled = false
	_map.configure(_layout_boxes, sector_data, base_spawns)
	_map.set_selected(selected_spawn)
	_update_texts()

func _build_role_buttons() -> void:
	for child in _role_grid.get_children():
		child.queue_free()
	_role_buttons.clear()
	for cls in CLASSES:
		var role := str(cls.role)
		var btn := Button.new()
		btn.text = str(cls.name)
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(func(): _choose_role(role))
		_role_grid.add_child(btn)
		_role_buttons[role] = btn

func _open_loadout() -> void:
	_rebuild_primary_buttons()
	_update_texts()
	_loadout_overlay.visible = true

func _close_loadout() -> void:
	if _loadout_overlay != null:
		_loadout_overlay.visible = false

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

