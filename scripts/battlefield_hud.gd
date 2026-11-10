extends CanvasLayer
class_name FRONTLINEBattlefieldHUD

## Боевой HUD: счёт, секторы, киллфид, компас и миникарта.
## Не владеет боем — получает готовые значения.

const COMPASS_SCRIPT = preload("res://scripts/compass_bar.gd")
const MINIMAP_SCRIPT = preload("res://scripts/minimap.gd")

var score_label: Label
var killfeed_container: VBoxContainer
var sector_indicators: Dictionary = {}
var compass: FRONTLINECompassBar
var minimap: FRONTLINEMinimap

func setup(sector_data: Array, player: Node3D, bots: Array, iron_spawns: Array, red_spawns: Array) -> void:
	layer = 5
	_build_top_bar(sector_data)
	_build_killfeed()
	_build_compass(sector_data, player)
	_build_minimap(sector_data, player, bots, iron_spawns, red_spawns)

func refresh_score(mode: String, iron: int, red: int) -> void:
	if score_label == null:
		return
	if mode == "TDM":
		score_label.text = "TDM (ДО 50)  •  IRON LEGION: %d   ⚔   RED FRONT: %d" % [iron, red]
	else:
		score_label.text = "IRON LEGION: %d   ⚔   RED FRONT: %d" % [iron, red]

func add_killfeed(killer: String, victim: String, victim_team: String) -> void:
	if killfeed_container == null:
		return
	var entry := Label.new()
	entry.text = "%s  ︻╦╤─  %s" % [killer, victim]
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	entry.add_theme_font_size_override("font_size", 14)
	var color := Color(1.0, 0.45, 0.40) if victim_team.contains("RED") else Color(0.55, 0.75, 1.0)
	entry.add_theme_color_override("font_color", color)
	entry.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	entry.add_theme_constant_override("shadow_offset_x", 1)
	entry.add_theme_constant_override("shadow_offset_y", 1)
	killfeed_container.add_child(entry)
	get_tree().create_timer(4.5, false).timeout.connect(func():
		if is_instance_valid(entry):
			entry.queue_free()
	)

func update_sector(section: Dictionary) -> void:
	var color := Color(0.7, 0.7, 0.7)
	if section.owner == "IRON LEGION":
		color = Color(0.25, 0.45, 0.85)
	elif section.owner == "RED FRONT":
		color = Color(0.85, 0.22, 0.18)
	var label: Label = sector_indicators.get(section.name, null)
	if label != null:
		label.add_theme_color_override("font_color", color)

func add_gunfire(world_pos: Vector3) -> void:
	if compass != null:
		compass.add_gunfire_ping(world_pos)

func _build_top_bar(sector_data: Array) -> void:
	var top_panel := PanelContainer.new()
	top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 320
	top_panel.offset_right = -320
	top_panel.offset_top = 16
	top_panel.offset_bottom = 68
	add_child(top_panel)
	var top_box := HBoxContainer.new()
	top_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top_box.add_theme_constant_override("separation", 28)
	top_panel.add_child(top_box)
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_box.add_child(score_label)
	var sectors := HBoxContainer.new()
	sectors.add_theme_constant_override("separation", 14)
	top_box.add_child(sectors)
	for sec in sector_data:
		var label := Label.new()
		label.text = "[ %s ]" % sec.name
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		sectors.add_child(label)
		sector_indicators[sec.name] = label

func _build_killfeed() -> void:
	killfeed_container = VBoxContainer.new()
	killfeed_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	killfeed_container.offset_left = 24
	killfeed_container.offset_right = 340
	killfeed_container.offset_top = 320
	killfeed_container.offset_bottom = 470
	killfeed_container.add_theme_constant_override("separation", 4)
	add_child(killfeed_container)

func _build_compass(sector_data: Array, player: Node3D) -> void:
	compass = COMPASS_SCRIPT.new()
	compass.anchor_left = 0.5
	compass.anchor_right = 0.5
	compass.offset_left = -190.0
	compass.offset_right = 190.0
	compass.offset_top = 74.0
	compass.offset_bottom = 110.0
	add_child(compass)
	if player != null:
		var camera: Camera3D = player.get("camera")
		if camera != null:
			compass.setup(camera, sector_data)

func _build_minimap(sector_data: Array, player: Node3D, bots: Array, iron_spawns: Array, red_spawns: Array) -> void:
	minimap = MINIMAP_SCRIPT.new()
	minimap.offset_left = 24.0
	minimap.offset_top = 124.0
	minimap.offset_right = 212.0
	minimap.offset_bottom = 312.0
	add_child(minimap)
	minimap.setup(player, bots, sector_data, iron_spawns, red_spawns)
