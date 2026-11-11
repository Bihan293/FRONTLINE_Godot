extends CanvasLayer
class_name FRONTLINEBattlefieldHUD

## Боевой HUD: счёт, секторы, киллфид, компас и миникарта.
## Вёрстка живёт в scenes/BattlefieldHUD.tscn, скрипт только обновляет данные.

@onready var score_label: Label = %ScoreLabel
@onready var killfeed_container: VBoxContainer = %Killfeed
@onready var _sector_box: HBoxContainer = %SectorBox
@onready var compass: FRONTLINECompassBar = %Compass
@onready var minimap: FRONTLINEMinimap = %Minimap

var sector_indicators: Dictionary = {}

func setup(sector_data: Array, player: Node3D, bots: Array, iron_spawns: Array, red_spawns: Array) -> void:
	_build_sector_indicators(sector_data)
	if player != null:
		var camera: Camera3D = player.get("camera")
		if camera != null:
			compass.setup(camera, sector_data)
	minimap.setup(player, bots, sector_data, iron_spawns, red_spawns)

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

func _build_sector_indicators(sector_data: Array) -> void:
	for child in _sector_box.get_children():
		child.queue_free()
	sector_indicators.clear()
	for sec in sector_data:
		var label := Label.new()
		label.text = "[ %s ]" % sec.name
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_sector_box.add_child(label)
		sector_indicators[sec.name] = label
